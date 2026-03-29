import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_list_tile.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinglitListTile', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitListTile(title: '홍길동')),
      );

      expect(find.text('홍길동'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitListTile(
            title: '홍길동',
            subtitle: '서울특별시',
          ),
        ),
      );

      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('서울특별시'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitListTile(title: '제목만')),
      );

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNull);
    });

    testWidgets('renders leading widget', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitListTile(
            title: '아바타',
            leading: CircleAvatar(child: Icon(Icons.person)),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitListTile(
            title: '화살표',
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('onTap is called when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          MinglitListTile(
            title: '탭 가능',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('onTap is not called when disabled', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          MinglitListTile(
            title: '비활성',
            onTap: () => tapped = true,
            enabled: false,
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isFalse);
    });

    testWidgets('enabled is true by default', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitListTile(title: '기본')),
      );

      final widget = tester.widget<MinglitListTile>(
        find.byType(MinglitListTile),
      );
      expect(widget.enabled, isTrue);
    });

    testWidgets('uses rounded shape', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitListTile(title: '모양')),
      );

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.shape, isA<RoundedRectangleBorder>());
    });
  });
}
