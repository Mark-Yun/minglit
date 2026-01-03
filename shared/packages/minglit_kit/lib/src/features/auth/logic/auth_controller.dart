import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

/// Controller for authentication actions (Sign In, Sign Out).
/// Handles the state of the *request* (loading, error, success).
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {
    // No initial state to load
  }

  /// Trigger Google Sign-In
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncData(null);
    } on Object catch (e, st) {
      try {
        state = AsyncError(e, st);
      } on Object catch (_) {}
    }
  }

  /// Trigger Email Sign-In (Dev/Test)
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(
            email: email,
            password: password,
          );
      // Success: Do nothing. Auth state change will trigger UI updates/redirects.
      // Setting state here causes 'disposed' error if redirect happens fast.
    } on Object catch (e, st) {
      try {
        state = AsyncError(e, st);
      } on Object catch (_) {}
    }
  }

  /// Trigger Sign-Out
  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(null);
    } on Object catch (e, st) {
      try {
        state = AsyncError(e, st);
      } on Object catch (_) {}
    }
  }
}
