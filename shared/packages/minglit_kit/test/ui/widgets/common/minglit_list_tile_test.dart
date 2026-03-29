import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_list_tile.dart';

/// A minimal 1x1 transparent PNG for testing image providers.
final _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //
  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4,
  0x89, 0x00, 0x00, 0x00, 0x0a, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9c, 0x62, 0x00, 0x00, 0x00, 0x02,
  0x00, 0x01, 0xe2, 0x21, 0xbc, 0x33, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42,
  0x60, 0x82,
]);

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinglitListTile', () {
    testWidgets('renders title only', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitListTile(title: '기본 타일')),
      );

      expect(find.text('기본 타일'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitListTile(
            title: '홍길동',
            subtitle: '파트너 매니저',
          ),
        ),
      );

      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('파트너 매니저'), findsOneWidget);
    });

    testWidgets('renders CircleAvatar when avatar is provided',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitListTile(
            title: '아바타 타일',
            avatar: MemoryImage(_kTransparentImage),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitListTile(
            title: '트레일링',
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          MinglitListTile(
            title: '탭 테스트',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          MinglitListTile(
            title: '비활성',
            enabled: false,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isFalse);
    });

    testWidgets('has Semantics widget with button and enabled',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitListTile(
            title: '시맨틱 테스트',
            onTap: () {},
          ),
        ),
      );

      // Verify a Semantics widget with button=true exists in the tree.
      expect(
        find.descendant(
          of: find.byType(MinglitListTile),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.button == true &&
                w.properties.enabled == true,
          ),
        ),
        findsWidgets,
      );
    });

    testWidgets('disabled tile is not interactive', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitListTile(
            title: '비활성 시맨틱',
            enabled: false,
          ),
        ),
      );

      // When disabled without onTap, ListTile should not be tappable.
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.enabled, isFalse);
      expect(listTile.onTap, isNull);
    });

    testWidgets('avatar takes precedence over leading',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitListTile(
            title: '우선순위 테스트',
            avatar: MemoryImage(_kTransparentImage),
            leading: const Icon(Icons.person),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets('minimum touch area is at least 48dp', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitListTile(
            title: '터치 영역',
            onTap: () {},
          ),
        ),
      );

      final tileSize = tester.getSize(find.byType(ListTile));
      expect(tileSize.height, greaterThanOrEqualTo(48));
    });
  });
}
