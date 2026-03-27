@Tags(['golden'])
library;

import 'dart:async';

import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

void main() {
  group('MyPage golden', () {
    testWidgets('logged out state', (tester) async {
      final mockAuth = MockAuthCoordinator();

      await expectPageGolden(
        tester,
        page: const MyPage(),
        goldenFileName: 'goldens/my_page_logged_out.png',
        overrides: [
          authCoordinatorProvider.overrideWithValue(mockAuth),
        ],
      );
    });

    testWidgets('logged in state', (tester) async {
      final mockAuth = MockAuthCoordinator();
      final mockHome = MockHomeCoordinator();

      await expectPageGolden(
        tester,
        page: const MyPage(),
        goldenFileName: 'goldens/my_page_logged_in.png',
        currentUser: const User(
          id: 'u1',
          appMetadata: {},
          userMetadata: {
            'full_name': '홍길동',
            'avatar_url': null,
          },
          aud: 'authenticated',
          createdAt: '2026-01-01T00:00:00.000Z',
          email: 'test@minglit.com',
        ),
        overrides: [
          authCoordinatorProvider.overrideWithValue(mockAuth),
          homeCoordinatorProvider.overrideWithValue(mockHome),
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
      );
    });

    testWidgets('logged out state (dark)', (tester) async {
      final mockAuth = MockAuthCoordinator();

      await expectPageGolden(
        tester,
        page: const MyPage(),
        goldenFileName: 'goldens/my_page_logged_out_dark.png',
        overrides: [
          authCoordinatorProvider.overrideWithValue(mockAuth),
        ],
        brightness: Brightness.dark,
      );
    });

    testWidgets('logged in state (dark)', (tester) async {
      final mockAuth = MockAuthCoordinator();
      final mockHome = MockHomeCoordinator();

      await expectPageGolden(
        tester,
        page: const MyPage(),
        goldenFileName: 'goldens/my_page_logged_in_dark.png',
        currentUser: const User(
          id: 'u1',
          appMetadata: {},
          userMetadata: {
            'full_name': '홍길동',
            'avatar_url': null,
          },
          aud: 'authenticated',
          createdAt: '2026-01-01T00:00:00.000Z',
          email: 'test@minglit.com',
        ),
        overrides: [
          authCoordinatorProvider.overrideWithValue(mockAuth),
          homeCoordinatorProvider.overrideWithValue(mockHome),
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        brightness: Brightness.dark,
      );
    });
  });
}

class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}
}
