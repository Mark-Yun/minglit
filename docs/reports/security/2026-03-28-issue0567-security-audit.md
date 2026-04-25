---
source_url: https://github.com/Mark-Yun/minglit/issues/567
captured_at: 2026-03-28
issue_number: 567
state: closed
labels: [P2-medium, audit-report]
author: Mark-Yun
title: "🔒 보안 감사 — 2026-03-28"
---

# 🔒 보안 감사 — 2026-03-28

> Issue #567 · closed · created 2026-03-28T03:03:45Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/567

## Body

## 🔒 보안 감사 리포트 — 2026-03-28

### 발견 항목

| # | 심각도 | OWASP | 파일 | 라인 | 내용 |
|---|--------|-------|------|------|------|
| 1 | High | A01 | `supabase/functions/event-matching/index.ts` | 33-36 | **인가 누락** — `requireAuth`로 JWT 유효성만 확인하고, 호출자가 해당 이벤트의 파트너/관리자인지 role/ownership 검증 없음. 인증된 일반 유저가 임의 eventId로 매칭 트리거 가능 |
| 2 | Medium | A01 | `supabase/functions/settlement-register-transfers/index.ts` | 20-24 | **권한 수준 불일치** — 정산 이체 함수가 일반 유저 JWT 허용. `reconciliation-daily`처럼 `service_role` bearer 토큰 필요 |
| 3 | Medium | A01 | `supabase/functions/payout-sync/index.ts` | 38-43 | **권한 수준 불일치** — 지급 동기화 함수가 일반 유저 JWT 허용. `service_role` bearer 토큰 필요 |
| 4 | Medium | A01 | `supabase/migrations/20260301000005_05_schema_system.sql` | 501-504 | **RLS 정책 누락** — `processed_events`, `dead_letter_queue`, `event_routes` 테이블에 RLS 활성화되어 있으나 CREATE POLICY 없음. PostgREST API로 노출 가능 |
| 5 | Medium | A06 | `apps/landing_user/package.json`, `apps/landing_partner/package.json` | — | **의존성 취약점** — `picomatch` high-severity 취약점 (양쪽 landing 앱 동일) |
| 6 | Low | A09 | `shared/packages/minglit_kit/lib/src/data/repositories/` | 다수 | **PII 평문 로깅** — email, userId가 `Log.d/Log.i`로 기록됨. `kReleaseMode` 가드로 릴리스 빌드에선 콘솔 미출력이나, 메모리 히스토리에 잔존하여 버그 리포트 내보내기 시 노출 가능 |

### 상세 분석

#### 1. `event-matching` 인가 누락 (High)

`requireAuth`는 JWT 유효성만 확인. 함수 내부에서 호출자가 해당 이벤트의 파트너 멤버인지, 관리자 권한이 있는지 검증하지 않음. 인증된 일반 앱 유저가 임의 `event_id`로 매칭 쌍 생성을 트리거할 수 있음.

**권장 수정**: `partner_member_permissions` 테이블에서 호출자의 role을 검증하거나, `service_role` bearer 토큰만 허용.

#### 2-3. 정산 함수 권한 수준 불일치 (Medium)

`settlement-register-transfers`와 `payout-sync`는 벌크 금융 작업을 수행하지만 일반 유저 JWT를 허용. 같은 정산 도메인의 `reconciliation-daily`는 올바르게 `service_role` 키를 요구함.

**권장 수정**: `reconciliation-daily`와 동일한 `service_role` bearer 토큰 검증 패턴 적용.

#### 4. PGMQ 테이블 RLS 정책 누락 (Medium)

`processed_events`, `dead_letter_queue`, `event_routes` — RLS가 활성화되어 있으나 정책이 없어 기본적으로 모든 접근이 거부됨(PostgreSQL 기본 동작). 다만, PostgREST에 스키마가 노출되어 있으면 의도치 않은 접근 시도 가능.

**권장 수정**: `service_role` 전용 정책 추가 또는 PostgREST 스키마 노출에서 제외.

#### 5. picomatch 의존성 취약점 (Medium)

양쪽 landing 앱에서 `picomatch` high-severity 취약점 감지. 간접 의존성으로 추정.

**권장 수정**: `npm audit fix` 또는 의존성 업데이트.

#### 6. PII 평문 로깅 (Low)

`auth_repository.dart`, `staff_repository.dart`, `event_repository_commands.dart`, `partner_application_repository.dart` 등에서 email, userId를 `Log.d`/`Log.i`로 기록. 릴리스 빌드에서는 콘솔 미출력이나 메모리 히스토리에 잔존.

**권장 수정**: email → 마스킹 (`j***@gmail.com`), userId → 앞 8자리만 출력.

### 분석 항목별 결과 요약

| 항목 | 결과 |
|------|------|
| 하드코딩 시크릿 | ✅ 없음 (Firebase API 키는 클라이언트 전용으로 정상) |
| Edge Function 인증 | ⚠️ 3개 함수 권한 검증 불충분 (위 #1-3) |
| SQL Injection | ✅ 없음 |
| 민감 데이터 로깅 | ⚠️ Low — debug 모드 한정 |
| RLS 정책 | ⚠️ 3개 테이블 정책 누락 |
| CORS 설정 | ✅ 와일드카드(*) 사용 — 모바일 앱 백엔드로 정상 |
| 의존성 취약점 | ⚠️ picomatch high |
| ENVIRONMENT 가드 | ✅ 모든 dev-* 함수 정상 |

### 보안 점수

| 영역 | 점수 |
|------|------|
| 인증/인가 | 7/10 |
| 데이터 보호 | 8/10 |
| 의존성 | 7/10 |
| RLS 정책 | 8/10 |

🤖 자동 생성 — audit-security worker

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-28

🤖 TPM 분석 완료.

**결과:**
- actionable 항목: 3건 → 이슈 생성
  - #592 — event-matching 인가 누락 (P1)
  - #593 — settlement-register-transfers, payout-sync 권한 수준 불일치 (P1)
  - #594 — PGMQ 시스템 테이블 RLS 정책 누락 (P2)
- skip 항목: 2건
  - picomatch 취약점 → 실제는 `brace-expansion` moderate (high 아님), 간접 의존성, 랜딩 페이지 전용. 실질 위험 낮음
  - PII 평문 로깅 → false positive. grep 검증 결과 해당 패턴 없음

원본 리포트를 닫습니다.
