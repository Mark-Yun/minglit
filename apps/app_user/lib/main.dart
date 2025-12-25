import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  // 구글 웹 클라이언트 ID (GCP Console에서 발급 필요)
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
  );

  // 서비스 로케이터 초기화 (AuthService 등록)
  setupLocator(googleWebClientId: googleWebClientId);

  runApp(const MinglitApp());
}

class MinglitApp extends StatelessWidget {
  const MinglitApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GetIt을 통해 AuthService 인스턴스 가져오기
    final authService = locator<AuthService>();

    return MaterialApp(
      title: 'Minglit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E), // Navy
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFFFF7043),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      // AuthState 변화에 따라 화면 전환
      home: StreamBuilder<AuthState>(
        stream: authService.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          
          // 로그인 되어 있으면 홈 화면
          if (session != null) {
            return const HomePage();
          }
          
          // 아니면 로그인 화면
          return const LoginPage();
        },
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = locator<AuthService>();

    return MinglitLoginScreen(
      isPartner: false,
      onGoogleSignIn: () async {
        try {
          await authService.signInWithGoogle();
        } catch (e) {
          debugPrint('Login Error: $e');
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
        debugPrint('User: Kakao Sign-In Clicked (Not Implemented)');
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = locator<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Minglit Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.userMetadata?['avatar_url'] != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user!.userMetadata!['avatar_url']),
                radius: 40,
              ),
            const SizedBox(height: 20),
            Text('안녕하세요, ${user?.userMetadata?['full_name'] ?? user?.email}님!'),
            const SizedBox(height: 10),
            Text('UID: ${user?.id}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
