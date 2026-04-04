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
    final destination = _sanitizeReturnLocation(from);
    if (destination == null || destination == '/') {
      _router.go('/');
    } else {
      // Fix #970: go(destination) replaces the entire navigation stack because
      // destination routes (e.g. /my) are top-level and have no implicit parent.
      // Navigate to home first to anchor the back stack, then push the
      // destination on top so the user can press back to return home.
      _router.go('/');
      _router.push(destination);
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
