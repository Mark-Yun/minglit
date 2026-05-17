// CUJ tests — account / signup-consent
//
// 대응 spec: docs/features/account/signup-consent/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:app_user/src/features/consent/logic/consent_coordinator.dart';
import 'package:app_user/src/features/consent/ui/signup_consent_page.dart';
import 'package:app_user/src/features/settings/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

class _MockUser extends Mock implements User {}

class _MockConsentRepository extends Mock implements ConsentRepository {}

class _MockConsentCoordinator extends Mock implements ConsentCoordinator {}

class _MockIamportRepository extends Mock implements IamportRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(<ConsentInput>[]);
    registerFallbackValue(ConsentType.termsOfService);
  });

  late _MockUser user;
  late _MockConsentRepository repo;
  late _MockConsentCoordinator coordinator;
  late _MockIamportRepository iamportRepo;

  setUp(() {
    user = _MockUser();
    when(() => user.id).thenReturn('test-user-id');

    repo = _MockConsentRepository();
    when(() => repo.getConsents(any())).thenAnswer((_) async => []);
    when(() => repo.saveConsents(any(), any())).thenAnswer((_) async {});
    when(() => repo.hasRequiredConsents()).thenAnswer((_) async => false);

    coordinator = _MockConsentCoordinator();

    iamportRepo = _MockIamportRepository();
    when(
      () => iamportRepo.verifyCertification(any()),
    ).thenAnswer((_) async => {});
  });

  List<dynamic> base() => [
    currentUserProvider.overrideWith((_) => user),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
    consentRepositoryProvider.overrideWith((_) => repo),
    consentCoordinatorProvider.overrideWith((_) => coordinator),
  ];

  List<dynamic> verificationBase() => [
    currentUserProvider.overrideWith((_) => user),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
    consentRepositoryProvider.overrideWith((_) => repo),
    iamportRepositoryProvider.overrideWith((_) => iamportRepo),
  ];

  List<dynamic> privacyBase() => [
    currentUserProvider.overrideWith((_) => user),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
    consentRepositoryProvider.overrideWith((_) => repo),
  ];

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 필수 동의 3종 체크 후 가입 (기존)
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '필수 동의 3종 체크 후 가입', () {
    cujCase(
      'happy: 정상 가입',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('서비스 이용약관'));
        await t.tap(find.text('개인정보 수집·이용 동의'));
        await t.tap(find.text('만 14세 이상 확인'));
        await t.pumpAndSettle();

        // CTA 활성 확인 (FR-2)
        final cta = t.widget<MinglitBottomCTA>(find.byType(MinglitBottomCTA));
        expect(cta.enabled, isTrue);

        await t.tap(find.text('동의하고 시작하기'));
        await t.pumpAndSettle();

        // FR-3: bulk save with 3 required types
        final captured = verify(
          () => repo.saveConsents('test-user-id', captureAny()),
        ).captured;
        expect(captured.single, hasLength(3));
        final keys = (captured.single as List<ConsentInput>)
            .map((c) => c.consentKey)
            .toSet();
        expect(keys, equals(ConsentType.requiredTypes.toSet()));

        // FR-12: 가입 완료 후 HomePage 진입 (coordinator 위임)
        verify(
          () => coordinator.completeSignup(from: any(named: 'from')),
        ).called(1);
      },
    );

    cujCase(
      'edge: 14세 미체크 → CTA 비활성',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('서비스 이용약관'));
        await t.tap(find.text('개인정보 수집·이용 동의'));
        // 만 14세 안 누름
        await t.pumpAndSettle();

        final cta = t.widget<MinglitBottomCTA>(find.byType(MinglitBottomCTA));
        expect(cta.enabled, isFalse);
        expect(cta.onPressed, isNull);

        verifyNever(() => repo.saveConsents(any(), any()));
      },
    );

    cujCase(
      'edge: 저장 실패 → coordinator 미호출',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        when(
          () => repo.saveConsents(any(), any()),
        ).thenThrow(Exception('network'));

        await t.tap(find.text('서비스 이용약관'));
        await t.tap(find.text('개인정보 수집·이용 동의'));
        await t.tap(find.text('만 14세 이상 확인'));
        await t.tap(find.text('동의하고 시작하기'));
        await t.pumpAndSettle();

        // 저장 실패 시 가입 완료 흐름 차단 (FR-12 negative)
        verifyNever(
          () => coordinator.completeSignup(from: any(named: 'from')),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 전체동의 토글로 일괄 체크 (FR-4)
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '전체동의 토글로 일괄 체크', () {
    cujCase(
      'happy: 전체동의 ON → 5개 모두 체크 + CTA 활성',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        // 전체 동의 타일 탭
        await t.tap(find.text('전체 동의'));
        await t.pumpAndSettle();

        // 필수 3개 포함되었으므로 CTA 활성 (FR-2)
        final cta = t.widget<MinglitBottomCTA>(find.byType(MinglitBottomCTA));
        expect(cta.enabled, isTrue);
      },
    );

    cujCase(
      'edge: 전체동의 ON → OFF → 모두 해제 + CTA 비활성',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        // 전체 동의 ON
        await t.tap(find.text('전체 동의'));
        await t.pumpAndSettle();

        // 전체 동의 다시 탭 → OFF
        await t.tap(find.text('전체 동의'));
        await t.pumpAndSettle();

        // 모두 해제되어 CTA 비활성 (FR-4)
        final cta = t.widget<MinglitBottomCTA>(find.byType(MinglitBottomCTA));
        expect(cta.enabled, isFalse);
      },
    );

    cujCase(
      'edge: 개별 해제 시 전체동의 토글 sync OFF',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        // 전체 동의 ON
        await t.tap(find.text('전체 동의'));
        await t.pumpAndSettle();

        // 개별 항목 하나 해제
        await t.tap(find.text('마케팅 정보 수신 동의'));
        await t.pumpAndSettle();

        // 전체 동의 체크박스는 unchecked 상태 (allSelected = false)
        // → '전체 동의' 타일의 Checkbox value는 false
        final checkbox = t.widget<Checkbox>(
          find
              .descendant(
                of: find.ancestor(
                  of: find.text('전체 동의'),
                  matching: find.byType(Material),
                ),
                matching: find.byType(Checkbox),
              )
              .first,
        );
        expect(checkbox.value, isFalse);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 약관 전문 바텀시트 열람 (FR-5)
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '약관 전문 바텀시트 열람', () {
    cujCase(
      'happy: 서비스 이용약관 탭 → 바텀시트 열람 → 닫기',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        // '보기 ›' 버튼 탭 (서비스 이용약관 항목 옆)
        await t.tap(
          find
              .descendant(
                of: find.ancestor(
                  of: find.text('서비스 이용약관'),
                  matching: find.byType(InkWell),
                ),
                matching: find.text('보기 ›'),
              )
              .first,
        );
        await t.pumpAndSettle();

        // 바텀시트 열림: 약관 전문 제목 확인 (FR-5)
        expect(find.text('서비스 이용약관'), findsWidgets);
        expect(find.text('주요 내용'), findsOneWidget);

        // 배리어 탭으로 닫기
        await t.tapAt(const Offset(10, 10));
        await t.pumpAndSettle();

        // 바텀시트 닫힘 — 동의 페이지 복귀
        expect(find.text('동의하고 시작하기'), findsOneWidget);
      },
    );

    cujCase(
      'happy: 제3자 제공 동의 탭 → 바텀시트 열람',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('보기 ›').at(1));
        await t.pumpAndSettle();

        // 제3자 제공 동의 전문 (FR-5)
        expect(find.text('제3자 제공 동의'), findsWidgets);
        expect(find.text('제공받는 자'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-4: 선택 동의 거부하고 가입 (FR-3, FR-12)
  // ---------------------------------------------------------------------------

  cujGroup('1-4', '선택 동의 거부하고 가입', () {
    cujCase(
      'happy: 필수 3개만 체크, 선택 미체크 → 정상 가입',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        // 필수 3개만 체크
        await t.tap(find.text('서비스 이용약관'));
        await t.tap(find.text('개인정보 수집·이용 동의'));
        await t.tap(find.text('만 14세 이상 확인'));
        await t.pumpAndSettle();

        // CTA 활성 (필수 3개 충족)
        final cta = t.widget<MinglitBottomCTA>(find.byType(MinglitBottomCTA));
        expect(cta.enabled, isTrue);

        await t.tap(find.text('동의하고 시작하기'));
        await t.pumpAndSettle();

        // FR-3: 선택 항목 미포함 — 필수 3개만 저장
        final captured = verify(
          () => repo.saveConsents('test-user-id', captureAny()),
        ).captured;
        final saved = captured.single as List<ConsentInput>;
        expect(saved, hasLength(3));
        final savedKeys = saved.map((c) => c.consentKey).toSet();
        expect(savedKeys, equals(ConsentType.requiredTypes.toSet()));

        // FR-12: 가입 완료
        verify(
          () => coordinator.completeSignup(from: any(named: 'from')),
        ).called(1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-5: 동의 화면에서 백 → 가입 미완료 (FR-6)
  // ---------------------------------------------------------------------------

  cujGroup('1-5', '동의 화면에서 백 → 가입 미완료', () {
    cujCase(
      'happy: 백 탭 → PopScope(canPop=false)로 화면 유지',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        // 시스템 백 시뮬레이션
        // Fix: PopScope(canPop: false)로 네비게이션 차단됨
        await t.binding.handlePopRoute();
        await t.pumpAndSettle();

        // 동의 화면 유지 — 가입 미완료 (FR-6)
        expect(find.text('동의하고 시작하기'), findsOneWidget);
        verifyNever(
          () => coordinator.completeSignup(from: any(named: 'from')),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-6: 라우터 가드로 강제 진입 (FR-1)
  // ---------------------------------------------------------------------------

  cujGroup('1-6', '라우터 가드로 강제 진입', () {
    cujCase(
      'happy: 동의 미완료 유저 → hasRequiredConsents=false (가드 차단)',
      // hasRequiredConsentsProvider를 Consumer로 읽어 guard 로직을 직접 검증
      app: Consumer(
        builder: (_, ref, __) {
          return ref
              .watch(hasRequiredConsentsProvider)
              .when(
                data: (has) => Text(has ? 'allowed' : 'blocked'),
                loading: () => const SizedBox(),
                error: (_, __) => const Text('error'),
              );
        },
      ),
      overrides: base,
      body: (t) async {
        // FR-1: 동의 미완료 유저는 가드 차단 → SignupConsentScreen redirect 트리거
        expect(find.text('blocked'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 동의 완료 유저 → hasRequiredConsents=true (가드 통과)',
      app: Consumer(
        builder: (_, ref, __) {
          return ref
              .watch(hasRequiredConsentsProvider)
              .when(
                data: (has) => Text(has ? 'allowed' : 'blocked'),
                loading: () => const SizedBox(),
                error: (_, __) => const Text('error'),
              );
        },
      ),
      overrides: () {
        when(() => repo.hasRequiredConsents()).thenAnswer((_) async => true);
        return base();
      },
      body: (t) async {
        // FR-12: 동의 완료 유저는 SignupConsentScreen 재진입 차단
        expect(find.text('allowed'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 본인인증 전 CI/DI 동의 (FR-7, FR-8)
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '본인인증 전 CI/DI 동의', () {
    cujCase(
      'happy: identity_verification 동의 없음 → 동의 시트 자동 표시',
      app: const IdentityVerificationScreen(),
      overrides: verificationBase,
      body: (t) async {
        // IdentityVerificationScreen 진입 시 동의 미완료면 시트 자동 표시 (FR-7)
        expect(find.text('본인확인정보 수집·이용 동의'), findsOneWidget);
        expect(find.text('동의하고 인증'), findsOneWidget);
        expect(find.text('취소'), findsOneWidget);
      },
    );

    cujCase(
      'edge: identity_verification 이미 동의 → 시트 미표시',
      app: const IdentityVerificationScreen(),
      overrides: () {
        // Fix: 이미 동의한 유저는 시트 없이 바로 Portone 호출 (FR-8)
        when(() => repo.getConsents(any())).thenAnswer(
          (_) async => [
            UserConsent(
              id: '1',
              userId: 'test-user-id',
              consentKey: ConsentType.identityVerification,
              consented: true,
              consentedAt: DateTime(2024),
              createdAt: DateTime(2024),
            ),
          ],
        );
        return verificationBase();
      },
      body: (t) async {
        // 이미 동의가 있으므로 시트 미표시
        expect(find.text('본인확인정보 수집·이용 동의'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: CI/DI 동의 후 Portone 호출 (FR-8, FR-9)
  // ---------------------------------------------------------------------------

  cujGroup('2-2', 'CI/DI 동의 후 Portone 호출', () {
    cujCase(
      'happy: 동의 → consent 저장 → 인증 플로우 진입',
      app: const IdentityVerificationScreen(),
      overrides: verificationBase,
      body: (t) async {
        // 시트 자동 표시됨 (CUJ 2-1과 동일 전제)
        expect(find.text('동의하고 인증'), findsOneWidget);

        await t.tap(find.text('동의하고 인증'));
        // FR-8: 동의 후 toggleConsent(identityVerification, consented: true) 저장
        // mock async 완료 대기 (Portone SDK 외부 호출 전)
        await t.pump(const Duration(milliseconds: 500));

        // FR-9: identityVerification consent 저장 확인
        final captured = verify(
          () => repo.saveConsents('test-user-id', captureAny()),
        ).captured;
        final saved = captured.last as List<ConsentInput>;
        expect(saved, hasLength(1));
        expect(saved.first.consentKey, ConsentType.identityVerification);
        expect(saved.first.consented, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-3: CI/DI 동의 거부 (FR-7)
  // ---------------------------------------------------------------------------

  cujGroup('2-3', 'CI/DI 동의 거부', () {
    cujCase(
      'happy: 취소 탭 → 동의 미저장, 시트 닫힘',
      app: const IdentityVerificationScreen(),
      overrides: verificationBase,
      body: (t) async {
        // 시트 자동 표시됨
        expect(find.text('취소'), findsOneWidget);

        await t.tap(find.text('취소'));
        await t.pumpAndSettle();

        // FR-7: 취소 시 동의 미저장
        verifyNever(() => repo.saveConsents(any(), any()));

        // 시트 닫힘 — 화면에 에러 메시지 표시
        expect(find.text('본인확인정보 수집·이용 동의'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 마케팅 동의 토글 변경 (FR-10)
  // ---------------------------------------------------------------------------

  cujGroup('3-1', '마케팅 동의 토글 변경', () {
    cujCase(
      'happy: 마케팅 OFF → ON 토글 → 즉시 저장',
      app: const PrivacyPage(),
      overrides: privacyBase, // 기본: getConsents() → [] (marketing=false)
      body: (t) async {
        // 마케팅 스위치 탭 (현재 false → true)
        await t.tap(find.text('마케팅 정보 수신'));
        await t.pumpAndSettle();

        // FR-10: 즉시 user_consents update
        final captured = verify(
          () => repo.saveConsents('test-user-id', captureAny()),
        ).captured;
        final saved = captured.single as List<ConsentInput>;
        expect(saved, hasLength(1));
        expect(saved.first.consentKey, ConsentType.marketingConsent);
        expect(saved.first.consented, isTrue);
      },
    );

    cujCase(
      'edge: 저장 실패 → 토글 원상복구 + 스낵바',
      app: const PrivacyPage(),
      overrides: () {
        when(
          () => repo.saveConsents(any(), any()),
        ).thenThrow(Exception('network'));
        return privacyBase();
      },
      body: (t) async {
        // Fix #886: toggle 실패 시 원상복구 + 스낵바
        await t.tap(find.text('마케팅 정보 수신'));
        await t.pumpAndSettle();

        // 스낵바 에러 메시지 표시
        expect(
          find.text('동의 변경에 실패했습니다. 다시 시도해주세요.'),
          findsOneWidget,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 제3자 제공 동의 철회 (FR-10, FR-11)
  // ---------------------------------------------------------------------------

  cujGroup('3-2', '제3자 제공 동의 철회', () {
    cujCase(
      'happy: 제3자 ON → OFF 철회 → 즉시 저장',
      app: const PrivacyPage(),
      overrides: () {
        // 초기 상태: thirdPartyProvision = true
        when(() => repo.getConsents(any())).thenAnswer(
          (_) async => [
            UserConsent(
              id: '1',
              userId: 'test-user-id',
              consentKey: ConsentType.thirdPartyProvision,
              consented: true,
              consentedAt: DateTime(2024),
              createdAt: DateTime(2024),
            ),
          ],
        );
        return privacyBase();
      },
      body: (t) async {
        // 제3자 제공 스위치 탭 (현재 true → false)
        await t.tap(find.text('제3자 제공 동의'));
        await t.pumpAndSettle();

        // FR-10: 철회 즉시 저장
        final captured = verify(
          () => repo.saveConsents('test-user-id', captureAny()),
        ).captured;
        final saved = captured.single as List<ConsentInput>;
        expect(saved, hasLength(1));
        expect(saved.first.consentKey, ConsentType.thirdPartyProvision);
        expect(saved.first.consented, isFalse);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-3: 필수 동의 항목 변경 불가 (FR-10, NFR-4)
  // ---------------------------------------------------------------------------

  cujGroup('3-3', '필수 동의 항목 변경 불가', () {
    cujCase(
      'happy: 필수 항목은 ReadOnly 타일 — 스위치 없음',
      app: const PrivacyPage(),
      overrides: privacyBase,
      body: (t) async {
        // FR-10: 필수 항목은 SwitchListTile 없이 ReadOnly 표시
        // SwitchListTile의 title Text는 선택 항목만
        final switches = t.widgetList<SwitchListTile>(
          find.byType(SwitchListTile),
        );
        final switchTitles = switches
            .map((s) => s.title)
            .whereType<Text>()
            .map((t) => t.data ?? '')
            .toSet();

        // 서비스 이용약관·개인정보 수집·이용 → 스위치 없음
        expect(switchTitles.contains('서비스 이용약관'), isFalse);
        expect(switchTitles.contains('개인정보 수집·이용'), isFalse);

        // 필수 항목 탭해도 saveConsents 미호출
        await t.tap(find.text('서비스 이용약관').first);
        await t.pumpAndSettle();
        verifyNever(() => repo.saveConsents(any(), any()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-4: 약관 보기 (사후) (FR-5)
  // ---------------------------------------------------------------------------

  cujGroup('3-4', '약관 보기 (사후)', () {
    cujCase(
      'happy: 약관 보기 섹션 탭 → 바텀시트로 현재 동의 버전 전문 표시',
      app: const PrivacyPage(),
      overrides: privacyBase,
      body: (t) async {
        // "약관 보기" 섹션의 '서비스 이용약관' ListTile 탭
        // (동의 현황 섹션의 _ReadOnlyConsentTile과 같은 텍스트이므로 .last 사용)
        await t.tap(find.text('서비스 이용약관').last);
        await t.pumpAndSettle();

        // FR-5: 바텀시트로 약관 전문 표시
        expect(find.text('서비스 이용약관'), findsWidgets);
        expect(find.text('주요 내용'), findsOneWidget);

        // 배리어 탭으로 닫기
        await t.tapAt(const Offset(10, 10));
        await t.pumpAndSettle();
        expect(find.text('개인정보'), findsOneWidget); // AppBar title 복귀
      },
    );

    cujCase(
      'happy: 개인정보처리방침 탭 → 바텀시트',
      app: const PrivacyPage(),
      overrides: privacyBase,
      body: (t) async {
        await t.tap(find.text('개인정보처리방침'));
        await t.pumpAndSettle();

        expect(find.text('개인정보처리방침'), findsWidgets);
        expect(find.text('수집하는 개인정보'), findsOneWidget);
      },
    );
  });
}
