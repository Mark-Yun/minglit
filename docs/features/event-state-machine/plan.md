# Event State Machine Extension — Technical Plan

**Issue**: #998
**Status**: `scheduled | cancelled | completed` → `scheduled | active | ongoing | completed | cancelled`

## 1. Problem Summary

현재 이벤트 상태가 3개(`scheduled`, `cancelled`, `completed`)뿐이라 실제 라이프사이클을 표현하지 못함:
- 체크인이 `scheduled` 상태에서 수행됨 (상태-행위 불일치)
- `scheduled → completed` 직행으로 중간 단계 없음
- 시뮬레이터가 `simCompleteEvents`로 강제 전환하여 우회 중
- 시작된 이벤트에 신규 신청 차단 불가

## 2. Target State Machine

```
scheduled ──→ active ──→ ongoing ──→ completed
    │
    └──→ cancelled    cancelled ←── active (파트너 취소)
```

| 전환 | 조건 | 방식 |
|------|------|------|
| `scheduled → active` | `start_time - 30분` 도달 (체크인 창 오픈) | 크론 (매 분) |
| `scheduled → cancelled` | 파트너 수동 취소 | 수동 |
| `active → ongoing` | `start_time` 도달 (이벤트 시작) | 크론 (매 분) |
| `active → cancelled` | 파트너 수동 취소 | 수동 |
| `ongoing → completed` | `end_time` 도달 | 크론 (15분) — 기존 유지 |

### 상태별 기능 권한

| 기능 | scheduled | active | ongoing | completed |
|------|:---------:|:------:|:-------:|:---------:|
| 신규 신청 | O | O | X | X |
| 체크인 | X | O | O | X |
| 매칭 투표 | X | X | O | O |
| 정산 생성 | X | X | X | O |
| 피드 노출 | O | O | X | X |
| 환불 | O (전액) | O (정책) | X | X |

## 3. Impact Analysis

### 3.1 DB Changes (Migration)

**check constraint 변경**:
- `events.status` check: `('scheduled','cancelled','completed')` → `('scheduled','active','ongoing','cancelled','completed')`

**크론잡 변경**:
- 기존 `auto-complete-past-events`: `scheduled → completed` (end_time) → `ongoing → completed` (end_time)로 변경
- 신규 `activate-upcoming-events`: `scheduled → active` (start_time - 30분 도달, 매 분)
- 신규 `start-active-events`: `active → ongoing` (start_time 도달, 매 분)

**이벤트 파이프라인 트리거 변경**:
- `trigger_produce_event_events()`: `event_cancelled` 조건에 `active → cancelled` 추가

### 3.2 Search/Feed Functions (5곳)

`e.status = 'scheduled'` 조건을 `e.status IN ('scheduled', 'active')` 로 변경:
- `search_events_pgroonga()` — `20260316000001_restore_block_filter_search.sql`
- `get_personalized_recommendations()` — `20260311000001_add_visibility.sql`
- `get_events_within_radius()` — `20260311000001_add_visibility.sql`
- `get_user_event_feed()` — `20260330000003_user_event_feed.sql`
- `send_event_reminders()` — `20260301000006_06_functions_triggers.sql`

### 3.3 RPC/Edge Functions

**`apply_event()` RPC** (`06_functions_triggers.sql:490`):
- 이벤트 상태 체크 추가: `status NOT IN ('ongoing', 'completed', 'cancelled')` 일 때만 허용

**`event-checkin` EF** (`supabase/functions/event-checkin/index.ts`):
- 이벤트 상태 체크 추가: `status IN ('active', 'ongoing')` 일 때만 허용

### 3.4 Simulator

**`sim_event.ts`의 `simCompleteEvents()`**:
- `scheduled → completed` 직행 대신 `scheduled → active → ongoing → completed` 순차 전환
- 또는 크론에 위임하고 시뮬레이터에서는 시간 조작으로 자연 전환 유도

### 3.5 Flutter Client

