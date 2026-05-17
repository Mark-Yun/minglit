# app_partner — 빌드·실행 명령

> 폴더 구조·아키텍처는 [`BLUEDOC.md`](./BLUEDOC.md), [`../architecture.md`](../architecture.md), [`architecture.md`](./architecture.md) (권한 routing) 참고.

## 사전 설정

```bash
# Java 17 (Fix #2287)
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
```

## 실행

```bash
# 개발 모드 (DevMap 시작)
flutter run -t lib/dev_main.dart --flavor dev --dart-define-from-file=../../minglit_env/dev/flutter.env

# 프로덕션 모드 (로그인 화면 시작)
flutter run -t lib/main.dart --flavor dev --dart-define-from-file=../../minglit_env/dev/flutter.env
```

## 빌드

```bash
flutter build apk --flavor dev --debug --dart-define-from-file=../../minglit_env/dev/flutter.env
flutter build apk --flavor dev --release --dart-define-from-file=../../minglit_env/dev/flutter.env
```

## 테스트·분석·포맷

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test                       # unit + widget
flutter test --tags golden         # golden
flutter test test/integration/     # integration
dart format .
```

## CI 에서 자동으로 도는 것

- `pr-gate`, `pr-setup-format` 등 — [`.github/workflows/BLUEDOC.md`](../../.github/workflows/BLUEDOC.md) 참고
