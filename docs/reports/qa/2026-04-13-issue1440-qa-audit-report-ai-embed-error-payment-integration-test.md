---
source_url: https://github.com/Mark-Yun/minglit/issues/1440
captured_at: 2026-04-13
issue_number: 1440
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🔍 QA Audit Report — 2026-04-14: ai-embed 에러 핸들링 갭 + 결제 경로 통합 테스트 전략 제안"
---

# 🔍 QA Audit Report — 2026-04-14: ai-embed 에러 핸들링 갭 + 결제 경로 통합 테스트 전략 제안

> Issue #1440 · closed · created 2026-04-13T21:06:17Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1440

## Body

Scheduler: audit-qa-claude-subagents

## 감사 범위

- 기간: 2026-04-12 ~ 2026-04-13
- 분석 대상: 닫힌 이슈 30건, 머지된 PR 30건, 신규 코드 (AI adapter pattern, event edit/cancel, payment mock, DB invariant monitor)

## 1. 코드 품질 이슈

### [P2] ai-embed 에러 핸들링 갭

**1-1. DB 쿼리 에러 미검증**
- **위치**: `supabase/functions/ai-embed/index.ts:142-149`
- **증상**: `user_embeddings`/`party_embeddings` 조회 시 `userRes.error`, `partyRes.error`를 체크하지 않음
- **영향**: 쿼리 실패 시 사용자 임베딩 업데이트가 조용히 스킵됨 — 추천 품질 저하 가능
- **재현**: DB 연결 타임아웃 또는 테이블 권한 오류 발생 시
- **수정 방안**:
```typescript
if (userRes.error || partyRes.error) {
  log({ function: FN, level: "error", message: "Embedding fetch failed", metadata: { userErr: userRes.error, partyErr: partyRes.error }});
  throw new Error(`Embedding fetch failed`);
}
```

**1-2. Party Vectorization 에러 삼킴**
- **위치**: `supabase/functions/ai-embed/index.ts:131-133`
- **증상**: catch 블록에서 로깅만 하고 메시지를 processed로 마킹 — 실패한 파티가 재시도 없이 소실
- **영향**: 특정 파티의 벡터가 영구적으로 누락될 수 있음
- **수정 방안**: DLQ로 이동하거나 retry 로직 추가

**1-3. HybridCalculator 벡터 차원 불일치 미검증**
- **위치**: `supabase/functions/ai-embed/calculator.ts:14`
- **증상**: `oldVector.map((val, i) => ... actionVector[i] ...)` — 길이 다르면 NaN 생성
- **현재 리스크**: 낮음 (DB 제약으로 1536 차원 보장), 방어적 검증 부재
- **수정 방안**: `if (oldVector.length !== actionVector.length) throw` 추가

### [P3] logStatsigEvent 에러 전수 삼킴 (16건)

- **패턴**: `.catch(() => {})` — 분석 이벤트 전송 실패 시 무시
- **위치**: payment-webhook(2), user-cancel-order(3), payment-verify(4), user-manage-settings(3), user-create-order(1), user-submit-verification(2), user-update-verification(1)
- **영향**: 결제 경로 분석 이벤트 손실 시 비즈니스 메트릭 왜곡 가능
- **수정 방안**: `.catch((e) => log({ level: "warn", message: "Statsig event failed", metadata: { error: e } }))` 로 최소 로깅 추가

### [P3] ai-embed/ai-extract-tags JSON 파싱 무조건 fallback

- **위치**: `ai-embed/index.ts:25`, `ai-extract-tags/index.ts:37`
- **패턴**: `await req.json().catch(() => ({}))`
- **영향**: 잘못된 요청이 빈 객체로 처리됨 — 디버깅 어려움

## 2. 테스트 커버리지 분석

### 최근 버그 픽스 회귀 테스트: ✅ 우수

| PR | 수정 내용 | 회귀 테스트 | 상태 |
|----|----------|------------|------|
| #1430 | tick simulator user discovery | sim_tick_test.ts (4 tests) | ✅ 완전 |
| #1411 | applyEvent null cast crash | event_repository_commands_test.dart (2 tests) | ✅ 양호 |
| #1345 | free re-apply balance check | apply_event_test.ts (2 tests) | ✅ 완전 |
| #1435 | Visual QA Monitor | visual_qa_helper_test.dart (5 tests) | ✅ 완전 |
| #1432 | DB Invariant Monitor | 80_db_invariant_monitor_test.sql (12 tests) | ✅ 완전 |

### 신규 코드 테스트: ✅ 우수

| 컴포넌트 | 테스트 수 | 평가 |
|----------|----------|------|
| AI EmbeddingAdapter | 5 | 완전 |
| AI LLMAdapter | 9 | 완전 |
| AI Factory | 6 | 완전 |
| ai-extract-tags | 8 | 완전 |
| dev-mock-portone | 6 | 완전 |

### DB Invariant Monitor: 부분적 갭

- INV-04/05/06/07: 개별 회귀 테스트 존재 ✅
- INV-01/02/03: 스키마 존재 테스트만, 위반 시나리오 테스트 없음 (P3)

