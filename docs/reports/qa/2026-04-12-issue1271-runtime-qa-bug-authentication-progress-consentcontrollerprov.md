---
source_url: https://github.com/Mark-Yun/minglit/issues/1271
captured_at: 2026-04-12
issue_number: 1271
state: closed
labels: [bug, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — 본인인증 진행 중 ConsentControllerProvider disposed 에러 발생"
---

# 🐛 Runtime QA 버그 — 본인인증 진행 중 ConsentControllerProvider disposed 에러 발생

> Issue #1271 · closed · created 2026-04-12T06:22:00Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1271

## Body

Scheduler: runtime-qa-cuj-user-gemini
Session: ./qa-sessions/20260412-150055

## 현상
본인인증 신청 과정에서 '오류 발생' 다이얼로그가 뜨며 프로세스가 중단됨.

## 원인 (추정)
`IdentityVerificationScreen`에서 `consentControllerProvider`를 `read`만 하고 `watch`하지 않아, 비동기 작업(`repository.saveConsents`) 도중에 provider가 disposed되어 에러 발생.

## 로그
```
04-12 02:12:43.740  8196  8196 I flutter : [E] TIME: 2026-04-12T02:12:43.739564 ❌ [ErrorUI] 일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.  ERROR: Cannot use the Ref of consentControllerProvider after it has been disposed.
```

## 영향
- 유저가 본인인증을 완료할 수 없음 (P0급 차단)

## 재현 경로
1. 로그인 (본인인증 미완료 유저)
2. 이벤트 상세 진입 -> '본인인증 후 신청하기' 클릭
3. 본인인증 동의 바텀시트에서 '동의하고 인증' 클릭
4. 1~2초 후 '오류 발생' 다이얼로그 나타남.

## 수정 제안
`IdentityVerificationScreen`의 `build` 메서드 또는 상위 레벨에서 `ref.watch(consentControllerProvider)`를 추가하여 비동기 작업이 완료될 때까지 provider가 유지되도록 함.


## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-12

PR #1284 생성 완료. auto-merge 활성화.

### Comment 3 — @Mark-Yun on 2026-04-12

✅ PR #1284 머지 완료. ConsentControllerProvider disposed 에러 방지 수정이 반영됐습니다.
