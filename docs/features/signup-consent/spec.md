# 회원가입 동의 (Signup Consent) 스펙

## 개요

회원가입 시 개인정보보호법 제15조/제22조에 따른 **명시적 동의 수집 UI**를 구현한다.
현재 OAuth 로그인 후 바로 앱에 진입하므로, 첫 로그인 시 동의 화면을 삽입해야 한다.

### 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **법적 준수** | 개인정보보호법 제15조(수집·이용), 제22조(동의 방법) 완전 준수 |
| **최소 마찰** | 기존 OAuth 로그인 경험을 해치지 않는 선에서 필수 동의만 최초 1회 수집 |
| **투명성** | 무엇을 왜 수집하는지 한 줄 요약 + 전문 열람 제공 |
| **통제권** | 설정에서 언제든 동의 내용 확인/변경 가능 |

### 참고한 앱/트렌드

| 앱 | 참고 포인트 |
|----|-----------|
| **토스** | 전체동의 + 개별 토글, 하단 고정 CTA, 미니멀한 UI |
| **카카오** | 소셜 로그인 후 최소 추가 동의, 접기/펼치기 약관 |
| **네이버** | [필수]/[선택] 태그 구분, 단계별 프로그레스 |
| **일반 트렌드** | 알기 쉬운 요약문 + 전문 접기, 마케팅 동의 명확한 선택 표시 |

### 법적 근거

| 조문 | 요구사항 | 본 스펙 반영 |
|------|---------|-------------|
| 개인정보보호법 §15 | 수집·이용 목적, 항목, 보유기간 고지 | 각 동의 항목에 명시 |
| 개인정보보호법 §22 | 필수 vs 선택 동의 분리, 선택 거부 시 서비스 이용 가능 보장 | [필수]/[선택] 태그 + 선택 항목 미동의 시에도 가입 가능 |
| 개인정보보호법 §29 | 안전조치 의무 (CI/DI 암호화) | 본인인증 동의에 암호화 저장 안내 포함 |
| 정보통신망법 §22 | 위치정보 수집 시 별도 동의 | 현재 수집 항목에 위치 미포함 (별도 대응 불필요) |

---

## 구성 요소

### 1. 동의 화면 (ConsentScreen)

**진입 조건**: 첫 로그인 시 (user_consents 테이블에 기록이 없는 경우)

**화면 구조** (위→아래):

```
┌─────────────────────────────────────────┐
│  ←  (뒤로가기 없음 — 필수 플로우)         │
├─────────────────────────────────────────┤
│                                         │
│  환영합니다!                              │  ← 타이틀
│  밍릿 이용을 위해 약관에 동의해 주세요.     │  ← 설명
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ ☑ 전체 동의                      │    │  ← 전체동의 토글
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─ [필수] 서비스 이용약관 ─── 보기 ▸ ─┐ │
│  │ 밍릿 서비스 이용을 위한 기본 약관     │ │  ← 한 줄 요약
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─ [필수] 개인정보 수집·이용 ─ 보기 ▸ ─┐ │
│  │ 이름, 이메일, 휴대폰번호 수집·이용    │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─ [필수] 만 14세 이상 ────────────────┐ │
│  │ 만 14세 이상 확인                    │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─ [선택] 마케팅 정보 수신 ─── 보기 ▸ ─┐ │
│  │ 이벤트, 할인 혜택 등 안내 수신        │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │ 다 같이 시작하기                     │ │  ← 하단 고정 버튼
│  │ (필수 항목 동의 시 활성화)            │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  ※ 선택 항목 미동의 시에도 서비스 이용이    │  ← 안내 문구
│     가능합니다.                           │
└─────────────────────────────────────────┘
```

### 2. 약관 상세 보기 (TermsDetailSheet)

각 "보기 ▸" 탭 시 MinglitBottomSheet로 표시:

| 항목 | 내용 출처 | 표시 방식 |
|------|----------|----------|
| 서비스 이용약관 | `landing_user/src/app/terms/page.tsx` 서비스약관 섹션 | 스크롤 가능한 바텀시트 |
| 개인정보 수집·이용 | 별도 동의서 (아래 템플릿 참고) | 스크롤 가능한 바텀시트 |
| 마케팅 정보 수신 | 간결한 설명 (Push/SMS/Email) | 바텀시트 |
| 만 14세 이상 | 확인 문구만 (상세 없음) | — |

**개인정보 수집·이용 동의서 내용**:
```
[개인정보 수집·이용 동의]

1. 수집 항목
   - 필수: 이메일, 이름(닉네임)
   - 본인인증 시: CI/DI, 이름, 생년월일, 성별, 휴대폰번호

2. 수집 목적
   - 회원 식별 및 관리
   - 서비스 제공 및 이벤트 참여 관리
   - 본인인증 및 중복가입 방지

3. 보유 기간
   - 회원 탈퇴 시까지
   - 단, 관련 법령에 따라 보존 필요 시 해당 기간 동안 보관

4. 동의 거부 권리
   - 필수 항목 동의 거부 시 서비스 이용이 제한됩니다.
   - 선택 항목은 동의하지 않아도 서비스 이용이 가능합니다.
```

