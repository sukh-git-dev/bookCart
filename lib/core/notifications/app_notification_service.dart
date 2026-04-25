import 'dart:async';
import 'dart:convert';

import 'package:bookcart/core/config/firebase_bootstrap.dart';
import 'package:bookcart/logic/cubits/auth_cubit.dart';
import 'package:bookcart/logic/cubits/book_cubit.dart';
import 'package:bookcart/logic/cubits/chat_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const AndroidNotificationChannel _chatChannel = AndroidNotificationChannel(
  'bookcart_chat',
  'BookCart Chat',
  description: 'New chat messages and buyer replies.',
  importance: Importance.high,
);

const AndroidNotificationChannel _callChannel = AndroidNotificationChannel(
  'bookcart_call',
  'BookCart Calls',
  description: 'High priority incoming call alerts.',
  importance: Importance.max,
);

const String _chatType = 'chat';
const String _callType = 'call';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  debugPrint(
    '[FCM] Background message received: '
    'id=${message.messageId}, data=${message.data}',
  );
  await AppNotificationService.instance.showBackgroundNotification(message);
}

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  StreamSubscription<RemoteMessage>? _foregroundMessagesSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _isInitialized = false;
  bool _isLocalNotificationsReady = false;
  String? _activeUserId;
  String? _currentToken;
  Map<String, dynamic>? _pendingOpenPayload;
  String? _lastChatAlertSignature;
  DateTime? _lastChatAlertAt;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      return;
    }

    _isInitialized = true;

    await _requestPermissions();
    await _initializeLocalNotifications();
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    _foregroundMessagesSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _log('FCM token refreshed: $token');
      unawaited(_syncCurrentUserToken());
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _log(
        'App opened from terminated notification: '
        'id=${initialMessage.messageId}, data=${initialMessage.data}',
      );
      _scheduleOpen(initialMessage.data);
    }

    _currentToken = await _messaging.getToken();
    _log('FCM token: ${_currentToken ?? 'null'}');
    await _syncCurrentUserToken();
  }

  Future<void> bindUser(String? userId) async {
    if (kIsWeb) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      return;
    }

    final previousUserId = _activeUserId;
    _activeUserId = _normalizeString(userId);
    _log('Binding notifications to user: ${_activeUserId ?? 'none'}');

    _currentToken ??= await _messaging.getToken();
    if (_currentToken != null) {
      _log('Using FCM token: $_currentToken');
    }

    final token = _currentToken;
    if (previousUserId != null &&
        previousUserId != _activeUserId &&
        token != null) {
      await _removeToken(previousUserId, token);
    }

    await _syncCurrentUserToken();
    await flushPendingOpen();
  }

  Future<void> flushPendingOpen() async {
    final payload = _pendingOpenPayload;
    if (payload == null) {
      return;
    }

    _pendingOpenPayload = null;
    _scheduleOpen(payload);
  }

  Future<void> showBackgroundNotification(RemoteMessage message) async {
    if (kIsWeb || message.notification != null) {
      return;
    }

    await _initializeLocalNotifications();
    await _showLocalNotification(message);
  }

  Future<void> dispose() async {
    await _foregroundMessagesSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _log(
      'Permission status: ${settings.authorizationStatus.name}, '
      'alert=${settings.alert}, badge=${settings.badge}, sound=${settings.sound}',
    );
  }

  Future<void> _initializeLocalNotifications() async {
    if (_isLocalNotificationsReady || kIsWeb) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: false,
        defaultPresentBanner: false,
        defaultPresentList: false,
      ),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_chatChannel);
    await androidPlugin?.createNotificationChannel(_callChannel);

    _isLocalNotificationsReady = true;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _log(
      'Foreground message received: '
      'id=${message.messageId}, title=${message.notification?.title}, '
      'body=${message.notification?.body}, data=${message.data}',
    );
    if (_notificationType(message.data) == _chatType) {
      _showChatSnackBar(message);
      return;
    }

    unawaited(_showLocalNotification(message));
  }

  void _handleOpenedMessage(RemoteMessage message) {
    _log(
      'Notification tapped: '
      'id=${message.messageId}, data=${message.data}',
    );
    _scheduleOpen(message.data);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _scheduleOpen(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (_) {
      return;
    }
  }

  void _showChatSnackBar(RemoteMessage message) {
    showInAppChatAlert(
      data: message.data,
      title: _notificationTitle(message),
      body: _notificationBody(message),
    );
  }

  void showInAppChatAlert({
    required Map<String, dynamic> data,
    String? title,
    String? body,
  }) {
    final chatId = _normalizeString(data['chatId']);
    if (_isCurrentConversationVisible(chatId)) {
      return;
    }

    final text = [
      if (title != null && title.isNotEmpty) title,
      if (body != null && body.isNotEmpty) body,
    ].join('\n');
    if (text.trim().isEmpty) {
      return;
    }

    final signature = '${chatId ?? ''}|$text';
    final now = DateTime.now();
    if (_lastChatAlertSignature == signature &&
        _lastChatAlertAt != null &&
        now.difference(_lastChatAlertAt!).inSeconds < 2) {
      return;
    }
    _lastChatAlertSignature = signature;
    _lastChatAlertAt = now;

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: Text(text),
          action: chatId == null
              ? null
              : SnackBarAction(
                  label: 'Open',
                  onPressed: () => _scheduleOpen(data),
                ),
        ),
      );
  }

  bool _isCurrentConversationVisible(String? chatId) {
    final context = navigatorKey.currentContext;
    if (context == null || chatId == null) {
      return false;
    }

    try {
      final bookState = context.read<BookCubit>().state;
      final chatState = context.read<ChatCubit>().state;
      return bookState.currentTabIndex == 3 &&
          chatState.selectedThreadId == chatId;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) {
      return;
    }

    await _initializeLocalNotifications();

    final title = _notificationTitle(message);
    final body = _notificationBody(message);
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final type = _notificationType(message.data);
    final chatId = _normalizeString(message.data['chatId']);
    final notificationId =
        message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
    _log(
      'Showing local notification: '
      'id=$notificationId, type=$type, chatId=${chatId ?? 'none'}',
    );

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          type == _callType ? _callChannel.id : _chatChannel.id,
          type == _callType ? _callChannel.name : _chatChannel.name,
          channelDescription: type == _callType
              ? _callChannel.description
              : _chatChannel.description,
          category: type == _callType
              ? AndroidNotificationCategory.call
              : AndroidNotificationCategory.message,
          importance: type == _callType ? Importance.max : Importance.high,
          priority: type == _callType ? Priority.max : Priority.high,
          fullScreenIntent: type == _callType,
          ticker: type == _callType
              ? 'Incoming BookCart call'
              : 'New BookCart chat message',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          threadIdentifier: chatId,
          interruptionLevel: type == _callType
              ? InterruptionLevel.timeSensitive
              : InterruptionLevel.active,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  String _notificationType(Map<String, dynamic> data) {
    final type = _normalizeString(data['type'])?.toLowerCase();
    if (type == _callType) {
      return _callType;
    }
    if (type == _chatType || _normalizeString(data['chatId']) != null) {
      return _chatType;
    }
    return 'general';
  }

  String? _notificationTitle(RemoteMessage message) {
    final notification = message.notification;
    if (notification?.title != null && notification!.title!.trim().isNotEmpty) {
      return notification.title!.trim();
    }

    final data = message.data;
    final type = _notificationType(data);
    if (type == _callType) {
      final callerName =
          _normalizeString(data['callerName']) ??
          _normalizeString(data['senderName']) ??
          'Book buyer';
      return 'Incoming call from $callerName';
    }

    if (type == _chatType) {
      final senderName = _normalizeString(data['senderName']) ?? 'Book buyer';
      return 'New message from $senderName';
    }

    return _normalizeString(data['title']) ?? 'Book Cart';
  }

  String? _notificationBody(RemoteMessage message) {
    final notification = message.notification;
    if (notification?.body != null && notification!.body!.trim().isNotEmpty) {
      return notification.body!.trim();
    }

    final data = message.data;
    final type = _notificationType(data);
    if (type == _callType) {
      final bookTitle = _normalizeString(data['bookTitle']) ?? 'your listing';
      return 'Tap to open the chat for $bookTitle.';
    }

    if (type == _chatType) {
      return _normalizeString(data['message']) ??
          _normalizeString(data['text']) ??
          'Open the app to view the latest message.';
    }

    return _normalizeString(data['body']);
  }

  void _scheduleOpen(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _pendingOpenPayload = Map<String, dynamic>.from(data);
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (!authState.isAuthenticated) {
      _pendingOpenPayload = Map<String, dynamic>.from(data);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nextContext = navigatorKey.currentContext;
      if (nextContext == null) {
        _pendingOpenPayload = Map<String, dynamic>.from(data);
        return;
      }

      Navigator.of(nextContext).popUntil((route) => route.isFirst);
      nextContext.read<BookCubit>().changeTab(3);

      final chatId = _normalizeString(data['chatId']);
      if (chatId != null) {
        unawaited(nextContext.read<ChatCubit>().selectThread(chatId));
      }
    });
  }

  Future<void> _syncCurrentUserToken() async {
    final userId = _activeUserId;
    final token = _currentToken;
    if (userId == null || token == null || token.isEmpty) {
      _log(
        'Skipping token sync. '
        'userId=${userId ?? 'null'}, tokenPresent=${token?.isNotEmpty ?? false}',
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(userId).set({
        'notificationTokens': FieldValue.arrayUnion([token]),
        'notificationPlatform': defaultTargetPlatform.name,
        'notificationsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _log('Saved FCM token to Firestore for user $userId');
    } catch (error) {
      _log('Failed to save FCM token for user $userId: $error');
    }
  }

  Future<void> _removeToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'notificationTokens': FieldValue.arrayRemove([token]),
        'notificationsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _log('Removed FCM token for previous user $userId');
    } catch (error) {
      _log('Failed to remove FCM token for user $userId: $error');
    }
  }

  String? _normalizeString(Object? value) {
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  void _log(String message) {
    debugPrint('[FCM] $message');
  }
}
