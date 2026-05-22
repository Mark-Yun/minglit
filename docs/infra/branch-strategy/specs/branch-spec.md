# Branch Spec

각 branch 의 protection rule, required status check, merge method, release bot bypass 설정의 구현 명세. GitHub Branch Protection / Ruleset API 로 직접 매핑 가능한 구체 값. [workflow-spec.md](./workflow-spec.md) 와 cross-reference.

## 명명 컨벤션

| Branch / Pattern | 종류 | 보호 |
|------------------|------|------|
| `dev-staging` | 영구 | yes |
| `dev` | 영구 | yes |
| `rc/YYYY-Wxx` | 임시 (weekly cut, RC → main 머지 후 삭제, 이력은 tag 보존) | yes (pattern protection) |
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
| Merge queue | **사용 안 함** (일반 PR + auto-merge 흐름으로 시작. 필요 시 후속 도입 — TBD) |
| Auto-delete head branch on merge | yes |
| Bypass roles | `minglit-release-bot` only for version bump/tag push. 인시던트 시 `--admin` 은 사용자 명시 승인 필요 |

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
| Require linear history | **yes** (nightly snapshot PR 만 들어옴, snapshot 자체가 linear) |
| Allowed merge methods | merge commit (snapshot 보존용) |
| Bypass roles | `minglit-release-bot` only for promotion/version metadata push |

> dev 는 사람이 직접 PR 안 만듦. `nightly-cut` workflow 만 PR 생성. branch protection 이 사실상 workflow 만 허용하는 효과.

### `main`

| 항목 | 값 |
|------|----|
| Default branch? | no (PR base 로는 사용, 일반 작업 base 아님) |
| Direct push | 금지 |
| Force push | 금지 |
| Branch deletion | 금지 |
| Required status checks | `main-pr-gate` (RC HEAD 의 `rc-gate-pass`, `expand-migrate-contract`, `rc-soak-passed` marker 를 내부 검증) |
| Required PR labels | GitHub Ruleset 직접 요구 없음. `main-pr-gate` 가 `rc-soak-passed` marker 를 검증 |
| Required reviewers | 0 (workflow auto-merge) |
| Require conversation resolution | yes |
| Require linear history | **yes** |
| Allowed merge methods | **rebase only** (rebase + fast-forward) |
| Auto-delete head branch on merge | yes (`rc/*` branch 는 main merge 후 삭제, 이력은 protected tag 로 보존) |
| Bypass roles | `minglit-release-bot` for final version/tag push, release manager only for catastrophic incident response |

> rc → main PR 만 받음. GitHub Ruleset 은 `main-pr-gate` 하나만 required 로 두고, `main-pr-gate` 내부에서 RC HEAD status, soak marker, contract 재검증을 수행한다. PR head SHA 와 dev commit status 가 다를 수 있으므로 `rc-gate-pass` 를 branch protection 의 독립 required check 로 걸지 않는다.

## Pattern Branch 설정

### `rc/YYYY-Wxx` (`rc/*` pattern)

| 항목 | 값 |
|------|----|
| Direct push | 금지 |
| Force push | 금지 |
| Branch deletion | 허용 대상 제한 (`minglit-release-bot` 만 RC 종료/abandon 시 삭제). human 삭제 금지 |
| Required status checks | `rc-pr-gate` (hotfix PR 에 대해) |
| Required reviewers | 0 |
| Require conversation resolution | yes |
| Require linear history | yes |
| Allowed merge methods | rebase only |
| Auto-delete head branch on merge | yes (hotfix branch 자동 삭제) |
| Bypass roles | `minglit-release-bot` only for RC version bump/tag push and RC branch cleanup |

