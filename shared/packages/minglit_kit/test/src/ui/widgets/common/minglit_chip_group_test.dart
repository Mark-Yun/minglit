import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_chip_group.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinglitChipGroup', () {
    testWidgets('scrollable=true renders ListView with correct height',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          const MinglitChipGroup(
            children: [
              Chip(label: Text('A')),
              Chip(label: Text('B')),
            ],
          ),
        ),
      );
      expect(find.byType(ListView), findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(ListView),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.height, 40);
    });

    testWidgets('scrollable=false renders Wrap', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const MinglitChipGroup(
            scrollable: false,
            children: [
              Chip(label: Text('A')),
              Chip(label: Text('B')),
            ],
          ),
        ),
      );
      expect(find.byType(Wrap), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('empty children renders without crash', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const MinglitChipGroup(children: []),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('children are displayed', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const MinglitChipGroup(
            children: [
              Chip(label: Text('Chip 1')),
              Chip(label: Text('Chip 2')),
              Chip(label: Text('Chip 3')),
            ],
          ),
        ),
      );
      expect(find.text('Chip 1'), findsOneWidget);
      expect(find.text('Chip 2'), findsOneWidget);
      expect(find.text('Chip 3'), findsOneWidget);
    });
  });
}
