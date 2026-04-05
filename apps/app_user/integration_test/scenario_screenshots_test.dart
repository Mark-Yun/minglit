import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/scenarios/all_user_scenarios.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ko_KR');
  });

  for (final scenario in UserScenarios.all) {
    testWidgets(scenario.name, (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((_) => scenario.currentUser),
            authStateChangesProvider.overrideWith(
              (_) => const Stream.empty(),
            ),
            notificationInitializerProvider.overrideWith((_) {}),
            ...scenario.overrides.cast(),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: scenario.brightness == Brightness.dark
                ? MinglitTheme.materialThemeDark
                : MinglitTheme.materialTheme,
            home: scenario.page,
          ),
        ),
      );
      // Use fixed pump for QR screens with animations; otherwise pumpAndSettle.
      if (scenario.name.contains('ticket_qr')) {
        await tester.pump(const Duration(milliseconds: 300));
      } else {
        await tester.pumpAndSettle();
      }
      await binding.takeScreenshot(scenario.name);
    });
  }
}
