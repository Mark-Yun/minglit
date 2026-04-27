---
source_url: https://github.com/Mark-Yun/minglit/issues/1653
captured_at: 2026-04-20
issue_number: 1653
state: closed
labels: [bug, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — CUJ-U02 입장 QR 생성 실패 (Ticket signing key not configured)"
---

# 🐛 Runtime QA 버그 — CUJ-U02 입장 QR 생성 실패 (Ticket signing key not configured)

> Issue #1653 · closed · created 2026-04-20T06:32:00Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1653

## Body

Scheduler: runtime-qa-cuj-user-sonnet-subagents

## 발견 시나리오
CUJ-U02: 이벤트 참가 → 체크인 → 매칭 투표

## 재현 단계
1. DevUserSwitchScreen에서 `user_18_f_강남@test.com` 로그인
2. 마이페이지 → 구매 내역 → 구매 항목 탭
3. "입장 QR" 버튼 탭

## 관찰 결과
QR 코드 화면 진입 시 Edge Function에서 500 에러 발생:
```
[E] TIME: 2026-04-20T02:30:57.290860 Error fetching ticket token
ERROR: FunctionException(status: 500, details: {error: Ticket signing key not configured}, reasonPhrase: Internal Server Error)
```

## 기대 결과
QR 코드가 정상 렌더링되어 체크인 가능

## 추정 원인
티켓 서명에 필요한 환경변수(시크릿 키)가 dev 환경 Edge Function에 미설정

## 환경
- 앱: app_user.dev (2026-04-20 빌드)
- 디바이스: Pixel 7a  
- 테스트 계정: user_18_f_강남@test.com
- 구매 항목: [QA] 스포츠 소셜 이벤트 (결제완료, D-29)

## 판정
❌ FAIL — 체크인/매칭의 핵심 경로 차단

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-20

## 수정 완료 (needs-swe-sonnet-1)

### 원인
dev Supabase 프로젝트에 `TICKET_SIGNING_PRIVATE_KEY_JWK` / `TICKET_SIGNING_PUBLIC_KEY_JWK` 시크릿이 미설정 상태였음.

### 조치
Ed25519 키 쌍을 생성하여 두 시크릿을 dev 프로젝트(`cnuahgrfzcqkmdyhunuk`)에 설정:
- `TICKET_SIGNING_PRIVATE_KEY_JWK` → `user-get-ticket-token` Edge Function 서명용
- `TICKET_SIGNING_PUBLIC_KEY_JWK` → `event-checkin` Edge Function 검증용

Supabase Edge Function은 시크릿 변경 즉시 재시작되므로 코드 배포 없이 적용됨.

### 확인 방법
앱에서 구매 완료 티켓의 "입장 QR" 버튼을 탭하여 QR 코드가 정상 렌더링되는지 확인.
