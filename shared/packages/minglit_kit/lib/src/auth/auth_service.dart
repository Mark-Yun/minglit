import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/log.dart';

class AuthService {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;
  final String? _defaultRedirectUrl;

  AuthService({
    SupabaseClient? supabase,
    String? webClientId, // 웹 구글 로그인용 클라이언트 ID (GCP Console에서 발급)
    String? defaultRedirectUrl,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _defaultRedirectUrl = defaultRedirectUrl,
        _googleSignIn = GoogleSignIn(
          // 웹에서는 clientId가 필요합니다.
          clientId: kIsWeb ? webClientId : null,
          // Android/iOS에서는 google-services.json / Info.plist 설정으로 자동 처리됨
        );

  /// 구글 로그인 진행 및 Supabase 세션 생성
  Future<void> signInWithGoogle() async {
    Log.d('🔐 Google Sign-In started (Web=$kIsWeb)');
    try {
      if (kIsWeb) {
        // 웹에서는 명시적으로 제공된 URL이나 현재 접속한 주소(Origin)를 리다이렉트 URL로 사용
        final redirectTo = _defaultRedirectUrl ?? Uri.base.origin;
        Log.d('🌐 Initiating Supabase OAuth redirect to: $redirectTo');
        
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectTo,
        );
        return;
      }

      // 1. 구글 로그인 네이티브 창 (Mobile) 띄우기
      Log.d('📱 Launching Google Native Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
// ... (나머지 코드 동일)
      
      // 사용자가 취소한 경우
      if (googleUser == null) {
        Log.w('⚠️ Google sign-in cancelled by user');
        throw const AuthException('Google sign-in was cancelled.');
      }
      Log.d('✅ Google Native Sign-In successful: ${googleUser.email}');

      // 2. 인증 정보(Token) 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        Log.e('❌ No ID Token found from Google');
        throw const AuthException('No ID Token found from Google.');
      }
      Log.d('🔑 ID Token retrieved');

      // 3. Supabase에 로그인 요청 (idToken 전달)
      Log.d('🔄 Authenticating with Supabase...');
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      Log.i('🎉 Supabase Sign-In successful!');
    } catch (e, stackTrace) {
      Log.e('❌ Sign-In Error', e, stackTrace);
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    Log.d('🚪 Sign-Out initiated...');
    try {
      await Future.wait([
        _supabase.auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      Log.i('👋 Sign-Out successful');
    } catch (e, stackTrace) {
      Log.e('❌ Sign-Out Error', e, stackTrace);
    }
  }
  
  /// 현재 사용자 정보
  User? get currentUser => _supabase.auth.currentUser;
  
  /// 로그인 상태 스트림 (상태 변화 감지용)
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
}
