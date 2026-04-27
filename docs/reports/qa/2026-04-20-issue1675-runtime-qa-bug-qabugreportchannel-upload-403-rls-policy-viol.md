---
source_url: https://github.com/Mark-Yun/minglit/issues/1675
captured_at: 2026-04-20
issue_number: 1675
state: closed
labels: [bug, P1-high, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — QaBugReportChannel 스토리지 업로드 403 (RLS 정책 위반)"
---

# 🐛 Runtime QA 버그 — QaBugReportChannel 스토리지 업로드 403 (RLS 정책 위반)

> Issue #1675 · closed · created 2026-04-20T21:50:52Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1675

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 증상

QA Bug Report 기능(ADB broadcast `com.minglit.dev.QA_BUG_REPORT`)이 스토리지 업로드 단계에서 403 오류로 실패함.

## 오류 로그

```
❌ [StorageRepo] uploadBytes failed  ERROR: StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
Layout dump upload failed (best-effort)  ERROR: StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
❌ [StorageRepo] uploadBytes failed  ERROR: StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
QaBugReportChannel: report submission failed  ERROR: StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
```

- 시각: 2026-04-20 17:46:35
- 앱: `com.minglit.app_user.dev`
- 유저: `user_18_f_강남@test.com` (DevUserSwitchScreen으로 로그인)
- 디바이스: Pixel 7a (`adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp`)
- 앱 버전: `26.04.1667-dev`

## 영향

- runtime-qa의 **핵심 버그 리포팅 메커니즘이 동작 불가**
- 스크린샷/위젯 트리/로그 자동 수집 불가
- 이슈 자동 생성 불가 → 수동 `gh issue create` fallback 필요

## 재현 방법

1. `user_18_f_강남@test.com`으로 DevUserSwitchScreen 로그인
2. ADB broadcast 실행:
   ```bash
   adb shell 'am broadcast -a com.minglit.dev.QA_BUG_REPORT -n com.minglit.app_user.dev/com.minglit.app_user.QaBugReportReceiver --es title "테스트" --es description "테스트"'
   ```
3. logcat에서 403 오류 확인

## 추정 원인

Supabase Storage RLS 정책에서 일반 `user` 역할 계정의 업로드가 허용되지 않음.
QA 버그 리포트 스토리지 버킷의 INSERT 정책 확인 필요.

## 세션 컨텍스트

2026-04-21 스모크 테스트 세션 (runtime-qa-smoke-user-sonnet-subagents) 중 발견.
U-S17 티켓 QR 테스트 단계에서 logcat에서 확인됨.

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-20

🤖 **needs-swe-sonnet-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-20

🤖 **needs-swe-sonnet-1** PR #1676 생성 완료.

**root cause**: `bug-report-attachments` 버킷 INSERT RLS 정책이 dev 인스턴스에서 누락 (기존 migration이 `CREATE POLICY`만 사용 — 재실행 불가).

**fix**: `DROP POLICY IF EXISTS` + `CREATE POLICY`로 멱등 재설정 + pgTAP 테스트 추가.

PR: https://github.com/Mark-Yun/minglit/pull/1676

### Comment 3 — @Mark-Yun on 2026-04-20

CI 통과 확인 (test-pgtap ✅, test-deno-ef ✅). 리뷰어 승인 대기 중.
