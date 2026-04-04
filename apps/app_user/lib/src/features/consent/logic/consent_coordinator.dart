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
    _router.go(_sanitizeReturnLocation(from) ?? '/');
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
