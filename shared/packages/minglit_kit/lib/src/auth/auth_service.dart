import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  AuthService({
    SupabaseClient? supabase,
    String? webClientId, // 웹 구글 로그인용 클라이언트 ID (GCP Console에서 발급)
  })  : _supabase = supabase ?? Supabase.instance.client,
        _googleSignIn = GoogleSignIn(
          // 웹에서는 clientId가 필요합니다.
          clientId: kIsWeb ? webClientId : null,
          // Android/iOS에서는 google-services.json / Info.plist 설정으로 자동 처리됨
        );

  /// 구글 로그인 진행 및 Supabase 세션 생성
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // 웹에서는 Supabase OAuth 리다이렉트 방식 사용 (디자인 자유도와 안정성 확보)
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
        );
        return;
      }

      // 1. 구글 로그인 네이티브 창 (Mobile) 띄우기
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // 사용자가 취소한 경우
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled.');
      }

      // 2. 인증 정보(Token) 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException('No ID Token found from Google.');
      }

      // 3. Supabase에 로그인 요청 (idToken 전달)
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      // 에러 전파 (UI에서 처리)
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
    } catch (e) {
      // 로그아웃 중 에러는 무시하거나 로깅
      print('Sign out error: $e');
    }
  }
  
  /// 현재 사용자 정보
  User? get currentUser => _supabase.auth.currentUser;
  
  /// 로그인 상태 스트림 (상태 변화 감지용)
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
}
