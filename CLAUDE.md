# Agent Conventions

- **GitHub Pages**: https://mark-yun.github.io/minglit/
- **Repository**: https://github.com/Mark-Yun/minglit

## Architecture Reference

작업 시작 전 `docs/architecture/` 문서를 참고하여 프로젝트 구조와 설계 의도를 파악한다.

| 문서 | 내용 |
|------|------|
| [client.md](docs/architecture/client.md) | Flutter 앱 아키텍처 (Feature-first, Coordinator, Repository, Design System) |
| [backend.md](docs/architecture/backend.md) | Supabase 백엔드 (50 테이블, Edge Functions, RLS, Triggers) |
| [trust-and-verification.md](docs/architecture/trust-and-verification.md) | 2-layer 신뢰 모델 (Identity + Qualification) |
| [payment-pipeline.md](docs/architecture/payment-pipeline.md) | 결제/정산 파이프라인 |
| [search-and-recommendation.md](docs/architecture/search-and-recommendation.md) | PGroonga 검색 + pgvector 추천 |
| [global-event-pipeline.md](docs/architecture/global-event-pipeline.md) | PGMQ 2-tier 이벤트 파이프라인 |
| [edge-functions.md](docs/debugging/edge-functions.md) | Edge Function 디버깅 (Axiom, Sentry, 로컬/Dev, 테스트) |

## Versioning Conventions

모노레포 전체에 `YY.MM.PR#` CalVer 버저닝을 사용한다.

### 버전 형식

| 구성요소 | 설명 | 예시 |
|----------|------|------|
| `YY` | 연도 2자리 | `26` (2026년) |
| `MM` | 월 2자리 | `03` (3월) |
| `PR#` | 월 내 릴리즈 순번 | `1`, `2`, `99` |

**예시**:
- `26.03.1` — 26년 3월 첫 번째 릴리즈
- `26.03.2` — 26년 3월 두 번째 릴리즈
- `26.05.1` — 26년 5월 첫 번째 릴리즈 (월 건너뛸 수 있음)

### Dev / Release 구분

- **dev 브랜치**: `-dev` 접미사 (예: `26.03.1-dev`)
- **release (main)**: 접미사 없음 (예: `26.03.1`)

### 패키지별 버전 형식

| 패키지 | 형식 | 예시 |
|--------|------|------|
| Flutter 앱 (`app_user`, `app_partner`) | `YY.MM.PR#[-dev]+YYMMPPPP` | `26.03.1-dev+26030001` |
| Shared packages (`minglit_kit` 등) | `YY.MM.PR#[-dev]` | `26.03.1-dev` |
| Landing pages (`landing_user` 등) | `YY.MM.PR#[-dev]` | `26.03.1-dev` |
| Root `package.json` | `YY.MM.PR#[-dev]` | `26.03.1-dev` |

- **versionCode** (`+YYMMPPPP`): `YYMM * 10000 + PR#`
  - 예: `26.03.1` → `2603 * 10000 + 1 = 26030001`
  - 예: `26.12.99` → `2612 * 10000 + 99 = 26120099`

### 버전 Bump 방법

```bash
# 버전 일괄 업데이트 (8개 대상 파일)
bash scripts/bump-version.sh <version>

# 예시
bash scripts/bump-version.sh 26.03.1-dev    # dev 버전 세팅
bash scripts/bump-version.sh 26.03.1        # release 버전 세팅
```

### CI 자동화 (예정 — 후속 PR에서 구현)

- PR merge to `main` 시 자동 bump + git tag (`v26.03.1` 형식) — *미구현, 후속 PR 예정*
- 동일 월이면 PR# + 1, 새 월이면 .1 시작

### 버전 관리 제외 대상

아래 테스트 패키지는 버저닝 대상에서 제외:
- `tests/test_data_seeder`
- `tests/backend_integration`
- `apps/integration_scenario_tester`

## Build Defaults

- APK 빌드 요청 시 `--debug`가 디폴트. `--release`는 명시적으로 요청할 때만 사용.
- Flutter 환경: dev 환경(`minglit_env/dev/flutter.env`)이 디폴트. local/prod는 명시적으로 요청할 때만.

### Build Commands

```bash
# Debug APK (디폴트)
cd apps/app_user && flutter build apk --flavor dev --debug --dart-define-from-file=../../minglit_env/dev/flutter.env

# Release APK (명시적 요청 시만)
cd apps/app_user && flutter build apk --flavor dev --release --dart-define-from-file=../../minglit_env/dev/flutter.env

# ADB 설치 (wireless)
adb -s adb-R3CX803P2ND-8btuuD._adb-tls-connect._tcp install -r build/app/outputs/flutter-apk/app-dev-debug.apk
```

