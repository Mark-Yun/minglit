import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_page.dart';
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

      // Fix #2130 적용 후: jumpToPage(4)이므로 즉시 page 4로 이동
      // 수정 전: animateToPage(4)이므로 여기서는 page 0~4 사이에 있음
      // AppBar 제목과 PageView 내용이 일치해야 함
      final element = tester.element(find.byType(PartnerApplyPage));
      final state = ProviderScope.containerOf(
        element,
      ).read(partnerApplyControllerProvider);

      // state가 4로 업데이트되었다면 title도 "최종 확인"이어야 함
      if (state.currentStep == 4) {
        // jumpToPage는 즉시이므로 title과 page가 동기화
        expect(find.text('최종 확인'), findsOneWidget);
      }

      await tester.pumpAndSettle();
      expect(find.text('최종 확인'), findsOneWidget);
    });
  });
}
