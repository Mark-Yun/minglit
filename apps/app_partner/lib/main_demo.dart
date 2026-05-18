/// Demo flavor entry for app_partner.
///
/// Boots with **zero server connections**. Identical widget tree to prod —
/// data layer replaced via `minglit_demo` ProviderScope overrides. The
/// demo partner ("민글릿 라운지 강남") becomes the current partner context.
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

import 'package:app_partner/main.dart' show MinglitPartnerApp;
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
      // Fail silently.
    }
  }

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
        ...demoOverrides(),
      ],
      child: const MinglitPartnerApp(),
    ),
  );
}
