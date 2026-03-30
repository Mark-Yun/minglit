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

  tearDown(() async {
    await authStateController.close();
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
      // ignore: unused_local_variable - Container must be held to keep provider alive.
      final container = createTestContainer()
        ..listen(notificationInitializerProvider, (_, _) {});

      authStateController.add(
        const AuthState(AuthChangeEvent.signedIn, null),
      );

      // Allow microtasks for stream + Riverpod propagation.
      await pumpEventQueue();

      verify(() => mockNotificationService.initialize()).called(1);
    });

    test('does not call initialize() on signedOut event', () async {
      // ignore: unused_local_variable - Container must be held to keep provider alive.
      final container = createTestContainer()
        ..listen(notificationInitializerProvider, (_, _) {});

      authStateController.add(
        const AuthState(AuthChangeEvent.signedOut, null),
      );

      await pumpEventQueue();

      verifyNever(() => mockNotificationService.initialize());
    });

    test('does not call initialize() on tokenRefreshed event', () async {
      // ignore: unused_local_variable - Container must be held to keep provider alive.
      final container = createTestContainer()
        ..listen(notificationInitializerProvider, (_, _) {});

      authStateController.add(
        const AuthState(AuthChangeEvent.tokenRefreshed, null),
      );

      await pumpEventQueue();

      verifyNever(() => mockNotificationService.initialize());
    });

    test('does not call initialize() on passwordRecovery event', () async {
      // ignore: unused_local_variable - Container must be held to keep provider alive.
      final container = createTestContainer()
        ..listen(notificationInitializerProvider, (_, _) {});

      authStateController.add(
        const AuthState(AuthChangeEvent.passwordRecovery, null),
      );

      await pumpEventQueue();

      verifyNever(() => mockNotificationService.initialize());
    });

    test('calls initialize() for each signedIn event', () async {
      // ignore: unused_local_variable - Container must be held to keep provider alive.
      final container = createTestContainer()
        ..listen(notificationInitializerProvider, (_, _) {});

      authStateController
        // ignore: prefer_const_constructors - Non-const needed for distinct stream events.
        ..add(AuthState(AuthChangeEvent.signedIn, null))
        // ignore: prefer_const_constructors - Non-const needed for distinct stream events.
        ..add(AuthState(AuthChangeEvent.signedIn, null));

      await pumpEventQueue();

      verify(() => mockNotificationService.initialize()).called(2);
    });
  });
}
