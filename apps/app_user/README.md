# app_user — 빌드·실행 명령

> 폴더 구조·아키텍처는 [`BLUEDOC.md`](./BLUEDOC.md), [`../architecture.md`](../architecture.md) 참고.

## 사전 설정

```bash
# Java 17 (Fix #2287: Gradle 8.14 + Java 25 호환성 이슈)
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
```

## 실행

```bash
# 개발 모드 (DevMap 시작)
flutter run -t lib/dev_main.dart --flavor dev --dart-define-from-file=../../minglit_env/dev/flutter.env

# 프로덕션 모드 (Router 시작)
flutter run -t lib/main.dart --flavor dev --dart-define-from-file=../../minglit_env/dev/flutter.env
```

## 빌드

```bash
# Debug APK (디폴트 — CLAUDE.md "Build Defaults")
flutter build apk --flavor dev --debug --dart-define-from-file=../../minglit_env/dev/flutter.env

# Release APK (명시적 요청 시만)
flutter build apk --flavor dev --release --dart-define-from-file=../../minglit_env/dev/flutter.env

# ADB 설치 (wireless 예시)
adb -s adb-R3CX803P2ND-8btuuD._adb-tls-connect._tcp install -r build/app/outputs/flutter-apk/app-dev-debug.apk
```

## 테스트·분석·포맷

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test                                    # unit + widget
flutter test --tags golden                      # golden (Alchemist)
flutter test test/integration/                  # integration
dart format .
```

## CI 에서 자동으로 도는 것

- `pr-gate`: analyze + test + golden + gitleaks (required check)
- `pr-setup-format`: PR push 마다 `dart fix --apply` + `dart format` 자동 적용 후 commit
- 자세한 워크플로우는 [`.github/workflows/BLUEDOC.md`](../../.github/workflows/BLUEDOC.md)
