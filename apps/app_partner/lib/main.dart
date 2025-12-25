import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/features/verification/review_verification_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );
  
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
  );

  // 서비스 로케이터 초기화
  setupLocator(googleWebClientId: googleWebClientId);

  runApp(const MinglitPartnerApp());
}

class MinglitPartnerApp extends StatelessWidget {
  const MinglitPartnerApp({super.key});

  /// 앱 초기화 프로세스
  Future<void> _initialize() async {
    // 폰트 로딩 대기
    await GoogleFonts.pendingFonts([
      GoogleFonts.poppins(),
      GoogleFonts.notoSansKr(),
    ]);
    
    if (kDebugMode) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minglit Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7043), // Orange
          primary: const Color(0xFFFF7043),
          secondary: const Color(0xFF1A237E),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      home: FutureBuilder(
        future: _initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MinglitSplashScreen(appName: 'Partner', isPartner: true);
          }
          return kDebugMode ? const PartnerDevMap() : const AuthWrapper();
        },
      ),
    );
  }
}

/// 인증 상태에 따라 화면을 분기하는 래퍼
class AuthWrapper extends StatelessWidget {
// ... (나머지 코드 유지)
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = locator<AuthService>();
    return StreamBuilder<AuthState>(
      stream: authService.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const PartnerHomePage();
        }
        return const PartnerLoginPage();
      },
    );
  }
}

/// Partner 앱 개발용 화면 목록
class PartnerDevMap extends StatelessWidget {
  const PartnerDevMap({super.key});

  @override
  Widget build(BuildContext context) {
    return DevScreenList(
      appName: 'Minglit Partner',
      items: [
        DevScreenItem(
          title: 'Main App Flow',
          description: '파트너 앱 정상 시작 흐름',
          screenBuilder: (_) => const AuthWrapper(),
        ),
        DevScreenItem(
          title: 'Partner Login',
          description: '파트너 전용 로그인 화면',
          screenBuilder: (_) => const PartnerLoginPage(),
        ),
        DevScreenItem(
          title: 'Partner Home',
          description: '파트너 대시보드 메인',
          screenBuilder: (_) => const PartnerHomePage(),
        ),
        DevScreenItem(
          title: 'Verification Review',
          description: '유저 인증 요청 심사 (승인/반려)',
          screenBuilder: (_) => const ReviewVerificationPage(),
        ),
      ],
    );
  }
}

class PartnerLoginPage extends StatelessWidget {
  const PartnerLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = locator<AuthService>();

    return MinglitLoginScreen(
      isPartner: true,
      onGoogleSignIn: () async {
        try {
          await authService.signInWithGoogle();
        } catch (e) {
          debugPrint('Partner Login Error: $e');
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('로그인 실패'),
                content: SelectableText('Error: $e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          }
        }
      },
      onKakaoSignIn: () {
        debugPrint('Partner: Kakao Sign-In Clicked');
      },
    );
  }
}

class PartnerHomePage extends StatelessWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = locator<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Color(0xFFFF7043)),
            const SizedBox(height: 20),
            Text('사장님(${user?.email}) 환영합니다!'),
             const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => authService.signOut(),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
