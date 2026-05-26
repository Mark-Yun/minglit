# Release Bot

`minglit-release-bot` 은 protected branch/tag/release 를 workflow 가 변경해야 할 때만 사용하는 GitHub App identity 다. Human direct push 를 대체하되, 일반 PR automation 과 release 권한을 분리한다.

## GitHub App 설정

| 항목 | 값 |
|------|----|
| App name | `minglit-release-bot` |
| Owner | 개인 계정 또는 `team-minglit` org |
| Visibility | **Any account** 권장 — 개인 계정에서 만든 App 을 org repo 에 설치하려면 필요 |
| Installation target | `Mark-Yun/minglit` + `Mark-Yun/minglit_env` selected repositories |
| Webhook | 불필요. Active 해제 가능 |

## Permissions

GitHub App permission 은 아래만 부여한다.

| Permission | Level | 이유 |
|------------|-------|------|
| Contents | Read/write | version bump commit, branch 생성/삭제, tag push, release asset/source 접근 |
| Pull requests | Read/write | promotion/backport PR 생성, auto-merge enable |
| Commit statuses | Read/write | `dev-soak/*`, `dev-rc-cut-pass`, `rc-main-cut-pass` 같은 gate marker 설정 |
| Checks | Read | required check / gate 상태 조회 |
| Actions | Read | `dev-rc-cut-gate` 가 monitor workflow run history 를 조회 |
| Issues | Read/write | release 자동 이슈 생성, failure comment |
| Metadata | Read | GitHub App 기본 권한 |

부여하지 않는 권한:

| Permission | 이유 |
|------------|------|
| Administration | Ruleset 수정은 초기 수동 설정 또는 별도 infra workflow 에서만 수행 |
| Actions write | workflow 실행/수정 권한은 상시 release path 에 불필요. run history 조회용 read 만 허용 |
| Secrets | secret 조회/수정 금지 |
| Members / Organization administration | repo release automation 범위 초과 |

## Secrets / Env

Workflow 에 release bot 장기 PAT 를 저장하지 않는다. App private key 로 매 run 마다 1시간짜리 installation token 을 mint 한다.

| 이름 | 위치 | 내용 |
|------|------|------|
| `MINGLIT_RELEASE_BOT_APP_ID` | `minglit_env/{stage}/github.env` | GitHub App ID |
| `MINGLIT_RELEASE_BOT_PRIVATE_KEY_BASE64` | `minglit_env/{stage}/github.env` | GitHub App private key PEM 을 base64 단일 라인으로 저장 |
| `MINGLIT_RELEASE_BOT_OWNER` | `minglit_env/{stage}/github.env` | `Mark-Yun` |
| `MINGLIT_RELEASE_BOT_REPOSITORIES` | `minglit_env/{stage}/github.env` | `minglit` |
| `MINGLIT_RELEASE_BOT_APP_ID` | GitHub Actions secret | `minglit_env` checkout bootstrap 용 GitHub App ID |
| `MINGLIT_RELEASE_BOT_PRIVATE_KEY` | GitHub Actions secret | `minglit_env` checkout bootstrap 용 GitHub App private key PEM |

`release-bot-token` composite action 은 GitHub Actions secret 의 App key 로 bootstrap token 을 만든 뒤 `minglit_env` 를 checkout 하고, 파일 기반 값을 우선 사용한다. `minglit_env` 를 읽을 수 없을 때만 기존 `MINGLIT_RELEASE_BOT_APP_ID` / `MINGLIT_RELEASE_BOT_PRIVATE_KEY` GitHub Actions secret 을 fallback 으로 사용한다.

## Workflow 사용법

공통 token mint 는 composite action 으로 제공한다.

```yaml
- name: Generate release bot token
  id: release-bot
  uses: ./.github/actions/release-bot-token
  with:
    env-file: minglit_env/dev/github.env
    fallback-app-id: ${{ secrets.MINGLIT_RELEASE_BOT_APP_ID }}
    fallback-private-key: ${{ secrets.MINGLIT_RELEASE_BOT_PRIVATE_KEY }}
```

생성된 token 은 같은 job 에서만 사용한다.

```yaml
- uses: actions/checkout@v6
  with:
    token: ${{ steps.release-bot.outputs.token }}
```

또는 push 직전에 remote URL 에 주입한다.

```bash
git remote set-url origin "https://x-access-token:${RELEASE_BOT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git push origin HEAD:dev
git remote set-url origin "https://github.com/${GITHUB_REPOSITORY}.git"
```

## 사용 workflow

| Workflow | 사용 이유 |
|----------|-----------|
| `dev-staging-dev-cut-gate` | dev-staging version bump/tag |
| `dev-staging-dev-cut` | immutable nightly branch 생성, dev PR 생성 |
| `shared-set-commit-status` | commit status 를 쓰는 low-level reusable |
| `set-dev-soak-status` | dev soak signal 을 `dev-soak/*` context 로 매핑 |
| `set-rc-soak-status` | rc soak signal 을 `rc-soak/*` context 로 매핑 |
| `monitor-event-flow-*` / `shared-notify` | backend simulator 실패 시 `set-dev-soak-status` 로 failure status + issue 기록 |
| AI app soak status writer | 앱 소킹/실디바이스 이상 발견 시 `set-dev-soak-status` 로 failure status 기록 |
| `dev-rc-cut-gate` | 24h soak run history 확인 후 `set-dev-soak-status` 로 `dev-soak/*` success + `dev-rc-cut-pass` status 기록 |
| `dev-rc-cut` | `rc/YYYY-Wxx` branch 생성, `promo/rc-*` tag |
| `rc-main-cut` | rc → main promotion PR 생성/auto-merge |
| `rc-hotfix-backport` | backport branch/PR 생성 |
| `main-deploy` | `promo/main-*` tag/release marker, prod deploy, RC branch cleanup |

## Ruleset Bypass

Ruleset bypass actor 는 `minglit-release-bot` App installation 으로 제한한다.

| Target | 허용 작업 |
|--------|-----------|
| `dev-staging` | version bump commit, `v*-dev-staging` tag |
| `dev` | dev-staging-dev-cut promotion branch/PR support |
| `rc/**` | RC branch 생성/삭제 |
| `main` | promotion tag/cleanup |
| `v*`, `promo/**` | protected tag 생성 |

Human 은 release bot private key/token 을 로컬에서 사용하지 않는다. 모든 bot write 는 workflow run URL, target ref, pushed tag/commit 을 job summary 에 남긴다.

## 검증

초기 설정 후 dry-run workflow 로 다음을 순서대로 확인한다.

1. selected repo token mint 성공
2. 임시 branch 생성/push/delete 성공
3. 임시 tag 생성/delete 성공
4. protected branch Ruleset bypass 성공
5. 권한 부족 시 실패 메시지가 명확한지 확인

---
_Reviewed: 2026-05-23 09:40_