> `rc-cut` workflow 가 branch 생성 후 이 protection ruleset 을 REST API 로 활성화. RC 종료 후 `minglit-release-bot` 이 branch 를 삭제하고, 릴리즈 이력은 `promo/rc-*`, `v*-rc-*`, `promo/main-*` protected tag 로 보존한다.

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
| `dev-staging-rules` | `dev-staging` | 위 영구 branch 표 그대로 + `minglit-release-bot` bypass |
| `dev-rules` | `dev` | 위 + `minglit-release-bot` bypass |
| `main-rules` | `main` | 위 + `minglit-release-bot` bypass |
| `rc-pattern-rules` | `rc/**` | 위 pattern 표 + `minglit-release-bot` bypass |
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

## Release Bot

Protected branch 에 대한 direct push 는 human 에게 허용하지 않는다. version bump commit, tag push, RC branch 생성/삭제처럼 workflow 가 branch state 를 변경해야 하는 경우만 전용 bot actor 를 사용한다.

| 항목 | 값 |
|------|----|
| Actor | `minglit-release-bot` (GitHub App 권장, 대안: fine-grained PAT 전용 bot account) |
| Token secret | `MINGLIT_RELEASE_BOT_TOKEN` |
| 사용 workflow | `dev-staging-post-merge-sync`, `nightly-cut`, `rc-cut`, `rc-post-merge-sync`, `rc-soak-check`, `rc-hotfix-backport`, `main-post-merge-promote` |
| Ruleset bypass | `dev-staging`, `dev`, `rc/**`, `main`, protected tag push (`v*`, `promo/**`) |
| Human 사용 | 금지. 로컬/수동 CLI 에서 token 사용 금지 |
| Audit | 모든 bot push 는 workflow run URL, actor, target ref, tag 목록을 PR/issue 또는 job summary 에 남김 |

### 최소 권한

GitHub App 기준 권장 permission:

| Permission | Level | 이유 |
|------------|-------|------|
| Contents | Read/write | version bump commit, branch 생성/삭제, tag push |
| Pull requests | Read/write | nightly/promotion/backport PR 생성, auto-merge enable |
| Commit statuses | Read/write | `rc-gate-pass` status set |
| Checks | Read | gate 상태 조회 |
| Issues | Read/write | auto-issue 생성/댓글 |
| Metadata | Read | GitHub App 기본 권한 |

`Actions`, `Administration`, `Secrets` 권한은 기본적으로 부여하지 않는다. Ruleset 수정/생성은 초기 설정 또는 별도 infra workflow 에서만 수행하며, release bot 의 상시 권한에서 제외한다.

## GitHub Environment Protection

Deploy 권한·secret 격리·required reviewer 등은 GitHub Environment 단위로:

| Environment | 용도 | 설정 |
|-------------|------|------|
| `dev` | dev 의 rc-gate-pass commit 으로 backend/web 자동 deploy | 자동 (no reviewer), Firebase service-account 등 dev secret |
| `production` | main push 로 mobile build + store upload | **required reviewer (release manager)** — store upload 직전에 사람 1 명 승인. Apple/Google secret 격리. Sentry production project token |
| `staging` (옵션) | RC Supabase branch 관리와 staging secret 격리 | TBD |

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
| 정상 작업 | AI agent / 개발자 | PR + auto-merge (우회 없음) |
| version bump/tag push | `minglit-release-bot` | Ruleset bypass, workflow 내부에서만 |
| nightly red 인데 main 핫픽스 필요 | release manager | `--admin` bypass + 명시 승인 (CLAUDE.md 룰) |
| catastrophic incident (Tier 2b hard kill) | release manager / on-call | branch 변경 아님 (admin page 로 RC 콘솔 변경) |
| RC abandon (TBD 시나리오) | RC owner | rc branch 삭제 + workflow_dispatch 로 새 rc-cut |

## 결정해야 할 것

- merge queue 도입 시점 (PR 동시성·conflict 데이터 쌓이면)
- `minglit-release-bot` 을 GitHub App 으로 만들지, fine-grained PAT bot account 로 시작할지
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
