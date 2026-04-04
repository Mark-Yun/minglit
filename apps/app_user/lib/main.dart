import 'dart:async';

import 'package:app_user/firebase_options.dart';
import 'package:app_user/src/l10n/generated/app_localizations.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

part 'main.g.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  EnvKeyStore.validate();

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
  } on Object catch (e, st) {
    // Fix #270: 초기화 에러 로깅 — 에러 삼킴 방지
    debugPrint('Sentry init failed: $e\n$st');
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

  const statsigClientKey = String.fromEnvironment('STATSIG_CLIENT_KEY');
  const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'local',
  );
  await StatsigAnalytics.initialize(statsigClientKey, tier: environment);
  StatsigAnalytics.logEvent(MingLitEvent.appOpened);

  // Sync Statsig user context with auth state changes
  ref.listen(authStateChangesProvider, (_, next) {
    next.whenData((authState) {
      final userId = authState.session?.user.id;
      if (userId != null) {
        unawaited(StatsigAnalytics.updateUser(userId));
      } else {
        // Fix #155: shutdown() kills _initialized flag, blocking all future events.
        // Reset to anonymous instead of shutting down the SDK.
        unawaited(StatsigAnalytics.updateUser(''));
      }
    });
  });
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
    ref
      ..watch(notificationInitializerProvider)
      // Remove native splash when startup completes (or fails).
      ..listen(appStartupProvider, (prev, next) {
        if (next is! AsyncLoading) FlutterNativeSplash.remove();
      });

    // ignore: use_minglit_async_value_widget - This is the app entry point, MaterialApp is not yet available.
    return MaterialApp.router(
      title: 'Minglit User',
      debugShowCheckedModeBanner: false,
      theme: MinglitTheme.materialTheme,
      darkTheme: MinglitTheme.materialThemeDark,
      themeMode: ref.watch(themeControllerProvider),
      routerConfig: goRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return MinglitAsyncValueWidget(
          value: startupState,
          data: (_) => BugReporterWrapper(
            navigatorKey: rootNavigatorKey,
            // Fix #382: child 강제 언래핑 제거 — nullable child에 fallback 추가
            child: PendingDeletionRecoveryListener(
              child: MinglitGlobalLoadingOverlay(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
          // Hidden behind native splash — show nothing.
          loading: () => const SizedBox.shrink(),
          error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
        );
      },
    );
  }
}
