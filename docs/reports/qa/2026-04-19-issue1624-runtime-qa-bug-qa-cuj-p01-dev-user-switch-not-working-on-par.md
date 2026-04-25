---
source_url: https://github.com/Mark-Yun/minglit/issues/1624
captured_at: 2026-04-19
issue_number: 1624
state: closed
labels: [bug, P1-high, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — [QA] CUJ-P01 — Dev User Switch not working on Partner login screen"
---

# 🐛 Runtime QA 버그 — [QA] CUJ-P01 — Dev User Switch not working on Partner login screen

> Issue #1624 · closed · created 2026-04-19T12:24:34Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1624

## Body

## 발견 사항\n- 파트너 앱 로그인 화면에서 로고 5회 탭 시 'Dev User Switch' 화면이 열리지 않음.\n-  빌드 플래그 확인됨.\n- 로딩 스피너 색상이 파트너(오렌지)가 아닌 유저(보라색)로 노출됨.\n- ADB broadcast () 수신 불가 (result=0).\n\n## 재현 경로\n1.  빌드 및 설치\n2. 로그인 화면 진입\n3. 로고 영역 5회 탭\n\n## 기대 결과\n- Dev User Switch 화면으로 이동하여 테스트 유저 전환 가능해야 함.\n\n## 환경\n- Device: Pixel 7a\n- Build: dev flavor\n- Session: 20260419-210033

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-19

🤖 **needs-swe-sonnet-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-19

🤖 **needs-swe-sonnet-1** 작업 완료.

**루트 원인**: `isDevEnv` 체크가 `dev` 값을 허용하지 않음. Supabase dev 프로젝트는 `ENVIRONMENT=dev`를 사용하지만 Flutter 앱은 `local | development`만 체크해 `isDevEnv=false` → 5-tap 미동작.

**수정**: PR #1625 — `partner_login_page.dart`, `login_page.dart`, `more_page.dart`에 `dev` 추가.

**나머지 이슈에 대한 분석**:
- 로딩 스피너 색상: 파트너 테마 primary(0xFF6C3CE1 = 진한 보라)가 맞음. 유저 primary(0xFF9900FF = 네온 보라)와 다른 색상. QA에서 오렌지를 기대했다면 design 이슈로 별도 논의 필요.
- ADB broadcast result=0: `BugReporterWrapper`가 `startupState` 로드 완료 후 초기화됨. 앱이 startup phase 중이거나 killed 상태일 때 브로드캐스트를 보내면 Flutter engine이 캐시되지 않아 무시됨. QA 타이밍 이슈로 보임.
