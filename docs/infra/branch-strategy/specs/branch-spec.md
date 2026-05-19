# Branch Spec

각 branch 의 protection rule, required status check, merge method, merge queue 설정의 구현 명세. GitHub Branch Protection / Ruleset API 로 직접 매핑 가능한 구체 값. [workflow-spec.md](./workflow-spec.md) 와 cross-reference.

## 명명 컨벤션

| Branch / Pattern | 종류 | 보호 |
|------------------|------|------|
| `dev-staging` | 영구 | yes |
| `dev` | 영구 | yes |
| `rc/YYYY-Wxx` | 임시 (weekly cut, RC → main 머지 후 archive) | yes (pattern protection) |
| `main` | 영구 | yes (가장 강함) |
| `feat/*`, `fix/*`, `chore/*`, `docs/*`, `hotfix/*` | 임시 (PR 머지 후 자동 삭제) | no |
| `backport/*` | 자동 생성 (rc-hotfix-backport) | no |
| `revert/*` | 자동 생성 (제거 — snapshot 모델이라 사용 안 함) | n/a |

## 영구 Branch 설정

### `dev-staging`

| 항목 | 값 |
|------|----|
| Default branch? | **yes** (작업 branch — agent 와 개발자가 PR base 로 사용) |
| Direct push | 금지 (`Restrict who can push to matching branches` → none) |
| Force push | 금지 |
| Branch deletion | 금지 |
| Required status checks | `dev-staging-pr-gate` (전체 step), CodeRabbit |
| Strict status checks (require up-to-date branch) | yes |
| Required reviewers | 0 (AI agent 가 commit 하는 zone, human review 0) |
| Dismiss stale reviews | n/a |
| Require conversation resolution | **yes** (모든 unresolved 코멘트 머지 차단) |
| Require linear history | **yes** (squash merge 강제) |
| Allowed merge methods | **squash only** |
| Require signed commits | no (현재 minglit 컨벤션 따름) |
| Merge queue | **사용 안 함** (단발 PR 흐름으로 시작. 필요 시 후속 도입 — TBD) |
| Auto-delete head branch on merge | yes |
| Bypass roles | none (단 인시던트 시 `--admin` 사용자 명시 승인 가능) |

### `dev`

| 항목 | 값 |
|------|----|
| Default branch? | no (dev-staging 이 default) |
| Direct push | 금지 |
| Force push | 금지 |
| Branch deletion | 금지 |
| Required status checks | `nightly-pr-gate` (dev-staging 의 snapshot PR 에 대해) |
| Required reviewers | 0 |
| Require conversation resolution | yes |
| Require linear history | **yes** (merge queue 통과 snapshot 만 들어옴, snapshot 자체가 linear) |
| Allowed merge methods | merge commit (snapshot 보존용) |
| Bypass roles | none |

> dev 는 사람이 직접 PR 안 만듦. `nightly-cut` workflow 만 PR 생성. branch protection 이 사실상 workflow 만 허용하는 효과.

### `main`