## Supabase Migration Rules

- 새 migration 생성 시, 반드시 `ls supabase/migrations/` 로 기존 version 확인 후 다음 번호 사용.
- Feature branch에서 migration 작성 시, dev branch의 최신 상태와 비교 필수:
  `git diff dev -- supabase/migrations/` 로 충돌 여부 확인.
- 같은 날짜에 여러 migration 필요 시 순차 번호 사용 (예: 000001, 000002, 000003).
- Migration 파일은 한번 dev/main에 머지되면 내용 수정 금지. 수정 필요 시 새 migration 추가.

## Branch Protection

- `dev` 브랜치는 direct push 금지. 반드시 feature branch에서 PR을 통해 머지.
- Required check: **`ci-result`** — 이 하나의 summary job이 모든 CI + CodeRabbit 리뷰를 게이트한다.
- Approvals 불필요 (0개). self-merge 가능.
- `required_conversation_resolution` 활성화 — 미해결 코멘트가 있으면 머지 불가.
- `required_linear_history` 활성화 — squash merge만 허용.
- `--admin` bypass는 **유저가 명시적으로 요청할 때만** 사용한다. CI나 리뷰 우회 목적 금지.

## Issue Priority Labels

이슈에는 우선순위 라벨을 붙여 처리 순서를 관리한다.

| 라벨 | 의미 | 처리 기한 |
|------|------|-----------|
| `P0-critical` | 서비스 장애, 즉시 수정 | 당일 |
| `P1-high` | 핵심 기능 버그 | 이번 주 |
| `P2-medium` | 일반 버그, 감사 이슈 | 다음 스프린트 |
| `P3-low` | 테스트 보강, enhancement | 여유 시 |

- AI Worker는 **P0 > P1 > P2 > P3 > 라벨 없음** 순서로 이슈를 처리한다.
- 같은 우선순위 내에서는 이슈 번호가 낮은(오래된) 것 먼저.

## PR Conventions

- PR 생성 시 관련 GitHub Issue가 있으면 PR body에 `Closes #이슈번호`를 포함한다.
- 여러 이슈: `Closes #53, closes #54, closes #55`
- dev 브랜치에 머지되면 해당 이슈가 자동으로 닫힌다.

### Auto-Merge

- PR 생성 직후 반드시 auto-merge를 활성화한다:
  ```bash
  gh pr create --base dev --title "..." --body "..."
  gh pr merge <PR번호> --auto --squash
  ```
- `ci-result` 통과 시 자동으로 squash merge 된다.
- 머지 후 소스 브랜치는 자동 삭제된다 (`delete_branch_on_merge` 활성화).

### CI 파이프라인

`ci-result`는 아래 모든 항목이 통과해야 success가 된다:

| Job | 조건 | 내용 |
|-----|------|------|
| `check-migration-versions` | 항상 | migration version 중복 검사 |
| `test-flutter-apps` | `apps/app_user/**`, `apps/app_partner/**` 또는 `shared/packages/minglit_kit/**` 변경 시 | Flutter analyze + test (matrix: app_user, app_partner) |
| `lint-landing-user` | `apps/landing_user/**` 또는 `shared/web/**` 변경 시 | npm lint + build |
| `lint-landing-partner` | `apps/landing_partner/**` 또는 `shared/web/**` 변경 시 | npm lint + build |
| `test-supabase` | `supabase/**` 변경 시 | pgTAP 테스트 |
| `test-edge-functions` | 동일 | Deno edge function 테스트 |
| CodeRabbit 리뷰 | PR only | `ci-result` job 내에서 최대 30분 대기 |

별도 워크플로우 (required check 아님, 참고용):
- **Auto Format PR**: PR 시 `dart fix --apply` + `dart format` 자동 적용. 포맷 변경이 있으면 자동 커밋.
- **Secret Scanning**: PR 시 Gitleaks로 시크릿 유출 검사.

### PR 케어 (생성 → 머지 완료까지)

PR을 생성하면 **MERGED 될 때까지 케어한다**. 생성만 하고 방치 금지.
CI 확인, 리뷰 코멘트 대응, 브랜치 업데이트를 모두 포함한다.

