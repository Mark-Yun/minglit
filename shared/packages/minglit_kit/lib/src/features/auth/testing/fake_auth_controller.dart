import 'dart:async';

import 'package:minglit_kit/src/features/auth/logic/auth_controller.dart';

/// Lightweight test double for auth-dependent widget tests.
class FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}
}
