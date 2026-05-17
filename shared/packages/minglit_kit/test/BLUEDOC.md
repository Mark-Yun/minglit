# minglit_kit/test — 테스트

`minglit_kit` 공용 패키지의 unit · widget · golden · contract 테스트. `lib/src/` 구조 미러링 + Repository 계약 테스트.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`src/`](./src/) | unit + widget 테스트 (lib/src/ 미러링: components/config/data/features/logic/theme/ui/utils) |
| [`contract/`](./contract/) | Repository 계약 테스트 — Supabase schema 와의 동기화 검증 |
| [`goldens/`](./goldens/) | Golden 테스트 (Alchemist) — 공용 위젯 시각 회귀 |
| [`logic/`](./logic/) | 글로벌 logic 테스트 (auth, provider 등) |
| [`services/`](./services/) | 외부 SDK 래퍼 테스트 |
| [`ui/`](./ui/) | UI / Design System 테스트 |
| [`utils/`](./utils/) | 유틸리티 함수 테스트 (age_util, refund_calculator 등) |
| [`helpers/`](./helpers/) | 테스트 헬퍼 (mocks, factory) |
| [`minglit_kit_test.dart`](./minglit_kit_test.dart) | 패키지 export 검증 |
| [`flutter_test_config.dart`](./flutter_test_config.dart) | 테스트 환경 setup |
| [`reporter.dart`](./reporter.dart) | test_reporter 통합 |
| [`analysis_options.yaml`](./analysis_options.yaml) | 테스트 코드 lint 룰 (lib 와 다른 룰 가능) |

## 핵심 컨벤션

- **계약 테스트 (`contract/`)** — Repository 가 wrapping 하는 Supabase 테이블/RPC 의 schema 가 변경되면 즉시 fail. 백엔드와 클라이언트 동기화 보장.
- **`lib/src/` 의 모든 폴더는 대응 `test/src/` 폴더를 가진다.**
- **Golden 은 Alchemist 사용** — `apps/app_user`/`app_partner` 와 동일.

## 실행

```bash
flutter test                       # 전체
flutter test test/contract/        # 계약 테스트만
flutter test --coverage             # 커버리지 → coverage/lcov.info
flutter test --tags golden          # Alchemist golden
```

CI 자동 실행: `pr-gate.test-flutter-apps` matrix (minglit_kit 변경 시). 커버리지 dev 자동 갱신: [`sync-test-coverage`](../../../../.github/workflows/sync-test-coverage.yml) → [`tests/_coverage/minglit_kit/`](../../../../tests/_coverage/minglit_kit/).

## 관련

- [minglit_kit BLUEDOC](../BLUEDOC.md)
- [minglit_kit architecture.md](../architecture.md)
- [tests/_coverage/BLUEDOC](../../../../tests/_coverage/BLUEDOC.md)

---
_Reviewed: 2026-05-17 22:32_
