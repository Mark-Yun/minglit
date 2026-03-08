# Agent Conventions

## Build Defaults

- APK 빌드 요청 시 `--debug`가 디폴트. `--release`는 명시적으로 요청할 때만 사용.
- Flutter 환경: dev 환경(`minglit_env/dev/flutter.env`)이 디폴트. local/prod는 명시적으로 요청할 때만.

## Supabase Migration Rules

- 새 migration 생성 시, 반드시 `ls supabase/migrations/` 로 기존 version 확인 후 다음 번호 사용.
- Feature branch에서 migration 작성 시, dev branch의 최신 상태와 비교 필수:
  `git diff dev -- supabase/migrations/` 로 충돌 여부 확인.
- 같은 날짜에 여러 migration 필요 시 순차 번호 사용 (예: 000001, 000002, 000003).
- Migration 파일은 한번 dev/main에 머지되면 내용 수정 금지. 수정 필요 시 새 migration 추가.