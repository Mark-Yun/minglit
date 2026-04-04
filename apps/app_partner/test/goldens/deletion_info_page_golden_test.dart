// Regression test for #951: design token replacement (BorderRadius hardcoding)
@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/account_deletion/account_deletion_coordinator.dart';
import 'package:app_partner/src/features/account_deletion/ui/deletion_info_page.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import '../utils/partner_golden_test_helpers.dart';

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
    when(
      () => mockRouter.push(
        any<String>(),
        extra: any<Object?>(named: 'extra'),
      ),
    ).thenAnswer((_) async => null);
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  goldenTest(
    'DeletionInfoPage — reason 없음 (light)',
    fileName: 'deletion_info_page_no_reason_light',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'no reason (light)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              overrides: [
                goRouterProvider.overrideWithValue(mockRouter),
                accountDeletionCoordinatorProvider.overrideWith(
                  (ref) => AccountDeletionCoordinator(mockRouter),
                ),
              ],
              page: const DeletionInfoPage(),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'DeletionInfoPage — reason 있음 (light)',
    fileName: 'deletion_info_page_with_reason_light',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'with reason (light)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              overrides: [
                goRouterProvider.overrideWithValue(mockRouter),
                accountDeletionCoordinatorProvider.overrideWith(
                  (ref) => AccountDeletionCoordinator(mockRouter),
                ),
              ],
              page: const DeletionInfoPage(
                reasonCode: 'service_dissatisfaction',
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'DeletionInfoPage — reason 없음 (dark)',
    fileName: 'deletion_info_page_no_reason_dark',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'no reason (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              brightness: Brightness.dark,
              overrides: [
                goRouterProvider.overrideWithValue(mockRouter),
                accountDeletionCoordinatorProvider.overrideWith(
                  (ref) => AccountDeletionCoordinator(mockRouter),
                ),
              ],
              page: const DeletionInfoPage(),
            ),
          ),
        ),
      ],
    ),
  );
}
