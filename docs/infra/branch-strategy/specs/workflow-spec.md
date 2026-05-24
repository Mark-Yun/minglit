# Workflow Spec

`.github/workflows/` 의 모든 workflow 의 추상 명세. 4-stage branch model + 3-tier kill switch + safety net 의 구현 단일 source. *YAML 디테일 아님 — 의도·계약 정의.*

## 명명 컨벤션

- **Entry workflow**: `<stage>-<action>` 패턴 (예: `dev-staging-pr-gate`, `dev-rc-cut`, `main-deploy`)
- **Reusable workflow** (`workflow_call`): 명사·동사형 (예: `pr-gate-core`, `version-bump`)
- File 이름 = workflow 이름 + `.yml`
- Stage prefix: `dev-staging-` · `dev-` · `rc-` · `main-`
- `*-cut-gate`: 다음 브랜치로 promote 할 source artifact 를 검증/선별하고 marker 를 남긴다
- `*-cut`: gate 가 남긴 marker 를 소비해서 실제 promotion PR 또는 branch 를 만든다
- Branch PR gate 는 `<branch>-pr-gate` 로만 부른다: `dev-staging-pr-gate`, `dev-pr-gate`, `rc-pr-gate`, `main-pr-gate`
- Reusable 은 prefix 없음
- Deploy entry workflow 는 `[branch]-deploy` 로 통일한다: `dev-deploy`, `rc-deploy`, `main-deploy`
- 기존 domain deploy workflow (`deploy-supabase`, `deploy-android-user` 등) 는 entrypoint 가 아니라 하위 구현/재사용 대상이다
- 이벤트 플로우 시뮬레이터는 deploy workflow 가 아니라 `monitor-event-flow-*` batch job 이며, dev 에서 계속 돌고 RC 에서는 main 배포 전 검증 signal 로 사용한다

## Reusable Workflows (`workflow_call` building blocks)

### `pr-gate-core`

모든 stage 의 PR 검증 공통 suite.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` |
| Inputs | `stage`: dev-staging\|dev\|rc\|main / `ref`: branch ref / `extra_steps`: array (optional) |
| Outputs | `status`: pass\|fail / `report_url` |
| 핵심 steps | test-flutter-apps (matrix) · lint-landing-* · test-supabase (pgTAP) · test-edge-functions (Deno) · check-migration-versions · `expand-migrate-contract` · `flag-registration-check` · gitleaks · CodeRabbit (≤30분 wait) |
| Called by | `dev-staging-pr-gate`, `dev-pr-gate`, `rc-pr-gate`, `main-pr-gate` |

### `version-bump`

`bump-version.sh` 실행 + commit + tag.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` |
| Inputs | `version`: YY.MM.PR# / `suffix`: ""\|`-dev-staging`\|`-rc-NN` / `commit_message`: string |
| Outputs | `commit_sha`, `tag_name` |
| 핵심 steps | `bash scripts/bump-version.sh {version}{suffix}` · commit (`skip_ci` option) · `git tag v{version}{suffix}` · push |
| Called by | `dev-staging-dev-cut-gate`, `dev-rc-cut`, `rc-post-merge-sync`, `main-deploy` |

### `shared-set-commit-status`

GitHub commit status 를 쓰는 low-level reusable workflow. Stage/signal mapping 은 하지 않는다.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` |
| Inputs | `sha`, `context`, `state`: failure\|success\|pending, `target_url`, `description` |
| Outputs | GitHub commit status |
| Called by | `set-dev-soak-status`, `set-rc-soak-status`, cut-gate evaluators |

외부 workflow/AI agent 는 직접 호출하지 않는다. Public API 는 stage별 `set-*-soak-status` entry workflow 다.

### `set-dev-soak-status`

Dev soak status write API. `workflow_call` 과 `workflow_dispatch` 를 모두 지원한다.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` + `workflow_dispatch` |
| Inputs | `signal`: backend-simulator\|real-device\|app-ai-review, `state`, `sha`, `target_url`, `description` |
| Mapping | `backend-simulator` → `dev-soak/backend-simulator`; `real-device` → `dev-soak/real-device`; `app-ai-review` → `dev-soak/app-ai-review` |
| Steps | validate signal/state → context mapping → calls `shared-set-commit-status` |
| Called by | `monitor-event-flow-*`, real-device workflow, AI agent, `dev-rc-cut-gate` |

### `set-rc-soak-status`

