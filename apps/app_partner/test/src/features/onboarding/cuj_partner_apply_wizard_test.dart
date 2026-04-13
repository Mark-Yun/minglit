import 'dart:async';

import 'package:app_partner/src/features/onboarding/onboarding_coordinator.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_page.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_status_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
// Fake controller — overrideWith() 패턴 (smoke test와 동일)
//
// Fix #1337: overrideWithValue()는 _SyncValueProviderElement 타입 에러 발생.
// overrideWith(() => _FakePartnerApplyController(state)) 패턴으로 대체.
// ---------------------------------------------------------------------------

/// 초기 상태를 주입할 수 있는 Fake 컨트롤러.
/// loadDraft()를 no-op으로 재정의하여 네트워크 의존을 차단한다.
class _FakePartnerApplyController extends PartnerApplyController {
  _FakePartnerApplyController(this._initialState);
  final PartnerApplyState _initialState;

  @override
  PartnerApplyState build() => _initialState;

  @override
  Future<void> loadDraft() async {}
}

/// GoRouter 없이 onboardingCoordinator 의존을 차단하는 Fake.
class _FakeOnboardingCoordinator extends OnboardingCoordinator {
  _FakeOnboardingCoordinator() : super(_FakeGoRouter());

  @override
  void goToApplyStatus() {}

  @override
  void goToApply() {}
}

class _FakeGoRouter implements GoRouter {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// All required text fields for a complete application.
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

/// Builds [PartnerApplyPage] with the given mock repo and optional overrides.
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

/// "신청하기" 버튼이 비활성화(null onPressed)되어 있는지 검증하는 헬퍼.
/// TC-P01-001 및 TC-P01-004에서 공통 사용.
void _expectSubmitButtonDisabled(WidgetTester tester) {
  final button = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, '신청하기'),
  );
  expect(
    button.onPressed,
    isNull,
    reason:
        '"신청하기" button must be disabled (null onPressed) when required fields are empty',
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
    /// 실제 입력 통합 테스트:
    /// PartnerApplyPage를 Step 0부터 렌더링하고, 각 단계에서 텍스트 필드를
    /// 입력한 뒤 "다음" 버튼을 탭하여 Step 4까지 이동한다.
    /// Step 4에서 "신청하기" 버튼을 탭하고 repo.submitDraft가 1회 호출됨을 검증한다.
    ///
    /// Step 3 (문서 업로드)은 XFile 플랫폼 의존으로 인해 초기 상태에
    /// mock path를 주입하고, 나머지 단계는 실제 UI 입력으로 진행한다.
    testWidgets(
      'IT-P01-001: Step 0→4 실제 UI 입력 → 신청하기 탭 → submitDraft 1회 호출',
      (tester) async {
        // Arrange
        when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
        when(() => mockRepo.saveDraft(any())).thenAnswer(
          (_) async =>
              const PartnerApplication(id: 'draft_1', userId: 'user_1'),
        );
        when(
          () =>
              mockRepo.submitDraft(applicationId: any(named: 'applicationId')),
        ).thenAnswer(
          (_) async =>
              const PartnerApplication(id: 'draft_1', userId: 'user_1'),
        );

        // 문서 경로를 포함한 초기 상태로 Fake 컨트롤러 주입.
        // Step 3 XFile picker는 플랫폼 의존 → mock path를 초기 상태에 주입.
        // applicationId는 saveDraft mock에서 'draft_1'이 반환되므로
        // nextStep() 후 자동으로 설정된다.
        const initialState = PartnerApplyState(
          bizRegistrationPath: 'mock://biz.pdf',
          bankbookPath: 'mock://bankbook.pdf',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              partnerRepositoryProvider.overrideWith((ref) => mockRepo),
              partnerApplyControllerProvider.overrideWith(
                () => _FakePartnerApplyController(initialState),
              ),
              onboardingCoordinatorProvider.overrideWith(
                (_) => _FakeOnboardingCoordinator(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('ko'),
              home: PartnerApplyPage(),
            ),
          ),
        );
        await tester.pump();

        // Step 0: brandName 입력 후 "다음" 탭
        await tester.enterText(find.byType(TextFormField).first, '테스트 브랜드');
        await tester.pump();
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();

        // Step 1: bizName, bizNumber, representativeName 입력 후 "다음" 탭
        final step1Fields = find.byType(TextFormField);
        await tester.enterText(step1Fields.at(0), '테스트 사업자');
        await tester.enterText(step1Fields.at(1), '123-45-67890');
        await tester.enterText(step1Fields.at(2), '홍길동');
        await tester.pump();
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();

        // Step 2: contactPhone, contactEmail, bankName, accountNumber, accountHolder 입력 후 "다음" 탭
        final step2Fields = find.byType(TextFormField);
        await tester.enterText(step2Fields.at(0), '010-1234-5678');
        await tester.enterText(step2Fields.at(1), 'test@test.com');
        await tester.enterText(step2Fields.at(2), '신한은행');
        await tester.enterText(step2Fields.at(3), '110-123-456789');
        await tester.enterText(step2Fields.at(4), '홍길동');
        await tester.pump();
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();

        // Step 3: 문서 업로드 — mock path가 이미 초기 상태에 주입됨
        // "다음" 탭으로 Step 4(review)로 이동
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();

        // Step 4: "신청하기" 버튼 확인 후 탭
        expect(find.text('신청하기'), findsOneWidget);
        await tester.tap(find.text('신청하기'));
        await tester.pumpAndSettle();

        // submitDraft가 1회 호출됨을 검증
        verify(
          () =>
              mockRepo.submitDraft(applicationId: any(named: 'applicationId')),
        ).called(1);
      },
    );

    test('submit()은 모든 필드 채운 뒤 repo.submitDraft를 1회 호출한다', () async {
      // Arrange
      when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
      when(() => mockRepo.saveDraft(any())).thenAnswer(
        (_) async => const PartnerApplication(id: 'draft_1', userId: 'user_1'),
      );
      when(
        () => mockRepo.submitDraft(applicationId: any(named: 'applicationId')),
      ).thenAnswer(
        (_) async =>
            const PartnerApplication(id: 'draft_1', userId: 'user_1'),
      );

      final container = createContainer(
        overrides: [
          partnerRepositoryProvider.overrideWith((ref) => mockRepo),
        ],
      );

      final notifier = container.read(partnerApplyControllerProvider.notifier);

      // Fill all required text fields via controller
      _fillAllTextFields(notifier);

      // Inject document paths and applicationId via direct state mutation
      notifier.state = notifier.state.copyWith(
        bizRegistrationPath: 'mock://biz.pdf',
        bankbookPath: 'mock://bankbook.pdf',
        applicationId: 'draft_1',
      );

      expect(
        notifier.validateAll(),
        isTrue,
        reason: 'validateAll must be true when all required fields are filled',
      );

      await notifier.submit();

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

        final element = tester.element(find.byType(PartnerApplyPage));
        ProviderScope.containerOf(
          element,
        ).read(partnerApplyControllerProvider.notifier).setStep(4);
        await tester.pumpAndSettle();

        _expectSubmitButtonDisabled(tester);
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
        ).thenAnswer(
          (_) async =>
              const PartnerApplication(id: 'draft_1', userId: 'user_1'),
        );

        // Fix #1337: overrideWith() + Fake 패턴 사용
        // overrideWithValue()는 _SyncValueProviderElement 타입 에러 발생
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
              partnerApplyControllerProvider.overrideWith(
                () => _FakePartnerApplyController(seededState),
              ),
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

        _expectSubmitButtonDisabled(tester);
      },
    );
  });
}
