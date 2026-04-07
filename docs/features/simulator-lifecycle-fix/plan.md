# 백엔드 시뮬레이터 라이프사이클 보완

> Issue: #964 — 메인화면 이벤트 피드 안뜸
> Author: needs-arch-claude-team-1

## 문제 분석

### 근본 원인

백엔드 시뮬레이터의 `run` phase가 **모든 `scheduled` 이벤트를 즉시 `completed`로 전환**하여, 피드에 표시할 이벤트가 0건이 됨.

```
run phase 쿼리: SELECT id FROM events WHERE status = 'scheduled' LIMIT 50
→ E2E 이벤트 + 비E2E 이벤트 모두 포함
→ simCompleteEvents()가 전부 completed로 변경
→ 피드 쿼리(status='scheduled' AND start_time >= now()) 결과 0건
```

### 구조적 문제 3가지

| # | 문제 | 영향 |
|---|------|------|
| 1 | `run` phase가 E2E/비E2E 구분 없이 모든 이벤트를 처리 | 피드 이벤트까지 completed 처리됨 |
| 2 | 시간 기반 자동 이벤트 완료 메커니즘 부재 | `simCompleteEvents`가 유일한 완료 주체 |
| 3 | 시뮬레이터가 피드용 이벤트를 생성하지 않음 | E2E 이벤트만 생성, 모두 같은 사이클에서 소비 |

## 설계 방안

### Change 1: 자동 이벤트 완료 크론 (신규 migration)

`end_time`이 지난 `scheduled` 이벤트를 자동으로 `completed`로 전환하는 pg_cron 추가.

```sql
SELECT cron.schedule(
  'auto-complete-past-events',
  '*/15 * * * *',
  $$
    UPDATE public.events
    SET status = 'completed', updated_at = now()
    WHERE status = 'scheduled'
      AND end_time < now();
  $$
);
```

- 15분 주기 실행
- 기존 `on_event_completed` 트리거가 자동으로 settlement 생성
- 프로덕션에서도 사용 가능한 범용 메커니즘

**파일**: `supabase/migrations/20260404000001_auto_complete_past_events.sql`

### Change 2: `run` phase E2E 전용 필터

`index.ts`의 `run` phase 쿼리를 E2E 이벤트만 대상으로 변경.

현재:
```ts
const { data: scheduledEvents } = await supabase
  .from("events")
  .select("id")
  .eq("status", "scheduled")
  .limit(50);
```

변경 후:
```ts
const { data: scheduledEvents } = await supabase
  .from("events")
  .select("id, parties!inner(title)")
  .eq("status", "scheduled")
  .like("parties.title", "[E2E]%")
  .limit(50);
```

- `parties.title`이 `[E2E]`로 시작하는 이벤트만 처리
- 비E2E 이벤트(피드용, 수동 생성)는 `scheduled` 상태 유지
- `simDiscoverAndApply`는 기존대로 비E2E 이벤트에도 참가 신청 → 피드에 참가자가 있는 자연스러운 이벤트

**파일**: `supabase/functions/backend-simulator/index.ts` (run phase 쿼리)

### Change 3: 피드 전시용 이벤트 생성

`create` phase에서 E2E 이벤트 외에 피드 전시용 이벤트를 추가 생성.

```ts
const DISPLAY_SCENARIOS = [
  { title: "강남 직장인 애프터워크 밍글", offset_days: 3 },
  { title: "홍대 대학생 주말 밍글", offset_days: 7 },
  { title: "성수 네트워킹 파티", offset_days: 14 },
  { title: "이태원 소셜 밍글", offset_days: 21 },
  { title: "압구정 프라이데이 밍글", offset_days: 30 },
];
```

- `[E2E]` 접두사 없음 → `run` phase 대상에서 제외
- 미래 날짜 (+3d ~ +30d) → 피드에 항상 노출
- `end_time` 지나면 자동 완료 크론이 처리
- 파티당 이벤트 2개 생성 (기존 E2E와 별도)
- 기존 시드 파트너의 로케이션 재사용

**파일**: `supabase/functions/backend-simulator/sim_create.ts` (신규 함수 `simCreateDisplayEvents`)

### Change 4: E2E 테스트 업데이트

기존 `e2e_test.ts`가 변경된 동작을 올바르게 검증하도록 업데이트.

**파일**: `supabase/functions/backend-simulator/e2e_test.ts`

## 영향 범위

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `supabase/migrations/20260404000001_auto_complete_past_events.sql` | 신규 | 자동 완료 크론 |
| `supabase/functions/backend-simulator/index.ts` | 수정 | run phase E2E 필터 |
| `supabase/functions/backend-simulator/sim_create.ts` | 수정 | 피드 전시용 이벤트 생성 추가 |
| `supabase/functions/backend-simulator/e2e_test.ts` | 수정 | 테스트 업데이트 |

## 기존 동작과의 호환성

- E2E 파이프라인 (create→approve→refund→run→settle): **변경 없음**. E2E 이벤트는 기존과 동일하게 전체 라이프사이클을 통과.
- `simDiscoverAndApply`: 비E2E 이벤트 참가 신청 유지. 피드 전시용 이벤트에도 참가자가 생겨 자연스러운 상태.
- Settlement 파이프라인: 자동 완료 크론이 `on_event_completed` 트리거를 발동 → 기존 settlement 로직 그대로 동작.
- `settlement-status-transition` 크론 (매일 3AM): 기존대로 PENDING → READY 전환.

## 리스크

| 리스크 | 확률 | 대응 |
|--------|------|------|
| Supabase `like` 필터가 inner join과 정확히 동작하지 않을 수 있음 | 낮음 | PostgREST 문서 확인 + 로컬 테스트 |
| 자동 완료 크론이 CUJ 테스트 중 이벤트를 완료시킬 수 있음 | 낮음 | E2E 이벤트는 미래 날짜(+12h~+30d)이므로 크론 영향 없음 |
| 기존 비E2E 이벤트가 run phase에서 누락됨 (의도된 변경) | - | 이전에는 비E2E도 처리됐으나, 이는 원래 설계 의도가 아님 |

## 태스크 분배

| 태스크 | 담당 | 내용 |
|--------|------|------|
| T1 | dev-1 | 자동 완료 크론 migration 작성 |
| T2 | dev-2 | `index.ts` run phase E2E 필터 + `sim_create.ts` 전시용 이벤트 생성 |
| T3 | dev-3 | `e2e_test.ts` 업데이트 + 전체 시뮬레이터 테스트 검증 |
| T4 | reviewer | 전체 코드 리뷰 |
