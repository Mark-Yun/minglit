---
source_url: https://github.com/Mark-Yun/minglit/issues/2362
captured_at: 2026-05-10
issue_number: 2362
state: open
labels: [report-runtime-qa, bug]
author: Mark-Yun
title: "🛑 HARD BLOCK — app_user build failed due to Kotlin version mismatch"
---

# 🛑 HARD BLOCK — app_user build failed due to Kotlin version mismatch

> Issue #2362 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2362

## Body

## Description
`app_user` build failed on `origin/dev` due to Kotlin version mismatch in `screen_brightness_android` plugin.

## Error Log
```
Execution failed for task ':screen_brightness_android:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.GradleCompilerRunnerWithWorkers$GradleKotlinCompilerWorkAction
   > Internal compiler error. See log for more details
```

## Flutter Fix Recommendation
Your project requires a newer version of the Kotlin Gradle plugin. Update the version number of the plugin with id "org.jetbrains.kotlin.android" in `apps/app_user/android/settings.gradle`.

## Environment
- Device: Pixel 7a
- Branch: origin/dev
- Scheduler: needs-runtime-qa-gemini-1
