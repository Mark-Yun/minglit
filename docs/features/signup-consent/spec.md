# 회원가입 개인정보 수집·이용 동의 스펙

## 개요

### 배경
법률/개인정보보호 감사(#747)에서 "회원가입 시 명시적 동의 수집 UI 없음"이 [High] 이슈로 지적되었다. 현재 OAuth 로그인 후 바로 앱 접근이 가능하며, CI/DI 수집(본인인증) 시에도 별도 동의 절차가 없다. 개인정보보호법 제15조/제22조 위반에 해당한다.

### 핵심 원칙
1. **필수/선택 분리**: 필수 동의만으로 서비스 이용 가능. 선택 동의 거부 시 불이익 없음
2. **명시적 동의**: 사전 체크(pre-checked) 금지, 사용자가 직접 탭/체크
3. **동의 이력 추적**: 언제, 어떤 버전의 약관에 동의했는지 DB에 기록
4. **점진적 동의(Progressive Consent)**: 모든 동의를 한 화면에 몰아넣지 않고, 필요 시점에 요청

### 참고 앱
- **토스(Toss)**: 카드형 단계적 동의 + 간결한 요약문
- **카카오(Kakao)**: 필수/선택 명확 구분 + 바텀시트 전문 보기
- **당근마켓(Karrot)**: 전체동의 토글 + 개별 체크박스 + 선택 항목 안내문

---

## 구성 요소

### 화면 1: 회원가입 약관 동의 (SignupConsentScreen)

**표시 시점**: 최초 OAuth 로그인 후 (신규 유저만). 기존 유저는 바로 앱 진입.

**레이아웃** (위→아래):

```
┌──────────────────────────────────┐
│  [백 버튼]                       │ ← AppBar (없음, 시스템 back만)
│                                  │
│  환영합니다! 👋                  │ ← titleLarge (20px bold)
│  서비스 이용을 위해              │ ← bodyMedium (16px)
│  약관에 동의해주세요             │
│                                  │
│  ┌────────────────────────────┐  │
│  │ ☑ 모두 동의합니다          │  │ ← 전체동의 토글 (필수+선택 모두)
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │ (필수) 서비스 이용약관     │ → │ ← 탭 → 바텀시트로 전문
│  │ (필수) 개인정보 수집·이용  │ → │ ← 탭 → 바텀시트로 전문
│  │ (필수) 만 14세 이상입니다  │ ○  │ ← 체크박스 (링크 없음)
│  │ (선택) 제3자 제공 동의     │ → │ ← 탭 → 바텀시트로 전문
│  │ (선택) 마케팅 정보 수신    │ ○  │ ← 체크박스 + "거부해도 서비스 이용 가능"
│  └────────────────────────────┘  │
│                                  │
│  ※ 선택 항목에 동의하지 않아도  │ ← bodySmall (13px), textSecondary
│    서비스 이용에 영향이 없습니다 │
│                                  │
│  ┌────────────────────────────┐  │
│  │      동의하고 시작하기      │  │ ← CTA 버튼 (필수 3개 체크 시 활성)
│  └────────────────────────────┘  │
│                                  │
└──────────────────────────────────┘
```

#### 구성 요소 상세

| 요소 | 위젯 | 동작 |
|------|------|------|
| 전체동의 토글 | `SwitchListTile` | ON: 모든 항목 체크. OFF: 모든 항목 해제. 중간 상태 없음 |
| 약관 항목 | `ListTile` + trailing `Icon(Icons.chevron_right)` | 탭 → 바텀시트로 전문 표시 |
| 만 14세 이상 | `CheckboxListTile` | 체크/해제만. 링크 없음 |
| 제3자 제공 | `ListTile` + trailing `Icon(Icons.chevron_right)` | 탭 → 바텀시트로 제공받는 자/항목/목적/기간 전문 |
| 마케팅 수신 | `CheckboxListTile` | 체크/해제 + 부가 텍스트 |
| CTA 버튼 | `ElevatedButton` | 필수 3개 모두 체크 시 `primary` 색상 활성. 아니면 비활성 |
| 바텀시트 | `showModalBottomSheet` + `DraggableScrollableSheet` | 약관 전문 스크롤 + "닫기" 버튼 |

#### 동의 항목 정의

| # | 항목 | 필수/선택 | key (policies 테이블) | 내용 요약 |
|---|------|----------|----------------------|----------|
| 1 | 서비스 이용약관 | 필수 | `terms_of_service` | 서비스 이용 조건, 금지 행위, 계정 관리 |
| 2 | 개인정보 수집·이용 | 필수 | `privacy_collection` | 수집 항목(이름, 이메일, 프로필), 목적, 보유기간 |
| 3 | 만 14세 이상 확인 | 필수 | `age_confirmation` | (약관 아님, 확인란) |
| 4 | 제3자 제공 동의 | 선택 | `third_party_provision` | 파트너(주최자)에게 참가자 정보 제공 — 이벤트 운영 목적 |
| 5 | 마케팅 정보 수신 | 선택 | `marketing_consent` | 이벤트/혜택 안내 (Push, SMS, 이메일) |

#### 법적 필수 고지 (개인정보보호법 제15조/제17조)

각 동의 항목의 바텀시트 전문에는 아래 고지를 **반드시** 포함한다:

**개인정보 수집·이용 (`privacy_collection`) 바텀시트:**

| 고지 항목 | 내용 |
|----------|------|
| 수집 항목 | 이름, 이메일, 프로필 사진, 관심 태그 |
| 수집 목적 | 서비스 제공 (계정 관리, 이벤트 매칭, 프로필 표시) |
| 보유 기간 | 회원 탈퇴 시까지 (관련 법령에 따른 보존 기간 별도 안내) |
| 거부 권리 | 동의를 거부할 수 있으나, 거부 시 서비스 이용이 불가합니다 |

**제3자 제공 (`third_party_provision`) 바텀시트:**

| 고지 항목 | 내용 |
|----------|------|
| 제공받는 자 | 이벤트 주최 파트너 (이벤트 신청 시 해당 파트너에 한정) |
| 제공 항목 | 이름(닉네임), 연령대, 자격 인증 정보(직업/소속 — 본인인증 완료 유저만) |
| 제공 목적 | 이벤트 운영 (참가자 확인, 매칭 진행, 체크인) |
| 보유 기간 | 이벤트 종료 후 30일 |
| 거부 권리 | 동의를 거부할 수 있으며, 거부해도 서비스 이용에 제한이 없습니다. 단, 이벤트 신청 시 개별 동의를 다시 요청합니다 |

> **위탁 vs 제3자 제공 구분**: Portone(결제), Iamport(본인인증) 등은 **위탁**이므로 별도 동의 불필요 (개인정보처리방침에 공개). 파트너에게 참가자 정보를 제공하는 것은 **제3자 제공**에 해당하여 별도 동의 필요.

### 화면 2: 본인인증 CI/DI 수집 동의 (IdentityVerificationConsentSheet)

**표시 시점**: `/certification` (본인인증) 화면에서 "본인인증 시작" 버튼 탭 전

**레이아웃** (바텀시트):

```
┌──────────────────────────────────┐
│  본인인증 정보 수집·이용 동의    │ ← titleMedium (16px bold)
│                                  │
│  본인확인을 위해 아래 정보를     │ ← bodyMedium (16px)
│  수집합니다.                     │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 수집 항목                  │  │
│  │ • 이름, 생년월일, 성별     │  │
│  │ • 휴대폰 번호              │  │
│  │ • CI (연계정보)            │  │
│  │ • DI (중복확인정보)        │  │
│  │                            │  │
│  │ 이용 목적                  │  │
│  │ • 본인확인 및 실명 인증    │  │
│  │ • 중복 가입 방지           │  │
│  │                            │  │
│  │ 보유 기간                  │  │
│  │ • 회원 탈퇴 시까지         │  │
│  │  (관련 법령에 따라 보존)   │  │
│  └────────────────────────────┘  │
│                                  │
│  ☑ (필수) 위 내용에 동의합니다  │ ← 체크해야 진행 가능
│                                  │
│  ┌────────────────────────────┐  │
│  │     본인인증 시작하기       │  │ ← CTA (동의 체크 시 활성)
│  └────────────────────────────┘  │
│  ┌────────────────────────────┐  │
│  │          취소               │  │ ← TextButton
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

### 화면 3: 동의 관리 (MyPage → 개인정보 설정)

**표시 시점**: `/my/privacy` (기존 PrivacyPage 교체)

**추가 항목**:

| 항목 | 초기값 | 변경 가능 |
|------|--------|----------|
| 서비스 이용약관 | 동의 | 불가 (탈퇴로만 철회) |
| 개인정보 수집·이용 | 동의 | 불가 (탈퇴로만 철회) |
| 제3자 제공 | 가입 시 선택 | **가능** — 토글 (철회 시 이벤트 신청마다 개별 동의 요청) |
| 마케팅 정보 수신 | 가입 시 선택 | **가능** — 토글 |
| 본인인증 정보 | 동의 | 불가 (탈퇴로만 철회) |
| 약관 보기 | — | 링크 → 바텀시트 |

---

## 데이터 소스

### 신규 테이블: `user_consents`

```sql
CREATE TABLE public.user_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_key text NOT NULL,        -- 'terms_of_service', 'privacy_collection', 'age_confirmation', 'third_party_provision', 'marketing_consent', 'identity_verification'
  consented boolean NOT NULL,
  policy_version integer,           -- policies 테이블 version 참조
  consented_at timestamptz NOT NULL DEFAULT now(),
  withdrawn_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_consents_user_key_unique UNIQUE(user_id, consent_key)
);

ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

