# Versioning & Tags

4-stage 모델 (`dev-staging → dev → rc → main`) 위에서의 버전/태그 컨벤션. 소스 파일 version bump 는 `dev-staging` coherent snapshot 에만 남기고, `dev`/`rc`/`main` 배포 산출물은 deploy-time metadata 로 버전을 주입한다.

## 기본 형식

| 구성요소 | 설명 | 예시 |
|----------|------|------|
| `YYYY` | 연도 4자리 | `2026` |
| `M` | 월 번호 | `5` |
| `PR#` | 머지된 PR 번호 (cumulative across repo) | `2572` |

- deploy artifact versionName: `YYYY.M.PR#[-channel]` — 예: `2026.5.2572-dev`, `2026.5.2572-rc`, `2026.5.2572`
- mobile build number / Android versionCode: `PR#` — 예: `2572`

> Store 에 이미 더 높은 Android versionCode 가 올라간 경우 PR# 단독 versionCode 는 migration rule 이 필요하다. 신규 업로드 전 Play Console 의 latest versionCode 를 확인한다.

## 단계별 채널 suffix

| Stage | Suffix | 예시 |
|-------|--------|------|
| dev-staging source snapshot | `-dev-staging` | `26.05.2572-dev-staging` (source file only) |
| dev artifact | `-dev` | `2026.5.2572-dev` |
| rc artifact | `-rc` | `2026.5.2572-rc` |
| main artifact | 없음 | `2026.5.2572` |

**원칙**: PR# 은 실제 source revision 을 설명하는 값이다. `dev`/`rc`/`main` branch 에는 version bump commit 을 만들지 않고, deploy workflow 가 source commit 에서 PR# 를 역추적해 build metadata 로 주입한다.

## Version Bump 위치

| Workflow | When | What |
|----------|------|------|
| `dev-staging-dev-cut-gate` | dev-staging PR 머지 직후 | `bump-version.sh {YY.MM.PR#}-dev-staging` + `v{YY.MM.PR#}-dev-staging` tag |
| `dev-staging-dev-cut` | daily snapshot 생성 시 | version 변경 없음 |
| `dev-rc-cut` | RC 브랜치 생성 시 | version 변경 없음. `rc/YYYY-Wxx` branch + `promo/rc-YYYY-Wxx` tag 만 생성 |
| RC hotfix merge | RC hotfix 머지 직후 | version 변경 없음. RC deploy metadata 가 최신 PR# 를 사용 |
| `main-deploy` | main push 직후 | version 변경 없음. deploy-time metadata + release asset/tag/marker 생성 |

`version-bump` reusable 은 현재 `dev-staging-dev-cut-gate` 전용으로 남긴다. `dev`/`rc`/`main` 에 자동 version commit 을 만들지 않는다.

## Tag 컨벤션

| Tag / Status | 시점 | 예시 | 부여자 |
|--------------|------|------|--------|
| `v{ver}-dev-staging` (tag) | dev-staging post-merge | `v26.05.2572-dev-staging` | workflow |
| `dev-rc-cut-pass` (commit status) | dev 머지 후 dev-rc-cut-gate green | (status only, tag 없음) | workflow |
| `promo/rc-YYYY-Wxx` (tag) | dev-rc-cut 직후 | `promo/rc-2026-W20` | workflow |
| `promo/main-YYYY-Wxx` (tag) | main 머지 직후 (동시) | `promo/main-2026-W20` | workflow |

`Wxx` = ISO week number (예: 2026-W20 = 2026년 20주차).

> **Tag naming regex 는 [`RELEASE.md`](../../../RELEASE.md) lock** (TODO). Sentry, Statsig, Vercel, App Store 가 모두 pin. rename = 모든 dashboard 깨짐.

조회:
- `git tag -l 'v*-dev-staging'` (dev-staging coherent snapshot)
- `git tag -l 'promo/main-*'` (weekly main promotion event)
- `git log --first-parent main` (main 의 promotion 이벤트, rebase 라 사실상 linear)
- `gh api repos/.../commits/{sha}/status` (dev-rc-cut-pass 확인)

## 동일 PR# 가 여러 단계 등장하는 의미

| 상태 | 의미 |
|------|------|
| `26.05.2572-dev-staging` | dev-staging source snapshot version/tag |
| `2026.5.2572-dev` | dev branch deploy artifact version |
| `2026.5.2572-rc` | rc branch deploy artifact version |
| `2026.5.2572` | main branch deploy artifact version |

source-controlled `26.05.*-dev-staging` 과 deploy artifact `2026.5.*` 는 목적이 다르다. 전자는 coherent snapshot marker, 후자는 사용자/스토어/릴리즈 에셋에 노출되는 build metadata 다.

## 버전 관리 제외 대상 (기존 유지)

- `tests/test_data_seeder`
- `tests/backend_integration`
- `apps/integration_scenario_tester`

## 결정해야 할 것

- mobile release branch hotfix 의 PR# 출처 (cherry-pick PR# 인가 새 PR# 인가)
- `RELEASE.md` 작성 (tag regex single source)
- Android Play Console 기존 versionCode 가 PR# 단독 값보다 큰 경우 migration rule

## 관련

- [branch-flow.md](./branch-flow.md) — promotion tag 사용 맥락
- [dev-staging-pipeline.md](./dev-staging-pipeline.md), [rc-promotion.md](./rc-promotion.md), [main-promotion.md](./main-promotion.md) — 각 stage 의 bump trigger
- 기존 [CLAUDE.md "Versioning Conventions"](../../../CLAUDE.md#versioning-conventions) — 원본

---
_Reviewed: 2026-05-24 10:24_
