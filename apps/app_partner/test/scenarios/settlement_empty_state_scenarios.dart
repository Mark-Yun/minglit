import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'partner_screenshot_scenario.dart';

class SettlementEmptyStateScenarios {
  static List<PartnerScreenshotScenario> get all => [
    const PartnerScreenshotScenario(
      name: 'settlement_empty_state_default',
      page: MinglitEmptyState(
        title: '정산 내역이 없습니다',
        icon: Icons.receipt_long_outlined,
      ),
      isComponent: true,
    ),
    const PartnerScreenshotScenario(
      name: 'settlement_empty_state_subtitle',
      page: MinglitEmptyState(
        title: '정산 내역이 없습니다',
        icon: Icons.receipt_long_outlined,
        subtitle: '이벤트를 등록하면 정산 내역이 표시됩니다.',
      ),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'settlement_empty_state_action',
      page: MinglitEmptyState(
        title: '이벤트가 없습니다',
        icon: Icons.event_outlined,
        subtitle: '새 이벤트를 만들어보세요.',
        actionLabel: '이벤트 만들기',
        onAction: () {},
      ),
      isComponent: true,
    ),
    const PartnerScreenshotScenario(
      name: 'settlement_empty_state_default_dark',
      page: MinglitEmptyState(
        title: '정산 내역이 없습니다',
        icon: Icons.receipt_long_outlined,
      ),
      brightness: Brightness.dark,
      isComponent: true,
    ),
    const PartnerScreenshotScenario(
      name: 'settlement_empty_state_subtitle_dark',
      page: MinglitEmptyState(
        title: '정산 내역이 없습니다',
        icon: Icons.receipt_long_outlined,
        subtitle: '이벤트를 등록하면 정산 내역이 표시됩니다.',
      ),
      brightness: Brightness.dark,
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'settlement_empty_state_action_dark',
      page: MinglitEmptyState(
        title: '이벤트가 없습니다',
        icon: Icons.event_outlined,
        subtitle: '새 이벤트를 만들어보세요.',
        actionLabel: '이벤트 만들기',
        onAction: () {},
      ),
      brightness: Brightness.dark,
      isComponent: true,
    ),
  ];
}
