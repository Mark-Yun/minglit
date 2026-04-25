---
source_url: https://github.com/Mark-Yun/minglit/issues/1836
captured_at: 2026-04-24
issue_number: 1836
state: closed
labels: [bug, bug-report, P2-medium, from-app, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "[Bug Report] [QA] CUJ-P01 — 파티 생성 위저드 Step 3 다음 진행 불확실 (확인 필요)"
---

# [Bug Report] [QA] CUJ-P01 — 파티 생성 위저드 Step 3 다음 진행 불확실 (확인 필요)

> Issue #1836 · closed · created 2026-04-24T12:32:31Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1836

## Body


### 🐞 Bug Report

**Description:**
파티 생성 위저드 3단계(인원 및 연락처)에서 연락처 미선택 상태 다음 버튼 탭 후 파티 목록으로 이동되는 현상 관찰됨. 의도적 네비게이션(이전 탭)인지 앱 버그인지 불확실. 재현 조건: Step 1(제목 입력) → Step 2(장소 선택) → Step 3(최소 인원 5, 연락처 미선택) → 다음 탭. 연락처 최소 1개 선택 필수 메시지가 표시되는 상태에서 다음 버튼 탭 시 파티 목록으로 이동됨. 수동 확인 권장.

**Environment:**
- Platform: android
- Timestamp: 2026-04-24T08:32:32.867540

<details>
<summary>📋 Logs</summary>

```log
[D] TIME: 2026-04-24T08:18:42.444441 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-24T08:18:42.468851 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-24T08:18:42.957362 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-24T08:18:43.059239 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-24T08:18:43.071513 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-24T08:18:43.238885 🧭 [Nav] PUSH: Unknown Route | args: {}
[I] TIME: 2026-04-24T08:18:43.343791 🧭 [Nav] PUSH: / | args: {}
[D] TIME: 2026-04-24T08:18:43.821120 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-24T08:18:45.004614 🧭 [Nav] PUSH: /checkin | args: {}
[I] TIME: 2026-04-24T08:18:47.264444 🧭 [Nav] PUSH: Unknown Route (from /checkin)
[I] TIME: 2026-04-24T08:19:11.386399 QaBugReportChannel: received triggerBugReport title="[QA] CUJ-P03 — QR 스캐너 요약 카드(진행률 N/M) 미표시" scenario=null session=null
[D] TIME: 2026-04-24T08:19:13.646083 Uploading bytes to bug-report-attachments/layout-dumps/4f407718-81d5-41e6-a498-230f9d2507d6.txt...
[D] TIME: 2026-04-24T08:19:13.826327 Uploading bytes to bug-report-attachments/screenshots/8368599f-3bfc-456b-ab85-e5ceb0e14933.png...
[D] TIME: 2026-04-24T08:19:14.553278 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/4f407718-81d5-41e6-a498-230f9d2507d6.txt
[D] TIME: 2026-04-24T08:19:14.559147 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/8368599f-3bfc-456b-ab85-e5ceb0e14933.png
[I] TIME: 2026-04-24T08:19:17.391394 Bug reported successfully via Edge Function
[I] TIME: 2026-04-24T08:19:17.393034 QaBugReportChannel: report submitted successfully
[I] TIME: 2026-04-24T08:19:25.724809 🧭 [Nav] POP: Unknown Route (from /checkin)
[I] TIME: 2026-04-24T08:19:28.176029 🧭 [Nav] PUSH: /settlement | args: {}
[D] TIME: 2026-04-24T08:19:28.659843 getSettlementDashboard called | partnerId: c518ec3d-0988-4b47-9abc-6655763a45bb
[D] TIME: 2026-04-24T08:19:29.161431 getSettlementDashboard success | total: 37
[I] TIME: 2026-04-24T08:19:48.253828 🧭 [Nav] PUSH: bank-account (from /settlement) | args: {}
[D] TIME: 2026-04-24T08:19:48.336116 getBankAccount called | partnerId: c518ec3d-0988-4b47-9abc-6655763a45bb
[D] TIME: 2026-04-24T08:19:48.505916 getBankAccount | not found: c518ec3d-0988-4b47-9abc-6655763a45bb
[I] TIME: 2026-04-24T08:20:01.902931 🧭 [Nav] POP: bank-account (from /settlement) | args: {}
[I] TIME: 2026-04-24T08:20:03.254311 🧭 [Nav] PUSH: /more | args: {}
[I] TIME: 2026-04-24T08:20:04.483987 🧭 [Nav] PUSH: verifications/manage (from /more) | args: {}
[D] TIME: 2026-04-24T08:20:04.565212 getPartnerVerifications called | partnerId: c518ec3d-0988-4b47-9abc-6655763a45bb, isActive: true
[D] TIME: 2026-04-24T08:20:04.568852 getPartnerVerifications called | partnerId: c518ec3d-0988-4b47-9abc-6655763a45bb, isActive: false
[D] TIME: 2026-04-24T08:20:04.790115 getPartnerVerifications success | count: 0
[D] TIME: 2026-04-24T08:20:04.794432 getPartnerVerifications success | count: 0
[I] TIME: 2026-04-24T08:20:15.095606 🧭 [Nav] POP: verifications/manage (from /more) | args: {}
[I] TIME: 2026-04-24T08:20:21.162896 🧭 [Nav] PUSH: parties (from /more) | args: {}
[D] TIME: 2026-04-24T08:20:21.171663 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-24T08:20:21.413290 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-24T08:20:21.576211 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-24T08:20:32.614860 🧭 [Nav] PUSH: Unknown Route (from parties)
[I] TIME: 2026-04-24T08:20:35.631483 🧭 [Nav] PUSH: parties | args: {eventId: 28367699-1814-41b1-96a8-821d2a8e3b1f, partyId: 7b32b554-4e76-4066-8390-69e665b66316}
[I] TIME: 2026-04-24T08:20:35.631758 🧭 [Nav] PUSH: Unknown Route (from parties)
[I] TIME: 2026-04-24T08:20:35.631868 🧭 [Nav] PUSH: Unknown Route
[I] TIME: 2026-04-24T08:20:35.632414 🧭 [Nav] REMOVE: Unknown Route (from /more)
[I] TIME: 2026-04-24T08:20:35.632569 🧭 [Nav] REMOVE: parties (from /more) | args: {}
[D] TIME: 2026-04-24T08:20:35.641798 getEventById called | id: 28367699-1814-41b1-96a8-821d2a8e3b1f
[D] TIME: 2026-04-24T08:20:35.649903 getTicketsByEventId called | eventId: 28367699-1814-41b1-96a8-821d2a8e3b1f
[D] TIME: 2026-04-24T08:20:35.781783 getTicketsByEventId success | count: 1
[D] TIME: 2026-04-24T08:20:35.827884 getEventById success | title: null
[D] TIME: 2026-04-24T08:20:35.850212 getApplicationsByEventId called | id: 28367699-1814-41b1-96a8-821d2a8e3b1f
[I] TIME: 2026-04-24T08:20:57.521013 🧭 [Nav] PUSH: tickets/:ticketId/edit | args: {ticketId: 67841485-20e4-4973-b778-ba31a9f1ea2a, eventId: 28367699-1814-41b1-96a8-821d2a8e3b1f, partyId: 7b32b554-4e76-4066-8390-69e665b66316}
[D] TIME: 2026-04-24T08:20:57.565217 getTicketById called | id: 67841485-20e4-4973-b778-ba31a9f1ea2a
[D] TIME: 2026-04-24T08:20:57.859054 getTicketById success | id: 67841485-20e4-4973-b778-ba31a9f1ea2a
[I] TIME: 2026-04-24T08:21:21.603062 🧭 [Nav] POP: tickets/:ticketId/edit | args: {ticketId: 67841485-20e4-4973-b778-ba31a9f1ea2a, eventId: 28367699-1814-41b1-96a8-821d2a8e3b1f, partyId: 7b32b554-4e76-4066-8390-69e665b66316}
[I] TIME: 2026-04-24T08:21:22.908117 🧭 [Nav] POP: Unknown Route
[D] TIME: 2026-04-24T08:21:37.437078 getLocationById called | id: 17c6d0df-a75f-4734-b1ac-759a79aa2881
[D] TIME: 2026-04-24T08:21:37.751627 getLocationById success | name: 서울 강남
[I] TIME: 2026-04-24T08:21:53.462507 🧭 [Nav] PUSH: Unknown Route
[I] TIME: 2026-04-24T08:21:54.467482 🧭 [Nav] POP: Unknown Route
[I] TIME: 2026-04-24T08:22:42.587725 🧭 [Nav] POP: Unknown Route (from parties)
[I] TIME: 2026-04-24T08:22:43.804301 🧭 [Nav] POP: parties (from /more) | args: {}
[D] TIME: 2026-04-24T08:23:31.694343 getSettlementItems called | partnerId: c518ec3d-0988-4b47-9abc-6655763a45bb
[D] TIME: 2026-04-24T08:23:32.233265 getSettlementItems success | count: 20
[I] TIME: 2026-04-24T08:23:47.148794 🧭 [Nav] PUSH: parties (from /more) | args: {}
[D] TIME: 2026-04-24T08:23:47.154826 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-24T08:23:47.451112 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-24T08:23:47.854757 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-24T08:23:57.307544 🧭 [Nav] PUSH: create (from parties) | args: {}
[I] TIME: 2026-04-24T08:24:24.891735 QaBugReportChannel: received triggerBugReport title="[QA] CUJ-P04 — 정산 탭 내 계좌 관리 버튼이 파티 생성으로 오동작" scenario=null session=null
[D] TIME: 2026-04-24T08:24:30.086870 Uploading bytes to bug-report-attachments/layout-dumps/7359e917-8ad5-4d1c-9213-8af807c71a28.txt...
[D] TIME: 2026-04-24T08:24:30.132909 Uploading bytes to bug-report-attachments/screenshots/23ef2ebb-f645-4850-9ffb-77e298556bbd.png...
[D] TIME: 2026-04-24T08:24:30.736883 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/23ef2ebb-f645-4850-9ffb-77e298556bbd.png
[E] TIME: 2026-04-24T08:24:31.261168 ❌ [StorageRepo] uploadBytes failed  ERROR: StorageException(message: The object exceeded the maximum allowed size, statusCode: 413, error: Payload too large)
[E] TIME: 2026-04-24T08:24:31.261843 Layout dump upload failed (best-effort)  ERROR: StorageException(message: The object exceeded the maximum allowed size, statusCode: 413, error: Payload too large)
[I] TIME: 2026-04-24T08:24:34.430686 Bug reported successfully via Edge Function
[I] TIME: 2026-04-24T08:24:34.430934 QaBugReportChannel: report submitted successfully
[I] TIME: 2026-04-24T08:24:50.555933 🧭 [Nav] POP: create (from parties) | args: {}
[I] TIME: 2026-04-24T08:24:51.642446 🧭 [Nav] POP: parties (from /more) | args: {}
[I] TIME: 2026-04-24T08:24:53.136666 🧭 [Nav] PUSH: bank-account (from /more) | args: {}
[D] TIME: 2026-04-24T08:24:53.189320 getBankAccount called | partnerId: c518ec3d-0988-4b47-9abc-6655763a45bb
[D] TIME: 2026-04-24T08:24:53.481934 getBankAccount | not found: c518ec3d-0988-4b47-9abc-6655763a45bb
[I] TIME: 2026-04-24T08:25:13.546645 🧭 [Nav] POP: bank-account (from /more) | args: {}
[I] TIME: 2026-04-24T08:25:27.997425 🧭 [Nav] PUSH: parties (from /more) | args: {}
[D] TIME: 2026-04-24T08:25:28.007754 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-24T08:25:28.362554 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-24T08:25:28.664024 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-24T08:25:41.283079 🧭 [Nav] PUSH: create (from parties) | args: {}
[I] TIME: 2026-04-24T08:26:12.319370 🧭 [Nav] POP: create (from parties) | args: {}
[I] TIME: 2026-04-24T08:26:33.601139 🧭 [Nav] POP: parties (from /more) | args: {}
[I] TIME: 2026-04-24T08:26:36.502905 🧭 [Nav] PUSH: parties (from /more) | args: {}
[D] TIME: 2026-04-24T08:26:36.508625 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-24T08:26:38.373049 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-24T08:26:38.592955 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-24T08:26:41.326567 🧭 [Nav] PUSH: create (from parties) | args: {}
[I] TIME: 2026-04-24T08:27:11.959509 🧭 [Nav] PUSH: Unknown Route (from create)
[I] TIME: 2026-04-24T08:27:39.921368 🧭 [Nav] POP: Unknown Route (from create)
[I] TIME: 2026-04-24T08:27:50.946502 🧭 [Nav] POP: create (from parties) | args: {}
[I] TIME: 2026-04-24T08:27:52.357604 🧭 [Nav] POP: parties (from /more) | args: {}
[I] TIME: 2026-04-24T08:27:54.952667 🧭 [Nav] PUSH: Unknown Route (from /settlement)
[D] TIME: 2026-04-24T08:27:54.981993 getSettlementItemDetail called | itemId: 5507dce6-366d-46bb-a870-24e7c3e8223e
[D] TIME: 2026-04-24T08:27:55.955595 getSettlementItemDetail success | id: 5507dce6-366d-46bb-a870-24e7c3e8223e
[I] TIME: 2026-04-24T08:28:09.291379 🧭 [Nav] POP: Unknown Route (from /settlement)
[I] TIME: 2026-04-24T08:28:25.125266 🧭 [Nav] PUSH: parties (from /more) | args: {}
[D] TIME: 2026-04-24T08:28:25.129396 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-24T08:28:25.353041 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-24T08:28:25.590568 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-24T08:28:27.466588 🧭 [Nav] PUSH: create (from parties) | args: {}
[I] TIME: 2026-04-24T08:28:51.325155 🧭 [Nav] PUSH: Unknown Route (from create)
[I] TIME: 2026-04-24T08:28:56.049307 🧭 [Nav] POP: Unknown Route (from create)
[I] TIME: 2026-04-24T08:29:20.202957 🧭 [Nav] POP: create (from parties) | args: {}
[I] TIME: 2026-04-24T08:29:24.333290 🧭 [Nav] PUSH: Unknown Route (from parties)
[I] TIME: 2026-04-24T08:29:37.164519 🧭 [Nav] POP: Unknown Route (from parties)
[I] TIME: 2026-04-24T08:29:50.012049 🧭 [Nav] PUSH: create (from parties) | args: {}
[I] TIME: 2026-04-24T08:30:00.718767 🧭 [Nav] PUSH: Unknown Route (from create)
[I] TIME: 2026-04-24T08:30:05.485546 🧭 [Nav] POP: Unknown Route (from create)
[I] TIME: 2026-04-24T08:30:14.086126 🧭 [Nav] POP: create (from parties) | args: {}
[I] TIME: 2026-04-24T08:30:15.506582 🧭 [Nav] PUSH: Unknown Route (from parties)
[I] TIME: 2026-04-24T08:30:32.263931 🧭 [Nav] POP: Unknown Route (from parties)
[I] TIME: 2026-04-24T08:30:58.497216 QaBugReportChannel: received triggerBugReport title="[QA] CUJ-Partner — 앱 전반의 네비게이션 및 입력 처리 불안정 (Ghost Navigation)" scenario=null session=null
[D] TIME: 2026-04-24T08:31:01.634393 Uploading bytes to bug-report-attachments/layout-dumps/f06fe84f-c942-4963-ba76-0f64b22ad2aa.txt...
[D] TIME: 2026-04-24T08:31:01.668810 Uploading bytes to bug-report-attachments/screenshots/01629a5c-ea9e-4a35-94a2-5ab1a65cd588.png...
[D] TIME: 2026-04-24T08:31:02.462913 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/01629a5c-ea9e-4a35-94a2-5ab1a65cd588.png
[E] TIME: 2026-04-24T08:31:02.540161 ❌ [StorageRepo] uploadBytes failed  ERROR: StorageException(message: The object exceeded the maximum allowed size, statusCode: 413, error: Payload too large)
[E] TIME: 2026-04-24T08:31:02.541320 Layout dump upload failed (best-effort)  ERROR: StorageException(message: The object exceeded the maximum allowed size, statusCode: 413, error: Payload too large)
[I] TIME: 2026-04-24T08:31:05.788448 Bug reported successfully via Edge Function
[I] TIME: 2026-04-24T08:31:05.789928 QaBugReportChannel: report submitted successfully
[I] TIME: 2026-04-24T08:32:28.500890 QaBugReportChannel: received triggerBugReport title="[QA] CUJ-P01 — 파티 생성 위저드 Step 3 다음 진행 불확실 (확인 필요)" scenario=null session=null
[D] TIME: 2026-04-24T08:32:31.563795 Uploading bytes to bug-report-attachments/layout-dumps/eb602759-1a4c-4c06-8fdb-56733edb03da.txt...
[D] TIME: 2026-04-24T08:32:31.638371 Uploading bytes to bug-report-attachments/screenshots/984404d6-86d2-4207-87ac-c99644a7bc03.png...
[D] TIME: 2026-04-24T08:32:32.629453 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/984404d6-86d2-4207-87ac-c99644a7bc03.png
[E] TIME: 2026-04-24T08:32:32.866616 ❌ [StorageRepo] uploadBytes failed  ERROR: StorageException(message: The object exceeded the maximum allowed size, statusCode: 413, error: Payload too large)
[E] TIME: 2026-04-24T08:32:32.867250 Layout dump upload failed (best-effort)  ERROR: StorageException(message: The object exceeded the maximum allowed size, statusCode: 413, error: Payload too large)
```

</details>


## Screenshot
![Screenshot](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/984404d6-86d2-4207-87ac-c99644a7bc03.png)


## Environment
| Key | Value |
|-----|-------|
| appVersion | 26.04.1827-dev |
| buildNumber | 26041827 |
| packageName | com.minglit.app_partner.dev |
| platform | android |
| osVersion | 15 |
| deviceModel | Pixel 7a |
| screenSize | 1080x2400 |
| networkStatus | wifi |
| batteryLevel | 72 |


## Comments (5)

### Comment 1 — @Mark-Yun on 2026-04-25

🤖 **tpm-exec-report-claude-subagents** 트리아지

**우선순위**: P2-medium (CUJ-P01 모호한 거동 — "확인 필요" 명시)
**라우팅**: needs-runtime-qa (재현/확인)

@runtime-qa
scenarios: P-CUJ-01
reason: Step 1→2→3 진행 후 연락처 미선택 상태에서 "다음" 탭 → 파티 목록으로 이동되는지 재현. 의도된 "이전 탭" 거동인지 실제 버그인지 판단. validation 메시지 노출 + 동시에 navigation pop 발생하면 명백한 버그 → needs-swe + P1로 승격.

**연관**: #1834, #1835 (Ghost Navigation 패턴군과 같은 라우팅 결함일 수 있음).

### Comment 2 — @Mark-Yun on 2026-04-25

🤖 **needs-runtime-qa-gemini-1** 작업 시작합니다.

### Comment 3 — @Mark-Yun on 2026-04-25

### 🧪 Runtime QA 결과 리포트

**검증 결과:** ❌ FAIL

**발견 사항:**
1. **연락처 필수 검증 우회:** Step 3(인원 및 연락처)에서 연락처를 하나도 선택하지 않아 '최소 한 개의 연락처를 선택해야 합니다.'라는 경고 문구가 표시되는 상태에서도 '다음' 버튼을 누르면 검증 없이 Step 4로 진입합니다.
2. **Double Tap Race Condition:** '다음' 버튼을 빠르게 연속으로 탭할 경우, 다음 단계(Step 4)를 건너뛰고 Step 5(티켓 설정)로 바로 진입하는 현상이 관찰되었습니다. 버튼의 Debounce 처리가 필요해 보입니다.

**재현 경로:**
1. 파티 생성 위저드 진입
2. Step 1 제목 입력 -> 다음
3. Step 2 장소 선택 -> 다음
4. Step 3 연락처 미선택 상태에서 '다음' 버튼 탭 -> Step 4 진입됨 (Bug)

**참고:** 제보된 '파티 목록으로 이동' 현상은 재현되지 않았으나, 검증 로직이 동작하지 않는 근본적인 문제가 확인되었습니다.

**증거 자료:** 
- [QA_BUG_REPORT]를 통해 상세 로그 및 스크린샷이 에지 펑션으로 전송되었습니다.
- 세션 스크린샷:  (Step 4 진입 확인),  (Step 5 진입 확인)

### Comment 4 — @Mark-Yun on 2026-04-25

🤖 **needs-swe-sonnet-1** 작업 시작합니다.

### Comment 5 — @Mark-Yun on 2026-04-25

🤖 **needs-swe-sonnet-1** 구현 완료. PR #1843 생성했습니다.
