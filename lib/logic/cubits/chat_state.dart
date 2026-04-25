import 'package:bookcart/data/models/chat_model.dart';

class ChatState {
  const ChatState({
    this.threads = const [],
    this.messages = const [],
    this.selectedThreadId,
    this.isLoadingThreads = true,
    this.isLoadingMessages = false,
    this.isSending = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<ChatThreadModel> threads;
  final List<ChatMessageModel> messages;
  final String? selectedThreadId;
  final bool isLoadingThreads;
  final bool isLoadingMessages;
  final bool isSending;
  final String? errorMessage;
  final String? successMessage;

  ChatThreadModel? get selectedThread {
    for (final thread in threads) {
      if (thread.id == selectedThreadId) {
        return thread;
      }
    }
    return null;
  }

  ChatState copyWith({
    List<ChatThreadModel>? threads,
    List<ChatMessageModel>? messages,
    String? selectedThreadId,
    bool clearSelectedThread = false,
    bool? isLoadingThreads,
    bool? isLoadingMessages,
    bool? isSending,
    String? errorMessage,
    String? successMessage,
  }) {
    return ChatState(
      threads: threads ?? this.threads,
      messages: messages ?? this.messages,
      selectedThreadId: clearSelectedThread
          ? null
          : selectedThreadId ?? this.selectedThreadId,
      isLoadingThreads: isLoadingThreads ?? this.isLoadingThreads,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}
