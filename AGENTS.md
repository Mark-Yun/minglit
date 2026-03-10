# Agent Conventions

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