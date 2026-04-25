---
source_url: https://github.com/Mark-Yun/minglit/issues/1107
captured_at: 2026-04-06
issue_number: 1107
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Report — 2026-04-06: MVP 피처 성숙도 점검 + 시장/규제 업데이트"
---

# 📊 PM Report — 2026-04-06: MVP 피처 성숙도 점검 + 시장/규제 업데이트

> Issue #1107 · closed · created 2026-04-06T08:04:56Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1107

## Body

# 📊 PM Report — 2026-04-06: MVP 피처 성숙도 점검 + 시장/규제 업데이트
**Scheduler: pm-exec-report-claude-subagents**
**Status: COMPLETED**

---

## 1. Executive Summary

7월 MVP 출시까지 약 3개월. 10개 핵심 피처 중 **6개 완료, 2개 부분 구현, 2개 미구현**. 완료된 피처(Event Now Bar, My Tickets, Partner Settlement, Signup Consent, Account Deletion, Partner Terms/Privacy)는 안정적이다. 그러나 **Tag Discovery가 스펙만 존재하고 구현이 전무**한 상태로, 7월 출시에 가장 큰 리스크다.

외부적으로는 Frip(액티비티 예약)과 소모임(반복 모임)이 각각 시장을 점유하고 있으나, **신뢰 기반 이벤트 매칭**이라는 밍글릿의 포지셔닝은 여전히 빈 공간이다. 다만 PIPA 개정안(2026.09.11 시행)과 전자상거래법 다크패턴 규제가 출시 전 반드시 검증해야 할 법적 리스크로 부상했다.

---

## 2. MVP 피처 파이프라인 성숙도

### 완료 (6/10) ✅

| 피처 | 문서 | 구현 | 비고 |
|------|------|------|------|
| **Event Now Bar** | spec, test-plan, plan, wireframe | 위젯 + 컨트롤러 완료 | Realtime 연동 확인 필요 |
| **My Tickets** | spec, test-plan, plan, wireframe | 전체 구현 + 테스트 | - |
| **Partner Settlement** | requirements, architecture, UI/UX, test-plan (4,400줄) | 10개 migration + EF + UI + 골든 테스트 | 가장 성숙한 피처 |
| **Signup Consent** | spec, test-plan, plan, wireframe | DB + Repository + Controller + UI | - |
| **Account Deletion** | spec, test-plan, plan, wireframe | DB + cron + Flow + UI | - |
| **Partner Terms/Privacy** | - | 랜딩 페이지 반영 완료 | - |

### 부분 구현 (2/10) ⚠️

| 피처 | 현황 | 블로커 |
|------|------|--------|
| **Recurring Events** | DB 스키마(recurrence_rules) + pg_cron 완료. Flutter UI 미구현 | `needs-swe`: 이벤트 생성 플로우에 반복 규칙 UI 추가 필요 |
| **Refund Policy V2** | spec + wireframe 있으나 test-plan/plan 없음. UI 일부 존재 | `needs-qa` + `needs-arch`: 문서 보강 후 3-tier 환불 로직 구현 |

### 미구현 (2/10) ❌

| 피처 | 현황 | 리스크 |
|------|------|--------|
| **Tag Discovery** | spec + wireframe만 존재. DB 스키마/UI/plan/test-plan 전무 | 🔴 **HIGH** — 디스커버리가 없으면 유저 유입 후 이탈 |
| **Statistics Tools** | 인프라(Statsig, Metabase 스키마, Sentry)만 구축. 유저 대면 기능 없음 | 🟡 MEDIUM — MVP에서 인프라만으로 충분할 수 있으나 파트너 대시보드 연동 필요 |

### Partner Dashboard 참고

- spec + test-plan 있으나 plan/wireframe 없음
- 코드는 성숙 (컨트롤러 + 위젯 + 테스트 존재)
- 문서 정비 필요하나 구현 자체는 양호

---

## 3. 시장/경쟁 환경

### 경쟁 포지셔닝

| 경쟁사 | 포지션 | 밍글릿 차별점 |
|--------|--------|---------------|
| **Frip** (1.5M+ 유저) | 액티비티 예약 플랫폼 | Frip은 1회성 예약 중심. 밍글릿은 매칭 + 반복 이벤트 |
| **소모임** (5M+ DL) | 취미 커뮤니티 + 정모/번개 | 소모임은 그룹 기반. 밍글릿은 이벤트 기반 신뢰 매칭 |
| **문토** | 소셜 모임 + AI 취향 매칭 | 밍글릿의 2-layer trust가 더 체계적 |

**핵심 인사이트**: Frip(예약)과 소모임(커뮤니티) 사이의 "신뢰 기반 이벤트 매칭" 공간은 아직 비어 있음. 문토가 AI 스크리닝으로 접근 중이므로 속도가 중요.

### 주요 트렌드

