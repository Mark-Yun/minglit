@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/more/more_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/partner_golden_test_helpers.dart';

const _testPartner = Partner(
  id: 'partner_1',
  name: '밍릿 라운지',
  contactEmail: 'hello@minglit.com',
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PackageInfo.setMockInitialValues(
      appName: 'Minglit Partner',
      packageName: 'com.minglit.partner',
      version: '26.04.934-dev',
      buildNumber: '26040934',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(const {});
  });

  goldenTest(
    'MorePage with partner profile',
    fileName: 'more_page_with_partner',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'with partner profile',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              page: const MorePage(),
              overrides: [
                currentPartnerInfoProvider.overrideWith((_) async => _testPartner),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'MorePage without partner profile',
    fileName: 'more_page_without_partner',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'without partner profile',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              page: const MorePage(),
              overrides: [
                currentPartnerInfoProvider.overrideWith((_) async => null),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'MorePage with partner profile (dark)',
    fileName: 'more_page_with_partner_dark',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'with partner profile (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              page: const MorePage(),
              brightness: Brightness.dark,
              overrides: [
                currentPartnerInfoProvider.overrideWith((_) async => _testPartner),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'MorePage without partner profile (dark)',
    fileName: 'more_page_without_partner_dark',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'without partner profile (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              page: const MorePage(),
              brightness: Brightness.dark,
              overrides: [
                currentPartnerInfoProvider.overrideWith((_) async => null),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
