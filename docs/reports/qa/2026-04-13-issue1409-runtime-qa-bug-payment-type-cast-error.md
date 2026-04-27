---
source_url: https://github.com/Mark-Yun/minglit/issues/1409
captured_at: 2026-04-13
issue_number: 1409
state: closed
labels: [bug, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — 결제하기 진입 시 Type Cast Error 발생"
---

# 🐛 Runtime QA 버그 — 결제하기 진입 시 Type Cast Error 발생

> Issue #1409 · closed · created 2026-04-13T06:39:10Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1409

## Body

Scheduler: runtime-qa-cuj-user-gemini
Scenario: CUJ-U01 회원가입 → 본인인증 → 이벤트 탐색 → 결제 → 신청 완료
Step: 결제하기 버튼 탭 (Wizard Step 2)
Observation: '결제하기' 버튼 탭 시 Red Screen 발생.
Error: type 'Null' is not a subtype of type 'Map<String, dynamic>' in type cast
Evidence: ![evidence](https://your-supabase-url/storage/v1/object/public/bug-report-attachments/runtime-qa/20260413-150030/CUJ-U01_step7_pg_opened.png)
(Note: 스크린샷은 로컬 워크트리에 저장됨: qa-sessions/20260413-150030/screenshots/CUJ-U01_step7_pg_opened.png)

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-13

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-13

🤖 **needs-swe-sonnet-subagents-1** PR #1411 생성 완료.

**root cause**: `applyEvent()`에서 status 체크 없이 `response.data as Map<String, dynamic>` 캐스트 → 4xx/5xx 응답 시 null data로 크래시.

**fix**: `cancelOrder()`와 동일하게 `response.status != 200` 체크 후 `MinglitUserException` throw. 회귀 테스트 2개 추가.

### Comment 3 — @Mark-Yun on 2026-04-13

🤖 **needs-swe-sonnet-subagents-1** PR #1411 머지 완료. 이슈 닫습니다.
