import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'partner_screenshot_scenario.dart';

const _baseState = PartnerApplyState(
  brandName: '밍릿 라운지',
  introduction: '강남에서 운영하는 프라이빗 소셜 이벤트 라운지입니다.',
  bizType: 'corporate',
  bizName: '밍릿 주식회사',
  bizNumber: '123-45-67890',
  representativeName: '김대표',
  contactPhone: '010-1234-5678',
  contactEmail: 'partner@minglit.com',
  address: '서울특별시 강남구 테헤란로 123 8층',
  bankName: '신한은행',
  accountNumber: '110-123-456789',
  accountHolder: '밍릿 주식회사',
  taxEmail: 'tax@minglit.com',
  bizRegistrationPath: 'partners/partner_1/business-registration.pdf',
  bankbookPath: 'partners/partner_1/bankbook.pdf',
);

class PartnerApplyScenarios {
  static PartnerScreenshotScenario _stepScenario(String name, int step) {
    return PartnerScreenshotScenario(
      name: name,
      page: _PartnerApplyStepHarness(step: step),
      overrides: [
        partnerApplyControllerProvider.overrideWith(
          () => _PartnerApplyGoldenController(
            _baseState.copyWith(currentStep: 0),
          ),
        ),
      ],
    );
  }

  static List<PartnerScreenshotScenario> get all => [
    _stepScenario('partner_apply_step_1_basic_info', 0),
    _stepScenario('partner_apply_step_2_business_info', 1),
    _stepScenario('partner_apply_step_3_contact_settlement', 2),
    _stepScenario('partner_apply_step_4_documents', 3),
    _stepScenario('partner_apply_step_5_review', 4),
  ];
}

class _PartnerApplyStepHarness extends ConsumerStatefulWidget {
  const _PartnerApplyStepHarness({required this.step});

  final int step;

  @override
  ConsumerState<_PartnerApplyStepHarness> createState() =>
      _PartnerApplyStepHarnessState();
}

class _PartnerApplyStepHarnessState
    extends ConsumerState<_PartnerApplyStepHarness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partnerApplyControllerProvider.notifier).setStep(widget.step);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const PartnerApplyPage();
  }
}

class _PartnerApplyGoldenController extends PartnerApplyController {
  _PartnerApplyGoldenController(this._state);

  final PartnerApplyState _state;

  @override
  PartnerApplyState build() => _state;

  @override
  Future<void> loadDraft() async {}
}
