# Workflow Spec

`.github/workflows/` 의 모든 workflow 의 추상 명세. 4-stage branch model + 3-tier kill switch + safety net 의 구현 단일 source. *YAML 디테일 아님 — 의도·계약 정의.*

## 명명 컨벤션

- **Entry workflow**: `<stage>-<action>` 패턴 (예: `dev-staging-pr-gate`, `rc-cut`, `main-post-merge-promote`)
- **Reusable workflow** (`workflow_call`): 명사·동사형 (예: `pr-gate-core`, `version-bump`)
- File 이름 = workflow 이름 + `.yml`
- Stage prefix: `dev-staging-` · `nightly-` · `rc-` · `main-`
- Reusable 은 prefix 없음
- **기존 deploy-* workflow 는 이름 유지** (예: `deploy-supabase`, `deploy-android-user`) — 재사용 + trigger 만 refactor

## Reusable Workflows (`workflow_call` building blocks)

### `pr-gate-core`

모든 stage 의 PR 검증 공통 suite.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` |
| Inputs | `stage`: dev-staging\|nightly\|rc\|main / `ref`: branch ref / `extra_steps`: array (optional) |
| Outputs | `status`: pass\|fail / `report_url` |
| 핵심 steps | test-flutter-apps (matrix) · lint-landing-* · test-supabase (pgTAP) · test-edge-functions (Deno) · check-migration-versions · `expand-migrate-contract` · `flag-registration-check` · gitleaks · CodeRabbit (≤30분 wait) |
| Called by | `dev-staging-pr-gate`, `nightly-pr-gate`, `rc-pr-gate`, `main-pr-gate` |

### `version-bump`

`bump-version.sh` 실행 + commit + tag.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` |
| Inputs | `version`: YY.MM.PR# / `suffix`: ""\|`-dev-staging`\|`-rc-NN` / `commit_message`: string |
| Outputs | `commit_sha`, `tag_name` |
| 핵심 steps | `bash scripts/bump-version.sh {version}{suffix}` · commit (with `[skip ci]`) · `git tag v{version}{suffix}` · push |
| Called by | `dev-staging-post-merge-sync`, `rc-cut`, `rc-post-merge-sync`, `main-post-merge-promote` |

### `rc-gate-suite`

Heavy integration test suite. 60분 예산.

| 항목 | 값 |
|------|----|
| Trigger | `workflow_call` |
| Inputs | `ref`: dev commit SHA |
| Outputs | `status`: pass\|fail / `failed_jobs`: array |
| Matrix | (app × scenario): `cuj-app-user × {happy, unhappy, chaos}` + `cuj-app-partner × {happy, unhappy, chaos}` + `integration-backend` + `integration-edge-functions` + `test-lab-smoke` |
| Called by | `rc-gate` |

> chaos 시나리오 미정의면 CUJ 로 추후 정의 (TBD).

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
| Trigger | `pull_request` (base: `dev-staging`) + `merge_group` (GitHub merge queue) |
| Outputs | required status check |
| Steps | calls `pr-gate-core` (stage=dev-staging) |
| Required for | dev-staging merge queue + PR merge |

#### `dev-staging-post-merge-sync`

| 항목 | 값 |
|------|----|
| Trigger | `push` to `dev-staging` (merge queue 통과 후) |
| Inputs | (from event) PR number, merged SHA |
| Outputs | tag `v{YY.MM.PR#}-dev-staging` |
| Steps | calls `version-bump` (suffix=`-dev-staging`, version=`{YY.MM.PR#}`) |

### nightly (dev 진입)

#### `nightly-cut`

| 항목 | 값 |
|------|----|
| Trigger | `schedule` (daily KST 02:00 TBD) + `workflow_dispatch` |
| Inputs | (none, or optional ref override) |
| Outputs | PR number (dev-staging → dev) or skip |
| Steps | (1) 이전 `nightly-cut` PR open 이면 skip + Slack (2) 가장 최근 `v*-dev-staging` tag SHA 조회 (3) dev HEAD == 그 SHA 이면 skip ("no new commits") (4) 아니면 `gh pr create` (base=dev, head=dev-staging) + auto-merge 활성화 |

#### `nightly-pr-gate`

| 항목 | 값 |
|------|----|
| Trigger | `pull_request` (base: `dev`) |
| Steps | calls `pr-gate-core` (stage=nightly) |
| Required for | dev branch protection |

#### `rc-gate`

