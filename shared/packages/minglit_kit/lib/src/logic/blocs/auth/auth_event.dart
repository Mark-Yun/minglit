import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

part 'auth_event.freezed.dart';

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.checkAuthStatus() = _CheckAuthStatus;
  const factory AuthEvent.signInWithGoogle() = _SignInWithGoogle;
  const factory AuthEvent.signOut() = _SignOut;
  const factory AuthEvent.authChanged(sb.AuthState state) = _AuthChanged;
}