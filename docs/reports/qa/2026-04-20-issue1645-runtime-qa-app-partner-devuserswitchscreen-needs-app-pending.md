---
source_url: https://github.com/Mark-Yun/minglit/issues/1645
captured_at: 2026-04-20
issue_number: 1645
state: closed
labels: [needs-swe, report-runtime-qa]
author: Mark-Yun
title: "❓ Runtime QA 의문 — app_partner DevUserSwitchScreen에 NEEDS_APP/PENDING 상태 유저 없음"
---

# ❓ Runtime QA 의문 — app_partner DevUserSwitchScreen에 NEEDS_APP/PENDING 상태 유저 없음

> Issue #1645 · closed · created 2026-04-20T03:58:19Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1645

## Body

Scheduler: runtime-qa-smoke-partner-sonnet-subagents

## 관찰

P-S02(웰컴), P-S03(파트너 신청), P-S04(신청 상태) 테스트를 위해 DevUserSwitchScreen 진입 시 사용 가능한 계정 목록:

- partner_hotplace_0/1/2 — 모두 PARTNER 등록 완료 상태
- partner_owner_1/2 — 모두 PARTNER 등록 완료 상태
- User 계정 7개 — 파트너 앱 대상 아님

NEEDS_APP(needsApplication/draftInProgress) 또는 PENDING(pendingReview/needsCorrection) 상태의 파트너 계정이 없어서 아래 시나리오 진입 불가:

| 시나리오 | 필요 상태 | 결과 |
|----------|----------|------|
| P-S02 웰컴 | NEEDS_APP | SKIP |
| P-S03 파트너 신청 위저드 | NEEDS_APP | SKIP |
| P-S04 신청 상태 | PENDING | SKIP |

## 요청

시드 데이터 또는 DevUserSwitch 유저 목록에 아래 추가:
- `needsApplication` 상태 파트너 유저 1개 (파트너 미신청)
- `draftInProgress` 상태 파트너 유저 1개 (신청 초안)
- `pendingReview` 상태 파트너 유저 1개 (심사 중)

## 테스트 환경

- 앱: com.minglit.app_partner.dev v26.04.1639-dev
- 디바이스: Pixel 7a
- 세션: 20260420-120103

## Comments (4)

### Comment 1 — @Mark-Yun on 2026-04-20

🤖 **needs-qa-claude-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-20

## QA 분석 결과 — needs-swe로 핸드오프

### 현황 확인

`supabase/seed.dev.sql` 의 5개 partner_owner/partner_hotplace 유저는 모두 `Phase 3` 에서 `partners` 레코드와 owner permission이 생성됨 → `OnboardingState.hasPartner` 로 귀결. 신청 흐름(P-S02/03/04) 진입 가능한 유저가 0개.

`OnboardingState` 분기 (`apps/app_partner/lib/src/logic/onboarding_state_provider.dart:30-49`):
- `needsApplication`: managed partner 0개 + `partner_applications` 0건
- `draftInProgress`: `partner_applications.status = 'draft'`
- `pendingReview`: `partner_applications.status = 'pending'`
- `needsCorrection`: `partner_applications.status = 'needs_correction'`

### 구현 가이드 (seed.dev.sql)

**Phase 1.5** (Partner Owners 생성 다음에 추가) — 신규 유저 3명:

| email | username | name | 목적 상태 |
|-------|----------|------|----------|
| `partner_apply_needs@test.com` | `partner_apply_needs` | 신청 미진행 파트너 | needsApplication |
| `partner_apply_draft@test.com` | `partner_apply_draft` | 초안 작성 중 파트너 | draftInProgress |
| `partner_apply_pending@test.com` | `partner_apply_pending` | 심사 대기 파트너 | pendingReview |

`partner_apply_needs` 는 auth.users / user_profiles 만 생성 (partner_applications 없음).

**Phase 3.5** — `partner_apply_draft`, `partner_apply_pending` 에 대해 `public.partner_applications` insert. NOT NULL 컬럼 (`brand_name`, `biz_type`, `biz_name`, `biz_number`, `representative_name`, `bank_name`, `account_number`, `account_holder`, `biz_registration_path`, `bankbook_path`) 채울 것. 멱등성 위해 `WHERE NOT EXISTS (SELECT 1 FROM partner_applications WHERE user_id = ...)` 가드.

```sql
INSERT INTO public.partner_applications (
  user_id, status, brand_name, introduction, address, contact_phone, contact_email,
  biz_type, biz_name, biz_number, representative_name,
  bank_name, account_number, account_holder,
  biz_registration_path, bankbook_path
)
SELECT u.id, 'draft', '드래프트 브랜드', '...', '서울 강남구', '010-9999-0001', u.email,
  'individual', '드래프트 사업자', '999-99-99990', '드래프트 대표',
  '신한은행', '110-999-999990', '드래프트 대표',
  'seed/biz_registration.png', 'seed/bankbook.png'
FROM auth.users u
WHERE u.email = 'partner_apply_draft@test.com'
  AND NOT EXISTS (SELECT 1 FROM public.partner_applications WHERE user_id = u.id);
```

(pending 도 동일 패턴, status='pending' + biz_number/name 다르게)

### 검증
- `npx supabase db reset` 후 dev-session-switch EF 호출 → 새 3개 유저 노출 확인
- 각 유저로 로그인 → app_partner 진입 시 의도한 상태로 분기되는지 확인
- runtime-qa 시나리오 P-S02/03/04 통과

### 파일
- `supabase/seed.dev.sql` (Phase 1.5 + Phase 3.5 추가)

### 주의사항 (QA 관점)
- `pwd_hash` 변수, `meta` 변수 재사용 패턴은 기존 LOOP 그대로 따를 것
- DO $$ BEGIN ... END $$ 블록 안에서 진행 (RLS 우회용 service-role)
- 멱등성 필수 — 시드는 여러 번 실행됨

승인된 시나리오는 `docs/qa/test-cases/app-partner-smoke.md` P-S02~P-S04 참고. 구현 후 PR 본문에 `Closes #1645` 명시.

### Comment 3 — @Mark-Yun on 2026-04-20

🤖 **needs-swe-sonnet-1** 작업 시작합니다. QA 분석에 따라 seed.dev.sql에 NEEDS_APP/PENDING 상태 파트너 유저 3명 추가 구현.

### Comment 4 — @Mark-Yun on 2026-04-20

🤖 **needs-swe-sonnet-1** 구현 완료. PR #1646 생성 및 auto-merge 설정 완료.

## 변경사항
- `supabase/seed.dev.sql` Phase 1.5: partner_apply_needs/draft/pending 유저 3명 추가
- Phase 3.5: draft/pending 유저에 partner_applications 레코드 생성 (멱등 가드)

PR 머지 후 다음 seed-dev 실행 시 자동 반영됩니다.
