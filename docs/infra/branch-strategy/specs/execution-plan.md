# Execution Plan

현재 `.github/workflows/` 상태를 분석하고, [workflow-spec.md](./workflow-spec.md) + [branch-spec.md](./branch-spec.md) 로 *어떻게 점진적으로 전환할지* 의 단일 source. **구현 PR 들의 base 문서**.

## 현재 state (workflow 인벤토리)

`.github/workflows/` = **30 파일**. 분류:

| 카테고리 | 파일 | 본 모델과의 관계 |
|----------|------|------------------|
| **Deploy** | `deploy-android-{user,partner}`, `deploy-ios-{user,partner}`, `deploy-supabase`, `deploy-vercel`, `deploy-dev-seed`, `shared-android-deploy` | spec 의 deploy 부분 — 재사용 + trigger refactor |
| **PR / Review** | `pr-gate`, `pr-review-setup`, `doc-freshness` | spec 의 pr-gate-core 의 base — 추출·일반화 대상 |
| **Post-merge** | `post-merge` (dev push orchestrator), `sync-version`, `sync-pr-branches`, `sync-test-coverage`, `sync-mds-mockups`, `sync-graphify` | spec 의 `*-post-merge-sync` 의 base — 부분 흡수 |
| **Reusable** | `shared-android-deploy`, `shared-cuj-integration`, `shared-notify` | spec 의 reusable 패턴 — 추가 reusable extract 시 참고 |
| **Monitor** | `monitor-allure`, `monitor-cuj-coverage`, `monitor-db-invariants`, `monitor-deno-coverage`, `monitor-event-flow-*`, `monitor-mds-render-coverage`, `monitor-patrol-e2e` | 본 release pipeline 과 orthogonal — 유지 |
| **Triage** | `triage-mds-issue`, `triage-slash` | 동상 — 유지 |

> `post-merge.yml` 주석에 *"single push:dev entry point for follow-up automation that previously lived in 5 separate workflows"* — 이미 orchestrator 패턴이 도입돼있음. 우리 spec 도 비슷한 방향 (`*-post-merge-sync` entry workflow 가 reusable 호출).

## Existing → Spec mapping

| Spec workflow | 기존 매핑 | 작업 분류 |
|---------------|----------|----------|
| `pr-gate-core` (reusable) | `pr-gate` 의 step 들을 reusable workflow_call 로 추출 + stage parameter 추가 | **refactor** |
| `version-bump` (reusable) | `sync-version` 의 핵심 로직 → reusable 분리 | **refactor** |
| `rc-gate-suite` (reusable) | 기존 `monitor-patrol-e2e`, `monitor-cuj-coverage` 등을 통합해 reusable suite 구성 | **신규 (조합)** |
| `auto-issue` (reusable) | (없음) | **신규** |
| `backport-pr` (reusable) | (없음) | **신규** |
| `dev-staging-pr-gate` | `pr-gate` 를 dev-staging base 로 재사용 (stage=dev-staging) | **신규 (얇은 wrapper)** |
| `dev-staging-post-merge-sync` | `post-merge` + `sync-version` orchestration | **신규 (조합)** |
| `nightly-cut` | (없음) | **신규** |
| `nightly-pr-gate` | `dev-staging-pr-gate` 와 동일 (stage=nightly) | **신규 (얇은 wrapper)** |
| `rc-gate` | (없음) — rc-gate-suite 호출 + status set + deploy chain | **신규** |
| `rc-cut`, `rc-pr-gate`, `rc-post-merge-sync`, `rc-soak-check`, `rc-hotfix-backport` | (모두 없음) | **신규** |
| `main-pr-gate`, `main-post-merge-promote` | (없음, 부분적으로 `sync-version`) | **신규 + refactor** |
| `deploy-supabase` | 그대로 + trigger refactor (rc-gate-pass + push:main) | **trigger refactor** |
| `deploy-vercel` | 그대로 + trigger refactor (cron 폐기 → rc-gate-pass + push:main) | **trigger refactor** |
| `deploy-android-{user,partner}`, `deploy-ios-{user,partner}` | 그대로 (이미 push:main trigger) | **변경 없음** |
| `deploy-dev-seed` | 본 spec scope 밖 (dev 환경 seeding) | **변경 없음** |

**요약**: 신규 ~13개, refactor ~5개, 변경 없음 ~5개 (monitor/triage 제외).