-- 유저는 자기 동의만 조회/수정
CREATE POLICY "user_read_own_consents" ON public.user_consents
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_insert_own_consents" ON public.user_consents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_update_own_consents" ON public.user_consents
  FOR UPDATE USING (auth.uid() = user_id);

-- service_role 전체 권한
CREATE POLICY "service_role_all_consents" ON public.user_consents
  FOR ALL USING (auth.role() = 'service_role');
```

### 신규 policies seed

```sql
INSERT INTO public.policies (key, value, version, effective_date, description) VALUES
('terms_of_service', '{"content_url": "/terms"}'::jsonb, 1, '2026-03-30', '서비스 이용약관 v1'),
('privacy_collection', '{"items": ["이름","이메일","프로필 사진","관심 태그"], "purpose": "서비스 제공 (계정 관리, 이벤트 매칭, 프로필 표시)", "retention": "회원 탈퇴 시까지", "refusal_consequence": "서비스 이용 불가"}'::jsonb, 1, '2026-03-30', '개인정보 수집·이용 동의서 v1'),
-- Fix #1141: 성별 제거, 자격 인증 정보 추가
('third_party_provision', '{"recipient": "이벤트 주최 파트너", "items": ["이름(닉네임)","연령대","자격 인증 정보(직업/소속)"], "purpose": "이벤트 운영 (참가자 확인, 매칭, 체크인)", "retention": "이벤트 종료 후 30일", "refusal_consequence": "이벤트 신청 시 개별 동의 필요"}'::jsonb, 1, '2026-03-30', '제3자 제공 동의서 v1'),
('marketing_consent', '{"channels": ["push","email"], "purpose": "이벤트/혜택 안내", "refusal_consequence": "없음"}'::jsonb, 1, '2026-03-30', '마케팅 정보 수신 동의서 v1');
```

### Repository 메서드

| 메서드 | 설명 |
|--------|------|
| `getConsentStatuses(userId)` | 유저의 모든 동의 상태 조회 |
| `saveConsents(userId, List<Consent>)` | 동의 일괄 저장 (upsert) |
| `updateMarketingConsent(userId, bool)` | 마케팅 동의 토글 |
| `hasRequiredConsents(userId)` | 필수 동의 완료 여부 (가드용) |

### Provider

| Provider | 설명 |
|----------|------|
| `consentRepositoryProvider` | Supabase 연동 Repository |
| `consentStatusProvider` | 현재 유저 동의 상태 (AsyncNotifier) |

---

## 라우트 변경

| 변경 | 라우트 | 설명 |
|------|--------|------|
| **신규** | `/signup/consent` | 회원가입 약관 동의 화면 |
| **수정** | `/certification` | 본인인증 전 동의 바텀시트 추가 |
| **수정** | `/my/privacy` | 동의 관리 항목 추가 (기존 placeholder 교체) |

### 라우트 가드 변경

**유저 앱 redirect 로직 수정**:
```
1. 비로그인 + 보호 경로 → /login?from=<path>
2. 로그인 + 필수 동의 미완료 → /signup/consent
3. 로그인 + 필수 동의 완료 → 정상 진입
```

조건 2는 `user_consents` 테이블에서 `terms_of_service`, `privacy_collection`, `age_confirmation` 3개가 모두 `consented = true`인지 확인.

---

## 에러/로딩 상태

### 회원가입 동의 화면
| 상태 | 처리 |
|------|------|
| 동의 저장 중 | CTA 버튼 로딩 인디케이터 |
| 동의 저장 실패 | 스낵바 "동의 저장에 실패했습니다. 다시 시도해주세요." |
| 네트워크 오류 | 스낵바 + 재시도 버튼 |
| 약관 로딩 중 | 바텀시트 내 shimmer loading |

### 본인인증 동의 바텀시트
| 상태 | 처리 |
|------|------|
| 동의 저장 + Portone 호출 중 | CTA 버튼 로딩 |
| Portone 오류 | 기존 에러 핸들링 유지 |

### 동의 관리 페이지
| 상태 | 처리 |
|------|------|
| 동의 상태 로딩 중 | CircularProgressIndicator |
| 마케팅 토글 저장 실패 | 토글 원상복구 + 스낵바 |

---

## 구현 이슈 분할 (예상)

| # | 제목 | 의존성 | 설명 |
|---|------|--------|------|
| 1 | DB: user_consents 테이블 + policies seed | 없음 | 마이그레이션 파일 |
| 2 | Flutter: ConsentRepository + Provider | #1 | Supabase 연동 |
| 3 | Flutter: SignupConsentScreen | #2 | 약관 동의 화면 |
| 4 | Flutter: 라우트 가드 (동의 여부 확인) | #2 | redirect 로직 수정 |
| 5 | Flutter: IdentityVerificationConsentSheet | #2 | 본인인증 전 동의 |
| 6 | Flutter: PrivacyPage 동의 관리 탭 | #2 | 기존 placeholder 교체 |
| 7 | EF: consent-save Edge Function | #1 | 동의 저장 API (선택, 클라이언트 direct도 가능) |

---

## 법적 근거

| 근거 | 내용 |
|------|------|
| 개인정보보호법 제15조 | 개인정보 수집·이용 시 동의 받아야 함 |
| 개인정보보호법 제22조 | 동의 방법 — 필수/선택 구분, 개별 동의 |
| 개인정보보호법 제17조 | 제3자 제공 시 별도 동의 (제공받는 자, 항목, 목적, 기간, 거부 권리 고지) |
| 개인정보보호법 제22조 | 필수/선택 동의 분리, 선택 거부 시 서비스 거부 금지 |
| 개인정보보호법 제24조 | 민감정보(CI/DI) 별도 명시적 동의 |
| 정보통신망법 제27조의2 | 개인정보처리방침 공개 |
| Apple/Google 앱스토어 정책 | 데이터 수집 투명성 요구 |

### 동의 이력 보관

| 항목 | 요건 |
|------|------|
| 최소 보관 기간 | 동의 기록 2년 (개인정보보호법 시행령) |
| 권장 보관 기간 | 5년 (업계 관행, Hinge 등 글로벌 데이팅 앱 기준) |
| 보관 내용 | 동의 일시, 동의 항목(consent_key), 약관 버전(policy_version), 동의/철회 여부 |
| 탈퇴 시 | user_consents 레코드는 `ON DELETE CASCADE`가 아닌 별도 보관 테이블로 이동 (추후 구현) |
