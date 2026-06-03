# RC Eligibility

RC eligibility 는 `dev` commit 이 `rc/YYYY-Wxx` branch source 로 사용 가능한지 나타내는 release gate 계약이다. 전체 승격 계약은 [promotion-contract.md](./promotion-contract.md) 를 따르고, 이 문서는 RC source marker 호환성만 좁게 다룬다. Canonical marker 는 **`dev-rc-cut-pass` commit status** 이며, `rc-eligible` 은 workflow 이름이나 status context 로 쓰지 않는다.

## Contract

| 역할 | 구현 | 계약 |
|------|------|------|
| Eligibility writer | `dev-rc-cut-gate` | latest `origin/dev` 또는 수동 `candidate_sha` 를 평가하고 통과 시 `dev-rc-cut-pass=success` 를 쓴다 |
| RC cutter | `dev-rc-cut` | `origin/dev` first-parent 최신 200 commit 중 `dev-rc-cut-pass=success` 인 첫 commit 을 RC source 로 고른다 |
| Main promotion validator | `main-pr-gate` | RC branch first-parent lineage 안에 `dev-rc-cut-pass=success` source commit 이 있는지 확인한다 |
| Tracking issue | `.github/actions/cut-issue` via `dev-rc-cut-gate` | 사람이 보는 projection 이며 eligibility source-of-truth 가 아니다 |

`dev-rc-cut-pass` 는 deploy marker 가 아니다. 이 status 는 "이 dev commit 을 RC branch 로 cut 해도 된다"는 source marker 만 의미한다. Prod deploy 는 `main` 머지 후 `main-deploy` 에서만 수행한다.

## Status Compatibility

`dev-rc-cut-gate` 는 `shared-soak-gate` 를 통해 아래 evidence 를 소비한다.

| Evidence | Context / workflow |
|----------|-------------------------|
| Backend simulator failure/pass | `dev-soak/backend-simulator` |
| Dev cron install run | `deploy-dev-event-flow-cron.yml` success on same `headSha` |
| User CUJ | `monitor-dev-cuj.yml` success on same `headSha` + `dev-soak/cuj-user` not failure |
| Partner CUJ | `monitor-dev-cuj.yml` success on same `headSha` + `dev-soak/cuj-partner` not failure |
| Final eligibility marker | `dev-rc-cut-pass` |

따라서 새 dev health writer 를 만들 때도 `dev-rc-cut-pass` 호환을 깨면 안 된다. `dev-health/*` 같은 새 context 를 도입하려면 다음 중 하나를 같은 PR 에서 처리해야 한다.

1. `dev-rc-cut-gate`, `dev-rc-cut`, `main-pr-gate`, contract test, docs 를 모두 새 context 로 전환한다.
2. 전환 기간 동안 `dev-soak/*` 와 새 context 를 dual-write 하고, gate 는 둘 중 canonical source 를 명확히 하나만 소비한다.
3. 이름만 정책상 health 로 바꾸고 status context 는 legacy compatibility 때문에 `dev-soak/*` 를 유지한다.

권장 경로는 3번이다. Dev 단계에서 "soak" 정책을 폐기하더라도, 기존 status context 는 RC eligibility 소비자와 event-flow simulator reporter 가 이미 의존하고 있으므로 한 번에 rename 하지 않는다.

## `rc-eligible` Naming

`rc-eligible` 이라는 이름을 새로 쓰려면 alias 가 아니라 **breaking rename** 으로 취급한다. 최소 변경 범위는 다음과 같다.

- `dev-rc-cut-gate` 의 `pass_context`
- `dev-rc-cut` 의 status query
- `main-pr-gate` 의 RC lineage status query
- `check-dev-soak-workflow-contract.py` 같은 workflow contract tests
- branch strategy docs 전체의 marker naming
- GitHub status 를 직접 쓰는 외부 automation / AI agent 문서

부분 적용은 금지한다. `dev-rc-cut-pass` 와 `rc-eligible` 을 동시에 source-of-truth 로 쓰면 RC source 선택이 비결정적이 된다.

## Operator Checks

repo 에 등록된 Actions 에는 `rc-eligible` workflow 가 없어야 한다.

```bash
gh workflow list --all --limit 200 | grep -E 'rc-eligible|rc eligible'
```

dev 에서 RC source 후보를 확인할 때는 다음 status 를 조회한다.

```bash
gh api repos/<owner>/<repo>/commits/<sha>/status \
  --jq '.statuses[] | select(.context == "dev-rc-cut-pass") | .state'
```

---
_Reviewed: 2026-06-03 15:05_
