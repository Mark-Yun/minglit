// Ref #1072: P0 Smoke — PartnerApplyPage 화면 진입 테스트
//
// 파트너 신청 위저드 화면이 크래시 없이 렌더링됨을 검증한다.
// 5단계 위저드의 초기 렌더링 및 내비게이션 요소를 검증한다.
import 'dart:async';

import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget buildWidget({PartnerApplyState? initialState}) {
    return ProviderScope(
      overrides: [
        // Fix #1072: overrideWith() 사용 — initState에서 .notifier.loadDraft() 호출.
        // overrideWithValue()는 _SyncValueProviderElement 타입 에러 발생.
        partnerApplyControllerProvider.overrideWith(
          () => _FakePartnerApplyController(
            initialState ?? const PartnerApplyState(),
          ),
        ),
        // authRepositoryProvider 의존 차단 (Fix #1073 패턴)
        authControllerProvider.overrideWith(_FakeAuthController.new),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerApplyPage(),
      ),
    );
  }

  group('PartnerApplyPage smoke', () {
    testWidgets('step 0에서 진행 표시 바(progress indicator)가 표시된다', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(MinglitLinearProgressIndicator), findsOneWidget);
    });

    testWidgets('step 0에서 "다음" 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('다음'), findsOneWidget);
    });

    testWidgets('step 0에서 "이전" 버튼은 숨겨져 있다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('이전'), findsNothing);
    });

    testWidgets('step 1 상태로 진입 시 "이전" 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const PartnerApplyState(currentStep: 1),
        ),
      );
      await tester.pump();

      expect(find.text('이전'), findsOneWidget);
    });

    testWidgets('마지막 step에서 "신청하기" 버튼이 표시된다', (tester) async {
      // step 4 = 마지막 단계
      await tester.pumpWidget(
        buildWidget(
          initialState: const PartnerApplyState(currentStep: 4),
        ),
      );
      await tester.pump();

      expect(find.text('신청하기'), findsOneWidget);
    });
  });
}

class _FakePartnerApplyController extends PartnerApplyController {
  _FakePartnerApplyController(this._initialState);
  final PartnerApplyState _initialState;

  @override
  PartnerApplyState build() => _initialState;

  @override
  Future<void> loadDraft() async {}
}

class _FakeAuthController extends AuthController {
  @override
  FutureOr<void> build() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signInWithGoogle({String? redirectTo}) async {}

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithApple({String? redirectTo}) async {}

  @override
  Future<void> signInWithKakao({String? redirectTo}) async {}
}
