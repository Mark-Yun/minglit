# Branch Flow

`dev-staging → dev → rc → main` 4-stage 모델의 머지 방향, branch protection, promotion tag, deploy/validation chain. Concrete workflow/status/tag/failure contract 는 [promotion-contract.md](./promotion-contract.md) 를 기준으로 한다.

## 흐름 다이어그램

```
  agents ──PR + auto-merge──▶ dev-staging
                              │
                              └─daily dev-staging-dev-cut merge-commit snapshot PR──▶ dev
                                                              │
                                                              ├─▶ dev push health/deploy + MDS render snapshot + daily dev-rc-cut-gate
                                                              │      │
                                                              │      ├─ visual evidence: artifacts/mds-render/snapshots/dev/<sha>/
                                                              │      │
                                                              │      ├─ pass: status dev-rc-cut-pass
                                                              │      │         │
                                                              │      │         └─▶ monitor-event-flow-* batch signal keeps running
                                                              │      │
                                                              │      └─ fail: 자동 이슈 + AI agent fix via dev-staging (no auto-revert)
                                                              │
                                                              └─weekly dev-rc-cut (최신 dev-rc-cut-pass commit)──▶ rc/YYYY-Wxx
                                                                                                              │
                                                                                                              ├─▶ rc-deploy (Supabase branching + pre-main validation)
                                                                                                              │
                                                                                                              └─5일 soak (hotfix 시 시계 리셋)──▶ rc-main-cut
                                                                                                                                                    │
                                                                                                                                                    └─main-deploy (prod deploy chain)
                                                                                                                                                              │
                                                                                                                                                              ├─▶ backend prod deploy (Supabase migration + EF)
                                                                                                                                                              ├─▶ deploy-android-{user,partner} ──▶ Play Store
                                                                                                                                                              ├─▶ deploy-ios-{user,partner} ──▶ App Store Connect
                                                                                                                                                              └─▶ Vercel production (native, main branch)
```

**Hotfix 흐름** (정상 source 는 dev-staging):

```
dev/hotfix/* ──PR──▶ dev
dev-staging fix PR ──merge──▶ dev-staging ──cherry-pick/promote──▶ rc/YYYY-Wxx
main/hotfix/* ──PR──▶ main ──backport──▶ dev-staging (+ active rc/* if needed)
```

상세는 [hotfix-policy.md](./hotfix-policy.md) 와 [rc-promotion.md](./rc-promotion.md).

RC hotfix 는 dev-staging-first 가 기본이다. active RC 에만 먼저 들어가는 RC-only hotfix 는 release-manager override 가 필요한 예외이며, 다음 RC 재출현 방지를 위해 dev-staging follow-up 이 필수다.

> Mobile cadence = hotfix 없으면 weekly (rc → main 머지 마다 자동 build/deploy). store review + staged rollout 은 외부 (workflow 밖).

## 단계별 PR 룰

| 머지 방향 | base ← head | 트리거 | 머지 방식 | 요구 체크 |
|-----------|-------------|--------|-----------|-----------|
| feature/agent → dev-staging | `dev-staging` ← `feat/*`, `fix/*`, `chore/*`, `docs/*` | PR + auto-merge | **squash** | `dev-staging-pr-gate` |
| dev-staging → dev | `dev` ← `cut/dev-staging-dev/YYYY-MM-DD-{sha8}` at daily cut-time `v*-dev-staging` tag | daily cron `dev-staging-dev-cut` | merge commit (snapshot ancestry 보존) | `dev-pr-gate` |
| hotfix → dev | `dev` ← `dev/hotfix/*` | approved hotfix only | approved hotfix merge | `dev-pr-gate` |
| hotfix → rc | `rc/YYYY-Wxx` ← dev-staging fix cherry-pick branch | dev-staging-first approved hotfix only | approved hotfix merge | `rc-pr-gate` |
| rc → main | `main` ← `rc/YYYY-Wxx` | `rc-main-cut` 이 5일 무커밋 시 PR 생성 + auto-merge | merge commit (RC ancestry 보존) | `main-pr-gate` |
| hotfix → main | `main` ← `main/hotfix/*` | approved + release-manager hotfix only | approved hotfix merge | `main-pr-gate` |

## Branch Protection 설정

| 브랜치 | direct push | linear | required check | merge 종류 |
|--------|-------------|--------|----------------|------------|
| `dev-staging` | 금지 (release bot 예외) | **ON** | `dev-staging-pr-gate` | squash |
| `dev` | 금지 | **OFF** | `dev-pr-gate` | merge commit for promotion |
| `rc/YYYY-Wxx` | 금지 | **OFF** | `rc-pr-gate` | approved hotfix merge |
| `main` | 금지 (release bot 예외) | **OFF** | `main-pr-gate` | merge commit for promotion |
| `artifacts/mds-render` | workflow only | n/a | n/a | SHA-bound PNG archive, not a promotion branch |

