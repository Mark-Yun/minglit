# 회원가입 동의 (signup-consent) — 기술 설계

## 아키텍처 원칙 요약

| 원칙 | 이 설계에서의 적용 |
|------|-------------------|
| Feature-first | `features/consent/` 독립 피처 생성 (app_user). 다른 피처 직접 import 없음 |
| Repository | `ConsentRepository`(minglit_kit)에서만 Supabase 호출. UI는 Repository만 참조 |
| Coordinator | `ConsentCoordinator`가 모든 라우팅 담당. UI에서 GoRouter 직접 호출 없음 |
| Design System | `MinglitSpacing`, `MinglitColors`, `MinglitTheme` 토큰 사용. 하드코딩 금지 |
| Progressive Consent | 회원가입 동의와 본인인증 동의를 분리. 필요 시점에만 요청 |

## 구현 이슈 분할

| 순서 | 제목 | 라벨 | 의존성 | 비고 |
|------|------|------|--------|------|
| 1 | DB 마이그레이션: `user_consents` 테이블 + `policies` seed | `needs-dev`, `db-migration` | 없음 | 단일 migration 파일 |
| 2 | minglit_kit: `ConsentRepository` + `ConsentController` | `needs-dev`, `enhancement` | #1 | shared 패키지, Riverpod provider |
| 3 | 유저 앱: `SignupConsentScreen` (회원가입 동의 화면) | `needs-dev`, `enhancement` | #2 | 전체동의 토글 + 개별 체크 + 바텀시트 |
| 4 | 유저 앱: 라우트 가드 변경 (동의 여부 redirect) | `needs-dev`, `enhancement` | #2 | `app_router.dart` redirect 로직 수정 |
| 5 | 유저 앱: `IdentityVerificationConsentSheet` (본인인증 전 동의) | `needs-dev`, `enhancement` | #2 | 기존 `IdentityVerificationScreen` 진입 전 바텀시트 |
| 6 | 유저 앱: `PrivacyPage` 동의 관리 탭 교체 | `needs-dev`, `enhancement` | #2 | 기존 placeholder 교체 |

## 수정 대상 파일

### 백엔드

#### DB 마이그레이션 (단일 파일)

**파일**: `supabase/migrations/20260330000004_user_consents.sql`

```sql
-- 1. user_consents 테이블
CREATE TABLE public.user_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_key text NOT NULL,
  consented boolean NOT NULL,
  policy_version integer,
  consented_at timestamptz NOT NULL DEFAULT now(),
  withdrawn_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_consents_user_key_unique UNIQUE(user_id, consent_key)
);

-- 2. 인덱스
CREATE INDEX idx_user_consents_user_id ON public.user_consents(user_id);

-- 3. RLS
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_read_own_consents" ON public.user_consents
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_insert_own_consents" ON public.user_consents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_update_own_consents" ON public.user_consents
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "service_role_all_consents" ON public.user_consents
  FOR ALL USING (auth.role() = 'service_role');

-- 4. GRANT
GRANT SELECT, INSERT, UPDATE ON public.user_consents TO authenticated;
GRANT ALL ON public.user_consents TO service_role;

-- 5. has_required_consents() RPC — 라우트 가드용
CREATE OR REPLACE FUNCTION public.has_required_consents()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_consents
    WHERE user_id = auth.uid()
      AND consent_key = 'terms_of_service'
      AND consented = true
  )
  AND EXISTS (
    SELECT 1 FROM public.user_consents
    WHERE user_id = auth.uid()
      AND consent_key = 'privacy_collection'
      AND consented = true
  )
  AND EXISTS (
    SELECT 1 FROM public.user_consents
    WHERE user_id = auth.uid()
      AND consent_key = 'age_confirmation'
      AND consented = true
  );
$$;

REVOKE EXECUTE ON FUNCTION public.has_required_consents() FROM public;
GRANT EXECUTE ON FUNCTION public.has_required_consents() TO authenticated, service_role;

-- 6. policies seed — 동의 약관 버전
INSERT INTO public.policies (key, value, version, effective_date, description) VALUES
('terms_of_service', '{"content_url": "/terms"}'::jsonb, 1, '2026-03-30', '서비스 이용약관 v1'),
('privacy_collection', '{"items": ["이름","이메일","프로필 사진","관심 태그"], "purpose": "서비스 제공", "retention": "회원 탈퇴 시까지", "refusal_consequence": "서비스 이용 불가"}'::jsonb, 1, '2026-03-30', '개인정보 수집·이용 동의서 v1'),
('third_party_provision', '{"recipient": "이벤트 주최 파트너", "items": ["이름","성별","연령대"], "purpose": "이벤트 운영", "retention": "이벤트 종료 후 30일", "refusal_consequence": "이벤트 신청 시 개별 동의 필요"}'::jsonb, 1, '2026-03-30', '제3자 제공 동의서 v1'),
('marketing_consent', '{"channels": ["push","email"], "purpose": "이벤트/혜택 안내", "refusal_consequence": "없음"}'::jsonb, 1, '2026-03-30', '마케팅 정보 수신 동의서 v1');
```

