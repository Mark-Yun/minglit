// CUJ tests — account / partner-account-deletion (탈퇴 사유 화면)
//
// 대응 spec: docs/features/account/partner-account-deletion/spec.md (TODO: 마이그레이션 예정)
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가.

import 'package:app_partner/src/features/account_deletion/account_deletion_coordinator.dart';
import 'package:app_partner/src/features/account_deletion/ui/deletion_reason_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

class _MockCoordinator extends Mock implements AccountDeletionCoordinator {}

class _FakeWithdrawalReason extends Fake implements WithdrawalReason {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeWithdrawalReason());
  });

  late _MockCoordinator coordinator;

  setUp(() {
    coordinator = _MockCoordinator();
  });

  List<dynamic> base() => [
    accountDeletionCoordinatorProvider.overrideWithValue(coordinator),
  ];

  cujGroup('1-1', '탈퇴 사유 선택 후 다음 단계 진입', () {
    cujCase(
      'happy: 사유 선택 → 다음 → pushInfo(reason: ...)',
      app: const DeletionReasonPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('더 이상 운영하지 않아요'));
        await t.pumpAndSettle();

        // 다음 버튼 활성 확인
        final nextBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '다음'),
        );
        expect(nextBtn.onPressed, isNotNull);

        await t.tap(find.text('다음'));
        await t.pumpAndSettle();

        verify(
          () => coordinator.pushInfo(reason: any(named: 'reason')),
        ).called(1);
      },
    );

    cujCase(
      'happy: 선택 없이 계속하기 → pushInfo(reason: null)',
      app: const DeletionReasonPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('선택하지 않고 계속하기'));
        await t.pumpAndSettle();

        // reason 없이 호출
        verify(() => coordinator.pushInfo()).called(1);
      },
    );

    cujCase(
      'edge: 사유 미선택 → 다음 비활성',
      app: const DeletionReasonPage(),
      overrides: base,
      body: (t) async {
        final nextBtn = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, '다음'),
        );
        expect(nextBtn.onPressed, isNull);
        verifyNever(
          () => coordinator.pushInfo(reason: any(named: 'reason')),
        );
      },
    );
  });
}
