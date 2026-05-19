# Branch Flow

`dev-staging → dev → rc → main` 4-stage 모델의 머지 방향, branch protection, promotion tag, auto-deploy chain.

## 흐름 다이어그램

```
  agents ──merge queue──▶ dev-staging
                              │
                              └─daily nightly-cut snapshot──▶ dev
                                                              │
                                                              ├─▶ rc-gate (post-merge 자동)
                                                              │      │
                                                              │      ├─ pass: status rc-gate-pass
                                                              │      │         │
                                                              │      │         ├─▶ deploy-supabase (EF + migration)
                                                              │      │         └─▶ deploy-vercel (4앱)
                                                              │      │
                                                              │      └─ fail: 자동 이슈 + AI agent fix via dev-staging (no auto-revert)
                                                              │
                                                              └─weekly rc-cut (최신 rc-gate-pass commit)──▶ rc/YYYY-Wxx
                                                                                                              │
                                                                                                              └─5일 soak (hotfix 시 시계 리셋)──▶ main
                                                                                                                                                    │
                                                                                                                                                    └─main-post-merge-promote
                                                                                                                                                              │
                                                                                                                                                              ├─▶ deploy-android-{user,partner} ──▶ Play Store
                                                                                                                                                              └─▶ deploy-ios-{user,partner} ──▶ App Store Connect
                                                                                                                                                                              (push: main trigger 로 자동, 병렬)
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
| feature/agent → dev-staging | `dev-staging` ← `feat/*`, `fix/*`, `chore/*`, `docs/*` | merge queue enqueue | **squash** (queue) | `dev-staging-pr-gate` |
| dev-staging → dev | `dev` ← `dev-staging` | daily cron `nightly-cut` | merge (snapshot) | `nightly-pr-gate` |
| hotfix → rc | `rc/YYYY-Wxx` ← hotfix branch | hotfix only | rebase | `rc-pr-gate` |
| rc → main | `main` ← `rc/YYYY-Wxx` | `rc-soak-check` 가 5일 무커밋 시 PR 생성 + auto-merge | rebase + ff | `main-pr-gate` + `rc-soak-passed` |

## Branch Protection 설정

| 브랜치 | direct push | linear | required check | merge 종류 |
|--------|-------------|--------|----------------|------------|
| `dev-staging` | 금지 | **ON** | `dev-staging-pr-gate` + merge queue | squash |
| `dev` | 금지 | **ON** | `nightly-pr-gate` | merge (snapshot) |
| `rc/YYYY-Wxx` | 금지 | **ON** | `rc-pr-gate` | rebase |
| `main` | 금지 | **ON** | `main-pr-gate` + `rc-gate-pass` (RC HEAD) + `expand-migrate-contract` + `rc-soak-passed` | rebase |

Hybrid linear history 금지 — 각 branch 내 일관 (squash or rebase 한 가지).

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

### dev rc-gate-pass → backend/web (continuous)

```yaml
# 개념
rc-gate (on push to dev):
  needs: pass
  parallel:
    - uses: ./.github/workflows/deploy-supabase.yml  # EF + migration
    - uses: ./.github/workflows/deploy-vercel.yml    # 4앱
```

### main push → mobile (every release)

```yaml
# 개념
main-post-merge-promote (on push to main):
  steps:
    - tag v{ver} + promo/main-Wxx + Sentry marker
    - Firebase RC `latest_version` = v{ver} 자동 update
  parallel:
    # (실제로는 workflow_call 아닌 push: main trigger 로 기존 deploy-* workflows 자동 발동)
    # - deploy-android-user / deploy-android-partner
    # - deploy-ios-user / deploy-ios-partner
```

상세: [specs/workflow-spec.md](./specs/workflow-spec.md).

## Safety Nets 위치

| Safety Net | 실행 위치 |
|------------|-----------|
| Version kill switch (soft/hard) | Firebase RC. soft `latest_version` = `main-post-merge-promote` 가 매 main 머지마다 자동 update / hard `kill_list_hard` = 내부 admin page manual (catastrophic only) |
| expand-migrate-contract CI | `dev-staging-pr-gate` (destructive op 탐지) + `main-pr-gate` (재검증) |
| flag-registration CI | `dev-staging-pr-gate` |

## 결정해야 할 것

- 주간 rc-cut 요일
- merge queue 모드 (concurrent vs serial)
- Fastlane / store upload 설정
- `RELEASE.md` 작성

---
_Reviewed: 2026-05-19 09:47_
