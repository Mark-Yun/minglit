---
source_url: https://github.com/Mark-Yun/minglit/issues/1657
captured_at: 2026-04-20
issue_number: 1657
state: closed
labels: [bug, bug-report, P1-high, report-exec, from-app]
author: Mark-Yun
title: "[Bug Report] [QA] 티켓 조회 시 500 에러 (signing key)"
---

# [Bug Report] [QA] 티켓 조회 시 500 에러 (signing key)

> Issue #1657 · closed · created 2026-04-20T06:55:16Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1657

## Body


### 🐞 Bug Report

**Description:**
티켓 토큰 조회 시 500 Internal Server Error 발생. 로그: Ticket signing key not configured. (CUJ-U01)

**Environment:**
- Platform: android
- Timestamp: 2026-04-20T02:55:15.399326

<details>
<summary>📋 Logs</summary>

```log
[I] TIME: 2026-04-20T02:30:34.321761 🧭 [Nav] PUSH: / | args: {}
[D] TIME: 2026-04-20T02:30:34.380377 getEventsByType called | type: EventFeedType.newArrivals
[D] TIME: 2026-04-20T02:30:34.391536 getTodayActiveEventsForUser called | userId: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[D] TIME: 2026-04-20T02:30:35.454990 getBulkEligibilityData called | userId: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[I] TIME: 2026-04-20T02:30:36.759772 🧭 [Nav] PUSH: /my (from /) | args: {}
[D] TIME: 2026-04-20T02:30:37.041630 getBulkEligibilityData success
[D] TIME: 2026-04-20T02:30:37.043009 Eligibility data arrived, refiltering 0 events
[D] TIME: 2026-04-20T02:30:37.047632 getTodayActiveEventsForUser success | count: 0
[D] TIME: 2026-04-20T02:30:37.282313 getEventsByType success | count: 8
[D] TIME: 2026-04-20T02:30:37.323707 [LocationService] Using last known position
[I] TIME: 2026-04-20T02:30:40.064716 🧭 [Nav] PUSH: /tickets/my (from /my) | args: {}
[D] TIME: 2026-04-20T02:30:40.082481 getMyTickets called | userId: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[D] TIME: 2026-04-20T02:30:40.608669 getMyTickets success | count: 1
[I] TIME: 2026-04-20T02:30:50.580734 🧭 [Nav] PUSH: /tickets/:ticketId/qr (from /tickets/my) | args: {ticketId: 3fab13d4-819c-4d34-a505-fd7ab0cedfcd}
[E] TIME: 2026-04-20T02:30:57.290860 Error fetching ticket token  ERROR: FunctionException(status: 500, details: {error: Ticket signing key not configured}, reasonPhrase: Internal Server Error)
[I] TIME: 2026-04-20T02:31:09.008295 🧭 [Nav] POP: /tickets/:ticketId/qr (from /tickets/my) | args: {ticketId: 3fab13d4-819c-4d34-a505-fd7ab0cedfcd}
[I] TIME: 2026-04-20T02:31:11.332066 🧭 [Nav] POP: /tickets/my (from /my) | args: {}
[I] TIME: 2026-04-20T02:31:13.631074 🧭 [Nav] POP: /my (from /) | args: {}
[I] TIME: 2026-04-20T02:32:34.506519 🧭 [Nav] PUSH: Unknown Route (from /)
[D] TIME: 2026-04-20T02:32:34.528773 getEventById called | id: bc87cd87-2bf2-42bd-9bf7-d83bd08e5fa0
[D] TIME: 2026-04-20T02:32:35.636665 getEventById success | title: [QA] 아트 문화 이벤트
[D] TIME: 2026-04-20T02:32:36.036875 getApplication called | event: bc87cd87-2bf2-42bd-9bf7-d83bd08e5fa0, user: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[I] TIME: 2026-04-20T02:32:37.937437 🧭 [Nav] PUSH: Unknown Route
[D] TIME: 2026-04-20T02:32:37.970728 getTicketBalanceStatus called | eventId: bc87cd87-2bf2-42bd-9bf7-d83bd08e5fa0
[D] TIME: 2026-04-20T02:32:38.262685 getTicketBalanceStatus success | count: 1
[I] TIME: 2026-04-20T02:32:41.391866 🧭 [Nav] POP: Unknown Route
[I] TIME: 2026-04-20T02:32:41.399218 🧭 [Nav] PUSH: /events/:eventId/apply | args: {eventId: bc87cd87-2bf2-42bd-9bf7-d83bd08e5fa0, ticket-id: a594f9eb-610a-48ad-a0f5-764e38df12b9}
[D] TIME: 2026-04-20T02:34:12.709742 applyEvent called | event: bc87cd87-2bf2-42bd-9bf7-d83bd08e5fa0, ticket: a594f9eb-610a-48ad-a0f5-764e38df12b9
[I] TIME: 2026-04-20T02:34:16.192074 ✅ [EventRepo] Free application confirmed. ID: 8a685e7f-3261-4504-9538-b643f7c752c8
[I] TIME: 2026-04-20T02:34:16.199834 🧭 [Nav] REPLACE: Unknown Route (from /events/:eventId/apply)
[I] TIME: 2026-04-20T02:42:24.488771 🧭 [Nav] POP: Unknown Route
[I] TIME: 2026-04-20T02:43:50.899651 🧭 [Nav] POP: Unknown Route (from /)
[I] TIME: 2026-04-20T02:46:05.179153 🧭 [Nav] PUSH: /search (from /) | args: {}
[I] TIME: 2026-04-20T02:52:06.758228 🧭 [Nav] PUSH: Unknown Route (from /search)
[D] TIME: 2026-04-20T02:52:06.771593 getEventById called | id: 322eaa20-8193-463b-a9cb-6feaecb7a7d8
[D] TIME: 2026-04-20T02:52:08.168613 getEventById success | title: [QA] 스포츠 소셜 이벤트
[D] TIME: 2026-04-20T02:52:08.201311 getApplication called | event: 322eaa20-8193-463b-a9cb-6feaecb7a7d8, user: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[I] TIME: 2026-04-20T02:53:37.445092 QaBugReportChannel: received triggerBugReport title="[QA] 전반적인 앱 내 이미지 엑박 노출 이슈" scenario=null session=null
[D] TIME: 2026-04-20T02:53:39.501436 Uploading bytes to bug-report-attachments/layout-dumps/fbd013c4-584b-4938-becb-6c7eb5342c89.txt...
[D] TIME: 2026-04-20T02:53:39.547852 Uploading bytes to bug-report-attachments/screenshots/f439ae0a-20bf-45a9-b6e7-00b3b75aea3f.png...
[D] TIME: 2026-04-20T02:53:40.985213 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/f439ae0a-20bf-45a9-b6e7-00b3b75aea3f.png
[D] TIME: 2026-04-20T02:53:40.987096 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/fbd013c4-584b-4938-becb-6c7eb5342c89.txt
[I] TIME: 2026-04-20T02:53:43.549741 Bug reported successfully via Edge Function
[I] TIME: 2026-04-20T02:53:43.550386 QaBugReportChannel: report submitted successfully
[I] TIME: 2026-04-20T02:54:26.003420 QaBugReportChannel: received triggerBugReport title="[QA] 무료 이벤트 결제 완료 시 앱 이탈 현상" scenario=null session=null
[D] TIME: 2026-04-20T02:54:27.184355 Uploading bytes to bug-report-attachments/layout-dumps/a51898ec-0361-46d0-a7f8-d7f56487ff02.txt...
[D] TIME: 2026-04-20T02:54:27.199735 Uploading bytes to bug-report-attachments/screenshots/05b47e8b-2089-4e42-a31f-2c5bac643fea.png...
[D] TIME: 2026-04-20T02:54:27.777790 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/05b47e8b-2089-4e42-a31f-2c5bac643fea.png
[D] TIME: 2026-04-20T02:54:27.781102 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/a51898ec-0361-46d0-a7f8-d7f56487ff02.txt
[I] TIME: 2026-04-20T02:54:30.011333 Bug reported successfully via Edge Function
[I] TIME: 2026-04-20T02:54:30.013465 QaBugReportChannel: report submitted successfully
[I] TIME: 2026-04-20T02:55:13.686201 QaBugReportChannel: received triggerBugReport title="[QA] 티켓 조회 시 500 에러 (signing key)" scenario=null session=null
[D] TIME: 2026-04-20T02:55:14.654470 Uploading bytes to bug-report-attachments/layout-dumps/03d39f6c-3271-4fce-bc6a-3884779f961c.txt...
[D] TIME: 2026-04-20T02:55:14.664882 Uploading bytes to bug-report-attachments/screenshots/0a8d8d66-d5a9-4dc9-a173-f396d57701b7.png...
[D] TIME: 2026-04-20T02:55:14.963458 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/0a8d8d66-d5a9-4dc9-a173-f396d57701b7.png
[D] TIME: 2026-04-20T02:55:15.398120 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/03d39f6c-3271-4fce-bc6a-3884779f961c.txt
```

