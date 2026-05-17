# event-flow-simulator

유저·파트너 트래픽을 시뮬레이션해 dev EF/스키마/트리거를 자동 검증하는 Supabase Edge Function.

## 단일 모드 — Stochastic Cascade

옛 phase / tick 분기는 v2 cascade 로 통합 삭제. 매 호출 = cascade 1회 실행.

## 호출 예시

```bash
curl -X POST "https://<project>.supabase.co/functions/v1/event-flow-simulator" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"ticks": 3, "usersPerTick": 10}'
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

- `monitor-tick-user.yml` 매시 :30 → `mode=tick` / `monitor-daily-lifecycle.yml` KST 07:00 → phase 6단계
- **prod 차단**: auth-manifest `envs: ["dev","development","local"]` 가드, `minglitEdgeFunction` wrapper 가 enforce
- 필수 env: `SIM_USER_PASSWORD` (Fix #1508), `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`

## 핵심 컨벤션

- `[E2E]` prefix 파티 + `user_` prefix 유저만 시뮬 대상 (실데이터 격리)
- 모든 쓰기 = EF 경유 (직접 DB DML 0건) — 실 트래픽 경로 충실 재현
- 액션 실패 시 `sim_reporter` 가 자동 GH 이슈 생성
- 단위 테스트: `cd supabase/functions && deno test event-flow-simulator/`

## 한계 / 개선 계획

v2 **Stochastic Cascade** 모델 (backend 를 확률적 funnel 로 모델링, invariant 1개로 N 시나리오 자동 가드) 도입 완료. 다만 실 invariant set 은 아직 미정의 — 진짜 minglit cross-EF 규칙 (money conservation, settlement coverage, match integrity 등) 은 별도 RFC 로 도입 예정. 상세는 [architecture.md](./architecture.md).

---
_Reviewed: 2026-05-17 22:32_
