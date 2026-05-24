import 'dart:async';
import 'dart:io';

import 'package:app_user/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

final FutureProvider<void> appStartupProvider =
    FutureProvider.autoDispose<void>(
      runUserStartup,
      name: 'appStartupProvider',
    );

Future<void> runUserStartup(Ref ref) async {
  await initializeDateFormatting('ko_KR');

  // Demo flavor short-circuits all network SDK init. Data comes from
  // minglit_demo ProviderScope overrides registered in main_demo.dart.
  // See docs/infra/app_demo/architecture.md "부팅 흐름".
  if (EnvKeyStore.isDemo) return;

  const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'local',
  );

  await MinglitStartupPlan(
    steps: [
      MinglitStartupStep.critical(
        'env.validate',
        () async => EnvKeyStore.validate(),
      ),
      MinglitStartupStep.critical('supabase', _initSupabase),
      MinglitStartupStep.platform('display.high_refresh', _setHighRefreshRate),
      MinglitStartupStep.platform('firebase', _initFirebase),
      MinglitStartupStep.degradable('statsig', () => _initStatsig(environment)),
    ],
    onNonCriticalFailure: (failure) {
      Log.e(
        'App startup warning: ${failure.stepName}',
        failure.error,
        failure.stackTrace,
      );
    },
  ).run();

  StatsigAnalytics.logEvent(MingLitEvent.appOpened);
  _syncStatsigUserContext(ref);
}

Future<void> _setHighRefreshRate() async {
  if (!kIsWeb && Platform.isAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
  }
}

/// Android 는 `com.google.gms.google-services` Gradle plugin 으로 native auto-init
/// (`src/<flavor>/google-services.json` 사용). iOS / Web 은 Dart options 사용.
/// Dart 측에서 잘못된 placeholder options 를 SDK 에 넘겨 init 가 hang 되는 문제 회피.
Future<FirebaseApp> _initFirebase() {
  if (!kIsWeb && Platform.isAndroid) {
    return Firebase.initializeApp();
  }
  return Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> _initSupabase() {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  return Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
}

Future<void> _initStatsig(String environment) async {
  const statsigClientKey = String.fromEnvironment('STATSIG_CLIENT_KEY');
  await StatsigAnalytics.initialize(statsigClientKey, tier: environment);
}

void _syncStatsigUserContext(Ref ref) {
  ref.listen(authStateChangesProvider, (_, next) {
    next.whenData((authState) {
      final userId = authState.session?.user.id;
      if (userId != null) {
        unawaited(StatsigAnalytics.updateUser(userId));
      } else {
        // Fix #155: shutdown() kills _initialized flag, blocking all future
        // events. Reset to anonymous instead of shutting down the SDK.
        unawaited(StatsigAnalytics.updateUser(''));
      }
    });
  });
}
