# ef-integration-test Architecture

본 문서는 ef-integration-test 의 **설계 원리**, **framework 구성요소**, **CI 통합**, **coverage notification** 을 담는다. 진입점은 [BLUEDOC.md](./BLUEDOC.md).

---

## Part 1 — 목적

> **PR 머지 전에 EF 가 실 Postgres / trigger / RLS 와 만났을 때의 contract 위반을 잡는다.**

기존 layer 들 사이의 빈 칸을 채움:

- Layer 5 (Deno unit, mock supabase) — EF 내부 로직만. mock fetch 라 schema/trigger/RLS 가짜 동작 사용 → 실 DB 와 drift 발견 못 함
- Layer 7 (event-flow-simulator cascade) — 확률 분포 기반 long-running. PR 시간 안 맞음. dev 환경 의존
- **(신규) ef-integration-test** — 실 Postgres + 실 EF runtime + 외부 mock. deterministic. PR 마다 실행

---

## Part 2 — 단일 핵심 원칙

> **각 cujTest = 1 CUJ 가 충족됐는지 binary 검증. 통과 = CUJ holds, 실패 = CUJ broken.**

내부 assertion 구조는 자유. tier 시스템 / 정형 매처 강제 안 함. helper 는 반복 패턴이 5+ 발생 시 자연 추출.

이유:
- CUJ 자체가 검증 단위 — 추가 layer 가 의미 더하지 않음
- 작성자 (사람 / agent) 가 CUJ 의 expected behavior 를 직접 코드로 명시 → 의도 명확
- helper 사전 설계는 over-engineering — 실 사용 패턴이 나온 후 추출이 정확

---

## Part 3 — Framework 구성요소

5 모듈 (`_framework/` 하위), 변경 빈도 낮음:

### 3.1 `suite.ts` — local supabase + 파일 단위 lifecycle

```ts
export async function suite(featureKey: string): Promise<Ctx>
```

호출 시점에:
- supabase URL/keys 캡처 (`supabase status -o env`)
- admin client (service_role) 생성
- 파일 시작 시 `supabase db reset --no-seed` 보장 (한 번만)
- `Ctx` 반환 — actor / db / mock 진입점

`Ctx` 구조:
```ts
type Ctx = {
  db: AdminClient;                  // service_role, RLS 우회 (assertion 용)
  actAs: { user(id), partner(id) }; // Actor 생성
  // ... 내부 state
};
```

### 3.2 `cuj_test.ts` — Deno.test wrapper

```ts
export function cujTest(
  ctx: Ctx,
  id: string,              // "1-1 user consents and signs up"
  scenario: string,        // "fresh" | "user-with-paid-app" | ...
  fn: (ctx: Ctx) => Promise<void>,
): void
```

자동 처리:
- 시나리오 시드 (`scenarios[scenario]` 호출)
- 실패 시 `[CUJ <id>]` prefix 로 출력 — debugging trace
- 실패 시 마지막 EF response + DB diff dump

### 3.3 `actor.ts` — Actor 추상

```ts
class Actor {
  invoke(efName: string, body: unknown): Promise<{ status, data }>
  // JWT 토큰 캐싱, Authorization 헤더 자동
}
```

`ctx.actAs.user("u1")` → JWT 발급 (캐시) → `actor.invoke("apply-event", ...)` → 실 HTTP call to local edge runtime.

### 3.4 `scenario.ts` — 재사용 seed preset

```ts
export const scenarios = {
  fresh: () => {},                          // no seed, db reset 만
  "minimal-users": async (db) => { ... },  // 1 partner, 2 user
  "user-with-pending-app": async (db) => { ... },
  "user-with-paid-app": async (db) => { ... },
  "user-blocked-partner": async (db) => { ... },
  "checked-in-participants": async (db) => { ... },
  // ... 점진 확장 (~20 시나리오 상한)
};
```

각 CUJ test 가 골라 씀. cujTest 가 자동 호출.

### 3.5 `mock_external.ts` — 외부 API redirect

- **PortOne** — `PORTONE_API_URL` env 를 local `dev-mock-portone` EF 로 redirect
- **Statsig** — `STATSIG_SERVER_KEY` 미설정 → `_shared/statsig_utils.ts` 가 no-op
- **GitHub API** — event-flow CUJ 안 호출 (bug-report 도메인 외)

신규 외부 의존 추가 시 본 모듈에 처리 패턴 추가.

---

## Part 4 — CI 워크플로우

