import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart' show AuthBloc;
import 'package:minglit_kit/src/logic/blocs/auth/auth_bloc.dart' show AuthBloc;
import 'package:supabase_flutter/supabase_flutter.dart' show User;

part 'auth_state.freezed.dart';

/// States for [AuthBloc].
@freezed
class AuthState with _$AuthState {
  /// Initial state.
  const factory AuthState.initial() = _Initial;

  /// Loading state during authentication.
  const factory AuthState.loading() = _Loading;

  /// User is successfully authenticated.
  const factory AuthState.authenticated(User user) = _Authenticated;

  /// User is not logged in.
  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// Authentication process failed.
  const factory AuthState.failure(Failure failure) = _Failure;
}
