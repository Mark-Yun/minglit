# .github/scripts/

워크플로우가 `bash .github/scripts/<name>.sh` 로 실행하는 **shell 헬퍼**. composite action 을 만들 만큼 무겁지 않은 명령 묶음.

## 이정표

| Script | 역할 | 호출자 |
|---|---|---|
| [`create-dev-flutter-env.sh`](./create-dev-flutter-env.sh) | Actions secrets → `minglit_env/dev/flutter.env` 재생성 (CI 가 private submodule `minglit_env/` 를 받지 못해서 필요, Fix #1169) | `shared-cuj-integration`, `monitor-patrol-e2e` |
| [`run-user-cuj.sh`](./run-user-cuj.sh) | `apps/app_user/integration_test/cuj/` 의 CUJ 테스트 실행 (emulator) | `shared-cuj-integration` (app-name=user 일 때) |
| [`run-partner-cuj.sh`](./run-partner-cuj.sh) | `apps/app_partner/integration_test/cuj/` CUJ 실행 | `shared-cuj-integration` (app-name=partner 일 때) |

## 핵심 컨벤션

- **`set -euo pipefail`** — 모든 스크립트가 명시. 한 step 의 실패가 다음 step 에 새지 않도록.
- **필수 env 는 시작부에 `: "${VAR:?msg}"` 로 검증** — secret 누락 시 즉시 명확히 fail.
- **secrets 는 환경변수로 받기만** — script 안에 secret 값·경로 하드코드 금지.
- **`cd apps/<app>` 같은 작업 디렉토리 전제는 명시** — 호출 워크플로우의 `working-directory:` 와 일치.
- **무거워지면 composite action 으로 승격** — script 가 외부 액션 chain 을 만들기 시작하면 [`actions/`](../actions/BLUEDOC.md) 로.

## 관련

- [workflows/BLUEDOC.md](../workflows/BLUEDOC.md) — 호출하는 워크플로우 컨벤션
- [actions/BLUEDOC.md](../actions/BLUEDOC.md) — script 가 자라면 composite 로 승격
- [.github/BLUEDOC.md](../BLUEDOC.md) — 상위 진입점
