# Promotion Contract

`dev-staging -> dev -> rc -> main` 승격의 source-of-truth 계약. 이 문서는 정책 의도와 concrete workflow/status/tag contract 를 함께 둔다. stage별 상세 운영 설명은 `dev-pipeline.md`, `rc-promotion.md`, `main-promotion.md` 를 따르되, 승격 판정 marker 나 실패 처리 계약이 충돌하면 이 문서를 먼저 고친다.

## Policy

| Stage | 역할 | 승격 원칙 |
|-------|------|-----------|
| `dev-staging` | 일반 작업 진입점 | feature/agent/human PR 은 여기로만 들어오고 squash merge 한다 |
| `dev` | integration health | daily snapshot 을 받고, 새 dev commit 마다 health 를 검증한다 (Flutter CUJ 는 [web-mvp pivot](../../architecture/web-mvp-pivot.md) 으로 동결). Dev 자체 24h soak 는 하지 않는다 |
| `rc/YYYY-Wxx` | release candidate soak | `dev-rc-cut-pass` 가 붙은 dev commit 에서 cut 하고, RC HEAD 기준 5일 soak 한다 |
| `main` | production snapshot | `rc-main-cut-pass` 가 붙은 RC 를 main 으로 promote 하고, main push 후 prod deploy 한다 |

승격 PR 은 source ancestry 보존을 위해 merge commit 을 사용한다. 일반 작업 PR 은 `dev-staging` 에서 squash merge 한다. `dev`, `rc/*`, `main` 직접 PR 은 promotion 또는 승인된 hotfix 만 허용한다.

MDS render PNG 는 source branch 에 커밋하지 않는다. 영구 보존이 필요한 visual evidence 는 전용 branch `artifacts/mds-render` 에 SHA-bound path 로 저장하고, 해당 source SHA 의 commit status 가 그 위치를 가리킨다.

## Promotion Edges

| Edge | Entry workflow | Source | Target | Merge / mutation |
|------|----------------|--------|--------|------------------|
| work -> dev-staging | `dev-staging-pr-gate` | feature/fix/chore/docs branch | `dev-staging` | PR squash merge |
| dev-staging -> dev | `dev-staging-dev-cut` + `dev-pr-gate` | `v*-dev-staging` tag SHA | `dev` | promotion PR merge commit |
| dev -> rc | `dev-rc-cut-gate` + `dev-rc-cut` | latest `dev-rc-cut-pass` dev commit | `rc/YYYY-Wxx` | branch cut + `promo/rc-*` tag |
| rc hotfix | `rc-pr-gate` | dev-staging-first fix cherry-pick branch | active `rc/YYYY-Wxx` | PR merge, RC soak clock reset |
| rc -> main | `rc-main-cut-gate` + `rc-main-cut` + `main-pr-gate` | `rc-main-cut-pass` RC HEAD | `main` | promotion PR merge commit |
| main -> prod | `main-deploy` | main merge commit | prod backend/web (mobile frozen: web-mvp pivot) | deploy only, no source version bump |

## Concrete Markers

| Marker | Type | Writer | Consumer | Meaning |
|--------|------|--------|----------|---------|
| `vYY.MM.DD+YYMMDDNN-dev-staging` | git tag | `dev-staging-dev-cut` | dev promotion, deploy metadata | coherent dev-staging snapshot |
| `dev-staging-health/*` | commit status | `monitor-dev-staging-health` | human/AI triage only | early regression signal, not a promotion gate |
| `artifacts/mds-render` | git branch | `sync-mds-render-snapshot` | AI visual review, human audit, `triage-mds-render-snapshot-diff` | source branch 밖의 MDS render PNG archive |
| `mds-render/snapshot` | commit status | `sync-mds-render-snapshot` | AI visual review, `dev-rc-cut-gate` when visual review is required | dev SHA 의 render snapshot 저장/조회 가능 여부 |
| `dev-soak/backend-simulator` | commit status | `deploy-dev-event-flow-cron`, simulator reporter, `dev-rc-cut-gate` | `dev-rc-cut-gate` | legacy-named dev health signal |
| `dev-soak/cuj-user` | commit status | `set-dev-soak-status` (manual; `monitor-dev-cuj` 동결) | `dev-rc-cut-gate` | manual block lever — failure 만 소비, success 는 required evidence 아님 |
| `dev-soak/cuj-partner` | commit status | `set-dev-soak-status` (manual; `monitor-dev-cuj` 동결) | `dev-rc-cut-gate` | manual block lever — failure 만 소비, success 는 required evidence 아님 |
| `dev-soak/real-device` | commit status | real-device workflow / AI agent | `dev-rc-cut-gate` | device smoke signal |
| `dev-soak/app-ai-review` | commit status | AI agent / human-assisted review | `dev-rc-cut-gate` | confirmed visual blocker/pass signal, normally consuming `artifacts/mds-render` snapshots |
| `dev-rc-cut-pass` | commit status | `dev-rc-cut-gate` | `dev-rc-cut`, `main-pr-gate` | RC cut source marker |
| `promo/rc-YYYY-Wxx` | git tag | `dev-rc-cut` | release audit/deploy metadata | RC branch creation marker |
| `rc-soak/*` | commit status | RC monitor/dogfooding workflows | `rc-main-cut-gate` | RC soak/pre-main signal |
| `rc-main-cut-pass` | commit status + PR label | `rc-main-cut-gate` / `rc-main-cut` | `rc-main-cut`, `main-pr-gate` | main promotion marker |
| `promo/main-YYYY-Wxx` | git tag | `main-deploy` / promotion workflow | release audit/deploy metadata | main promotion marker |

