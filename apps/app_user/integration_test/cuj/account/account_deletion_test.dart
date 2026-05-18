// CUJ tests — account / account-deletion (유저 탈퇴 플로우)
//
// 대응 spec: docs/features/account/account-deletion/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// Fix #2555: app_user account-deletion CUJ integration test 누락 해소

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_info_page.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart';
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

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 탈퇴 사유 선택 후 안내 화면 진입 (FR-1, FR-2)
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '탈퇴 사유 선택 후 안내 화면 진입', () {
    cujCase(
      'happy: 사유 선택 → 다음 → pushInfo(reason: ...)',
      app: const DeletionReasonPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('개인정보가 걱정돼요'));
        await t.pumpAndSettle();

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

        verify(() => coordinator.pushInfo()).called(1);
      },
    );

    cujCase(
      'edge: 사유 미선택 시 다음 버튼 비활성',
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

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 안내 화면에서 손실/보존 정보 확인 후 진행 (FR-3)
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '안내 화면에서 계속 진행 → pushVerify', () {
    cujCase(
      'happy: 탈퇴 전 확인 화면 렌더 + 계속 진행 → pushVerify 호출',
      app: const DeletionInfoPage(),
      overrides: base,
      body: (t) async {
        expect(find.text('탈퇴 전 확인'), findsOneWidget);

        await t.tap(find.text('계속 진행'));
        await t.pumpAndSettle();

        verify(() => coordinator.pushVerify()).called(1);
      },
    );

    cujCase(
      'happy: 사유 있는 경우 선택한 탈퇴 사유 표시',
      app: const DeletionInfoPage(
        reasonCode: 'privacy_concern',
      ),
      overrides: base,
      body: (t) async {
        expect(find.text('선택한 탈퇴 사유'), findsOneWidget);
        expect(find.text('계속 진행'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-5: 완료 화면 렌더링 확인 (FR-9)
  // ---------------------------------------------------------------------------

  cujGroup('1-5', '탈퇴 완료 화면 렌더링', () {
    cujCase(
      'happy: 탈퇴 완료 화면 — 체크 아이콘 + 안내 문구 + 확인 버튼 렌더',
      app: const DeletionCompletePage(),
      overrides: base,
      body: (t) async {
        expect(find.text('탈퇴 요청이 완료됐어요'), findsOneWidget);
        expect(find.text('확인'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      },
    );
  });
}
