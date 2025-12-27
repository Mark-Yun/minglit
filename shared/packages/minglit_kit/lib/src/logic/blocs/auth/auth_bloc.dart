import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/logic/blocs/auth/auth_event.dart';
import 'package:minglit_kit/src/logic/blocs/auth/auth_state.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// BLoC for managing Global Authentication state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Creates an [AuthBloc] with the given [AuthRepository].
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState.initial()) {
    on<AuthEvent>((event, emit) async {
      await event.map(
        checkAuthStatus: (e) => _onCheckAuthStatus(emit),
        signInWithGoogle: (e) => _onSignInWithGoogle(emit),
        signOut: (e) => _onSignOut(emit),
        authChanged: (e) => _onAuthChanged(e.state, emit),
      );
    });

    // Start listening to auth changes upon creation.
    _authSubscription = _authRepository.onAuthStateChange.listen((data) {
      if (!isClosed) {
        add(AuthEvent.authChanged(data));
      }
    });
  }

  final AuthRepository _authRepository;
  StreamSubscription<sb.AuthState>? _authSubscription;

  Future<void> _onCheckAuthStatus(Emitter<AuthState> emit) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthState.authenticated(user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onSignInWithGoogle(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.signInWithGoogle();
    } on Exception catch (e) {
      emit(AuthState.failure(e.toString()));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onSignOut(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.signOut();
    } on Exception catch (e) {
      emit(AuthState.failure(e.toString()));
    }
  }

  Future<void> _onAuthChanged(
    sb.AuthState state,
    Emitter<AuthState> emit,
  ) async {
    final session = state.session;
    final user = session?.user;

    Log.d('🔄 [AuthBloc] Auth State Changed: ${state.event}');

    if (user != null) {
      emit(AuthState.authenticated(user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  @override
  Future<void> close() {
    unawaited(_authSubscription?.cancel());
    return super.close();
  }
}