| 항목 | 값 |
|------|----|
| Trigger | `push` to `dev` (= nightly-cut PR merge 직후) |
| Outputs | commit status `rc-gate-pass` (success only) |
| Steps | (1) calls `rc-gate-suite` (2) **success**: set commit status `rc-gate-pass` → parallel `workflow_call` 기존 `deploy-supabase` + `deploy-vercel` (3) **failure**: `auto-issue` (P1, label `rc-gate-failure`, assignee=직전 rc-gate-pass 이후 머지된 PR 작성자들). dev 는 broken 상태로 잠시 머묾, AI agent 가 fix PR 을 dev-staging 으로 normal flow 로 작성 → 다음 nightly-cut → 다음 rc-gate 가 검증 |
| Backoff | 같은 area 3회 연속 실패 시 `rc-cut` 자동 차단 (다음 weekly cut PR 안 만듦) |

> **No auto-revert** — snapshot 모델: 실패 = no tag, dev keeps moving, 새 fix 가 자연스럽게 다음 rc-gate 에서 검증됨.

#### `deploy-supabase` (기존, refactor 대상)

| 항목 | 값 |
|------|----|
| 현재 trigger | `push` to dev or main + paths filter (`supabase/migrations/**`, `supabase/functions/**`) |
| Refactor 후 trigger | `workflow_call` from `rc-gate` (success) + `push` to main |
| Outputs | deploy status, Sentry release marker |
| Steps | (1) Supabase migration apply (2) EF deploy (3) Sentry release marker (4) post-deploy smoke (5) 실패 시 retry → `auto-issue` (P0) + on-call |

#### `deploy-vercel` (기존, refactor 대상)

| 항목 | 값 |
|------|----|
| 현재 trigger | `schedule` cron 2시간 + `workflow_dispatch` |
| Refactor 후 trigger | `workflow_call` from `rc-gate` (success) + `push` to main (cron 폐기) |
| Outputs | deploy status |
| Steps | Vercel deploy hooks (4앱 parallel) · 실패 시 retry → `auto-issue` (P0) |

### rc

#### `rc-cut`

| 항목 | 값 |
|------|----|
| Trigger | `schedule` (weekly KST TBD) + `workflow_dispatch` |
| Outputs | branch `rc/YYYY-Wxx` + tag `v{ver}-rc-01` + tag `promo/rc-YYYY-Wxx` |
| Steps | (1) 현재 `rc/*` 살아있는지 확인 → 있으면 skip + Slack `#release` (hotfix 로 길어지는 중) (2) dev 의 최신 `rc-gate-pass` status SHA query (`gh api`) (3) 없으면 (3일+ green 없음) alert + abort (4) `git branch rc/YYYY-Wxx <SHA>` + push (5) calls `version-bump` (suffix=`-rc-01`) (6) `git tag promo/rc-YYYY-Wxx` + push (7) branch protection 활성화 (8) Slack `#release` 알림 |

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
| Steps | (1) 현 rc 의 마지막 `v*-rc-*` tag 의 NN 파싱 (2) calls `version-bump` (suffix=`-rc-{NN+1}`) |

#### `rc-soak-check`

| 항목 | 값 |
|------|----|
| Trigger | `schedule` (daily KST TBD) |
| Outputs | rc → main PR (5일 무커밋 시) or skip |
| Steps | (1) `rc/*` 존재 확인 → 없으면 종료 (2) rc HEAD 의 `committer date` 조회 (3) committer date 가 5일 이전이면: `gh pr create base=main head=rc/YYYY-Wxx` + label `rc-soak-passed` + auto-merge 활성화 |

#### `rc-hotfix-backport`

