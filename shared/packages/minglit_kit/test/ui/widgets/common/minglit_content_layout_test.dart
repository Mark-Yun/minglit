import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mds/src/theme/minglit_theme.dart';
import 'package:mds/src/ui/widgets/common/minglit_content_layout.dart';
import 'package:mds/src/ui/widgets/common/minglit_section.dart';
import 'package:mds/src/ui/widgets/common/minglit_section_divider.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('MinglitContentLayout', () {
    testWidgets('renders all sections', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitContentLayout(
            sections: [
              MinglitSection(title: '섹션 1', child: Text('내용 1')),
              MinglitSection(title: '섹션 2', child: Text('내용 2')),
              MinglitSection(title: '섹션 3', child: Text('내용 3')),
            ],
          ),
        ),
      );

      expect(find.text('섹션 1'), findsOneWidget);
      expect(find.text('내용 1'), findsOneWidget);
      expect(find.text('섹션 2'), findsOneWidget);
      expect(find.text('내용 2'), findsOneWidget);
      expect(find.text('섹션 3'), findsOneWidget);
      expect(find.text('내용 3'), findsOneWidget);
      expect(find.byType(MinglitContentLayout), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink when sections is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const MinglitContentLayout(sections: [])),
      );

      // Fix #1464: SizedBox.shrink()는 width/height가 모두 0.0인 SizedBox.
      // (null이 아님 — 생성자가 width: 0.0, height: 0.0으로 명시함)
      final shrinkFinder = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 0.0 && widget.height == 0.0,
      );
      expect(shrinkFinder, findsOneWidget);

      // Column이 렌더링되지 않아야 함
      expect(find.byType(Column), findsNothing);
    });

    testWidgets('applies custom sectionGap between sections', (tester) async {
      const customGap = 60.0;

      await tester.pumpWidget(
        wrap(
          const MinglitContentLayout(
            sectionGap: customGap,
            sections: [
              Text('섹션 A'),
              Text('섹션 B'),
            ],
          ),
        ),
      );

      // 두 섹션 사이의 SizedBox가 customGap 높이를 가져야 함
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final gapBox = sizedBoxes.any((box) => box.height == customGap);
      expect(gapBox, isTrue);
    });

    testWidgets(
      'renders MinglitSectionDivider.thin when showDividers is true',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            const MinglitContentLayout(
              showDividers: true,
              sections: [
                Text('섹션 A'),
                Text('섹션 B'),
                Text('섹션 C'),
              ],
            ),
          ),
        );

        // 섹션이 3개이면 divider는 2개 (사이마다 하나)
        expect(find.byType(MinglitSectionDivider), findsNWidgets(2));
      },
    );

    testWidgets(
      'does not render MinglitSectionDivider when showDividers is false',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            const MinglitContentLayout(
              sections: [
                Text('섹션 A'),
                Text('섹션 B'),
              ],
            ),
          ),
        );

        expect(find.byType(MinglitSectionDivider), findsNothing);
      },
    );

    testWidgets('applies custom topPadding and bottomPadding', (tester) async {
      const customTop = 8.0;
      const customBottom = 16.0;

      await tester.pumpWidget(
        wrap(
          const MinglitContentLayout(
            topPadding: customTop,
            bottomPadding: customBottom,
            sections: [Text('섹션')],
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
      expect(
        padding.padding,
        const EdgeInsets.only(top: customTop, bottom: customBottom),
      );
    });

    testWidgets('uses default topPadding (large) and bottomPadding (xlarge)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const MinglitContentLayout(
            sections: [Text('섹션')],
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
      expect(
        padding.padding,
        const EdgeInsets.only(
          top: MinglitSpacing.large,
          bottom: MinglitSpacing.xlarge,
        ),
      );
    });

    testWidgets('uses Column with CrossAxisAlignment.start', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitContentLayout(
            sections: [Text('섹션')],
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
    });

    testWidgets('showDividers uses half-gap spacing on each side of divider', (
      tester,
    ) async {
      const customGap = 40.0;
      const halfGap = customGap / 2;

      await tester.pumpWidget(
        wrap(
          const MinglitContentLayout(
            sectionGap: customGap,
            showDividers: true,
            sections: [
              Text('섹션 A'),
              Text('섹션 B'),
            ],
          ),
        ),
      );

      // divider 전후로 halfGap 높이의 SizedBox가 존재해야 함
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final halfGapBoxes = sizedBoxes
          .where((box) => box.height == halfGap)
          .toList();
      expect(halfGapBoxes.length, greaterThanOrEqualTo(2));
    });
  });
}
