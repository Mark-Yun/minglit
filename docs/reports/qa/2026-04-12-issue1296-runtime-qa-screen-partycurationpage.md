---
source_url: https://github.com/Mark-Yun/minglit/issues/1296
captured_at: 2026-04-12
issue_number: 1296
state: closed
labels: [report-runtime-qa]
author: Mark-Yun
title: "❓ Runtime QA 의문 — 홈 화면에서 큐레이션(PartyCurationPage) 진입 경로 미발견"
---

# ❓ Runtime QA 의문 — 홈 화면에서 큐레이션(PartyCurationPage) 진입 경로 미발견

> Issue #1296 · closed · created 2026-04-12T09:19:37Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1296

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 현상

스모크 테스트 카탈로그(U-S02)에서 `/curation` (PartyCurationPage) 진입 테스트가 필요하나, 홈 화면을 3회 스크롤해도 큐레이션 섹션/버튼을 발견하지 못함.

## 시도한 경로

1. 홈 화면 정렬 탭 영역 - 추천순/마감임박/가까운날짜/가까운거리만 존재
2. 홈 화면 핫태그 섹션 - 태그 칩만 존재
3. 홈 화면 스크롤 다운 3회 - 이벤트 카드만 추가 로드됨
4. GUEST/AUTH(user_20_f_ok) 두 상태 모두 시도

## 질문

1. PartyCurationPage(/curation)로 진입하는 UI 경로가 어디인가?
2. 특정 조건이 필요한가? (VERIFIED 유저, 특정 시간, 지역 설정 등)
3. 스모크 카탈로그 U-S02 테스트 방법 명확화 필요.

## 세션 정보

- Session: 20260412-173634
- Device: Pixel 7a
- 앱 버전: dev flavor debug build (dev branch HEAD)

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-12

🤖 **needs-qa-claude-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-12

## 🤖 **needs-qa-claude-1** 분석 결과

### 결론: **#1293과 중복 이슈**

코드 분석 결과, 큐레이션 페이지(`PartyCurationPage`)의 상태는 다음과 같습니다:

1. **라우트 등록**: `EventCurationRoute` → `/curation` — 정상 등록됨
2. **코디네이터 메서드**: `EventCoordinator.pushEventCuration()` — 정의됨
3. **UI 진입점**: **없음** — `pushEventCuration()`을 호출하는 UI 위젯이 없음

`pushEventCuration()`은 유닛 테스트에서만 호출되고 있으며, 실제 앱 UI에서는 어디에서도 호출하지 않습니다. 이 상태는 스모크 카탈로그 U-S02에 이미 `⚠️ BLOCKED — 홈에서 진입 UI 없음 (see #1293)` 으로 기록되어 있습니다.

### 조치
- 이 이슈는 #1293과 동일한 문제이므로 중복 닫기합니다.
- 큐레이션 진입점 구현은 #1293에서 트래킹됩니다.
- runtime-qa 테스터는 U-S02를 **BLOCKED**으로 스킵하면 됩니다.

### Comment 3 — @Mark-Yun on 2026-04-12

중복 이슈 닫기. #1293에서 트래킹 중.
