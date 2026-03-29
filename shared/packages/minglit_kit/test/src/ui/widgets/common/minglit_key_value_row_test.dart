import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_key_value_row.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinglitKeyValueRow', () {
    testWidgets('renders with required params only', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitKeyValueRow(label: '이름', value: '홍길동')),
      );

      expect(find.text('이름'), findsOneWidget);
      expect(find.text('홍길동'), findsOneWidget);
    });

    testWidgets('renders label and value in a Row', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitKeyValueRow(label: '가격', value: '10,000원')),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.text('가격'), findsOneWidget);
      expect(find.text('10,000원'), findsOneWidget);
    });

    testWidgets('renders with empty string values', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitKeyValueRow(label: '', value: '')),
      );

      expect(find.byType(MinglitKeyValueRow), findsOneWidget);
      // Both empty Text widgets should be present
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('applies bold font weight when bold is true', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitKeyValueRow(label: '총액', value: '50,000원', bold: true),
        ),
      );

      final valueText = tester.widget<Text>(find.text('50,000원'));
      expect(valueText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('applies normal font weight when bold is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const MinglitKeyValueRow(label: '수량', value: '3개')),
      );

      final valueText = tester.widget<Text>(find.text('3개'));
      expect(valueText.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('applies custom valueColor', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitKeyValueRow(
            label: '상태',
            value: '활성',
            valueColor: Colors.green,
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('활성'));
      expect(valueText.style?.color, Colors.green);
    });
  });
}
