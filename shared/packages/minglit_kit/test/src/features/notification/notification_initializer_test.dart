import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/notification/notification_initializer.dart';
import 'package:minglit_kit/src/features/notification/notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/test_utils.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockNotificationService mockNotificationService;
  late StreamController<AuthState> authStateController;

  setUp(() {
    mockNotificationService = MockNotificationService();
    authStateController = StreamController<AuthState>();

    when(() => mockNotificationService.initialize()).thenAnswer((_) async {});
  });

  tearDown(() {
    authStateController.close();
  });

  ProviderContainer createTestContainer() {
    return createContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => authStateController.stream,
        ),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
      ],
    );
  }

  group('notificationInitializerProvider', () {
    test('calls initialize() on signedIn event', () async {
      final container = createTestContainer();

      // Use listen to keep the provider alive and active.
      container.listen(notificationInitializerProvider, (_, __) {});

      authStateController.add(
        AuthState(AuthChangeEvent.signedIn, null),
      );

      // Allow microtasks for stream + Riverpod propagation.
      await pumpEventQueue();

      verify(() => mockNotificationService.initialize()).called(1);
    });

    test('does not call initialize() on signedOut event', () async {
      final container = createTestContainer();
      container.listen(notificationInitializerProvider, (_, __) {});

      authStateController.add(
        AuthState(AuthChangeEvent.signedOut, null),
      );

      await pumpEventQueue();

      verifyNever(() => mockNotificationService.initialize());
    });

    test('does not call initialize() on tokenRefreshed event', () async {
      final container = createTestContainer();
      container.listen(notificationInitializerProvider, (_, __) {});

      authStateController.add(
        AuthState(AuthChangeEvent.tokenRefreshed, null),
      );

      await pumpEventQueue();

      verifyNever(() => mockNotificationService.initialize());
    });

    test('does not call initialize() on passwordRecovery event', () async {
      final container = createTestContainer();
      container.listen(notificationInitializerProvider, (_, __) {});

      authStateController.add(
        AuthState(AuthChangeEvent.passwordRecovery, null),
      );

      await pumpEventQueue();

      verifyNever(() => mockNotificationService.initialize());
    });

    test('calls initialize() for each signedIn event', () async {
      final container = createTestContainer();
      container.listen(notificationInitializerProvider, (_, __) {});

      authStateController
        ..add(AuthState(AuthChangeEvent.signedIn, null))
        ..add(AuthState(AuthChangeEvent.signedIn, null));

      await pumpEventQueue();

      verify(() => mockNotificationService.initialize()).called(2);
    });
  });
}
