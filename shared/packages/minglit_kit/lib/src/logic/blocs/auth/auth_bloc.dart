import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../data/repositories/auth_repository.dart';
import '../../../utils/log.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<sb.AuthState>? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.initial()) {
    on<AuthEvent>((event, emit) async {
      await event.map(
        checkAuthStatus: (_) => _checkAuthStatus(emit),
        signInWithGoogle: (_) => _signInWithGoogle(emit),
        signOut: (_) => _signOut(emit),
        authChanged: (e) => _authChanged(e.state, emit),
      );
    });

    // BLoC 생성 시 상태 감지 시작
    _authSubscription = _authRepository.onAuthStateChange.listen((data) {
      add(AuthEvent.authChanged(data));
    });
  }

  Future<void> _checkAuthStatus(Emitter<AuthState> emit) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthState.authenticated(user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _signInWithGoogle(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.signInWithGoogle();
      // 성공하면 _onAuthChanged를 통해 상태가 업데이트될 것임
    } catch (e) {
      emit(AuthState.failure(e.toString()));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _signOut(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.signOut();
    } catch (e) {
      emit(AuthState.failure(e.toString()));
    }
  }

  Future<void> _authChanged(sb.AuthState state, Emitter<AuthState> emit) async {
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
    _authSubscription?.cancel();
    return super.close();
  }
}