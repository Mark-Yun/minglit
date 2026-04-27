---
source_url: https://github.com/Mark-Yun/minglit/issues/1487
captured_at: 2026-04-15
issue_number: 1487
state: closed
labels: [P1-high, audit-report]
author: Mark-Yun
title: "🔒 Security Audit Report — 2026-04-16: AI EF 인가 결함, 결제 소유권 검증 누락, 정산 인가 우회, QR 서명 미검증"
---

# 🔒 Security Audit Report — 2026-04-16: AI EF 인가 결함, 결제 소유권 검증 누락, 정산 인가 우회, QR 서명 미검증

> Issue #1487 · closed · created 2026-04-15T21:08:55Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1487

## Body

Scheduler: audit-security-claude-subagents

# [Security] 심층 취약점 진단 보고서 — 2026-04-16

**진단 일자:** 2026-04-16 | **대상:** Minglit 백엔드 (Edge Functions + RLS)
**보안 전문가:** audit-security-claude-subagents
**범위:** 최근 2주 변경사항 중심 (PR #1226~#1468) — AI EF, 결제, QR 토큰, Axiom 로깅, RLS 정책

---

## 1. 경영진 요약

**전체 위험 등급: High**

4건의 P1 취약점이 발견되었다. 핵심 위협은 **인가(authorization) 결함**이다:
- AI 워커 EF가 anon JWT로 호출 가능 → OpenAI API 비용 무제한 증폭
- 결제 확인 API에서 소유권 검증 누락 → 타인 결제 승인 가능
- 정산 전송 API에서 파트너 소속 검증 누락 → 임의 파트너 정산 트리거 가능
- QR 체크인에서 서버 측 서명 검증 없음 → 클라이언트 우회로 서명 없이 체크인 가능

**주요 위협 시나리오:** 인증된 일반 유저가 `payment-verify`를 호출하여 타인의 주문을 결제 완료 처리하거나, `settlement-transfer`를 호출하여 임의 파트너의 정산을 트리거할 수 있다.

---

## 2. 상세 기술 진단

### 🔴 P1-1: AI Edge Functions — anon JWT 호출 허용 + batch_size 무제한

| 항목 | 내용 |
|------|------|
| **위치** | `supabase/functions/ai-embed/index.ts`, `supabase/functions/ai-extract-tags/index.ts` |
| **심각도** | P1 (High) |
| **OWASP** | A01:2021 — Broken Access Control |

**취약점:** 두 AI 워커 EF 모두 `verify_jwt = true`만 설정. Supabase anon key(앱에 공개 배포)로 생성한 JWT면 누구나 호출 가능. 핸들러 내부에 `requireAuth`나 `requireServiceRole` 없음.

**공격 시나리오:**
```bash
# 공격자: anon key로 JWT 생성 → ai-embed 직접 호출
curl -X POST https://<project>.supabase.co/functions/v1/ai-embed \
  -H "Authorization: Bearer <anon_jwt>" \
  -d '{"batch_size": 10000}'
```
→ `batch_size`에 서버 측 상한 없음. 10,000건 일괄 OpenAI API 호출 → 비용 폭증.

**비교:** `settlement-transfer`, `payment-verify` 등 시스템 전용 EF는 `requireServiceRole`을 사용.

**수정 방향:** 두 함수 모두 `requireServiceRole(req)` 추가. cron에서 service_role key로 호출하도록 변경.

---

### 🔴 P1-2: payment-verify — 소유권 검증 누락

| 항목 | 내용 |
|------|------|
| **위치** | `supabase/functions/payment-verify/index.ts:44-51` |
| **심각도** | P1 (High) |
| **OWASP** | A01:2021 — Broken Access Control (IDOR) |

**취약점:** `requireAuth`로 인증은 확인하지만, DB 조회 시 `user_id` 필터가 없음. 인증된 유저가 타인의 `merchant_uid`를 알면 타인의 결제를 확인(approved) 처리 가능.

**공격 시나리오:**
```
POST /functions/v1/payment-verify
Authorization: Bearer <attacker_jwt>
Body: { "imp_uid": "<real_portone_uid>", "merchant_uid": "<victim_app_id>" }
```
→ 피해자의 event_application이 `approved`로 변경됨.

**비교:** `payment-cancel/index.ts:53`은 `application.user_id !== auth` 검사가 있음.

**수정 방향:** `.select("payment_amount, status, user_id")` + `if (order.user_id !== auth) return errorResponse("Forbidden", 403)` 추가.

---

### 🔴 P1-3: settlement-transfer — 인증 유저가 임의 파트너 정산 트리거 가능

| 항목 | 내용 |
|------|------|
| **위치** | `supabase/functions/settlement-transfer/index.ts:21` |
| **심각도** | P1 (High) |
| **OWASP** | A01:2021 — Broken Access Control |

**취약점:** `requireAuth(req)`만 사용. 파트너 멤버십이나 service_role 검증 없음. 인증된 일반 유저가 `partner_id`를 알면 포트원 정산 전송 API를 트리거할 수 있음.

**비교:** 동일 도메인의 `payout-sync`, `reconciliation-daily`, `settlement-register-transfers`는 모두 `requireServiceRole` 사용.

**수정 방향:** `requireServiceRole(req)`로 변경 (cron/시스템 전용 함수이므로).

---

### 🔴 P1-4: event-checkin — 서버 측 QR 서명 검증 없음

| 항목 | 내용 |
|------|------|
| **위치** | `supabase/functions/event-checkin/index.ts:37-55` |
| **심각도** | P1 (High) |
| **OWASP** | A07:2021 — Identification and Authentication Failures |

**취약점:** QR 토큰은 Ed25519로 서명되지만, `event-checkin` EF는 `(event_id, participant_id)`만 받고 서명/만료를 검증하지 않음. 서명 검증이 전적으로 클라이언트(파트너 앱)에 위임됨.

**완화 요소:** `participant.user_id === auth` 검사가 있어 타인 체크인은 불가. 그러나 파트너 앱 조작으로 서명 없이 본인 체크인 가능.

**추가 문제:** 토큰 TTL 7일 — 대부분 이벤트 대비 과도하게 김 (`user-get-ticket-token/index.ts:84`).

**수정 방향:** `event-checkin`에 `signature` + `expires_at` 파라미터 추가 → 서버에서 `get_ticket_public_key()` RPC로 Ed25519 검증.

---

### 🟠 P2-1: apply-event — check_party_balance 유료 재신청 경로 누락

| 항목 | 내용 |
|------|------|
| **위치** | `supabase/functions/apply-event/index.ts:117-206` |
| **심각도** | P2 |

Fix #1345에서 무료 재신청 경로(line 212)에만 `check_party_balance` 추가. 유료 재신청(line 121-133) 및 유료 신규(line 139-162) 경로는 성별 균형 검증을 건너뜀.

---

### 🟠 P2-2: notification-worker — 인가 가드 없음

| 항목 | 내용 |
|------|------|
| **위치** | `supabase/functions/notification-worker/index.ts:243` |
| **심각도** | P2 |

핸들러에 `requireAuth`/`requireServiceRole` 없음. anon key로 호출 가능. FCM 푸시 알림 발송 트리거 가능.

**수정 방향:** `requireServiceRole(req)` 추가.

---

### 🟠 P2-3: identity-verify — DB 에러에 PII 포함 가능한 raw 객체 로깅

| 항목 | 내용 |
|------|------|
| **위치** | `supabase/functions/identity-verify/index.ts:73` |
| **심각도** | P2 |

`metadata: { detail: updateError }` — `PostgrestError` 객체를 raw로 Axiom에 전송. PostgreSQL 에러 메시지에 `p_name`, `p_phone_number` 값이 포함되면 PII가 평문으로 Axiom에 기록됨. 동일 파일 line 43에서는 `maskJsonString`으로 마스킹하는 패턴이 있으나 이 경로는 누락.

---

### 🟠 P2-4: AI EF — 에러 응답에 환경변수명 노출 + PII 스크러빙 없이 OpenAI 전송

| 항목 | 내용 |
|------|------|
| **위치** | `ai-embed/index.ts:192-198`, `ai-extract-tags/index.ts:228-233`, `_shared/ai/factory.ts:11`, `ai-embed/party_serializer.ts:25` |
| **심각도** | P2 |

1. 에러 응답에 `OPENAI_API_KEY is not set`, `SUPABASE_SERVICE_ROLE_KEY` 등 환경변수명 노출
2. `party_serializer.ts`에서 `location.address`를 스크러빙 없이 OpenAI API에 전송. `pii_masker.ts`는 Axiom 로깅 경로에만 적용

---

### 🟠 P2-5: user_notifications INSERT 정책 — `with check (true)` 미스코프

| 항목 | 내용 |
|------|------|
| **위치** | `supabase/migrations/**/07_rls_grants.sql:241` |
| **심각도** | P2 |

`user_notifications` INSERT 정책이 `with check (true)`로 `authenticated` 전체에 열려 있음. 타인의 알림을 삽입할 수 있는 가능성.

---

### 🟡 P3: 추가 발견 사항

| # | 항목 | 위치 | 설명 |
|---|------|------|------|
| 1 | `payment-webhook` IP whitelist만 사용 | `payment-webhook/index.ts:32-35` | `x-forwarded-for` 스푸핑 가능. PortOne V1 한계로 HMAC 불가. 추적 이슈 필요 |
| 2 | `payment-webhook` 멱등성 가드 없음 | `payment-webhook/index.ts:64-148` | PortOne 재시도 시 `pgmq_send` 중복 → 중복 푸시 알림 |
| 3 | `dev-mock-portone` 환경 게이트 단일 의존 | `iamport_client.ts:24-25` | `ENVIRONMENT` env var에만 의존. `IamportClient` 내부에 2차 게이트 없음 |
| 4 | `OPENAI_API_KEY` env-manifest.json 미등록 | `env-manifest.json` | 조기 부트 검증 우회 |
| 5 | QR 토큰 TTL 7일 과도 | `user-get-ticket-token/index.ts:84` | 이벤트 종료 또는 24h 중 짧은 쪽으로 제한 권장 |
| 6 | `user_embeddings`/`user_actions`/`party_embeddings` RLS 정책 0건 | 스키마 정의 | 암묵적 deny (의도적일 수 있음) — 명시적 service_role 정책 권장 |

---

## 3. 단계적 조치 로드맵

### Quick Wins (즉시 조치 — 1~2줄 수정)
1. `ai-embed`, `ai-extract-tags` → `requireServiceRole(req)` 추가
2. `settlement-transfer` → `requireServiceRole(req)` 변경
3. `notification-worker` → `requireServiceRole(req)` 추가
4. `payment-verify` → `user_id` 소유권 검증 추가
5. `ai-embed`, `ai-extract-tags` → `batch_size` 상한 추가 (`Math.min(batchSize, 50)`)

### Short-term (1~2주)
6. `event-checkin` → 서버 측 Ed25519 서명 검증 추가
7. `apply-event` → 유료 경로에 `check_party_balance` 추가
8. `identity-verify:73` → `updateError` 마스킹 적용
9. AI EF 에러 응답 → 제네릭 메시지로 교체
10. `party_serializer.ts` → `location.address` 스크러빙

### Long-term (전략 과제)
11. PortOne V2 HMAC 웹훅 서명 검증 도입
12. `dev-mock-portone` 2차 환경 게이트 추가
13. AI EF에 rate limiting / invocation frequency guard 도입

---

## 4. 컴플라이언스

- **개인정보보호법:** P2-3 (identity-verify PII 로깅), P2-4 (OpenAI에 주소 전송)는 개인정보 제3자 제공 동의 없이 외부 API에 위치 정보를 전송하는 경로. 개인정보처리방침의 "AI 관련 제3자 제공" 항목과 일치하는지 법률 검토 필요.
- **위치정보법:** 최근 위치정보 이용약관(#1452)이 추가되었으나, AI EF에서 `location.address`를 OpenAI에 전송하는 부분이 약관 범위에 포함되는지 확인 필요.

---

## 5. 방법론

- 수동 코드 리뷰 (Edge Functions + RLS migrations)
- 최근 2주 변경 PR 기반 차등 분석
- OWASP Top 10 2021 기준 분류
- 비즈니스 맥락 기반 공격 시나리오 도출

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-16

🤖 **tpm-exec-report-claude-subagents** 분석 완료.

## 코드 검증 결과

모든 항목을 실제 코드 대조하여 검증했습니다.

### Actionable (5건 → 이슈 생성)

| 항목 | 판정 | 이슈 |
|------|------|------|
| P1-1: AI EF anon JWT 호출 + batch_size 무제한 | ✅ 확인 | #1489 |
| P1-3: settlement-transfer requireAuth (타 함수는 requireServiceRole) | ✅ 확인 | #1489 |
| P2-2: notification-worker 인가 없음 | ✅ 확인 | #1489 |
| P1-2: payment-verify user_id 소유권 검증 누락 | ✅ 확인 | #1490 |
| P1-4: event-checkin QR 서명 미검증 | ✅ 확인 (**P2 하향** — user_id 소유권 검증 있어 타인 체크인 불가) | #1491 |
| P2-1: apply-event 유료 경로 balance check 누락 | ✅ 확인 | #1492 |
| P2-4: AI EF 환경변수명 노출 + PII 스크러빙 누락 | ✅ 확인 | #1493 |

### Skip (3건)

| 항목 | 사유 |
|------|------|
| P2-3: identity-verify PII 로깅 | `maskJsonString` + `log()` 미들웨어 자동 마스킹 확인. 정상. |
| P2-5: user_notifications INSERT RLS | 테이블 GRANT에서 authenticated에 INSERT 없음. service_role만 삽입 가능. 실질적 위험 없음. |
| P3 6건 | 추적 과제 수준. 즉시 조치 불필요. |

원본 리포트를 닫습니다.
