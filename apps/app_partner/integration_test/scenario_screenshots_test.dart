import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/scenarios/all_partner_scenarios.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ko_KR');
  });

  for (final scenario in PartnerScenarios.all) {
    testWidgets(scenario.name, (tester) async {
      Widget child;
      if (scenario.isComponent) {
        // Component scenarios: render in MaterialApp without ProviderScope.
        child = MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: scenario.brightness == Brightness.dark
              ? MinglitTheme.materialThemeDark
              : MinglitTheme.materialTheme,
          home: Scaffold(body: Center(child: scenario.page)),
        );
      } else {
        // Full-page scenarios: render with ProviderScope + localization.
        child = ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((_) => null),
            authStateChangesProvider.overrideWith(
              (_) => const Stream.empty(),
            ),
            notificationInitializerProvider.overrideWith((_) {}),
            notificationListProvider.overrideWith(_EmptyNotificationList.new),
            ...scenario.overrides.cast(),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: scenario.brightness == Brightness.dark
                ? MinglitTheme.materialThemeDark
                : MinglitTheme.materialTheme,
            locale: const Locale('ko'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: scenario.page,
          ),
        );
      }

      await tester.pumpWidget(child);
      await tester.pumpAndSettle();
      await binding.takeScreenshot(scenario.name);
    });
  }
}

class _EmptyNotificationList extends NotificationList {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}
