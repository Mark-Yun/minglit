import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/notification_repository.dart';
import 'package:minglit_kit/src/features/notification/notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../../helpers/test_utils.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockPermissionHandlerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PermissionHandlerPlatform {}

const _authorizedSettings = NotificationSettings(
  authorizationStatus: AuthorizationStatus.authorized,
  alert: AppleNotificationSetting.enabled,
  announcement: AppleNotificationSetting.disabled,
  badge: AppleNotificationSetting.enabled,
  carPlay: AppleNotificationSetting.disabled,
  lockScreen: AppleNotificationSetting.enabled,
  notificationCenter: AppleNotificationSetting.enabled,
  showPreviews: AppleShowPreviewSetting.always,
  timeSensitive: AppleNotificationSetting.disabled,
  criticalAlert: AppleNotificationSetting.disabled,
  sound: AppleNotificationSetting.enabled,
  providesAppNotificationSettings: AppleNotificationSetting.disabled,
);

const _deniedSettings = NotificationSettings(
  authorizationStatus: AuthorizationStatus.denied,
  alert: AppleNotificationSetting.disabled,
  announcement: AppleNotificationSetting.disabled,
  badge: AppleNotificationSetting.disabled,
  carPlay: AppleNotificationSetting.disabled,
  lockScreen: AppleNotificationSetting.disabled,
  notificationCenter: AppleNotificationSetting.disabled,
  showPreviews: AppleShowPreviewSetting.never,
  timeSensitive: AppleNotificationSetting.disabled,
  criticalAlert: AppleNotificationSetting.disabled,
  sound: AppleNotificationSetting.disabled,
  providesAppNotificationSettings: AppleNotificationSetting.disabled,
);

const _provisionalSettings = NotificationSettings(
  authorizationStatus: AuthorizationStatus.provisional,
  alert: AppleNotificationSetting.enabled,
  announcement: AppleNotificationSetting.disabled,
  badge: AppleNotificationSetting.enabled,
  carPlay: AppleNotificationSetting.disabled,
  lockScreen: AppleNotificationSetting.enabled,
  notificationCenter: AppleNotificationSetting.enabled,
  showPreviews: AppleShowPreviewSetting.always,
  timeSensitive: AppleNotificationSetting.disabled,
  criticalAlert: AppleNotificationSetting.disabled,
  sound: AppleNotificationSetting.enabled,
  providesAppNotificationSettings: AppleNotificationSetting.disabled,
);

