import 'package:app_user/src/features/consent/logic/consent_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(() => mockRouter.go(any())).thenReturn(null);
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  group('completeSignup — 홈으로 이동 (push 없음)', () {
    test('from이 null이면 홈(/)으로 go한다', () {
      ConsentCoordinator(mockRouter).completeSignup(from: null);

      verify(() => mockRouter.go('/')).called(1);
      verifyNever(() => mockRouter.push(any()));
    });

    test('from이 빈 문자열이면 홈(/)으로 go한다', () {
      ConsentCoordinator(mockRouter).completeSignup(from: '');

      verify(() => mockRouter.go('/')).called(1);
      verifyNever(() => mockRouter.push(any()));
    });

    test('from이 /이면 홈(/)으로 go한다', () {
      ConsentCoordinator(mockRouter).completeSignup(from: '/');

      verify(() => mockRouter.go('/')).called(1);
      verifyNever(() => mockRouter.push(any()));
    });

    test('from이 /login으로 시작하면 홈(/)으로 go한다', () {
      ConsentCoordinator(mockRouter).completeSignup(from: '/login');

      verify(() => mockRouter.go('/')).called(1);
      verifyNever(() => mockRouter.push(any()));
    });

    test('from이 /signup/consent로 시작하면 홈(/)으로 go한다', () {
      ConsentCoordinator(mockRouter).completeSignup(from: '/signup/consent');

      verify(() => mockRouter.go('/')).called(1);
      verifyNever(() => mockRouter.push(any()));
    });

    test('from이 //로 시작하면 홈(/)으로 go한다', () {
      ConsentCoordinator(mockRouter).completeSignup(from: '//evil.com');

      verify(() => mockRouter.go('/')).called(1);
      verifyNever(() => mockRouter.push(any()));
    });

    test('from이 /로 시작하지 않으면 홈(/)으로 go한다', () {
      ConsentCoordinator(mockRouter).completeSignup(from: 'https://evil.com');

      verify(() => mockRouter.go('/')).called(1);
      verifyNever(() => mockRouter.push(any()));
    });
  });

  group('completeSignup — 목적지로 이동 (back stack 보존)', () {
    // Fix #970: go(destination)은 전체 스택을 교체하므로
    // 먼저 go('/')로 홈을 스택에 anchor한 뒤 push(destination)으로 이동한다.

    test('from이 /my이면 go(/)한 뒤 push(/my)한다', () {
      ConsentCoordinator(mockRouter).completeSignup(from: '/my');

      verifyInOrder([
        () => mockRouter.go('/'),
        () => mockRouter.push('/my'),
      ]);
    });

    test('from이 /tickets/my이면 go(/)한 뒤 push(/tickets/my)한다', () {
      ConsentCoordinator(mockRouter).completeSignup(from: '/tickets/my');

      verifyInOrder([
        () => mockRouter.go('/'),
        () => mockRouter.push('/tickets/my'),
      ]);
    });

    test('from이 /purchase-history이면 go(/)한 뒤 push(/purchase-history)한다', () {
      ConsentCoordinator(mockRouter).completeSignup(from: '/purchase-history');

      verifyInOrder([
        () => mockRouter.go('/'),
        () => mockRouter.push('/purchase-history'),
      ]);
    });
  });
}
