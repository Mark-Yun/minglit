import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_section.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('MinglitSection', () {
    testWidgets('renders with required params only', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitSection(title: '섹션 제목', child: Text('본문'))),
      );

      expect(find.text('섹션 제목'), findsOneWidget);
      expect(find.text('본문'), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitSection(
            title: '참가자',
            child: Column(
              children: [
                Text('홍길동'),
                Text('김철수'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('참가자'), findsOneWidget);
      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('김철수'), findsOneWidget);
    });

    testWidgets('renders with empty content child', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitSection(title: '빈 섹션', child: SizedBox.shrink())),
      );

      expect(find.text('빈 섹션'), findsOneWidget);
      expect(find.byType(MinglitSection), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitSection(
            title: '이벤트',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('더보기'),
            ),
            child: const Text('이벤트 목록'),
          ),
        ),
      );

      expect(find.text('이벤트'), findsOneWidget);
      expect(find.text('더보기'), findsOneWidget);
      expect(find.text('이벤트 목록'), findsOneWidget);
    });

    testWidgets('does not render trailing when null', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitSection(title: '제목', child: Text('내용'))),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('title has bold font weight by default', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitSection(title: '굵은 제목', child: Text('내용'))),
      );

      final titleText = tester.widget<Text>(find.text('굵은 제목'));
      expect(titleText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('applies custom titleStyle', (tester) async {
      const customStyle = TextStyle(fontSize: 24, color: Colors.red);

      await tester.pumpWidget(
        wrap(
          const MinglitSection(
            title: '커스텀',
            titleStyle: customStyle,
            child: Text('내용'),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('커스텀'));
      expect(titleText.style?.fontSize, 24);
      expect(titleText.style?.color, Colors.red);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitSection(
            title: '제목',
            padding: EdgeInsets.all(32),
            child: Text('내용'),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.byType(Column),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(32));
    });
  });
}
