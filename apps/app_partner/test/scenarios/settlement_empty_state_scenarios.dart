import 'package:app_partner/src/features/settlement/widgets/settlement_empty_state.dart';
import 'package:flutter/material.dart';

import 'partner_screenshot_scenario.dart';

class SettlementEmptyStateScenarios {
  static List<PartnerScreenshotScenario> get all => [
    const PartnerScreenshotScenario(
      name: 'settlement_empty_state_default',
      page: SettlementEmptyState(title: '정산 내역이 없습니다'),
      isComponent: true,
    ),
    const PartnerScreenshotScenario(
      name: 'settlement_empty_state_subtitle',
      page: SettlementEmptyState(
        title: '정산 내역이 없습니다',
        subtitle: '이벤트를 등록하면 정산 내역이 표시됩니다.',
      ),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'settlement_empty_state_action',
      page: SettlementEmptyState(
        title: '이벤트가 없습니다',
        subtitle: '새 이벤트를 만들어보세요.',
        icon: Icons.event_outlined,
        actionLabel: '이벤트 만들기',
        onAction: () {},
      ),
      isComponent: true,
    ),
    const PartnerScreenshotScenario(
      name: 'settlement_empty_state_default_dark',
      page: SettlementEmptyState(title: '정산 내역이 없습니다'),
      brightness: Brightness.dark,
      isComponent: true,
    ),
    const PartnerScreenshotScenario(
      name: 'settlement_empty_state_subtitle_dark',
      page: SettlementEmptyState(
        title: '정산 내역이 없습니다',
        subtitle: '이벤트를 등록하면 정산 내역이 표시됩니다.',
      ),
      brightness: Brightness.dark,
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'settlement_empty_state_action_dark',
      page: SettlementEmptyState(
        title: '이벤트가 없습니다',
        subtitle: '새 이벤트를 만들어보세요.',
        icon: Icons.event_outlined,
        actionLabel: '이벤트 만들기',
        onAction: () {},
      ),
      brightness: Brightness.dark,
      isComponent: true,
    ),
  ];
}
