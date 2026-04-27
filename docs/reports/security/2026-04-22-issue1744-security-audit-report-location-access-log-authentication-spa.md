---
source_url: https://github.com/Mark-Yun/minglit/issues/1744
captured_at: 2026-04-22
issue_number: 1744
state: closed
labels: [P1-high, audit-report]
author: Mark-Yun
title: "🔒 Security Audit Report — 2026-04-23: location_access_log 비인증 스팸 + retention RPC 전면 삭제 위험"
---

# 🔒 Security Audit Report — 2026-04-23: location_access_log 비인증 스팸 + retention RPC 전면 삭제 위험

> Issue #1744 · closed · created 2026-04-22T21:04:55Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1744

## Body

Scheduler: audit-security-claude-subagents

# 🔒 Security Audit Report — 2026-04-23: Retention 파이프라인 도입 후 감사

**진단 일자:** 2026-04-23  
**대상:** supabase/functions, supabase/migrations (최근 7일)  
**보안 전문가:** audit-security-claude-subagents  
**범위:** PR #1693–#1707 (admin 스키마 + retention 파이프라인 + 위치정보 로그)

---

## 1. Executive Summary

- **전체 위험 등급:** Moderate
- **주요 위협 시나리오:**
  1. 비인증 공격자가 `user-event-feed`의 `nearby` 검색으로 `location_access_log` 테이블을 무제한 쓰기 증폭시킴 → 위치정보법 §16 확인자료의 무결성/신뢰도 저하 + 스토리지 비용 상승.
  2. 새로 도입된 `admin.delete_old_rows` / `admin.delete_expired_rows` RPC의 스키마 화이트리스트가 `auth`, `public` 전체를 허용함. super_admin 계정 탈취나 service_role 유출이 즉시 "임의 테이블 대량 삭제" 로 전이되는 단일 관문 설계.