`dev-soak/*` 는 이름만 legacy 다. 정책상 dev soak 는 폐기하지만, existing consumers (`dev-rc-cut-gate`, event-flow simulator reporter, docs/spec tests) 와 호환하려면 prefix 를 즉시 `dev-health/*` 로 바꾸지 않는다. 새 이름을 쓰려면 dual-write 또는 일괄 rename 을 별도 PR 로 처리한다.

`rc-eligible` 이라는 workflow/tag/status 는 없다. `rc-gate-pass` 는 과거 status 잔재로 취급하고 새 승격 계약에서 소비하지 않는다. RC eligibility 의 canonical marker 는 `dev-rc-cut-pass` 다.

## Gate Evidence

Release gate 는 true evidence 기반이다. 실패 이슈가 없다는 사실은 pass 가 아니다.

| Gate | Required success evidence | Blocking evidence |
|------|---------------------------|-------------------|
| `dev-pr-gate` | reusable `pr-gate` success + source guard success | source guard failure, PR gate failure |
| `dev-rc-cut-gate` | same-SHA `deploy-dev-event-flow-cron` success, required real-device/app AI review evidence, no required `dev-soak/*` failure status (Flutter CUJ run 요구는 web-mvp pivot 으로 제거) | any required `dev-soak/*=failure`, `mds-render/snapshot=failure` when visual review is required, missing required success evidence, infra failure |
| `rc-pr-gate` | reusable `pr-gate` success + source guard success | RC-only unapproved source, PR gate failure |
| `rc-main-cut-gate` | RC age >= 5 days since last RC commit, required `rc-soak/*` success, pre-main validation success, dev-staging-first hotfix lineage | `rc-soak/*=failure`, hotfix lineage violation, missing evidence, age not met |
| `main-pr-gate` | reusable `pr-gate` success, RC lineage contains `dev-rc-cut-pass=success`, RC HEAD has `rc-main-cut-pass=success` and PR label | missing lineage marker, missing RC marker, PR gate failure |

## Failure Contract

| Failure | Immediate action | Follow-up workflow | Promotion effect |
|---------|------------------|--------------------|------------------|
| `dev-staging-pr-gate` fails | PR stays unmerged | author/AI fixes same PR | no dev-staging merge |
| `monitor-dev-staging-health` fails | set `dev-staging-health/*=failure`, create/update issue | AI fix PR to `dev-staging` | does not directly block promotion |
| `dev-pr-gate` fails on promotion PR | promotion PR stays open/failed | fix in `dev-staging`, rerun or regenerate cut | dev does not advance |
| `dev-soak/cuj-*=failure` set manually (`set-dev-soak-status`; `monitor-dev-cuj` 는 동결) | create/update issue | fix PR to `dev-staging`, next `dev-staging-dev-cut` creates new dev commit | `dev-rc-cut-gate` must not write `dev-rc-cut-pass` |
| `sync-mds-render-snapshot` fails on dev push | set `mds-render/snapshot=failure`, create/update infra issue | fix workflow/render infra or app render issue via `dev-staging` | visual review cannot pass; `dev-rc-cut-gate` blocks if app AI review is required |
| AI visual review finds blocker | set `dev-soak/app-ai-review=failure`, create one fix issue per confirmed finding | AI fix PR to `dev-staging`, next `dev-staging-dev-cut` creates new dev commit | `dev-rc-cut-gate` must not write `dev-rc-cut-pass` |
| `deploy-dev-event-flow-cron` or simulator fails | set `dev-soak/backend-simulator=failure`, create/update issue | AI fix PR to `dev-staging` | `dev-rc-cut-gate` blocks RC eligibility |
| `dev-rc-cut-gate` missing evidence | no pass marker; cut issue stays waiting | required monitor/status writer reruns or fix PR lands | `dev-rc-cut` skips this commit |
| `dev-rc-cut` cannot find pass commit | skip and alert if prolonged | run/fix `dev-rc-cut-gate` evidence | no RC branch cut |
| `rc-pr-gate` fails | hotfix PR stays unmerged | fix cherry-pick branch or source dev-staging PR | RC HEAD unchanged |
| `rc-deploy` fails | create/update P0/P1 issue | fix via dev-staging-first hotfix, then RC cherry-pick | `rc-main-cut-gate` cannot pass |
| `rc-soak/*` fails or dogfooding blocker appears | set `rc-soak/*=failure`, create/update issue | dev-staging fix PR -> RC cherry-pick PR -> `rc-deploy` | RC 5-day clock resets after hotfix merge |
| `rc-main-cut-gate` missing evidence/age | no `rc-main-cut-pass` | wait, rerun monitor, or fix RC | `rc-main-cut` skips |
| `main-pr-gate` fails | main promotion PR stays failed or is closed for hard policy violation | fix RC or regenerate promotion | main does not advance |
| `main-deploy` fails | create P0/P1 deploy issue | deploy retry or hotfix via normal flow | source already on main; prod recovery is incident process |

