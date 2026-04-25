---
source_url: https://github.com/Mark-Yun/minglit/issues/1832
captured_at: 2026-04-24
issue_number: 1832
state: closed
labels: [bug-report, from-app, report-runtime-qa]
author: Mark-Yun
title: "[Bug Report] [QA] CUJ-P03 — QR 스캐너 내 요약 카드 및 엔트리 그룹 통계 누락"
---

# [Bug Report] [QA] CUJ-P03 — QR 스캐너 내 요약 카드 및 엔트리 그룹 통계 누락

> Issue #1832 · closed · created 2026-04-24T12:13:05Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1832

## Body


### 🐞 Bug Report

**Description:**
체크인 QR 스캐너 진입 시 요약 카드(N/M)와 엔트리 그룹별 통계가 노출되지 않음 (#1779 기능). 또한 수동 체크인 버튼도 보이지 않아 QR 인식 실패 시 대응 불가능함.

**Environment:**
- Platform: android
- Timestamp: 2026-04-24T08:13:06.071920

<details>
<summary>📋 Logs</summary>

```log
[D] TIME: 2026-04-24T08:10:55.843707 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-24T08:10:55.860722 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[I] TIME: 2026-04-24T08:10:56.566840 🧭 [Nav] PUSH: /welcome | args: {}
[D] TIME: 2026-04-24T08:10:57.102815 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-24T08:10:57.112434 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-24T08:10:57.337934 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-24T08:10:57.385856 🧭 [Nav] PUSH: Unknown Route (from /welcome) | args: {}
[I] TIME: 2026-04-24T08:10:57.386732 🧭 [Nav] REMOVE: /welcome | args: {}
[I] TIME: 2026-04-24T08:10:57.440518 🧭 [Nav] PUSH: / | args: {}
[D] TIME: 2026-04-24T08:10:57.940519 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-24T08:11:14.442766 🧭 [Nav] PUSH: /checkin | args: {}
[I] TIME: 2026-04-24T08:11:26.324815 🧭 [Nav] PUSH: Unknown Route (from /checkin)
[I] TIME: 2026-04-24T08:13:02.673829 QaBugReportChannel: received triggerBugReport title="[QA] CUJ-P03 — QR 스캐너 내 요약 카드 및 엔트리 그룹 통계 누락" scenario=null session=null
[D] TIME: 2026-04-24T08:13:05.226561 Uploading bytes to bug-report-attachments/layout-dumps/5d384f2d-b41c-411a-a6a9-ba517ddfb0c2.txt...
[D] TIME: 2026-04-24T08:13:05.523641 Uploading bytes to bug-report-attachments/screenshots/86878742-279e-4783-916b-96aadef12a87.png...
[D] TIME: 2026-04-24T08:13:06.020599 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/86878742-279e-4783-916b-96aadef12a87.png
[D] TIME: 2026-04-24T08:13:06.068570 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/5d384f2d-b41c-411a-a6a9-ba517ddfb0c2.txt
```

</details>


## Screenshot
![Screenshot](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/86878742-279e-4783-916b-96aadef12a87.png)


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


## Layout Dump
[📐 View Layout Dump](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/5d384f2d-b41c-411a-a6a9-ba517ddfb0c2.txt)


## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-24

🤖 **needs-swe-sonnet-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-24

🤖 **needs-swe-sonnet-1** 분석 완료

**Root Cause: PR #1817 미머지**

현재 dev 빌드(`v26.04.1827-dev`)는 QR 체크인 Phase 1-3 기능이 없습니다.

- 요약 카드(`CheckinSummaryCard`), 엔트리 그룹 통계, 수동 체크인 버튼은 PR #1817에서 구현됨
- PR #1817은 현재 리뷰 중 (`needs-review`) — 머지되면 기능이 dev에 반영됩니다
- 현재 `/checkin` → Unknown Route는 QR 스캐너 화면으로 진입 시 신규 라우트(`/checkin/scan`)가 없어서 발생하는 현상일 수 있음

**Action**: PR #1817이 머지되면 QA 재테스트 필요. 이 이슈는 버그가 아니라 미배포 기능 리포트입니다.

`needs-swe` 라벨 제거하고 이슈를 클로즈합니다. PR #1817 머지 후 QA에서 재확인해주세요.
