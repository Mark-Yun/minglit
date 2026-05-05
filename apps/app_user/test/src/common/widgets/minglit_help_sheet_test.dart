import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Future<void> _openSheet(
  WidgetTester tester, {
  String title = '도움말',
  List<HelpSection> sections = const [],
  String confirmLabel = '확인',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showMinglitHelpSheet(
              context: ctx,
              title: title,
              sections: sections,
              confirmLabel: confirmLabel,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('MinglitHelpSheet', () {
    testWidgets('renders sheet title', (tester) async {
      await _openSheet(tester, title: '파티 관리 가이드');
      expect(find.text('파티 관리 가이드'), findsOneWidget);
    });

    testWidgets('renders all section titles and bodies', (tester) async {
      await _openSheet(
        tester,
        sections: const [
          HelpSection(title: '파티가 뭔가요?', body: '파티는 소규모 모임입니다.'),
          HelpSection(title: '파티장이란?', body: '파티를 주최하는 사람입니다.'),
        ],
      );

      expect(find.text('파티가 뭔가요?'), findsOneWidget);
      expect(find.text('파티는 소규모 모임입니다.'), findsOneWidget);
      expect(find.text('파티장이란?'), findsOneWidget);
      expect(find.text('파티를 주최하는 사람입니다.'), findsOneWidget);
    });

    testWidgets('confirm button uses custom confirmLabel', (tester) async {
      await _openSheet(tester, confirmLabel: '닫기');
      expect(find.text('닫기'), findsOneWidget);
    });

    testWidgets('default confirmLabel is 확인', (tester) async {
      await _openSheet(tester);
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('tapping confirm button dismisses sheet', (tester) async {
      await _openSheet(tester, title: '안내');
      expect(find.text('안내'), findsOneWidget);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('안내'), findsNothing);
    });

    testWidgets('section with leading widget renders it', (tester) async {
      await _openSheet(
        tester,
        sections: const [
          HelpSection(
            title: '조건 안내',
            body: '조건을 확인하세요.',
            leading: Icon(Icons.info_outline),
          ),
        ],
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('조건 안내'), findsOneWidget);
    });

    testWidgets(
      'section without leading renders no extra icon',
      (tester) async {
        await _openSheet(
          tester,
          sections: const [
            HelpSection(title: '안내', body: '내용입니다.'),
          ],
        );

        expect(find.byType(Icon), findsNothing);
      },
    );

    testWidgets(
      'renders without crash for empty sections list',
      (tester) async {
        await _openSheet(tester);
        expect(find.text('확인'), findsOneWidget);
      },
    );

    testWidgets(
      'first section has no top divider; second does',
      (tester) async {
        await _openSheet(
          tester,
          sections: const [
            HelpSection(title: '첫째', body: '내용1'),
            HelpSection(title: '둘째', body: '내용2'),
          ],
        );

        final decoratedBoxes = tester.widgetList<DecoratedBox>(
          find.byType(DecoratedBox),
        ).toList();

        final sectionBoxes = decoratedBoxes.where((b) {
          final decoration = b.decoration;
          if (decoration is BoxDecoration) {
            final border = decoration.border;
            if (border is Border) {
              return border.top.width > 0;
            }
          }
          return false;
        }).toList();

        // Exactly one divider (between section 1 and 2)
        expect(sectionBoxes.length, 1);
      },
    );
  });
}