No automatic revert is part of the normal contract. Broken `dev` keeps moving through the normal dev-staging fix path. Broken RC is fixed by dev-staging-first hotfix and RC cherry-pick. Catastrophic RC can be abandoned by release manager.

## CUJ Contract (동결 — web-mvp pivot)

> **2026-06-06 동결.** Flutter 앱 동결로 `monitor-dev-cuj` 는 disable 되었고 dev commit 의 CUJ 자동 실행 의무는 폐지됐다. `dev-soak/cuj-*` 는 `set-dev-soak-status` 수동 블락 레버로만 남는다. 웹 MVP smoke/CUJ 신호를 required evidence 로 추가하는 것이 후속 과제다. 상세: [web-mvp-pivot.md](../../architecture/web-mvp-pivot.md)

기존 계약 (모바일 재개 시 참고): CUJ is not a PR gate. Every new `dev` commit must run user and partner CUJ unconditionally; the runner aggregates failures before returning non-zero.

| Workflow | Trigger | Writes |
|----------|---------|--------|
| `monitor-dev-cuj` (disabled) | ~~`push` to `dev`~~, manual dispatch | `dev-soak/cuj-user`, `dev-soak/cuj-partner`, CI issue with failed CUJ file list |

## MDS Render Snapshot Contract

MDS render snapshots are dev health evidence, not source code. The promoted `dev` SHA is the canonical visual candidate.

| Item | Contract |
|------|----------|
| Source | latest promoted `dev` commit SHA |
| Storage branch | `artifacts/mds-render` |
| Storage path | `snapshots/dev/<dev-sha>/<screen>/state-*.png` |
| Status | `mds-render/snapshot` on the same `dev` SHA |
| Consumer | AI visual review / human audit |
| Fix path | fix PR to `dev-staging`; never commit PNG or fixes directly to `dev` |

Workflow:

1. `dev-staging-dev-cut` promotes a source snapshot to `dev`.
2. `push` to `dev` triggers the MDS render snapshot writer.
3. The writer renders emulator PNGs for the promoted `dev` SHA and commits them only to `artifacts/mds-render`.
4. The writer sets `mds-render/snapshot=success` with a target URL/path to `snapshots/dev/<dev-sha>/`; on failure it sets `failure` and files an issue.
5. If the artifact commit changed PNGs, the writer dispatches `mds_render_snapshot_archived`; `triage-mds-render-snapshot-diff` runs from the default branch and files a visual review issue when PNG diffs are present.
6. The AI visual review agent fetches `artifacts/mds-render`, compares `snapshots/dev/<dev-sha>/` against MDS spec assets, and triages findings.
7. The review issue is not the fix tracker. Each confirmed visual blocker gets a separate fix issue with enough screen/state/snapshot/spec detail for an AI worker to fix it.
8. If at least one blocker is confirmed, the agent writes `dev-soak/app-ai-review=failure` on the source dev SHA, using the review or representative finding issue as `target_url`.
9. If no blocker is found, the agent writes `dev-soak/app-ai-review=success` on the same SHA and closes the review issue with evidence.
10. Visual blockers are fixed through normal `dev-staging` PR flow and reach `dev` in the next promotion.

`artifacts/mds-render` is not a promotion source and is not merged into `dev`, `rc`, or `main`. It is an archive branch and does not carry source workflow files; dispatch from `sync-mds-render-snapshot` is the trigger contract for triage. `latest` pointers may exist for convenience, but gate logic must use SHA-bound paths and commit statuses.

## Query Examples

```bash
git tag -l 'v*-dev-staging'
git tag -l 'promo/rc-*'
git tag -l 'promo/main-*'
```

```bash
gh api repos/<owner>/<repo>/commits/<sha>/status \
  --jq '.statuses[] | select(.context == "dev-rc-cut-pass" or .context == "mds-render/snapshot" or (.context | startswith("dev-soak/")))'
```

```bash
gh workflow list --all --limit 200 | grep -E 'dev-rc-cut|rc-main-cut|monitor-dev-cuj'
```

---
_Reviewed: 2026-06-04 22:11_