```yaml
# .github/workflows/ci-ef-integration.yml (예정)
name: ci-ef-integration

on:
  pull_request:
    paths: ['supabase/functions/**', 'supabase/migrations/**']
  workflow_dispatch:

jobs:
  integration:
    runs-on: [self-hosted, ephemeral]
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v6
      - uses: supabase/setup-cli@v2
      - uses: denoland/setup-deno@v2

      - run: supabase start                              # ~30-60s 1회
      - run: supabase db reset --no-seed                 # 마이그 적용
      - id: status
        run: |
          echo "service_role_key=$(supabase status -o env | grep SERVICE_ROLE_KEY | cut -d= -f2)" >> $GITHUB_OUTPUT

      - run: deno test --allow-all --no-parallel supabase/functions/_integration_tests/cuj/
        env:
          SUPABASE_URL: http://127.0.0.1:54321
          SUPABASE_SERVICE_ROLE_KEY: ${{ steps.status.outputs.service_role_key }}
          PORTONE_API_URL: http://127.0.0.1:54321/functions/v1/dev-mock-portone

      - name: CUJ coverage report
        if: always()
        run: deno run --allow-all supabase/functions/_integration_tests/_framework/coverage.ts > /tmp/coverage.md

      - name: Post coverage as PR comment
        if: github.event_name == 'pull_request' && always()
        uses: marocchino/sticky-pull-request-comment@v2
        with:
          path: /tmp/coverage.md
          header: cuj-coverage

      - if: always()
        run: supabase stop
```

성능 추정:
- supabase start: 30-60s
- 마이그 reset: 5-10s
- 테스트: ~2-3s/CUJ × 100 CUJ = 3-5분
- **전체 PR run: ~4-7분**

병렬화 가능 (`--parallel` + scenarios 격리) 한 장래 최적화.

---

## Part 5 — Coverage Notification

### 5.1 측정 항목

| 항목 | 출처 |
|---|---|
| **CUJ coverage** | `docs/features/<cat>/<feat>/spec.md` 의 CUJs 표 ID vs `cuj/<cat>/<feat>_test.ts` 의 Deno.test 이름 prefix |
| **EF coverage** | test 파일 frontmatter `@efs` (선택) 또는 런타임 trace (axiom 로그) |
| **Feature coverage** | feature 별 covered/missing CUJ 수 |

### 5.2 출력 (PR sticky comment)

```markdown
# CUJ Integration Coverage

| Feature | spec.md CUJs | Covered | Missing |
|---|---|---|---|
| account/signup-consent | 5 | 4 | `1-3` |
| event/refund-policy-v2 | 7 | 7 | (all covered) |
| event/event-edit-cancel | 4 | 0 | `1-1`, `1-2`, `2-1`, `2-2` |
```

### 5.3 gate 정책

초기엔 **정보만 게시**. 운영 데이터 축적 후 strict (놓친 CUJ → PR fail) 단계 고려.

---

## Part 6 — 트레이드오프

| 항목 | 결정 | 대안 |
|---|---|---|
| 격리 단위 | 파일 = suite, 테스트 = scenario | 매 테스트 reset (너무 느림) / transaction rollback (EF 가 HTTP 경계 넘으면 불가) |
| 병렬 | serial (`--no-parallel`) | 병렬 → DB state 충돌. supabase 인스턴스 1개 한계 |
| supabase 부팅 | 워크플로우 시작 시 1회 | 매 테스트 부팅 비현실적 |
| assertion 구조 | 자유 (tier 없음) | helper tier — over-engineering |
| 외부 mock 위치 | `_framework/mock_external.ts` 단일 | per-EF mock 분산 — 추적 어려움 |
| Coverage gate | 정보만 (초기) | strict fail (놓친 CUJ) — 운영 후 고려 |

---

## Part 7 — 인접 layer 와의 관계

| Layer | 책임 분리 |
|---|---|
| `_payment_integration_tests/` | in-process EF chaining + 전체 mock (실 DB 없음). 본 framework 와 다른 layer, 공존 |
| `event-flow-simulator/` | Layer 7 cascade — 확률 분포, long-running, dev 환경. 본 framework 는 deterministic, PR-time |
| Layer 5 (Deno unit) | EF 내부 로직 mock 테스트. 본 framework 는 실 schema/trigger/RLS contract |
| Layer 4 (pgTAP) | DB schema/RPC/RLS 직접 검증. 본 framework 는 EF 경로 통과 시의 통합 동작 |

---

## Part 8 — 도입 단계 (예정)

| # | 작업 | 기간 |
|---|---|---|
| 1 | `_framework/` 5 모듈 작성 + minimal scenarios 5개 | 1주 |
| 2 | 첫 CUJ test 시범 — `cuj/account/signup_consent_test.ts` 1 파일 | 2-3일 |
| 3 | CI 워크플로우 `ci-ef-integration.yml` 추가 (self-hosted Docker 안정화 선행) | 2-3일 |
| 4 | coverage.ts + PR 코멘트 통합 | 2-3일 |
| 5 | 점진 확장 — feature 별 cuj/<cat>/<feat>_test.ts 작성 | 지속 |

---

## 형제 문서

- [BLUEDOC.md](./BLUEDOC.md) — 진입점
- [README.md](./README.md) — 로컬 실행 빠른 가이드 (예정)
- [features/BLUEDOC.md](../../../docs/features/BLUEDOC.md) — PRD / spec.md / CUJ ID 컨벤션
- [edge-functions.md](../../../docs/operations/edge-functions.md) — EF 운영 / 디버깅
- [event-flow-simulator/architecture.md](../event-flow-simulator/architecture.md) — Layer 7 cascade 모델
