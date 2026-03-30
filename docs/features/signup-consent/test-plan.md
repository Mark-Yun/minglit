# 회원가입 동의 (signup-consent) — 테스트 계획

## 개요

회원가입 시 개인정보 수집·이용 동의 기능의 테스트 계획.
`docs/features/signup-consent/plan.md`(PR #867) 기반으로 작성.

**테스트 대상 구현 이슈:**
| 순서 | 제목 | 계층 |
|------|------|------|
| 1 | DB: `user_consents` 테이블 + `policies` seed | DB |
| 2 | minglit_kit: `ConsentRepository` + `ConsentController` | Repository/Logic |
| 3 | 유저 앱: `SignupConsentScreen` | Widget |
| 4 | 유저 앱: 라우트 가드 (동의 여부 redirect) | Integration |
| 5 | 유저 앱: `IdentityVerificationConsentSheet` | Widget |
| 6 | 유저 앱: `PrivacyPage` 동의 관리 | Widget |

---

## 계층별 테스트 계획

### Layer 1: Database 테스트 (pgTAP)

**파일**: `supabase/tests/database/56_user_consents_test.sql`

| # | 테스트 케이스 | 우선순위 |
|---|-------------|---------|
| 1.1 | `user_consents` 테이블이 존재한다 | P1 |
| 1.2 | 필수 컬럼이 존재한다 (id, user_id, consent_key, consented, policy_version, consented_at, withdrawn_at, created_at) | P1 |
| 1.3 | `user_consents_user_key_unique` UNIQUE 제약조건이 동작한다 (같은 user_id + consent_key 중복 INSERT 시 에러) | P1 |
| 1.4 | RLS — authenticated 유저가 자기 동의만 SELECT 가능하다 | P1 |
| 1.5 | RLS — authenticated 유저가 자기 동의만 INSERT 가능하다 | P1 |
| 1.6 | RLS — authenticated 유저가 자기 동의만 UPDATE 가능하다 | P1 |
| 1.7 | RLS — authenticated 유저가 다른 유저 동의를 SELECT 할 수 없다 | P1 |
| 1.8 | RLS — service_role은 모든 동의에 접근 가능하다 | P2 |
| 1.9 | `has_required_consents()` — 3개 필수 동의(terms_of_service, privacy_collection, age_confirmation) 모두 `consented = true`이면 `true` 반환 | P1 |
| 1.10 | `has_required_consents()` — 필수 동의 중 1개라도 없으면 `false` 반환 | P1 |
| 1.11 | `has_required_consents()` — 필수 동의가 `consented = false`이면 `false` 반환 | P1 |
| 1.12 | `has_required_consents()` — 동의 레코드가 전혀 없으면 `false` 반환 | P1 |
| 1.13 | `has_required_consents()` — 선택 동의(marketing_consent, third_party_provision)만 있고 필수 없으면 `false` 반환 | P2 |
| 1.14 | policies seed 데이터 — terms_of_service, privacy_collection, third_party_provision, marketing_consent 4건이 존재한다 | P2 |

**테스트 구조 참고**: `supabase/tests/database/52_policies_test.sql` 패턴 사용.

```sql
-- 예시 구조
BEGIN;
SELECT plan(14);

-- 스키마 테스트
SELECT has_table('public', 'user_consents', 'user_consents exists');
SELECT has_column('public', 'user_consents', 'consent_key', 'has consent_key');
-- ...

-- RLS 테스트: savepoint 패턴
SAVEPOINT before_rls;
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "user-a"}';
-- INSERT own consent → OK
-- SELECT other user's consent → 0 rows
ROLLBACK TO SAVEPOINT before_rls;

-- has_required_consents() 테스트
SAVEPOINT before_rpc;
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "user-b"}';
INSERT INTO user_consents (user_id, consent_key, consented) VALUES
  ('user-b', 'terms_of_service', true),
  ('user-b', 'privacy_collection', true),
  ('user-b', 'age_confirmation', true);
SELECT results_eq(
  $$SELECT has_required_consents()$$,
  $$VALUES (true)$$,
  'all required consents → true'
);
ROLLBACK TO SAVEPOINT before_rpc;

SELECT * FROM finish();
ROLLBACK;
```

---

### Layer 2: Repository 테스트 (minglit_kit)

**파일**: `shared/packages/minglit_kit/test/src/data/repositories/consent_repository_test.dart`

**Mock**: `createMockSupabase()` + `mockTable()` (기존 `supabase_mock_helpers.dart` 활용)

| # | 테스트 케이스 | 우선순위 |
|---|-------------|---------|
| 2.1 | `getConsents(userId)` — 동의 목록 반환 | P1 |
| 2.2 | `getConsents(userId)` — 동의 없으면 빈 리스트 반환 | P1 |
| 2.3 | `saveConsents(userId, consents)` — 동의 일괄 upsert 호출 | P1 |
| 2.4 | `saveConsents()` — Supabase 에러 시 예외 전파 | P1 |
| 2.5 | `updateConsent(userId, key, true)` — consented=true + consented_at 설정 | P1 |
| 2.6 | `updateConsent(userId, key, false)` — consented=false + withdrawn_at 설정 | P1 |
| 2.7 | `hasRequiredConsents()` — RPC `has_required_consents` 호출하여 true 반환 | P1 |
| 2.8 | `hasRequiredConsents()` — RPC false 반환 | P1 |
| 2.9 | `hasRequiredConsents()` — RPC 에러 시 예외 전파 | P2 |

```dart
// 예시 구조
void main() {
  late MockSupabaseClient mockClient;
  late ConsentRepository repository;

  setUp(() {
    mockClient = createMockSupabase(currentUser: MockUser());
    repository = ConsentRepository(mockClient);
  });

  group('ConsentRepository', () {
    group('getConsents', () {
      test('returns consent list', () async {
        mockTable(mockClient, 'user_consents', selectData: [
          {'consent_key': 'terms_of_service', 'consented': true, ...},
        ]);
        final result = await repository.getConsents('user-1');
        expect(result, hasLength(1));
        expect(result.first.consentKey, 'terms_of_service');
      });
    });

    group('hasRequiredConsents', () {
      test('returns true when all required consents given', () async {
        // FakeRpcBuilder로 true 반환 mock
        final result = await repository.hasRequiredConsents();
        expect(result, isTrue);
      });
    });
  });
}
```

---

### Layer 3: Controller 테스트 (minglit_kit)

**파일**: `shared/packages/minglit_kit/test/src/features/consent/logic/consent_controller_test.dart`

**Mock**: `MockConsentRepository` (mocktail)

| # | 테스트 케이스 | 우선순위 |
|---|-------------|---------|
| 3.1 | `build()` — 로그인 유저의 동의 상태를 로드한다 | P1 |
| 3.2 | `build()` — 비로그인 시 빈 리스트 반환 | P2 |
| 3.3 | `saveSignupConsents()` — 동의 저장 후 상태 갱신 | P1 |
| 3.4 | `saveSignupConsents()` — 에러 시 AsyncError 상태 | P1 |
| 3.5 | `toggleConsent('marketing_consent', false)` — 개별 동의 철회 후 상태 갱신 | P1 |
| 3.6 | `toggleConsent('marketing_consent', true)` — 철회 후 재동의 | P2 |

```dart
// 예시 구조
void main() {
  late MockConsentRepository mockRepo;

  setUp(() {
    mockRepo = MockConsentRepository();
  });

  group('ConsentController', () {
    test('loads consent statuses on build', () async {
      when(() => mockRepo.getConsents(any()))
          .thenAnswer((_) async => [testConsent]);

      final container = createContainer(overrides: [
        consentRepositoryProvider.overrideWithValue(mockRepo),
      ]);

      final state = await container.read(consentControllerProvider.future);
      expect(state, hasLength(1));
    });
  });
}
```

---

### Layer 4: Widget 테스트 (app_user)

#### 4-A. SignupConsentScreen

**파일**: `apps/app_user/test/src/features/consent/ui/signup_consent_page_test.dart`

| # | 테스트 케이스 | 우선순위 |
|---|-------------|---------|
| 4.1 | 초기 상태: 모든 체크박스 미선택, CTA 비활성 | P1 |
| 4.2 | 전체동의 토글 ON → 모든 항목(필수+선택) 체크됨 | P1 |
| 4.3 | 전체동의 토글 OFF → 모든 항목 해제됨 | P1 |
| 4.4 | 필수 3개만 체크 (선택 미체크) → CTA 활성 | P1 |
| 4.5 | 필수 2개만 체크 → CTA 비활성 | P1 |
| 4.6 | 개별 항목 체크 후 1개 해제 → 전체동의 토글 OFF | P2 |
| 4.7 | 약관 항목(서비스 이용약관) 탭 → `ConsentDetailSheet` 바텀시트 표시 | P2 |
| 4.8 | CTA 탭 → `ConsentController.saveSignupConsents()` 호출 | P1 |
| 4.9 | CTA 탭 → 저장 중 로딩 인디케이터 표시 | P2 |
| 4.10 | 저장 실패 → 스낵바 에러 메시지 | P2 |
| 4.11 | 5개 동의 항목 텍스트가 올바르게 렌더링된다 (필수 3 + 선택 2) | P1 |
| 4.12 | "선택 항목 거부해도 서비스 이용 가능" 안내 문구 표시 | P2 |

```dart
// 예시 구조
testWidgets('CTA disabled when required consents incomplete', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        consentControllerProvider.overrideWith((_) => AsyncData([])),
      ],
      child: const MaterialApp(home: SignupConsentScreen()),
    ),
  );
  await tester.pumpAndSettle();

  final cta = find.widgetWithText(ElevatedButton, '동의하고 시작하기');
  expect(tester.widget<ElevatedButton>(cta).enabled, isFalse);
});
```

#### 4-B. IdentityVerificationConsentSheet

**파일**: `apps/app_user/test/src/features/consent/ui/identity_verification_consent_sheet_test.dart`

| # | 테스트 케이스 | 우선순위 |
|---|-------------|---------|
| 4.13 | 바텀시트 렌더링: 수집 항목(이름, 생년월일, 성별, 휴대폰, CI, DI) 표시 | P1 |
| 4.14 | 동의 체크 전 → CTA 비활성 | P1 |
| 4.15 | 동의 체크 후 → CTA 활성 | P1 |
| 4.16 | CTA 탭 → `true` 반환하며 바텀시트 닫힘 | P1 |
| 4.17 | 취소 버튼 → `null` 반환하며 바텀시트 닫힘 | P2 |
| 4.18 | 이용 목적, 보유 기간 텍스트 올바르게 표시 | P2 |

#### 4-C. PrivacyPage (동의 관리)

**파일**: `apps/app_user/test/src/features/settings/privacy_page_test.dart`

| # | 테스트 케이스 | 우선순위 |
|---|-------------|---------|
| 4.19 | 동의 현황 로딩 중 → 로딩 인디케이터 | P2 |
| 4.20 | 필수 동의 항목 "동의됨" 텍스트 표시 (토글 없음) | P1 |
| 4.21 | 선택 동의 항목(마케팅, 제3자 제공) Switch 토글 표시 | P1 |
| 4.22 | 마케팅 토글 OFF → `toggleConsent('marketing_consent', false)` 호출 | P1 |
| 4.23 | 토글 저장 실패 → 토글 원상복구 + 스낵바 에러 | P2 |
| 4.24 | 약관 보기 링크 탭 → 바텀시트 표시 | P3 |

---

### Layer 5: Integration 테스트 (라우트 가드)

**파일**: `apps/app_user/test/integration/consent_redirect_test.dart`

**참고 패턴**: `apps/app_user/test/integration/auth_redirect_test.dart`

| # | 테스트 케이스 | 우선순위 |
|---|-------------|---------|
| 5.1 | 로그인 + 필수 동의 미완료 + 보호 경로(`/my`) 접근 → `/signup/consent`로 redirect | P1 |
| 5.2 | 로그인 + 필수 동의 완료 + `/my` 접근 → 정상 진입 | P1 |
| 5.3 | 비로그인 + `/my` 접근 → `/login`으로 redirect (기존 동작 유지) | P1 |
| 5.4 | `/signup/consent` 자체 접근 → redirect 루프 없음 | P1 |
| 5.5 | `hasRequiredConsentsProvider`가 AsyncLoading 상태 → redirect skip (null) | P2 |
| 5.6 | 동의 완료 후 `hasRequiredConsentsProvider` invalidate → 다음 네비게이션에서 정상 진입 | P2 |

```dart
// 예시 구조 (auth_redirect_test.dart 패턴 활용)
testWidgets('redirects to consent when required consents missing', (tester) async {
  final app = createTestApp(
    isLoggedIn: true,
    initialPath: '/my',
    overrides: [
      hasRequiredConsentsProvider.overrideWith((_) => AsyncData(false)),
    ],
  );
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();

  expect(find.byType(SignupConsentScreen), findsOneWidget);
});
```

---

### Layer 6: Golden 테스트

**파일**: `apps/app_user/test/goldens/signup_consent_golden_test.dart`

| # | 테스트 케이스 | 우선순위 |
|---|-------------|---------|
| 6.1 | SignupConsentScreen — 초기 상태 (모든 항목 미체크) | P2 |
| 6.2 | SignupConsentScreen — 전체 동의 상태 (모든 항목 체크) | P2 |
| 6.3 | SignupConsentScreen — 필수만 체크 상태 | P3 |
| 6.4 | IdentityVerificationConsentSheet — 바텀시트 | P3 |
| 6.5 | PrivacyPage — 동의 관리 화면 | P3 |

```dart
// 예시 구조
@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';

void main() {
  goldenTest(
    'SignupConsentScreen initial state',
    fileName: 'signup_consent_initial',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'unchecked',
          child: GoldenPageWrapper(
            overrides: [
              consentControllerProvider.overrideWith((_) => AsyncData([])),
            ],
            child: const SignupConsentScreen(),
          ),
        ),
      ],
    ),
  );
}
```

---

## 기존 코드 영향 범위 테스트

본인인증 화면(`identity_verification_screen.dart`) 수정에 따른 기존 동작 보장:

| # | 테스트 케이스 | 우선순위 |
|---|-------------|---------|
| 7.1 | 이미 `identity_verification` 동의가 있는 유저 → 바텀시트 표시 없이 바로 인증 시작 | P1 |
| 7.2 | 동의 바텀시트에서 취소 → 에러 메시지 표시, 인증 미진행 | P1 |

**파일**: `apps/app_user/test/src/features/consent/ui/identity_verification_consent_integration_test.dart` (또는 기존 verification 테스트에 추가)

---

## 실행 순서

### P1 (필수) — 19건
- DB: 1.1~1.7, 1.9~1.12 (11건)
- Repository: 2.1~2.8 (8건)
- Controller: 3.1, 3.3~3.5 (4건)
- Widget: 4.1~4.5, 4.8, 4.11, 4.13~4.16, 4.20~4.22 (13건)
- Integration: 5.1~5.4 (4건)
- 기존 영향: 7.1~7.2 (2건)

### P2 (권장) — 15건
- DB: 1.8, 1.13, 1.14 (3건)
- Repository: 2.9 (1건)
- Controller: 3.2, 3.6 (2건)
- Widget: 4.6~4.7, 4.9~4.10, 4.12, 4.17~4.19, 4.23 (9건)
- Integration: 5.5~5.6 (2건)

### P3 (선택) — 3건
- Widget: 4.24 (1건)
- Golden: 6.3~6.5 (2건, 6.1~6.2는 P2)

**총 42건** (P1: 32건, P2: 15건, P3: 3건)

---

## 테스트 실행 명령어

```bash
# Repository + Controller 테스트
cd shared/packages/minglit_kit && flutter test test/src/data/repositories/consent_repository_test.dart
cd shared/packages/minglit_kit && flutter test test/src/features/consent/logic/consent_controller_test.dart

# Widget 테스트
cd apps/app_user && flutter test test/src/features/consent/
cd apps/app_user && flutter test test/src/features/settings/privacy_page_test.dart

# Integration 테스트
cd apps/app_user && flutter test test/integration/consent_redirect_test.dart

# Golden 테스트
cd apps/app_user && flutter test --tags golden test/goldens/signup_consent_golden_test.dart

# pgTAP 테스트
supabase test db

# 전체 확인
cd apps/app_user && flutter analyze && flutter test
```
