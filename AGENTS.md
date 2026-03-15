# Agent Conventions

## Architecture Reference

작업 시작 전 `docs/architecture/` 문서를 참고하여 프로젝트 구조와 설계 의도를 파악한다.

| 문서 | 내용 |
|------|------|
| [client.md](docs/architecture/client.md) | Flutter 앱 아키텍처 (Feature-first, Coordinator, Repository, Design System) |
| [backend.md](docs/architecture/backend.md) | Supabase 백엔드 (29 테이블, Edge Functions, RLS, Triggers) |
| [trust-and-verification.md](docs/architecture/trust-and-verification.md) | 2-layer 신뢰 모델 (Identity + Qualification) |
| [payment-pipeline.md](docs/architecture/payment-pipeline.md) | 결제/정산 파이프라인 |
| [search-and-recommendation.md](docs/architecture/search-and-recommendation.md) | PGroonga 검색 + pgvector 추천 |
| [global-event-pipeline.md](docs/architecture/global-event-pipeline.md) | PGMQ 2-tier 이벤트 파이프라인 |

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
- PR 머지 전 `check-migration-versions` CI 체크 통과 필수 (migration version 중복 검사).
- Approvals 불필요 (0개). self-merge 가능.
- Admin은 긴급 시 bypass 가능하지만, 일반 작업은 항상 PR 사용.

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
- required check (`check-migration-versions`) 통과 시 자동으로 squash merge 된다.
- 머지 후 소스 브랜치는 자동 삭제된다 (`delete_branch_on_merge` 활성화).
- Admin bypass (`--admin`)는 긴급 상황에서만 사용한다.

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