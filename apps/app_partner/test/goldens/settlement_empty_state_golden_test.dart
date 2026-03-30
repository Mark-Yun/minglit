@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/settlement/widgets/settlement_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/golden_test_helpers.dart';

void main() {
  goldenTest(
    'default (title only)',
    fileName: 'settlement_empty_state_default',
    pumpBeforeTest: pumpAndDumpTree('settlement_empty_state_default'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'default',
          child: const GoldenComponentWrapper(
            child: SettlementEmptyState(title: '정산 내역이 없습니다'),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'with subtitle',
    fileName: 'settlement_empty_state_subtitle',
    pumpBeforeTest: pumpAndDumpTree('settlement_empty_state_subtitle'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'with subtitle',
          child: const GoldenComponentWrapper(
            child: SettlementEmptyState(
              title: '정산 내역이 없습니다',
              subtitle: '이벤트를 등록하면 정산 내역이 표시됩니다.',
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'with action button',
    fileName: 'settlement_empty_state_action',
    pumpBeforeTest: pumpAndDumpTree('settlement_empty_state_action'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'with action button',
          child: GoldenComponentWrapper(
            child: SettlementEmptyState(
              title: '이벤트가 없습니다',
              subtitle: '새 이벤트를 만들어보세요.',
              icon: Icons.event_outlined,
              actionLabel: '이벤트 만들기',
              onAction: () {},
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'default (title only) (dark)',
    fileName: 'settlement_empty_state_default_dark',
    pumpBeforeTest: pumpAndDumpTree('settlement_empty_state_default_dark'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'default (dark)',
          child: const GoldenComponentWrapper(
            brightness: Brightness.dark,
            child: SettlementEmptyState(title: '정산 내역이 없습니다'),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'with subtitle (dark)',
    fileName: 'settlement_empty_state_subtitle_dark',
    pumpBeforeTest: pumpAndDumpTree('settlement_empty_state_subtitle_dark'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'with subtitle (dark)',
          child: const GoldenComponentWrapper(
            brightness: Brightness.dark,
            child: SettlementEmptyState(
              title: '정산 내역이 없습니다',
              subtitle: '이벤트를 등록하면 정산 내역이 표시됩니다.',
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'with action button (dark)',
    fileName: 'settlement_empty_state_action_dark',
    pumpBeforeTest: pumpAndDumpTree('settlement_empty_state_action_dark'),
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'with action button (dark)',
          child: GoldenComponentWrapper(
            brightness: Brightness.dark,
            child: SettlementEmptyState(
              title: '이벤트가 없습니다',
              subtitle: '새 이벤트를 만들어보세요.',
              icon: Icons.event_outlined,
              actionLabel: '이벤트 만들기',
              onAction: () {},
            ),
          ),
        ),
      ],
    ),
  );
}
