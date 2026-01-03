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
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState, Supabase;

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
            defaultRedirectUrl: 'http://localhost:3000',
          ),
        ),
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
            observers: [
              MinglitNavigationObserver(),
            ],
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
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );
  const supabaseServiceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: 'sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz',
  );

  try {
    await Future.wait([
      initializeDateFormatting('ko_KR'),
      Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabasePublishableKey,
      ),
    ]);

    DevConfig.init(supabaseUrl, supabaseServiceRoleKey);
  } on Exception catch (e) {
    debugPrint('⚠️ App startup warning: $e');
  }
}

class MinglitDevApp extends StatelessWidget {
  const MinglitDevApp({super.key});

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

    return startupState.when(
      data: (_) => const _AuthenticatedApp(),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MinglitTheme.materialTheme,
        home: const MinglitSplashScreen(
          appName: 'User Dev',
        ),
      ),
      error: (e, st) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Startup Error: $e'),
          ),
        ),
      ),
    );
  }
}

class _AuthenticatedApp extends ConsumerWidget {
  const _AuthenticatedApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

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
        return MinglitGlobalLoadingOverlay(child: child!);
      },
    );
  }
}
