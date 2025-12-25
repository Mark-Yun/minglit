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
  
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
  );

  runApp(MinglitPartnerApp(googleWebClientId: googleWebClientId));
}

class MinglitPartnerApp extends StatelessWidget {
  final String? googleWebClientId;

  const MinglitPartnerApp({super.key, this.googleWebClientId});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(webClientId: googleWebClientId);

    return MaterialApp(
      title: 'Minglit Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7043),
          primary: const Color(0xFFFF7043),
          secondary: const Color(0xFF1A237E),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      home: StreamBuilder<AuthState>(
        stream: authService.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return PartnerHomePage(authService: authService);
          }
          return PartnerLoginPage(authService: authService);
        },
      ),
    );
  }
}

class PartnerLoginPage extends StatelessWidget {
  final AuthService authService;

  const PartnerLoginPage({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MinglitLoginScreen(
      isPartner: true,
      onGoogleSignIn: () async {
        try {
          await authService.signInWithGoogle();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Login Failed: $e')),
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
  final AuthService authService;

  const PartnerHomePage({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
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