RC soak status write API. dev 와 signal set 이 다를 수 있으므로 별도 entry 로 둔다.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` + `workflow_dispatch` |
| Inputs | `signal`: backend-simulator\|real-device\|dogfooding, `state`, `sha`, `target_url`, `description` |
| Mapping | `backend-simulator` → `rc-soak/backend-simulator`; `real-device` → `rc-soak/real-device`; `dogfooding` → `rc-soak/dogfooding` |
| Steps | validate signal/state → context mapping → calls `shared-set-commit-status` |
| Called by | `rc-deploy`, real-device workflow, AI agent, `rc-main-cut-gate` |

Issue 는 audit/log surface 이며 gate 판정 source-of-truth 가 아니다.

### `shared-soak-gate`

Soak window, workflow run history, commit status failure context 를 평가하고 통과 시 success marker 를 쓰는 reusable evaluator. Stage-specific promotion 의미는 갖지 않는다.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` |
| Inputs | `candidate_ref`, `candidate_sha`, `min_soak_hours`, `required_runs_json`, `failure_contexts`, `success_contexts`, `pass_context`, `pass_description` |
| Outputs | `skipped`, `reason`, `candidate_sha` |
| Called by | `dev-rc-cut-gate`, `rc-main-cut-gate` |

`required_runs_json` 은 workflow run history 조건을 담는다. 기본은 candidate commit 이후의 성공 run 수를 세며, 필요 시 `match_head_sha=true` 로 head SHA 일치를 강제할 수 있다.

### `auto-issue`

GitHub issue 자동 생성 + Slack 알림.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` |
| Inputs | `title`, `body`, `labels` (array), `assignees` (array), `priority`: P0\|P1\|P2\|P3, `slack_channel`: optional |
| Outputs | `issue_number` |
| 핵심 steps | `gh issue create` + Slack webhook fire (priority 별 채널) |
| Called by | 모든 workflow 의 실패 path |

### `backport-pr`

Cross-branch cherry-pick PR 자동 생성.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` |
| Inputs | `source_branch`, `target_branch`, `commits`: SHA array |
| Outputs | `pr_number`, `has_conflict`: bool |
| 핵심 steps | `git cherry-pick` · 충돌 시 partial commit + label `backport-conflict` · push to `backport/{source}-{target}-{sha8}` · `gh pr create` |
| Called by | `rc-hotfix-backport` |

## Entry Workflows

### dev-staging

#### `dev-staging-pr-gate`

| 항목 | 값 |
|------|----|
| Trigger | `pull_request` (base: `dev-staging`) |
| Outputs | required status check |
| Steps | calls `pr-gate-core` (stage=dev-staging) |
| Required for | dev-staging PR merge |

#### `dev-staging-dev-cut-gate`

| 항목 | 값 |
|------|----|
| Trigger | `push` to `dev-staging` (PR squash merge 후) |
| Inputs | (from event) PR number, merged SHA |
| Outputs | tag `v{YY.MM.PR#}-dev-staging` |
| Steps | calls `version-bump` (suffix=`-dev-staging`, version=`{YY.MM.PR#}`) using release bot GitHub App token |

### dev-staging → dev

#### `dev-staging-dev-cut`

| 항목 | 값 |
|------|----|
| Trigger | `schedule` (daily KST 02:00 TBD) + `workflow_dispatch` |
| Inputs | optional `tag_name` (`v*-dev-staging`) |
| Outputs | PR number (dev-staging → dev) or skip |
| PR title | `ci(dev-staging-dev-cut): promote {tag_name} to dev` |
| Steps | (1) 이전 `dev-staging-dev-cut` PR open 이면 skip + Slack (2) 가장 최근 `v*-dev-staging` tag SHA 조회, 또는 입력 `tag_name` 사용 (3) dev 가 그 SHA 를 이미 포함하면 skip ("no new commits") (4) `cut/dev-staging-dev/YYYY-MM-DD-{sha8}` promotion branch 를 tag SHA 에서 생성 (5) `gh pr create` (base=dev, head=`cut/dev-staging-dev/YYYY-MM-DD-{sha8}`) + auto-merge 활성화 (`rebase`, active dev ruleset 의 linear history 와 호환) |

#### `dev-pr-gate`

| 항목 | 값 |
|------|----|
| Trigger | `pull_request` (base: `dev`) |
| Steps | calls `pr-gate-core` (stage=dev) |
| Required for | dev branch protection |

#### `dev-rc-cut-gate`

