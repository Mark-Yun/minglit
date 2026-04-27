---
source_url: https://github.com/Mark-Yun/minglit/issues/1338
captured_at: 2026-04-12
issue_number: 1338
state: open
labels: [enhancement, P2-medium, report-exec]
author: Mark-Yun
title: "test(app_partner): 이벤트 수정/취소 통합 테스트 추가"
---

# test(app_partner): 이벤트 수정/취소 통합 테스트 추가

> Issue #1338 · open · created 2026-04-12T13:07:04Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1338

## Body

Scheduler: needs-pm-claude-1

## 배경

파트너앱에서 이벤트 수정/취소(P07) 관련 통합 테스트가 전혀 없음. 참가자가 있는 이벤트 취소 시 환불/알림 처리가 핵심.

## 테스트 케이스

### P07: 이벤트 수정/취소
- TC-P07-001: 이벤트 정보 수정 (시간/정원 변경 → 저장 → 참가자 알림)
- TC-P07-002: 이벤트 취소 (사유 입력 → 확인 → 전 참가자 환불/알림)
- TC-P07-003: 참가자 있는 이벤트 취소 경고 다이얼로그

## 참고
- Epic: #1310
- 플로우 맵: `docs/testing/user-flow-test-map.md` (P07)

## Comments (15)

### Comment 1 — @Mark-Yun on 2026-04-12

## QA Review — needs-qa-claude-1

### 1. 코드 현황

| 대상 | 상태 | 비고 |
|------|------|------|
| 이벤트 수정 (EventEdit) | ❌ **미구현** | `EventEditRoute` 없음. Create/Detail만 존재 |
| 이벤트 취소 | ⚠️ 확인 필요 | EventDetailPage 내에 취소 액션이 있을 수 있으나 별도 UI/Route 미확인 |

기존 테스트:
- `event_detail_controller_test.dart` — 이벤트 상세 컨트롤러
- `event_create_controller_test.dart` — 이벤트 생성 컨트롤러

### 2. 테스트 케이스 판정

- **TC-P07-001** (이벤트 정보 수정): ❌ **blocked** — 수정 UI 미구현. 피쳐 구현 이슈가 선행되어야 함
- **TC-P07-002** (이벤트 취소 + 환불/알림): ⚠️ EventDetailPage 내 취소 플로우 확인 후 작성 가능
- **TC-P07-003** (취소 경고 다이얼로그): ⚠️ 동일

### 3. 판정

이벤트 수정 기능이 구현되지 않은 상태에서 통합 테스트 작성은 불가. 두 가지 선택지:

1. **이벤트 취소 테스트만 분리** → `needs-swe`로 축소 scope 진행
2. **이벤트 수정 피쳐 구현을 선행** → `needs-pm` 또는 `needs-arch`로 리라우팅

`needs-qa` 제거. `needs-swe`는 유지하되 **scope를 이벤트 취소 플로우 테스트로 한정**합니다. 이벤트 수정 테스트는 해당 피쳐 구현 후 별도 이슈로 추적하세요.

### Comment 2 — @Mark-Yun on 2026-04-13

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 3 — @Mark-Yun on 2026-04-13

## 조사 결과 — needs-swe-sonnet-subagents-1

QA 리뷰에서 TC-P07-002/003 구현 가능 여부가 "⚠️ 확인 필요"였는데, 직접 탐색한 결과 **이벤트 취소 기능 자체가 미구현**임을 확인했습니다.

### 현황

| 구성요소 | 상태 |
|---------|------|
| EventDetailPage 취소 버튼/다이얼로그 | ❌ 없음 |
| EventDetailController.cancelEvent() | ❌ 없음 |
| PartyEventRepository 파트너 취소 메서드 | ❌ 없음 (updateEventStatus만 존재) |

### 판단

TC-P07-002 (이벤트 취소 + 환불/알림), TC-P07-003 (취소 경고 다이얼로그) 모두 blocked.

테스트 이슈 범위를 넘어 피쳐 구현이 선행되어야 합니다. 판단을 TPM에게 넘깁니다.

- `needs-swe` 제거, `needs-tpm` 추가합니다.

### Comment 4 — @Mark-Yun on 2026-04-13

🤖 **needs-tpm-claude-1** TPM 분석 완료.

### 분석 결과

SWE 조사에서 확인된 바와 같이, **이벤트 수정/취소 기능 자체가 미구현** 상태입니다:
- `EventEditRoute` 없음 (Create/Detail만 존재)
- 이벤트 취소 버튼/다이얼로그 없음
- 백엔드 Edge Function도 부재

### TPM 판단

이 이슈는 **기능 미구현으로 인해 blocked** 입니다. 통합 테스트는 기능이 존재해야 작성할 수 있습니다.

**조치:**
1. 이 이슈는 Epic #1310의 서브이슈로, 기능 구현 후 다시 활성화합니다
2. 피처 구현 이슈는 PM이 기획 + 스펙을 먼저 작성해야 합니다 → `needs-pm` 라벨로 신규 이슈 생성
3. 현재 이슈는 blocked 상태로 보류 — 피처 구현 이슈에서 참조하겠습니다

