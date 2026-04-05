import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/features/auth/testing/fake_auth_controller.dart';

import 'partner_screenshot_scenario.dart';

class PartnerLoginScenarios {
  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'partner_login_page_default',
      page: const PartnerLoginPage(),
      overrides: [
        authControllerProvider.overrideWith(FakeAuthController.new),
      ],
    ),
  ];
}
