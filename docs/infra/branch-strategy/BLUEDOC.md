# Branch Strategy

4-stage (`dev-staging → dev → rc → main`) + 일반 PR/auto-merge + cut-gate/cut SRP + feature flag + 3가지 safety net. AI agent 가 dev-staging 에 PR, `dev-rc-cut-pass` commit 에서 RC 를 cut 하고, `rc-main-cut-pass` RC 에서 main PR 을 cut 한다. main 머지에서 backend + mobile 모두 prod 로 deploy 한다 (hotfix 없으면 weekly). 이벤트 플로우 시뮬레이터는 release promotion 과 별개인 batch monitor 로 계속 돈다.

## Workflow Overview

```mermaid
flowchart LR
  agent[Agent / Human PR] --> dsg[dev-staging-pr-gate]
  dsg --> ds[dev-staging]
  ds --> nc[dev-staging-dev-cut]
  nc --> dstag["v*-dev-staging tag"]

  nc --> npg[dev-pr-gate]
  npg --> dev[dev]

  dev -. 24h soak .-> rg[dev-rc-cut-gate]
  monitor["monitor-event-flow-* batch"] -. dev-soak/backend-simulator .-> dev
  ai["AI app soak / real-device"] -. dev-soak/app-ai-review .-> dev
  rg -->|pass| rgp["dev-rc-cut-pass status"]
  rg -->|blocked| issue[status failure + issue/audit]
  rgp --> rcut[dev-rc-cut]
  rcut --> rc["rc/YYYY-Wxx"]

  ds --> rhf[rc hotfix source commit]
  rhf --> rpg[rc-pr-gate]
  rpg --> rc

  rc --> rcd[rc-deploy]
  rc --> rmcg[rc-main-cut-gate]
  rcd --> rmcg
  rmcg -->|pass| rmcp["rc-main-cut-pass marker"]
  rmcp --> mcut[rc-main-cut]
  mcut --> mpg[main-pr-gate]
  mpg --> main[main]
  main --> md[main-deploy]
  md --> prod[(Production)]

  monitor -. pre-main signal .- rc
```

### Abstract Workflow Set

| 단계 | Entry workflow | 역할 |
|------|----------------|------|
| dev-staging PR | `dev-staging-pr-gate` | feature/agent PR 의 빠른 CI gate |
| dev-staging 지속 검증 | `monitor-dev-staging-health` | 6시간마다 EF unit/integration + user/partner CUJ 로 nightly 전 회귀 감지 |
| dev-staging → dev cut gate | `dev-staging-dev-cut-gate` | 수동 candidate inspect 전용. per-merge mutation 없음 |
| dev-staging → dev cut | `dev-staging-dev-cut` + `dev-pr-gate` | daily cut 시점에 coherent snapshot 을 직접 bump/tag 하고 dev PR 로 promote |
| dev → rc cut gate | `dev-rc-cut-gate` | 24h dev soak status + dev cron install run 확인 후 `dev-rc-cut-pass` status 부여 |
| dev deploy/validation | `dev-deploy` | dev 환경 deploy/validation orchestrator. 이벤트 플로우 시뮬레이터는 dev Supabase pg_cron 으로 별도 운영 |
| dev → rc cut | `dev-rc-cut` | latest `dev-rc-cut-pass` commit 에서 `rc/YYYY-Wxx` 생성 |
| rc hotfix | dev-staging fix PR + `rc-pr-gate` | dev-staging 에 먼저 반영된 fix commit 을 active RC 로 cherry-pick/promote |
| rc deploy/validation | `rc-deploy` | Supabase branching 기반 RC 검증 환경 구성 + pre-main validation |
| rc → main cut gate | `rc-main-cut-gate` | soak/pre-main validation 통과 RC 에 `rc-main-cut-pass` marker 부여 |
| rc → main cut | `rc-main-cut` + `main-pr-gate` | gate 가 선별한 RC 를 main PR 로 promote |
| prod deploy | `main-deploy` | prod backend/mobile deploy, deploy-time version metadata, RC cleanup |

## 4-stage 모델

| 단계 | 역할 | 진입 방식 |
|------|------|-----------|
| `dev-staging` | AI agent commit zone | 일반 PR + auto-merge + 가벼운 `pr-gate` |
| `dev` | soak-validated trunk | daily `dev-staging-dev-cut` → 24h soak → `dev-rc-cut-gate` |
| `rc/YYYY-Wxx` | mobile RC, 5일 soak | weekly cut from latest dev-rc-cut-pass |
| `main` | mobile-stable snapshot | rc → main 머지 (soak 통과 시) |

## Safety Nets 3종

| Safety Net | 정책 / 명세 |
|------------|-------------|
| Version kill switch (Tier 2a soft + 2b hard) | 6개월 backward compat, Firebase RC source / [main-promotion.md](./main-promotion.md) |
| Expand-Migrate-Contract CI | 6개월 DB schema, Option C / [dev-staging-pipeline.md](./dev-staging-pipeline.md) |
| Flag-registration CI | unflagged 코드 차단 / [dev-staging-pipeline.md](./dev-staging-pipeline.md) |

## 이정표

