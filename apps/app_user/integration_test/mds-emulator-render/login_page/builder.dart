// LoginPageBuilder — login_page 전용 fluent API.

import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/logic/auth_coordinator.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';
import '../_mocks/notifiers.dart';

class LoginPageBuilder extends MdsScreenBuilder<LoginPage> {
  LoginPageBuilder()
    : super(
        page: const LoginPage(),
        base: [
          authControllerProvider.overrideWith(IdleAuthController.new),
          authCoordinatorProvider.overrideWithValue(MockAuthCoordinator()),
        ],
      );

  /// 다크 모드 토글.
  LoginPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