### 3. 본인인증 전 CI/DI 동의 (Identity Consent Dialog)

**진입 조건**: 본인인증(IdentityVerificationScreen) 진입 직전

**화면 구조**:
```
┌─────────────────────────────────────┐
│                                     │
│  본인확인정보 수집·이용 동의          │
│                                     │
│  본인인증을 위해 아래 정보를          │
│  수집·이용합니다.                     │
│                                     │
│  • CI (연계정보)                     │
│  • DI (중복확인정보)                  │
│  • 이름, 생년월일, 성별              │
│  • 휴대폰번호                        │
│                                     │
│  수집목적: 본인확인 및 중복가입 방지   │
│  보유기간: 회원 탈퇴 시까지           │
│                                     │
│  ※ CI/DI는 암호화되어 안전하게        │
│     저장됩니다.                      │
│                                     │
│  ┌──────────┐  ┌──────────────────┐ │
│  │   취소    │  │   동의하고 인증   │ │
│  └──────────┘  └──────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### 4. 제3자 제공 동의 (이벤트 신청 시)

**진입 조건**: 이벤트 신청 위저드 진행 중, 파트너에게 정보 제공 필요 시

**화면 구조**: 신청 위저드 내 하나의 스텝으로 포함
```
┌─────────────────────────────────────┐
│  [필수] 개인정보 제3자 제공 동의       │
│                                     │
│  이벤트 주최 파트너에게 아래 정보가    │
│  제공됩니다.                         │
│                                     │
│  제공받는 자: {파트너 브랜드명}        │
│  제공 항목: 이름, 휴대폰번호           │
│  제공 목적: 이벤트 참여 확인 및 연락   │
│  보유기간: 이벤트 종료 후 6개월        │
│                                     │
│  ☑ 위 내용을 확인했으며 동의합니다.    │
│                                     │
└─────────────────────────────────────┘
```

---

## 데이터 소스

### 신규 테이블: `user_consents`

```sql
create table public.user_consents (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  consent_type consent_type_enum not null,
  consent_version text not null default '1.0',
  consented_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  source text not null default 'signup',
  constraint user_consents_pkey primary key (id)
);

create type consent_type_enum as enum (
  'terms_of_service',
  'privacy_collection',
  'age_verification',
  'marketing',
  'ci_di_collection',
  'third_party_sharing'
);

create index idx_user_consents_user_id on public.user_consents(user_id);
create index idx_user_consents_type_active on public.user_consents(user_id, consent_type)
  where withdrawn_at is null;
```

### RLS 정책

```sql
-- 유저는 자신의 동의 기록만 조회 가능
create policy "Users can view own consents"
  on public.user_consents for select
  using (auth.uid() = user_id);

-- 서비스 역할은 전체 접근 가능 (EF에서 사용)
create policy "Service role full access"
  on public.user_consents for all
  using (auth.role() = 'service_role');
```

### Edge Function

```sql
-- 동의 기록 저장 RPC
create or replace function public.save_user_consents(
  p_user_id uuid,
  p_consents jsonb -- [{type: 'terms_of_service', version: '1.0'}, ...]
)
returns void as $$
  insert into public.user_consents (user_id, consent_type, consent_version, source)
  select
    p_user_id,
    (consent->>'type')::consent_type_enum,
    consent->>'version',
    coalesce(consent->>'source', 'signup')
  from jsonb_array_elements(p_consents) as consent;
$$ language sql security definer;
```

### 데이터 흐름

```
OAuth 로그인 완료
  │
  ├─ user_consents에 기록 있음 → 바로 앱 진입
  │
  └─ user_consents에 기록 없음 → ConsentScreen 표시
       │
       ├─ 필수 동의 완료
       │    ├─ save_user_consents RPC 호출
       │    ├─ marketing_consent → user_settings 업데이트
       │    └─ 앱 진입 (원래 가려던 경로로)
       │
       └─ 뒤로가기 → 로그아웃 처리
```

### 필요 Provider/Repository 메서드

| 메서드 | 위치 | 설명 |
|--------|------|------|
| `hasRequiredConsents()` | `minglit_kit/.../auth_repository.dart` | user_consents 조회하여 필수 동의 여부 반환 |
| `saveConsents(List<ConsentType>)` | `minglit_kit/.../auth_repository.dart` | 동의 기록 저장 RPC 호출 |
| `updateMarketingConsent(bool)` | `minglit_kit/.../settings_repository.dart` | user_settings.marketing_consent 업데이트 |

---

## 라우트 변경

### 신규 라우트

| 라우트 | 경로 | 화면 | 비고 |
|--------|------|------|------|
| `ConsentRoute` | `/consent` | `ConsentScreen` | 보호됨 (로그인 필수), 바로가기 불가 |

### 라우트 추가 위치

`apps/app_user/lib/src/routing/app_routes.dart`에 `ConsentRoute` 추가.

### Redirect 로직 변경

`apps/app_user/lib/src/routing/app_router.dart`에 추가:
```
기존:
  로그인됨 + 보호된 경로 → 정상 진입

