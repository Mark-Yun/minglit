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

  runApp(const MinglitPartnerApp());
}

final supabase = Supabase.instance.client;

class MinglitPartnerApp extends StatelessWidget {
  const MinglitPartnerApp({super.key});

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
      home: const PartnerLoginPage(),
    );
  }
}

class PartnerLoginPage extends StatelessWidget {
  const PartnerLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MinglitLoginScreen(
      isPartner: true, // 파트너 앱 모드 (오렌지 테마)
      onGoogleSignIn: () async {
        debugPrint('Partner: Google Sign-In Clicked');
        // TODO: 로그인 로직 추가
      },
      onKakaoSignIn: () {
        debugPrint('Partner: Kakao Sign-In Clicked');
      },
    );
  }
}