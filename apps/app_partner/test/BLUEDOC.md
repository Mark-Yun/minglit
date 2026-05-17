# app_partner/test — 테스트

`app_partner` 의 unit · widget · integration · golden 테스트. `lib/src/` 구조를 그대로 미러링.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`src/`](./src/) | unit + widget 테스트 (lib/src/ 미러링) |
| [`integration/`](./integration/) | Integration 테스트 (CI 의 `pr-gate.test-integration-app-partner-cuj` 실행) |
| [`alchemist/`](./alchemist/) | Alchemist golden 설정·고정 골든 |
| [`visual_qa/`](./visual_qa/) | 시각 QA 캡처 |
| [`utils/`](./utils/) | 테스트 헬퍼 (mocks, utils, reporter integration) |
| [`widget_test.dart`](./widget_test.dart) | 레거시 widget test |
| [`flutter_test_config.dart`](./flutter_test_config.dart) | 테스트 환경 setup |
| [`reporter.dart`](./reporter.dart) | test_reporter 통합 |

## 핵심 컨벤션

- **Unit/widget 테스트는 `src/<sub>/<feature>_test.dart` 패턴** — `lib/src/` 미러링.
- **권한 분기 테스트는 router redirect 레벨에서** — feature 안에 권한 체크 없으므로 권한 시나리오는 [`integration_test/`](../integration_test/cuj/) 의 router context 로 검증.
- **Golden 은 `--tags golden`** — Alchemist 가 처리.
- **공용 mock/util 은 [`utils/`](./utils/)**.

## 실행

```bash
flutter test                       # unit + widget
flutter test test/src/features/member/   # 특정 feature
flutter test --coverage             # 커버리지 → coverage/lcov.info
flutter test --tags golden          # Alchemist golden
```

CI 자동 실행: `pr-gate.test-flutter-apps` matrix. 커버리지 dev 자동 갱신: [`sync-test-coverage`](../../../.github/workflows/sync-test-coverage.yml) → [`tests/_coverage/app_partner/`](../../../tests/_coverage/app_partner/).

## 관련

- [app_partner BLUEDOC](../BLUEDOC.md)
- [app_partner architecture.md](../architecture.md) — 권한·온보딩 router redirect
- [integration_test/cuj/BLUEDOC](../integration_test/cuj/BLUEDOC.md)
- [tests/_coverage/BLUEDOC](../../../tests/_coverage/BLUEDOC.md)

---
_Reviewed: 2026-05-17 22:32_
