---
source_url: https://github.com/Mark-Yun/minglit/issues/1322
captured_at: 2026-04-12
issue_number: 1322
state: closed
labels: [P0-critical, report-runtime-qa]
author: Mark-Yun
title: "🐛 [HARD BLOCK] Build failed on dev branch due to Redeclaration of MainActivity"
---

# 🐛 [HARD BLOCK] Build failed on dev branch due to Redeclaration of MainActivity

> Issue #1322 · closed · created 2026-04-12T12:08:19Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1322

## Body

### Summary
Commit 93c5ba93b4c57bb44dbba3f3e57ac6d066c4604b (#1295) introduced duplicate `MainActivity.kt` files in both `app_user` and `app_partner`.
This causes a compilation error in the Kotlin compiler because both `src/main` and `src/dev` provide the same class in the same package.

### Error Message
```
e: file:///.../apps/app_partner/android/app/src/dev/kotlin/com/minglit/app_partner/MainActivity.kt:12:7 Redeclaration:
class MainActivity : FlutterActivity
e: file:///.../apps/app_partner/android/app/src/main/kotlin/com/minglit/app_partner/MainActivity.kt:5:7 Redeclaration:
class MainActivity : FlutterActivity
```

### Affected Files
- `apps/app_partner/android/app/src/dev/kotlin/com/minglit/app_partner/MainActivity.kt`
- `apps/app_user/android/app/src/dev/kotlin/com/minglit/app_user/MainActivity.kt`

### Expected Behavior
The `dev` flavor should either:
1. Exclude the `src/main` version of the file via `build.gradle.kts`.
2. Or, the `src/main` version should be moved to a different source set (e.g. `prod`).

Scheduler: runtime-qa-cuj-partner-gemini
Label: needs-swe, report-runtime-qa

## Comments (4)

### Comment 1 — @Mark-Yun on 2026-04-12

## 분석

PR #1295에서 `src/dev/MainActivity.kt`를 추가했는데, `src/main/MainActivity.kt`가 이미 존재. Android source set에서 Kotlin 파일은 override가 안 되고 같이 컴파일돼서 Redeclaration.

## 수정 방안

`src/dev/MainActivity.kt` 삭제. `src/main/MainActivity.kt`에 FlutterEngineCache 등록 로직 이관. FlutterEngineCache는 release에서도 무해 (BroadcastReceiver가 dev에만 있으므로 호출 안 됨).

대상: app_user + app_partner 둘 다.

### Comment 2 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 3 — @Mark-Yun on 2026-04-12

Fix PR을 생성했습니다: #1341

https://github.com/Mark-Yun/minglit/pull/1341

- `src/dev/MainActivity.kt` 삭제 (app_user, app_partner 둘 다)
- FlutterEngineCache 로직을 `src/main/MainActivity.kt`로 통합
- auto-merge 활성화 완료

### Comment 4 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-1** PR #1341이 dev에 머지 완료. MainActivity 중복 선언 해결됨. 두 앱 모두 FlutterEngineCache 로직을 src/main으로 통합하고 src/dev 파일 삭제.
