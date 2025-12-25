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

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
  );

  runApp(const MinglitApp());
}

final supabase = Supabase.instance.client;

class MinglitApp extends StatelessWidget {
  const MinglitApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MinglitLoginScreen(
      isPartner: false, // 유저 앱 모드
      onGoogleSignIn: () async {
        debugPrint('User: Google Sign-In Clicked');
        // TODO: 로그인 로직 추가
      },
      onKakaoSignIn: () {
        debugPrint('User: Kakao Sign-In Clicked');
      },
    );
  }
}