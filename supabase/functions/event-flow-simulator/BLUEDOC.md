# event-flow-simulator

유저·파트너 트래픽을 dev 에 5분 단위로 흘려 EF/스키마/트리거를 자동 검증하는 Supabase Edge Function.

## 단일 모드 — Stochastic Cascade

옛 phase / tick 분기는 v2 cascade 로 통합 삭제. 매 호출 = 작은 cascade 1회 실행.

## 호출 예시

```bash
curl -X POST "https://<project>.supabase.co/functions/v1/event-flow-simulator" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"ticks": 1, "usersPerTick": 5, "partnersPerTick": 2, "seed": 202605250905}'
```

응답 = `{ success, run_id, actors, trace_summary, violations, github_issue_url }`. 실패 시 reporter 가 자동 GH 이슈 생성.

## 폴더 구조

- `index.ts` — EF 진입점 (cascade 호출)
- `core/` — 엔진 (cascade, observable, trace, transport, snapshot, reporter, auth, types)
- `action/` — 8 액션 (apply/refund/checkin/discover/vote/block + partner_approve/reject/create_event)
- `policy/` — user/partner 가중 sampling 정책
- `params/` — 확률 데이터 (default.ts — happy 0.85-0.95 / critical negative 0.05-0.15)
- `invariant/` — cross-EF 규칙 registry (본 PR 인프라만, 실 invariant 정의는 follow-up RFC)
- `modes/` — 호출 패턴 wrapper (현재: tick.ts)

## 트리거 / 환경 가드

- target: `monitor-event-flow-distributed` 가 dev 에서 5분마다 작은 tick 실행 (하루 288회)
- legacy: `monitor-event-flow-hourly` / `monitor-event-flow-daily` 는 수동 smoke 전용
- **prod 차단**: auth-manifest `envs: ["dev","development","local"]` 가드, `minglitEdgeFunction` wrapper 가 enforce
- 필수 env: `SIM_USER_PASSWORD` (Fix #1508), `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`

## 핵심 컨벤션

- 시간은 고정 5분, 랜덤은 actor/user/partner/event sampling 에만 적용
- 유저는 `user-event-feed` EF 결과에서 신청 대상을 선택한다. 특정 party/event prefix 직접 필터 금지
- party/event/ticket 생성은 seed SQL 이 아니라 partner EF 경유
- `seed.dev.sql` 은 user / partner / permission / verification 같은 base actor 데이터만 담당
- 액션 실패 시 `sim_reporter` 가 자동 GH 이슈 생성
- 단위 테스트: `cd supabase/functions && deno test event-flow-simulator/`

## 한계 / 개선 계획
v2 **Stochastic Cascade** 모델은 도입됐지만 현재 구현은 `[E2E]` prefix snapshot 과 large daily run 흔적이 남아 있다. 다음 단계는 5분 distributed tick, actor random sampling, feed-driven apply, partner-EF-driven party/event generation 으로 정렬한다. 상세는 [architecture.md](./architecture.md).

---
_Reviewed: 2026-05-25 16:20_
