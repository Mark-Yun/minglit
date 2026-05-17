# backend-simulator Architecture

본 문서는 `backend-simulator` EF 의 **현재 구조의 한계** 와 **v2 재설계 제안** 을 담는다. 진입점은 [BLUEDOC.md](./BLUEDOC.md).

---

## Part 1 — 목적 vs 현재 충족도

### 명시된 목적

1. **EF 테스트** — 모든 Edge Function 의 happy path / 실패 경로 자동 호출
2. **스키마 검증** — 테이블 constraint, generated column, FK, RLS 동작 가드
3. **DB 트리거 검증** — PGMQ 2-tier event pipeline, DB trigger, pg_cron 잡의 부수 효과 추적
4. **규모 시뮬** — race condition, lock contention, P99 latency degradation 노출

### 충족도 (4축)

| 축 | 현재 | 정량 |
|---|---|---|
| EF coverage | 손코딩 8 액션 = 8 EF | **8/~55 ≈ 15%** (전체 EF 디렉토리 59개 중 `_shared`, `_test_utils` 제외) |
| 스키마 invariant | EF 가 어쩌다 위반 시만 잡힘 (passive) | **tick 모드 0 명시 invariant** (phase 모드의 `sim_assertions.ts` 는 settlement·participant·refund 일부 보유) |
| 비동기 파급 / 트리거 부수 효과 | EF 직접 결과만 검증 | **0** — PGMQ enqueue/consume, DB trigger side effect, cron 전이 미검증 |
| 규모 | hourly 5-30 액션 / 일 ~800 액션 | **데모급** — race 0건 노출 가능 |

> **어휘 정합**: 본 문서의 "비동기 파급" = BLUEDOC 의 "트리거" = EF 호출 후 DB trigger / PGMQ worker / pg_cron 이 발생시키는 후속 효과. 동일 개념의 다른 표현.

### 현재 운영 마일스톤 (2026-05-17 기준)

