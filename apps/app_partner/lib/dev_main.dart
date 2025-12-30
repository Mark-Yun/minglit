import 'dart:async';

import 'package:app_partner/src/features/dev/partner_dev_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

part 'dev_main.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  runApp(
    ProviderScope(
      overrides: [
        authConfigProvider.overrideWithValue(
          const AuthConfig(
            webClientId: googleWebClientId,
            defaultRedirectUrl: 'http://localhost:3001',
          ),
        ),
      ],
      child: const MinglitPartnerDevApp(),
    ),
  );
}

@riverpod
Future<void> appStartup(Ref ref) async {
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );
  const supabaseServiceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz',
  );

  try {
    // 1. Load Asset Manifest
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = manifest.listAssets();

    // Filter image assets from minglit_kit
    const imagePathPrefix = 'packages/minglit_kit/assets/images/';
    const logoPath = '${imagePathPrefix}minglit_app_bar_logo.png';

    final imageAssets = allAssets.where(
      (path) => path.startsWith(imagePathPrefix),
    );

    // 2. Essential Startup (Wait for these)
    await Future.wait([
      initializeDateFormatting('ko_KR'),
      Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabasePublishableKey,
      ),
      // Wait for the critical logo and fonts to prevent UI flicker
      rootBundle.load(logoPath),
      GoogleFonts.pendingFonts([
        GoogleFonts.notoSansKr(),
      ]),
    ]);

    // 3. Background Caching for remaining images
    for (final asset in imageAssets) {
      if (asset != logoPath) {
        unawaited(rootBundle.load(asset));
      }
    }

    // 4. Initialize Dev Config
    DevConfig.init(supabaseUrl, supabaseServiceRoleKey);

    // 5. Engine Stabilization Delay
    // Give 200ms for the engine to finish font mapping and image decoding
    await Future<void>.delayed(const Duration(milliseconds: 200));
  } on Exception catch (e) {
    debugPrint('❌ [Startup] Critical error: $e');
  }
}

class MinglitPartnerDevApp extends StatelessWidget {
  const MinglitPartnerDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppView();
  }
}

class _AppView extends ConsumerWidget {
  const _AppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(appStartupProvider);

    // Precache logo for the main app
    unawaited(
      precacheImage(
        const AssetImage(
          'packages/minglit_kit/assets/images/minglit_app_bar_logo.png',
        ),
        context,
      ),
    );

    return startupState.when(
      // Case 1: Initializing - Show Splash immediately with a lightweight app
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const MinglitSplashScreen(
          appName: 'Partner Dev',
          isPartner: true,
        ),
      ),

      // Case 2: Error - Show Error UI
      error: (e, st) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Startup Error: $e')),
        ),
      ),

      // Case 3: Ready - Show the Real App with full theme and routes
      data: (_) => MaterialApp(
        title: 'Minglit Partner (Dev)',
        debugShowCheckedModeBanner: false,
        theme: MinglitTheme.materialTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        builder: (context, child) {
          return MinglitGlobalLoadingOverlay(child: child!);
        },
        home: const PartnerDevMap(),
      ),
    );
  }
}
