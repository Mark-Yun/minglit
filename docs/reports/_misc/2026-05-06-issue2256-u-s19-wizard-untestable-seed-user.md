---
source_url: https://github.com/Mark-Yun/minglit/issues/2256
captured_at: 2026-05-06
issue_number: 2256
state: open
labels: [needs-qa, report-runtime-qa]
author: Mark-Yun
title: "❓ Runtime QA 의문 — U-S19 신청 위저드 테스트 불가: 시드 유저가 모든 이벤트에 이미 신청됨"
---

# ❓ Runtime QA 의문 — U-S19 신청 위저드 테스트 불가: 시드 유저가 모든 이벤트에 이미 신청됨

> Issue #2256 · open · created 2026-05-05T21:57:51Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2256

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 상황

app-user-smoke.md U-S19 (이벤트 신청 위저드 진입) 스모크 테스트 시, DevUserSwitchScreen의 유일한 VERIFIED 유저 `user_18_f_강남@test.com`가 홈에 표시되는 **모든 이벤트**에 이미 신청되어 있어 위저드 화면 진입 불가.

## 확인된 상태

- 홈 이벤트 3개: CUJ-P05 파티, 스포츠 소셜 모임, 아트 & 문화 이벤트 — 모두 "이미 신청한 이벤트" 표시
- 파트너 이벤트 페이지에서도 동일
- 내 티켓 목록: CUJ-P05, U-S19 신청 테스트 이벤트, 소셜 클래스 이벤트 3건 존재

## 영향

- U-S19 (EventApplicationWizardPage 진입) 스모크 검증 불가
- 중복 신청 방지(U-E03)는 정상 동작 확인됨

## 요청

1. 시드 데이터에 `user_18_f_강남`이 미신청인 이벤트 1개 이상 유지
2. 또는 DevUserSwitchScreen에 신청 이력 없는 VERIFIED 유저 추가 (예: `user_qa_fresh@test.com`)
3. 또는 `app-user-smoke.md` U-S19 시나리오에 전제조건 명시

## 관련 파일

- `docs/qa/test-cases/app-user-smoke.md` U-S19
- `supabase/seed/` 시드 데이터