| 항목 | 값 |
|------|----|
| Trigger | `schedule` (cut 직전, TBD) + `workflow_dispatch` |
| Inputs | optional `candidate_sha` (default: latest `origin/dev` HEAD) |
| Outputs | commit status `dev-rc-cut-pass` (success only) + `dev-soak/*` success confirmations |
| Steps | calls `shared-soak-gate` with candidate=`origin/dev`, min_soak_hours=24, required runs=`monitor-event-flow-hourly>=20` + `monitor-event-flow-daily>=1`, failure context=`dev-soak/backend-simulator`, success context=`dev-soak/backend-simulator`, pass context=`dev-rc-cut-pass` |
| Failure path | 조건 미충족이면 `dev-rc-cut-pass` 를 쓰지 않는다. 실패를 발견한 monitor/AI agent 가 이미 `dev-soak/*` failure 를 쓴다 |

> **No auto-revert** — snapshot 모델: 실패 = no `dev-rc-cut-pass`, dev keeps moving, 새 fix 가 자연스럽게 다음 dev-staging-dev-cut 후 새 candidate 로 검증됨.
> **Naming** — `dev-rc-cut-pass` 가 canonical RC eligibility marker 이다. `rc-eligible` 은 현재 workflow/status 명칭이 아니다.
> **SSOT** — dev soak 판정은 [../dev-soak-status-model.md](../dev-soak-status-model.md) 의 commit status + run history 를 따른다. GitHub Issue 는 사람이 보는 incident/audit surface 다.

#### `dev-deploy`

| 항목 | 값 |
|------|----|
| Trigger | TBD (`push` to `dev` 또는 `workflow_dispatch`) |
| Outputs | dev deploy/validation status |
| Steps | dev 환경 배포 또는 smoke 가 필요할 때만 수행. backend prod deploy 는 여기서 하지 않고 `main-deploy` 에서 수행 |
| Note | 이벤트 플로우 시뮬레이터는 `dev-deploy` 가 아니라 `monitor-event-flow-hourly` / `monitor-event-flow-daily` batch 로 계속 돈다 |

#### `monitor-event-flow-*` (release pipeline 외부 batch)

| 항목 | 값 |
|------|----|
| Trigger | schedule (`monitor-event-flow-hourly`, `monitor-event-flow-daily`) |
| Branch/env | dev 를 계속 관찰. RC cut 후에는 RC env/Supabase branch 도 pre-main 검증 signal 로 사용 |
| Outputs | event-flow simulation signal, `set-dev-soak-status(signal=backend-simulator,state=failure)`, issue/alert |
| Note | promotion gate 자체가 아니라 지속 신호다. main deploy 를 대신하지 않는다 |

### rc

#### `dev-rc-cut`

| 항목 | 값 |
|------|----|
| Trigger | `schedule` (weekly KST TBD) + `workflow_dispatch` |
| Outputs | branch `rc/YYYY-Wxx` + tag `v{ver}-rc-01` + tag `promo/rc-YYYY-Wxx` |
| Steps | (1) active RC marker 가 있으면 skip + Slack `#release` (hotfix 로 길어지는 중) (2) dev 의 최신 `dev-rc-cut-pass` status SHA query (`gh api`) (3) 없으면 cut 보류 (4) `git branch rc/YYYY-Wxx <SHA>` + push using release bot (5) calls `version-bump` (suffix=`-rc-01`) (6) `git tag promo/rc-YYYY-Wxx` + push (7) branch protection 활성화 (8) Slack `#release` 알림 |

#### `rc-pr-gate`

| 항목 | 값 |
|------|----|
| Trigger | `pull_request` (base: `rc/*`) |
| Steps | calls `pr-gate-core` (stage=rc) |
| Required for | rc branch protection |

#### `rc-post-merge-sync`

| 항목 | 값 |
|------|----|
| Trigger | `push` to `rc/*` (hotfix merge 후) |
| Outputs | tag `v{ver}-rc-NN` (NN+1) |
| Steps | (1) 현 rc 의 마지막 `v*-rc-*` tag 의 NN 파싱 (2) calls `version-bump` (suffix=`-rc-{NN+1}`) using release bot |

#### `rc-deploy`

| 항목 | 값 |
|------|----|
| Trigger | `push` to `rc/*` + `workflow_dispatch` |
| Outputs | RC env deploy/validation status |
| Steps | (1) Supabase branch `rc-YYYY-Wxx` 생성/확인 (2) migration/EF apply to RC branch (3) RC env smoke (4) event-flow simulation signal 확인 (5) 실패 시 `auto-issue` |
| Note | RC 는 계속 유지되는 장기 branch 가 아니라 Supabase branching 기반의 임시 검증 환경이다 |

#### `rc-main-cut-gate`

