---
source_url: https://github.com/Mark-Yun/minglit/issues/2139
captured_at: 2026-05-04
issue_number: 2139
state: open
labels: [report-runtime-qa, needs-qa]
author: Mark-Yun
title: "❓ Runtime QA 의문 — U-S20 /dev 라우트 미구현 (테스트 카탈로그 vs 구현 불일치)"
---

# ❓ Runtime QA 의문 — U-S20 /dev 라우트 미구현 (테스트 카탈로그 vs 구현 불일치)

> Issue #2139 · open · created 2026-05-04 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2139

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 발견 경위
app-user-smoke.md 스모크 테스트 세션 (2026-05-04) — U-S20 실행 중

## 현상

smoke test 카탈로그 `docs/qa/test-cases/app-user-smoke.md`에는 다음과 같이 명세되어 있음:

| # | 화면 | 경로 | Page 클래스 | GUEST | AUTH | VERIFIED | 비고 |
|---|------|------|------------|-------|------|----------|------|
| U-S20 | 개발 도구 | `/dev` | `UserDevMap` | OK | OK | OK | dev flavor만 접근 가능 |
| U-S21 | 유저 전환 | `/dev/switch` | `DevUserSwitchScreen` | OK | OK | OK | dev flavor만 접근 가능 |

그러나 실제 앱 (`com.minglit.app_user.dev`, v26.05.2114-dev)에서 딥링크 `minglit://app/dev`로 진입 시:

```
페이지를 찾을 수 없습니다.
요청하신 페이지가 존재하지 않거나 이동되었습니다.
```

UI dump 증거:
```
content-desc="페이지를 찾을 수 없습니다."
content-desc="요청하신 페이지가 존재하지 않거나 이동되었습니다."
content-desc="홈으로" (버튼)
```

반면 U-S21 `/dev/switch`는 정상 작동 (Dev: Session Switcher 화면 진입 확인).

## 의문 사항

1. `/dev` → `UserDevMap` 라우트가 코드에서 제거/미구현된 것인가?
2. 아니면 테스트 카탈로그 경로가 잘못 명세된 것인가?
3. `UserDevMap`이 실제로 존재하는 클래스인지 확인 필요

## 판정

❓ QUESTION — 테스트 카탈로그 (`app-user-smoke.md`) 수정이 필요하거나, 구현에서 `/dev` 라우트가 복구되어야 함.

## 환경
- 앱: com.minglit.app_user.dev v26.05.2114-dev
- 디바이스: Pixel 7a
- Scheduler: runtime-qa-smoke-user-sonnet-subagents
- 테스트 날짜: 2026-05-04
