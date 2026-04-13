// IT-P01: Onboarding → Event 생성까지의 Critical User Journey
//
// 파트너 신청 → 심사 대기 → 이벤트 생성 흐름의 주요 화면을 캡처하는
// 헤드리스 위젯 테스트.
//
// 각 testWidgets의 주요 스텝에 VisualQA capture 호출이 추가된다.
// capture 실패 시 테스트 자체는 실패하지 않는다.

import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_page.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_status_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import '../visual_qa/visual_qa_helper.dart';

// ---------------------------------------------------------------------------
// Shared setup
// ---------------------------------------------------------------------------

Widget _buildApplyPage(List<dynamic> overrides) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ko'),
      home: PartnerApplyPage(),
    ),
  );
}

Widget _buildStatusPage(List<dynamic> overrides) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ko'),
      home: PartnerApplyStatusPage(),
    ),
  );
}

// ---------------------------------------------------------------------------
// IT-P01
// ---------------------------------------------------------------------------

void main() {
  late MockPartnerRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(const PartnerApplication(id: '', userId: ''));
  });

  setUp(() {
    mockRepo = MockPartnerRepository();
    // getMyApplication을 stub으로 막아 loadDraft가 완료될 수 있도록 함
    when(() => mockRepo.getMyApplication()).thenAnswer(
      (_) async => null,
    );
    when(() => mockRepo.saveDraft(any())).thenAnswer(
      (_) async => const PartnerApplication(id: 'draft_id', userId: 'user_1'),
    );
  });

  group('IT-P01: Onboarding → Event', () {
    // -----------------------------------------------------------------------
    // S1: PartnerApplyPage 초기 렌더링
    // -----------------------------------------------------------------------
    testWidgets(
      'S1 - PartnerApplyPage renders step 0 with progress indicator',
      (tester) async {
        await tester.pumpWidget(
          _buildApplyPage([
            partnerRepositoryProvider.overrideWithValue(mockRepo),
          ]),
        );
        await tester.pump();

        // Capture: 초기 화면
        await tester.capture('step0_initial');

        expect(find.byType(MinglitLinearProgressIndicator), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // S2: 컨트롤러로 step 1 이동 후 이전 버튼 표시 확인
    // -----------------------------------------------------------------------
    testWidgets('S2 - controller setStep(1) shows 이전 button', (tester) async {
      await tester.pumpWidget(
        _buildApplyPage([
          partnerRepositoryProvider.overrideWithValue(mockRepo),
        ]),
      );
      await tester.pump();

      // Capture: step 0 상태
      await tester.capture('step0_before_next');

      // PageView 애니메이션 없이 컨트롤러로 직접 step 이동
      final element = tester.element(find.byType(PartnerApplyPage));
      ProviderScope.containerOf(
        element,
      ).read(partnerApplyControllerProvider.notifier).setStep(1);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Capture: step 1 상태
      await tester.capture('step1_after_next');

      expect(find.text('이전'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // S3: 마지막 스텝(step 4)에서 신청하기 버튼 표시
    // -----------------------------------------------------------------------
    testWidgets('S3 - step 4 shows 신청하기 button', (tester) async {
      await tester.pumpWidget(
        _buildApplyPage([
          partnerRepositoryProvider.overrideWithValue(mockRepo),
        ]),
      );
      await tester.pump();

      final element = tester.element(find.byType(PartnerApplyPage));
      ProviderScope.containerOf(
        element,
      ).read(partnerApplyControllerProvider.notifier).setStep(4);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Capture: 신청하기 버튼이 있는 마지막 스텝
      await tester.capture('step4_submit_button');

      expect(find.text('신청하기'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // S4: 심사 대기 상태 (PartnerApplyStatusPage - pendingReview)
    // -----------------------------------------------------------------------
    testWidgets('S4 - PartnerApplyStatusPage shows pending message', (
      tester,
    ) async {
      when(() => mockRepo.getMyApplication()).thenAnswer(
        (_) => SynchronousFuture<PartnerApplication?>(
          const PartnerApplication(
            id: 'app_1',
            userId: 'user_1',
            status: 'pending',
          ),
        ),
      );

      await tester.pumpWidget(
        _buildStatusPage([
          partnerRepositoryProvider.overrideWith((ref) => mockRepo),
          onboardingStateProvider.overrideWith(
            (ref) => SynchronousFuture(OnboardingState.pendingReview),
          ),
        ]),
      );
      await tester.pump();
      await tester.pump();

      // Capture: 심사 대기 화면
      await tester.capture('status_pending_review');

      expect(find.textContaining('심사 중입니다'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // S5: 보완 필요 상태 (needsCorrection)
    // -----------------------------------------------------------------------
    testWidgets(
      'S5 - PartnerApplyStatusPage shows needsCorrection with edit button',
      (tester) async {
        const adminComment = '사업자 등록증을 다시 제출해주세요.';

        when(() => mockRepo.getMyApplication()).thenAnswer(
          (_) => SynchronousFuture<PartnerApplication?>(
            const PartnerApplication(
              id: 'app_2',
              userId: 'user_2',
              status: 'needs_correction',
              adminComment: adminComment,
            ),
          ),
        );

        await tester.pumpWidget(
          _buildStatusPage([
            partnerRepositoryProvider.overrideWith((ref) => mockRepo),
            onboardingStateProvider.overrideWith(
              (ref) => SynchronousFuture(OnboardingState.needsCorrection),
            ),
          ]),
        );
        await tester.pump();
        await tester.pump();

        // Capture: 보완 필요 화면
        await tester.capture('status_needs_correction');

        expect(find.textContaining('보완이 필요합니다'), findsOneWidget);
        expect(find.text(adminComment), findsOneWidget);
        expect(find.text('신청서 수정하기'), findsOneWidget);
      },
    );
  });
}