**설계 결정**:
- `user_consents`를 별도 테이블로 분리 (기존 `user_settings.marketing_consent` 컬럼과 중복). 이유: 동의 이력 추적 + 약관 버전 참조 + 법적 보관 의무(2년). `user_settings.marketing_consent`는 마이그레이션 후 deprecated 처리하되, 이번 이슈에서는 삭제하지 않는다.
- `ON DELETE CASCADE`: 현재는 cascade로 설정하되, 향후 회원 탈퇴 기능(#853 account-deletion)에서 보관 테이블 이동 로직이 추가되면 그때 변경한다.
- Edge Function 없음: 동의 저장은 클라이언트에서 직접 `user_consents` INSERT/UPDATE. RLS가 `auth.uid() = user_id`로 보호하므로 EF 레이어 불필요. 복잡한 서버 사이드 로직이 없다.

### 프론트엔드

#### 신규 파일 — shared (minglit_kit)

| 파일 | 변경 내용 |
|------|----------|
| `minglit_kit/lib/src/data/models/user_consent.dart` | `UserConsent` freezed 모델 (consentKey, consented, policyVersion, consentedAt, withdrawnAt) |
| `minglit_kit/lib/src/data/repositories/consent_repository.dart` | `ConsentRepository` — getConsents(), saveConsents(), updateConsent(), hasRequiredConsents() |
| `minglit_kit/lib/src/features/consent/logic/consent_controller.dart` | `ConsentController` AsyncNotifier — 동의 상태 캐싱 + 변경 |

#### 신규 파일 — app_user

| 파일 | 변경 내용 |
|------|----------|
| `app_user/lib/src/features/consent/ui/signup_consent_page.dart` | `SignupConsentScreen` — 회원가입 동의 화면 (전체동의 토글, 개별 체크, 바텀시트 전문) |
| `app_user/lib/src/features/consent/ui/consent_detail_sheet.dart` | `ConsentDetailSheet` — 약관 전문 바텀시트 (`DraggableScrollableSheet`) |
| `app_user/lib/src/features/consent/ui/identity_verification_consent_sheet.dart` | `IdentityVerificationConsentSheet` — 본인인증 전 CI/DI 동의 바텀시트 |
| `app_user/lib/src/features/consent/logic/consent_coordinator.dart` | `ConsentCoordinator` — 동의 화면 라우팅 |

#### 수정 파일 — app_user

| 파일 | 변경 내용 |
|------|----------|
| `app_user/lib/src/routing/app_routes.dart` | `/signup/consent` 라우트 추가 (`SignupConsentRoute`) |
| `app_user/lib/src/routing/app_router.dart` | redirect 로직에 동의 여부 확인 추가 (조건 2: 로그인 + 필수 동의 미완료 → `/signup/consent`) |
| `app_user/lib/src/features/settings/privacy_page.dart` | placeholder → 동의 관리 UI (약관 목록 + 선택 동의 토글 + 약관 보기 링크) |
| `shared/packages/minglit_kit/lib/src/features/verification/ui/identity_verification_screen.dart` | `_startVerification()` 진입 전 `IdentityVerificationConsentSheet` 표시. 이미 동의한 경우 skip |

## 상세 설계

### 1. ConsentRepository (minglit_kit)

```dart
@Riverpod(keepAlive: true)
ConsentRepository consentRepository(Ref ref) {
  return ConsentRepository(Supabase.instance.client);
}

class ConsentRepository {
  const ConsentRepository(this._client);
  final SupabaseClient _client;

  /// 유저의 모든 동의 상태 조회
  Future<List<UserConsent>> getConsents(String userId) async {
    final response = await _client
        .from('user_consents')
        .select()
        .eq('user_id', userId);
    return response.map((e) => UserConsent.fromJson(e)).toList();
  }

  /// 동의 일괄 저장 (회원가입 시). upsert로 중복 방지.
  Future<void> saveConsents(String userId, List<UserConsent> consents) async {
    await _client.from('user_consents').upsert(
      consents.map((c) => c.toJsonForInsert(userId)).toList(),
      onConflict: 'user_id,consent_key',
    );
  }

  /// 개별 동의 토글 (마케팅, 제3자 제공)
  Future<void> updateConsent(String userId, String key, bool consented) async {
    await _client.from('user_consents').upsert({
      'user_id': userId,
      'consent_key': key,
      'consented': consented,
      if (!consented) 'withdrawn_at': DateTime.now().toIso8601String(),
      if (consented) 'consented_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,consent_key');
  }

  /// 필수 동의 완료 여부 (라우트 가드용). RPC 호출로 단일 쿼리.
  Future<bool> hasRequiredConsents() async {
    final result = await _client.rpc<bool>('has_required_consents');
    return result;
  }
}
```

### 2. ConsentController (minglit_kit)

```dart
@riverpod
class ConsentController extends _$ConsentController {
  @override
  FutureOr<List<UserConsent>> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final repo = ref.watch(consentRepositoryProvider);
    return repo.getConsents(user.id);
  }

  Future<void> saveSignupConsents(Map<String, bool> consents) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = Supabase.instance.client.auth.currentUser!;
      final repo = ref.read(consentRepositoryProvider);
      final list = consents.entries.map((e) => UserConsent(
        consentKey: e.key,
        consented: e.value,
        consentedAt: DateTime.now(),
      )).toList();
      await repo.saveConsents(user.id, list);
      return repo.getConsents(user.id);
    });
  }

  Future<void> toggleConsent(String key, bool value) async {
    final user = Supabase.instance.client.auth.currentUser!;
    final repo = ref.read(consentRepositoryProvider);
    await repo.updateConsent(user.id, key, value);
    ref.invalidateSelf();
  }
}
```

### 3. 라우트 가드 변경 (app_router.dart)

현재 redirect 로직:
1. 비로그인 + 보호 경로 → `/login?from=<path>`

변경 후:
1. 비로그인 + 보호 경로 → `/login?from=<path>`
2. **로그인 + `/signup/consent` 아닌 보호 경로 + 필수 동의 미완료 → `/signup/consent`**
3. 로그인 + 필수 동의 완료 → 정상 진입

```dart
redirect: (context, state) {
  final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
  final path = state.uri.path;

  // ... 기존 dev, explore, 로그인 중 로직 유지 ...

  // 비로그인 + 보호 경로 → 로그인
  if (!isLoggedIn && isProtected) {
    return Uri(path: '/login', queryParameters: {'from': path}).toString();
  }

  // 로그인 상태 + 보호 경로 + 동의 미완료 → 동의 화면
  // /signup/consent 자체는 리다이렉트 루프 방지
  if (isLoggedIn && isProtected && path != '/signup/consent') {
    final hasConsents = ref.read(hasRequiredConsentsProvider).valueOrNull;
    if (hasConsents == false) {
      return '/signup/consent';
    }
  }

  return null;
},
```

**`hasRequiredConsentsProvider`** — 앱 시작 시 1회 조회, 동의 완료 후 갱신:

```dart
@Riverpod(keepAlive: true)
class HasRequiredConsents extends _$HasRequiredConsents {
  @override
  FutureOr<bool> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    return ref.watch(consentRepositoryProvider).hasRequiredConsents();
  }
}
```

**주의사항**: `redirect`는 동기 함수이므로 `hasRequiredConsentsProvider`는 앱 시작 시 미리 resolve되어야 한다. `AsyncLoading` 상태에서는 redirect를 skip(null 반환)하여 race condition 방지. 동의 완료 후 `ref.invalidate(hasRequiredConsentsProvider)`로 갱신하면 `refreshListenable`이 트리거되어 다시 redirect 평가.

### 4. SignupConsentScreen 위젯 트리

```
SignupConsentScreen (ConsumerStatefulWidget)
├── AppBar: 없음 (시스템 back만)
├── Column
│   ├── Text("환영합니다! 👋") — titleLarge
│   ├── Text("서비스 이용을 위해 약관에 동의해주세요") — bodyMedium
│   ├── SwitchListTile("모두 동의합니다") — 전체 토글
│   ├── Divider
│   ├── ConsentItemTile(필수: 서비스 이용약관) → onTap: ConsentDetailSheet
│   ├── ConsentItemTile(필수: 개인정보 수집·이용) → onTap: ConsentDetailSheet
│   ├── ConsentItemTile(필수: 만 14세 이상) — 체크만, 링크 없음
│   ├── ConsentItemTile(선택: 제3자 제공) → onTap: ConsentDetailSheet
│   ├── ConsentItemTile(선택: 마케팅 수신) — 부가 안내문
│   ├── Text("선택 항목 거부해도 서비스 이용 가능") — bodySmall, textSecondary
│   └── ElevatedButton("동의하고 시작하기") — 필수 3개 체크 시 활성
```

**ConsentItemTile**: `min-height: 48px` (WCAG 2.5.8, UX 리뷰 #861 반영). 좌측 체크박스 + 텍스트 + 우측 chevron(전문 있는 경우).

**ConsentDetailSheet**: `showModalBottomSheet` + `DraggableScrollableSheet`. 약관 전문은 `policies` 테이블에서 로드. `TextButton("닫기")` (UX 리뷰 #861 반영, ElevatedButton 아님).

### 5. IdentityVerificationConsentSheet

기존 `IdentityVerificationScreen._startVerification()` 진입 전에 동의 여부를 확인한다.

```dart
// identity_verification_screen.dart 수정
Future<void> _startVerification() async {
  // 1. identity_verification 동의 여부 확인
  final consents = await ref.read(consentControllerProvider.future);
  final hasIdvConsent = consents.any(
    (c) => c.consentKey == 'identity_verification' && c.consented,
  );

  // 2. 미동의 시 바텀시트 표시
  if (!hasIdvConsent && mounted) {
    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const IdentityVerificationConsentSheet(),
    );
    if (agreed != true) {
      setState(() => _errorMessage = '본인인증 동의가 필요합니다.');
      return;
    }
    // 동의 저장
    await ref.read(consentControllerProvider.notifier)
        .saveSignupConsents({'identity_verification': true});
  }

  // 3. 기존 Iamport 인증 로직 (변경 없음)
  // ...
}
```

### 6. PrivacyPage 동의 관리

기존 placeholder를 실제 동의 관리 화면으로 교체한다.

```
PrivacyPage (ConsumerWidget)
├── AppBar: "개인정보"
├── ListView
│   ├── Section: "동의 현황"
│   │   ├── ListTile("서비스 이용약관" / "동의됨" / trailing: chevron) → 바텀시트
│   │   ├── ListTile("개인정보 수집·이용" / "동의됨" / trailing: chevron) → 바텀시트
│   │   ├── ListTile("제3자 제공 동의" / trailing: Switch) → 토글 가능
│   │   ├── ListTile("마케팅 정보 수신" / trailing: Switch) → 토글 가능
│   │   └── ListTile("본인인증 정보" / "동의됨" 또는 "미동의") → 읽기 전용
│   ├── Section: "약관 보기"
│   │   ├── ListTile("서비스 이용약관") → 바텀시트 or 웹뷰
│   │   └── ListTile("개인정보처리방침") → 바텀시트 or 웹뷰
│   └── Section: "계정"
│       └── ListTile("회원 탈퇴") → 탈퇴 플로우 (account-deletion 피처 연동)
```

- 필수 동의 항목(이용약관, 개인정보 수집·이용): "동의됨" 텍스트, 색상 `textSecondary` (UX 리뷰 #861)
- 선택 동의 항목(제3자 제공, 마케팅): `Switch` 위젯으로 토글
- 토글 실패 시: 원상복구 + 스낵바 에러

## 데이터 흐름

### 회원가입 동의 플로우

```
[OAuth 로그인 완료]
  ↓
app_router redirect: hasRequiredConsents == false
  ↓
/signup/consent (SignupConsentScreen)
  ↓ (CTA 탭)
ConsentCoordinator.submitConsents()
  ↓
ConsentController.saveSignupConsents()
  ↓
ConsentRepository.saveConsents() → Supabase user_consents INSERT
  ↓
ref.invalidate(hasRequiredConsentsProvider)
  ↓
app_router redirect: hasRequiredConsents == true → 원래 목적지
```

### 본인인증 동의 플로우

```
[/certification 진입]
  ↓
IdentityVerificationScreen._startVerification()
  ↓ (identity_verification 미동의)
IdentityVerificationConsentSheet (바텀시트)
  ↓ (동의 체크 + CTA)
ConsentController.saveSignupConsents({'identity_verification': true})
  ↓
ConsentRepository.saveConsents() → Supabase user_consents INSERT
  ↓
Iamport 인증 시작 (기존 로직)
```

### 동의 관리 플로우

```
[/my/privacy 진입]
  ↓
ConsentController.build() → 전체 동의 상태 로드
  ↓
PrivacyPage UI 렌더
  ↓ (마케팅 토글)
ConsentController.toggleConsent('marketing_consent', false)
  ↓
ConsentRepository.updateConsent() → Supabase user_consents UPDATE
```

## 의존성 방향

```
UI (features/consent/ui/)
  ↓ (coordinator 경유)
Coordinator (consent_coordinator.dart)
  ↓ (controller 경유)
Controller (minglit_kit/consent_controller.dart)
  ↓ (repository 경유)
Repository (minglit_kit/consent_repository.dart)
  ↓ (Supabase SDK)
DB (user_consents, policies)
```

UI → Coordinator → Controller → Repository → DB
모든 화살표는 단방향. 역방향 참조 없음.

## user_settings.marketing_consent 마이그레이션 전략

현재 `user_settings` 테이블에 `marketing_consent` 컬럼이 존재한다. 기존 유저의 데이터를 보존하면서 `user_consents` 테이블로 전환한다.

| 단계 | 시점 | 작업 |
|------|------|------|
| 1 | 이번 이슈 | `user_consents` 테이블 생성. 앱은 `user_consents`만 참조 |
| 2 | 이번 이슈 | `user_settings.marketing_consent`는 그대로 유지 (deprecated 표시) |
| 3 | 후속 이슈 | 기존 유저의 `user_settings.marketing_consent = true` 데이터를 `user_consents`로 마이그레이션하는 one-time 스크립트 |
| 4 | 후속 이슈 | `user_settings.marketing_consent` 컬럼 삭제 |

이번 이슈에서는 기존 유저와 신규 유저를 구분한다:
- **신규 유저** (가입 시 `user_consents`에 레코드 없음): 자동으로 `/signup/consent`로 redirect
- **기존 유저** (`user_consents` 레코드 없음이지만 이미 서비스 이용 중): `has_required_consents()`가 `false`를 반환하므로, 다음 로그인 시 동의 화면으로 안내. 이는 의도된 동작 — 법적 요구사항으로 기존 유저도 명시적 동의가 필요.

## 기존 유저 동의 수집 UX

기존 유저가 앱 업데이트 후 최초 진입 시:
1. 보호 경로 접근 → `hasRequiredConsents == false` → `/signup/consent`
2. 동의 화면 헤더를 "환영합니다!" 대신 **"약관이 업데이트되었습니다"**로 분기
3. 분기 조건: `authStateChangesProvider`의 `event == AuthChangeEvent.signedIn`이 아닌 경우 (이미 로그인 상태)

이 분기는 `SignupConsentScreen`에서 `isNewUser` 파라미터 또는 로컬 체크로 구현.

## 리스크 및 대응

| 리스크 | 확률 | 대응 |
|--------|------|------|
| redirect에서 `hasRequiredConsentsProvider`가 `AsyncLoading` 상태 | 중 | `valueOrNull`이 null이면 redirect skip → 다음 navigation에서 재평가 |
| 기존 유저 대량 동의 화면 노출로 이탈 | 중 | 동의 화면 UX를 간결하게 유지. "전체 동의" 1탭으로 완료 가능. 법적 의무이므로 회피 불가 |
| `user_settings.marketing_consent`와 `user_consents` 데이터 불일치 | 낮음 | 이번 이슈에서는 `user_consents`만 참조. 마이그레이션 스크립트는 후속 이슈 |
| 약관 전문 로딩 실패 (policies 테이블 쿼리 실패) | 낮음 | 바텀시트에서 shimmer + 재시도 버튼. 약관 로딩 실패해도 체크박스 자체는 비활성화하지 않음 |
| 동의 저장 실패 시 부분 저장 | 낮음 | `saveConsents`는 단일 upsert 배치. 실패 시 전체 롤백 (Supabase default) |

## UX 리뷰 반영 사항 (#861)

| 항목 | 반영 위치 |
|------|----------|
| 동의 항목 행 min-height 48px (WCAG 2.5.8) | `ConsentItemTile` |
| 바텀시트 닫기 버튼 TextButton (dismiss 액션) | `ConsentDetailSheet` |
| 동의 관리 아이템 패딩 `medium` (16px) 토큰 | `PrivacyPage` |
| "동의됨" 상태 색상 `textSecondary` (WCAG AA 4.5:1) | `PrivacyPage` |
| `screenEdge` 패딩 16px | 모든 동의 화면 |
