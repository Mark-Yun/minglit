import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

class _MockSession extends Mock implements Session {}

late DeletionStatus? _currentDeletionStatus;
late int _checkStatusCalls;
late int _cancelDeletionCalls;
late int _signOutCalls;

class _FakeAccountDeletionController extends AccountDeletionController {
  @override
  FutureOr<DeletionStatus?> build() async => _currentDeletionStatus;

  @override
  Future<DeletionStatus?> checkStatus() async {
    _checkStatusCalls++;
    return _currentDeletionStatus;
  }

  @override
  Future<DeletionStatus?> cancelDeletion() async {
    _cancelDeletionCalls++;
    return _currentDeletionStatus = const DeletionStatus();
  }
}

class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}

  @override
  Future<void> signOut() async {
    _signOutCalls++;
  }
}

void main() {
  late StreamController<AuthState> authStateController;
  late User user;
  late _MockSession session;

  setUp(() {
    authStateController = StreamController<AuthState>.broadcast();
    _currentDeletionStatus = null;
    _checkStatusCalls = 0;
    _cancelDeletionCalls = 0;
    _signOutCalls = 0;
    user = User(
      id: 'partner-1',
      appMetadata: const {
        'provider': 'email',
        'providers': ['email'],
      },
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime(2026).toIso8601String(),
      email: 'partner@test.com',
      identities: const [],
    );
    session = _MockSession();
    when(() => session.user).thenReturn(user);
  });

  tearDown(() async {
    await authStateController.close();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith(
          (_) => authStateController.stream,
        ),
        accountDeletionControllerProvider.overrideWith(
          _FakeAccountDeletionController.new,
        ),
        authControllerProvider.overrideWith(_FakeAuthController.new),
      ],
      child: const MaterialApp(
        home: PendingDeletionRecoveryListener(
          child: Scaffold(body: Text('partner-home')),
        ),
      ),
    );
  }

  testWidgets('pending deletion sign-in can keep deletion and sign out', (
    tester,
  ) async {
    _currentDeletionStatus = DeletionStatus(
      deletedAt: DateTime.now().subtract(const Duration(days: 2)),
      gracePeriodEnds: DateTime.now().add(const Duration(days: 5)),
      isPending: true,
    );

    await tester.pumpWidget(buildSubject());

    authStateController.add(AuthState(AuthChangeEvent.signedIn, session));
    await tester.pumpAndSettle();

    expect(find.text('탈퇴 대기 중인 계정입니다'), findsOneWidget);
    expect(find.textContaining('5일 후 계정이 영구 삭제돼요'), findsOneWidget);

    await tester.tap(find.text('탈퇴 유지'));
    await tester.pumpAndSettle();

    expect(_checkStatusCalls, 1);
    expect(_cancelDeletionCalls, 0);
    expect(_signOutCalls, 1);
  });

  testWidgets('non-pending sign-in does not show recovery dialog', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    authStateController.add(AuthState(AuthChangeEvent.signedIn, session));
    await tester.pumpAndSettle();

    expect(find.text('탈퇴 대기 중인 계정입니다'), findsNothing);
    expect(_checkStatusCalls, 1);
    expect(_cancelDeletionCalls, 0);
    expect(_signOutCalls, 0);
  });
}
