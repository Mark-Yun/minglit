@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_status_page.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import '../utils/partner_golden_test_helpers.dart';

void main() {
  late MockPartnerRepository mockRepo;

  setUp(() {
    mockRepo = MockPartnerRepository();
  });

  goldenTest(
    'PartnerApplyStatusPage pending review',
    fileName: 'partner_apply_status_page_pending',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () {
      when(() => mockRepo.getMyApplication()).thenAnswer(
        (_) => SynchronousFuture<PartnerApplication?>(
          const PartnerApplication(
            id: 'application_pending',
            userId: 'user_1',
            status: 'pending',
          ),
        ),
      );

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'pending review',
            child: SizedBox(
              width: 390,
              height: 844,
              child: PartnerGoldenPageWrapper(
                page: const PartnerApplyStatusPage(),
                overrides: [
                  partnerRepositoryProvider.overrideWith((_) => mockRepo),
                  onboardingStateProvider.overrideWith(
                    (_) => SynchronousFuture(OnboardingState.pendingReview),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  goldenTest(
    'PartnerApplyStatusPage needs correction',
    fileName: 'partner_apply_status_page_needs_correction',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () {
      when(() => mockRepo.getMyApplication()).thenAnswer(
        (_) => SynchronousFuture<PartnerApplication?>(
          const PartnerApplication(
            id: 'application_correction',
            userId: 'user_1',
            status: 'needs_correction',
            adminComment: '사업자 등록증과 통장 사본을 다시 업로드해주세요.',
          ),
        ),
      );

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'needs correction',
            child: SizedBox(
              width: 390,
              height: 844,
              child: PartnerGoldenPageWrapper(
                page: const PartnerApplyStatusPage(),
                overrides: [
                  partnerRepositoryProvider.overrideWith((_) => mockRepo),
                  onboardingStateProvider.overrideWith(
                    (_) => SynchronousFuture(OnboardingState.needsCorrection),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
