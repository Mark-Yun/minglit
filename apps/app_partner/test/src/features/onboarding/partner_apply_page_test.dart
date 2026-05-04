import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_page.dart';
import 'package:app_partner/src/features/onboarding/steps/step1_basic_info.dart';
import 'package:app_partner/src/features/onboarding/steps/step5_review.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

void main() {
  late MockPartnerRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(const PartnerApplication(id: '', userId: ''));
  });

  setUp(() {
    mockRepo = MockPartnerRepository();
    when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
    when(() => mockRepo.saveDraft(any())).thenAnswer(
      (_) async => const PartnerApplication(id: 'draft_id', userId: 'user_1'),
    );
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        partnerRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerApplyPage(),
      ),
    );
  }

  group('PartnerApplyPage', () {
    testWidgets('renders progress indicator on step 0', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(MinglitLinearProgressIndicator), findsOneWidget);
    });

    testWidgets('"다음" button exists on step 0', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('다음'), findsOneWidget);
    });

    testWidgets('"이전" button is hidden on step 0', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('이전'), findsNothing);
    });

    testWidgets('"이전" button appears after moving to step 1', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final element = tester.element(find.byType(PartnerApplyPage));
      ProviderScope.containerOf(
        element,
      ).read(partnerApplyControllerProvider.notifier).setStep(1);

      await tester.pumpAndSettle();

      expect(find.text('이전'), findsOneWidget);
    });

    testWidgets('"신청하기" button exists on step 4', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final element = tester.element(find.byType(PartnerApplyPage));
      ProviderScope.containerOf(
        element,
      ).read(partnerApplyControllerProvider.notifier).setStep(4);

      await tester.pumpAndSettle();

      expect(find.text('신청하기'), findsOneWidget);
    });

    // Fix #2161: Step 2(biz info) — Next button gates on validateStep(1)
    group('Fix #2161 — Step 2 biz info validation', () {
      testWidgets('Next disabled when biz fields are empty', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier).setStep(1);

        await tester.pumpAndSettle();

        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull,
        );
      });

      testWidgets('Next enabled when all biz fields filled', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        final notifier = ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier);
        notifier
          ..setStep(1)
          ..updateField('bizName', 'Example Corp')
          ..updateField('bizNumber', '123-45-67890')
          ..updateField('representativeName', '홍길동');

        await tester.pumpAndSettle();

        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull,
        );
      });
    });

    // Fix #2162: Step 3(contact/bank) — Next button gates on validateStep(2)
    group('Fix #2162 — Step 3 contact/bank validation', () {
      testWidgets('Next disabled when contact fields are empty', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier).setStep(2);

        await tester.pumpAndSettle();

        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull,
        );
      });

      testWidgets('Next enabled when all contact and bank fields filled', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        final notifier = ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier);
        notifier
          ..setStep(2)
          ..updateField('contactPhone', '010-1234-5678')
          ..updateField('contactEmail', 'biz@example.com')
          ..updateField('bankName', '국민은행')
          ..updateField('accountNumber', '123456789012')
          ..updateField('accountHolder', '홍길동');

        await tester.pumpAndSettle();

        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull,
        );
      });
    });

    // Fix #2163: Step 4(documents) — Next button gates on validateStep(3)
    group('Fix #2163 — Step 4 documents validation', () {
      testWidgets('Next disabled when no documents uploaded', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier).setStep(3);

        await tester.pumpAndSettle();

        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull,
        );
      });
    });
  });

  // Fix #2130: draft restore 시 animateToPage 애니메이션 중
  // AppBar 제목(currentStep 기반)과 PageView 내용이 불일치하는 버그 회귀 방지.
  // _restoreDraft()가 jumpToPage로 즉시 이동하는지 검증.
  group('Fix #2130 — draft restore 후 title/content sync', () {
    testWidgets('step 4 draft 복원 후 AppBar가 "최종 확인"을 표시한다', (tester) async {
      when(() => mockRepo.getMyApplication()).thenAnswer(
        (_) async => const PartnerApplication(
          id: 'draft-1',
          userId: 'user-1',
          status: 'draft',
          currentStep: 4,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('최종 확인'), findsOneWidget);
    });

    testWidgets('step 4 draft 복원 후 controller state가 currentStep=4다', (
      tester,
    ) async {
      when(() => mockRepo.getMyApplication()).thenAnswer(
        (_) async => const PartnerApplication(
          id: 'draft-1',
          userId: 'user-1',
          status: 'draft',
          currentStep: 4,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(PartnerApplyPage));
      final state = ProviderScope.containerOf(
        element,
      ).read(partnerApplyControllerProvider);
      expect(state.currentStep, 4);
    });

    testWidgets('step 4 draft 복원 직후 PageView가 page 0(기본 정보)이 아닌 page 4에 있다', (
      tester,
    ) async {
      when(() => mockRepo.getMyApplication()).thenAnswer(
        (_) async => const PartnerApplication(
          id: 'draft-1',
          userId: 'user-1',
          status: 'draft',
          currentStep: 4,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      // pump만 하고 animateToPage 애니메이션이 완료되기 전 상태를 확인
      await tester.pump(); // first frame
      await tester.pump(); // post-frame callback fires (loadDraft starts)
      await tester.pump(); // loadDraft completes (mock is instant)

      // Fix #2130 적용 후: jumpToPage(4)이므로 즉시 page 4로 이동.
      // 수정 전 animateToPage(4)라면 이 시점에 PageView는 여전히 page 0 근처에
      // 있으므로 Step1BasicInfo가 렌더되고 Step5Review는 위젯 트리에 없다.
      final element = tester.element(find.byType(PartnerApplyPage));
      final state = ProviderScope.containerOf(
        element,
      ).read(partnerApplyControllerProvider);

      // controller state가 4여야 한다 (조건부 검사 아님)
      expect(state.currentStep, 4);
      // PageView가 page 4에 있으면 Step5Review가 렌더된다
      expect(find.byType(Step5Review), findsOneWidget);
      // page 0이 아니므로 Step1BasicInfo는 위젯 트리에 없어야 한다
      expect(find.byType(Step1BasicInfo), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('최종 확인'), findsOneWidget);
    });
  });
}
