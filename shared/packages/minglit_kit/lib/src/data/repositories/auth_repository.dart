import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/log.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;
  final String? _defaultRedirectUrl;

  AuthRepository({
    SupabaseClient? supabase,
    String? webClientId,
    String? defaultRedirectUrl,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _defaultRedirectUrl = defaultRedirectUrl,
        _googleSignIn = GoogleSignIn(
          clientId: kIsWeb ? webClientId : null,
        );

  /// 현재 로그인된 사용자 반환
  User? get currentUser => _supabase.auth.currentUser;

  /// 인증 상태 변경 스트림
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// 구글 로그인
  Future<void> signInWithGoogle() async {
    Log.d('🔐 [AuthRepo] Google Sign-In started (Web=$kIsWeb)');
    try {
      if (kIsWeb) {
        final redirectTo = _defaultRedirectUrl ?? Uri.base.origin;
        Log.d('🌐 [AuthRepo] OAuth redirect to: $redirectTo');
        
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectTo,
        );
        return;
      }

      // Mobile
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException('No ID Token found from Google.');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      Log.i('🎉 [AuthRepo] Supabase Sign-In successful!');
    } catch (e, stackTrace) {
      Log.e('❌ [AuthRepo] Sign-In Error', e, stackTrace);
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      await Future.wait([
        _supabase.auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      Log.i('👋 [AuthRepo] Sign-Out successful');
    } catch (e, stackTrace) {
      Log.e('❌ [AuthRepo] Sign-Out Error', e, stackTrace);
      rethrow;
    }
  }
}
