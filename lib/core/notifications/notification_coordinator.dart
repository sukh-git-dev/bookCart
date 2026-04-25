import 'dart:async';

import 'package:bookcart/core/notifications/app_notification_service.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/auth_state.dart';
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
    await AppNotificationService.instance.bindUser(
      context.read<AuthCubit>().state.user?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_started) {
        return;
      }

      unawaited(AppNotificationService.instance.flushPendingOpen());
    });

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.user?.id != current.user?.id,
      listener: (context, state) {
        unawaited(AppNotificationService.instance.bindUser(state.user?.id));
      },
      child: widget.child,
    );
  }
}
