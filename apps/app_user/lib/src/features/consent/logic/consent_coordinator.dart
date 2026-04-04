import 'package:app_user/src/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'consent_coordinator.g.dart';

@riverpod
ConsentCoordinator consentCoordinator(Ref ref) {
  return ConsentCoordinator(ref.read(goRouterProvider));
}

class ConsentCoordinator {
  ConsentCoordinator(this._router);

  final GoRouter _router;

  void completeSignup({String? from}) {
    final returnTo = _sanitizeReturnLocation(from);
    if (returnTo == null || returnTo == '/') {
      _router.go('/');
    } else {
      // Fix #970: go('/') first to restore home in the back stack, then push
      // the return target so back navigation returns to home instead of exiting.
      _router.go('/');
      _router.push(returnTo);
    }
  }

  String? _sanitizeReturnLocation(String? from) {
    if (from == null || from.isEmpty) return null;
    if (!from.startsWith('/') || from.startsWith('//')) return null;
    if (from.startsWith('/login') || from.startsWith('/signup/consent')) {
      return null;
    }
    return from;
  }
}
