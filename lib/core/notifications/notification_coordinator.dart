import 'dart:async';

import 'package:bookcart/core/notifications/app_notification_service.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
import 'package:bookcart/logic/cubits/chat_cubit.dart';
import 'package:bookcart/logic/cubits/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationCoordinator extends StatefulWidget {
  const NotificationCoordinator({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationCoordinator> createState() =>
      _NotificationCoordinatorState();
}

class _NotificationCoordinatorState extends State<NotificationCoordinator> {
  bool _started = false;
  bool _hasHydratedThreads = false;
  String? _threadCacheUserId;
  Map<String, String> _knownThreadFingerprints = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) {
        return;
      }

      _started = true;
      unawaited(_startNotifications());
    });
  }

  Future<void> _startNotifications() async {
    await AppNotificationService.instance.initialize();
    if (!mounted) {
      return;
    }
    final userId = context.read<AuthCubit>().state.user?.id;
    await AppNotificationService.instance.bindUser(userId);
    await _bindChatWatch(userId);
  }

  Future<void> _bindChatWatch(String? userId) async {
    _resetThreadCache(userId: userId);
    if (userId == null) {
      await context.read<ChatCubit>().reset();
      return;
    }

    await context.read<ChatCubit>().watchChatsForUser(userId);
  }

  void _resetThreadCache({String? userId}) {
    _threadCacheUserId = userId;
    _hasHydratedThreads = false;
    _knownThreadFingerprints = const {};
  }

  void _handleChatStateChange(BuildContext context, ChatState state) {
    final userId = context.read<AuthCubit>().state.user?.id;
    if (userId == null || state.isLoadingThreads) {
      return;
    }

    if (_threadCacheUserId != userId) {
      _resetThreadCache(userId: userId);
    }

    final nextFingerprints = <String, String>{
      for (final thread in state.threads)
        thread.id:
            '${thread.updatedAt?.microsecondsSinceEpoch ?? 0}|'
            '${thread.lastSenderId}|${thread.lastMessage}',
    };

    if (!_hasHydratedThreads) {
      _hasHydratedThreads = true;
      _knownThreadFingerprints = nextFingerprints;
      return;
    }

    for (final thread in state.threads) {
      final previousFingerprint = _knownThreadFingerprints[thread.id];
      final currentFingerprint = nextFingerprints[thread.id];
      if (previousFingerprint == currentFingerprint) {
        continue;
      }
      if (thread.lastMessage.trim().isEmpty ||
          thread.lastSenderId.trim().isEmpty ||
          thread.lastSenderId == userId) {
        continue;
      }

      AppNotificationService.instance.showInAppChatAlert(
        data: {
          'type': 'chat',
          'chatId': thread.id,
          'senderName': thread.displayNameFor(userId),
          'bookTitle': thread.bookTitle,
          'message': thread.lastMessage,
        },
        title: 'New message from ${thread.displayNameFor(userId)}',
        body: thread.lastMessage,
      );
    }

    _knownThreadFingerprints = nextFingerprints;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_started) {
        return;
      }

      unawaited(AppNotificationService.instance.flushPendingOpen());
    });

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.user?.id != current.user?.id,
          listener: (context, state) {
            unawaited(AppNotificationService.instance.bindUser(state.user?.id));
            unawaited(_bindChatWatch(state.user?.id));
          },
        ),
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (previous, current) =>
              previous.threads != current.threads,
          listener: _handleChatStateChange,
        ),
      ],
      child: widget.child,
    );
  }
}
