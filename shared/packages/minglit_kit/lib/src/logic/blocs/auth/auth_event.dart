import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart' show AuthBloc;
import 'package:minglit_kit/src/logic/blocs/auth/auth_bloc.dart' show AuthBloc;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

part 'auth_event.freezed.dart';

/// Events for [AuthBloc].
@freezed
class AuthEvent with _$AuthEvent {
  /// Initial check of current authentication status.
  const factory AuthEvent.checkAuthStatus() = _CheckAuthStatus;

  /// Request to sign in with Google.
  const factory AuthEvent.signInWithGoogle() = _SignInWithGoogle;

  /// Request to sign out.
  const factory AuthEvent.signOut() = _SignOut;

  /// Triggered when Supabase auth state changes.
  const factory AuthEvent.authChanged(sb.AuthState state) = _AuthChanged;
}
