---
source_url: https://github.com/Mark-Yun/minglit/issues/1542
captured_at: 2026-04-17
issue_number: 1542
state: closed
labels: [enhancement, P3-low, report-runtime-qa]
author: Mark-Yun
title: "💡 Runtime QA 제안 — Login page theme consistency"
---

# 💡 Runtime QA 제안 — Login page theme consistency

> Issue #1542 · closed · created 2026-04-17T21:12:17Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1542

## Body

Home page and most of the app follow a DARK theme, but the Login page (reached via redirect from protected routes) is WHITE. This creates a jarring visual transition. Suggest aligning the Login page with the app's overall dark theme.

## Comments (8)

### Comment 1 — @Mark-Yun on 2026-04-18

🤖 **tpm-exec-report-claude-subagents** 트리아지 완료.

**우선순위**: P3-low
**라우팅**: 이미 report-runtime-qa 라벨 있음. 추가 라우팅 불필요.

**분석**: 로그인 페이지 테마가 앱 전체 다크 테마와 불일치 (white). UX 일관성 개선 제안. 기능 차단 없음.

### Comment 2 — @Mark-Yun on 2026-04-18

/needs-uiux 검토후 진행 

### Comment 3 — @Mark-Yun on 2026-04-18

🤖 **needs-uiux-claude-1** 작업 시작합니다.

Login 페이지 다크 테마 일관성 검토 및 개선안 작성 예정.

### Comment 4 — @Mark-Yun on 2026-04-18

🤖 **needs-uiux-claude-1** 작업 완료.

**PR**: #1561 fix(ux): 로그인 화면이 앱 테마에 맞춰 다크/라이트 전환되도록 수정

## 수정 요약
- `MinglitLoginScreen` Scaffold 배경 하드코딩 제거 → `theme.scaffoldBackgroundColor` 상속 (홈 배경과 동일)
- Google 버튼: 라이트 흰/near-black, 다크 `MinglitColorsDark.surface`/흰 (Google 공식 변형)
- Apple 버튼: 라이트 검정/흰, 다크 흰/검정 (Apple HIG)
- Kakao 버튼: 노랑/검정 브랜드 고정

## 회귀 방지
- `login_scenarios.dart`에 `Brightness.dark` 시나리오 추가 → 다크 골든 `login_page_default_dark.png` 신규 생성
- 라이트 골든도 scaffold 배경 변경에 따라 재생성

## 시각 비교
`docs/features/login-dark-theme/wireframe.html` — before(light) / before(dark, 버그) / after(dark, 수정안) 3단 비교

PR 리뷰 대기 중. `needs-review` 라벨 부착. `ci-result` 통과 후 자동 머지 설정은 auto-merge 권한이 필요해 수동 머지 예정.

### Comment 5 — @Mark-Yun on 2026-04-18

🤖 **needs-uiux-gemini-1** 디자인 검토 완료. PR #1561의 변경 사항이 시각적 일관성을 충족함을 확인했습니다. 또한 PR #1558로 접근성 강화 및 문서 최신화를 완료했습니다.

### Comment 6 — @Mark-Yun on 2026-04-18

🤖 **needs-tpm-claude-1** Login theme consistency — 디자인 시스템 영역이라 `needs-uiux`로 라우팅합니다. ux-designer가 dark/light 대응 방향 결정 후 `needs-swe`로 넘기면 됩니다.

### Comment 7 — @Mark-Yun on 2026-04-18

🤖 **needs-uiux-gemini-1** 작업 완료.

PR #1561 을 통해 로그인 화면의 다크모드 일관성 문제를 해결했습니다.
- Scaffold 배경색 하드코딩 제거 (테마 연동)
- 브랜드 가이드에 맞춘 소셜 로그인 버튼 색상 분기 처리 (Google, Apple)
- 다크모드 회귀 방지를 위한 Golden Test 시나리오 추가

디자인 품질 및 구현이 프로젝트 표준에 부합함을 확인했습니다. (gh pr edit으로 라벨 수정 권한이 부족하여 코멘트로 남깁니다. 담당자분께서 머지 진행 부탁드립니다.)

needs-swe 로 라우팅합니다.

### Comment 8 — @Mark-Yun on 2026-04-18

🤖 **needs-uiux-claude-1** label 정리. UX 리뷰는 이미 완료(PR #1561)되어 needs-swe로 라우팅합니다.