void main() {
  late MockNotificationRepository mockRepository;
  late MockFirebaseMessaging mockFcm;
  late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
  late MockPermissionHandlerPlatform mockPermissionHandler;

  NotificationService buildService(ProviderContainer container) {
    return container.read(notificationServiceProvider);
  }

  setUp(() {
    mockRepository = MockNotificationRepository();
    mockFcm = MockFirebaseMessaging();
    mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
    mockPermissionHandler = MockPermissionHandlerPlatform();
    PermissionHandlerPlatform.instance = mockPermissionHandler;
  });

  ProviderContainer createServiceContainer() {
    return createContainer(
      overrides: [
        notificationServiceProvider.overrideWith(
          (ref) => NotificationService(
            mockRepository,
            ref,
            fcm: mockFcm,
            localNotifications: mockLocalNotifications,
          ),
        ),
      ],
    );
  }

  group('_showLocalNotification (#1686)', () {
    test(
      'displays notification when message has no android payload — iOS foreground regression',
      () async {
        // Regression #1686: old code gated on `android != null`, skipping iOS.
        // On non-Android platforms (Linux CI / iOS), Platform.isAndroid = false
        // so the new guard `if (Platform.isAndroid && android == null)` does NOT
        // skip the call. Re-introducing the old guard causes this test to fail.
        when(
          () => mockLocalNotifications.show(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        const message = RemoteMessage(
          notification: RemoteNotification(
            title: 'Test',
            body: 'iOS foreground test',
          ),
          // no AndroidNotification — simulates iOS message
        );

        final service = buildService(createServiceContainer());
        await service.showLocalNotificationForTest(message);

        verify(
          () => mockLocalNotifications.show(
            id: any(named: 'id'),
            title: 'Test',
            body: 'iOS foreground test',
            notificationDetails: any(named: 'notificationDetails'),
            payload: any(named: 'payload'),
          ),
        ).called(1);
      },
    );
  });

  group('_ensureNotificationPermission (#1687)', () {
    test(
      'returns false immediately when permission is permanently denied',
      () async {
        // Regression: permanently denied must not reach Firebase — infinite dialog prevention
        when(
          () => mockPermissionHandler.checkPermissionStatus(
            Permission.notification,
          ),
        ).thenAnswer((_) async => PermissionStatus.permanentlyDenied);

        final service = buildService(createServiceContainer());
        final result = await service.ensureNotificationPermissionForTest();

        expect(result, false);
        verifyNever(() => mockFcm.requestPermission());
      },
    );

    test(
      'requests permission when status is denied, then checks Firebase',
      () async {
        when(
          () => mockPermissionHandler.checkPermissionStatus(
            Permission.notification,
          ),
        ).thenAnswer((_) async => PermissionStatus.denied);
        when(
          () => mockPermissionHandler.requestPermissions([
            Permission.notification,
          ]),
        ).thenAnswer(
          (_) async => {Permission.notification: PermissionStatus.granted},
        );
        when(() => mockFcm.requestPermission()).thenAnswer(
          (_) async => _authorizedSettings,
        );

        final service = buildService(createServiceContainer());
        final result = await service.ensureNotificationPermissionForTest();

        expect(result, true);
        verify(
          () => mockPermissionHandler.requestPermissions([
            Permission.notification,
          ]),
        ).called(1);
        verify(() => mockFcm.requestPermission()).called(1);
      },
    );

    test('skips permission request dialog when already granted', () async {
      when(
        () => mockPermissionHandler.checkPermissionStatus(
          Permission.notification,
        ),
      ).thenAnswer((_) async => PermissionStatus.granted);
      when(() => mockFcm.requestPermission()).thenAnswer(
        (_) async => _authorizedSettings,
      );

      final service = buildService(createServiceContainer());
      await service.ensureNotificationPermissionForTest();

      verifyNever(
        () =>
            mockPermissionHandler.requestPermissions([Permission.notification]),
      );
    });

    test('returns true for provisional Firebase authorization', () async {
      when(
        () => mockPermissionHandler.checkPermissionStatus(
          Permission.notification,
        ),
      ).thenAnswer((_) async => PermissionStatus.granted);
      when(() => mockFcm.requestPermission()).thenAnswer(
        (_) async => _provisionalSettings,
      );

      final service = buildService(createServiceContainer());
      final result = await service.ensureNotificationPermissionForTest();

      expect(result, true);
    });

    test('returns false when Firebase authorization is denied', () async {
      when(
        () => mockPermissionHandler.checkPermissionStatus(
          Permission.notification,
        ),
      ).thenAnswer((_) async => PermissionStatus.granted);
      when(() => mockFcm.requestPermission()).thenAnswer(
        (_) async => _deniedSettings,
      );

      final service = buildService(createServiceContainer());
      final result = await service.ensureNotificationPermissionForTest();

      expect(result, false);
    });

    // Regression: before fix, request() result was discarded — user denying
    // the runtime dialog was not detected, and Firebase was called anyway.
    test(
      'returns false and skips Firebase when user denies runtime dialog',
      () async {
        when(
          () => mockPermissionHandler.checkPermissionStatus(
            Permission.notification,
          ),
        ).thenAnswer((_) async => PermissionStatus.denied);
        when(
          () => mockPermissionHandler.requestPermissions([
            Permission.notification,
          ]),
        ).thenAnswer(
          (_) async => {Permission.notification: PermissionStatus.denied},
        );

        final service = buildService(createServiceContainer());
        final result = await service.ensureNotificationPermissionForTest();

        expect(result, false);
        verifyNever(() => mockFcm.requestPermission());
      },
    );
  });
}