| 문서 | 내용 |
|------|------|
| [branch-flow.md](./branch-flow.md) | flow + protection + tag + hotfix |
| [test-strategy.md](./test-strategy.md) | per-stage gates |
| [error-detection.md](./error-detection.md) | detection layers |
| [dev-staging-pipeline.md](./dev-staging-pipeline.md) | 일반 PR/auto-merge + pr-gate + safety net CI |
| [dev-pipeline.md](./dev-pipeline.md) | dev-staging-dev-cut + dev-rc-cut-gate + auto-deploy chain |
| [dev-soak-status-model.md](./dev-soak-status-model.md) | dev soak commit status contexts + run history based `dev-rc-cut-gate` 판정 |
| [rc-promotion.md](./rc-promotion.md) | dev-rc-cut + soak + dev-staging-first hotfix |
| [main-promotion.md](./main-promotion.md) | rc → main + main-deploy + min-version |
| [hotfix-policy.md](./hotfix-policy.md) | dev/rc/main 직접 PR 차단 + branch별 hotfix 승인 규칙 |
| [life-of-flag.md](./life-of-flag.md) | flag lifecycle |
| [versioning.md](./versioning.md) | CalVer + tag |
| [specs/](./specs/BLUEDOC.md) | workflow spec, branch spec, execution plan (구현 계약) |

## 역할 (workflow 가 처리 못하는 edge case 만)

**release manager** 비상 min-version bump · workflow-blocked promotion 수동 처리 / **on-call** workflow 자동 복구 실패한 P0 / **feature owner** flag 정책 결정 · cleanup PR review / **RC owner** abandon 판단 (TBD)

## 핵심 컨벤션

- 코드 promotion = 한 방향 PR, 기능 promotion = flag flip
- `*-cut-gate` = 다음 브랜치로 promote 할 source artifact 선별/마킹, `*-cut` = 그 artifact 로 PR/branch 생성. 검증과 promotion 을 같은 workflow 에 섞지 않는다
- dev/rc release 판정은 **true evidence 기반**이다. failure issue/status 가 없다는 것은 `unknown` 이며 pass 가 아니다. cut-gate 는 명시적인 success status, required workflow run history, git lineage 같은 positive evidence 만 소비한다
- dev soak 판정의 source-of-truth 는 GitHub Issue/label 이 아니라 commit status context + workflow run history 다 ([dev-soak-status-model.md](./dev-soak-status-model.md))
- cut-gate Issue 는 사람이 진행 상태를 추적하기 위한 projection 이다. 생성/갱신/닫기는 `.github/actions/cut-issue` 와 `close-cut-issue-on-pr-merge` 가 담당하며, promotion 판정 SSOT 로 사용하지 않는다
- 일반 작업 PR 은 dev-staging 에서 squash 로 정리한다. Branch promotion PR 은 source branch ancestry 보존을 위해 merge commit 을 사용하며, dev/rc/main 에 linear history 를 강제하지 않는다
- Protected branch 직접 push 는 human 금지. dev-staging daily cut version bump, promotion branch/tag, RC cleanup 은 `minglit-release-bot` 전용 token + Ruleset bypass 로만 허용
- `deploy-dev-event-flow-cron` 은 `dev` push 에서만 `dev-event-flow-simulator` pg_cron 을 설치한다. `monitor-event-flow-*` 는 수동 smoke 이며, RC cron 은 RC project 준비 후 별도 설치한다
- main 머지 = backend + mobile 모두 prod deploy. backend prod deploy 는 `main-deploy` 에서 한 번에 수행한다
- 소스 파일 version bump 는 `dev-staging-dev-cut` 이 promote 할 dev-staging snapshot 에만 남긴다. release bot 이 protected `dev-staging` 에 직접 bump commit 을 fast-forward push 하고, 날짜 버전(`YY.MM.DD`) + snapshot build number(`YYMMDDNN`) tag 를 붙인다. `dev`/`rc`/`main` 은 branch state 를 바꾸지 않고 deploy workflow 가 metadata 를 build-time 에 주입한다
- `main-deploy` 는 prod deploy execution 을 담당한다. main push 에서 version bump commit 을 만들지 않고, release asset/tag/marker 는 deploy metadata 를 기준으로 생성한다
- 모바일 배포 산출물(APK/AAB/IPA)은 GitHub Release asset 이 canonical archive 다. Actions artifact 는 테스트 리포트/스크린샷/로그 같은 단기 디버깅 산출물에만 사용한다
- 일반 PR 은 `dev-staging` 으로만 진입한다. `dev`, `rc/*`, `main` 직접 PR 은 promotion 또는 승인된 hotfix 만 허용한다 ([hotfix-policy.md](./hotfix-policy.md))
- RC hotfix 의 source-of-truth 는 dev-staging 이다. fix 는 먼저 dev-staging 에 머지하고, 같은 commit/snapshot 을 active RC 로 cherry-pick/promote 한다. RC-only hotfix 는 release-manager override 가 필요한 예외다 ([hotfix-policy.md](./hotfix-policy.md), [rc-promotion.md](./rc-promotion.md))
- Tag regex 는 `RELEASE.md` lock (TODO)

### Promotion PR Title

Promotion PR 제목은 workflow 이름과 source artifact 를 앞에 둔다. PR list 와 git log 만 보고 어떤 workflow 가 무엇을 promote 했는지 알 수 있어야 한다.

| 단계 | 제목 형식 |
|------|-----------|
| dev-staging → dev | `ci(dev-staging-dev-cut): promote v26.05.27+2832-dev-staging to dev` |
| dev → rc | `ci(dev-rc-cut): cut rc/2026-W22 from <source>` |
| rc → main | `ci(rc-main-cut): promote rc/2026-W22 to main` |
| rc hotfix apply | `ci(rc-hotfix-apply): apply dev-staging fix #1234 to rc/2026-W22` |

### RC Eligibility Marker

RC cut 의 source-of-truth status 이름은 **`dev-rc-cut-pass`** 이다. `rc-eligible` 은 현재 구현된 workflow/status 명칭이 아니며, 새 이름으로 바꾸려면 `dev-rc-cut-gate`, `dev-rc-cut`, `main-pr-gate`, 문서 전체를 같은 PR 에서 일괄 변경한다.

---
_Reviewed: 2026-05-25 16:20_
