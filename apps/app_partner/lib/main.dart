import 'dart:async';

import 'package:app_partner/src/bootstrap/partner_startup.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:minglit_kit/minglit_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Fix #1538: 테스트에서 production delegate 목록을 참조할 수 있도록 상수로 추출.
// 이 상수가 변경되면 party_description_input_test.dart도 자동으로 반영된다.
const List<LocalizationsDelegate<Object>> kPartnerLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  quill.FlutterQuillLocalizations.delegate,
];

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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
              defaultRedirectUrl: 'http://localhost:3001',
              mobileRedirectScheme: 'com.minglit.app_partner',
            ),
          ),
          notificationDeepLinkHandlerProvider.overrideWith((ref) {
            final router = ref.read(goRouterProvider);
            return router.go;
          }),
        ],
        child: const MinglitPartnerApp(),
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

class MinglitPartnerApp extends StatelessWidget {
  const MinglitPartnerApp({super.key});

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
    if (startupState is AsyncData<void>) {
      // Activate notification initializer only after critical startup succeeds.
      ref.watch(notificationInitializerProvider);
    }
    // Remove native splash when startup completes (or fails).
    ref.listen(appStartupProvider, (prev, next) {
      if (next is! AsyncLoading) FlutterNativeSplash.remove();
    });

    // ignore: use_minglit_async_value_widget - This is the app entry point, MaterialApp is not yet available.
    return MaterialApp.router(
      title: 'Minglit Partner',
      debugShowCheckedModeBanner: false,
      theme: MinglitTheme.partnerTheme,
      darkTheme: MinglitTheme.partnerThemeDark,
      themeMode: ref.watch(themeControllerProvider),
      routerConfig: goRouter,
      localizationsDelegates: kPartnerLocalizationsDelegates,
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
          error: (e, st) => StartupFatalErrorView(
            error: e,
            onRetry: () => ref.invalidate(appStartupProvider),
          ),
        );
      },
    );
  }
}