**`event.dart` 모델**: status 필드가 `String` 타입이므로 DB 변경만으로 호환됨. 별도 수정 불필요.

**UI 로직** (Event Now Bar 등): 기존 상태 체크 로직이 `status == 'completed'`/`'cancelled'` 패턴이면 호환됨.
신규 상태(`active`, `ongoing`)에 대한 UI 표시는 후속 PR로 분리 가능.

## 4. Task Breakdown

### Task 1: DB Migration (dev-1)

새 migration 파일: `20260405000001_event_state_machine_extension.sql`

1. `events.status` check constraint DROP + 신규 constraint 추가 (`scheduled`, `active`, `ongoing`, `cancelled`, `completed`)
2. 기존 `auto-complete-past-events` 크론 수정: `WHERE status = 'ongoing'` (기존: `WHERE status = 'scheduled'`)
3. 신규 크론 `activate-upcoming-events`: 매 분, `scheduled → active` (WHERE `status = 'scheduled' AND start_time - interval '30 minutes' <= now()`)
4. 신규 크론 `start-active-events`: 매 분, `active → ongoing` (WHERE `status = 'active' AND start_time <= now()`)
5. `trigger_produce_event_events()` 수정: `active → cancelled` 케이스 추가
6. Search/Feed/Radius 함수 재정의: `e.status = 'scheduled'` → `e.status IN ('scheduled', 'active')`
   - `search_events_pgroonga()` (Section 7a)
   - `get_personalized_recommendations()` (Section 7b)
   - `get_user_event_feed()` (Section 7c)
   - `send_event_reminders()` — 리마인더는 `scheduled`와 `active` 모두에서 발송 (Section 7d)
   - `get_events_within_radius()` (Section 7e)
7. `apply_event()` 수정: 이벤트 상태 validation 추가 — `ongoing`, `completed`, `cancelled` 상태면 에러

### Task 2: Edge Function 수정 (dev-2)

1. `event-checkin/index.ts`: 이벤트 조회 시 `events.status` 체크 추가 — `active` 또는 `ongoing`이 아니면 400 반환
2. `backend-simulator/sim_event.ts`의 `simCompleteEvents()` 수정: 상태 머신 순서대로 전환 (`scheduled → active → ongoing → completed`)

### Task 3: pgTAP 테스트 (dev-3)

1. 상태 전환 크론 테스트:
   - `scheduled → active` (start_time - 30분 도달)
   - `active → ongoing` (start_time 도달)
   - `ongoing → completed` (end_time 도달)
   - 전환 조건 미충족 시 상태 유지
2. `apply_event()` 상태 validation 테스트:
   - `scheduled` 상태: 성공
   - `active` 상태: 성공
   - `ongoing` 상태: 에러
   - `completed` 상태: 에러
3. 이벤트 파이프라인 트리거 테스트:
   - `active → cancelled` 시 `event_cancelled` 이벤트 발행
4. 정산 트리거 테스트:
   - `ongoing → completed` 시 `create_settlement_on_event_completion` 정상 동작

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| 기존 `scheduled` 이벤트 중 이미 시작된 것들 | Migration에서 `UPDATE events SET status = 'ongoing' WHERE status = 'scheduled' AND start_time <= now() AND end_time > now()` 실행 |
| Search/Feed에서 `active` 이벤트 누락 | `IN ('scheduled', 'active')` 로 일괄 변경 |
| 시뮬레이터 E2E 테스트 깨짐 | `simCompleteEvents` 수정으로 상태 순차 전환 |
| Flutter 클라이언트 호환성 | `status`가 String 타입이므로 DB만 변경해도 호환. UI 표시는 후속 PR |

## 6. Out of Scope (후속 PR)

- Flutter UI에서 `active`/`ongoing` 상태별 뱃지 표시
- `min_participants` 기반 `scheduled → active` 자동 전환 (PM 스펙 확정 필요)
- 최소인원 미달 시 자동 취소 로직
- 환불 정책 연동 (#765)
