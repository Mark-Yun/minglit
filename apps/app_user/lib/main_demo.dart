/// Demo flavor entry for app_user.
///
/// Boots with **zero server connections** — all Repository providers are
/// replaced with in-memory fakes from `minglit_demo`. The widget tree (router,
/// coordinators, screens) is identical to prod.
///
/// Build with:
/// ```bash
/// flutter build apk --flavor demo \
///   --target lib/main_demo.dart \
///   --dart-define-from-file=../../minglit_env/demo/flutter.env
/// ```
///
/// See docs/infra/app_demo/architecture.md "부팅 흐름".
library;

import 'dart:async';
import 'dart:io';

import 'package:app_user/main.dart' show MinglitApp;
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:minglit_demo/minglit_demo.dart';
import 'package:minglit_kit/minglit_kit.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (!kIsWeb && Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } on Object catch (_) {
      // Some devices don't support configurable display modes; fail silently.
    }
  }

  // Demo flavor validates only the bare minimum (ENVIRONMENT=demo). All
  // network keys are unused — appStartup() short-circuits via
  // EnvKeyStore.isDemo.
  EnvKeyStore.validate();

  if (!EnvKeyStore.isDemo) {
    throw StateError(
      'main_demo.dart entered without IS_DEMO=true. Demo flavor build must '
      'pass --dart-define=IS_DEMO=true (typically via minglit_env/demo/flutter.env).',
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        // Foundation: fixture data + Fake Repositories (replaces all
        // minglit_kit Repository providers).
        ...demoOverrides(),

        // App-local providers that prod's main.dart configures (auth config,
        // notification deep-link routing). Demo replicates with dummy values.
        authConfigProvider.overrideWithValue(
          const AuthConfig(
            webClientId: '',
            defaultRedirectUrl: '',
            mobileRedirectScheme: 'com.minglit.demo.user',
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
