---
source_url: https://github.com/Mark-Yun/minglit/issues/2052
captured_at: 2026-04-30
issue_number: 2052
state: open
labels: [audit-report, P1-high]
author: Mark-Yun
title: "🔒 Security Audit Report — 2026-04-30: save_user_consents 가 user-controlled timestamp/policy_version 신뢰 — §50 ⑧ 갱신 cron 회피 + PIPA §22 증빙 무결성"
---

# 🔒 Security Audit Report — 2026-04-30: save_user_consents 가 user-controlled timestamp/policy_version 신뢰 — §50 ⑧ 갱신 cron 회피 + PIPA §22 증빙 무결성

> Issue #2052 · open · created 2026-04-30 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2052

## Body

Scheduler: audit-security-claude-subagents

# 🔒 Security Audit Report — 2026-04-30: `save_user_consents` RPC가 user-controlled 타임스탬프/policy_version을 신뢰 → §50 ⑧ 갱신 cron 회피 + PIPA §22 동의 증빙 무결성 훼손

**진단 일자:** 2026-04-30
**대상:** `supabase/migrations/20260330000004_user_consents.sql`, `supabase/migrations/20260429000003_marketing_consent_renewal_fn.sql`, `shared/packages/minglit_kit/lib/src/data/repositories/consent_repository.dart`
**보안 전문가:** audit-security-claude-subagents
**범위:** PR #2041(#2044) 마케팅 동의 2년 재확인 cron 도입 직후, 동의 저장 RPC와 갱신 cron의 데이터 흐름 재검증

---

## 1. Executive Summary

- **전체 위험 등급:** Moderate (Integrity-focused)
- **주요 위협 시나리오:** 정상 인증된 유저가 자신의 `marketing_consent` 레코드의 `consented_at`/`withdrawn_at`/`policy_version` 값을 임의 시점/임의 버전으로 위조해 (a) 정보통신망법 §50 ⑧ 2년 재확인 cron의 알림·자동철회 로직을 영구 회피하거나, (b) "나는 N년 전에 철회했다 / 신버전 약관에 동의한 적 없다" 라는 위조된 증빙으로 분쟁/규제 조사 시 회사 측 동의 기록 무결성을 깨뜨림.

