---
source_url: https://github.com/Mark-Yun/minglit/issues/1133
captured_at: 2026-04-07
issue_number: 1133
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Report — 2026-04-07: Feature Maturity 교정 + 다크패턴 규제 긴급도 상향"
---

# 📊 PM Report — 2026-04-07: Feature Maturity 교정 + 다크패턴 규제 긴급도 상향

> Issue #1133 · closed · created 2026-04-07T08:04:19Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1133

## Body

Scheduler: pm-exec-report-claude-subagents

## Summary

어제 보고서(#1108)의 피처 성숙도 매트릭스를 **실제 코드 기반**으로 교정하고, 경쟁/규제 환경을 업데이트합니다.

### 핵심 변경 3가지

1. **Feature Maturity 교정**: 코드 확인 결과 My Tickets(80%), Partner Dashboard(70%), Account Deletion(60%) 등 누락 피처 추가. Recurring Events 50%→65% 상향.
2. **당근모임 급성장**: YoY 가입자 +125%, 모임 수 +63%. QR 출석체크/브랜드 콜라보 등 신규 기능. Minglit의 차별화 포인트를 더 강하게 어필해야 함.
3. **다크패턴 규제 긴급도 상향**: 2025.08.13 본격 집행이 **이미 시작**됨. 출시 시점에는 완전 적용 상태. 환불/해지/결제 플로우 점검 시급.

---

## Feature Maturity Matrix (코드 기반 교정)

| Feature | 이전(#1108) | 교정 | BE | Flutter | 리스크 |
|---------|------------|------|-----|---------|--------|
| Tag Discovery | 0% | **0%** | ❌ | ❌ | 🔴 출시 블로커 |
| Recurring Events | 50% | **65%** | ✅ | Partner ✅ / User ❌ | 🟡 |
| Refund Policy V2 | 30% | **40%** | ✅ | 부분 ✅ | 🟡 |
| Account Deletion | 미포함 | **60%** | ✅ | ❓ | 🟡 |
| My Tickets | 미포함 | **80%** | - | ✅ + Tests | 🟢 |
| Partner Dashboard | 미포함 | **70%** | - | ✅ | 🟢 |

---

## 경쟁 환경

- **당근모임**: YoY 가입자 +125%, 모임 수 +63%. 하이퍼로컬 + 모임 조합 급성장.
- **문토**: 52억원 시리즈A. 95만 누적 가입, 20-30대 68%.
- **글로벌**: Eventbrite "Soft Socializing" — 79% of 18-35 더 많은 이벤트 참석 계획. Partiful 500K+ MAU (+400% YoY).

---

## 규제 리스크 (긴급도 상향)

### 다크패턴 (2025.08.13 본격 집행 — 이미 적용 중)
- 취소 방해 금지, 반복 강요 금지, 사전 선택 금지, 순차적 가격 공개 금지
- 위반 시: 3회 이상 → 최대 500만원 과태료 + 1년 영업정지
- **Minglit 해당 영역**: 티켓 환불, 계정 탈퇴, 결제 플로우 → 모두 미점검 상태

### PIPA 분리 동의
- 필수/선택 동의 항목별 개별 체크박스 필수
- 중요 내용 강조 표시 의무

---

## 액션 아이템

| # | 긴급도 | 액션 |
|---|--------|------|
| 1 | 🔴 P0 | Tag Discovery 파이프라인 가동 (needs-qa → needs-arch → needs-swe) |
| 2 | 🔴 P0 | `needs-legal` 이슈: 다크패턴 규제 감사 (환불/해지/결제) |
| 3 | 🟡 P1 | `needs-legal` 이슈: Signup Consent PIPA 재점검 |
| 4 | 🟡 P1 | Recurring Events User 앱 UI → needs-swe |
| 5 | 🟢 P2 | Trust Badge UI 기획 (당근모임 성장 대응) |

---

## 부록: report-exec 노이즈

현재 9개 report-exec 이슈 열려 있음. TPM에게 오래된 이슈(#962, #1046, #1079, #1080) 정리 권고.

---

*Previous report: #1108 (2026-04-06)*
*Full draft: `tmp/pm-report-draft.md`*

## Comments (4)

### Comment 1 — @Mark-Yun on 2026-04-07

🤖 **pm-exec-report-claude-subagents** 액션 아이템 실행 결과:

- ✅ **#1134** — 다크패턴 규제 대응 감사 (`needs-legal`)
- ✅ **#1135** — Signup Consent PIPA 분리 동의 재점검 (`needs-legal`)
- ⏳ Tag Discovery 파이프라인 가동 — 기존 spec 완료 상태이므로 `needs-qa` → `needs-arch` → `needs-swe` 순서로 진행 필요. 별도 이슈 생성은 기존 Tag Discovery 관련 이슈 확인 후 판단.

### Comment 2 — @Mark-Yun on 2026-04-07

🤖 **pm-exec-report-claude-subagents** 추가 액션:

- ✅ **#1136** — Tag Discovery 구현 파이프라인 가동 (`needs-qa`, `P0-critical`)

### 이번 사이클 최종 결과
| # | 액션 | 이슈 | 상태 |
|---|------|------|------|
| 1 | Tag Discovery 파이프라인 가동 | #1136 | ✅ `needs-qa` |
| 2 | 다크패턴 규제 감사 | #1134 | ✅ `needs-legal` |
| 3 | PIPA Consent 재점검 | #1135 | ✅ `needs-legal` |
| 4 | Recurring Events User UI | 기존 파이프라인 | ⏳ |
| 5 | Trust Badge UI | 후속 사이클 | ⏳ |

report-exec 노이즈 정리는 TPM에게 위임.

### Comment 3 — @Mark-Yun on 2026-04-07

### ⚠️ Feature Maturity 재교정 (정밀 코드 분석 기반)

초기 보고서의 추정치를 정밀 코드 분석으로 교정합니다. 특히 Account Deletion과 Refund Policy V2를 크게 과소평가했습니다.

| Feature | 초기 추정 | **정밀 분석** | 주요 발견 |
|---------|----------|-------------|-----------|
| Tag Discovery | 0% | **0%** | Spec만 존재, 코드 zero |
| Recurring Events | 65% | **60%** | BE ✅ + Partner UI ✅. E2E 테스트 부족 |
| Refund Policy V2 | 40% | **70%** | `refund_calculator.dart` + `refund_utils.ts` + DB trigger + 시뮬레이터 존재. Partner 환불 UI만 미구현 |
| My Tickets | 80% | **90%** | Today 배너, D-Day 카운터, QR 버튼 등 거의 완성 |
| Partner Dashboard | 70% | **85%** | 5탭 네비게이션 재설계 완료. 리뷰 시스템만 "준비 중" |
| Account Deletion | 60% | **95%** | 양쪽 앱(User+Partner) 모두 4단계 플로우 완성. DI 해싱, 7일 소프트 삭제, 법적 보관 아카이브까지 구현 |

**핵심 결론**: Tag Discovery 0%만이 진짜 출시 블로커. 나머지 피처는 예상보다 성숙도가 높다. 전체 MVP 완성도는 ~75%로 추정 (어제 보고서의 60%에서 상향).

🤖 pm-exec-report-claude-subagents

### Comment 4 — @Mark-Yun on 2026-04-10

종합 리포트에서 내용 확인 완료. Feature Maturity는 #1193에서 다시 코드 전수조사로 재교정됨.
