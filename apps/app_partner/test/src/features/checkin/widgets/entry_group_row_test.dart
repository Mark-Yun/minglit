import 'package:app_partner/src/features/checkin/stats/entry_group_checkin_stats_controller.dart';
import 'package:app_partner/src/features/checkin/widgets/entry_group_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 400, child: child)),
  );
}

const _groupFull = EntryGroupCheckinStats(
  id: 'g1',
  label: '남 20대 초반',
  total: 14,
  checkedIn: 13, // ratio ≈ 0.928 → error
);

const _groupMid = EntryGroupCheckinStats(
  id: 'g2',
  label: '여 20대 초반',
  total: 14,
  checkedIn: 8, // ratio ≈ 0.571 → warning
);

const _groupLow = EntryGroupCheckinStats(
  id: 'g3',
  label: '남 30대',
  total: 20,
  checkedIn: 5, // ratio = 0.25 → primary
);

Color _barColor(WidgetTester tester) {
  final progressBar = tester.widget<LinearProgressIndicator>(
    find.byType(LinearProgressIndicator),
  );
  final animation = progressBar.valueColor;
  expect(animation, isA<AlwaysStoppedAnimation<Color>>());
  return (animation! as AlwaysStoppedAnimation<Color>).value;
}

void main() {
  group('EntryGroupRow', () {
    testWidgets('레이블과 체크인 숫자 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(const EntryGroupRow(stats: _groupFull, showDivider: false)),
      );

      expect(find.text('남 20대 초반'), findsOneWidget);
      // RichText로 렌더링되어 합산 텍스트로 검증
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == '13/14',
        ),
        findsOneWidget,
      );
    });

    testWidgets('LinearProgressIndicator 렌더링', (tester) async {
      await tester.pumpWidget(
        _wrap(const EntryGroupRow(stats: _groupMid, showDivider: false)),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('showDivider=true이면 Divider 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(const EntryGroupRow(stats: _groupLow, showDivider: true)),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('showDivider=false이면 Divider 없음', (tester) async {
      await tester.pumpWidget(
        _wrap(const EntryGroupRow(stats: _groupLow, showDivider: false)),
      );

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('완충률 ≥90% — error 색상 진행률 바', (tester) async {
      await tester.pumpWidget(
        _wrap(const EntryGroupRow(stats: _groupFull, showDivider: false)),
      );

      final barColor = _barColor(tester);
      final scheme = Theme.of(
        tester.element(find.byType(LinearProgressIndicator)),
      ).colorScheme;
      expect(barColor, scheme.error);
    });

    testWidgets('완충률 50–89% — warning 색상 진행률 바', (tester) async {
      await tester.pumpWidget(
        _wrap(const EntryGroupRow(stats: _groupMid, showDivider: false)),
      );

      final barColor = _barColor(tester);
      final scheme = Theme.of(
        tester.element(find.byType(LinearProgressIndicator)),
      ).colorScheme;
      // MinglitColors.warning — error, primary와 다른 색
      expect(barColor, isNot(scheme.error));
      expect(barColor, isNot(scheme.primary));
      expect(barColor, MinglitColors.warning);
    });

    testWidgets('완충률 <50% — primary 색상 진행률 바', (tester) async {
      await tester.pumpWidget(
        _wrap(const EntryGroupRow(stats: _groupLow, showDivider: false)),
      );

      final barColor = _barColor(tester);
      final scheme = Theme.of(
        tester.element(find.byType(LinearProgressIndicator)),
      ).colorScheme;
      expect(barColor, scheme.primary);
    });

    testWidgets('Semantics 레이블 포함', (tester) async {
      await tester.pumpWidget(
        _wrap(const EntryGroupRow(stats: _groupFull, showDivider: false)),
      );

      expect(find.bySemanticsLabel(RegExp(r'남 20대 초반')), findsOneWidget);
    });
  });
}
