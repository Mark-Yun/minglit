# minglit_kit — 빌드·테스트 명령

> 폴더 구조·아키텍처는 [`BLUEDOC.md`](./BLUEDOC.md), [`architecture.md`](./architecture.md) 참고. 본 패키지는 단독 실행되지 않고 `app_user`/`app_partner` 에서 import.

## 테스트·분석·포맷

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test                           # unit + widget
flutter test --tags golden             # golden (kit 의 공용 위젯)
dart format .
```

## 의존 앱에서 변경 검증

`minglit_kit` 변경 시 두 앱 모두 영향. 변경 후 양쪽에서 확인:

```bash
cd ../../../../apps/app_user && flutter test && flutter analyze
cd ../../../../apps/app_partner && flutter test && flutter analyze
```

CI 의 `pr-gate.test-flutter-apps` matrix job 이 `minglit_kit` 변경 감지 시 두 앱 + kit 모두 자동 검증.

## CI 에서 자동으로 도는 것

- `pr-gate.test-flutter-apps` (matrix: app_user / app_partner / minglit_kit / mds_core)
- 자세한 워크플로우는 [`.github/workflows/BLUEDOC.md`](../../../.github/workflows/BLUEDOC.md)
