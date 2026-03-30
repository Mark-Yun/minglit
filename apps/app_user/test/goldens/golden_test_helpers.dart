import 'dart:io';

import 'package:alchemist/alchemist.dart'
    show GoldenTestScenario, PumpAction, onlyPumpAndSettle;
import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/search/logic/search_coordinator.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Alchemist page-wrapper for app_user golden tests.
// ---------------------------------------------------------------------------

/// Wraps a page widget in [ProviderScope] + [MaterialApp] with the given
/// overrides and theme, suitable for Alchemist [GoldenTestScenario].
class GoldenPageWrapper extends StatelessWidget {
  const GoldenPageWrapper({
    required this.page,
    this.overrides = const [],
    this.brightness = Brightness.light,
    this.currentUser,
    super.key,
  });

  final Widget page;
  final List<dynamic> overrides;
  final Brightness brightness;
  final User? currentUser;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => currentUser),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: page,
      ),
    );
  }
}

/// Initializes locale data and SharedPreferences mocks for golden tests.
Future<void> initGoldenDeps() async {
  SharedPreferences.setMockInitialValues({});
  await initializeDateFormatting('ko_KR');
}

// ---------------------------------------------------------------------------
// Mock coordinators (used by pages that ref.read coordinators)
// ---------------------------------------------------------------------------

class MockHomeCoordinator extends Mock implements HomeCoordinator {}

class MockEventCoordinator extends Mock implements EventCoordinator {}

class MockAuthCoordinator extends Mock implements AuthCoordinator {}

class MockSearchCoordinator extends Mock implements SearchCoordinator {}

/// No-op ActiveFilters — disables location/eligibility filters in tests.
class NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}

/// Creates a [PumpAction] that pumps the widget tree, then dumps the render
/// tree to a `.render.txt` file alongside the golden image.
///
/// The dump contains exact padding, sizes, and constraints for every
/// [RenderObject] — useful for automated spacing/alignment analysis.
Future<void> Function(WidgetTester) pumpAndDumpTree(String fileName) {
  return (WidgetTester tester) async {
    await initGoldenDeps();
    await onlyPumpAndSettle(tester);
    final dump = tester.binding.renderViews.first.toStringDeep();
    File('test/goldens/$fileName.render.txt').writeAsStringSync(dump);
  };
}
