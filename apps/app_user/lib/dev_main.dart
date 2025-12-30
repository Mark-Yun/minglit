import 'dart:async';

import 'package:app_user/src/features/dev/user_dev_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

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

    return MaterialApp(
      title: 'Minglit User (Dev)',
      theme: MinglitTheme.materialTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      builder: (context, child) {
        return MinglitGlobalLoadingOverlay(child: child!);
      },
      home: startupState.when(
        data: (_) => const UserDevMap(),
        loading: () => const MinglitSplashScreen(appName: 'User Dev'),
        error: (e, st) => Scaffold(
          body: Center(
            child: Text('Startup Error: $e'),
          ),
        ),
      ),
    );
  }
}
