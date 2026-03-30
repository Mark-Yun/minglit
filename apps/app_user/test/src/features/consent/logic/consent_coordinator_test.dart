import 'package:app_user/src/features/consent/logic/consent_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('completeSignup', () {
    test('from이 null이면 홈(/)으로 이동한다', () {
      _expectNavigatesTo('/');
    });

    test('from이 유효한 경로면 해당 경로로 이동한다', () {
      _expectNavigatesTo('/tickets/my', from: '/tickets/my');
    });

    test('from이 /login으로 시작하면 홈(/)으로 이동한다', () {
      _expectNavigatesTo('/', from: '/login');
    });

    test('from이 /signup/consent로 시작하면 홈(/)으로 이동한다', () {
      _expectNavigatesTo('/', from: '/signup/consent');
    });

    test('from이 빈 문자열이면 홈(/)으로 이동한다', () {
      _expectNavigatesTo('/', from: '');
    });

    test('from이 //로 시작하면 홈(/)으로 이동한다', () {
      _expectNavigatesTo('/', from: '//evil.com');
    });

    test('from이 /로 시작하지 않으면 홈(/)으로 이동한다', () {
      _expectNavigatesTo('/', from: 'https://evil.com');
    });
  });
}

void _expectNavigatesTo(String expectedPath, {String? from}) {
  final mockRouter = MockGoRouter();
  ConsentCoordinator(mockRouter).completeSignup(from: from);

  verify(() => mockRouter.go(expectedPath)).called(1);
}
