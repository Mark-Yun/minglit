# backend-simulator

유저·파트너 트래픽을 시뮬레이션해 dev EF/스키마/트리거를 자동 검증하는 Supabase Edge Function.

## 두 모드 (`index.ts` 의 `mode` 분기)

| 모드 | 호출 | 동작 |
|---|---|---|
| `phase` (default) | `{"phase": "create|approve|refund|run|settle|verify"}` 또는 빈 body | 6 단계 직렬 시뮬 (옛, **2026-04-26 deprecated** — PR #1355 의 2주 안정 운영 시한 경과) |
| `tick` | `{"mode": "tick"}` | DB 상태 기반 행위자(actor) 시뮬 — 매 호출마다 partner/user 가 자율 액션 생성·실행 |

## 호출 예시

```bash
curl -X POST "https://<project>.supabase.co/functions/v1/backend-simulator" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"mode":"tick"}'
```

## 폴더 구조

- `index.ts` — EF 진입점 (mode 분기)
- `sim_{auth,reporter,assertions,types}.ts` — 공용
- `sim_{create,approve,refund,event,settle}.ts` — Phase 모드 모듈
- `tick/` — Tick 모드 (`sim_tick.ts` orchestrator + `action_runner.ts` + `sim_action.ts` 베이스 + `actions/` 8종 + `factories/` partner/user)

## 트리거 / 환경 가드

- `monitor-tick-user.yml` 매시 :30 → `mode=tick` / `monitor-daily-lifecycle.yml` KST 07:00 → phase 6단계
- **prod 차단**: auth-manifest `envs: ["dev","development","local"]` 가드, `minglitEdgeFunction` wrapper 가 enforce
- 필수 env: `SIM_USER_PASSWORD` (Fix #1508), `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`

## 핵심 컨벤션

- `[E2E]` prefix 파티 + `user_` prefix 유저만 시뮬 대상 (실데이터 격리)
- 모든 쓰기 = EF 경유 (직접 DB DML 0건) — 실 트래픽 경로 충실 재현
- 액션 실패 시 `sim_reporter` 가 자동 GH 이슈 생성
- 단위 테스트: `cd supabase/functions && deno test backend-simulator/`

## 한계 / 개선 계획

현재 구조의 본질적 한계 (EF 커버리지 15%, tick 모드 invariant 0, PGMQ 파급 미추적, 데모급 규모) 와 v2 설계 제안은 [architecture.md](./architecture.md) 참조.
