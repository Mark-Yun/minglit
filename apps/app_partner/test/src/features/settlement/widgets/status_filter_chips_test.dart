// Fix #1103: settlement 도메인 테스트 보강

import 'package:app_partner/src/features/settlement/widgets/status_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget({
    String? selectedStatus,
    required ValueChanged<String?> onStatusChanged,
  }) {
    // Use a very wide view so all chips are on-screen and tappable.
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 2000,
          child: StatusFilterChips(
            selectedStatus: selectedStatus,
            onStatusChanged: onStatusChanged,
          ),
        ),
      ),
    );
  }

  group('StatusFilterChips widget', () {
    testWidgets('renders 8 ChoiceChip widgets', (tester) async {
      await tester.pumpWidget(
        buildWidget(selectedStatus: null, onStatusChanged: (_) {}),
      );
      expect(find.byType(ChoiceChip), findsNWidgets(8));
    });

    testWidgets('renders all expected labels', (tester) async {
      await tester.pumpWidget(
        buildWidget(selectedStatus: null, onStatusChanged: (_) {}),
      );
      for (final label in [
        '전체',
        '대기',
        '확정',
        '지급중',
        '완료',
        '실패',
        '보류',
        '취소',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets(
      '전체 chip is selected when selectedStatus is null',
      (tester) async {
        await tester.pumpWidget(
          buildWidget(selectedStatus: null, onStatusChanged: (_) {}),
        );
        // The ChoiceChip that contains '전체' should be selected
        final chips = tester.widgetList<ChoiceChip>(
          find.byType(ChoiceChip),
        );
        final allChip = chips.firstWhere(
          (c) => c.label is Text && (c.label as Text).data == '전체',
        );
        expect(allChip.selected, isTrue);
      },
    );

    testWidgets(
      'COMPLETED chip is selected when selectedStatus is COMPLETED',
      (tester) async {
        await tester.pumpWidget(
          buildWidget(
            selectedStatus: 'COMPLETED',
            onStatusChanged: (_) {},
          ),
        );
        final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
        final completedChip = chips.firstWhere(
          (c) => c.label is Text && (c.label as Text).data == '완료',
        );
        expect(completedChip.selected, isTrue);
      },
    );

    testWidgets(
      '전체 chip is not selected when specific status is selected',
      (tester) async {
        await tester.pumpWidget(
          buildWidget(
            selectedStatus: 'PENDING',
            onStatusChanged: (_) {},
          ),
        );
        final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
        final allChip = chips.firstWhere(
          (c) => c.label is Text && (c.label as Text).data == '전체',
        );
        expect(allChip.selected, isFalse);
      },
    );

    testWidgets('tapping 전체 chip calls onStatusChanged with null',
        (tester) async {
      String? received = 'INITIAL';
      await tester.pumpWidget(
        buildWidget(
          selectedStatus: 'COMPLETED',
          onStatusChanged: (s) => received = s,
        ),
      );
      await tester.tap(find.text('전체'));
      expect(received, isNull);
    });

    testWidgets('tapping PENDING chip calls onStatusChanged with PENDING',
        (tester) async {
      String? received;
      await tester.pumpWidget(
        buildWidget(
          selectedStatus: null,
          onStatusChanged: (s) => received = s,
        ),
      );
      await tester.tap(find.text('대기'));
      expect(received, 'PENDING');
    });

    testWidgets('tapping COMPLETED chip calls onStatusChanged with COMPLETED',
        (tester) async {
      String? received;
      await tester.pumpWidget(
        buildWidget(
          selectedStatus: null,
          onStatusChanged: (s) => received = s,
        ),
      );
      await tester.tap(find.text('완료'));
      expect(received, 'COMPLETED');
    });

    testWidgets('tapping FAILED chip calls onStatusChanged with FAILED',
        (tester) async {
      String? received;
      await tester.pumpWidget(
        buildWidget(
          selectedStatus: null,
          onStatusChanged: (s) => received = s,
        ),
      );
      await tester.tap(find.text('실패'));
      expect(received, 'FAILED');
    });

    testWidgets('tapping HOLD chip calls onStatusChanged with HOLD',
        (tester) async {
      String? received;
      await tester.pumpWidget(
        buildWidget(
          selectedStatus: null,
          onStatusChanged: (s) => received = s,
        ),
      );
      await tester.tap(find.text('보류'));
      expect(received, 'HOLD');
    });
  });
}
