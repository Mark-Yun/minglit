import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: Scaffold(body: child),
    );
  }

  group('MinglitAlert', () {
    testWidgets('renders title and content', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const MinglitAlert(
            title: '테스트 알림',
            content: '알림 내용입니다.',
          ),
        ),
      );

      expect(find.text('테스트 알림'), findsOneWidget);
      expect(find.text('알림 내용입니다.'), findsOneWidget);
    });

    testWidgets('renders custom contentWidget', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const MinglitAlert(
            title: '커스텀 알림',
            contentWidget: KeyedSubtree(
              key: Key('custom_widget'),
              child: Text('커스텀'),
            ),
          ),
        ),
      );

      expect(find.text('커스텀 알림'), findsOneWidget);
      expect(find.byKey(const Key('custom_widget')), findsOneWidget);
      // content string should be ignored if contentWidget is provided
    });

    testWidgets('destructive type shows warning icon', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const MinglitAlert(
            title: '삭제 확인',
            type: MinglitAlertType.destructive,
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('showConfirm confirm button returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await MinglitAlert.showConfirm(
                  context: context,
                  title: '확인 창',
                  content: '계속하시겠습니까?',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('확인 창'), findsOneWidget);
      
      // Tap confirm button (default text '확인')
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('showConfirm cancel button returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await MinglitAlert.showConfirm(
                  context: context,
                  title: '확인 창',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap cancel button (default text '취소')
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('destructive showConfirm uses destructive button', (tester) async {
      await tester.pumpWidget(
        buildApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                MinglitAlert.showConfirm(
                  context: context,
                  title: '삭제',
                  isDestructive: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Find confirm button (ElevatedButton for primary/destructive)
      final confirmButton = find.byType(ElevatedButton).at(1); // 0 is 'Open'
      final widget = tester.widget<ElevatedButton>(confirmButton);
      
      // Destructive button uses error color
      final color = widget.style?.backgroundColor?.resolve({});
      expect(color, MinglitColors.error);
    });
  });
}
