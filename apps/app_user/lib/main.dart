import 'dart:async';

import 'package:app_user/firebase_options.dart';
import 'package:app_user/src/l10n/generated/app_localizations.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
part 'main.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'local',
  );
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  void startApp() {
    runApp(
      ProviderScope(
        overrides: [
          authConfigProvider.overrideWithValue(
            const AuthConfig(
              webClientId: googleWebClientId,
              defaultRedirectUrl: 'http://localhost:3000',
              mobileRedirectScheme: 'com.minglit.app_user',
            ),
          ),
          notificationDeepLinkHandlerProvider.overrideWith((ref) {
            final router = ref.read(goRouterProvider);
            return router.go;
          }),
        ],
        child: const MinglitApp(),
      ),
    );
  }

  if (sentryDsn.isEmpty) {
    startApp();
    return;
  }

  try {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = sentryDsn
          ..environment = environment
          ..tracesSampleRate = 0.2;
      },
      appRunner: () => runZonedGuarded(
        startApp,
        (error, stackTrace) =>
            Sentry.captureException(error, stackTrace: stackTrace),
      ),
    );
  } on Object catch (_) {
    startApp();
  }
}

@riverpod
Future<void> appStartup(Ref ref) async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be set.\n'
      'Run with: flutter run --dart-define-from-file=../../minglit_env/local/flutter.env',
    );
  }

  try {
    await Future.wait([
      initializeDateFormatting('ko_KR'),
      Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ]);
  } on Exception catch (e) {
    Log.e('App startup warning', e);
  }
}

class MinglitApp extends StatelessWidget {
  const MinglitApp({super.key});

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
    final goRouter = ref.watch(goRouterProvider);
    // Activate notification initializer to listen for sign-in events
    ref.watch(notificationInitializerProvider);

    // ignore: use_minglit_async_value_widget - This is the app entry point, MaterialApp is not yet available.
    return MaterialApp.router(
      title: 'Minglit User',
      debugShowCheckedModeBanner: false,
      theme: MinglitTheme.materialTheme,
      routerConfig: goRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: MinglitSplashTransition.build,
          child: startupState.when(
            data: (_) => BugReporterWrapper(
              key: const ValueKey('app'),
              navigatorKey: rootNavigatorKey,
              child: MinglitGlobalLoadingOverlay(child: child!),
            ),
            loading: () => const MinglitSplashScreen(
              key: ValueKey('splash'),
              appName: 'User',
            ),
            error: (e, st) => Scaffold(
              key: const ValueKey('error'),
              body: Center(child: Text('Error: $e')),
            ),
          ),
        );
      },
    );
  }
}
