# app_user/test — 테스트

`app_user` 의 unit · widget · integration · golden 테스트. `lib/src/` 구조를 그대로 미러링.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`src/`](./src/) | unit + widget 테스트 (lib/src/ 와 동일 구조: `common/`, `data/`, `features/`, `logic/`, `routing/`) |
| [`integration/`](./integration/) | Integration 테스트 (Flutter integration_test, CI 의 `pr-gate.test-integration-app-user-cuj` 가 실행) |
| [`visual_qa/`](./visual_qa/) | 시각 QA 캡처 (`visual_qa_helper.dart` + capture artifacts) |
| [`utils/`](./utils/) | 테스트 헬퍼 (`mocks.dart`, `test_utils.dart`, `auto_label_allure_reporter.dart`) |
| [`widget_test.dart`](./widget_test.dart) | 레거시 widget test (default Flutter scaffold) |
| [`flutter_test_config.dart`](./flutter_test_config.dart) | 테스트 환경 setup (모든 테스트가 자동 로드) |
| [`reporter.dart`](./reporter.dart) | `test_reporter` 통합 (Allure 등 외부 리포터) |

## 핵심 컨벤션

- **Unit/widget 테스트는 `src/<sub>/<feature>_test.dart` 패턴** — `lib/src/` 의 구조 미러링.
- **Integration 테스트는 `integration_test/` 사용** (CUJ 패턴) — `test/integration/` 은 일반 통합, `integration_test/cuj/` 는 emulator 기반 CUJ.
- **Golden 테스트는 `--tags golden`** — Alchemist 가 처리, CI 에서 별도 step.
- **공용 mock/util 은 [`utils/`](./utils/)** — feature 별로 흩뿌리지 않음.

## 실행

```bash
flutter test                       # unit + widget (전체)
flutter test test/src/features/auth/   # 특정 feature
flutter test --coverage             # 커버리지 측정 → coverage/lcov.info
flutter test --tags golden          # Alchemist golden
```

CI 자동 실행은 `pr-gate.test-flutter-apps` (matrix). 커버리지 dev 자동 갱신은 [`sync-test-coverage`](../../../.github/workflows/sync-test-coverage.yml) → [`tests/_coverage/app_user/`](../../../tests/_coverage/app_user/).

## 관련

- [app_user BLUEDOC](../BLUEDOC.md)
- [integration_test/BLUEDOC](../integration_test/BLUEDOC.md) — emulator 기반 CUJ
- [tests/_coverage/BLUEDOC](../../../tests/_coverage/BLUEDOC.md) — 커버리지 저장소
