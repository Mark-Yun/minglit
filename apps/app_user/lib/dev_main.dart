import 'dart:async';

import 'package:app_user/src/l10n/generated/app_localizations.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
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
            defaultRedirectUrl: 'http://localhost:3000',
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

          Log.d(
            '🧭 [Router] Initializing GoRouter with ${$appRoutes.length} routes',
          );
          for (final route in $appRoutes) {
            if (route is GoRoute) {
              Log.d('  - Route: ${route.path}');
            }
          }

          return GoRouter(
            navigatorKey: rootNavigatorKey,
            refreshListenable: authState,
            debugLogDiagnostics: true, // Enable Router logging
            redirect: (context, state) async {
              final isLoggedIn = ref.read(currentUserProvider) != null;
              final isLoggingIn = state.uri.path == '/login';
              final path = state.uri.path;
              final isDevPage = path.startsWith('/dev');

              Log.d(
                '🧭 [Router] path: $path | isLoggedIn: $isLoggedIn | '
                'isLoggingIn: $isLoggingIn | isDevPage: $isDevPage',
              );

              // 0. Check for Saved Return URL (After OAuth Login)
              if (isLoggedIn) {
                final prefs = await SharedPreferences.getInstance();
                final returnUrl = prefs.getString('auth_return_url');
                if (returnUrl != null) {
                  Log.d('🧭 [Router] Found saved return URL: $returnUrl');
                  await prefs.remove('auth_return_url');
                  return returnUrl;
                }
              }

              // 1. Default dev redirect for root path
              if (path == '/') {
                Log.d('🧭 [Router] Root path detected. Redirecting to /dev');
                return '/dev';
              }

              // Allow dev pages without login for testing
              if (isDevPage) return null;

              // 1. 이미 로그인 상태인데 로그인 페이지로 가려면 홈으로 보냄
              if (isLoggedIn && isLoggingIn) {
                Log.d(
                  '🧭 [Router] Redirecting to / (LoggedIn & on Login Page)',
                );
                return '/';
              }

              // 2. 보호된 경로 정의 (로그인 필수)
              const protectedPaths = [
                '/my', // 마이페이지
                '/tickets/my', // 내 티켓 목록
                '/payment', // 결제 관련
              ];

              final isProtected = protectedPaths.any(path.startsWith);

              // 3. 비로그인 상태에서 보호된 경로 진입 시 -> 로그인 페이지로
              if (!isLoggedIn && isProtected) {
                final redirectUrl = Uri(
                  path: '/login',
                  queryParameters: {'from': path},
                ).toString();

                Log.d(
                  '🧭 [Router] Redirecting to $redirectUrl '
                  '(Not LoggedIn & Protected Path)',
                );
                return redirectUrl;
              }

              return null;
            },
            routes: $appRoutes,
            observers: [MinglitNavigationObserver()],
          );
        }),
      ],
      child: const MinglitDevApp(),
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
    defaultValue: 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz',
  );

  try {
    await initializeDateFormatting('ko_KR');

    DevConfig.init(supabaseUrl, supabaseServiceRoleKey);
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
    Log.e('App startup warning', e);
  }
}

class MinglitDevApp extends ConsumerWidget {
  const MinglitDevApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final startupState = ref.watch(appStartupProvider);

    return MaterialApp.router(
      title: 'Minglit User (Dev)',
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
        // Handle Startup State
        return startupState.when(
          data: (_) => StaffGuardWrapper(
            child: MinglitGlobalLoadingOverlay(child: child!),
          ),
          loading: () => const MinglitSplashScreen(appName: 'User Dev'),
          error: (e, st) => MaterialApp(
            home: Scaffold(body: Center(child: Text('Startup Error: $e'))),
          ),
        );
      },
    );
  }
}