| 시점 | 상태 |
|---|---|
| 2026-04-12 (PR #1355) | tick 모드 도입 — 0 actions / run 으로 기동 |
| 2026-04-15 (PR #1468) | hourly 워크플로우를 tick 모드로 전환 (옛 phase hourly 와 공존) |
| 2026-05-16 (PR #2456) | `user_event_feed` RPC 의 `pr.status` dead reference 제거 → tick 이 feed 받아 액션 생성 가능 |
| 2026-05-16 (PR #2461) | `validStatuses` 에 `'approved'` 추가 (Fix #1660 drift) → 무료 이벤트 apply 정상 처리 |
| 2026-05-17 시점 | tick run 당 5 actions 생성, 모두 EF 200 + DB row 생성 성공 — **본격 작동 진입** |

### 결과적 위험

- 신규 EF 50개 추가 시 시뮬 커버 0 (수동 SimAction 작성 비용)
- PGMQ worker 가 깨져도 tick 통과 — 비동기 파이프라인 깨짐 미감지
- pg_cron 잡 (`activate-upcoming-events` 등) 검증 불가 — 5-state event machine 의 자동 전이 미가드
- 부하 시 query plan degradation / connection pool 고갈 미검출

---

## Part 2 — v2 설계 (5축 강화)

### A. Manifest-Driven Action Generation

**현재**: `tick/actions/*.ts` 8개 손코딩. 신규 EF = 신규 클래스.

**v2 (선행 작업 필요)**: `auth-manifest.json` 의 각 EF 에서 자동 액션 등록. 다만 **현 manifest 스키마는 `callers`, `envs`, `description` 만 가짐** — `requestSchema` 필드가 없음. 본 축 도입은 다음 두 단계:

1. **auth-manifest 확장 RFC** — 각 EF 에 `requestSchema` (JSON Schema) + `role` 필드 추가. 50+ EF 의 schema 정의는 별도 작업
2. 자동 등록 코드:

```ts
// 각 EF spec 의 requestSchema 로 fast-check generator 생성 → valid payload 합성
for (const [efName, spec] of Object.entries(authManifest.functions)) {
  if (!spec.envs.includes('dev')) continue;
  registerAction({
    ef: efName,
    role: spec.role,                           // ← manifest 확장 필요
    payloadGen: jsonSchemaToArbitrary(spec.requestSchema),  // ← manifest 확장 필요
  });
}
```

신규 EF 추가 → manifest 갱신만으로 자동 커버. **8 → ~55 EF**.

### B. Schema Invariant Layer

**현재**: per-action assertion (EF 호출 직후 row 존재 + status).

**v2**: 매 tick 종료 시 전역 invariant RPC 호출.

> **기존 `check_db_invariants()` 와의 관계**: 별도 layer 로 이미 존재 (`monitor-db-invariants.yml` 매시간 cron, `docs/qa/test-strategy.md` Layer 6 = "DB monitor"). 본 v2 의 `sim_check_invariants()` 는 **tick run 단위** 에서 호출되어 **시뮬 액션 직후** 상태를 검증 — `check_db_invariants()` 의 매시간 스냅샷과 시간축 / 책임이 다름. 두 RPC 가 공통 invariant 정의를 공유하면 SoT 단일화 가능 (개선 작업의 부수 효과).

```sql
CREATE FUNCTION sim_check_invariants() RETURNS TABLE(invariant text, violations jsonb) AS $$
  SELECT 'paid_has_payment', jsonb_agg(a.id)
    FROM event_applications a
    LEFT JOIN payments p ON p.application_id = a.id
   WHERE a.status = 'paid' AND p.id IS NULL
  HAVING count(*) > 0
  UNION ALL
  SELECT 'slots_consistent', jsonb_agg(e.id)
    FROM events e
   WHERE e.remaining_slots != e.max_participants - e.current_participants
  HAVING count(*) > 0
  UNION ALL
  -- ... 그 외 도메인 invariant
$$;
```

추가: **negative test 액션** — 의도적으로 invalid payload, FK 위반, RLS 우회 시도 → 가드 동작 확인.

### C. PGMQ 파급 추적

**현재**: EF 직접 결과만 본다.

**v2**: 액션 검증 단계에 PGMQ enqueue/consume assertion 추가. 사용 함수는 PGMQ 확장의 표준 API (`pgmq.read`, `pgmq.metrics`).

```ts
await action.execute();

// 큐에 메시지 enqueue 됐는지 — read 후 즉시 visibility 복귀 (vt=1초)
const messages = await supabase.schema('pgmq').rpc('read', {
  queue_name: 'event_pipeline',
  vt: 1,
  qty: 10,
});
assert(messages.some(m => m.message.event_type === 'application_created'));

await sleep(2000);  // worker 처리 대기

// DLQ / queue depth 확인
const metrics = await supabase.schema('pgmq').rpc('metrics', { queue_name: 'event_pipeline_dlq' });
assert(metrics.queue_length === 0);
```

worker 가 깨지거나 DLQ 가 누적되면 tick 즉시 실패. 참조: [docs/architecture/global-event-pipeline.md](../../../docs/architecture/global-event-pipeline.md).

### D. 시간 가속 (cron 시나리오)

**현재**: pg_cron 잡 동작 검증 불가 (실시간 의존).

**v2**: simulated clock advance RPC + cron 잡 수동 트리거.

```ts
await supabase.rpc('sim_advance_time', { interval: '35 minutes' });
await supabase.rpc('activate_upcoming_events');  // cron 잡 수동 호출
const snap = await snapshot();
assert(snap.events
  .filter(e => e.start_time < now() + 30*MIN)
  .every(e => e.status === 'active'));
```

5-state event machine (`scheduled → active → ongoing → completed`) 자동 전이 가드.

### E. 규모 (3 모드 분리)

| 모드 | 빈도 | 액션/run | 목적 |
|---|---|---|---|
| `tick` (현재) | 매 hourly :30 | ~5-30 | 스모크, 회귀 가드 |
| `soak` (신규) | 주 1회 | ~3,000 (Poisson λ=2/min × 50 유저 × 30분) | latency P50/P99, connection pool watermark |
| `spike` (신규) | PR 머지 시 (옵션) | ~200 (1분 burst) | race condition, deadlock |

`[E2E-SOAK]` prefix 로 데이터 격리. 핵심 metric 은 별도 axiom 대시보드.

---

## Part 3 — v2 Internal 7-Stack 미래 비전 (선택)

> **이름 주의**: 본 7-Stack 은 **backend-simulator EF 내부 컴포넌트 적층** 을 의미. `docs/qa/test-strategy.md` 의 "7-Layer test taxonomy" (Patrol/Emulator/.../Tick simulator) 와는 별개 개념. 후자의 Layer 7 = 본 EF 전체 = 본 7-Stack 의 호스트.

위 5축이 "목적 충족" 이라면, **아키텍처 미학** 의 이상은 다음 7-tier 분리:

```
Tier 7  Differential Analyzer    (PR 단위 trajectory diff)
Tier 6  Invariant Monitor        (safety + liveness, TLA+ 스타일)
Tier 5  Trace Recorder           (event sourcing, replay)
Tier 4  Scheduler                (DES, simulated clock, Poisson 도착)
Tier 3  Policy Sampler           (pure: snapshot × actor × prng → action distribution)
Tier 2  World Snapshot           (single RPC → frozen state, in-memory)
Tier 1  Capability-Typed Executor (phantom type 으로 actor-action 매칭 강제)
```

### 핵심 아이디어

- **Action as Data** — `type Action = { kind, actor, ...payload }`. 직렬화/replay/event sourcing 자연스러움
- **Policy as Distribution** — `(state, actor, prng) → Distribution<Action>`. parameter sweep, A·B 정책 비교 가능
- **Snapshot 1회 RPC** — DB round-trip O(actors × queries) → O(1). 시뮬 자체가 pure 로 격하 → unit-testable
- **Capability Types** — `SimToken<R extends Role>` 으로 actor↔action 짝 매칭 compile-time 강제
- **Trace Replay** — seed + snapshot_hash 로 동일 시나리오 로컬 재현. failure bisect 자연스러움

### 트레이드오프

- 마이그 비용: 1-2 주 (8 액션 + 2 factory 재작성)
- 학습 곡선: DES, property-based testing, capability types 익숙해야 함
- Snapshot RPC 단일 장애점 (현재는 factory 별 부분 실패 가능)
- Premature abstraction 위험: 현 규모에 over-engineering 가능

---

## Part 4 — 우선순위 (ROI 순)

| # | 작업 | 기간 | 효과 |
|---|---|---|---|
| 1 | **C — PGMQ 추적** | 1주 | minglit 핵심 의존인 PGMQ 의 검증 공백 해소 (가장 큰 가시성 gap) |
| 2 | **B — Schema Invariant** | 3-4일 | 한 RPC 추가로 즉시 가드 강화 |
| 3 | **A — Manifest-Driven** | 2주 + manifest 정비 | 신규 EF 추가 비용 ↓ (16% → ~95%) |
| 4 | **D — 시간 가속** | 1주 | cron 잡 검증 가능 |
| 5 | **E — soak/spike 모드** | 2-3주 | 규모/race 검출 (다른 4개 끝난 뒤) |
| 6 | **v2 Internal 7-Stack 재설계** | 1-2달 | 위 1-5 완료 후 본질적 미학 추구 시 |

---

## 형제 문서

- [BLUEDOC.md](./BLUEDOC.md) — 본 디렉토리의 진입점, 현재 폴더 구조 / 모드 설명
- [docs/architecture/backend.md](../../../docs/architecture/backend.md) — 전체 Supabase 백엔드 아키텍처 (50 테이블, EF, RLS, trigger)
- [docs/architecture/global-event-pipeline.md](../../../docs/architecture/global-event-pipeline.md) — PGMQ 2-tier 파이프라인 (Layer C 참조)
- [docs/operations/edge-functions.md](../../../docs/operations/edge-functions.md) — EF 디버깅 (axiom, sentry)
