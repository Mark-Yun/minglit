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

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

/// IT-P01: 파트너 입점 신청 위저드 통합 테스트
///
/// TC-P01-001: 5단계 위저드 전체 입력 → 제출 → pendingReview
/// TC-P01-002: 중간 단계 임시저장 → 재진입 시 이어하기
/// TC-P01-003: needsCorrection 상태 보정 사유 표시
/// TC-P01-004: 필수 입력 누락 시 다음 단계 차단

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// All required fields for a complete application, except file paths.
void _fillAllTextFields(PartnerApplyController notifier) {
  notifier
    ..updateField('brandName', '테스트 브랜드')
    ..updateField('introduction', '소개글입니다')
    ..updateField('bizName', '테스트 사업자')
    ..updateField('bizNumber', '123-45-67890')
    ..updateField('representativeName', '홍길동')
    ..updateField('contactPhone', '010-1234-5678')
    ..updateField('contactEmail', 'test@test.com')
    ..updateField('bankName', '신한은행')
    ..updateField('accountNumber', '110-123-456789')
    ..updateField('accountHolder', '홍길동');
}

/// Builds [PartnerApplyPage] wrapped in [ProviderScope] + minimal [MaterialApp].
Widget _buildApplyWidget(
  MockPartnerRepository mockRepo, {
  List<Override> extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      partnerRepositoryProvider.overrideWith((ref) => mockRepo),
      ...extraOverrides,
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ko'),
      home: PartnerApplyPage(),
    ),
  );
}

// ---------------------------------------------------------------------------

