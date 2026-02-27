import 'package:flutter/foundation.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/utils/log.dart';
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
  Future<void> signInWithGoogle({String? redirectTo}) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithGoogle(
            redirectTo: redirectTo,
          );
      // On Web, the browser redirects. We don't want to trigger "Login Success"
      // navigation in the split second before the page unloads.
      if (!kIsWeb) {
        state = const AsyncData(null);
      }
    } on Object catch (e, st) {
      Log.e('AuthController signInWithGoogle failed', e, st);
      try {
        state = AsyncError(e, st);
      } on Object catch (stateError, stateStackTrace) {
        Log.e(
          'AuthController failed to update signInWithGoogle state',
          stateError,
          stateStackTrace,
        );
      }
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
      Log.e('AuthController signInWithEmail failed', e, st);
      try {
        state = AsyncError(e, st);
      } on Object catch (stateError, stateStackTrace) {
        Log.e(
          'AuthController failed to update signInWithEmail state',
          stateError,
          stateStackTrace,
        );
      }
    }
  }

  /// Trigger Apple Sign-In
  Future<void> signInWithApple({String? redirectTo}) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithApple(
            redirectTo: redirectTo,
          );
      if (!kIsWeb) {
        state = const AsyncData(null);
      }
    } on Object catch (e, st) {
      Log.e('AuthController signInWithApple failed', e, st);
      try {
        state = AsyncError(e, st);
      } on Object catch (stateError, stateStackTrace) {
        Log.e(
          'AuthController failed to update signInWithApple state',
          stateError,
          stateStackTrace,
        );
      }
    }
  }

  /// Trigger Kakao Sign-In
  Future<void> signInWithKakao({String? redirectTo}) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithKakao(
            redirectTo: redirectTo,
          );
      // Kakao uses web OAuth redirect on ALL platforms (mobile and web).
      // Don't set AsyncData — onAuthStateChange
      // triggers navigation after callback.
    } on Object catch (e, st) {
      Log.e('AuthController signInWithKakao failed', e, st);
      try {
        state = AsyncError(e, st);
      } on Object catch (stateError, stateStackTrace) {
        Log.e(
          'AuthController failed to update signInWithKakao state',
          stateError,
          stateStackTrace,
        );
      }
    }
  }

  /// Trigger Sign-Out
  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(null);
    } on Object catch (e, st) {
      Log.e('AuthController signOut failed', e, st);
      try {
        state = AsyncError(e, st);
      } on Object catch (stateError, stateStackTrace) {
        Log.e(
          'AuthController failed to update signOut state',
          stateError,
          stateStackTrace,
        );
      }
    }
  }
}
