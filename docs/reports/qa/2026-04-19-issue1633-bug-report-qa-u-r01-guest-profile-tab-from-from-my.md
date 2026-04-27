---
source_url: https://github.com/Mark-Yun/minglit/issues/1633
captured_at: 2026-04-19
issue_number: 1633
state: closed
labels: [bug-report, P2-medium, from-app, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "[Bug Report] [QA] U-R01 — GUEST 프로필 탭 시 from=/ 전달 (기대: from=/my)"
---

# [Bug Report] [QA] U-R01 — GUEST 프로필 탭 시 from=/ 전달 (기대: from=/my)

> Issue #1633 · closed · created 2026-04-19T21:56:59Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1633

## Body


### 🐞 Bug Report

**Description:**
증상: GUEST 상태에서 AppBar 프로필 아이콘 탭 시 /login 으로 리다이렉트되나 from 파라미터가 /my가 아닌 /로 전달됨. Nav 로그: PUSH: /login (from /) | args: {from: /}. 이후 로그인 성공 시 MyPage가 아닌 홈으로 이동. 기대 동작: from=/my로 전달되어 로그인 후 MyPage로 복귀. 발견: runtime-qa-smoke-user-sonnet-subagents 세션 20260420-060101.

**Environment:**
- Platform: android
- Timestamp: 2026-04-19T17:56:58.036629

<details>
<summary>📋 Logs</summary>

```log
[I] TIME: 2026-04-19T17:54:50.691236 🧭 [Nav] PUSH: / | args: {}
[D] TIME: 2026-04-19T17:54:50.751650 getEventsByType called | type: EventFeedType.newArrivals
[D] TIME: 2026-04-19T17:54:50.761895 getTodayActiveEventsForUser called | userId: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[D] TIME: 2026-04-19T17:54:51.548411 getBulkEligibilityData called | userId: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[D] TIME: 2026-04-19T17:54:51.795468 getBulkEligibilityData success
[D] TIME: 2026-04-19T17:54:51.797408 Eligibility data arrived, refiltering 0 events
[D] TIME: 2026-04-19T17:54:51.858682 getTodayActiveEventsForUser success | count: 0
[D] TIME: 2026-04-19T17:54:51.957169 getEventsByType success | count: 4
[D] TIME: 2026-04-19T17:54:52.058197 [LocationService] Using last known position
[I] TIME: 2026-04-19T17:55:09.415238 🧭 [Nav] PUSH: Unknown Route (from /) | args: {}
[I] TIME: 2026-04-19T17:55:09.415708 🧭 [Nav] REMOVE: / | args: {}
[I] TIME: 2026-04-19T17:56:26.871427 🧭 [Nav] PUSH: / | args: {}
[I] TIME: 2026-04-19T17:56:26.871702 🧭 [Nav] REMOVE: Unknown Route | args: {}
[D] TIME: 2026-04-19T17:56:26.876443 getBulkEligibilityData called | userId: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[D] TIME: 2026-04-19T17:56:26.877129 getEventsByType called | type: EventFeedType.newArrivals
[D] TIME: 2026-04-19T17:56:26.881217 getTodayActiveEventsForUser called | userId: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[D] TIME: 2026-04-19T17:56:29.792401 getBulkEligibilityData success
[D] TIME: 2026-04-19T17:56:29.793805 Eligibility data arrived, refiltering 0 events
[D] TIME: 2026-04-19T17:56:29.814924 getTodayActiveEventsForUser success | count: 0
[D] TIME: 2026-04-19T17:56:30.004262 getEventsByType success | count: 4
[D] TIME: 2026-04-19T17:56:30.049953 [LocationService] Using last known position
[I] TIME: 2026-04-19T17:56:56.340154 QaBugReportChannel: received triggerBugReport title="[QA] U-R01 — GUEST 프로필 탭 시 from=/ 전달 (기대: from=/my)" scenario=null session=null
[D] TIME: 2026-04-19T17:56:57.265052 Uploading bytes to bug-report-attachments/layout-dumps/679c54da-0824-444d-9449-fe6bc7548822.txt...
[D] TIME: 2026-04-19T17:56:57.291438 Uploading bytes to bug-report-attachments/screenshots/8c5d0205-f668-4282-8bc6-17bec49ed06b.png...
[D] TIME: 2026-04-19T17:56:58.024930 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/679c54da-0824-444d-9449-fe6bc7548822.txt
[D] TIME: 2026-04-19T17:56:58.030955 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/8c5d0205-f668-4282-8bc6-17bec49ed06b.png
```

</details>


## Screenshot
![Screenshot](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/8c5d0205-f668-4282-8bc6-17bec49ed06b.png)


## Environment
| Key | Value |
|-----|-------|
| appVersion | 26.04.1545-dev |
| buildNumber | 26041545 |
| packageName | com.minglit.app_user.dev |
| platform | android |
| osVersion | 15 |
| deviceModel | Pixel 7a |
| screenSize | 1080x2400 |
| networkStatus | wifi |
| batteryLevel | 72 |


## Layout Dump
[📐 View Layout Dump](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/679c54da-0824-444d-9449-fe6bc7548822.txt)


## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-19

🤖 **needs-swe-sonnet-1** 작업 시작합니다. GUEST 프로필 탭 from=/ 버그 + user app isDevEnv('dev' 미인식) 동시 수정 예정.
