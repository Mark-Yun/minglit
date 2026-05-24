# Branch Flow

`dev-staging → dev → rc → main` 4-stage 모델의 머지 방향, branch protection, promotion tag, deploy/validation chain.

## 흐름 다이어그램

```
  agents ──PR + auto-merge──▶ dev-staging
                              │
                              └─daily nightly-cut linear snapshot PR──▶ dev
                                                              │
                                                              ├─▶ rc-gate (post-merge 자동)
                                                              │      │
                                                              │      ├─ pass: status rc-gate-pass
                                                              │      │         │
                                                              │      │         └─▶ monitor-event-flow-* batch signal keeps running
                                                              │      │
                                                              │      └─ fail: 자동 이슈 + AI agent fix via dev-staging (no auto-revert)
                                                              │
                                                              └─weekly rc-cut (최신 rc-gate-pass commit)──▶ rc/YYYY-Wxx
                                                                                                              │
                                                                                                              ├─▶ rc-deploy (Supabase branching + pre-main validation)
                                                                                                              │
                                                                                                              └─5일 soak (hotfix 시 시계 리셋)──▶ main-cut
                                                                                                                                                    │
                                                                                                                                                    └─main-deploy (prod deploy chain)
                                                                                                                                                              │
                                                                                                                                                              ├─▶ backend prod deploy (Supabase migration + EF)
                                                                                                                                                              ├─▶ deploy-android-{user,partner} ──▶ Play Store
                                                                                                                                                              ├─▶ deploy-ios-{user,partner} ──▶ App Store Connect
                                                                                                                                                              └─▶ Vercel production (native, main branch)
```

**Hotfix backport 흐름** (rc → dev-staging):

```
rc/* hotfix 머지 ──auto cherry-pick──▶ backport-branch ──PR──▶ dev-staging
```

상세는 [rc-promotion.md](./rc-promotion.md).

> Mobile cadence = hotfix 없으면 weekly (rc → main 머지 마다 자동 build/deploy). store review + staged rollout 은 외부 (workflow 밖).

## 단계별 PR 룰

| 머지 방향 | base ← head | 트리거 | 머지 방식 | 요구 체크 |
|-----------|-------------|--------|-----------|-----------|
| feature/agent → dev-staging | `dev-staging` ← `feat/*`, `fix/*`, `chore/*`, `docs/*` | PR + auto-merge | **squash** | `dev-staging-pr-gate` |
| dev-staging → dev | `dev` ← `nightly/YYYY-MM-DD-{sha8}` at latest `v*-dev-staging` tag | daily cron `nightly-cut` | rebase (linear snapshot) | `nightly-pr-gate` |
| hotfix → rc | `rc/YYYY-Wxx` ← hotfix branch | hotfix only | rebase | `rc-pr-gate` |
| rc → main | `main` ← `rc/YYYY-Wxx` | `main-cut` 이 5일 무커밋 시 PR 생성 + auto-merge | rebase + ff | `main-pr-gate` |

## Branch Protection 설정

| 브랜치 | direct push | linear | required check | merge 종류 |
|--------|-------------|--------|----------------|------------|
| `dev-staging` | 금지 (release bot 예외) | **ON** | `dev-staging-pr-gate` | squash |
| `dev` | 금지 | **ON** | `nightly-pr-gate` | rebase (linear snapshot) |
| `rc/YYYY-Wxx` | 금지 | **ON** | `rc-pr-gate` | rebase |
| `main` | 금지 (release bot 예외) | **ON** | `main-pr-gate` | rebase |

Hybrid linear history 금지 — 각 branch 내 일관 (squash or rebase 한 가지). `dev` 는 active ruleset 의 linear history 와 맞추기 위해 nightly promotion 도 rebase 를 사용한다. Protected branch 직접 push 는 `minglit-release-bot` 의 version bump/tag/promotion commit 에만 Ruleset bypass 로 허용한다.

## Promotion Tag 컨벤션

| Tag / Status | 시점 | 예시 | 부여자 |
|--------------|------|------|--------|
| `v{ver}-dev-staging` (tag) | dev-staging-post-merge-sync | `v26.05.2572-dev-staging` | workflow |
| `rc-gate-pass` (commit status) | rc-gate green 시 dev commit 에 | (status only, tag 없음) | workflow |
| `promo/rc-YYYY-Wxx` (tag) | rc-cut 직후 | `promo/rc-2026-W20` | workflow |
| `v{ver}-rc-NN` (tag) | rc-cut + hotfix | `v26.05.2572-rc-01`, `v26.05.2585-rc-02` | workflow |
| `promo/main-YYYY-Wxx` (tag) | main 머지 직후 | `promo/main-2026-W20` | workflow |
| `v{ver}` (tag) | main 머지 직후 (동시) | `v26.05.2585` | workflow |

> **Tag naming regex 는 [`RELEASE.md`](../../../RELEASE.md) lock** (TODO). 외부 도구 (Sentry, Statsig, Vercel, App Store, Play Console) 가 pin → rename = 모든 dashboard 깨짐.

조회: `git tag -l 'v*'`, `git tag -l 'promo/main-*'`, `gh api repos/.../commits/{sha}/status` (rc-gate-pass)

## Auto-deploy Chain

### dev validation signal

```yaml
# 개념 — release promotion 과 독립적인 batch signal
monitor-event-flow-*:
  schedule: continuous
  branch: dev
  purpose: backend/event-flow simulation signal
```

### main push → prod deploy chain

```yaml
# 개념 — backend + mobile 모두 prod
main-deploy (on push to main):
  steps:
    - tag v{ver} + promo/main-Wxx + Sentry marker
    - Firebase RC `latest_version` = v{ver} 자동 update
  parallel:
    - backend prod deploy  # Supabase migration + EF
    - uses: ./.github/workflows/deploy-android-{user,partner}.yml
    - uses: ./.github/workflows/deploy-ios-{user,partner}.yml
    # Vercel: native build 가 main branch → production deployment
```

상세: [specs/workflow-spec.md](./specs/workflow-spec.md).

## Safety Nets 위치

| Safety Net | 실행 위치 |
|------------|-----------|
| Version kill switch (soft/hard) | Firebase RC. soft `latest_version` = `main-deploy` 가 매 main 머지마다 자동 update / hard `kill_list_hard` = 내부 admin page manual (catastrophic only) |
| expand-migrate-contract CI | `dev-staging-pr-gate` (destructive op 탐지) + `main-pr-gate` (재검증) |
| flag-registration CI | `dev-staging-pr-gate` |

## 결정해야 할 것

- 주간 rc-cut 요일
- Fastlane / store upload 설정
- `RELEASE.md` 작성

---
_Reviewed: 2026-05-24 10:24_
