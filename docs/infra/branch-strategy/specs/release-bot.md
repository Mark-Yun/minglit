# Release Bot

`minglit-release-bot` 은 protected branch/tag/release 를 workflow 가 변경해야 할 때만 사용하는 GitHub App identity 다. Human direct push 를 대체하되, 일반 PR automation 과 release 권한을 분리한다.

## GitHub App 설정

| 항목 | 값 |
|------|----|
| App name | `minglit-release-bot` |
| Owner | 개인 계정 또는 `team-minglit` org |
| Visibility | **Any account** 권장 — 개인 계정에서 만든 App 을 org repo 에 설치하려면 필요 |
| Installation target | `team-minglit/minglit` selected repository |
| Webhook | 불필요. Active 해제 가능 |

## Permissions

GitHub App permission 은 아래만 부여한다.

| Permission | Level | 이유 |
|------------|-------|------|
| Contents | Read/write | version bump commit, branch 생성/삭제, tag push, release asset/source 접근 |
| Pull requests | Read/write | nightly/promotion/backport PR 생성, auto-merge enable |
| Commit statuses | Read/write | `rc-gate-pass` 같은 commit status 설정 |
| Checks | Read | required check / gate 상태 조회 |
| Issues | Read/write | release 자동 이슈 생성, failure comment |
| Metadata | Read | GitHub App 기본 권한 |

부여하지 않는 권한:

| Permission | 이유 |
|------------|------|
| Administration | Ruleset 수정은 초기 수동 설정 또는 별도 infra workflow 에서만 수행 |
| Actions | workflow 실행/수정 권한은 상시 release path 에 불필요 |
| Secrets | secret 조회/수정 금지 |
| Members / Organization administration | repo release automation 범위 초과 |

## Secrets / Env

Workflow 에는 장기 PAT 를 저장하지 않는다. App private key 로 매 run 마다 1시간짜리 installation token 을 mint 한다.

| 이름 | 위치 | 내용 |
|------|------|------|
| `MINGLIT_RELEASE_BOT_APP_ID` | GitHub Actions secret 또는 `minglit_env/{stage}` | GitHub App ID |
| `MINGLIT_RELEASE_BOT_PRIVATE_KEY` | GitHub Actions secret 권장 | GitHub App private key PEM |
| `MINGLIT_RELEASE_BOT_OWNER` | `minglit_env/{stage}` 또는 workflow env | `team-minglit` |
| `MINGLIT_RELEASE_BOT_REPOSITORIES` | `minglit_env/{stage}` 또는 workflow env | `minglit` |

비밀이 아닌 `owner`, `repositories` 는 env 파일에 둘 수 있다. `private-key` 는 줄바꿈이 포함된 PEM 이라 GitHub Actions secret 으로 두는 것을 기본값으로 한다.

## Workflow 사용법

공통 token mint 는 composite action 으로 제공한다.

```yaml
- name: Generate release bot token
  id: release-bot
  uses: ./.github/actions/release-bot-token
  with:
    app-id: ${{ secrets.MINGLIT_RELEASE_BOT_APP_ID }}
    private-key: ${{ secrets.MINGLIT_RELEASE_BOT_PRIVATE_KEY }}
    owner: ${{ vars.MINGLIT_RELEASE_BOT_OWNER || 'team-minglit' }}
    repositories: ${{ vars.MINGLIT_RELEASE_BOT_REPOSITORIES || 'minglit' }}
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
| `sync-version` | dev/main version bump commit, main release tag |
| `dev-staging-post-merge-sync` | dev-staging version bump/tag |
| `nightly-cut` | immutable nightly branch 생성, dev PR 생성 |
| `rc-cut` | `rc/YYYY-Wxx` branch 생성, RC tag |
| `rc-post-merge-sync` | RC hotfix version bump/tag |
| `rc-soak-check` | rc → main promotion PR 생성/auto-merge |
| `rc-hotfix-backport` | backport branch/PR 생성 |
| `main-post-merge-promote` | final version/tag/release marker, RC branch cleanup |

## Ruleset Bypass

Ruleset bypass actor 는 `minglit-release-bot` App installation 으로 제한한다.

| Target | 허용 작업 |
|--------|-----------|
| `dev-staging` | version bump commit, `v*-dev-staging` tag |
| `dev` | nightly promotion/version metadata push |
| `rc/**` | RC branch 생성/삭제, RC hotfix version bump |
| `main` | final version bump/tag/promotion commit |
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