| 항목 | 값 |
|------|----|
| Trigger | `schedule` (daily KST TBD) + `workflow_dispatch` |
| Outputs | marker `rc-main-cut-pass` on current RC head, or skip/fail |
| Steps | (1) active `rc/*` 확인 → 없으면 종료 (2) calls `shared-soak-gate` with candidate=selected RC HEAD, min_soak_hours=120, failure contexts=`rc-soak/*`, pass context=`rc-main-cut-pass` (3) main promotion 차단 조건(`dev-rc-cut-gate-degraded`, P0/P1 blocker 등)은 후속 확장 |
| Note | promotion PR 을 만들지 않는다. main 으로 보낼 RC 를 선별하는 gate 전용 workflow 다 |

#### `rc-main-cut`

| 항목 | 값 |
|------|----|
| Trigger | `schedule` (daily KST TBD, after `rc-main-cut-gate`) + `workflow_dispatch` |
| Outputs | rc → main PR or skip |
| PR title | `ci(rc-main-cut): promote rc/YYYY-Wxx to main` |
| Steps | (1) `rc-main-cut-pass` marker 가 있는 active `rc/*` 확인 → 없으면 종료 (2) 이미 open rc → main PR 이 있으면 skip (3) `gh pr create base=main head=rc/YYYY-Wxx` + label `rc-main-cut-pass` + auto-merge 활성화 |
| Note | soak/validation 판단은 `rc-main-cut-gate` 책임이다. `rc-main-cut` 은 marker 소비와 PR 생성만 담당한다 |

#### `rc-hotfix-backport`

