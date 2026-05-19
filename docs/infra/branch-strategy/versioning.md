# Versioning & Tags

4-stage 모델 (`dev-staging → dev → rc → main`) 위에서의 CalVer (`YY.MM.PR#`) 적용 + tag 컨벤션. 기존 CLAUDE.md 의 "Versioning Conventions" 를 4-stage + flag 모델에 맞게 보강.

## 기본 형식 (기존 유지)

| 구성요소 | 설명 | 예시 |
|----------|------|------|
| `YY` | 연도 2자리 | `26` |
| `MM` | 월 2자리 | `05` |
| `PR#` | 머지된 PR 번호 (cumulative across repo) | `2572` |

- mobile versionCode: `YYMM * 10000 + PR#` — 예: `26052572`

> CLAUDE.md 의 "새 월이면 .1 시작" 은 `scripts/bump-version.sh` 와 불일치 — 실제론 PR# 가 cumulative. CLAUDE.md 정정 PR 별도 권장.

## 단계별 Suffix

| Stage | Suffix | 예시 |
|-------|--------|------|
| dev-staging | `-dev-staging` | `26.05.2572-dev-staging` |
| dev (nightly-cut snapshot) | (동일 suffix 유지, 새 bump 없음) | `26.05.2572-dev-staging` |
| rc (cut) | `-rc-NN` (N = 1) | `26.05.2572-rc-01` |
| rc (hotfix) | `-rc-NN` (N 증가) | `26.05.2585-rc-02` |
| main (final) | (없음) | `26.05.2585` |

**원칙**: PR# 은 dev-staging 머지 시점에 부여, 모든 stage 에서 동일 PR# 유지. RC hotfix 시 새 PR# (hotfix PR 의 번호) + `_rc-NN` 증가.

## Version Bump 위치

| Workflow | When | What |
|----------|------|------|
| `dev-staging-post-merge-sync` | dev-staging PR 머지 직후 | `bump-version.sh {PR#}-dev-staging` |
| `nightly-cut` | daily snapshot 생성 시 | version 변경 없음 (dev-staging 의 그대로 가져감) |
| `rc-cut` | RC 브랜치 생성 시 | `bump-version.sh {ver}-rc-01` |
| `rc-post-merge-sync` | RC hotfix 머지 직후 | `bump-version.sh {PR#}-rc-NN` (N 증가) |
| `main-post-merge-promote` | rc → main 머지 직후 | `bump-version.sh {ver}` (suffix 제거) |

## Tag 컨벤션

| Tag / Status | 시점 | 예시 | 부여자 |
|--------------|------|------|--------|
| `v{ver}-dev-staging` (tag) | dev-staging post-merge | `v26.05.2572-dev-staging` | workflow |
| `rc-gate-pass` (commit status) | dev 머지 후 rc-gate green | (status only, tag 없음) | workflow |
| `v{ver}-rc-NN` (tag) | rc-cut + hotfix | `v26.05.2572-rc-01`, `v26.05.2585-rc-02` | workflow |
| `promo/rc-YYYY-Wxx` (tag) | rc-cut 직후 | `promo/rc-2026-W20` | workflow |
| `v{ver}` (tag) | main 머지 직후 | `v26.05.2585` | workflow |
| `promo/main-YYYY-Wxx` (tag) | main 머지 직후 (동시) | `promo/main-2026-W20` | workflow |
| `release/mobile-YYYY-MM` (branch) | mobile-cut | `release/mobile-2026-05` | workflow |

`Wxx` = ISO week number (예: 2026-W20 = 2026년 20주차).

> **Tag naming regex 는 [`RELEASE.md`](../../../RELEASE.md) lock** (TODO). Sentry, Statsig, Vercel, App Store 가 모두 pin. rename = 모든 dashboard 깨짐.

조회:
- `git tag -l 'v*'` (모든 release version)
- `git tag -l 'promo/main-*'` (weekly main promotion event)
- `git log --first-parent main` (main 의 promotion 이벤트, rebase 라 사실상 linear)
- `gh api repos/.../commits/{sha}/status` (rc-gate-pass 확인)

## 동일 PR# 가 여러 단계 등장하는 의미

| 상태 | 의미 |
|------|------|
| `26.05.2572-dev-staging` | dev-staging 에 PR# 2572 머지된 시점 |
| `26.05.2572-rc-01` | 그 commit 이 rc 로 cut 된 시점 (rc-gate 통과 후) |
| `26.05.2585-rc-02` | RC 에 hotfix PR# 2585 가 머지된 시점 |
| `26.05.2585` | rc → main 머지 시 final version (RC 의 최종 hotfix version) |

PR# 가 dev-staging 에서 부여되고 같은 PR# 가 후속 단계에서 suffix 만 바뀌어 등장. 헷갈리지 않게 *suffix 가 stage 표시* 라는 룰 명확.

## 버전 관리 제외 대상 (기존 유지)

- `tests/test_data_seeder`
- `tests/backend_integration`
- `apps/integration_scenario_tester`

## 결정해야 할 것

- mobile release branch hotfix 의 PR# 출처 (cherry-pick PR# 인가 새 PR# 인가)
- main 비-promotion 변경의 version bump 룰 (긴급 hotfix 직접 push 시)
- `RELEASE.md` 작성 (tag regex single source)
- merge queue 가 squash commit 에 `bump-version.sh` 결과를 inline 시킬지 별도 commit 으로 둘지

## 관련

- [branch-flow.md](./branch-flow.md) — promotion tag 사용 맥락
- [dev-staging-pipeline.md](./dev-staging-pipeline.md), [rc-promotion.md](./rc-promotion.md), [main-promotion.md](./main-promotion.md) — 각 stage 의 bump trigger
- 기존 [CLAUDE.md "Versioning Conventions"](../../../CLAUDE.md#versioning-conventions) — 원본

---
_Reviewed: 2026-05-19 09:47_
