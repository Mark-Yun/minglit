import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('MinglitKeyValueRow', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitKeyValueRow(label: '이름', value: '홍길동'),
        ),
      );

      expect(find.text('이름'), findsOneWidget);
      expect(find.text('홍길동'), findsOneWidget);
    });

    testWidgets('applies bold font weight when bold is true', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitKeyValueRow(label: '총 금액', value: '20,000원', bold: true),
        ),
      );

      final valueText = tester.widget<Text>(find.text('20,000원'));
      expect(valueText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('does not apply bold by default', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitKeyValueRow(label: '항목', value: '값'),
        ),
      );

      final valueText = tester.widget<Text>(find.text('값'));
      expect(valueText.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('applies custom value color', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitKeyValueRow(
            label: '상태',
            value: '성공',
            valueColor: Colors.green,
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('성공'));
      expect(valueText.style?.color, Colors.green);
    });

    testWidgets('renders empty strings without error', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitKeyValueRow(label: '', value: ''),
        ),
      );

      // Should render two empty Text widgets without crashing
      expect(find.byType(MinglitKeyValueRow), findsOneWidget);
    });
  });
}
