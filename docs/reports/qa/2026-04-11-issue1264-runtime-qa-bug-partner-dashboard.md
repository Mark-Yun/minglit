---
source_url: https://github.com/Mark-Yun/minglit/issues/1264
captured_at: 2026-04-11
issue_number: 1264
state: closed
labels: [bug, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — 파트너 대시보드의 '다가오는 이벤트' 숫자가 실제와 다름 (갱신 안 됨)"
---

# 🐛 Runtime QA 버그 — 파트너 대시보드의 '다가오는 이벤트' 숫자가 실제와 다름 (갱신 안 됨)

> Issue #1264 · closed · created 2026-04-11T12:19:56Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1264

## Body

### 현상
새로운 회차(이벤트)를 생성했음에도 불구하고, 파트너 홈 대시보드의 '다가오는 이벤트' 카운트가 '0'으로 유지됨. (실제 상세 목록에는 이벤트가 존재함)

### 재현 경로
1. 파트너 앱 실행 -> 기존 파트너 로그인
2. 홈 대시보드에서 '이벤트 만들기' 탭
3. 특정 파티 선택 후 '회차 생성 완료'
4. 홈 대시보드로 돌아와 '다가오는 이벤트' 카운트 확인

### 관찰 내용
- '자유 오픈 밍글' 파티 상세 페이지의 '이벤트 관리' 탭에는 2026.04.18 회차가 정상적으로 표시됨.
- 그러나 홈 대시보드의 요약 통계(다가오는 이벤트)는 여전히 '0'으로 표시됨.
- 실시간 동기화 이슈 또는 통계 계산 로직 오류로 추정됨.

### 환경
- Session ID: 20260411-210032
- Device: Android
- Build: 26.04.1252-dev

Scheduler: runtime-qa-cuj-partner-gemini

## Comments (4)

### Comment 1 — @Mark-Yun on 2026-04-11

🤖 **needs-swe-sonnet-subagents-2** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-11

PR #1266 생성했습니다. CI 통과 후 auto-merge됩니다.

**Root cause**: `EventCreateController.submit()`에서 이벤트 생성 후 `partyEventsProvider`만 invalidate하고 `partnerDashboardControllerProvider`를 invalidate하지 않아 대시보드 상태가 stale로 유지됨.

**수정 내용**:
- `event_create_controller.dart`: submit() 성공 시 `ref.invalidate(partnerDashboardControllerProvider)` 추가
- `partner_dashboard_controller.dart`: `ref.mounted` 체크 추가로 invalidation 중 race condition 방지
- regression test 추가 (21개 테스트 통과)

### Comment 3 — @Mark-Yun on 2026-04-11

✅ PR #1266 머지 완료. dev 브랜치에 반영됐습니다.

### Comment 4 — @Mark-Yun on 2026-04-11

🤖 **needs-swe-codex-1** PR #1266이 dev에 머지되어 작업 완료 확인했습니다.

- 머지 시각: 2026-04-11T12:53:57Z
- CI: `ci-result` 통과
- CodeRabbit 리뷰 스레드: resolved

이슈는 `Closes #1264`로 자동 close되었습니다.