변경:
  로그인됨 + 필수 동의 미완료 + /consent가 아님 → /consent
  로그인됨 + 필수 동의 완료 + /consent → from 경로 또는 /
  로그인됨 + 필수 동의 완료 + 보호된 경로 → 정상 진입
```

**주의**: `/consent`는 보호된 경로에서 제외 (로그인은 되어 있어야 하지만, 보호 경로 redirect보다 먼저 체크).

---

## 동의 항목 정의

### 가입 시 동의 (ConsentScreen)

| # | 타입 | 필수/선택 | consent_type_enum | 요약 | 전문 출처 |
|---|------|----------|-------------------|------|----------|
| 1 | 서비스 이용약관 | 필수 | `terms_of_service` | 밍릿 서비스 이용을 위한 기본 약관 | landing_user/terms |
| 2 | 개인정보 수집·이용 | 필수 | `privacy_collection` | 이름, 이메일 수집·이용 | 별도 동의서 |
| 3 | 만 14세 이상 | 필수 | `age_verification` | 만 14세 이상 확인 | 체크박스만 |
| 4 | 마케팅 정보 수신 | 선택 | `marketing` | 이벤트, 할인 혜택 안내 | 간결 설명 |

### 본인인증 시 동의

| # | 타입 | 필수/선택 | consent_type_enum | 요약 |
|---|------|----------|-------------------|------|
| 5 | CI/DI 수집·이용 | 필수 | `ci_di_collection` | 본인확인정보 수집·이용 |

### 이벤트 신청 시 동의

| # | 타입 | 필수/선택 | consent_type_enum | 요약 |
|---|------|----------|-------------------|------|
| 6 | 제3자 제공 | 필수 | `third_party_sharing` | 파트너에게 참가자 정보 제공 |

---

## 에러/로딩 상태

### ConsentScreen

| 상태 | 처리 |
|------|------|
| 동의 저장 중 | MinglitButton 로딩 상태 (스피너) |
| 동의 저장 실패 | SnackBar 에러 메시지 + 재시도 |
| 네트워크 오류 | "네트워크 연결을 확인해 주세요" SnackBar |
| 전체동의 토글 | 체크 → 모든 항목 선택 / 해제 → 모든 항목 해제 (필수/선택 구분 유지 안함 — 전체동의는 편의 기능) |

### CI/DI 동의 다이얼로그

| 상태 | 처리 |
|------|------|
| 취소 | 다이얼로그 닫기, 본인인증 진행 안 함 |
| 동의 | 본인인증(PortOne) 실행 → 기존 IdentityVerificationScreen 진입 |

---

## 엣지 케이스

| 케이스 | 대응 |
|--------|------|
| 앱 재설치 후 첫 실행 | user_consents에 기록 있으면 건너뜀 |
| 동의 버전 업데이트 | consent_version 비교하여 신규 동의 요청 (현재는 v1.0만 존재) |
| 마케팅 동의만 나중에 변경 | 설정에서 변경 가능 (user_settings.marketing_consent) |
| OAuth 로그인 실패 후 재시도 | 동의 화면 도달 전이므로 영향 없음 |
| 백그라운드에서 앱 복귀 | 동의 화면 유지 (상태 보존) |

---

## 구현 이슈 분할 (예상)

| 순서 | 제목 | 의존성 | 설명 |
|------|------|--------|------|
| 1 | `user_consents` 테이블 마이그레이션 | 없음 | DB 스키마 + RLS + RPC |
| 2 | ConsentScreen UI | 1 | 동의 화면 위젯 + 상태관리 |
| 3 | 라우트 + Redirect 로직 | 2 | ConsentRoute 추가 + auth guard 수정 |
| 4 | CI/DI 동의 다이얼로그 | 1 | 본인인증 전 동의 UI |
| 5 | 제3자 제공 동의 스텝 | 1 | 이벤트 신청 위저드에 스텝 추가 |
| 6 | 설정 > 동의 관리 | 1~3 | 동의 현황 확인/변경 UI |

---

## 참고 문서

- 법적 감사 리포트: `#747`
- 기존 이용약관: `apps/landing_user/src/app/terms/page.tsx`
- 기존 개인정보처리방침: `apps/landing_user/src/app/privacy/page.tsx`
- 디자인 시스템: `docs/ux/design-system/`
- 아키텍처: `docs/architecture/client.md`, `docs/architecture/backend.md`
