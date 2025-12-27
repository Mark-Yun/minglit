import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'src/features/dev/user_dev_map.dart';

void main() async {
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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: locator<AuthRepository>()),
        RepositoryProvider.value(value: locator<PartnerRepository>()),
        RepositoryProvider.value(value: locator<VerificationRepository>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(authRepository: context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => PartnerBloc(partnerRepository: context.read<PartnerRepository>()),
          ),
          BlocProvider(
            create: (context) => VerificationBloc(verificationRepository: context.read<VerificationRepository>()),
          ),
        ],
        child: MaterialApp(
          title: 'Minglit User (DEV)',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
            useMaterial3: true,
            textTheme: GoogleFonts.notoSansKrTextTheme(),
          ),
          home: const UserDevMap(),
        ),
      ),
    );
  }
}