| 항목 | 값 |
|------|----|
| Trigger | `pull_request` closed/merged (base: `rc/*`) |
| Outputs | backport PR (rc/* → dev-staging) |
| Steps | calls `backport-pr` (source=`rc/*`, target=dev-staging, commits=[merged PR commits only]) · 충돌 시 `auto-issue` (P1, AI agent assignee). `rc-post-merge-sync` 의 version bump commit 은 backport 대상에서 제외 |

### main

#### `main-pr-gate`

| 항목 | 값 |
|------|----|
| Trigger | `pull_request` (base: `main`) |
| Steps | (1) calls `pr-gate-core` (stage=main) (2) RC lineage 의 `dev-rc-cut-pass` commit status 확인 (3) PR 의 `rc-main-cut-pass` label/marker 확인 |
| Required for | main branch protection |

#### `main-deploy`

| 항목 | 값 |
|------|----|
| Trigger | `push` to `main` (rc → main auto-merge 또는 승인된 `main/hotfix/*` 머지 직후) |
| Outputs | tag `v{ver}` + tag `promo/main-YYYY-Wxx` + Sentry marker + Firebase RC `latest_version` update + parallel deploy chain |
| Steps | (1) plan `finalize_required` vs `deploy_required` (2) RC promotion 이면 calls `version-bump` (suffix="") + `promo/main-YYYY-Wxx` tag (3) 이미 final version 인 hotfix push 면 version/tag finalization skip (4) Sentry release marker `v{ver}` (5) Firebase RC `latest_version` = `v{ver}` (Admin SDK) (6) **parallel deploy chain** (모두 target=main env): backend prod deploy, mobile deploy workflows (7) RC Supabase branch 삭제 |

> `main-deploy` 내부 또는 하위 workflow 로 실행되는 deploy jobs:
> - backend prod deploy (Supabase migration + EF)
> - `deploy-android-user`, `deploy-android-partner` (each calls `shared-android-deploy`)
> - `deploy-ios-user`, `deploy-ios-partner` (TBD: shared-ios-deploy reusable)
> - Vercel: native build 가 main push 자동 감지 (workflow_call 아님)

> Mobile APK/AAB/IPA 는 GitHub Release asset 이 canonical archive 다. Actions artifact 는 coverage, screenshot diff, test report, runner log 같은 단기 디버깅 산출물에만 사용한다.

> Cadence: backend prod + mobile 모두 weekly (rc → main 머지 마다, hotfix 없으면). store review + staged rollout 은 store-side.

## Workflow Chain Diagram

```
[agent PR opens to dev-staging]
       ↓
[dev-staging-pr-gate] ──auto-merge──▶ dev-staging push
                                                ↓
                                         [dev-staging-dev-cut-gate]
                                                ↓ tag v{ver}-dev-staging

[daily KST 02:00]
    ↓
[dev-staging-dev-cut] ──PR created──▶ [dev-pr-gate] ──auto-merge──▶ dev push
                                                                    ↓
                                                              [dev-rc-cut-gate]
                                                              ├ success ─▶ status dev-rc-cut-pass
                                                              │              ↓ monitor-event-flow-* continuous signal
                                                              │
                                                              └ failure ─▶ [auto-issue P1] (AI agent assignee → dev-staging fix PR)
                                                                          (no auto-revert — dev 잠시 broken, 다음 fix 가 다음 dev-rc-cut-gate 에서 검증)

[weekly cron]
    ↓
[dev-rc-cut] ──branch out from latest dev-rc-cut-pass commit──▶ rc/YYYY-Wxx (+ v{ver}-rc-01)
                                                                ↓ (soak, hotfix 가능)
                                                                │
                                                          [rc-pr-gate] (hotfix PR)
                                                                ↓ rc push
                                                                ↓ (parallel)
                                                          [rc-post-merge-sync] ──▶ v{ver}-rc-NN
                                                          [rc-hotfix-backport]  ──▶ backport PR to dev-staging
[rc-deploy]           ──▶ Supabase branch + pre-main validation

[daily cron, rc 존재 시]
    ↓
[rc-main-cut-gate] ──5일 무커밋 + pre-main signal green──▶ marker rc-main-cut-pass
                                                                  ↓
                                                           [rc-main-cut] ──▶ rc → main PR
                                                                  ↓ [main-pr-gate] → auto-merge
                                                                  ↓ main push
                                                                  ↓
                                                            [main-deploy]
                                       ↓ tag v{ver} + promo/main-Wxx + Sentry release
                                       ↓ Firebase RC `latest_version` = v{ver}
                                       ↓ (parallel)
                                 [backend prod deploy] ──▶ Supabase main
                                 [deploy-android-user, deploy-android-partner] ──▶ Play Store
                                 [deploy-ios-user, deploy-ios-partner] ──▶ App Store Connect
                                 (각 workflow 가 push: main trigger 로 자동 발동, 병렬)

(Tier 2b hard kill = 내부 admin page manual operation, workflow 없음 — catastrophic incident response 용. admin page 구현은 별도 작업)
```

## Dry Run Verification

Promotion/deploy entry workflows support `workflow_dispatch` dry-run where mutation steps are skipped and the calculated plan is written to the job summary.

| Workflow | Dry-run behavior |
|----------|------------------|
| `dev-staging-dev-cut` | selects `v*-dev-staging`, computes cut branch, skips branch push/PR/auto-merge |
| `dev-rc-cut-gate` | evaluates soak/run/status inputs, skips `dev-soak/*` and `dev-rc-cut-pass` status writes |
| `dev-rc-cut` | selects source SHA/version/RC week, skips RC branch push/version bump/tags |
| `rc-main-cut-gate` | selects RC branch and evaluates soak, skips `rc-main-cut-pass` status write |
| `rc-main-cut` | selects RC branch, skips main PR/auto-merge |
| `dev-deploy` | summarizes web/mobile dev deploy plan, skips deploy jobs |
| `main-deploy` | computes final version/tags/deploy targets, skips version bump/tags/deploy jobs |

Use dry-run before connecting new deploy backends or changing branch rulesets. Dry-run verifies workflow planning and guard logic without mutating GitHub, Supabase, Vercel, App Store, or Play Store.

## 결정해야 할 것

- `pr-gate-core` 의 stage 별 `extra_steps` 명세
- `version-bump` 의 commit 방식 (별도 commit vs squash inline)
- `set-dev-soak-status` / `set-rc-soak-status` 의 signal set 확정
- real-device / app AI review 가 어떤 workflow 또는 agent 에서 pass/failure status 를 쓸지 확정
- `dev-deploy` 가 실제로 맡을 dev deploy/smoke 범위
- `rc-deploy` 의 Supabase branch seed data 와 event-flow simulation contract
- CUJ chaos 시나리오 정의 (현재 미정의)
- Fastlane 설정 (Play `supply`, App Store `pilot`) + cert / keystore 관리
- macOS runner 비용 (iOS build 비용)
- Firebase Admin SDK 인증 (GitHub secret 으로 service account)
- Slack webhook URL 관리 (`#nightly`, `#release` 별도 secret)

## 관련

- [../branch-flow.md](../branch-flow.md) — workflow 가 흘러가는 branch 그림
- [../test-strategy.md](../test-strategy.md) — pr-gate-core 와 dev soak signal 배치
- [../dev-soak-status-model.md](../dev-soak-status-model.md) — dev soak commit status / run history SSOT
- [../error-detection.md](../error-detection.md) — auto-issue 의 priority 와 채널
- [../life-of-flag.md](../life-of-flag.md) — flag lifecycle
- [../versioning.md](../versioning.md) — version-bump 의 suffix 진행
- `branch-spec.md` (예정) — 각 entry workflow 가 어느 branch protection 의 required check 인지
- `execution-plan.md` (예정) — 기존 workflow refactor + 구현 순서

---
_Reviewed: 2026-05-24 16:45_
