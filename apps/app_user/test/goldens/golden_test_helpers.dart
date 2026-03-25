import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed surface size for golden tests — iPhone 14 ratio (390x844).
const goldenSurfaceSize = Size(390, 844);

/// Pumps a [page] (full-page widget with its own Scaffold) inside a themed
/// [MaterialApp] + [ProviderScope], then compares against [goldenFileName].
///
/// Providers needed by child widgets can be overridden via [overrides].
Future<void> expectPageGolden(
  WidgetTester tester, {
  required Widget page,
  required String goldenFileName,
  Size surfaceSize = goldenSurfaceSize,
  List<dynamic> overrides = const [],
  User? currentUser,
}) async {
  // Prevent MissingPluginException for SharedPreferences in test environment.
  SharedPreferences.setMockInitialValues({});

  // Ensure intl locale data is available for date formatting widgets.
  await initializeDateFormatting('ko_KR');

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Default safe overrides — prevent platform channel / API errors.
        currentUserProvider.overrideWith((_) => currentUser),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MinglitTheme.materialTheme,
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

/// Pumps [widget] inside a themed [MaterialApp] + [Scaffold] + [ProviderScope]
/// for component-level golden tests.
Future<void> expectGolden(
  WidgetTester tester, {
  required Widget widget,
  required String goldenFileName,
  Size surfaceSize = goldenSurfaceSize,
  List<dynamic> overrides = const [],
  User? currentUser,
}) async {
  // Prevent MissingPluginException for SharedPreferences in test environment.
  SharedPreferences.setMockInitialValues({});

  // Ensure intl locale data is available for date formatting widgets.
  await initializeDateFormatting('ko_KR');

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => currentUser),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MinglitTheme.materialTheme,
        home: Scaffold(body: Center(child: widget)),
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
// Mock coordinators (used by pages that ref.read coordinators)
// ---------------------------------------------------------------------------

class MockHomeCoordinator extends Mock implements HomeCoordinator {}

class MockEventCoordinator extends Mock implements EventCoordinator {}

class MockAuthCoordinator extends Mock implements AuthCoordinator {}

/// No-op ActiveFilters — disables location/eligibility filters in tests.
class NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}
