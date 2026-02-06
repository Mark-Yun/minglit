import 'dart:async';

import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;
import 'package:minglit_kit/minglit_dev.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'dev_main.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );

  // Initialize Supabase immediately for StaffGuard access
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    );
  } catch (e) {
    // Handle "Invalid Refresh Token" error by clearing storage and retrying
    if (e.toString().contains('Invalid Refresh Token') ||
        (e is AuthApiException && e.code == 'refresh_token_not_found')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Log.w('⚠️ Invalid Refresh Token detected during init. Storage cleared.');

      // Retry initialization
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabasePublishableKey,
      );
    } else {
      rethrow;
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        authConfigProvider.overrideWithValue(
          const AuthConfig(
            webClientId: googleWebClientId,
            defaultRedirectUrl: 'http://localhost:3001',
          ),
        ),
        // Set environment domains to Dev
        minglitDomainsProvider.overrideWithValue(const MinglitDomains.dev()),
        // Override goRouter to start at /dev for dev_main
        goRouterProvider.overrideWith((ref) {
          final rootNavigatorKey = GlobalKey<NavigatorState>();
          final authState = ValueNotifier<AuthState?>(null);

          ref.listen(authStateChangesProvider, (_, next) {
            next.whenData((state) {
              authState.value = state;
            });
          });

          return GoRouter(
            navigatorKey: rootNavigatorKey,
            initialLocation: '/dev',
            refreshListenable: authState,
            redirect: (context, state) {
              final isLoggedIn = ref.read(currentUserProvider) != null;
              final isLoggingIn = state.uri.path == '/login';
              final isDevPage = state.uri.path.startsWith('/dev');

              // Allow dev pages without login for testing
              if (isDevPage) return null;

              if (!isLoggedIn && !isLoggingIn) {
                return '/login';
              }
              if (isLoggedIn && isLoggingIn) {
                return '/';
              }
              return null;
            },
            routes: $appRoutes,
          );
        }),
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
  const supabaseServiceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
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
      // Wait for the critical logo and fonts to prevent UI flicker
      rootBundle.load(logoPath),
      GoogleFonts.pendingFonts([GoogleFonts.notoSansKr()]),
    ]);

    // Initialize Kakao Map SDK
    const kakaoMapKey = String.fromEnvironment('KAKAO_MAP_JAVASCRIPT_KEY');
    if (kakaoMapKey.isNotEmpty) {
      kakao.AuthRepository.initialize(appKey: kakaoMapKey);
    } else {
      Log.w('Kakao Map Key is missing in environment variables');
    }

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
  } on AuthApiException catch (e) {
    if (e.message.contains('Invalid Refresh Token') ||
        e.code == 'refresh_token_already_used') {
      Log.w('[Startup] Invalid Refresh Token detected. Clearing storage...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Log.i('[Startup] Storage cleared. Please reload the app.');
    }
    rethrow;
  } on Exception catch (e) {
    Log.e('[Startup] Critical error', e);
  }
}

class MinglitPartnerDevApp extends StatelessWidget {
  const MinglitPartnerDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Wrap the entire app with a Shell MaterialApp and StaffGuard.
    // This ensures protection is active even during startup/loading/error states.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MinglitTheme.materialTheme,
      home: const StaffGuardWrapper(child: _AppView()),
    );
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

    // ignore: use_minglit_async_value_widget - This is the app entry point, MaterialApp is not yet available.
    return startupState.when(
      // Case 1: Initializing - Show Splash immediately
      loading: () =>
          const MinglitSplashScreen(appName: 'Partner Dev', isPartner: true),

      // Case 2: Error - Show Error UI
      error: (e, st) =>
          Scaffold(body: Center(child: Text('Startup Error: $e'))),

      // Case 3: Ready - Show the Real App using GoRouter
      data: (_) => const _AuthenticatedApp(),
    );
  }
}

class _AuthenticatedApp extends ConsumerWidget {
  const _AuthenticatedApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Minglit Partner (Dev)',
      debugShowCheckedModeBanner: false,
      theme: MinglitTheme.materialTheme,
      routerConfig: goRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return MinglitGlobalLoadingOverlay(child: child!);
      },
    );
  }
}
