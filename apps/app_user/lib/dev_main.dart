import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart' as main_prod;
import 'src/features/dev/user_dev_map.dart';

void main() async {
  // 프로덕션 main의 초기화 로직 공유
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:54321');
  const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH');
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  setupLocator(googleWebClientId: googleWebClientId, defaultRedirectUrl: 'http://localhost:3000');

  runApp(const MinglitDevApp());
}

class MinglitDevApp extends StatelessWidget {
  const MinglitDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minglit User (DEV)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      home: const UserDevMap(), // 개발자 맵으로 바로 진입
    );
  }
}
