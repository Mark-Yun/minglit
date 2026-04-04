@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/verification/create/create_verification_controller.dart';
import 'package:app_partner/src/features/verification/create/create_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/partner_golden_test_helpers.dart';

void main() {
  // The goldenTest helper registers tests synchronously and is intentionally
  // not awaited inside main().
  // ignore: discarded_futures
  goldenTest(
    'CreateVerificationPage empty builder',
    fileName: 'create_verification_page_empty',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        _buildCreateVerificationScenario(
          name: 'empty builder',
          state: const CreateVerificationState(),
        ),
      ],
    ),
  );

  // The goldenTest helper registers tests synchronously and is intentionally
  // not awaited inside main().
  // ignore: discarded_futures
  goldenTest(
    'CreateVerificationPage with configured fields',
    fileName: 'create_verification_page_with_fields',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        _buildCreateVerificationScenario(
          name: 'configured fields',
          state: const CreateVerificationState(
            displayName: '골프 핸디캡 인증',
            internalName: 'golf_handicap_2026',
            description: '최근 라운딩 기준 핸디캡 증빙을 제출받습니다.',
            fields: [
              VerificationFormField(
                key: 'handicap_text',
                type: 'text',
                label: '핸디캡',
              ),
              VerificationFormField(
                key: 'scorecard_file',
                type: 'file',
                label: '스코어카드 첨부',
                required: false,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

GoldenTestScenario _buildCreateVerificationScenario({
  required String name,
  required CreateVerificationState state,
}) {
  return GoldenTestScenario(
    name: name,
    child: SizedBox(
      width: 390,
      height: 844,
      child: PartnerGoldenPageWrapper(
        page: const CreateVerificationPage(partnerId: 'partner_1'),
        overrides: [
          createVerificationControllerProvider.overrideWith(
            () => _CreateVerificationGoldenController(state),
          ),
        ],
      ),
    ),
  );
}

class _CreateVerificationGoldenController extends CreateVerificationController {
  _CreateVerificationGoldenController(this._state);

  final CreateVerificationState _state;

  @override
  CreateVerificationState build() => _state;
}