| 항목 | 값 |
|------|----|
| Trigger | `push` to `rc/*` (rc-post-merge-sync 와 parallel) |
| Outputs | backport PR (rc/* → dev-staging) |
| Steps | calls `backport-pr` (source=`rc/*`, target=dev-staging, commits=[새 hotfix SHA]) · 충돌 시 `auto-issue` (P1, AI agent assignee) |

### main

#### `main-pr-gate`

| 항목 | 값 |
|------|----|
| Trigger | `pull_request` (base: `main`) |
| Steps | (1) calls `pr-gate-core` (stage=main) (2) RC HEAD 의 `rc-gate-pass` commit status 확인 (3) PR 의 `rc-soak-passed` label 확인 |
| Required for | main branch protection |

#### `main-post-merge-promote`

| 항목 | 값 |
|------|----|
| Trigger | `push` to `main` (rc → main auto-merge 직후) |
| Outputs | tag `v{ver}` + tag `promo/main-YYYY-Wxx` + Sentry marker + Firebase RC `latest_version` update |
| Steps | (1) calls `version-bump` (suffix="") (2) `git tag promo/main-YYYY-Wxx` + push (3) Sentry release marker `v{ver}` (4) Firebase RC `latest_version` = `v{ver}` (Admin SDK) (5) **deploys 는 별도 — push: main trigger 로 기존 workflow 들이 자동 발동** |

> main push 후 자동 발동되는 기존 deploy workflows (병렬):
> - `deploy-supabase` — EF + migration
> - `deploy-vercel` — 4 web 앱
> - `deploy-android-user`, `deploy-android-partner` (each calls `shared-android-deploy`)
> - `deploy-ios-user`, `deploy-ios-partner` (TBD: shared-ios-deploy reusable 있는지 확인)

> Mobile cadence = main 머지 마다 weekly build/upload (hotfix 없으면). store review + staged rollout 은 store-side.
> Fastlane vs native action 등 mobile deploy 의 구체 도구는 기존 workflow 따름 (Fastlane 통일 검토는 후속 TBD).

## Workflow Chain Diagram

```
[agent PR opens to dev-staging]
       ↓
[dev-staging-pr-gate] ──merge queue 통과──▶ dev-staging push
                                                ↓
                                         [dev-staging-post-merge-sync]
                                                ↓ tag v{ver}-dev-staging

[daily KST 02:00]
    ↓
[nightly-cut] ──PR created──▶ [nightly-pr-gate] ──auto-merge──▶ dev push
                                                                    ↓
                                                              [rc-gate]
                                                              ├ success ─▶ status rc-gate-pass + [deploy-supabase] + [deploy-vercel]
                                                              │              ↓ Sentry release
                                                              │
                                                              └ failure ─▶ [auto-issue P1] (AI agent assignee → dev-staging fix PR)
                                                                          (no auto-revert — dev 잠시 broken, 다음 fix 가 다음 rc-gate 에서 검증)

[weekly cron]
    ↓
[rc-cut] ──branch out from latest rc-gate-pass commit──▶ rc/YYYY-Wxx (+ v{ver}-rc-01)
                                                                ↓ (soak, hotfix 가능)
                                                                │
                                                          [rc-pr-gate] (hotfix PR)
                                                                ↓ rc push
                                                                ↓ (parallel)
                                                          [rc-post-merge-sync] ──▶ v{ver}-rc-NN
                                                          [rc-hotfix-backport]  ──▶ backport PR to dev-staging

[daily cron, rc 존재 시]
    ↓
[rc-soak-check] ──5일 무커밋──▶ rc → main PR (label rc-soak-passed)
                                       ↓ [main-pr-gate] → auto-merge
                                       ↓ main push
                                       ↓
                                 [main-post-merge-promote]
                                       ↓ tag v{ver} + promo/main-Wxx + Sentry release
                                       ↓ Firebase RC `latest_version` = v{ver}
                                       ↓ (parallel)
                                 [deploy-android-user, deploy-android-partner] ──▶ Play Store
                                 [deploy-ios-user, deploy-ios-partner] ──▶ App Store Connect
                                 (각 workflow 가 push: main trigger 로 자동 발동, 병렬)

(Tier 2b hard kill = 내부 admin page manual operation, workflow 없음 — catastrophic incident response 용. admin page 구현은 별도 작업)
```

## 결정해야 할 것

- `pr-gate-core` 의 stage 별 `extra_steps` 명세
- `version-bump` 의 commit 방식 (별도 commit vs squash inline)
- `rc-gate-suite` matrix 분할 (60분 예산)
- CUJ chaos 시나리오 정의 (현재 미정의)
- Fastlane 설정 (Play `supply`, App Store `pilot`) + cert / keystore 관리
- macOS runner 비용 (iOS build 비용)
- Firebase Admin SDK 인증 (GitHub secret 으로 service account)
- Slack webhook URL 관리 (`#nightly`, `#release` 별도 secret)

## 관련

- [../branch-flow.md](../branch-flow.md) — workflow 가 흘러가는 branch 그림
- [../test-strategy.md](../test-strategy.md) — pr-gate-core 와 rc-gate-suite 의 test 내용
- [../error-detection.md](../error-detection.md) — auto-issue 의 priority 와 채널
- [../life-of-flag.md](../life-of-flag.md) — flag lifecycle
- [../versioning.md](../versioning.md) — version-bump 의 suffix 진행
- `branch-spec.md` (예정) — 각 entry workflow 가 어느 branch protection 의 required check 인지
- `execution-plan.md` (예정) — 기존 workflow refactor + 구현 순서

---
_Reviewed: 2026-05-19 09:47_
