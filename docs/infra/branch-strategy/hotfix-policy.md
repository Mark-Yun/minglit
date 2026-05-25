# Hotfix Policy

`dev`, `rc/*`, `main` 은 일반 작업 PR 을 직접 받지 않는다. 정상 진입점은 항상 `dev-staging` 이다. Hotfix 는 예외 흐름이며, branch name + PR label + linked issue label 로 명시 승인된 경우에만 branch별 PR gate 를 통과한다.

## Branch Naming

| 대상 base | hotfix branch | 용도 |
|-----------|---------------|------|
| `dev` | `dev/hotfix/<slug>` | dev soak 를 막는 긴급 수정. 수정 후 다음 `dev-rc-cut-gate` 가 다시 검증 |
| `rc/YYYY-Wxx` | `rc/hotfix/<slug>` | active RC 검증 중 발견된 release blocker 수정 |
| `main` | `main/hotfix/<slug>` | prod incident 또는 store release 직전 치명 이슈 수정 |

대상 branch 를 prefix 로 먼저 둔다. GitHub branch list/ruleset/검색에서 "어느 branch 를 겨냥한 hotfix 인가" 를 즉시 알 수 있게 하기 위해서다. `hotfix/dev/*` 처럼 hotfix 를 앞에 두는 이름은 사용하지 않는다.

## Labels

| Label | 붙는 곳 | 의미 |
|-------|---------|------|
| `hotfix:dev-approved` | linked issue + PR | `dev/hotfix/*` PR 을 dev 로 머지할 수 있음 |
| `hotfix:rc-approved` | linked issue + PR | `rc/hotfix/*` PR 을 active `rc/*` 로 머지할 수 있음 |
| `hotfix:main-approved` | linked issue + PR | `main/hotfix/*` PR 을 main 으로 머지할 수 있음 |
| `release-manager-approved` | PR | main hotfix 에 사람 승인 완료. `hotfix:main-approved` 와 함께 필요 |

Issue label 은 승인 근거다. PR label 은 merge gate 가 읽는 실제 신호다. 둘 중 하나만 있으면 통과하지 않는다.

## Gate Rules

| Base | 정상 허용 | Hotfix 예외 |
|------|-----------|-------------|
| `dev-staging` | 일반 `feat/*`, `fix/*`, `chore/*`, `docs/*` PR | 별도 hotfix 개념 없음 |
| `dev` | `cut/dev-staging-dev/*` promotion PR | `dev/hotfix/*` + `hotfix:dev-approved` on PR and linked issue |
| `rc/*` | 없음 | `rc/hotfix/*` + `hotfix:rc-approved` on PR and linked issue |
| `main` | `rc/YYYY-Wxx` + `rc-main-cut-pass` promotion PR | `main/hotfix/*` + `hotfix:main-approved` on PR and linked issue + `release-manager-approved` on PR |

에러 메시지는 branch별 gate 에서 동일한 문구로 시작한다.

```text
Direct PRs to dev/rc/main are blocked.
Use dev-staging as the normal entry branch.
For emergency changes, create a <base>/hotfix/* branch and get the required hotfix approval labels on the linked issue and PR.
```

## Linked Issue Requirement

Hotfix PR body 는 `Closes #123`, `Fixes #123`, `Resolves #123` 중 하나를 포함해야 한다. Gate 는 GitHub API 로 linked issue 의 label 을 확인한다.

여러 issue 를 닫는 PR 은 허용하되, **최소 1개 linked issue** 가 대상 branch 의 approval label 을 가져야 한다. main hotfix 는 linked issue approval 외에 PR 자체의 `release-manager-approved` label 을 추가로 요구한다.

## Backport

RC/main hotfix 는 머지 후 반드시 `dev-staging` 으로 backport 된다.

| Source | Backport |
|--------|----------|
| `rc/hotfix/*` → `rc/YYYY-Wxx` | `rc-hotfix-backport` 가 `backport/rc-<pr>` PR 을 `dev-staging` 으로 생성 |
| `main/hotfix/*` → `main` | `main-hotfix-backport` 또는 수동 release-manager PR 로 `dev-staging` + 필요 시 active `rc/*` 에 반영 |

Backport 실패는 `P1-high` 이상 issue 로 기록한다. main hotfix backport 실패는 `P0-critical` 로 승격할 수 있다.

## Main Hotfix Human Approval

`main` 은 사용자 영향이 즉시 발생하므로 자동 label 만으로 열지 않는다. 최소 요구:

- linked issue: `hotfix:main-approved`
- PR: `hotfix:main-approved`
- PR: `release-manager-approved`
- branch: `main/hotfix/*`
- required check: `main-pr-gate`

추후 GitHub Ruleset 의 required reviewer 를 main hotfix path 에만 조건부로 걸 수 없으면, `main-pr-gate` 가 PR review state 또는 team approval 을 직접 확인하도록 확장한다.

---
_Reviewed: 2026-05-24 17:10_
