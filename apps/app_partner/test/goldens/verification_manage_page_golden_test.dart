@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/verification/manage/verification_manage_controller.dart';
import 'package:app_partner/src/features/verification/manage/verification_manage_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../utils/partner_golden_test_helpers.dart';

void main() {
  final baseTime = DateTime(2026, 4, 2, 15);

  // The goldenTest helper registers tests synchronously and is intentionally
  // not awaited inside main().
  // ignore: discarded_futures
  goldenTest(
    'VerificationManagePage with active and archived items',
    fileName: 'verification_manage_page_with_items',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'active and archived',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              page: const VerificationManagePage(),
              overrides: [
                verificationManageControllerProvider.overrideWith(
                  () => _VerificationManageGoldenController(
                    VerificationManageState(
                      active: [
                        Verification(
                          id: 'verification_active_1',
                          partnerId: 'partner_1',
                          category: VerificationCategory.career,
                          internalName: 'career_vip',
                          displayName: '직장 인증',
                          description: '회사 재직 여부를 확인합니다.',
                          iconKey: 'briefcase',
                          formSchema: [
                            const VerificationFormField(
                              key: 'company_name',
                              type: 'text',
                              label: '회사명',
                            ),
                            const VerificationFormField(
                              key: 'certificate',
                              type: 'file',
                              label: '재직증명서',
                            ),
                          ],
                          createdAt: baseTime,
                        ),
                        Verification(
                          id: 'verification_active_2',
                          partnerId: 'partner_1',
                          category: VerificationCategory.academic,
                          internalName: 'academic_graduate',
                          displayName: '학력 인증',
                          description: '졸업/재학 증빙을 제출합니다.',
                          iconKey: 'school',
                          formSchema: [
                            const VerificationFormField(
                              key: 'school_name',
                              type: 'text',
                              label: '학교명',
                            ),
                          ],
                          createdAt: baseTime.subtract(const Duration(days: 1)),
                        ),
                      ],
                      archived: [
                        Verification(
                          id: 'verification_archived_1',
                          partnerId: 'partner_1',
                          category: VerificationCategory.asset,
                          internalName: 'asset_income',
                          displayName: '소득 인증',
                          description: '소득 증빙 서류를 제출합니다.',
                          iconKey: 'payments',
                          formSchema: [
                            const VerificationFormField(
                              key: 'income_file',
                              type: 'file',
                              label: '소득 증빙',
                            ),
                          ],
                          isActive: false,
                          createdAt: baseTime.subtract(const Duration(days: 5)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // The goldenTest helper registers tests synchronously and is intentionally
  // not awaited inside main().
  // ignore: discarded_futures
  goldenTest(
    'VerificationManagePage empty state',
    fileName: 'verification_manage_page_empty',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'empty state',
          child: SizedBox(
            width: 390,
            height: 844,
            child: PartnerGoldenPageWrapper(
              page: const VerificationManagePage(),
              overrides: [
                verificationManageControllerProvider.overrideWith(
                  () => _VerificationManageGoldenController(
                    const VerificationManageState(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _VerificationManageGoldenController extends VerificationManageController {
  _VerificationManageGoldenController(this._state);

  final VerificationManageState _state;

  @override
  FutureOr<VerificationManageState> build() => _state;
}