## Phase 1: 브랜치 skeletal 셋업

**위험도**: 낮음. CI 변경 없음.

### Steps

1. `dev-staging` branch 생성 (현 `dev` 에서 cut)
2. dev-staging 에 **최소 protection** 만 (deletion 금지, force push 금지) — required check 없음 (workflow 없으니까)
3. `dev-staging` 의 README 또는 PR template 에 안내
4. agent / 개발자가 dev-staging 으로 PR 시도 (수동 dry-run)

### Rollback

- `dev-staging` branch 삭제. dev/main 그대로 작업.

### 결정

- 어느 시점에 default branch 를 dev-staging 으로 바꿀지 (Phase 4 까지 dev 유지)

## Phase 2: Workflow refactor

**위험도**: 중간. 기존 PR 흐름에 영향 가능.

### Steps (순차)

| Step | 작업 | 영향 |
|------|------|------|
| 2a | `pr-gate.yml` 단일 파일 유지하면서 내부 jobs 를 `workflow_call` 받게 변경 + stage parameter 추가. `pr-gate-core` 별도 파일 아님 | PR 흐름 동일, 내부 jobs reusable 化 |
| 2b | stage 별 `extra_steps` 지원 (dev-staging / rc / main) | 기존 동작 동일 |
| 2c | `version-bump` reusable extract (sync-version 의 핵심 로직) | sync-version 의 caller 가 reusable 호출하게 변경 |
| 2d | `minglit-release-bot` 생성 + App ID/private key 등록 + workflow permission 최소화 | protected branch/tag push 를 human 대신 bot 으로 수행 |
| 2e | `auto-issue` reusable 추가 | 신규 — 기존 영향 없음 |
| 2f | **`ci-result` 폐기** — 현 branch protection 의 required check `ci-result` 를 각 branch 의 `pr-gate` 로 변경 (Phase 4 에서 실제 적용) | 본 step 은 workflow 측 준비, 실제 protection 변경은 4 |
| 2g | `deploy-supabase` 의 trigger refactor — push:dev 부분을 rc-gate-pass workflow_call **with target=main-staging** 로 변경, push:main 은 main-post-merge-promote 의 workflow_call **with target=main** | staging deploy 와 prod deploy 분리. 사용자 서버 영향 X |
| 2h | **`deploy-vercel` 폐기** — 자체 빌드 워크플로우 제거. **Vercel native build 로 전환** (Vercel-GitHub 연결, Vercel-side: main=production, dev=preview) | Vercel-side 설정 필요, workflow 측 작업 없음 |

### Rollback

- 각 step 별로 별도 PR. revert 가능.
- 특히 2e/2f 는 별도 PR + 적용 후 1주 모니터링.

### 결정

- 기존 `pr-gate.yml` 파일을 그대로 두고 reusable 내부 사용 vs `pr-gate-core.yml` 신규 파일 (기존 파일은 trigger 만 정의)
- 2c 의 sync-version 도 그대로 두고 reusable 호출 vs 완전 흡수

## Phase 3: Workflow 신규 구현

**위험도**: 중간~높음. 새 흐름 도입.

### Steps (순차 + 일부 병렬)

