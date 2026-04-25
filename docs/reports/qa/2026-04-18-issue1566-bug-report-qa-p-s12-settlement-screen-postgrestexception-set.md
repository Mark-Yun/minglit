---
source_url: https://github.com/Mark-Yun/minglit/issues/1566
captured_at: 2026-04-18
issue_number: 1566
state: closed
labels: [bug, bug-report, from-app, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "[Bug Report] [QA] P-S12 — 정산 상세 화면 PostgrestException: settlement_histories.created_at column 없음"
---

# [Bug Report] [QA] P-S12 — 정산 상세 화면 PostgrestException: settlement_histories.created_at column 없음

> Issue #1566 · closed · created 2026-04-18T03:28:38Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1566

## Body


### 🐞 Bug Report

**Description:**
정산 내역 탭에서 정산 항목 탭 시 오류 화면 표시. 에러: PostgrestException(message: column settlement_histories.created_at does not exist, code: 42703, details: Bad Request). PARTNER 상태 유저 /settlement/:id 접근 시 재현. Supabase 마이그레이션에서 settlement_histories 테이블의 created_at 컬럼이 누락된 것으로 추정. Scheduler: runtime-qa-smoke-partner-sonnet-subagents

**Environment:**
- Platform: android
- Timestamp: 2026-04-17T23:28:39.129215

<details>
<summary>📋 Logs</summary>

```log
[D] TIME: 2026-04-17T23:27:36.646814 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-17T23:27:37.217264 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[I] TIME: 2026-04-17T23:27:37.404962 🧭 [Nav] PUSH: /welcome | args: {}
[D] TIME: 2026-04-17T23:27:37.858994 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-17T23:27:37.902565 🧭 [Nav] PUSH: Unknown Route (from /welcome) | args: {}
[I] TIME: 2026-04-17T23:27:37.903029 🧭 [Nav] REMOVE: /welcome | args: {}
[I] TIME: 2026-04-17T23:27:37.969557 🧭 [Nav] PUSH: / | args: {}
[D] TIME: 2026-04-17T23:27:37.976967 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-17T23:27:38.329061 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-17T23:27:38.459869 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-17T23:27:39.502667 🧭 [Nav] PUSH: /settlement | args: {}
[D] TIME: 2026-04-17T23:27:39.717183 getSettlementDashboard called | partnerId: c518ec3d-0988-4b47-9abc-6655763a45bb
[D] TIME: 2026-04-17T23:27:40.076241 getSettlementDashboard success | total: 36
[D] TIME: 2026-04-17T23:28:07.409766 getSettlementItems called | partnerId: c518ec3d-0988-4b47-9abc-6655763a45bb
[D] TIME: 2026-04-17T23:28:07.681804 getSettlementItems success | count: 20
[I] TIME: 2026-04-17T23:28:20.448929 🧭 [Nav] PUSH: Unknown Route (from /settlement)
[D] TIME: 2026-04-17T23:28:20.536781 getSettlementItemDetail called | itemId: 0c544a89-82dd-4e50-9ad4-e52835f81ed9
[E] TIME: 2026-04-17T23:28:20.950685 ❌ [SettlementRepo] getSettlementItemDetail Error  ERROR: PostgrestException(message: column settlement_histories.created_at does not exist, code: 42703, details: Bad Request, hint: null)
[I] TIME: 2026-04-17T23:28:36.386927 QaBugReportChannel: received triggerBugReport title="[QA] P-S12 — 정산 상세 화면 PostgrestException: settlement_histories.created_at column 없음" scenario=null session=null
[D] TIME: 2026-04-17T23:28:38.511637 Uploading bytes to bug-report-attachments/layout-dumps/458e4339-5097-4d7e-b17d-aa82db7d5fe8.txt...
[D] TIME: 2026-04-17T23:28:38.526870 Uploading bytes to bug-report-attachments/screenshots/13c35905-7e02-4eb8-b1c6-40a2bc1f828e.png...
[D] TIME: 2026-04-17T23:28:39.066829 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/13c35905-7e02-4eb8-b1c6-40a2bc1f828e.png
[D] TIME: 2026-04-17T23:28:39.125059 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/458e4339-5097-4d7e-b17d-aa82db7d5fe8.txt
```

</details>


## Screenshot
![Screenshot](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/13c35905-7e02-4eb8-b1c6-40a2bc1f828e.png)


## Environment
| Key | Value |
|-----|-------|
| appVersion | 26.04.1532-dev |
| buildNumber | 26041532 |
| packageName | com.minglit.app_partner.dev |
| platform | android |
| osVersion | 15 |
| deviceModel | Pixel 7a |
| screenSize | 1080x2400 |
| networkStatus | wifi |
| batteryLevel | 76 |


## Layout Dump
[📐 View Layout Dump](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/458e4339-5097-4d7e-b17d-aa82db7d5fe8.txt)


## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-18

🤖 **needs-swe-sonnet-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-18

🤖 **needs-swe-sonnet-1** 수정 완료 — PR #1569 생성 및 auto-merge 활성화

**Root cause**: settlement_histories 테이블에 created_at 컬럼 없음. event_at이 올바른 컬럼명.

수정 파일:
- settlement_repository.dart — select/order event_at 사용
- settlement_item_detail.dart — fromJson/toJson event_at 사용  
- Tests — 기존 테스트 업데이트 + regression test 추가
