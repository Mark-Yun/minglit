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
                                                              │      │         ├─▶ backend-auto-deploy (EF + migration)
                                                              │      │         └─▶ web-auto-deploy (Vercel 4앱)
                                                              │      │
                                                              │      └─ fail: bot 자동 이슈 + AI fix PR 경로
                                                              │
                                                              └─weekly rc-cut (최신 rc-gate-pass commit)──▶ rc/YYYY-Wxx
                                                                                                              │
                                                                                                              └─5일 soak (hotfix 시 시계 리셋)──▶ main
                                                                                                                                                    │
                                                                                                                                                    └─monthly mobile-cut──▶ release/mobile-YYYY-MM
                                                                                                                                                                                  │
                                                                                                                                                                                  └─ App Store
```

**Hotfix backport 흐름** (rc → dev-staging):

```
rc/* hotfix 머지 ──auto cherry-pick──▶ backport-branch ──PR──▶ dev-staging
```

상세는 [rc-promotion.md](./rc-promotion.md). Mobile cherry-pick 은 backport 불필요 (main 에서 cherry-pick 한 commit 은 이미 dev-staging 에 존재).

## 단계별 PR 룰

| 머지 방향 | base ← head | 트리거 | 머지 방식 | 요구 체크 |
|-----------|-------------|--------|-----------|-----------|
| feature/agent → dev-staging | `dev-staging` ← `feat/*`, `fix/*`, `chore/*`, `docs/*` | merge queue enqueue | **squash** (queue) | `dev-staging-pr-gate` |
| dev-staging → dev | `dev` ← `dev-staging` | daily cron `nightly-cut` | merge (snapshot) | `nightly-pr-gate` |
| feature → rc | `rc/YYYY-Wxx` ← hotfix branch | hotfix only | rebase | `rc-pr-gate` |
| rc → main | `main` ← `rc/YYYY-Wxx` | `rc-soak-check` 가 5일 무커밋 시 PR 생성 + auto-merge | rebase + ff | `main-pr-gate` + `rc-soak-passed` |
| main → release/mobile-YYYY-MM | branch cut | monthly cron `mobile-cut` | branch 신규 생성 | mobile smoke |

## Branch Protection 설정

| 브랜치 | direct push | linear | required check | merge 종류 |
|--------|-------------|--------|----------------|------------|
| `dev-staging` | 금지 | **ON** | `dev-staging-pr-gate` + merge queue | squash |
| `dev` | 금지 | **ON** | `nightly-pr-gate` | merge (snapshot) |
| `rc/YYYY-Wxx` | 금지 | **ON** | `rc-pr-gate` | rebase |
| `main` | 금지 | **ON** | `main-pr-gate` + `rc-gate-pass` (RC HEAD) + `expand-migrate-contract` + `rc-soak-passed` | rebase |
| `release/mobile-*` | 금지 | ON | mobile smoke | rebase (cherry-pick) |

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
| `release/mobile-YYYY-MM` (branch) | mobile-cut | `release/mobile-2026-05` | workflow |

> **Tag naming regex 는 [`RELEASE.md`](../../../RELEASE.md) lock** (TODO). 외부 도구 (Sentry, Statsig, Vercel) 가 pin → rename = 모든 dashboard 깨짐.

조회: `git tag -l 'v*'`, `git tag -l 'promo/main-*'`, `gh api repos/.../commits/{sha}/status` (rc-gate-pass)

## Auto-deploy Chain

dev 의 `rc-gate-pass` status 가 set 되는 즉시 `rc-gate` workflow 가 `workflow_call` 로 호출:

```yaml
# 개념
trigger-deploys:
  needs: rc-gate (green)
  parallel:
    - uses: ./.github/workflows/backend-auto-deploy.yml  # EF + migration
    - uses: ./.github/workflows/web-auto-deploy.yml      # Vercel 4앱
```

Mobile 은 별도 cadence — main 에서 monthly cut.

## Safety Nets 위치

| Safety Net | 실행 위치 |
|------------|-----------|
| min-version endpoint | server-side, `mobile-cut` 시점에 monthly auto-bump ([main-promotion.md](./main-promotion.md)) |
| expand-migrate-contract CI | `dev-staging-pr-gate` (destructive op 탐지) + `main-pr-gate` (재검증) |
| flag-registration CI | `dev-staging-pr-gate` |

## 결정해야 할 것

- 주간 rc-cut 요일
- monthly mobile-cut 날짜
- merge queue 모드 (concurrent vs serial)
- cherry-pick 자동화 도구 선정 (Runway/Xray/자체)
- `RELEASE.md` 작성

---
_Reviewed: 2026-05-19 09:47_
