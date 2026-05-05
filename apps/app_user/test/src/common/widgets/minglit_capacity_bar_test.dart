import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: Scaffold(body: SizedBox(width: 300, child: child)),
    );

void main() {
  group('MinglitCapacityBar', () {
    testWidgets('renders segmented mode when total <= threshold', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitCapacityBar(total: 8, filled: 4, pending: 2),
        ),
      );
      expect(find.byType(MinglitCapacityBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders continuous mode when total > threshold', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitCapacityBar(total: 100, filled: 60, pending: 20),
        ),
      );
      expect(find.byType(MinglitCapacityBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps filled and pending to total without overflow', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitCapacityBar(total: 5, filled: 10, pending: 10),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('zero filled and pending renders track only', (tester) async {
      await tester.pumpWidget(
        _wrap(const MinglitCapacityBar(total: 8, filled: 0)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('total=0 renders empty without crash', (tester) async {
      await tester.pumpWidget(
        _wrap(const MinglitCapacityBar(total: 0, filled: 0)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('custom segmentThreshold overrides default', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitCapacityBar(
            total: 50,
            filled: 25,
            segmentThreshold: 60,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('custom color and height accepted', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MinglitCapacityBar(
            total: 10,
            filled: 5,
            height: 4,
            color: Color(0xFF0000FF),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