지난 4-23 감사(#1744) 이후 신규 도입된 `admin.process_marketing_consent_renewals` 갱신 cron은 `consented_at` 컬럼을 만료 판정의 단일 기준으로 사용한다. 그러나 이 컬럼을 채우는 **authenticated client write entrypoint**인 `public.save_user_consents` 가 **클라이언트 페이로드의 timestamptz 값을 그대로 받아쓴다**. (`public.upsert_user_settings_with_consent` 도 동일 컬럼에 `consented_at` 을 기록하지만 `v_now := now()` 서버 고정 + service_role 전용 — 인증 유저가 직접 호출 가능한 경로는 `save_user_consents` 가 유일.) CodeRabbit/Gitleaks/lint 가 절대 잡을 수 없는 "RPC 입력값 신뢰 모델" 의 비즈니스 맥락 결함.

---

## 2. Finding 상세

### 2.1 [H1] `save_user_consents` 가 client-supplied `consented_at` / `withdrawn_at` / `policy_version` 을 그대로 신뢰 — 동의 증빙 위·변조 + §50 갱신 cron 영구 회피

**파일:**
- `supabase/migrations/20260330000004_user_consents.sql:59-121` (`save_user_consents` RPC)
- `supabase/migrations/20260429000003_marketing_consent_renewal_fn.sql:41-70` (cron 만료 기준이 `consented_at`)
- `shared/packages/minglit_kit/lib/src/data/repositories/consent_repository.dart:41-47` (정상 클라이언트 호출 경로)
- `shared/packages/minglit_kit/lib/src/data/models/user_consent.dart:65-78` (`ConsentInput` 정상 페이로드 — `consented_at`/`withdrawn_at` 미포함)

**심각도(CVSS v4.0):** 6.0 (Medium) — `CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:N/VI:H/VA:N/SC:N/SI:L/SA:N`
**OWASP:** A04 Insecure Design + A08 Software and Data Integrity Failures

**증거 (RPC 본문):**
```sql
-- supabase/migrations/20260330000004_user_consents.sql:83-119
INSERT INTO public.user_consents (
  user_id, consent_key, consented, policy_version,
  consented_at,        -- ← entry.consented_at 그대로
  withdrawn_at         -- ← entry.withdrawn_at 그대로
)
SELECT
  p_user_id,
  entry.consent_key,
  entry.consented,
  entry.policy_version,
  COALESCE(entry.consented_at, now()),
  CASE WHEN entry.consented THEN NULL
       ELSE COALESCE(entry.withdrawn_at, now()) END
FROM jsonb_to_recordset(p_consents) AS entry(
  consent_key text,
  consented boolean,
  policy_version integer,
  consented_at timestamptz,    -- ← jsonb_to_recordset 가 클라 키를 그대로 매핑
  withdrawn_at timestamptz
)
ON CONFLICT (user_id, consent_key) DO UPDATE
SET
  consented      = EXCLUDED.consented,
  policy_version = COALESCE(EXCLUDED.policy_version, public.user_consents.policy_version),
  consented_at   = CASE WHEN EXCLUDED.consented
                        THEN EXCLUDED.consented_at      -- 재동의 시 user 값 그대로
                        ELSE public.user_consents.consented_at END,
  withdrawn_at   = CASE WHEN EXCLUDED.consented THEN NULL
                        ELSE COALESCE(EXCLUDED.withdrawn_at, now()) END;  -- 철회 시 user 값
```

`auth.uid() = p_user_id` 동일성 검증은 있지만(line 75–77) **자기 자신의 레코드에 한해 임의 시점·임의 버전 값을 박아 넣을 수 있음**. Flutter 정상 클라(`ConsentInput`)는 `consent_key/consented/policy_version` 3개만 보내지만, RPC 자체는 REST `/rest/v1/rpc/save_user_consents` 로 그대로 노출되어 임의 키 추가가 가능.

대조: 같은 날 추가된 `public.upsert_user_settings_with_consent` (`20260429000005_upsert_user_settings_atomic.sql:16,42,48`) 는 `v_now := now()` 를 서버에서 픽스해서 `consented_at` 을 채우고 service_role 만 호출 가능 — 안전 패턴은 이미 존재함. 비대칭이 그대로 남아 있음.

**PoC — §50 ⑧ 갱신 cron 영구 회피:**
```bash
# 정상 로그인된 본인 JWT 사용. anon key 와 함께.
curl -s -X POST "https://<project>.supabase.co/rest/v1/rpc/save_user_consents" \
  -H "apikey: <SUPABASE_ANON_KEY>" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{
    "p_user_id": "<자기 user_id>",
    "p_consents": [{
      "consent_key": "marketing_consent",
      "consented": true,
      "policy_version": 1,
      "consented_at": "2099-01-01T00:00:00Z"
    }]
  }'
```
이후 `admin.process_marketing_consent_renewals(730)` 의 만료 판정 `uc.consented_at < now() - 730 * INTERVAL '1 day'` 가 73년간 false → **이 유저는 영구히 갱신 안내·자동 철회 대상에서 제외**. 정보통신망법 §50 ⑧ "2년마다 동의 사실을 확인" 의무를 회사가 자동으로 위반하는 상태가 되며, 한국인터넷진흥원(KISA) 점검 시 회사 책임.

**PoC — 동의 증빙 위조 (분쟁/규제 대비):**
```bash
# 시나리오: 유저가 향후 "나는 2020년에 마케팅 동의를 철회했는데도 푸시를 받았다" 주장
curl -s -X POST "https://<project>.supabase.co/rest/v1/rpc/save_user_consents" \
  -H "apikey: <ANON_KEY>" -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{
    "p_user_id": "<자기 user_id>",
    "p_consents": [{
      "consent_key": "marketing_consent",
      "consented": false,
      "withdrawn_at": "2020-01-01T00:00:00Z"
    }]
  }'
```
`user_consents` 에 `withdrawn_at = 2020-01-01` 로 기록됨. CHECK 제약 `(consented=false AND withdrawn_at IS NOT NULL)` 통과. 회사가 그 사이 보낸 마케팅 푸시 로그(`user_notifications.category='marketing'`)와 결합하면 **회사 측 자체 DB 가 §50 위반 증거** 가 됨. 분쟁조정/소송 시 반박 불능.

**PoC — `policy_version` 임의 다운그레이드:**
```bash
# 신규 v3 약관에 동의한 유저가 본인 레코드를 v1 로 되돌림
-d '{
  "p_user_id": "<self>",
  "p_consents": [{
    "consent_key": "privacy_collection",
    "consented": true,
    "policy_version": 1
  }]
}'
```
ON CONFLICT 로직: `policy_version = COALESCE(EXCLUDED.policy_version, public.user_consents.policy_version)` 가 그대로 1로 덮어씀. 회사가 "이 유저는 v3 약관에 동의했다" 고 주장해도 **DB 가 v1 만 가리킴** → PIPA §22 "동의받은 사항을 명확히 입증" 의무 미충족.

**비즈니스 영향:**
- **§50 ⑧ 의무 위반 자동화:** 본 finding 의 PoC 페이로드를 자동화하면 "마케팅 푸시는 받고 싶지만 2년 갱신은 귀찮아서 안 하고 싶은" 유저 한 명이 회피하는 데서 끝나지 않음. 예컨대 가입 시 "마케팅 ON" 을 자동 토글하는 잘못된 클라 빌드 한 번이 미래 시점 `consented_at` 을 박아 두면, 마이그레이션·롤백 비용이 크다.
- **PIPA §22 ② 동의 증빙 무결성:** 개인정보 수집·이용 동의는 "수집·이용 목적, 수집 항목, 보유·이용 기간 및 동의 거부권" 을 동의받은 시점에 명확히 입증해야 함. `consented_at` 이 클라이언트가 제공한 값이라는 것은 입증 자료의 신뢰성 자체를 흔든다.
- **분쟁 시 입증 책임 역전:** 한국 개인정보보호위 분쟁조정 절차에서 "동의 시점/철회 시점" 입증 책임은 사업자에게 있다. 자기 DB 의 timestamp 가 user-controlled 라는 사실이 외부에 알려지면, 회사가 제출하는 모든 동의 증빙의 증거능력이 취약해진다.

**오용 가능성 평가:** 인증 유저만 호출 가능하고 본인 레코드만 수정 가능하므로 "타인 데이터 조작" 은 불가. 그러나 본 finding 의 핵심은 **회사 측 레코드의 무결성** 이며, 이는 회사가 그 레코드를 법적 증빙으로 사용하기 때문에 발생. 즉, 단일 유저의 자해적 위조 한 건으로도 그 유저에 대한 회사의 §50/PIPA 입증력이 깨진다.

**수정 방향 (Quick Win, ~1일):**
1. `save_user_consents` 의 `jsonb_to_recordset` 스키마에서 `consented_at`/`withdrawn_at` 컬럼 제거. INSERT/UPDATE 시 항상 `now()` 사용:
   ```sql
   FROM jsonb_to_recordset(p_consents) AS entry(
     consent_key text,
     consented boolean,
     policy_version integer
   )
   -- consented_at = now()
   -- withdrawn_at = CASE WHEN entry.consented THEN NULL ELSE now() END
   ```
2. `policy_version` 검증: `policies` 테이블의 현재 active version 과 비교해 다운그레이드 거부, 또는 항상 서버측 `(SELECT max(version) FROM public.policies WHERE key = entry.consent_key)` 로 결정.
3. 회귀 방지 pgTAP 테스트 추가 (`56_user_consents_test.sql`):
   - 클라이언트가 `consented_at: '2099-01-01'` 을 보내도 DB 에는 `now()` 만 기록되는지
   - 클라이언트가 더 낮은 `policy_version` 을 보내도 다운그레이드되지 않는지

**중기 (Short-term, 1–2주):**
- `user_consents` 에 `client_reported_consented_at timestamptz NULL` 컬럼 추가(감사 목적). 클라이언트가 보낸 시점은 별도 컬럼에 보관하고, 법적 증빙은 서버 timestamp 사용. retention/cron 모두 서버 컬럼 기준.
- `policies.is_current` 또는 `effective_until` 도입. `policy_version` 입력 검증 시 "현재 active 버전만 허용" 정책 강제.

**장기 (Long-term):**
- SECURITY DEFINER 패턴 전반 점검: `auth.uid() = p_user_id` 로 "본인" 만 검증하는 RPC들을 listing 후, 본인 외 컬럼(특히 timestamptz·version·money 컬럼) 도 입력 신뢰 모델 검토. 같은 패턴이 다른 RPC 에 더 있을 가능성 높음.

---

## 3. Remediation Roadmap

| 항목 | 기간 | 우선순위 |
|------|------|----------|
| H1 Quick Win 1·3 (서버 timestamp 강제 + pgTAP 회귀 테스트) | 1일 | **P1** |
| H1 Quick Win 2 (`policy_version` 다운그레이드 방지) | 0.5일 | P1 |
| Short-term (`client_reported_consented_at` 분리, `policies.is_current`) | 3–5일 | P2 |
| SECURITY DEFINER 입력 신뢰 모델 전수조사 | 1–2주 | P2 |

---

## 4. Compliance & Governance

- **정보통신망법 §50 ⑧ + 시행령 §62의3:** "수신 동의 후 매 2년마다 동의 사실 재확인" 의무. cron 의 만료 기준이 user-controlled timestamp 인 한, 이 의무 이행 자체를 회사가 자기 DB 로 보장 못 함. KISA 점검 시 핵심 지적 사항.
- **PIPA §22 ② / §29:** 개인정보 수집·이용 동의의 입증 책임은 사업자. 동의 시점·철회 시점·동의 약관 버전이 모두 클라이언트에서 결정될 수 있다는 사실은 입증력 약화의 직접 원인.
- **거버넌스 권고:** SECURITY DEFINER 함수 신규 추가 시 "user-controlled 컬럼 목록" 을 PR 본문에 명시하는 체크리스트 도입. 코드리뷰어가 `auth.uid()` 검증 + 입력 신뢰 모델을 함께 검토하도록 표준화.

---

## 5. 참고

- 이전 감사: #1744 (2026-04-23), #1487 (2026-04-16)
- 관련 PR: #877 (`save_user_consents` 도입), #2044 (#2041) 갱신 cron 도입
- 안전 패턴 참조: `supabase/migrations/20260429000005_upsert_user_settings_atomic.sql` — `v_now := now()` 서버 픽스, service_role only
- 표준 문서: `docs/standards/postgres-18-rls.md` (확인 필요), `docs/templates/vulnerability.md`
