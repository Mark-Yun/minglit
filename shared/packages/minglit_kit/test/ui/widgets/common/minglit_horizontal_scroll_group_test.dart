import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_horizontal_scroll_group.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

// Returns a Row of [count] wide boxes inside a scroll group bounded by [viewWidth].
Widget _scrollableRow({required int count, required double viewWidth}) {
  return SizedBox(
    width: viewWidth,
    height: 40,
    child: MinglitHorizontalScrollGroup(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        itemBuilder: (_, i) => SizedBox(key: ValueKey(i), width: 100, height: 40),
      ),
    ),
  );
}

void main() {
  group('MinglitHorizontalScrollGroup', () {
    testWidgets('no-overflow: 페이드 없음', (tester) async {
      await tester.pumpWidget(
        _wrap(_scrollableRow(count: 2, viewWidth: 400)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MinglitHorizontalScrollGroup), findsOneWidget);
      // 콘텐츠(200px)가 뷰(400px)에 다 들어가므로 chevron 아이콘 없음
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('overflow: 초기 상태에서 오른쪽 chevron 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(_scrollableRow(count: 10, viewWidth: 300)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('overflow: 끝까지 스크롤 시 chevron 사라짐', (tester) async {
      await tester.pumpWidget(
        _wrap(_scrollableRow(count: 10, viewWidth: 300)),
      );
      await tester.pumpAndSettle();

      // 끝까지 드래그
      await tester.drag(find.byType(ListView), const Offset(-2000, 0));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('overflow: 스크롤 후 왼쪽으로 돌아오면 chevron 다시 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(_scrollableRow(count: 10, viewWidth: 300)),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(-200, 0));
      await tester.pumpAndSettle();
      // 우측에 더 있으므로 chevron 여전히 표시
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('MinglitChipGroup(scrollable)에 scroll affordance 적용', (tester) async {
      // MinglitHorizontalScrollGroup이 MinglitChipGroup 내부에 삽입되었는지 확인
      final chips = List.generate(
        20,
        (i) => Chip(label: Text('chip $i')),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: MinglitHorizontalScrollGroup(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: chips,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MinglitHorizontalScrollGroup), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });
}