`needs-tpm` 라벨을 제거합니다.

### Comment 5 — @Mark-Yun on 2026-04-18

🤖 **needs-tpm-claude-1** Epic #1310의 child로 파일링됐는데 `needs-swe` 라벨이 빠져 있었습니다. 라우팅합니다.

### Comment 6 — @Mark-Yun on 2026-04-18

🤖 **needs-swe-sonnet-1** 조사 결과 및 에스컬레이션.

현재 dev 브랜치에서 이벤트 수정/취소 기능이 여전히 미구현 상태임을 확인했습니다.

**확인 항목:**
- `EventEditRoute` 없음 (2026-04-13 조사 이후 변동 없음)
- `apps/app_partner/lib/` 에서 `EventEdit`, `event_cancel`, `CancelEvent` 관련 코드 없음

**상황:**
테스트를 작성하려면 피처 구현이 선행되어야 합니다. 이벤트 수정/취소는 신규 기능으로 아래 두 가지 중 결정이 필요합니다.

**선택지:**
A) 이벤트 수정/취소 기능을 구현한 뒤 통합 테스트 추가 (대규모 — PM spec 필요)
B) 이슈를 Epic #1310 구현 이후로 defer (needs-arch/needs-pm으로 별도 파이프라인)

Mark의 판단 요청.

### Comment 7 — @Mark-Yun on 2026-04-18

🤖 **needs-pm-claude-1** 작업 시작합니다.

### Comment 8 — @Mark-Yun on 2026-04-18

## PM 판단 — needs-pm-claude-1

### 현황 확인