void main() {
  late MockPartnerRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(const PartnerApplication(id: '', userId: ''));
  });

  setUp(() {
    mockRepo = MockPartnerRepository();
  });

  // ---------------------------------------------------------------------------
  // TC-P01-001: 5단계 위저드 전체 입력 → 제출
  // ---------------------------------------------------------------------------
  group('TC-P01-001: 5단계 위저드 전체 입력 → 제출', () {
    test('submit()은 모든 필드 채운 뒤 repo.submitDraft를 1회 호출한다', () async {
      // Arrange
      when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
      when(() => mockRepo.saveDraft(any())).thenAnswer(
        (_) async => const PartnerApplication(id: 'draft_1', userId: 'user_1'),
      );
      when(
        () => mockRepo.submitDraft(applicationId: any(named: 'applicationId')),
      ).thenAnswer((_) async {});

      final container = createContainer(
        overrides: [
          partnerRepositoryProvider.overrideWith((ref) => mockRepo),
        ],
      );

      final notifier = container.read(partnerApplyControllerProvider.notifier);

      // Fill all required text fields
      _fillAllTextFields(notifier);

      // Inject document paths and applicationId via overrideWithValue so we
      // don't touch the protected state setter.
      // overrideWithValue replaces the provider's state with a fixed value.
      // We re-read the current state (after text fields are set) and then
      // patch it with the extra fields using the override mechanism.
      final patchedState = container
          .read(partnerApplyControllerProvider)
          .copyWith(
            bizRegistrationPath: 'mock://biz.pdf',
            bankbookPath: 'mock://bankbook.pdf',
            applicationId: 'draft_1',
          );

      // Re-create container with the patched value override so validateAll()
      // can see the document paths.
      final container2 = createContainer(
        overrides: [
          partnerRepositoryProvider.overrideWith((ref) => mockRepo),
          partnerApplyControllerProvider.overrideWithValue(patchedState),
        ],
      );

      final notifier2 = container2.read(
        partnerApplyControllerProvider.notifier,
      );

      expect(
        notifier2.validateAll(),
        isTrue,
        reason: 'validateAll must be true when all required fields are filled',
      );

      await notifier2.submit();

      verify(
        () => mockRepo.submitDraft(applicationId: 'draft_1'),
      ).called(1);
    });

    testWidgets(
      '"신청하기" 버튼이 Step 4(마지막 단계)에서 렌더링된다',
      (tester) async {
        when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
        when(() => mockRepo.saveDraft(any())).thenAnswer(
          (_) async =>
              const PartnerApplication(id: 'draft_1', userId: 'user_1'),
        );

        await tester.pumpWidget(_buildApplyWidget(mockRepo));
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier).setStep(4);
        await tester.pumpAndSettle();

        expect(find.text('신청하기'), findsOneWidget);
      },
    );

    testWidgets(
      '"신청하기" 버튼은 필수 필드 미입력 시 비활성화(null onPressed)된다',
      (tester) async {
        when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
        when(() => mockRepo.saveDraft(any())).thenAnswer(
          (_) async =>
              const PartnerApplication(id: 'draft_1', userId: 'user_1'),
        );

        await tester.pumpWidget(_buildApplyWidget(mockRepo));
        await tester.pump();

        // Go to last step without filling any fields
        final element = tester.element(find.byType(PartnerApplyPage));
        ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier).setStep(4);
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '신청하기'),
        );
        expect(
          button.onPressed,
          isNull,
          reason:
              'Submit button must be disabled when required fields are empty',
        );
      },
    );

    testWidgets(
      '"신청하기" 버튼은 모든 필드 입력 후 활성화된다',
      (tester) async {
        when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
        when(() => mockRepo.saveDraft(any())).thenAnswer(
          (_) async =>
              const PartnerApplication(id: 'draft_1', userId: 'user_1'),
        );
        when(
          () =>
              mockRepo.submitDraft(applicationId: any(named: 'applicationId')),
        ).thenAnswer((_) async {});

        // Pre-seed state with all required fields so the last step shows
        // the active "신청하기" button.
        const seededState = PartnerApplyState(
          currentStep: 4,
          applicationId: 'draft_1',
          brandName: '테스트 브랜드',
          introduction: '소개글',
          bizName: '테스트 사업자',
          bizNumber: '123-45-67890',
          representativeName: '홍길동',
          contactPhone: '010-1234-5678',
          contactEmail: 'test@test.com',
          bankName: '신한은행',
          accountNumber: '110-123-456789',
          accountHolder: '홍길동',
          bizRegistrationPath: 'mock://biz.pdf',
          bankbookPath: 'mock://bankbook.pdf',
        );

        await tester.pumpWidget(
          _buildApplyWidget(
            mockRepo,
            extraOverrides: [
              partnerApplyControllerProvider.overrideWithValue(seededState),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '신청하기'),
        );
        expect(
          button.onPressed,
          isNotNull,
          reason:
              'Submit button must be enabled when all required fields are filled',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // TC-P01-002: 중간 단계 임시저장 → 재진입 시 이어하기
  // ---------------------------------------------------------------------------
  group('TC-P01-002: 중간 단계 임시저장 → 재진입 이어하기', () {
    testWidgets(
      'loadDraft 호출 시 저장된 draft 데이터와 currentStep이 복원된다',
      (tester) async {
        const savedDraft = PartnerApplication(
          id: 'draft_saved',
          userId: 'user_1',
          brandName: '저장된 브랜드',
          bizName: '저장된 사업자',
          currentStep: 1,
        );
        when(
          () => mockRepo.getMyApplication(),
        ).thenAnswer((_) async => savedDraft);
        when(
          () => mockRepo.saveDraft(any()),
        ).thenAnswer((_) async => savedDraft);

        await tester.pumpWidget(_buildApplyWidget(mockRepo));
        // initState posts loadDraft via addPostFrameCallback.
        await tester.pump(); // frame 1: addPostFrameCallback fires
        await tester.pump(); // frame 2: loadDraft future resolves

        final element = tester.element(find.byType(PartnerApplyPage));
        final state = ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider);

        expect(
          state.brandName,
          '저장된 브랜드',
          reason: 'brandName must be restored from saved draft',
        );
        expect(
          state.bizName,
          '저장된 사업자',
          reason: 'bizName must be restored from saved draft',
        );
        expect(
          state.currentStep,
          1,
          reason: 'currentStep must resume from saved draft step',
        );
      },
    );

    testWidgets(
      'loadDraft은 status=pending인 경우 상태를 복원하지 않는다',
      (tester) async {
        const pendingApp = PartnerApplication(
          id: 'app_1',
          userId: 'user_1',
          status: 'pending',
          brandName: '신청된 브랜드',
        );
        when(
          () => mockRepo.getMyApplication(),
        ).thenAnswer((_) async => pendingApp);

        await tester.pumpWidget(_buildApplyWidget(mockRepo));
        await tester.pump();
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        final state = ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider);

        // pending status → loadDraft returns early → state stays at defaults
        expect(
          state.brandName,
          '',
          reason: 'pending application must not be loaded into draft fields',
        );
        expect(
          state.currentStep,
          0,
          reason: 'step must remain 0 when draft is not loaded',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // TC-P01-003: needsCorrection 상태 보정 사유 표시
  // ---------------------------------------------------------------------------
  group('TC-P01-003: needsCorrection 상태 보정 사유 표시', () {
    testWidgets(
      'status=needs_correction draft가 있으면 loadDraft가 필드와 applicationId를 복원한다',
      (tester) async {
        const correctionApp = PartnerApplication(
          id: 'app_needs_correction',
          userId: 'user_1',
          status: 'needs_correction',
          adminComment: '사업자 등록증을 다시 제출해주세요.',
          brandName: '수정 필요 브랜드',
          bizName: '수정 사업자',
        );
        when(
          () => mockRepo.getMyApplication(),
        ).thenAnswer((_) async => correctionApp);
        when(
          () => mockRepo.saveDraft(any()),
        ).thenAnswer((_) async => correctionApp);

        await tester.pumpWidget(_buildApplyWidget(mockRepo));
        await tester.pump();
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        final state = ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider);

        expect(
          state.brandName,
          '수정 필요 브랜드',
          reason:
              'needs_correction application must have fields restored for re-editing',
        );
        expect(
          state.applicationId,
          'app_needs_correction',
          reason:
              'applicationId must be preserved so re-submission targets the same application',
        );
      },
    );

    testWidgets(
      'PartnerApplyStatusPage: needsCorrection 상태 시 보완 메시지와 adminComment가 표시된다',
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
          ProviderScope(
            overrides: [
              partnerRepositoryProvider.overrideWith((ref) => mockRepo),
              onboardingStateProvider.overrideWith(
                (ref) => SynchronousFuture(OnboardingState.needsCorrection),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('ko'),
              home: PartnerApplyStatusPage(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        expect(find.textContaining('보완이 필요합니다'), findsOneWidget);
        expect(find.text(adminComment), findsOneWidget);
      },
    );

    testWidgets(
      'PartnerApplyStatusPage: needsCorrection 상태 시 "신청서 수정하기" 버튼이 표시된다',
      (tester) async {
        when(() => mockRepo.getMyApplication()).thenAnswer(
          (_) => SynchronousFuture<PartnerApplication?>(
            const PartnerApplication(
              id: 'app_2',
              userId: 'user_2',
              status: 'needs_correction',
              adminComment: '수정 필요',
            ),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              partnerRepositoryProvider.overrideWith((ref) => mockRepo),
              onboardingStateProvider.overrideWith(
                (ref) => SynchronousFuture(OnboardingState.needsCorrection),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('ko'),
              home: PartnerApplyStatusPage(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        expect(find.text('신청서 수정하기'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // TC-P01-004: 필수 입력 누락 시 다음 단계 차단
  // ---------------------------------------------------------------------------
  group('TC-P01-004: 필수 입력 누락 시 다음 단계 차단', () {
    testWidgets(
      'Step 0: brandName 비워두면 canProceed()가 false를 반환한다',
      (tester) async {
        when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
        when(() => mockRepo.saveDraft(any())).thenAnswer(
          (_) async =>
              const PartnerApplication(id: 'draft_1', userId: 'user_1'),
        );

        await tester.pumpWidget(_buildApplyWidget(mockRepo));
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        final notifier = ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier);

        // brandName is empty by default
        expect(
          notifier.canProceed(),
          isFalse,
          reason:
              'canProceed must return false when brandName is empty on step 0',
        );
      },
    );

    testWidgets(
      'Step 0: brandName 입력 후 canProceed()가 true를 반환한다',
      (tester) async {
        when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
        when(() => mockRepo.saveDraft(any())).thenAnswer(
          (_) async =>
              const PartnerApplication(id: 'draft_1', userId: 'user_1'),
        );

        await tester.pumpWidget(_buildApplyWidget(mockRepo));
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        final notifier = ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier);

        notifier.updateField('brandName', '입력된 브랜드');
        await tester.pump();

        expect(
          notifier.canProceed(),
          isTrue,
          reason: 'canProceed must return true after brandName is filled',
        );
      },
    );

    testWidgets(
      'Step 1: biz 필드 누락 시 validateStep(1)이 false를 반환한다',
      (tester) async {
        when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
        when(() => mockRepo.saveDraft(any())).thenAnswer(
          (_) async =>
              const PartnerApplication(id: 'draft_1', userId: 'user_1'),
        );

        await tester.pumpWidget(_buildApplyWidget(mockRepo));
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        final notifier = ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier);

        notifier.setStep(1);
        await tester.pumpAndSettle();

        expect(
          notifier.validateStep(1),
          isFalse,
          reason:
              'validateStep(1) must be false when bizName/bizNumber/representativeName are empty',
        );
      },
    );

    testWidgets(
      'Step 4(review): 모든 필드 미입력 시 "신청하기" 버튼이 비활성화된다',
      (tester) async {
        when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
        when(() => mockRepo.saveDraft(any())).thenAnswer(
          (_) async =>
              const PartnerApplication(id: 'draft_1', userId: 'user_1'),
        );

        await tester.pumpWidget(_buildApplyWidget(mockRepo));
        await tester.pump();

        final element = tester.element(find.byType(PartnerApplyPage));
        ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier).setStep(4);
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '신청하기'),
        );
        expect(
          button.onPressed,
          isNull,
          reason:
              '"신청하기" button must be disabled (null onPressed) when required fields are empty',
        );
      },
    );
  });
}