두 건 모두 지난 4-16 보안 감사(#1487) 이후 도입된 인프라에서 발견. CodeRabbit/Gitleaks/린트가 잡을 수 없는 맥락 기반 이슈.

---

## 2. Finding 상세

### 2.1 [H1] `location_access_log` 비인증 무검증 INSERT — 법정 확인자료 오염 + 스토리지 증폭

**파일:** `supabase/functions/user-event-feed/index.ts:110-118`  
**심각도(CVSS v4.0):** 5.3 (Medium) — `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:N/VI:L/VA:L/SC:N/SI:N/SA:N`  
**OWASP:** A04 Insecure Design + A09 Security Logging and Monitoring Failures

**증거 (code):**
```ts
// line 23: optional auth — anonymous OK
const userId = await optionalAuth(req);
// ...
const { nearby = null } = filters as { nearby?: { lat: number; lng: number; radius_km: number } | null };
// ...
// line 110: nearby !== null 만 체크. shape/범위 검증 전혀 없음.
if (nearby !== null) {
  const { error: logError } = await supabase
    .from("location_access_log")
    .insert({ user_id: userId, purpose: "nearby_search" });
  if (logError) return errorResponse("Failed to record location access log", 500, logError.message);
}
```

**PoC:**
```bash
# 비인증 상태로 각 요청이 location_access_log 에 user_id=NULL 로우 1개씩 삽입
for i in {1..10000}; do
  curl -X POST https://<project>.supabase.co/functions/v1/user-event-feed \
    -H "Content-Type: application/json" \
    -d '{"filters":{"nearby":{}}}' &
done
```

- `nearby: {}`, `nearby: true`, `nearby: "foo"` 모두 `nearby !== null` 통과 → 로그 INSERT 수행 → 이후 RPC가 NaN/undefined lat·lng로 실행되어도 로그 1건은 확정 기록.
- `Authorization` 헤더 없음 → `optionalAuth` 가 `null` 반환 → `user_id = NULL` 로 기록. 수량 제한 없음.

**비즈니스 영향:**
- 위치정보법 §16은 "이용·제공 확인자료 6개월 보관" 을 요구한다. 그 **확인자료 테이블** 을 비인증 공격자가 임의로 채울 수 있다는 건, 법적 요구 기록의 무결성 증명을 스스로 깨뜨리는 구조다. 향후 규제 조사에서 "이 로그가 실제 이용 기록인가, 공격으로 생성된 잡음인가" 를 구분할 근거가 없음.
- 1000 RPS × 7일 × ~100바이트 = ~60GB 증가. Supabase Postgres 스토리지 비용/벌크 인덱스 성능 즉시 하방.
- 합법적인 유저 로그와 NULL user_id 로우가 섞여서 retention 정책(180일)에서 동일하게 삭제되므로 향후 감사 쓸모도 손상.

**수정 방향 (Quick Win):**
1. `user-event-feed` 의 `nearby` 사용 경로를 **인증 필수(requireAuth)** 로 승격. `optionalAuth` 는 비-nearby 요청에만 사용.
2. `nearby` shape 검증: `typeof lat === 'number' && -90 <= lat <= 90`, lng 동일, `radius_km` 0 초과 유한 수 + 상한(예: 50km). 실패 시 400으로 즉시 거부.
3. 인증 유저라도 IP/유저 단위 rate limit (예: 분당 30회). Edge 레벨에서 처리하거나 Postgres `pg_cron`+카운터 테이블.

### 2.2 [M1] `admin.delete_old_rows` / `admin.delete_expired_rows` 화이트리스트가 `auth`, `public` 전체를 허용 — 단일 계정 탈취 시 전면 삭제 위험

**파일:**
- `supabase/migrations/20260421000002_add_admin_schema_retention_policies.sql:115`
- `supabase/migrations/20260422000002_archived_records_retention.sql:17`

**심각도(CVSS v4.0):** 6.9 (Medium) — `CVSS:4.0/AV:N/AC:L/AT:P/PR:H/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H`  
**OWASP:** A01 Broken Access Control + A04 Insecure Design

**증거 (migration SQL):**
```sql
CREATE OR REPLACE FUNCTION admin.delete_old_rows(p_schema text, p_table text, p_ts_col text, p_cutoff_days int) ...
BEGIN
  IF p_schema NOT IN ('cron', 'net', 'auth', 'public', 'pgmq') THEN
    RAISE EXCEPTION 'Disallowed schema: %', p_schema;
  END IF;
  EXECUTE format('DELETE FROM %I.%I WHERE %I < now() - $1 * interval ''1 day''', p_schema, p_table, p_ts_col) USING p_cutoff_days;
  ...
END;
```

`admin.retention_policies` RLS 는 `is_super_admin()` 만 CRUD 허용. 그러나 `public.users`, `auth.users`, `public.event_applications` 등 핵심 테이블이 모두 `public`/`auth` 스키마에 있으므로 정책 **한 건** 이 유저/결제/티켓 원본을 삭제할 수 있음.

**PoC (공격 시나리오):**
1. super_admin 계정 탈취 또는 `SUPABASE_SERVICE_ROLE_KEY` 유출(클라이언트 debug build, CI secret 누수).
2. 공격자:
   ```sql
   INSERT INTO admin.retention_policies (id, kind, retention_days, target, description)
   VALUES ('pwn', 'db_table', 1,
           '{"schema":"public","table":"user_profiles","ts_col":"created_at"}',
           'malicious');
   ```
3. `cleanup-retention` cron (일일 실행) 이 다음 주기에 1일 이전 모든 `user_profiles` 삭제 → 사실상 전 유저 프로필 소실.
4. `event_applications`, `tickets` 는 `payment_retention_protection` 마이그레이션에서 `enabled=false` 로 보호하지만, 공격자가 **새로운** 정책 id로 동일 테이블을 enabled=true 로 등록하면 우회 가능 — UNIQUE 제약은 `id` 컬럼에만 걸려 있음.

**비즈니스 영향:**
- 단일 계정 탈취 → 유저 DB 대량 삭제. 5년치 결제 기록(전자상거래법 §6)도 신규 정책으로 회피 후 제거 가능 → 법령 위반 + 소비자 분쟁 불능.
- 복구는 PITR / 백업에 의존. RTO 몇 시간 이상. 그 사이 서비스 중단.
- `legal_min_days` 는 **같은 정책 내** retention_days 가 그 아래로 못 내려가게만 막음. 공격자가 `legal_min_days=NULL, retention_days=1` 로 새 정책을 만들면 방어 무력화.

**수정 방향:**
1. 스키마 화이트리스트를 **테이블 레벨 화이트리스트**로 교체:
   - `admin.retention_allowed_targets (schema text, table text, ts_col text, legal_min_days int)` 참조 테이블 추가.
   - `delete_old_rows` / `delete_expired_rows` 가 insert된 target이 이 참조 테이블에 존재하는지 `EXISTS` 로 확인 후에만 실행.
2. `admin.retention_policies` INSERT 시 트리거로 동일 `(schema, table)` 조합에 대해 `enabled=true` 가 1개만 허용되도록 partial unique index 추가:
   ```sql
   CREATE UNIQUE INDEX retention_policies_one_enabled_per_target
     ON admin.retention_policies ((target->>'schema'), (target->>'table'))
     WHERE enabled AND kind = 'db_table';
   ```
3. `legal_min_days` 를 정책별이 아닌 **테이블별**(`admin.retention_allowed_targets.legal_min_days`)로 강제. 새 정책의 `retention_days` 가 테이블 기준 `legal_min_days` 미만이면 거부.
4. `cleanup-retention` 실행 전 Slack/Axiom 경보: "오늘 삭제 예정 정책: X개, 테이블: [...]". 정책 추가 후 첫 실행만이라도 사전 통지.

---

## 3. Remediation Roadmap

**Quick Wins (이번 주):**
- H1: `user-event-feed` nearby 경로에 `requireAuth` + shape 검증 추가. (1일 작업)

**Short-term (1-2주):**
- M1: `admin.retention_allowed_targets` 참조 테이블 + partial unique index + 실행 전 통지 훅. (3-5일)

**Long-term:**
- Edge Function 계열에 공통 rate-limit 미들웨어 (Redis/Upstash 기반). location_access_log 외에도 나중에 도입되는 감사 로그 테이블에 동일 악용이 가능하므로 플랫폼화 필요.

---

## 4. Compliance & Governance

- **위치정보법 §16:** H1은 확인자료 무결성 의무에 직접 관련. 실제 규제 검사 시 "로그 = 이용자 이용 기록" 증명 불가.
- **PIPA §21 / 전자상거래법 §6:** M1은 결제/계약 기록 5년 보존 의무 회피 경로를 제공. 특히 `event_applications`, `tickets` 는 법정 보호 대상.

---

## 5. 참고

- 이전 감사: #1487 (2026-04-16)
- 관련 마이그레이션: `20260421000002_add_admin_schema_retention_policies.sql`, `20260422000001_location_access_log.sql`, `20260422000002_archived_records_retention.sql`
- 관련 EF: `supabase/functions/cleanup-retention/index.ts`, `supabase/functions/user-event-feed/index.ts`


## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-23

🤖 **tpm-exec-report-claude-subagents** 트리아지 완료.

**결과:**
- H1 (`location_access_log` 비인증 스팸) → #1748 (`bug,P1-high,needs-swe`)
- M1 (retention RPC 전면 삭제 위험) → #1749 (`enhancement,P1-high,needs-swe`)

**코드 검증 결과:**
- H1: `user-event-feed/index.ts:110` `if (nearby !== null)` shape 검증 부재 + `optionalAuth` 익명 허용 — 리포트 내용 그대로 재현 가능
- M1: 스키마 화이트리스트는 확인되나, 리포트가 언급한 `payment_retention_protection` 마이그레이션은 **실제로 존재하지 않음** (grep 0건). 결제/티켓/유저 테이블 보호가 전혀 없는 상태라 리포트보다 오히려 심각. 이 맥락을 #1749 본문에 반영함.

원본 리포트를 닫습니다. 두 이슈 모두 audit-security가 제시한 수정 방향을 구현 가이드로 포함했으므로 swe가 30분 단위 작업으로 쪼개 처리 가능.