| 항목 | 상태 |
|------|------|
| 스펙 (`docs/features/event-edit-cancel/spec.md`) | ✅ merged via #1397 (2026-04-13) |
| 와이어프레임 | ✅ merged via #1397 + UX 수정 #1400 |
| UX 리뷰 (#1398) | ✅ COMPLETED (2026-04-13) |
| QA 테스트 계획 | ❌ **생성되지 않음** — 파이프라인 누락 |
| SWE 구현 이슈 | ❌ **생성되지 않음** — 파이프라인 누락 |
| 실제 코드 (grep `EventEdit\|CancelEvent`) | ❌ 없음 |

**파이프라인 고장**: `pm → ux-designer → [qa-lead 누락] → [swe 누락]`. #1398 닫으면서 다음 단계 이슈를 만들지 않았음. 2026-04-13 이후 5일간 방치.

### PM 판단 (Option A 권고 — 구현)

**MVP(2026-07) 관점에서 MUST-HAVE 기능**.

1. **이벤트 취소 없이 출시 불가** — 파트너가 일정 변경/인원 미달/장소 불가 상황에서 이벤트를 취소할 수단이 전혀 없음. 참가자 보호 차원에서도 필수
2. **이벤트 수정 없이 출시 시 운영 리스크** — 오타/시간 실수가 영구 고정. 파트너 이탈 요인
3. **기존 인프라 활용도 높음** — 스펙상 `partner-manage-event` EF의 기존 `update`/`update_status` 액션 확장만 필요. 신규 EF 불필요
4. **경쟁 앱 전부 기본 제공** — Eventbrite/Meetup/Luma 모두 기본 기능. 밍글릿만 없으면 파트너 온보딩 차단

**Option B (defer)는 권장 안 함**: MVP까지 3개월 남았는데 핵심 파트너 운영 기능을 뒤로 미루면 출시 품질 치명타.

### 권장 조치 (Mark 승인 시)

1. **신규 이슈 생성**: `feat(app_partner): 이벤트 수정/취소 구현` (P2-medium, `needs-qa` 라벨, 스펙 참조)
2. **파이프라인 진행**: needs-qa → needs-swe → needs-review
3. **#1338은 이 구현 이슈의 blocker로 링크** 후 needs-pm 제거. 기능 머지 후 재활성화
4. **우선순위**: 기존 P2 유지. P0 보안 이슈 우선, 이 기능은 이번 스프린트 내 시작 목표

### 예상 영향도

| 항목 | 추정 |
|------|------|
| SWE 구현 규모 | 중 (2~3 PR 분할 권장: ① EF 확장 ② 파트너 UI ③ 알림 연동) |
| DB 스키마 변경 | 최소 (`events.metadata.cancel_reason` 추가만) |
| 리스크 | 환불 로직이 기존 `payment-cancel` EF를 재사용하므로 낮음 |
| 출시 영향 | MVP 차단 해소 — 현재 없으면 출시 불가 |

### 요청

`report-exec` 유지. Mark의 최종 승인 요청:
- **[ ] Option A 승인** → PM이 다음 사이클에 구현 이슈 생성 + 파이프라인 진행
- **[ ] Option B** → 구현 defer, #1338은 장기 blocked 유지 (비권장)
- **[ ] 다른 판단** → 코멘트로 방향 지시

`needs-pm` 라벨은 제거합니다. Mark 승인 후 다음 단계 진행 가능.

### Comment 9 — @Mark-Yun on 2026-04-18

/needs-pm 옵션 a승인합니다 feature workflow 진행해주세요

### Comment 10 — @Mark-Yun on 2026-04-18

🤖 **needs-pm-claude-1** Mark 승인 확인. Feature workflow 진행합니다.

### Comment 11 — @Mark-Yun on 2026-04-18

## needs-pm-claude-1 — Feature workflow 진행 완료

Mark Option A 승인에 따라 구현 파이프라인을 활성화했습니다.

### 조치

1. **QA 테스트 계획 이슈 생성**: #1592 (`needs-qa` 라벨)
2. **#1338은 blocked 상태로 보류** — #1592 파이프라인이 진행되어 기능이 머지되면 이 테스트 이슈를 재활성화
3. `needs-pm` + `report-exec` 라벨 제거

### 파이프라인 진행 상황

| 단계 | 이슈 | 상태 |
|------|------|------|
| 기획 (pm) | #1396 / PR #1397 | ✅ COMPLETED |
| UX 리뷰 | #1398 / PR #1400 | ✅ COMPLETED |
| QA 테스트 계획 | **#1592** | 🟡 진행 중 |
| SWE 구현 (7개 분할 예상) | 예정 | ⏳ 대기 |
| 통합 테스트 재활성화 | #1338 (this) | ⏳ 기능 머지 후 |

Epic #1310 기준으로 추적됩니다.

### Comment 12 — @Mark-Yun on 2026-04-19

🤖 **tpm-exec-report-claude-subagents** 04-12 할당 이후 6일간 업데이트 없음. 진행 상황 공유 부탁드립니다. 블로킹이 있으면 `needs-tpm` 라벨로 리라우팅해주세요.

### Comment 13 — @Mark-Yun on 2026-04-22

🤖 **needs-tpm-claude-1** 라우팅: 블로커였던 #1592 (테스트 계획)는 closed, test-plan 머지 완료 (PR #1594). 이 이슈를 unblocked 상태로 전환하여 `needs-swe`로 라우팅.

### Comment 14 — @Mark-Yun on 2026-04-22

🤖 **needs-swe-sonnet-1** 작업 시작합니다.

### Comment 15 — @Mark-Yun on 2026-04-22

🤖 **needs-swe-sonnet-1** 분석 결과, 현재 단계에서 통합 테스트 작성 불가.

## 발견 사항

`docs/features/event-edit-cancel/test-plan.md` §구현 이슈 매핑에 따르면:

| 이슈 번호 | 내용 | 상태 |
|---------|------|------|
| 1 | EF: update_status 취소 + 환불 + 알림 | 미구현 |
| 2 | EF: update 시 핵심정보 변경 알림 | 미구현 |
| 3 | Flutter: EventEditRoute + EventCreatePage 편집 모드 | 미구현 |
| 4 | Flutter: EventDetailPage 수정/취소 진입점 + 취소 UI | 미구현 |
| 5 | Flutter: EventRepository updateEvent/cancelEvent | 미구현 |
| 6 | Flutter: 유저앱 취소 이벤트 표시 | 미구현 |
| 7 (#1338) | 통합 테스트 | **"다른 6개 이슈 머지 후 마지막에 진행"** |

현재 EventDetailPage에 수정/취소 버튼이 없고, 취소 UI(바텀시트/확인 다이얼로그), EventRepository의 cancelEvent()/updateEvent()가 모두 미구현.

통합 테스트는 실제 UI 흐름을 검증하므로, UI가 없는 상태에서 작성하면 의미가 없습니다.

## 선택지

**Option A**: 이 이슈에서 구현(1-6) + 테스트(7)를 모두 처리
- 장점: 단일 PR로 완결
- 단점: PR 규모 과대, 리뷰 부담 증가, 아키텍처 결정(EF, DB migration 포함)이 필요

**Option B**: 구현 이슈 1-6을 별도로 생성/할당 → 완료 후 #1338 진행
- 장점: 테스트 계획 원래 의도대로, PR 크기 적절
- 단점: 추가 이슈 생성 및 우선순위 결정 필요

**Option C**: 구현 이슈 3-5(Flutter 부분)만 이 이슈에서 먼저 처리, EF(1-2)는 별도
- 장점: 빠른 Flutter 진행, EF는 나중에
- 단점: 취소 UI는 있으나 실제 환불/알림 로직 없이 모킹만으로 테스트

**needs-swe-sonnet-1 의견**: Option B 권장. 이슈별 책임이 명확하고 테스트 계획의 설계 의도를 따름. 단, Mark가 빠른 진행을 원한다면 Option A도 가능하며 이 경우 이 이슈에서 Flutter 부분(3+4+5+7)을 구현하고 EF/DB는 별도 이슈로 분리 추천.

`report-exec` 라벨로 Mark에게 결정 요청합니다.
