@Tags(['golden'])
library;

import 'package:app_partner/src/features/settlement/widgets/settlement_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/golden_test_helpers.dart';

void main() {
  group('SettlementEmptyState golden', () {
    testWidgets('default (title only)', (tester) async {
      await expectGolden(
        tester,
        widget: const SettlementEmptyState(title: '정산 내역이 없습니다'),
        goldenFileName: 'settlement_empty_state_default.png',
      );
    });

    testWidgets('with subtitle', (tester) async {
      await expectGolden(
        tester,
        widget: const SettlementEmptyState(
          title: '정산 내역이 없습니다',
          subtitle: '이벤트를 등록하면 정산 내역이 표시됩니다.',
        ),
        goldenFileName: 'settlement_empty_state_subtitle.png',
      );
    });

    testWidgets('with action button', (tester) async {
      await expectGolden(
        tester,
        widget: SettlementEmptyState(
          title: '이벤트가 없습니다',
          subtitle: '새 이벤트를 만들어보세요.',
          icon: Icons.event_outlined,
          actionLabel: '이벤트 만들기',
          onAction: () {},
        ),
        goldenFileName: 'settlement_empty_state_action.png',
      );
    });

    testWidgets('default (title only) (dark)', (tester) async {
      await expectGolden(
        tester,
        widget: const SettlementEmptyState(title: '정산 내역이 없습니다'),
        goldenFileName: 'settlement_empty_state_default_dark.png',
        brightness: Brightness.dark,
      );
    });

    testWidgets('with subtitle (dark)', (tester) async {
      await expectGolden(
        tester,
        widget: const SettlementEmptyState(
          title: '정산 내역이 없습니다',
          subtitle: '이벤트를 등록하면 정산 내역이 표시됩니다.',
        ),
        goldenFileName: 'settlement_empty_state_subtitle_dark.png',
        brightness: Brightness.dark,
      );
    });

    testWidgets('with action button (dark)', (tester) async {
      await expectGolden(
        tester,
        widget: SettlementEmptyState(
          title: '이벤트가 없습니다',
          subtitle: '새 이벤트를 만들어보세요.',
          icon: Icons.event_outlined,
          actionLabel: '이벤트 만들기',
          onAction: () {},
        ),
        goldenFileName: 'settlement_empty_state_action_dark.png',
        brightness: Brightness.dark,
      );
    });
  });
}
