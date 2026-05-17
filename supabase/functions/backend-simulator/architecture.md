# backend-simulator Architecture

본 문서는 `backend-simulator` EF 의 **목적**, **추상화 모델 (v2)**, **폴더 구조**, **마이그레이션 단계** 를 담는다. 진입점은 [BLUEDOC.md](./BLUEDOC.md).

---

## Part 1 — 목적 (What this simulator exists for)

### 1차 목적
> **PR 머지 전에 backend 비즈니스 규칙 위반을 잡는다.**

예: "user 가 partner 를 block 한 후 refund 시도 → EF 가 거부해야 함" 같은 **여러 EF 호출이 엮여서 emerge 하는 규칙**. 단일 EF 단위 테스트로는 잡히지 않고, production 에서야 발견되는 부류.

### 2차 목적
- **Dev DB 의 다양한 상태 사전 준비** (paid, refunded, blocked, matched, no-show ...) — manual QA 시 발견 비용 ↓
- **회귀 차단** — 핵심 flow (refund, matching, settlement) 가 코드 변경으로 깨지면 즉시 알림
- **확장성** — 신규 EF 추가 시 시뮬 커버가 거의 자동

### 명시적으로 *아닌* 것
- Production 시스템 (dev 전용 — `auth-manifest` envs 가드)
- Load testing 도구 (latency 측정 ≠ correctness 검증)
- UI 테스트 (Patrol/Alchemist 가 그 layer)

---

## Part 2 — 핵심 추상화: Stochastic Cascade (v2)

### Mental Model

> **Backend = state transition machine. 각 EF = 하나의 valid transition. Actor = 자기 observable state 를 보고 다음 transition 을 확률적으로 sampling 하는 정책.**

```
[impression]    ──p≈0.10──→ [feed view]
[feed view]     ──p≈0.30──→ [event detail view]
[event detail]  ──p≈0.50──→ [application submitted]   ← EF: apply-event
[application]   ──p≈0.95──→ [paid]                    ← EF: payment-confirm
                ──p≈0.05──→ [cancelled]
[paid]          ──p≈0.10──→ [refund requested]        ← EF: user-cancel-order  (critical)
                ──p≈0.85──→ [checked-in]              ← EF: event-checkin
                ──p≈0.05──→ [no-show]
[checked-in]    ──p≈0.60──→ [voted]                   ← EF: user-cast-vote
[voted]         ──p=mutual→ [matched]                 (trigger emergent)
```

각 화살표 = EF 호출 + 확률 게이트. cascade 가 funnel 자체를 모델링.

### 왜 이 추상화가 옳은가

| 다른 접근 | 한계 |
|---|---|
| Scenario 선언 (각 multi-step 케이스 손코딩) | 시나리오 N 개 작성 비용 = N. 빠진 조합은 영원히 안 잡힘 |
| Property-based random fuzz | 도메인 모르고 무작위 → invalid state 많아 효율 낮음 |
| **Stochastic Cascade** | 도메인 funnel 의 isomorphic 모델. 확률 분포 안에서 actor 가 합리적 행동 → cross-EF 조합 자동 탐색. invariant 1개 = N 시나리오 가드 |

### Cross-EF 버그가 emerge 하는 메커니즘

너 예시 (`block → refund` 거부 위반) 자동 검증:

1. User policy 가 매 cascade step 에서 `block_partner` (확률 ~0.05) 와 `refund` (paid 보유 시 ~0.10) 를 독립 sampling
2. 10K simulated user × N tick 돌리면 — 통계적으로 수십 명이 "block 후 같은 partner event refund" 경로 자연 진입
3. 만약 EF 가 잘못해서 환불 허용 → 다음 invariant 가 위반 잡음:

```sql
-- invariant: blocked_partner_refund_denied
SELECT a.id FROM event_applications a
JOIN refunds r ON r.application_id = a.id
JOIN events e ON e.id = a.event_id
JOIN parties p ON p.id = e.party_id
WHERE EXISTS (
  SELECT 1 FROM social_interactions s
   WHERE s.user_id = a.user_id
     AND s.target_id = p.partner_id
     AND s.interaction_type = 'block'
     AND s.created_at < r.created_at
)
```

**시나리오 따로 안 적음**. policy + invariant 만 있으면 random walk 가 자동으로 조합 탐색.

### 확률 파라미터 철학

- **Happy path 위주** — apply→pay, paid→checkin, partner approve 같은 정상 흐름은 0.85 ~ 0.95
- **Critical negative slightly 높임** — refund, block, payment_fail, reject 같은 cross-EF 가드 영역은 0.05 ~ 0.15 (happy 보다 낮지만 매 cascade 에 sampling 되도록 0 아님)
- **Chaos mode** (`params/stress.ts`) 는 critical negative 를 0.30 ~ 0.50 으로 의도 과샘플링 → 야간/주말 stress run 에서 cross-EF invariant 위반 가시화
- 절대값보다 운영 데이터 fit 방향 우선