</details>


## Screenshot
![Screenshot](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/0a8d8d66-d5a9-4dc9-a173-f396d57701b7.png)


## Environment
| Key | Value |
|-----|-------|
| appVersion | 26.04.1636-dev |
| buildNumber | 26041636 |
| packageName | com.minglit.app_user.dev |
| platform | android |
| osVersion | 15 |
| deviceModel | Pixel 7a |
| screenSize | 1080x2400 |
| networkStatus | wifi |
| batteryLevel | 71 |


## Layout Dump
[📐 View Layout Dump](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/03d39f6c-3271-4fce-bc6a-3884779f961c.txt)


## Comments (4)

### Comment 1 — @Mark-Yun on 2026-04-20

🤖 **needs-tpm-claude-1** 트리아지.

## 배경
dev 환경 (app v26.04.1636-dev, android) 티켓 QR 화면 진입 시 Edge Function이 500으로 실패.
에러: `FunctionException(status: 500, details: {error: Ticket signing key not configured})`

## 영향
- 모든 유저 티켓 QR 조회 불가 → dev 환경 티켓 검증/사용 테스트 블로킹
- Runtime QA CUJ-U01 테스트 세션 차단

## 추정 원인
Edge Function 환경 변수(`TICKET_SIGNING_KEY` 류)가 dev 환경에 미설정 또는 미배포.

