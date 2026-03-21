import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/notification_repository.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';

/// Provides the notification repository instance.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

/// Handles deep links triggered by notifications.
typedef NotificationDeepLinkHandler = void Function(String link);

/// Provides the notification deep link handler.
final notificationDeepLinkHandlerProvider =
    Provider<NotificationDeepLinkHandler>((_) {
  return (_) {};
});

/// Provides the notification service instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    ref.watch(notificationRepositoryProvider),
    ref,
  );
});

/// Manages FCM registration, local notifications, and deep links.
class NotificationService {
  /// Creates a notification service bound to [NotificationRepository].
  NotificationService(this._repository, this._ref);

  final NotificationRepository _repository;
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  /// Initializes permissions, token registration, and handlers.
  Future<void> initialize() async {
    // 1. Request Permission
    final settings = await _fcm.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('User granted permission');
    } else {
      _logger.w('User declined or has not accepted permission');
      return;
    }

    // 2. Setup Local Notifications (for foreground display)
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // TODO(Notification): Add iOS settings
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleDeepLink(details.payload);
      },
    );

    // 3. Get Token & Register
    final token = await _fcm.getToken();
    if (token != null) {
      unawaited(_registerToken(token));
    }

    // 4. Listen for Token Refresh
    _fcm.onTokenRefresh.listen((token) {
      unawaited(_registerToken(token));
    });

    // 5. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((message) {
      _logger
        ..d('Got a message whilst in the foreground!')
        ..d('Message data: ${message.data}');

      if (message.notification != null) {
        unawaited(_showLocalNotification(message));
      }
    });

    // 6. Background Message Tap Handler
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleDeepLink(message.data['deep_link'] as String?);
    });

    // 7. Terminated State Message Check
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleDeepLink(initialMessage.data['deep_link'] as String?);
    }
  }

  Future<void> _registerToken(String token) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      await _repository.upsertToken(
        userId: user.id,
        token: token,
        deviceType: deviceType,
      );
      _logger.i('FCM Token registered: $token');
    } on Object catch (e) {
      _logger.e('Failed to register FCM token', error: e);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'minglit_channel_default',
            '기본 알림',
            channelDescription: '중요한 알림을 받습니다.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['deep_link'] as String?,
      );
    }
  }

  void _handleDeepLink(String? link) {
    final trimmed = link?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _logger.w('딥링크가 비어 있습니다.');
      return;
    }

    if (!trimmed.startsWith('/')) {
      _logger.w('딥링크 형식이 올바르지 않습니다: $trimmed');
      return;
    }

    final handler = _ref.read(notificationDeepLinkHandlerProvider);
    handler(trimmed);
  }

  // 로그인 성공 시 호출할 메서드
  /// Registers the token after a successful user login.
  Future<void> onUserLogin() async {
    final token = await _fcm.getToken();
    if (token != null) {
      unawaited(_registerToken(token));
    }
  }
}