| Step | 작업 | 의존 |
|------|------|------|
| 3a | `dev-staging-pr-gate`, `dev-staging-post-merge-sync` | 2a, 2b, 2c, 2d |
| 3b | `nightly-cut`, `nightly-pr-gate` | 3a + dev-staging branch 존재 (Phase 1) |
| 3c | `rc-gate-suite` reusable 조립 (CUJ × matrix + integration + Test Lab) | 2a |
| 3d | `rc-gate` (호출 + status set + deploy chain trigger) | 3c + 2f/2g |
| 3e | `rc-cut`, `rc-pr-gate`, `rc-post-merge-sync`, `rc-soak-check` | 3d + rc/* branch 패턴 확정 + Supabase branching 설정 |
| 3f | `backport-pr` reusable, `rc-hotfix-backport` | 2a |
| 3g | `main-pr-gate`, `main-post-merge-promote` | 3d (rc-gate-pass status 필요) |

### Verification 단계

각 step 후 *최소 1주 운영*:
- 신규 workflow 가 의도대로 동작?
- 기존 workflow 와 충돌 없음?
- 실패 시 auto-issue 정상?

### Rollback

- 각 신규 workflow 는 별도 파일이라 삭제로 rollback. branch protection 에 required 로 등록하기 *전*에는 안전.
- `deploy-vercel` cron 폐기는 보수적으로 — 새 trigger 안정화 확인 후.

### 결정

- 신규 workflow 도입 순서가 정확히 위 순서 맞는지 (3a-3g)
- 각 verification 기간 (1주 vs 더 짧게/길게)
- 운영 중 issue 발견 시 다음 step 진행 여부

## Phase 4: Branch rule 적용

**위험도**: 가장 높음. required check 잘못 지정 시 모든 PR 머지 차단.

### Steps (조심스럽게, 하나씩)

| Step | 작업 | Pre-condition |
|------|------|---------------|
| 4a | `dev-staging` Ruleset 적용 (required: `dev-staging-pr-gate`) | 3a 1주 운영 |
| 4b | `dev` Ruleset 갱신 (required: `nightly-pr-gate`) | 3b 1주 |
| 4c | `rc/**` pattern Ruleset 적용 (required: `rc-pr-gate`) | 3e 1주 |
| 4d | `main` Ruleset 갱신 — **기존 `ci-result` required check 제거** + 추가: `main-pr-gate` 단일 required check (`rc-gate-pass`, `expand-migrate-contract`, `rc-soak-passed` 는 내부 검증) | 3g 1주 + 3d 안정 |
| 4e | Tag protection Ruleset (`v*`, `promo/**`) + release bot tag bypass | 4d 안정 (release 가 도는 게 확인된 후) |
| 4f | Branch creation 제한 (`rc/**` → bot only) | 4c 안정 |
| 4g | GitHub Environment `production` 생성 + required reviewer 설정 | 3g 1주 |
| 4h | **Default branch 변경**: `dev` → `dev-staging` | 모든 위 단계 안정 |

### Rollback

- 각 Ruleset 은 GitHub 콘솔에서 즉시 disable 가능
- Default branch 변경은 rollback 가능 (수동)
- 가장 위험: 4d (main 의 required check) — 잘못 적용 시 모든 release 차단. **항상 단계별로 우선 *warn-only* 모드로 적용 후 *enforced* 전환**

### 결정

- 각 Ruleset 의 bypass list (admin / release manager)
- 4h 시점 (Phase 4 끝일까, 운영 1개월 후일까)

## 우선순위 / Critical Path

가장 critical 한 path (block 면 전체 멈춤):

```
Phase 1 (skeletal) → Phase 2a-2c (pr-gate refactor) → Phase 3a (dev-staging workflow)
    → Phase 3d (rc-gate, 가장 큰 신규) → Phase 4a (첫 protection 적용)
```

비-critical (병렬 가능):
- Phase 2e (`auto-issue` reusable) — 신규, 의존 없음
- Phase 2f/2g (deploy trigger refactor) — Phase 3 이전에 끝나면 OK
- 3c (rc-gate-suite) — 3d 이전에만 끝나면 OK

## Secret Management 정리 (별도 작업, user 와 함께)

**현재 상태**: GitHub repo secrets 에 `DEV_*` / `MAIN_*` prefix 로 분리. 관리 빡센 상태.

**결정**: **모든 secret + config 를 `minglit_env/{stage}/*.env` 파일로 통일**. private repo 신뢰 기반 (user 명시적 결정).

### 분류 없음 — 전부 파일

| 항목 | 처리 |
|------|------|
| API base URL, feature flag default, timeout 등 config | `minglit_env/{stage}/*.env` (그대로 string) |
| Apple cert (.p12), Android keystore (.jks) 같은 binary | `minglit_env/{stage}/*.env` 에 **base64 encoded** string |
| Play Console / Firebase Admin SDK service-account JSON | `minglit_env/{stage}/*.env` 에 string (single line) 또는 file path reference |
| Sentry / Statsig / DB credentials | `minglit_env/{stage}/*.env` |
| GitHub Actions native (`GITHUB_TOKEN`) | GH 자동 주입, 별도 관리 X |

> **Trade-off 인지**: private repo 라도 collaborator 추가 시 모두에게 secret 노출, 실수로 public 만들면 전체 노출, audit log 부재. user 가 이 trade-off 명시 수용 — 운영 비용 절감이 우선.

### Workflow 로딩 패턴

```yaml
# 개념
- uses: cardinalby/export-env-action@v2
  with:
    envFile: minglit_env/${{ inputs.stage }}/flutter.env
# 이후 step 에서 $API_URL, $APPLE_CERT_BASE64 등 직접 참조
```

### 마이그레이션 step (단순)

| Step | 작업 |
|------|------|
| S1 | 현 GH secrets (`DEV_*`, `MAIN_*`) 인벤토리 작성 |
| S2 | 전부 `minglit_env/{stage}/*.env` 로 이전 (binary 는 base64 encoding) |
| S3 | Workflow 들이 file 로딩 + 적절한 stage env 사용하도록 refactor |
| S4 | 기존 GH secrets 삭제 (안 쓰는 것 정리) |

**Phase 매핑**: Phase 2 와 **병렬 X**. **user 와 별도 작업 (timing TBD)**. workflow 측에서는 그동안 stub / placeholder 사용.

## 운영 중 주의사항

1. **CI 실패가 release 차단**: pr-gate 의 stage parameter 가 정확히 매칭돼야 함. *required check 이름 한 글자라도 다르면 차단*. 특히 `ci-result` → stage pr-gate 전환 시 cutover 타이밍 중요
2. **trigger 변경**: cron → push 변경 시 *겹치는 기간* 발생할 수 있음 — 한쪽 비활성화 후 다른쪽 활성화. 부분 적용 금지
3. **status check naming**: `rc-gate-pass` 같은 commit status 의 이름이 spec 과 workflow 에서 일치해야 함. branch protection 에는 직접 required 로 걸지 않고 `main-pr-gate` 내부에서 검증
4. **AI agent 의 PR 동시성**: merge queue 없으니 race condition 발생 시 수동 conflict resolve 필요 (또는 merge queue 도입 검토)
5. **Release bot token 실패**: GitHub App ID/private key 누락 또는 App 권한 부족이면 version bump/tag/promotion workflow 가 막힘. 최초 도입 시 dry-run branch 로 push/tag/delete까지 검증
6. **Secret 마이그레이션 중 workflow 실패**: file 기반과 GH secret 참조가 섞이는 transition 기간 — env 변수 누락 시 즉시 발견 (CI 통과 못함)

## Self-review: Phase 3 ordering

내부 검토 결과 — **현재 순서 (3a → 3b → 3c → 3d → 3e → 3f → 3g) OK**, 단 다음 minor 개선:

- **3a / 3b 병렬 가능**: dev-staging-pr-gate (3a) 와 nightly-cut (3b) 는 서로 의존이 약함. 단 version bump/tag push 검증에는 release bot 준비가 선행되어야 함
- **3c → 3d 사이 verification 불필요**: rc-gate-suite (3c) 는 reusable, 호출은 rc-gate (3d) 에서. 3c 자체로는 동작 없음 → 3d 와 동일 PR 또는 직후 PR 가능
- **3f 는 3e 와 같이**: rc-hotfix-backport 가 rc-promotion 흐름의 일부라 같은 시점에 도입이 자연스러움
- **가장 critical**: 3d (rc-gate) — 첫 verification 기간 1주 이상 추천 (다른 stage 와 달리 60분 비용 + 통합 시나리오 복잡)

권장 변경 없음. 위 순서 그대로 진행.

## TBD (구현 중 결정)

- `auto-issue` 의 P0/P1/P2 라벨 컨벤션 표준 (현재 minglit 의 `P0-critical` 등 따름)
- `rc-gate-suite` 매트릭스 분할 (60분 예산 안에 들어오게)
- 4d 의 main protection 적용을 *warn-only* → *enforced* 전환 일자
- Vercel native build 전환 시점 + Vercel-GitHub 연결 설정 (Vercel-side 작업)
- Secret 마이그레이션 timing (user 와 함께 — Phase 2/3 와 별도)

## 관련

- [workflow-spec.md](./workflow-spec.md) — 각 workflow 의 contract
- [branch-spec.md](./branch-spec.md) — Phase 4 의 Ruleset 매핑
- [../branch-flow.md](../branch-flow.md) — 큰 그림
- 기존 [`.github/workflows/BLUEDOC.md`](../../../../.github/workflows/BLUEDOC.md) — 현재 workflow 의 인벤토리 진입점

---
_Reviewed: 2026-05-19 09:47_
