import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/features/dev/partner_dev_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:54321');
  const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH');
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  setupLocator(googleWebClientId: googleWebClientId, defaultRedirectUrl: 'http://localhost:3001');

  runApp(const MinglitPartnerDevApp());
}

class MinglitPartnerDevApp extends StatelessWidget {
  const MinglitPartnerDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minglit Partner (DEV)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF7043)),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      home: const PartnerDevMap(),
    );
  }
}
