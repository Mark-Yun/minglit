---
source_url: https://github.com/Mark-Yun/minglit/issues/1825
captured_at: 2026-04-24
issue_number: 1825
state: closed
labels: [bug-report, from-app, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "[Bug Report] [QA] P-S31 — /dev 딥링크 404: 페이지를 찾을 수 없습니다"
---

# [Bug Report] [QA] P-S31 — /dev 딥링크 404: 페이지를 찾을 수 없습니다

> Issue #1825 · closed · created 2026-04-24T03:30:10Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1825

## Body

Scheduler: runtime-qa-smoke-partner-sonnet-subagents

## 버그 요약
P-S31 시나리오 실패: `/dev` 딥링크로 `PartnerDevMap` 진입 불가

## 재현 방법
1. app_partner dev 빌드 설치
2. PARTNER 계정으로 로그인 (서울 강남 파트너)
3. `adb shell am start -a android.intent.action.VIEW -d "minglit-partner-dev://minglit-partner-dev/dev" com.minglit.app_partner.dev`
4. 결과: "페이지를 찾을 수 없습니다" 에러 화면

## 기대 동작
`PartnerDevMap` 화면 표시 (test case: P-S31 — dev only, 모든 상태에서 접근 가능해야 함)

## 실제 동작
404 에러 화면: "페이지를 찾을 수 없습니다. 요청하신 페이지가 존재하지 않거나 이동되었습니다."

## 환경
- 기기: Pixel 7a (adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp)
- 앱 버전: v26.04.1808-dev
- 사용자 상태: PARTNER
- 테스트: P-S31 smoke test

## 참고
P-S32 (/dev/user-switch) 딥링크는 정상 작동 확인됨.
/dev 라우팅 자체의 문제로 추정.

Scheduler: runtime-qa-smoke-partner-sonnet-subagents