| 항목 | 값 |
|------|----|
| Default branch? | no (PR base 로는 사용, 일반 작업 base 아님) |
| Direct push | 금지 |
| Force push | 금지 |
| Branch deletion | 금지 |
| Required status checks | `main-pr-gate` (전체) + `rc-gate-pass` (RC HEAD commit 의 GitHub commit status) + `expand-migrate-contract` (재실행) |
| Required PR labels | `rc-soak-passed` (rc-soak-check 가 부여) |
| Required reviewers | 0 (workflow auto-merge) |
| Require conversation resolution | yes |
| Require linear history | **yes** |
| Allowed merge methods | **rebase only** (rebase + fast-forward) |
| Auto-delete head branch on merge | no (rc/* branch 는 archive 정책 따로 — TBD) |
| Bypass roles | release manager (catastrophic incident response 시) |

> rc → main PR 만 받음. `main-pr-gate` 가 RC HEAD 의 status 등을 검증하는 게이트.

## Pattern Branch 설정

### `rc/YYYY-Wxx` (`rc/*` pattern)

| 항목 | 값 |
|------|----|
| Direct push | 금지 |
| Force push | 금지 |
| Branch deletion | 금지 (머지 후에도 archive 보존 — release history marker 역할) |
| Required status checks | `rc-pr-gate` (hotfix PR 에 대해) |
| Required reviewers | 0 |
| Require conversation resolution | yes |
| Require linear history | yes |
| Allowed merge methods | rebase only |
| Auto-delete head branch on merge | yes (hotfix branch 자동 삭제) |
| Bypass roles | none |

> `rc-cut` workflow 가 branch 생성 후 이 protection ruleset 을 REST API 로 활성화.

### `feat/*`, `fix/*`, `chore/*`, `docs/*`, `hotfix/*`

| 항목 | 값 |
|------|----|
| Protection | **none** (개발자/agent 가 자유롭게 작업) |
| Auto-delete on PR merge | yes (모든 단기 branch) |
| 컨벤션 (강제 아닌 약속) | branch name 의 prefix 가 PR scope 와 일치, conventional commit 권장 |

### `backport/*`

| 항목 | 값 |
|------|----|
| Protection | none |
| 생성 방식 | `rc-hotfix-backport` workflow 가 자동 생성 |
| Auto-delete on PR merge | yes |

## GitHub Rulesets (채택)

GitHub 의 **Rulesets** 채택 (legacy Branch Protection 아님). 패턴 기반·target 별 규칙 묶음 관리:

| Ruleset | Target | 규칙 |
|---------|--------|------|
| `dev-staging-rules` | `dev-staging` | 위 영구 branch 표 그대로 |
| `dev-rules` | `dev` | 위 |
| `main-rules` | `main` | 위 |
| `rc-pattern-rules` | `rc/**` | 위 pattern 표 |
| `auto-delete-temp` | `feat/**`, `fix/**`, `chore/**`, `docs/**`, `hotfix/**`, `backport/**` | auto-delete only |
| `tag-protection` | `v*`, `promo/**`, `mobile-released/**` | 아래 Tag Protection 표 |
| `branch-creation` | `rc/**`, `release/**` | 아래 Branch Creation 표 |

Rulesets 의 장점 (legacy 대비):
- Patterns 으로 한 번에 여러 branch
- Bypass list 명확
- Imports/exports JSON (자동화·Terraform 친화)
- Audit log 통합
- **Tag/branch creation 도 ruleset 으로** (legacy 는 branch 만)

## Tag Protection

릴리즈 history 의 핵심 — 외부 도구 (Sentry, Statsig, Vercel, Store) 가 pin 하므로 손상 금지.

| Tag pattern | 보호 |
|-------------|------|
| `v*` (예: `v26.05.2572`, `v26.05.2572-rc-01`) | 삭제 금지, force-push 금지 |
| `promo/**` (예: `promo/main-2026-W20`) | 삭제 금지, force-push 금지 |
| `mobile-released/**` (있다면) | 삭제 금지 |

Bypass: 없음 (catastrophic 한 경우만 admin 명시 승인).

## Branch Creation 제한

`rc/*`, `release/*` 같은 의미있는 패턴은 특정 actor 만 생성 가능:

| Pattern | 생성 권한 |
|---------|----------|
| `rc/YYYY-Wxx` | `rc-cut` workflow (GitHub Actions bot) only — human 직접 생성 금지 |
| `release/**` | (현재 사용 안 함, 향후 추가 시 정의) |
| `backport/**` | `rc-hotfix-backport` workflow only |

Bypass: release manager (긴급 RC 새 cut 시).

## GitHub Environment Protection

Deploy 권한·secret 격리·required reviewer 등은 GitHub Environment 단위로:

| Environment | 용도 | 설정 |
|-------------|------|------|
| `dev` | dev 의 rc-gate-pass commit 으로 backend/web 자동 deploy | 자동 (no reviewer), Firebase service-account 등 dev secret |
| `production` | main push 로 mobile build + store upload | **required reviewer (release manager)** — store upload 직전에 사람 1 명 승인. Apple/Google secret 격리. Sentry production project token |
| `staging` (옵션) | RC soak 용 ephemeral Supabase branch 등 | TBD |

**중요**: production environment 의 required reviewer = workflow 자동 흐름에 한 번의 human approval 삽입. catastrophic 사고 방지의 마지막 안전망.

## CODEOWNERS (옵션 — 도입 결정 필요)

특정 path 의 PR 자동 review 할당:

| Path | Owner |
|------|-------|
| `.github/workflows/**` | release manager / DevOps |
| `supabase/migrations/**` | DB lead |
| `docs/infra/branch-strategy/**` | release manager |
| `shared/packages/**` | core platform lead |

CODEOWNERS 가 required reviewer 와 결합하면 자동으로 review 요청 + 머지 차단. 현재 minglit reviewer 수 = 0 이라 옵션 (review 강제 안 함). 향후 critical path 만 강제 검토 도입 고려.

## Merge Queue (현재 사용 안 함)

단발 PR 흐름으로 시작. 필요 시 후속 도입 (TBD — agent PR 동시성·conflict 빈도 보고 결정).

도입 시 검토 항목:
- 활성화 branch: `dev-staging` only
- Build concurrency / min entries / max wait time 적정값
- Lateral merge (queue 우회) 허용 여부

> 현 상태: dev-staging 도 일반 PR + auto-merge 패턴.

## Auto-bypass / 권한 매트릭스

| 시나리오 | 누가 | 우회 방법 |
|----------|------|----------|
| 정상 작업 | AI agent / 개발자 | merge queue + auto-merge (우회 없음) |
| nightly red 인데 main 핫픽스 필요 | release manager | `--admin` bypass + 명시 승인 (CLAUDE.md 룰) |
| catastrophic incident (Tier 2b hard kill) | release manager / on-call | branch 변경 아님 (admin page 로 RC 콘솔 변경) |
| RC abandon (TBD 시나리오) | RC owner | rc branch 삭제 + workflow_dispatch 로 새 rc-cut |

## 결정해야 할 것

- merge queue 도입 시점 (PR 동시성·conflict 데이터 쌓이면)
- `--admin` bypass 의 audit log 자동 분석 (분기별 사용 패턴 검토)
- `signed commits` 요구 여부 (현재 미요구, 향후 SLSA 컴플라이언스 고려)
- `production` environment 의 required reviewer 명단 (release manager — 누가?)
- CODEOWNERS 도입 여부 + 적용 path
- staging environment 활용 (Supabase branch 격리 등) — `execution-plan.md` 에서 결정

## 관련

- [workflow-spec.md](./workflow-spec.md) — required status check 의 workflow 정의
- [../branch-flow.md](../branch-flow.md) — branch 간 머지 방향 큰 그림
- `execution-plan.md` (예정) — protection rule 의 점진 적용 순서

---
_Reviewed: 2026-05-19 09:47_
