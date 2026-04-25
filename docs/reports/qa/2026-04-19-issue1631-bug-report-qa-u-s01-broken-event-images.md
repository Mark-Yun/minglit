---
source_url: https://github.com/Mark-Yun/minglit/issues/1631
captured_at: 2026-04-19
issue_number: 1631
state: closed
labels: [bug-report, P2-medium, from-app, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "[Bug Report] [QA] U-S01 — Broken Event Images"
---

# [Bug Report] [QA] U-S01 — Broken Event Images

> Issue #1631 · closed · created 2026-04-19T21:20:27Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1631

## Body


### 🐞 Bug Report

**Description:**
Event cards on the Home screen and Event Detail screen show broken image placeholders (camera with a slash). Image loading or storage path issue.

**Environment:**
- Platform: android
- Timestamp: 2026-04-19T17:20:28.695339

<details>
<summary>📋 Logs</summary>

```log
[I] TIME: 2026-04-19T17:18:30.075649 🧭 [Nav] PUSH: / | args: {}
[D] TIME: 2026-04-19T17:18:30.136088 getEventsByType called | type: EventFeedType.newArrivals
[D] TIME: 2026-04-19T17:18:30.144 getTodayActiveEventsForUser called | userId: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[D] TIME: 2026-04-19T17:18:30.908236 getBulkEligibilityData called | userId: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
[D] TIME: 2026-04-19T17:18:31.082252 getBulkEligibilityData success
[D] TIME: 2026-04-19T17:18:31.083853 Eligibility data arrived, refiltering 0 events
[D] TIME: 2026-04-19T17:18:31.340537 getTodayActiveEventsForUser success | count: 0
[D] TIME: 2026-04-19T17:18:31.455238 getEventsByType success | count: 4
[D] TIME: 2026-04-19T17:18:31.552671 [LocationService] Using last known position
[I] TIME: 2026-04-19T17:18:32.810269 🧭 [Nav] PUSH: /my (from /) | args: {}
[I] TIME: 2026-04-19T17:18:47.255267 🧭 [Nav] POP: /my (from /) | args: {}
[I] TIME: 2026-04-19T17:19:21.779276 🧭 [Nav] PUSH: /tags/:tagId (from /) | args: {tagId: d69826ef-d9ed-407a-9555-65bfa0eaf3f3, tag-name: 공연}
[I] TIME: 2026-04-19T17:19:32.907171 🧭 [Nav] POP: /tags/:tagId (from /) | args: {tagId: d69826ef-d9ed-407a-9555-65bfa0eaf3f3, tag-name: 공연}
[I] TIME: 2026-04-19T17:19:36.613063 🧭 [Nav] PUSH: /tags/:tagId (from /) | args: {tagId: d69826ef-d9ed-407a-9555-65bfa0eaf3f3, tag-name: 공연}
[I] TIME: 2026-04-19T17:19:51.145613 🧭 [Nav] POP: /tags/:tagId (from /) | args: {tagId: d69826ef-d9ed-407a-9555-65bfa0eaf3f3, tag-name: 공연}
[I] TIME: 2026-04-19T17:19:55.026522 🧭 [Nav] PUSH: /search (from /) | args: {}
[I] TIME: 2026-04-19T17:20:25.953716 QaBugReportChannel: received triggerBugReport title="[QA] U-S02, U-S09, U-S12 — Navigation Major Regression" scenario=null session=null
[D] TIME: 2026-04-19T17:20:27.174562 Uploading bytes to bug-report-attachments/layout-dumps/aea7d74c-6d7d-4183-a2c7-cd2481852511.txt...
[D] TIME: 2026-04-19T17:20:27.214590 Uploading bytes to bug-report-attachments/screenshots/fd7bb7c5-1046-49fa-8122-adcd9b045747.png...
[I] TIME: 2026-04-19T17:20:27.353294 QaBugReportChannel: received triggerBugReport title="[QA] U-S01 — Broken Event Images" scenario=null session=null
[D] TIME: 2026-04-19T17:20:27.915156 Uploading bytes to bug-report-attachments/layout-dumps/3c809bae-2293-41d3-aaba-883e0278cc08.txt...
[D] TIME: 2026-04-19T17:20:27.937438 Uploading bytes to bug-report-attachments/screenshots/466ce7b6-52aa-4060-b59a-036b77bd8b57.png...
[D] TIME: 2026-04-19T17:20:27.947520 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/fd7bb7c5-1046-49fa-8122-adcd9b045747.png
[D] TIME: 2026-04-19T17:20:27.960232 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/aea7d74c-6d7d-4183-a2c7-cd2481852511.txt
[I] TIME: 2026-04-19T17:20:28.032255 QaBugReportChannel: received triggerBugReport title="[QA] U-S01 — No events for logged-in user" scenario=null session=null
[D] TIME: 2026-04-19T17:20:28.457606 Uploading bytes to bug-report-attachments/layout-dumps/14f8ea0f-2a6f-430c-aff0-cfbb374449bf.txt...
[D] TIME: 2026-04-19T17:20:28.473196 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/466ce7b6-52aa-4060-b59a-036b77bd8b57.png
[D] TIME: 2026-04-19T17:20:28.496768 Uploading bytes to bug-report-attachments/screenshots/f63ca5b5-e128-492d-8700-c3475ade9175.png...
[D] TIME: 2026-04-19T17:20:28.694473 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/3c809bae-2293-41d3-aaba-883e0278cc08.txt
```

</details>


## Screenshot
![Screenshot](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/466ce7b6-52aa-4060-b59a-036b77bd8b57.png)


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
[📐 View Layout Dump](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/3c809bae-2293-41d3-aaba-883e0278cc08.txt)