## 수정 방향
1. `supabase/functions/` 내 ticket 토큰 생성 관련 Edge Function 특정 (e.g., `get-ticket-token`, `mint-ticket-token` 등)
2. 해당 Edge Function의 signing key env 이름 확인
3. dev Supabase 프로젝트 secrets에 `supabase secrets set TICKET_SIGNING_KEY=...` 로 등록 (또는 관련 env 이름)
4. Edge Function 재배포 후 동일 티켓(ID: `3fab13d4-819c-4d34-a505-fd7ab0cedfcd`)으로 검증

## 검증
- `curl`로 Edge Function 직접 호출 → 200 확인
- app에서 `/tickets/:ticketId/qr` 진입 → 에러 없이 QR 표시

P1-high로 라벨링, needs-swe로 라우팅합니다.

### Comment 2 — @Mark-Yun on 2026-04-20

🤖 **needs-swe-sonnet-1** 작업 시작합니다. 티켓 signing key Edge Function 조사 중.

### Comment 3 — @Mark-Yun on 2026-04-20

## 원인 분석 및 수정 필요 사항 (needs-swe-sonnet-1)

### 원인

`user-get-ticket-token` Edge Function이 `TICKET_SIGNING_PRIVATE_KEY_JWK` 환경 변수를 찾지 못함 → 500 에러.

관련 코드 (`supabase/functions/user-get-ticket-token/index.ts`):
```typescript
const privateKeyJwkStr = Deno.env.get('TICKET_SIGNING_PRIVATE_KEY_JWK');
if (!privateKeyJwkStr) {
  return errorResponse('Ticket signing key not configured', 500);
}
```

또한 `TICKET_SIGNING_PRIVATE_KEY_JWK` / `TICKET_SIGNING_PUBLIC_KEY_JWK`가 `env-manifest.json`에 등록되지 않아 sync 검사에서 누락 상태.

### 코드 수정 (자동 처리)

`env-manifest.json`에 두 키를 등록하는 PR을 별도 생성합니다.

### 수동 처리 필요 (Mark님 액션 필요)

dev 및 prod Supabase Edge Function 환경 변수 설정:

**1. Ed25519 키 쌍 생성 (터미널):**
```bash
# Deno 사용 (deno 설치 필요)
deno eval "
const keyPair = await crypto.subtle.generateKey(
  { name: 'Ed25519' },
  true,
  ['sign', 'verify']
);
const privateJwk = await crypto.subtle.exportKey('jwk', keyPair.privateKey);
const publicJwk = await crypto.subtle.exportKey('jwk', keyPair.publicKey);
console.log('PRIVATE:', JSON.stringify(privateJwk));
console.log('PUBLIC:', JSON.stringify(publicJwk));
"
```

**2. Supabase Dashboard에서 Secret 설정:**
- Project Settings → Edge Functions → Add Secret
- `TICKET_SIGNING_PRIVATE_KEY_JWK` = 생성된 private JWK (JSON 문자열)
- `TICKET_SIGNING_PUBLIC_KEY_JWK` = 생성된 public JWK (JSON 문자열)
- **dev 프로젝트**와 **prod 프로젝트** 모두 설정 필요

> ⚠️ Private Key는 절대 Git에 커밋하지 마세요. Supabase Dashboard에서만 관리하세요.

### Comment 4 — @Mark-Yun on 2026-04-20

🤖 **needs-swe-sonnet-1** 상태 업데이트.

**코드 수정 완료**: PR #1669 (`fix(env): TICKET_SIGNING_*_KEY_JWK를 env-manifest.json에 등록`) — dev 브랜치에 머지됨.

**남은 작업 (Mark님 수동 액션 필요)**: Supabase Dashboard에서 Edge Function secrets 설정.

이전 코멘트의 지침대로 dev/prod 프로젝트 모두 `TICKET_SIGNING_PRIVATE_KEY_JWK`, `TICKET_SIGNING_PUBLIC_KEY_JWK` 설정 필요. `report-exec` 라벨 추가.
