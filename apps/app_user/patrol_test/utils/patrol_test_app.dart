// Patrol test helper — wraps MinglitApp with the same ProviderScope overrides
// used in main.dart. Keeps test setup consistent with production app launch.
import 'package:app_user/main.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget createPatrolTestApp() {
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  return ProviderScope(
    overrides: [
      authConfigProvider.overrideWithValue(
        const AuthConfig(
          webClientId: googleWebClientId,
          defaultRedirectUrl: 'http://localhost:3000',
          mobileRedirectScheme: 'com.minglit.app_user',
        ),
      ),
    ],
    child: const MinglitApp(),
  );
}
