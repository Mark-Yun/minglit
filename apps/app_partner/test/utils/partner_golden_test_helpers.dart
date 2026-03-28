import 'package:alchemist/alchemist.dart' show GoldenTestScenario;
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/more/more_coordinator.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Alchemist page-wrapper for app_partner golden tests.
// ---------------------------------------------------------------------------

/// Wraps a page widget in [ProviderScope] + [MaterialApp] with localization
/// delegates and the given overrides/theme for Alchemist [GoldenTestScenario].
class PartnerGoldenPageWrapper extends StatelessWidget {
  const PartnerGoldenPageWrapper({
    required this.page,
    this.overrides = const [],
    this.brightness = Brightness.light,
    super.key,
  });

  final Widget page;
  final List<dynamic> overrides;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        notificationListProvider.overrideWith(_EmptyNotificationList.new),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        locale: const Locale('ko'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------------

class MockPartnerHomeCoordinator extends Mock
    implements PartnerHomeCoordinator {}

class MockMoreCoordinator extends Mock implements MoreCoordinator {}

/// Empty notification list for golden tests.
class _EmptyNotificationList extends NotificationList {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}