1. **신뢰/인증이 테이블 스테이크**: 데이팅 앱(Pairs, NoonDate 등)에서 시작된 PASS 인증이 비데이팅 소셜로 확산 중. 밍글릿의 trust 아키텍처는 앞서 있으나, "인증됨" 시그널을 UI에서 더 적극적으로 노출해야 함.
2. **큐레이션 > 카탈로그**: 유저는 끝없는 스크롤보다 큐레이팅된 소수 이벤트를 선호. Tag Discovery의 OR 필터 + 5개 태그 제한은 이 트렌드에 부합.
3. **반복 이벤트 = 리텐션**: 소모임의 주간 14,000건 정기 모임이 증명. 1회성 앱은 성장 정체.

---

## 4. 규제 리스크 (출시 전 필수 검증)

### 🔴 PIPA 개정안 (2026.09.11 시행)

| 항목 | 내용 | 밍글릿 영향 |
|------|------|-------------|
| 동의 세분화 | 묶음 동의 불가, 목적별 개별 동의 필수 | signup-consent 스펙 재검증 필요 |
| 데이터 이동권 | 유저가 다른 플랫폼으로 데이터 전송 요청 가능 | 데이터 export API 설계 필요 (출시 후 대응 가능) |
| 대표 책임 강화 | CEO가 데이터 보호 최종 책임자 | 내부 정책 문서화 필요 |

**Action**: `needs-legal`로 signup-consent 스펙의 PIPA 개정안 적합성 검증 요청.

### 🔴 전자상거래법 다크패턴 규제 (시행 중)

| 금지 항목 | 밍글릿 해당 여부 |
|-----------|-----------------|
| 해지/취소 방해 | 환불 플로우가 구매보다 어려우면 안 됨 |
| 숨겨진 자동갱신 | 반복 이벤트 결제 시 명시적 동의 필요 |
| 드립 프라이싱 | 최종 가격을 처음부터 표시 |
| 사전 선택 옵션 | 체크박스 기본 선택 금지 |

**Action**: `needs-legal`로 refund-policy-v2 + recurring-events 결제 플로우의 다크패턴 규제 적합성 검증 요청.

---

## 5. 전략적 권고사항

### P0: Tag Discovery 구현 착수 (7월 출시 블로커)

- **현황**: spec + wireframe만 존재. DB/UI/plan/test-plan 전무
- **이유**: 디스커버리 없이 출시하면 유저가 이벤트를 찾을 수 없음. "홈 피드에 전체 이벤트 나열"은 스케일하지 않음
- **Action**: `needs-qa` → test-plan 작성 → `needs-arch` → plan 작성 → `needs-swe` → 구현
- **목표**: 4월 중 DB 스키마 + 기본 UI 완성

### P1: Recurring Events Flutter UI 구현

- **현황**: 백엔드(DB + cron) 완료, 프론트엔드 없음
- **이유**: 소모임 대비 핵심 차별점. 리텐션의 핵심 메커닉
- **Action**: `needs-swe` — 이벤트 생성 플로우에 반복 규칙 설정 UI 추가

### P1: Refund Policy V2 문서 + 구현 완성

- **현황**: spec/wireframe만 존재. test-plan/plan 없음. 현재 환불은 100%/0% 이진 구조
- **이유**: 전자상거래법 준수 + 유저 신뢰. 3-tier(100% → 50% → 0%) 전환 필수
- **Action**: `needs-qa` → test-plan → `needs-arch` → plan → `needs-swe` → 구현

### P2: 규제 적합성 검증 일괄 요청

- PIPA 개정안 vs signup-consent, account-deletion
- 다크패턴 규제 vs refund-policy-v2, recurring-events 결제
- **Action**: `needs-legal` 이슈 생성

### P2: Trust 시그널 UI 강화

- "인증된 호스트", "인증된 참가자" 배지를 이벤트 카드/상세에 더 적극적으로 노출
- **Action**: `needs-uiux` — trust 시그널 노출 개선 제안

---

## 6. 어제(4/5) 대비 변동사항

| 항목 | 4/5 리포트 | 4/6 현재 |
|------|-----------|---------|
| Recurring Events DB | 미반영 | ✅ `recurrence_rules` migration 머지됨 (PR #1100) |
| Settlement 테스트 | - | ✅ 8개 갭 구현 완료 (PR #1104) |
| 통합 테스트 | Phase 1 | Phase 3까지 완료 (P0 CUJ 7건 + Smoke 9건) |
| Cross-feature import 위반 | - | ✅ 해소 + event_now 5-phase 분리 (PR #1102) |
| 아키텍처 문서 | - | ✅ 현행화 완료 (PR #1093) |

---

## 7. 다음 사이클 우선순위

1. **Tag Discovery** test-plan + plan 작성 요청 (가장 시급)
2. **Recurring Events** Flutter UI 구현 요청
3. **Refund Policy V2** 문서 보강 + 구현 요청
4. **규제 검증** needs-legal 이슈 생성
5. **Trust 시그널 UI** needs-uiux 제안

---

*Report generated by pm-exec-report-claude-subagents.*


## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-10

종합 리포트에서 내용 확인 완료. 이 리포트의 Feature Maturity 수치는 #1193에서 코드 전수조사로 대폭 상향 교정됨 (Refund V2 20→90%, Recurring Events 60→90% 등).
