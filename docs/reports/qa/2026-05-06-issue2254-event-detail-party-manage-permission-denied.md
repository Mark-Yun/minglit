---
source_url: https://github.com/Mark-Yun/minglit/issues/2254
captured_at: 2026-05-06
issue_number: 2254
state: open
labels: [bug, bug-report, from-app, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "[Bug Report] [QA] U-S03 — EventDetailPage 참가현황 탭 permission denied: PARTY_MANAGE required"
---

# [Bug Report] [QA] U-S03 — EventDetailPage 참가현황 탭 permission denied: PARTY_MANAGE required

> Issue #2254 · open · created 2026-05-05T21:24:43Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2254

## Body

### 🐞 Bug Report

**Description:**
U-S03 이벤트 상세 화면 진입 후 참가현황(participants) 탭 데이터 로드 시 PostgrestException 반복 발생. 일반 VERIFIED 유저가 getEntryGroupParticipantCounts 쿼리 실행 시 PARTY_MANAGE 권한 오류. 앱은 크래시 없이 동작하나 참가인원 데이터 미표시. logcat: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001) x3회 반복.

**Environment:**
- Platform: android
- Timestamp: 2026-05-06T06:24:41.396521

<details>
<summary>📋 Logs</summary>

```log
[E] TIME: 2026-05-06T06:23:46.334537 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
[E] TIME: 2026-05-06T06:23:46.681376 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
[E] TIME: 2026-05-06T06:23:47.214273 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
[E] TIME: 2026-05-06T06:23:48.148473 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
[E] TIME: 2026-05-06T06:23:49.939483 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
[E] TIME: 2026-05-06T06:23:53.226913 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
[E] TIME: 2026-05-06T06:23:59.734741 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
[E] TIME: 2026-05-06T06:24:06.273542 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
[E] TIME: 2026-05-06T06:24:12.889760 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
[E] TIME: 2026-05-06T06:24:19.476292 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
[E] TIME: 2026-05-06T06:24:26.041811 getEntryGroupParticipantCounts Error  ERROR: PostgrestException(message: permission denied: PARTY_MANAGE required, code: P0001, details: Bad Request, hint: null)
```

</details>

## Screenshot
![Screenshot](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/89d44953-4aff-42fa-a4f6-8e6cdd065796.png)

## Environment
| Key | Value |
|-----|-------|
| appVersion | 26.05.2247-dev |
| buildNumber | 26052247 |
| packageName | com.minglit.app_user.dev |
| platform | android |
| osVersion | 12 |
| deviceModel | SM-G970N |
| screenSize | 1080x2136 |
| networkStatus | wifi |
| batteryLevel | 100 |

## Layout Dump
[📐 View Layout Dump](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/e28e4a64-ebed-465d-9780-875de07a9970.txt)
