import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/staff_repository.dart';
import 'package:minglit_kit/src/features/auth/ui/staff_guard_wrapper.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mocks.dart';

class MockStaffRepository extends Mock implements StaffRepository {}

class MockSession extends Mock implements Session {}

void main() {
  group('StaffGuardWrapper', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockStaffRepository mockStaffRepo;
    late StreamController<AuthState> authStreamController;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockStaffRepo = MockStaffRepository();
      authStreamController = StreamController<AuthState>.broadcast();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.onAuthStateChange)
          .thenAnswer((_) => authStreamController.stream);
      when(() => mockStaffRepo.verifyStaffStatus())
          .thenAnswer((_) async => null);
    });

    tearDown(() async {
      await authStreamController.close();
    });

    Widget buildSubject({Widget? child}) {
      return ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWith((ref) => mockClient),
          staffRepositoryProvider.overrideWith((ref) => mockStaffRepo),
        ],
        child: MaterialApp(
          home: StaffGuardWrapper(
            child: child ?? const Text('Protected Content'),
          ),
        ),
      );
    }

    // Fix #487: kIsWeb is always false in test (IO) env, so the guard is
    // bypassed and child is rendered directly. Web-specific paths (showing
    // StaffGateScreen) cannot be exercised in standard Flutter unit tests.

    testWidgets(
      'renders child directly in non-web environment (kIsWeb=false)',
      (tester) async {
        await tester.pumpWidget(buildSubject());

        expect(find.text('Protected Content'), findsOneWidget);
        expect(find.byType(StaffGuardWrapper), findsOneWidget);
      },
    );

    testWidgets(
      'subscribes to auth.onAuthStateChange on init',
      (tester) async {
        await tester.pumpWidget(buildSubject());

        verify(() => mockAuth.onAuthStateChange).called(1);
      },
    );

    testWidgets(
      'auth change with @minglit.com email saves staff token',
      (tester) async {
        final mockUser = MockUser();
        when(() => mockUser.email).thenReturn('staff@minglit.com');

        final mockSession = MockSession();
        when(() => mockSession.user).thenReturn(mockUser);
        when(() => mockSession.accessToken).thenReturn('test-token');
        when(() => mockStaffRepo.saveStaffToken('test-token'))
            .thenAnswer((_) async {});

        await tester.pumpWidget(buildSubject());

        authStreamController.add(
          AuthState(AuthChangeEvent.signedIn, mockSession),
        );
        await tester.pump();

        verify(() => mockStaffRepo.saveStaffToken('test-token')).called(1);
      },
    );

    testWidgets(
      'auth change with non-minglit email does not save staff token',
      (tester) async {
        final mockUser = MockUser();
        when(() => mockUser.email).thenReturn('user@gmail.com');

        final mockSession = MockSession();
        when(() => mockSession.user).thenReturn(mockUser);

        await tester.pumpWidget(buildSubject());

        authStreamController.add(
          AuthState(AuthChangeEvent.signedIn, mockSession),
        );
        await tester.pump();

        verifyNever(() => mockStaffRepo.saveStaffToken(any()));
      },
    );

    testWidgets(
      'auth change with null email does not save staff token',
      (tester) async {
        final mockUser = MockUser();
        when(() => mockUser.email).thenReturn(null);

        final mockSession = MockSession();
        when(() => mockSession.user).thenReturn(mockUser);

        await tester.pumpWidget(buildSubject());

        authStreamController.add(
          AuthState(AuthChangeEvent.signedIn, mockSession),
        );
        await tester.pump();

        verifyNever(() => mockStaffRepo.saveStaffToken(any()));
      },
    );

    testWidgets(
      'auth change with null session does not save staff token',
      (tester) async {
        await tester.pumpWidget(buildSubject());

        authStreamController.add(
          const AuthState(AuthChangeEvent.signedOut, null),
        );
        await tester.pump();

        verifyNever(() => mockStaffRepo.saveStaffToken(any()));
      },
    );

    testWidgets(
      'cancels auth subscription on dispose',
      (tester) async {
        expect(authStreamController.hasListener, isFalse);

        await tester.pumpWidget(buildSubject());
        expect(authStreamController.hasListener, isTrue);

        // Dispose the widget by replacing it with an empty container.
        await tester.pumpWidget(const SizedBox.shrink());
        expect(authStreamController.hasListener, isFalse);
      },
    );

    testWidgets(
      'still renders child widget even when staffGuard has data',
      (tester) async {
        final mockUser = MockUser();
        when(() => mockStaffRepo.verifyStaffStatus())
            .thenAnswer((_) async => mockUser);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // In non-web env, child is always shown regardless of staff status
        expect(find.text('Protected Content'), findsOneWidget);
      },
    );
  });
}
