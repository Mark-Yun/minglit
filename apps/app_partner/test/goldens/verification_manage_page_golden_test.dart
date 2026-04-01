@Tags(['golden'])
library;

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/verification/manage/verification_manage_controller.dart';
import 'package:app_partner/src/features/verification/manage/verification_manage_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/golden_test_helpers.dart';

class MockVerificationManageController extends Mock
    implements VerificationManageController {
  MockVerificationManageController(this._state);
  final VerificationManageState _state;

  @override
  FutureOr<VerificationManageState> build() => _state;

  @override
  set state(AsyncValue<VerificationManageState> value) {}

  @override
  AsyncValue<VerificationManageState> get state => AsyncData(_state);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  const activeVerification = Verification(
    id: 'v1',
    category: VerificationCategory.career,
    internalName: 'custom_career',
    displayName: '직장 인증 (재직증명서)',
    description: '회사명과 부서가 포함된 재직증명서를 업로드해주세요.',
    iconKey: 'briefcase',
  );

  const archivedVerification = Verification(
    id: 'v2',
    category: VerificationCategory.academic,
    internalName: 'custom_academic',
    displayName: '학력 인증 (졸업증명서)',
    description: '대학교 졸업증명서 또는 학위증명서입니다.',
    iconKey: 'graduation-cap',
    isActive: false,
  );

  group('VerificationManagePage Golden Tests', () {
    goldenTest(
      'active list',
      fileName: 'verification_manage_active',
      builder: () => GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(390),
        children: [
          GoldenTestScenario(
            name: 'active list with data',
            child: GoldenPageWrapper(
              child: ProviderScope(
                overrides: [
                  verificationManageControllerProvider.overrideWith(
                    () => MockVerificationManageController(
                      const VerificationManageState(
                        active: [activeVerification],
                        archived: [archivedVerification],
                      ),
                    ),
                  ),
                ],
                child: const VerificationManagePage(),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'empty state',
      fileName: 'verification_manage_empty',
      builder: () => GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(390),
        children: [
          GoldenTestScenario(
            name: 'empty active list',
            child: GoldenPageWrapper(
              child: ProviderScope(
                overrides: [
                  verificationManageControllerProvider.overrideWith(
                    () => MockVerificationManageController(
                      const VerificationManageState(),
                    ),
                  ),
                ],
                child: const VerificationManagePage(),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'active list (dark)',
      fileName: 'verification_manage_active_dark',
      builder: () => GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(390),
        children: [
          GoldenTestScenario(
            name: 'active list (dark)',
            child: GoldenPageWrapper(
              brightness: Brightness.dark,
              child: ProviderScope(
                overrides: [
                  verificationManageControllerProvider.overrideWith(
                    () => MockVerificationManageController(
                      const VerificationManageState(
                        active: [activeVerification],
                        archived: [archivedVerification],
                      ),
                    ),
                  ),
                ],
                child: const VerificationManagePage(),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