---

## Part 3 — 폴더 구조 (v2 목표 상태)

```
backend-simulator/
├── index.ts              # EF 진입점 (mode → runtime 호출)
├── BLUEDOC.md
├── architecture.md
│
├── core/                 # cascade 엔진 (변경 빈도 낮음)
│   ├── policy.ts         # Policy = (observableState, rng) → Action 타입
│   ├── observable.ts     # role 별 observable state 정의 (RLS-like 격리)
│   ├── cascade.ts        # tick loop: sample → call EF → update state → record trace
│   ├── trace.ts          # event sourcing 로그 (모든 transition 기록)
│   ├── replay.ts         # seed + initial state → 동일 cascade 재현
│   └── runner.ts         # 위 4개 묶어서 모드별 실행
│
├── action/               # WHAT — EF 별 transition 정의 (1 EF = 1 파일)
│   ├── _registry.ts      # 등록 + manifest 매핑 (점진 자동화 target)
│   ├── apply.ts          # canApply(state) + buildPayload(state, rng) + onSuccess hook
│   ├── refund.ts
│   ├── block.ts
│   ├── approve.ts
│   └── ... (8 → ~55 점진 추가)
│
├── policy/               # WHO — actor 별 의사결정
│   ├── user.ts           # function user(observable, rng): Action — 가능 액션 가중 sampling
│   ├── partner.ts
│   └── system.ts         # cron / 시간 전진 행위
│
├── params/               # HOW MUCH — 확률 파라미터 (데이터, 코드 X)
│   ├── default.ts        # production-like rates (Part 2 의 확률 철학)
│   ├── happy.ts          # smoke (critical negative 거의 0)
│   ├── stress.ts         # chaos (critical negative 0.30+)
│   └── seed.ts           # dev DB 채우기용 (다양성 ↑)
│
├── invariant/            # WHY — cross-EF 비즈니스 규칙 검증
│   ├── _registry.ts
│   ├── money.ts          # 결제 합 ≈ 환불 + 정산 + 미정산
│   ├── blocking.ts       # blocked partner 에 환불/매칭/notification 안 감
│   ├── matching.ts       # mutual vote 만 match
│   ├── lifecycle.ts      # event status 전이 규칙 (scheduled→active→ongoing→completed)
│   └── pgmq.ts           # PGMQ 큐 무결성 (depth, DLQ, enqueue/consume balance)
│
└── modes/                # 호출 패턴 — params × cascade depth 조합
    ├── tick.ts           # hourly :30 — short cascade, default params
    ├── pr-gate.ts        # PR CI — medium cascade, default params, 모든 invariant
    ├── stress.ts         # 야간/주말 — chaos params, invariant 위반 → 자동 issue
    └── seed.ts           # 수동 1회성 — large cascade, seed params로 dev DB 채움
                          #   ⚠️ 초기 fixture (partners, base users) 는 SQL seed 가 박음.
                          #   EF 직접 시딩은 과거 timeout 사건으로 금지 (Fix #1413).
```

### 옛 phase 모드 처리

`sim_create.ts`, `sim_approve.ts`, `sim_refund.ts`, `sim_event.ts`, `sim_settle.ts` 는 v2 마이그 완료 시 **삭제 대상**. cascade `modes/seed.ts` + `modes/pr-gate.ts` 가 동일 기능 cover (실제로는 더 넓음).

---

## Part 4 — 마이그레이션 단계 (ROI 순)

| # | 단계 | 작업 | 기간 | 검증 |
|---|---|---|---|---|
| 1 | core 엔진 PoC | `core/policy.ts`, `core/observable.ts`, `core/cascade.ts` 작성 + 단순 cascade (apply 1단계) 동작 | 1주 | 단위 테스트 |
| 2 | 액션 마이그 | 기존 8 SimAction → `action/*.ts` 8 파일. 기존 *_test.ts 유지 | 1주 | 기존 deno test 통과 |
| 3 | policy + params | `policy/user.ts`, `policy/partner.ts`, `params/default.ts` 작성 | 3-4일 | small cascade run → 액션 발생 검증 |
| 4 | invariant 초기 set | money / blocking / matching / lifecycle / pgmq 5개 invariant 정의 (SQL + JS) | 1주 | stress params 로 의도적 위반 → 잡히는지 검증 |
| 5 | `modes/tick.ts` | 얇은 wrapper. 기존 hourly :30 cron 동작 보장 | 2일 | 1회 dispatch → 기존과 동등 결과 |
| 6 | `modes/pr-gate.ts` + CI | PR 머지 전 cascade 실행 + invariant 위반 시 PR 차단 | 2-3일 | 의도된 회귀 PR 1개로 차단 검증 |
| 7 | `modes/seed.ts` + phase 삭제 | dev DB 시딩 (단, 초기 fixture 는 SQL seed 사용 — EF 타임아웃 우회). 옛 phase 모드 5 파일 삭제 | 3-4일 | seed 1회 실행 후 dev 상태 다양성 측정 |
| 8 | `modes/stress.ts` | chaos params + invariant 위반 → GH 이슈 자동 생성 | 3일 | 야간 stress run → 알림 도착 검증 |
| 9 | shallow / deep 분리 | 흥미로운 tier 만 실 EF 호출 + 나머지 in-memory → 운영 트래픽급 규모 시뮬 가능 | 1주 | 시뮬 시간 / 비용 측정 |
| 10 | 문서 + 마이그 가이드 | architecture.md 보강, 신규 EF 추가 가이드 | 2-3일 | — |
| **합계** | | | **~5-6주** | |

