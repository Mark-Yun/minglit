import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_text_field.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );
  }

  group('MinglitTextField', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTextField(label: '이름')),
      );

      expect(find.text('이름'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTextField(label: '이메일', hintText: 'example@minglit.com')),
      );

      expect(find.text('example@minglit.com'), findsOneWidget);
    });

    testWidgets('displays error text', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTextField(label: '이메일', errorText: '올바른 이메일이 아닙니다')),
      );

      expect(find.text('올바른 이메일이 아닙니다'), findsOneWidget);
    });

    testWidgets('displays helper text', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTextField(label: '이름', helperText: '실명을 입력하세요')),
      );

      expect(find.text('실명을 입력하세요'), findsOneWidget);
    });

    testWidgets('renders disabled state', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTextField(label: '비활성', enabled: false)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('renders prefix and suffix icons', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitTextField(
            label: '검색',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.clear),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTextField(label: '비밀번호', obscureText: true)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;
      await tester.pumpWidget(
        wrap(MinglitTextField(label: '입력', onChanged: (v) => changedValue = v)),
      );

      await tester.enterText(find.byType(TextField), '안녕하세요');
      expect(changedValue, '안녕하세요');
    });

    testWidgets('supports multiline input', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTextField(label: '메모', maxLines: 3)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 3);
    });

    testWidgets('uses OutlineInputBorder with rounded corners', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTextField(label: '테스트')),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration!;
      final border = decoration.border as OutlineInputBorder;

      expect(border.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('label is accessible via semantics', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTextField(label: '접근성 테스트')),
      );

      expect(find.text('접근성 테스트'), findsOneWidget);
    });
  });
}