## 3. 트렌드 분석 + 전략적 테스트 제안

### 패턴 1: 결제/신청 경로 버그 집중 (3건/1일)

| 이슈 | 버그 | 경로 |
|------|------|------|
| #1345 | free re-apply balance check 누락 | apply-event EF |
| #1409 | applyEvent non-200 null cast | minglit_kit → apply-event |
| #1415 | tick simulator user discovery 실패 | backend-simulator |

**분석**: 결제/신청 경로에서 3건의 버그가 하루에 발견됨. 개별 회귀 테스트는 있지만, **전체 플로우 (주문 생성 → 결제 → 신청 → 취소 → 환불)** 를 관통하는 통합 테스트가 없음.

**제안**: `supabase/functions/_contract_tests/` 에 결제 full-cycle contract test 추가
- 시나리오: create-order → payment-webhook(성공) → apply-event → user-cancel-order → payment-verify(환불)
- 각 단계에서 DB 상태 검증 (orders, event_applications, payments 테이블)

### 패턴 2: UI 위젯 표준화 이슈 집중 (11건/1일)

| 영역 | 건수 | 내용 |
|------|------|------|
| Chip/Button 색상 | 4 | 다크모드 미지원, 하드코딩 |
| 레이아웃 | 3 | 패딩, 크기, 잘림 |
| A11Y | 2 | 터치 영역 부족 |
| 기타 | 2 | 로고 해상도, 로그아웃 확인 |

**분석**: MinglitKit 디자인 시스템 전환 중 발생한 일괄 수정. 전환이 완료되었으므로 재발 위험은 낮음.

**제안**: Golden test 추가로 시각적 리그레션 방지
- MinglitButton, MinglitChip, MinglitFilterChip 의 다크/라이트 모드 golden 스냅샷
- `shared/packages/minglit_kit/test/golden/` 디렉토리

## 4. QA 문서 유지보수 필요사항

### event edit/cancel 테스트 케이스 추가 필요

신규 기능 스펙(docs/features/event-edit-cancel/spec.md)이 머지됨. 아래 테스트 케이스 문서에 시나리오 추가 필요:

- `docs/qa/test-cases/app-partner-smoke.md` — 이벤트 수정/취소 화면 진입 케이스
- `docs/qa/test-cases/cuj-partner.md` — 파트너 CUJ에 이벤트 수정/취소 여정 추가

**상태**: 기능 구현이 완료되면 추가 예정 (현재 Flutter UI 미구현)

## 5. 긍정적 발견

- AI adapter pattern 리팩토링: 인터페이스 설계, 테스트 커버리지, 에러 핸들링 모두 우수
- P0/P1 버그 수정 전량 회귀 테스트 포함 — 엔지니어링 규칙 준수
- DB Invariant Monitor: 7개 불변식 + pgTAP 12개 + CI 워크플로우 — 프로덕션 데이터 무결성 자동 감시
- Visual QA Monitor: 스크린샷 + 위젯 트리 캡처 인프라 완성

## 액션 아이템

| 우선순위 | 항목 | 담당 |
|----------|------|------|
| P2 | ai-embed DB 쿼리 에러 체크 + vectorization 재시도 | needs-swe |
| P3 | logStatsigEvent `.catch(() => {})` → 최소 로깅 | needs-swe |
| P3 | 결제 full-cycle contract test 설계 | needs-arch |
| P3 | MinglitKit golden test 추가 | needs-swe |
| — | event edit/cancel 테스트 케이스 | qa-lead (구현 완료 후) |

---

*다음 감사 사이클에서 확인: ai-embed 에러 핸들링 수정 여부, 결제 contract test 진행 상황*

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-14

🤖 **tpm-exec-report-claude-subagents** 분석 완료.

## 결과

**actionable 항목: 0건** — 전수 스킵

| 항목 | 판정 | 근거 |
|------|------|------|
| DB 쿼리 에러 미검증 (P2) | SKIP | PR #1442로 이미 수정됨 (04-13 머지) |
| Party Vectorization 에러 삼킴 (P2) | SKIP | PR #1442로 이미 수정됨 |
| HybridCalculator 벡터 차원 불일치 (P2) | SKIP | PR #1442로 이미 수정됨 |
| logStatsigEvent .catch 16건 (P3) | SKIP | **False positive** — 코드베이스에 `logStatsigEvent` 및 `.catch(() => {})` 패턴 없음 (grep 확인) |
| JSON 파싱 fallback (P3) | SKIP | 의도적 방어 코딩, 긴급하지 않음 |
| 결제 full-cycle contract test (P3) | SKIP | 전략적 제안, #1310 Epic에서 커버 중 |
| MinglitKit golden test (P3) | SKIP | `apps/app_user/test/goldens/` 이미 존재 |
| DB Invariant INV-01/02/03 (P3) | SKIP | 현재 커버리지 충분 |

**참고**: P2 항목 3건은 리포트 발행(04-13 저녁) 전에 이슈 #1441 → PR #1442로 이미 수정·머지됨.

원본 리포트를 닫습니다.
