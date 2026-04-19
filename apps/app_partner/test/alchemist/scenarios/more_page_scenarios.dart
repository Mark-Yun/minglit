import 'package:app_partner/src/features/more/more_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'partner_screenshot_scenario.dart';

const _testPartner = Partner(
  id: 'partner_1',
  name: '밍릿 라운지',
  contactEmail: 'hello@minglit.com',
);

class MorePageScenarios {
  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'more_page_with_partner',
      page: const MorePage(),
      overrides: [
        currentPartnerInfoProvider.overrideWith((_) async => _testPartner),
      ],
    ),
    PartnerScreenshotScenario(
      name: 'more_page_without_partner',
      page: const MorePage(),
      overrides: [
        currentPartnerInfoProvider.overrideWith((_) async => null),
      ],
    ),
    PartnerScreenshotScenario(
      name: 'more_page_with_partner_dark',
      page: const MorePage(),
      brightness: Brightness.dark,
      overrides: [
        currentPartnerInfoProvider.overrideWith((_) async => _testPartner),
      ],
    ),
    PartnerScreenshotScenario(
      name: 'more_page_without_partner_dark',
      page: const MorePage(),
      brightness: Brightness.dark,
      overrides: [
        currentPartnerInfoProvider.overrideWith((_) async => null),
      ],
    ),
  ];
}
