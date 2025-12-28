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
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  /// Trigger Sign-Out
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signOut());
  }
}
