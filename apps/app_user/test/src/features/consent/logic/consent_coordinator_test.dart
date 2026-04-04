import 'package:app_user/src/features/consent/logic/consent_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('completeSignup', () {
    test('from이 null이면 홈(/)으로 이동한다', () {
      _expectNavigatesToHome(from: null);
    });

    test('from이 유효한 경로면 홈 경유 후 해당 경로로 이동한다', () {
      _expectNavigatesViaHome('/tickets/my', from: '/tickets/my');
    });

    test('from이 /my이면 홈 경유 후 /my로 이동한다', () {
      _expectNavigatesViaHome('/my', from: '/my');
    });

    test('from이 /login으로 시작하면 홈(/)으로 이동한다', () {
      _expectNavigatesToHome(from: '/login');
    });

    test('from이 /signup/consent로 시작하면 홈(/)으로 이동한다', () {
      _expectNavigatesToHome(from: '/signup/consent');
    });

    test('from이 빈 문자열이면 홈(/)으로 이동한다', () {
      _expectNavigatesToHome(from: '');
    });

    test('from이 //로 시작하면 홈(/)으로 이동한다', () {
      _expectNavigatesToHome(from: '//evil.com');
    });

    test('from이 /로 시작하지 않으면 홈(/)으로 이동한다', () {
      _expectNavigatesToHome(from: 'https://evil.com');
    });
  });
}

/// Verifies that completeSignup navigates directly to home (go only, no push).
void _expectNavigatesToHome({String? from}) {
  final mockRouter = MockGoRouter();
  ConsentCoordinator(mockRouter).completeSignup(from: from);
  verify(() => mockRouter.go('/')).called(1);
  verifyNever(() => mockRouter.push(any()));
}

/// Verifies that completeSignup navigates home first, then pushes [expectedPath].
/// Fix #970: home route must be in the back stack so back key returns to home
/// instead of exiting the app.
void _expectNavigatesViaHome(String expectedPath, {required String? from}) {
  final mockRouter = MockGoRouter();
  when(() => mockRouter.push(any<String>())).thenAnswer((_) async => null);
  ConsentCoordinator(mockRouter).completeSignup(from: from);
  verify(() => mockRouter.go('/')).called(1);
  verify(() => mockRouter.push(expectedPath)).called(1);
}
