// Fix #2390: Regression tests for search page accessibility labels.
// Verifies that NAF=true (Not Accessibility Friendly) issues are resolved.
import 'package:app_user/src/features/search/logic/search_coordinator.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter/material.dart';
// Riverpod 3.x: Override is no longer exported from flutter_riverpod's main
// barrel — import misc.dart explicitly.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoRouter extends Mock implements GoRouter {}

Widget _buildTestWidget({List<Override> extraOverrides = const []}) {
  final mockRouter = _MockGoRouter();
  when(() => mockRouter.push(any())).thenAnswer((_) async => null);

  return ProviderScope(
    overrides: [
      // Riverpod 3.x: FutureProvider.overrideWith expects FutureOr<T>.
      searchResultsProvider.overrideWith((_) => <Event>[]),
      goRouterProvider.overrideWithValue(mockRouter),
      searchCoordinatorProvider.overrideWith(
        (ref) => SearchCoordinator(ref.read(goRouterProvider)),
      ),
      ...extraOverrides,
    ],
    child: const MaterialApp(
      home: SearchPage(),
    ),
  );
}

void main() {
  group('SearchPage a11y — Fix #2390', () {
    testWidgets('TextField has Semantics label for screen readers', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      // The Semantics wrapper must exist with the correct label
      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '이벤트 검색 입력',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('clear button has tooltip when text is present', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      // Enter text to make the clear button appear
      await tester.enterText(find.byType(TextField), '스포츠');
      await tester.pump();

      // Clear button (IconButton) must have tooltip set — tooltip drives
      // Android contentDescription
      final clearButton = find.widgetWithIcon(IconButton, Icons.clear);
      expect(clearButton, findsOneWidget);

      final iconButton = tester.widget<IconButton>(clearButton);
      expect(iconButton.tooltip, '입력 지우기');
    });

    testWidgets('clear button is absent when text field is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      // No text → no clear button
      expect(find.widgetWithIcon(IconButton, Icons.clear), findsNothing);
    });
  });
}