---

## Part 5 — 기능 사양 (오버킬 OK 라고 한 영역)

### 5.1 Cascade Trace 기록

매 transition = event sourcing log:
```json
{ "tick": 42, "actor": "user-abc", "action": {"kind":"refund", "app":"a-1"},
  "ef_status": 403, "trace_id": "...", "rng_state": "..." }
```

위반 발생 시 직전 N step + DB diff 자동 출력. 디버깅 비용 ↓.

### 5.2 PRNG Splitting (재현성)

PRNG 를 splittable (e.g., splitmix) 로 — 액터별 독립 시드, 전체는 reproducible. 실패 trace → seed + step index 로 로컬 재현.

### 5.3 Invariant Shrinking

깨진 cascade trace 가 200 step 이면 디버그 어려움. Hypothesis 스타일 shrinking → "위반 최소 step 시퀀스" 자동 추출 (~5-10 step) → 디버그 비용 더 ↓.

### 5.4 Daily Trajectory Diff

main 머지 직후 cascade 결과 (같은 seed 로) vs 이전 결과 diff → "이 PR 이 cascade 분포에 어떤 영향을 줬는지" 가시화. 회귀 추가 알림.

### 5.5 Self-Documenting Invariant Catalog

매 PR 시 `invariant/*.ts` 의 모든 invariant → markdown 자동 생성 → `docs/qa/invariant-catalog.md`. "현재 가드 중인 비즈니스 규칙" 항상 최신.

---

## Part 6 — 기존 컴포넌트 매핑

| 현재 | v2 매핑 |
|---|---|
| `SimAction` 추상 클래스 + 8 구현 | `action/*.ts` 8 파일 (canExecute + buildPayload + onSuccess) |
| `PartnerActionFactory` / `UserActionFactory` | `policy/partner.ts` / `policy/user.ts` (가중치 + observable state) |
| `ActionRunner` | `core/cascade.ts` 의 한 부분 |
| `tick/sim_tick.ts` orchestrator | `modes/tick.ts` (얇은 wrapper) |
| `sim_assertions.ts` (phase 전용) | `invariant/*.ts` 로 이전 + 확장 |
| 옛 phase 모드 (`sim_create.ts` 등) | **삭제** — `modes/seed.ts` + `modes/pr-gate.ts` 가 대체 |
| `sim_reporter.ts` (GH 이슈 생성) | 유지 + invariant 위반 reporter 추가 |

---

## Part 7 — 트레이드오프 / 한계

| 항목 | 비용 |
|---|---|
| 마이그 비용 | ~5-6주 (Part 4) |
| 학습 곡선 | DES, property-based testing 패턴 — 신규 합류자 onboarding 필요 |
| Invariant 작성 부담 | 비즈니스 규칙 1개 = invariant 1개 작성. 누가 책임? |
| Cascade 비결정성 | PRNG seed 로 reproducible 보장하지만 "왜 이 cascade 가 이 분포?" 직관 떨어짐 |
| seed 모드의 SQL 의존 | EF 시딩 안전 도달 전까지는 SQL fixture + cascade 두 단계 — 약간 복잡 |
| 신규 EF 자동 등록 | manifest 확장 (`requestSchema` 추가) 선행 필요 — 별도 RFC |

이전에 검토한 다른 접근들의 거부 이유:
- **Scenario 선언** — 시나리오 N 개 손코딩 비용 + 빠진 조합 영원히 안 잡힘 (user 명시 거부)
- **v2 7-Stack** — 학문적 미학에 치우침, YAGNI 위반, "Layer" 단어가 `docs/qa/test-strategy.md` 7-Layer 와 충돌

---

## 형제 문서

- [BLUEDOC.md](./BLUEDOC.md) — 본 디렉토리 진입점, 모드 / 폴더 구조
- [docs/architecture/backend.md](../../../docs/architecture/backend.md) — 전체 Supabase 백엔드
- [docs/architecture/global-event-pipeline.md](../../../docs/architecture/global-event-pipeline.md) — PGMQ 2-tier (invariant/pgmq.ts 참조)
- [docs/qa/test-strategy.md](../../../docs/qa/test-strategy.md) — 7-Layer test taxonomy (본 EF = Layer 7)
- [docs/operations/edge-functions.md](../../../docs/operations/edge-functions.md) — EF 디버깅 (axiom, sentry)
