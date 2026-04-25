---
source_url: https://github.com/Mark-Yun/minglit/issues/1285
captured_at: 2026-04-12
issue_number: 1285
state: closed
labels: [bug, needs-review, report-runtime-qa]
author: Mark-Yun
title: "⚠️ Runtime QA 버그 — BugReport FAB이 홈 화면 마이페이지 버튼 터치 영역 차단"
---

# ⚠️ Runtime QA 버그 — BugReport FAB이 홈 화면 마이페이지 버튼 터치 영역 차단

> Issue #1285 · closed · created 2026-04-12T08:58:19Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1285

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 현상

홈 화면에서 BugReport FAB([912,160][1038,286])이 마이페이지 네비게이션 버튼([933,129][1059,255])의 터치 영역(center: 996,192)과 겹쳐 마이페이지 버튼 탭 시 BugReport 다이얼로그가 열림.

## 재현 경로

1. 앱 실행 → 홈 화면
2. 우측 상단 마이페이지 아이콘 탭 (center: 996, 192)
3. 기대: 마이페이지로 이동
4. 실제: BugReport FAB 다이얼로그 오픈

## 영향 범위

- 마이페이지 버튼 center(996,192)이 FAB bounds[912,160][1038,286] 안에 있음
- 일반 사용자는 y=140 근처의 버튼 상단을 정확히 탭해야만 마이페이지 접근 가능
- PR #1268에서 FAB를 bottom→top으로 이동한 이후 발생

## 원인 추정

PR #1268 (BugReporter FAB bottom → top 이동) 이후 FAB가 헤더 우측 상단에 배치되면서 기존 네비게이션 버튼 위에 오버레이됨.

## 증거

- FAB bounds: [912,160][1038,286]
- MyPage 버튼 bounds: [933,129][1059,255]  
- 터치 center(996,192): FAB 내부에 포함됨
- 우회 방법: y=140 탭 (버튼 상단, FAB 위)

![홈 화면](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/runtime-qa/20260412-173634/fab_overlap_home.png)

## 세션 정보

- Session: 20260412-173634
- Device: Pixel 7a (adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp)
- 앱 버전: dev flavor debug build (dev branch HEAD)

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-12

fab 는 없애고, 우측 상단 액션바에 액션 버튼으로 변경 (dev 에서만 보이도록)

### Comment 2 — @Mark-Yun on 2026-04-12

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 3 — @Mark-Yun on 2026-04-12

PR #1299 생성. auto-merge 활성화.
