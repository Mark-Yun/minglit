# Versioning & Tags

4-stage 모델 (`dev-staging → dev → rc → main`) 위에서의 버전/태그 컨벤션. 소스 파일 version bump 는 `dev-staging` coherent snapshot 에만 남기고, `dev`/`rc`/`main` 배포 산출물은 deploy-time metadata 로 버전을 주입한다.

## 기본 형식

| 구성요소 | 설명 | 예시 |
|----------|------|------|
| `YY` | 연도 2자리 | `26` |
| `MM` | 월 2자리 | `05` |
| `DD` | KST 기준 snapshot 날짜 | `27` |
| `BUILD` | snapshot build number (`YYMMDDNN`) | `26060101` |

- deploy artifact versionName: `YY.MM.DD[-channel]` — 예: `26.05.27-dev`, `26.05.27-rc`, `26.05.27`
- mobile build number / Android versionCode: `BUILD` — 예: `26060101`
- full identity/tag: `vYY.MM.DD+BUILD[-channel]` — 예: `v26.06.01+26060101-dev-staging`

`BUILD` 는 PR 번호가 아니다. `dev-staging-dev-cut` 이 promote 하는 snapshot 기준으로 KST 날짜 `YYMMDD` + 같은 날짜 sequence `NN` 을 붙여 만든다. GitHub PR 번호는 생성 순서라 merge/promote 순서를 보장하지 않으므로 build number 로 쓰지 않는다.

## 단계별 채널 suffix

| Stage | Suffix | 예시 |
|-------|--------|------|
| dev-staging source snapshot | `-dev-staging` | `26.06.01-dev-staging+26060101` (Flutter), `26.06.01-dev-staging` (packages) |
| dev artifact | `-dev` | `26.06.01-dev+26060101` |
| rc artifact | `-rc` | `26.06.01-rc+26060101` |
| main artifact | 없음 | `26.06.01+26060101` |

**원칙**: 날짜와 build number 는 promote 된 snapshot 을 설명한다. 포함된 source PR 목록은 git first-parent history 와 promotion PR body, snapshot SHA 는 `v*-dev-staging` tag 로 추적한다.

## Version Bump 위치

| Workflow | When | What |
|----------|------|------|
| `dev-staging-dev-cut-gate` | 수동 점검 | active mutation 없음. candidate ref 의 snapshot tag 존재 여부만 inspect |
| `dev-staging-dev-cut` | daily snapshot 생성 시 | protected `dev-staging` 에 release bot 이 직접 version bump commit 을 fast-forward push 하고 `v{YY.MM.DD}+{BUILD}-dev-staging` tag 생성 후 dev PR promote |
| `dev-rc-cut` | RC 브랜치 생성 시 | version 변경 없음. `rc/YYYY-Wxx` branch + `promo/rc-YYYY-Wxx` tag 만 생성 |
| RC hotfix merge | RC hotfix 머지 직후 | version 변경 없음. RC deploy metadata 가 latest snapshot build number 를 사용 |
| `main-deploy` | main push 직후 | version 변경 없음. deploy-time metadata + release asset/tag/marker 생성 |

`dev-staging-dev-cut` 의 release-bot direct push 는 protected branch human direct push 금지의 유일한 source version bump 예외다. `dev`/`rc`/`main` 에 자동 version commit 을 만들지 않는다.

## Tag 컨벤션

| Tag / Status | 시점 | 예시 | 부여자 |
|--------------|------|------|--------|
| `v{ver}+{build}-dev-staging` (tag) | `dev-staging-dev-cut` version bump commit 직후 | `v26.06.01+26060101-dev-staging` | workflow |
| `dev-rc-cut-pass` (commit status) | dev 머지 후 dev-rc-cut-gate green | (status only, tag 없음) | workflow |
| `promo/rc-YYYY-Wxx` (tag) | dev-rc-cut 직후 | `promo/rc-2026-W20` | workflow |
| `promo/main-YYYY-Wxx` (tag) | main 머지 직후 (동시) | `promo/main-2026-W20` | workflow |

`Wxx` = ISO week number (예: 2026-W20 = 2026년 20주차).

> **Tag naming regex 는 [`RELEASE.md`](../../../RELEASE.md) lock** (TODO). Sentry, Statsig, Vercel, App Store 가 모두 pin. rename = 모든 dashboard 깨짐.

조회:
- `git tag -l 'v*-dev-staging'` (dev-staging coherent snapshot)
- `git tag -l 'promo/main-*'` (weekly main promotion event)
- `git log --first-parent main` (main 의 promotion merge 이벤트)
- `gh api repos/.../commits/{sha}/status` (dev-rc-cut-pass 확인)

## 동일 build number 가 여러 단계 등장하는 의미

| 상태 | 의미 |
|------|------|
| `26.06.01-dev-staging+26060101` | dev-staging source snapshot version/tag |
| `26.06.01-dev+26060101` | dev branch deploy artifact version |
| `26.06.01-rc+26060101` | rc branch deploy artifact version |
| `26.06.01+26060101` | main branch deploy artifact version |

source-controlled `26.MM.DD-dev-staging` 과 deploy artifact `26.MM.DD[-channel]` 는 같은 snapshot date 를 공유한다. build number 는 snapshot tag 의 `BUILD` 로 고정된다.

## 버전 관리 제외 대상 (기존 유지)

- `tests/test_data_seeder`
- `tests/backend_integration`
- `apps/integration_scenario_tester`

## 결정해야 할 것

- `RELEASE.md` 작성 (tag regex single source)
- legacy PR-number build tag 에서 `YYMMDDNN` build number 로 넘어가는 transition monitoring

## 관련

- [branch-flow.md](./branch-flow.md) — promotion tag 사용 맥락
- [dev-staging-pipeline.md](./dev-staging-pipeline.md), [rc-promotion.md](./rc-promotion.md), [main-promotion.md](./main-promotion.md) — 각 stage 의 bump trigger
- 기존 [CLAUDE.md "Versioning Conventions"](../../../CLAUDE.md#versioning-conventions) — 원본

---
_Reviewed: 2026-05-24 10:24_
