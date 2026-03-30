import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_bottom_sheet.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinglitBottomSheet', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitBottomSheet(
            child: Text('Content'),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('shows drag handle by default', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitBottomSheet(
            child: Text('Content'),
          ),
        ),
      );

      // Handle is a DecoratedBox with SizedBox(width: 32, height: 4)
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final handleBox = sizedBoxes.where(
        (sb) => sb.width == 32 && sb.height == 4,
      );
      expect(handleBox, isNotEmpty);
    });

    testWidgets('hides drag handle when showHandle is false', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitBottomSheet(
            showHandle: false,
            child: Text('Content'),
          ),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final handleBox = sizedBoxes.where(
        (sb) => sb.width == 32 && sb.height == 4,
      );
      expect(handleBox, isEmpty);
    });

    testWidgets('displays title when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitBottomSheet(
            title: '옵션 선택',
            child: Text('Content'),
          ),
        ),
      );

      expect(find.text('옵션 선택'), findsOneWidget);
    });

    testWidgets('does not display title when null', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitBottomSheet(
            child: Text('Content'),
          ),
        ),
      );

      // Only the child text should be present
      expect(find.text('Content'), findsOneWidget);
      // No title text
      expect(find.byType(MinglitBottomSheet), findsOneWidget);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitBottomSheet(
            padding: EdgeInsets.all(32),
            child: Text('Padded'),
          ),
        ),
      );

      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('renders with title and handle together', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitBottomSheet(
            title: '제목',
            child: Text('내용'),
          ),
        ),
      );

      expect(find.text('제목'), findsOneWidget);
      expect(find.text('내용'), findsOneWidget);

      // Handle should be present
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final handleBox = sizedBoxes.where(
        (sb) => sb.width == 32 && sb.height == 4,
      );
      expect(handleBox, isNotEmpty);
    });
  });

  group('showMinglitBottomSheet', () {
    testWidgets('opens a modal bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showMinglitBottomSheet<void>(
                    context: context,
                    title: '테스트',
                    child: const Text('바텀시트 내용'),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('테스트'), findsOneWidget);
      expect(find.text('바텀시트 내용'), findsOneWidget);
    });

    testWidgets('can be dismissed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showMinglitBottomSheet<void>(
                    context: context,
                    child: const Text('Dismissible'),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Dismissible'), findsOneWidget);

      // Tap the scrim to dismiss
      await tester.tapAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      expect(find.text('Dismissible'), findsNothing);
    });
  });
}
