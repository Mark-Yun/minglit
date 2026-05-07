import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mds/src/theme/minglit_theme.dart';
import 'package:mds/src/ui/widgets/common/minglit_dday_chip.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: MinglitTheme.materialTheme,
  home: Scaffold(body: child),
);

void main() {
  group('MinglitDDayChip', () {
    testWidgets('today (D-0) shows "오늘" label', (tester) async {
      await tester.pumpWidget(_wrap(const MinglitDDayChip(daysUntil: 0)));
      expect(find.text('오늘'), findsOneWidget);
    });

    testWidgets('soon (D-3) shows "D-3" label', (tester) async {
      await tester.pumpWidget(_wrap(const MinglitDDayChip(daysUntil: 3)));
      expect(find.text('D-3'), findsOneWidget);
    });

    testWidgets('later (D-10) shows "D-10" label', (tester) async {
      await tester.pumpWidget(_wrap(const MinglitDDayChip(daysUntil: 10)));
      expect(find.text('D-10'), findsOneWidget);
    });

    testWidgets('custom label overrides default', (tester) async {
      await tester.pumpWidget(
        _wrap(const MinglitDDayChip(daysUntil: 0, label: '오늘 마감')),
      );
      expect(find.text('오늘 마감'), findsOneWidget);
      expect(find.text('오늘'), findsNothing);
    });

    testWidgets('negative daysUntil treated as today', (tester) async {
      await tester.pumpWidget(_wrap(const MinglitDDayChip(daysUntil: -1)));
      expect(find.text('오늘'), findsOneWidget);
    });

    testWidgets('boundary D-7 uses soon tier', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _wrap(MinglitDDayChip(key: key, daysUntil: 7)),
      );
      expect(find.text('D-7'), findsOneWidget);
    });

    testWidgets('boundary D-8 uses later tier', (tester) async {
      await tester.pumpWidget(_wrap(const MinglitDDayChip(daysUntil: 8)));
      expect(find.text('D-8'), findsOneWidget);
    });

    testWidgets('has Semantics label for accessibility', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const MinglitDDayChip(daysUntil: 3)));

      final semantics = tester.getSemantics(find.byType(MinglitDDayChip));
      expect(semantics.label, contains('3일'));
      handle.dispose();
    });

    testWidgets('today semantics label indicates 오늘 진행', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const MinglitDDayChip(daysUntil: 0)));

      final semantics = tester.getSemantics(find.byType(MinglitDDayChip));
      expect(semantics.label, contains('오늘'));
      handle.dispose();
    });

    testWidgets('custom label is used for Semantics label override', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const MinglitDDayChip(daysUntil: 5, label: '마감 임박')),
      );

      final semantics = tester.getSemantics(find.byType(MinglitDDayChip));
      expect(semantics.label, '마감 임박');
      handle.dispose();
    });
  });
}
