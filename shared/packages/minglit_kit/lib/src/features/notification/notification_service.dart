import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/repositories/notification_repository.dart';
import 'package:minglit_kit/src/logic/providers/auth_provider.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:logger/logger.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    ref.watch(notificationRepositoryProvider),
    ref,
  );
});

class NotificationService {
  final NotificationRepository _repository;
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  NotificationService(this._repository, this._ref);

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('User granted permission');
    } else {
      _logger.w('User declined or has not accepted permission');
      return;
    }

    // 2. Setup Local Notifications (for foreground display)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // TODO: Add iOS settings
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // TODO: Handle foreground notification tap (deep link)
        _handleDeepLink(details.payload);
      },
    );

    // 3. Get Token & Register
    String? token = await _fcm.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // 4. Listen for Token Refresh
    _fcm.onTokenRefresh.listen(_registerToken);

    // 5. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.d('Got a message whilst in the foreground!');
      _logger.d('Message data: ${message.data}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 6. Background Message Tap Handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       _handleDeepLink(message.data['deep_link']);
    });
    
    // 7. Terminated State Message Check
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleDeepLink(initialMessage.data['deep_link']);
    }
  }

  Future<void> _registerToken(String token) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return; // 로그인 상태가 아니면 등록하지 않음 (로그인 시 다시 호출 필요)

    try {
      String deviceType = Platform.isAndroid ? 'android' : 'ios';
      // Web 처리는 별도 필요
      
      await _repository.upsertToken(
        userId: user.id,
        token: token,
        deviceType: deviceType,
      );
      _logger.i('FCM Token registered: $token');
    } catch (e) {
      _logger.e('Failed to register FCM token', error: e);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'minglit_channel_default', // Channel ID
            '기본 알림', // Channel Name
            channelDescription: '중요한 알림을 받습니다.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['deep_link'],
      );
    }
  }

  void _handleDeepLink(String? link) {
    if (link != null) {
      // TODO: Use GoRouter to navigate
      _logger.i('Navigate to deep link: $link');
      // ref.read(routerProvider).push(link); 
      // Router 접근이 어려울 수 있으므로, 별도 StreamController나 Listener 패턴 사용 권장
    }
  }
  
  // 로그인 성공 시 호출할 메서드
  Future<void> onUserLogin() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await _registerToken(token);
    }
  }
}
