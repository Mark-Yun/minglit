import 'package:app_partner/src/features/onboarding/partner_apply_status_page.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'partner_screenshot_scenario.dart';

class PartnerApplyStatusScenarios {
  static List<dynamic> _pendingOverrides() {
    final mockRepo = MockPartnerRepository();
    when(() => mockRepo.getMyApplication()).thenAnswer(
      (_) => SynchronousFuture<PartnerApplication?>(
        const PartnerApplication(
          id: 'application_pending',
          userId: 'user_1',
          status: 'pending',
        ),
      ),
    );
    return [
      partnerRepositoryProvider.overrideWith((_) => mockRepo),
      onboardingStateProvider.overrideWith(
        (_) => SynchronousFuture(OnboardingState.pendingReview),
      ),
    ];
  }

  static List<dynamic> _needsCorrectionOverrides() {
    final mockRepo = MockPartnerRepository();
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
    return [
      partnerRepositoryProvider.overrideWith((_) => mockRepo),
      onboardingStateProvider.overrideWith(
        (_) => SynchronousFuture(OnboardingState.needsCorrection),
      ),
    ];
  }

  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'partner_apply_status_page_pending',
      page: const PartnerApplyStatusPage(),
      overrides: _pendingOverrides(),
    ),
    PartnerScreenshotScenario(
      name: 'partner_apply_status_page_needs_correction',
      page: const PartnerApplyStatusPage(),
      overrides: _needsCorrectionOverrides(),
    ),
  ];
}
