import 'dart:async';

import 'package:bookcart/core/utils/app_logger.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/data/models/chat_model.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:bookcart/data/repository/chat_repository.dart';
import 'package:bookcart/logic/cubits/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository) : super(const ChatState());

  final ChatRepository _repository;
  StreamSubscription<List<ChatThreadModel>>? _threadsSubscription;
  StreamSubscription<List<ChatMessageModel>>? _messagesSubscription;
  String? _watchingUserId;
  String? _watchingThreadId;

  Future<void> watchChatsForUser(String userId) async {
    if (_watchingUserId == userId) {
      return;
    }

    AppLogger.info(
      'ChatCubit',
      'watchChatsForUser: subscribing',
      details: {'userId': userId},
    );
    _watchingUserId = userId;
    await _threadsSubscription?.cancel();
    emit(
      state.copyWith(
        isLoadingThreads: true,
        clearSelectedThread: true,
        messages: const [],
      ),
    );

    _threadsSubscription = _repository
        .watchChatsForUser(userId)
        .listen(
          (threads) {
            AppLogger.success(
              'ChatCubit',
              'Threads synced',
              details: {'userId': userId, 'count': threads.length},
            );
            final previousSelectedThreadId = state.selectedThreadId;
            final selectedThreadExists = threads.any(
              (thread) => thread.id == state.selectedThreadId,
            );
            final nextSelectedThreadId = selectedThreadExists
                ? state.selectedThreadId
                : threads.isEmpty
                ? null
                : threads.first.id;

            emit(
              state.copyWith(
                threads: threads,
                selectedThreadId: nextSelectedThreadId,
                clearSelectedThread: nextSelectedThreadId == null,
                isLoadingThreads: false,
              ),
            );

            if (nextSelectedThreadId != null &&
                nextSelectedThreadId != previousSelectedThreadId) {
              selectThread(nextSelectedThreadId);
            } else if (nextSelectedThreadId == null) {
              _messagesSubscription?.cancel();
              _watchingThreadId = null;
              emit(
                state.copyWith(messages: const [], isLoadingMessages: false),
              );
            }
          },
          onError: (error, stackTrace) {
            AppLogger.error(
              'ChatCubit',
              'watchChatsForUser stream error',
              error: error,
              stackTrace: stackTrace,
            );
            _watchingUserId = null;
            emit(
              state.copyWith(
                isLoadingThreads: false,
                errorMessage: error is ChatRepositoryException
                    ? error.message
                    : 'Could not load chats right now.',
              ),
            );
          },
        );
  }

  Future<void> selectThread(String threadId) async {
    if (_watchingThreadId == threadId && _messagesSubscription != null) {
      return;
    }

    AppLogger.info(
      'ChatCubit',
      'selectThread',
      details: {'threadId': threadId},
    );
    await _messagesSubscription?.cancel();
    emit(
      state.copyWith(
        selectedThreadId: threadId,
        messages: const [],
        isLoadingMessages: true,
      ),
    );
    _watchingThreadId = threadId;

    _messagesSubscription = _repository
        .watchMessages(threadId)
        .listen(
          (messages) {
            AppLogger.success(
              'ChatCubit',
              'Messages synced',
              details: {'threadId': threadId, 'count': messages.length},
            );
            emit(state.copyWith(messages: messages, isLoadingMessages: false));
          },
          onError: (error, stackTrace) {
            AppLogger.error(
              'ChatCubit',
              'watchMessages stream error',
              error: error,
              stackTrace: stackTrace,
            );
            _watchingThreadId = null;
            emit(
              state.copyWith(
                isLoadingMessages: false,
                errorMessage: error is ChatRepositoryException
                    ? error.message
                    : 'Could not load messages right now.',
              ),
            );
          },
        );
  }

  Future<void> startChatForBook({
    required BookModel book,
    required UserModel buyer,
  }) async {
    final timer = AppLogger.startTimer(
      'ChatCubit',
      'startChatForBook',
      details: {'bookId': book.id, 'buyerId': buyer.id},
    );
    emit(state.copyWith(isSending: true));

    try {
      final thread = await _repository.startChat(book: book, buyer: buyer);
      timer.success('Chat opened', details: {'threadId': thread.id});
      emit(
        state.copyWith(
          selectedThreadId: thread.id,
          isSending: false,
          successMessage: 'Chat opened.',
        ),
      );
      await selectThread(thread.id);
    } on ChatRepositoryException catch (error) {
      timer.fail('Open chat failed', error: error);
      emit(state.copyWith(isSending: false, errorMessage: error.message));
    } catch (error, stackTrace) {
      timer.fail('Open chat failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSending: false,
          errorMessage: 'Could not open chat right now.',
        ),
      );
    }
  }

  Future<bool> sendMessage({
    required UserModel sender,
    required String text,
  }) async {
    final threadId = state.selectedThreadId;
    if (threadId == null) {
      emit(state.copyWith(errorMessage: 'Select a chat first.'));
      return false;
    }

    final timer = AppLogger.startTimer(
      'ChatCubit',
      'sendMessage',
      details: {'threadId': threadId, 'senderId': sender.id},
    );
    emit(state.copyWith(isSending: true));

    try {
      await _repository.sendMessage(
        chatId: threadId,
        sender: sender,
        text: text,
      );
      timer.success('Message sent');
      emit(state.copyWith(isSending: false));
      return true;
    } on ChatRepositoryException catch (error) {
      timer.fail('Send message failed', error: error);
      emit(state.copyWith(isSending: false, errorMessage: error.message));
      return false;
    } catch (error, stackTrace) {
      timer.fail('Send message failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSending: false,
          errorMessage: 'Could not send that message.',
        ),
      );
      return false;
    }
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        threads: state.threads,
        messages: state.messages,
        selectedThreadId: state.selectedThreadId,
        isLoadingThreads: state.isLoadingThreads,
        isLoadingMessages: state.isLoadingMessages,
        isSending: state.isSending,
      ),
    );
  }

  Future<void> reset() async {
    await _threadsSubscription?.cancel();
    await _messagesSubscription?.cancel();
    _threadsSubscription = null;
    _messagesSubscription = null;
    _watchingUserId = null;
    _watchingThreadId = null;
    emit(const ChatState(isLoadingThreads: false));
  }

  @override
  Future<void> close() async {
    await _threadsSubscription?.cancel();
    await _messagesSubscription?.cancel();
    return super.close();
  }
}
