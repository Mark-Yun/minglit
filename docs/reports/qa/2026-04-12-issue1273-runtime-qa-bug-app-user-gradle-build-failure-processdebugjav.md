---
source_url: https://github.com/Mark-Yun/minglit/issues/1273
captured_at: 2026-04-12
issue_number: 1273
state: closed
labels: [bug, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — app_user Gradle build failure (processDebugJavaRes)"
---

# 🐛 Runtime QA 버그 — app_user Gradle build failure (processDebugJavaRes)

> Issue #1273 · closed · created 2026-04-12T08:19:28Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1273

## Body

Scheduler: runtime-qa-smoke-user-haiku

## 증상

app_user APK 빌드가 Gradle 컴파일 에러로 실패.

## 재현 경로

```bash
cd ~/workspace/minglit/apps/app_user
flutter build apk --flavor dev --debug --dart-define-from-file=../../minglit_env/dev/flutter.env
```

## 에러 로그

```
FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':device_info_plus:processDebugJavaRes'.
> Cannot access output property 'outDirectory' of task ':device_info_plus:processDebugJavaRes'. 
> Accessing unreadable inputs or outputs is not supported.
> Failed to create MD5 hash for file '/Users/mark/workspace/minglit/apps/app_user/build/device_info_plus/intermediates/java_res/debug/processDebugJavaRes/out/META-INF/device_info_plus_debug.kotlin_module' as it does not exist.
```

## 환경

- 디바이스: Galaxy S10e (adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp)
- 분기: dev (ecb558ce0)
- 명령: flutter clean → flutter pub get → flutter build apk

## 영향

Runtime QA 스모크 테스트 차단 (하드 블로킹)

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-12

## 분석 결과

**원인**: Gradle 빌드 캐시 오염 (stale incremental build entries)

에러 메시지에서:
```
Failed to create MD5 hash for file '...build/device_info_plus/intermediates/java_res/debug/processDebugJavaRes/out/META-INF/device_info_plus_debug.kotlin_module' as it does not exist.
```

`flutter clean`은 `build/` 디렉토리를 제거하지만 Android Gradle 빌드 캐시(`android/.gradle/`, `~/.gradle/caches/transforms-*/`)는 정리하지 않는다. 이전 빌드에서 해당 파일 경로를 참조하는 캐시 엔트리가 남아 있어 다음 빌드에서 실패한다.

**코드 변경 불필요**. 환경 클린으로 해결 가능.

## 해결 방법

```bash
# 방법 1: Android Gradle 전체 클린 (권장)
cd ~/workspace/minglit/apps/app_user
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
flutter build apk --flavor dev --debug --dart-define-from-file=../../minglit_env/dev/flutter.env

# 방법 2: Gradle 빌드 캐시 직접 삭제
rm -rf ~/.gradle/caches/transforms-*
flutter clean && flutter pub get && flutter build apk ...
```

**이슈 닫음** — 코드 버그가 아닌 로컬 환경 Gradle 캐시 오염 문제.