Global linear history 정책은 폐기한다. 일반 작업 PR 은 `dev-staging` 에서 squash 로 정리하고, branch promotion PR 은 source branch ancestry 를 보존하기 위해 merge commit 을 사용한다. Protected branch 직접 push 는 `minglit-release-bot` 의 dev-staging version bump, promotion branch/tag, RC cleanup 에만 Ruleset bypass 로 허용한다.

## Artifact Branch

`artifacts/mds-render` 는 source branch 가 아니라 Git-backed visual evidence archive 다.

| 규칙 | 내용 |
|------|------|
| canonical path | `snapshots/dev/<dev-sha>/<screen>/state-*.png` |
| writer | dev push 후 MDS render snapshot workflow |
| consumer | `triage-mds-render-snapshot-diff`, AI visual review / human audit |
| status | source dev SHA 의 `mds-render/snapshot` |
| 금지 | `dev-staging`, `dev`, `rc/*`, `main` 에 PNG snapshot 커밋 |

`triage-mds-render-snapshot-diff` 는 snapshot PNG diff 가 생기면 AI visual review issue 를 만든다. AI visual review 가 blocker 를 찾으면 `dev-soak/app-ai-review=failure` 를 쓰고, fix 는 일반 flow 처럼 `dev-staging` PR 로 들어간다.

## Promotion Tag 컨벤션

| Tag / Status | 시점 | 예시 | 부여자 |
|--------------|------|------|--------|
| `v{ver}+{build}-dev-staging` (tag) | dev-staging-dev-cut direct bump commit | `v26.06.01+26060101-dev-staging` | workflow |
| `dev-rc-cut-pass` (commit status) | dev-rc-cut-gate green 시 dev commit 에 | (status only, tag 없음) | workflow |
| `promo/rc-YYYY-Wxx` (tag) | dev-rc-cut 직후 | `promo/rc-2026-W20` | workflow |
| `promo/main-YYYY-Wxx` (tag) | main 머지 직후 | `promo/main-2026-W20` | workflow |
| `build-{channel}-v{version}+{build}` (GitHub Release) | deploy artifact archive | `build-dev-v26.05.27-dev+2832` | deploy workflow |

> **Tag naming regex 는 [`RELEASE.md`](../../../RELEASE.md) lock** (TODO). 외부 도구 (Sentry, Statsig, Vercel, App Store, Play Console) 가 pin → rename = 모든 dashboard 깨짐.

조회: `git tag -l 'v*'`, `git tag -l 'promo/main-*'`, `gh api repos/.../commits/{sha}/status` (dev-rc-cut-pass)

## Auto-deploy Chain

### dev validation signal

```yaml
# 개념 — release promotion 과 독립적인 batch signal
monitor-event-flow-*:
  schedule: continuous
  branch: dev
  purpose: backend/event-flow simulation signal

monitor-dev-staging-health:
  schedule: every 6 hours
  branch: dev-staging
  purpose: EF unit/integration early regression signal

monitor-dev-cuj:  # disabled (web-mvp pivot — Flutter CUJ 동결)
  trigger: manual dispatch only
  branch: dev
  purpose: (legacy) user/partner CUJ health signal

sync-mds-render-snapshot:
  trigger: push to dev
  branch: dev
  purpose: MDS render PNG archive + mds-render/snapshot status
```

### main push → prod deploy chain

```yaml
# 개념 — backend + mobile 모두 prod
main-deploy (on push to main):
  steps:
    - compute deploy-time version metadata: YY.MM.DD + snapshot build number
    - tag promo/main-Wxx + Sentry marker
    - Firebase RC `latest_version` = computed version 자동 update
  parallel:
    - backend prod deploy  # Supabase migration + EF
    - uses: ./.github/workflows/deploy-android-{user,partner}.yml
    - uses: ./.github/workflows/deploy-ios-{user,partner}.yml
    # Vercel: native build 가 main branch → production deployment
```

상세: [specs/workflow-spec.md](./specs/workflow-spec.md).

Mobile APK/AAB/IPA archive 는 GitHub Release asset 이 canonical 이다. Actions artifact 는 workflow 실패 분석용 테스트 리포트/스크린샷/로그 같은 단기 디버깅 산출물에만 사용한다. MDS render PNG 처럼 SHA-bound visual evidence 로 재조회해야 하는 산출물은 `artifacts/mds-render` branch 에 보존한다.

## Safety Nets 위치

| Safety Net | 실행 위치 |
|------------|-----------|
| Version kill switch (soft/hard) | Firebase RC. soft `latest_version` = `main-deploy` 가 매 main 머지마다 자동 update / hard `kill_list_hard` = 내부 admin page manual (catastrophic only) |
| expand-migrate-contract CI | `dev-staging-pr-gate` (destructive op 탐지) + `main-pr-gate` (재검증) |
| flag-registration CI | `dev-staging-pr-gate` |

## 결정해야 할 것

- 주간 dev-rc-cut 요일
- Fastlane / store upload 설정
- `RELEASE.md` 작성

## 관련

- [promotion-contract.md](./promotion-contract.md) — 승격 정책 + concrete marker/failure contract

---
_Reviewed: 2026-06-04 22:11_
