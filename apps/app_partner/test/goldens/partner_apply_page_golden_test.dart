@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/partner_golden_test_helpers.dart';

void main() {
  const baseState = PartnerApplyState(
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

  // ignore: discarded_futures, goldenTest registers the case during main().
  goldenTest(
    'PartnerApplyPage wizard steps',
    fileName: 'partner_apply_page_steps',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        _partnerApplyScenario(
          name: 'step 1 basic info',
          step: 0,
          state: baseState,
        ),
        _partnerApplyScenario(
          name: 'step 2 business info',
          step: 1,
          state: baseState,
        ),
        _partnerApplyScenario(
          name: 'step 3 contact settlement',
          step: 2,
          state: baseState,
        ),
        _partnerApplyScenario(
          name: 'step 4 documents',
          step: 3,
          state: baseState,
        ),
        _partnerApplyScenario(name: 'step 5 review', step: 4, state: baseState),
      ],
    ),
  );
}

GoldenTestScenario _partnerApplyScenario({
  required String name,
  required int step,
  required PartnerApplyState state,
}) {
  return GoldenTestScenario(
    name: name,
    child: SizedBox(
      width: 390,
      height: 844,
      child: PartnerGoldenPageWrapper(
        page: _PartnerApplyStepHarness(step: step),
        overrides: [
          partnerApplyControllerProvider.overrideWith(
            () => _PartnerApplyGoldenController(state.copyWith(currentStep: 0)),
          ),
        ],
      ),
    ),
  );
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
