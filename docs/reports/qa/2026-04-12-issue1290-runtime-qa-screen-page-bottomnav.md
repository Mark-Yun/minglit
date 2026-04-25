---
source_url: https://github.com/Mark-Yun/minglit/issues/1290
captured_at: 2026-04-12
issue_number: 1290
state: closed
labels: [report-runtime-qa]
author: Mark-Yun
title: "❓ Runtime QA 의문 — 홈 화면에서 마이페이지 접근 경로 불명 (BottomNav 미노출)"
---

# ❓ Runtime QA 의문 — 홈 화면에서 마이페이지 접근 경로 불명 (BottomNav 미노출)

> Issue #1290 · closed · created 2026-04-12T09:08:16Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1290

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 관찰 내용

세션 ID: `20260412-173125`
디바이스: Galaxy S10e (`adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp`)
앱 버전: v26.04.1270-dev (app_user, dev flavor)
인증 상태: AUTH (user_20_f_no@test.com)

uiautomator dump로 홈 화면의 모든 clickable 요소 확인 결과, 마이페이지(/my) 진입 버튼/탭 미발견.

홈 화면 clickable 요소 (Y 기준):
- `[888,165][1032,309]` → Bug Report FAB (확인)
- `[624,129][768,273]` → 검색 (확인)
- `[768,129][912,273]` → 알림 센터 (확인)
- `[912,129][1056,273]` → Bug Report (확인)
- 그 외: 정렬 필터, 태그 필터, 이벤트 카드

Y=1724~2020 하단 탭 시도 시 모두 이벤트 카드 이동. BottomNav 요소 없음.

관련 커밋: #1268 (BugReporter FAB bottom→top 이동으로 BottomNav 탭 충돌 해소)

**질문:**
1. 마이페이지 진입 경로가 어디인가? (BottomNav? 헤더 아이콘?)
2. BottomNav가 uiautomator에 노출되지 않는 이유?
3. GUEST와 AUTH 상태의 네비게이션 구조 차이?

영향 받는 미검증 시나리오: U-S09, U-S10, U-S11, U-S12, U-S13

![홈 화면 AUTH 상태](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/runtime-qa/20260412-173125/home_auth_no_bottomnav.png)
[세션 로그](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/runtime-qa/20260412-173125/session_nav_errors.txt)


## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-12

🤖 **needs-qa-claude-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-12

## QA 분석 결과

### 결론: 버그 아님 — 설계상 의도된 동작

**app_user에는 BottomNav가 없습니다.** 이것은 설계상 의도된 것으로, 아래 문서에 명시되어 있습니다:

- `docs/ux/menu-structure.md:13`: "유저 앱은 StatefulShellRoute를 사용하지 않으며, 모든 라우트가 독립 top-level로 구성됨"
- `docs/ux/design-system/04-navigation.md:9-11`: "유저 앱은 BottomNav Shell을 사용하지 않음"

### app_user vs app_partner 네비게이션 비교

| 앱 | 네비게이션 방식 | BottomNav |
|---|---|---|
| **app_user** | top-level 독립 라우트 | ❌ 없음 |
| **app_partner** | StatefulShellRoute + 5탭 | ✅ 있음 (`partner_scaffold.dart`) |

### 마이페이지 접근 경로

마이페이지(`/my`)는 **홈 AppBar의 프로필 아이콘**을 통해 접근합니다. BottomNav 탭이 아닙니다.

### PR #1268 관계

PR #1268은 BugReporter FAB 위치만 변경했으며 (bottom → top), BottomNav 제거와는 무관합니다. FAB가 **app_partner**의 NavigationBar 탭과 충돌하는 문제를 해결한 것입니다.

### 후속 조치

1. ✅ 테스트 케이스 `app-user-smoke.md`의 홈 액션에 네비게이션 경로를 명확히 표기하겠습니다
2. ✅ Runtime QA 가이드에 app_user 네비게이션 구조 참고 노트를 추가하겠습니다
3. 영향 받는 시나리오(U-S09~U-S13)은 **AppBar 프로필 아이콘 탭 → `/my` 진입**으로 수행 가능합니다

`needs-qa` 라벨 제거하고 이슈를 닫겠습니다.

### Comment 3 — @Mark-Yun on 2026-04-12

PR #1300 에서 테스트 케이스 업데이트 완료.
