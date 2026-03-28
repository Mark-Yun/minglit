import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/more/more_coordinator.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

/// Fixed surface size for golden tests — iPhone 14 ratio (390x844).
const goldenSurfaceSize = Size(390, 844);

/// Pumps a [page] (full-page widget with its own Scaffold) inside a themed
/// [MaterialApp] + [ProviderScope] with localization delegates,
/// then compares against [goldenFileName].
Future<void> expectPageGolden(
  WidgetTester tester, {
  required Widget page,
  required String goldenFileName,
  Size surfaceSize = goldenSurfaceSize,
  List<dynamic> overrides = const [],
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Default safe overrides
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
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(goldenFileName),
  );
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
