import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:54321');
  const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH');
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  setupLocator(googleWebClientId: googleWebClientId, defaultRedirectUrl: 'http://localhost:3000');

  runApp(const MinglitApp());
}

class MinglitApp extends StatelessWidget {
  const MinglitApp({super.key});

  Future<void> _initialize() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.poppins(),
      GoogleFonts.notoSansKr(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minglit User',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFFFF7043),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      home: FutureBuilder(
        future: _initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MinglitSplashScreen(appName: 'User');
          }
          return const AuthWrapper(); // 프로덕션은 바로 인증 래퍼로
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = locator<AuthService>();
    return StreamBuilder<AuthState>(
      stream: authService.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomePage();
        }
        return const LoginPage();
      },
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
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('로그인 실패'),
                content: SelectableText('Error: $e'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
              ),
            );
          }
        }
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
              CircleAvatar(backgroundImage: NetworkImage(user!.userMetadata!['avatar_url']), radius: 40),
            const SizedBox(height: 20),
            Text('안녕하세요, ${user?.userMetadata?['full_name'] ?? user?.email}님!'),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: () => authService.signOut(), child: const Text('로그아웃')),
          ],
        ),
      ),
    );
  }
}