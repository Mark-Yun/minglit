import 'dart:async';

import 'package:app_user/src/l10n/generated/app_localizations.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_dev.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'dev_main.g.dart';

const _kDevStartScreen = 'dev_start_screen';

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

  final prefs = await SharedPreferences.getInstance();
  final startWithDashboard = prefs.getBool(_kDevStartScreen) ?? false;

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    );
  } catch (e) {
    if (e.toString().contains('Invalid Refresh Token') ||
        (e is AuthApiException && e.code == 'refresh_token_not_found')) {
      await prefs.clear();
      Log.w('⚠️ Invalid Refresh Token detected during init. Storage cleared.');

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
        minglitDomainsProvider.overrideWithValue(const MinglitDomains.dev()),
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
            refreshListenable: authState,
            debugLogDiagnostics: true,
            initialLocation: startWithDashboard ? '/' : '/dev',
            redirect: (context, state) {
              final isLoggedIn = ref.read(currentUserProvider) != null;
              final isLoggingIn = state.uri.path == '/login';
              final isCallback = state.uri.path == '/auth/callback';
              final path = state.uri.path;
              final isDevPage = path.startsWith('/dev');

              Log.d(
                '🧭 [Router] path: $path | isLoggedIn: $isLoggedIn | '
                'isLoggingIn: $isLoggingIn | isDevPage: $isDevPage',
              );

              if (isCallback) return null;

              if (isDevPage) return null;

              if (isLoggedIn && isLoggingIn) {
                return '/';
              }

              const protectedPaths = [
                '/my',
                '/tickets/my',
                '/payment',
              ];

              final isProtected = protectedPaths.any(path.startsWith);

              if (!isLoggedIn && isProtected) {
                return Uri(
                  path: '/login',
                  queryParameters: {'from': path},
                ).toString();
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
  );

  try {
    await initializeDateFormatting('ko_KR');
    DevConfig.init(supabaseUrl, supabaseServiceRoleKey);
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
        // ignore: use_minglit_async_value_widget - This is the app entry point, MaterialApp is not yet available.
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: MinglitSplashTransition.build,
          child: startupState.when(
            data: (_) => StaffGuardWrapper(
              key: const ValueKey('app'),
              child: MinglitGlobalLoadingOverlay(child: child!),
            ),
            loading: () => const MinglitSplashScreen(
              key: ValueKey('splash'),
              appName: 'User Dev',
            ),
            error: (e, st) => Scaffold(
              key: const ValueKey('error'),
              body: Center(child: Text('Startup Error: $e')),
            ),
          ),
        );
      },
    );
  }
}