```bash
# 1. CI 상태 확인 (ci-result가 CodeRabbit 대기까지 포함)
gh pr checks <PR번호>

# 2. 리뷰 코멘트 확인
gh api repos/{owner}/{repo}/pulls/{PR번호}/comments --jq '.[] | {path: .path, body: .body, line: .line}'

# 3. PR 상태 확인 (머지 여부, 브랜치 상태)
gh pr view <PR번호> --json state,mergedAt,mergeStateStatus --jq '{state: .state, merged: .mergedAt, mergeState: .mergeStateStatus}'
```

#### 모니터링 결과별 대응

| 상태 | 대응 |
|------|------|
| `ci-result` 통과 + 코멘트 없음 | auto-merge 대기 |
| `ci-result` 통과 + **코멘트 있음** | 코멘트 대응 (아래 규칙 참고) |
| CI 실패 | 실패 원인 파악 → 수정 (아래 규칙 참고) |
| PR `MERGED` | 모니터링 종료 |
| `mergeStateStatus: BEHIND` | 브랜치 업데이트 필요 (아래 규칙 참고) |

#### 브랜치 업데이트 (BEHIND 상태)

PR의 브랜치가 base(dev) 대비 뒤처지면 auto-merge가 진행되지 않는다. 반드시 업데이트한다:

```bash
# 방법 1: GitHub API로 업데이트 (권장 — 로컬 체크아웃 불필요)
gh api repos/{owner}/{repo}/pulls/{PR번호}/update-branch --method PUT

# 방법 2: 로컬에서 업데이트
git checkout <브랜치>
git fetch origin
git merge origin/dev
git push
```

- `mergeStateStatus`가 `BEHIND`이면 **즉시** 브랜치를 업데이트한다.
- 업데이트 후 CI가 다시 돌아가고, 통과하면 auto-merge가 진행된다.
- 충돌(conflict)이 발생하면 로컬에서 수동 해결 후 push.

#### 코멘트 대응 규칙

- 리뷰 코멘트는 **전부 resolve** 한다 (GitHub 설정에서도 강제됨 — unresolved 코멘트가 있으면 머지 불가).
- 대응 방법:
  1. 코드 수정 필요: 수정 후 같은 브랜치에 push → 답글 → resolve
  2. 수정 불필요 (의도된 설계): 근거를 답글로 남기고 → resolve
  3. 논의 필요: 답글로 의견 남기고 사용자에게 판단 요청

### CI 실패 대응

1. `gh run view <run_id> --log-failed`로 실패 원인 파악
2. **ci-result만 실패** + 나머지 전부 pass → CodeRabbit 타임아웃일 가능성. `gh run rerun <run_id> --failed`로 재실행 (최대 3회).
3. 실제 test/build 실패 → 로컬에서 수정 후 같은 브랜치에 push (PR은 유지됨)
4. CI 재실행 → 통과 확인 → auto-merge 완료까지 반복

## Deploy Conventions

- Vercel 배포는 cron (2시간마다) + 수동(`workflow_dispatch`)으로 실행된다.
- PR/push 시 Vercel auto-deploy는 `ignoreCommand`로 차단되어 있다.
- 즉시 배포가 필요하면: GitHub Actions → Deploy to Vercel → Run workflow → branch 선택 → 실행.
- 4개 앱(app_user, app_partner, landing_user, landing_partner) 모두 매 cron마다 deploy된다.

## Bug Fix Conventions

### 진단 프로세스
- 버그 리포트에 포함된 스크린샷, UI dump(widget tree, render tree 등)를 반드시 먼저 분석한다.
- 증상이 아닌 root cause를 찾아 수정한다. 표면적 증상만 막는 workaround 금지.
- root cause 파악이 어려울 경우, 재현 경로를 먼저 확보한 뒤 디버깅한다.
- debuggability, maintainability, readability를 고려한 수정을 한다. 급한 핫픽스라도 코드 품질을 떨어뜨리지 않는다.
- 수정 후, 해당 버그를 재현하는 유닛 테스트 또는 인티그레이션 테스트를 추가하여 재발을 차단한다.

### 코드 이력 주석
- 버그 픽스 코드에는 반드시 관련 Issue 번호와 수정 이유를 주석으로 남긴다.
- 형식: `// Fix #이슈번호: 수정 이유 (한 줄 요약)`
- 예시:
  ```dart
  // Fix #72: PartyStatusEditSheet에서 visibility가 null일 때 크래시 — default 값 보장
  final visibility = party.visibility ?? 'public';
  ```
- 주석은 수정된 코드 바로 위에 작성한다. 파일 상단이나 먼 곳에 남기지 않는다.
