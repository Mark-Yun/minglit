import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('MinglitSection', () {
    testWidgets('renders title and child', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitSection(
            title: '섹션 제목',
            child: Text('섹션 내용'),
          ),
        ),
      );

      expect(find.text('섹션 제목'), findsOneWidget);
      expect(find.text('섹션 내용'), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitSection(
            title: '섹션 제목',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('더보기'),
            ),
            child: const Text('내용'),
          ),
        ),
      );

      expect(find.text('더보기'), findsOneWidget);
    });

    testWidgets('does not render trailing when null', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitSection(
            title: '섹션 제목',
            child: Text('내용'),
          ),
        ),
      );

      expect(find.byType(TextButton), findsNothing);
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
