---
source_url: https://github.com/Mark-Yun/minglit/issues/1262
captured_at: 2026-04-11
issue_number: 1262
state: closed
labels: [bug, P3-low, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA WARNING — Bug icon overlay overlaps More tab in Partner App"
---

# 🐛 Runtime QA WARNING — Bug icon overlay overlaps More tab in Partner App

> Issue #1262 · closed · created 2026-04-11T03:32:52Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1262

## Body

Scheduler: runtime-qa-smoke-partner-gemini
Status: WARNING
Context: Partner App Home/Shell screen.
Description: The red bug icon (dev tool) overlay at the bottom right partially overlaps with the 'More' (더보기) tab touch target. 
Observation: Tapping the 'More' tab frequently triggers the bug report overlay instead of navigating to the More screen.
Evidence: [qa-sessions/20260411-121608/screenshots/more_screen_retry.png]
Suggested Fix: Move the bug icon higher or to a less crowded area (e.g., top right or center right).

## Comments (6)

### Comment 1 — @Mark-Yun on 2026-04-12

🤖 **tpm-exec-report-claude-subagents** 라벨 라우팅.

P3-low + needs-swe 부착. Dev 빌드 전용 디버그 아이콘 위치 문제로, 프로덕션 영향 없음. QA 테스트 편의를 위해 여유 시 수정.

### Comment 2 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-2** 작업 시작합니다.

### Comment 3 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-2** PR #1267 생성 완료. auto-merge 활성화함. CI 통과 시 자동 squash merge 예정.

### Comment 4 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-2** PR #1268 생성 완료. auto-merge 활성화.

### Comment 5 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-codex-1** 완료 확인했습니다.

PR #1268 머지 완료: https://github.com/Mark-Yun/minglit/pull/1268

- CodeRabbit 코멘트 반영: BugReporter FAB 오프셋을 `MinglitSpacing.medium` 토큰으로 변경
- 회귀 테스트 보강: `top/right` 위치가 토큰 값을 쓰는지 검증
- CI: `ci-result` 포함 required checks 통과
- 참고: CI에서 Linux golden 1장이 자동 갱신되어 포함됐고, 재실행 후 통과했습니다.

### Comment 6 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-2** PR #1268 머지 완료. 작업 종료합니다.
