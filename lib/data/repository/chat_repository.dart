import 'dart:async';

import 'package:bookcart/core/utils/supabase_schema_error_utils.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/data/models/chat_model.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  ChatRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  Stream<List<ChatThreadModel>> watchChatsForUser(String userId) {
    return _resolvedClient
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map(
          (rows) => rows
              .map((row) => Map<String, dynamic>.from(row))
              .where((row) => _belongsToUser(row, userId))
              .map(
                (row) => ChatThreadModel.fromJson(
                  row,
                  fallbackId: row['id'] as String? ?? '',
                ),
              )
              .toList(),
        )
        .handleError((error) {
          if (isSupabaseMissingTableError(error, table: 'public.chats')) {
            throw ChatRepositoryException(
              supabaseSchemaSetupMessage(table: 'public.chats'),
            );
          }
          throw error;
        });
  }

  Stream<List<ChatMessageModel>> watchMessages(String chatId) {
    return _resolvedClient
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map(
          (rows) => rows
              .map(
                (row) => ChatMessageModel.fromJson(
                  row,
                  fallbackId: row['id'] as String? ?? '',
                ),
              )
              .toList(),
        )
        .handleError((error) {
          if (isSupabaseMissingTableError(
            error,
            table: 'public.chat_messages',
          )) {
            throw ChatRepositoryException(
              supabaseSchemaSetupMessage(table: 'public.chat_messages'),
            );
          }
          throw error;
        });
  }

  Future<ChatThreadModel> startChat({
    required BookModel book,
    required UserModel buyer,
  }) async {
    if (book.id.trim().isEmpty || book.sellerId.trim().isEmpty) {
      throw const ChatRepositoryException(
        'Seller details are missing for this listing.',
      );
    }
    if (book.sellerId == buyer.id) {
      throw const ChatRepositoryException(
        'This is your own listing. Buyers will message you here.',
      );
    }

    final chatId = '${book.id}_${book.sellerId}_${buyer.id}';
    final dynamic existingChat;
    try {
      existingChat = await _resolvedClient
          .from('chats')
          .select()
          .eq('id', chatId)
          .maybeSingle();
    } on PostgrestException catch (error) {
      if (isSupabaseMissingTableError(error, table: 'public.chats')) {
        throw ChatRepositoryException(
          supabaseSchemaSetupMessage(table: 'public.chats'),
        );
      }
      rethrow;
    }
    if (existingChat != null) {
      return ChatThreadModel.fromJson(
        Map<String, dynamic>.from(existingChat),
        fallbackId: chatId,
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final dynamic row;
    try {
      row = await _resolvedClient
          .from('chats')
          .insert({
            'id': chatId,
            'book_id': book.id,
            'book_title': book.title,
            'book_price': book.price,
            'buyer_id': buyer.id,
            'seller_id': book.sellerId,
            'buyer_name': buyer.name,
            'seller_name': book.sellerName.trim().isEmpty
                ? 'Seller'
                : book.sellerName,
            'participant_ids': [buyer.id, book.sellerId],
            'last_message': '',
            'last_sender_id': null,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();
    } on PostgrestException catch (error) {
      if (isSupabaseMissingTableError(error, table: 'public.chats')) {
        throw ChatRepositoryException(
          supabaseSchemaSetupMessage(table: 'public.chats'),
        );
      }
      rethrow;
    }

    return ChatThreadModel.fromJson(
      Map<String, dynamic>.from(row),
      fallbackId: chatId,
    );
  }

  Future<void> sendMessage({
    required String chatId,
    required UserModel sender,
    required String text,
  }) async {
    final message = text.trim();
    if (message.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _resolvedClient.from('chat_messages').insert({
        'chat_id': chatId,
        'text': message,
        'sender_id': sender.id,
        'created_at': now,
      });

      // Keep the thread preview fresh for environments that have not yet
      // applied the chat sync trigger migration. The database trigger handles
      // this server-side once enabled, so failures here should not block a
      // successfully inserted message.
      try {
        await _resolvedClient
            .from('chats')
            .update({
              'last_message': message,
              'last_sender_id': sender.id,
              'updated_at': now,
            })
            .eq('id', chatId);
      } catch (_) {}
    } on PostgrestException catch (error) {
      if (isSupabaseMissingTableError(error)) {
        throw ChatRepositoryException(supabaseSchemaSetupMessage());
      }
      rethrow;
    }
  }

  bool _belongsToUser(Map<String, dynamic> row, String userId) {
    final buyerId = row['buyer_id']?.toString() ?? row['buyerId']?.toString();
    final sellerId =
        row['seller_id']?.toString() ?? row['sellerId']?.toString();

    return buyerId == userId || sellerId == userId;
  }
}

class ChatRepositoryException implements Exception {
  const ChatRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
