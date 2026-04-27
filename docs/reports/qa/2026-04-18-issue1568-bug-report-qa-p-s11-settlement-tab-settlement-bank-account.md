---
source_url: https://github.com/Mark-Yun/minglit/issues/1568
captured_at: 2026-04-18
issue_number: 1568
state: closed
labels: [bug, bug-report, P1-high, from-app, report-runtime-qa]
author: Mark-Yun
title: "[Bug Report] [QA] P-S11 — 정산 탭에서 계좌 관리(/settlement/bank-account) 진입 경로를 찾을 수 없음"
---

# [Bug Report] [QA] P-S11 — 정산 탭에서 계좌 관리(/settlement/bank-account) 진입 경로를 찾을 수 없음

> Issue #1568 · closed · created 2026-04-18T03:47:45Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1568

## Body


### 🐞 Bug Report

**Description:**
테스트 케이스 P-S11에서 정산 탭(SettlementPage)의 계좌 관리 버튼을 찾을 수 없음. 헤더 버튼 2개는 모두 월 네비게이션(이전달/다음달)으로 확인됨. 스크롤해도 계좌 관리 버튼 없음. /settlement/bank-account(BankAccountPage)로 이동하는 진입 경로가 UI에서 발견되지 않음. 의도적으로 제거된 것인지 다른 경로가 있는지 확인 필요. Scheduler: runtime-qa-smoke-partner-sonnet-subagents

**Environment:**
- Platform: android
- Timestamp: 2026-04-17T23:47:45.560191

<details>
<summary>📋 Logs</summary>

```log
[D] TIME: 2026-04-17T23:38:01.488157 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[I] TIME: 2026-04-17T23:38:02.207265 🧭 [Nav] PUSH: /welcome | args: {}
[D] TIME: 2026-04-17T23:38:02.736107 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-17T23:38:02.985117 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-17T23:38:03.059820 🧭 [Nav] PUSH: Unknown Route (from /welcome) | args: {}
[I] TIME: 2026-04-17T23:38:03.060602 🧭 [Nav] REMOVE: /welcome | args: {}
[I] TIME: 2026-04-17T23:38:03.132151 🧭 [Nav] PUSH: / | args: {}
[D] TIME: 2026-04-17T23:38:03.143638 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-17T23:38:03.724037 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-17T23:38:03.865735 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-17T23:38:15.792438 🧭 [Nav] PUSH: /applications | args: {}
[D] TIME: 2026-04-17T23:38:16.287463 getApplicationsByEventId called | id: 73dcb4f1-c532-49b6-b942-fb43bd1e8a4c
[D] TIME: 2026-04-17T23:38:16.433277 getApplicationsByEventId called | id: 6649e892-baa9-46c3-928e-f73926f4af29
[D] TIME: 2026-04-17T23:38:16.500667 getApplicationsByEventId called | id: 78a0273a-0c4c-43f7-be81-cfb85ac22f99
[D] TIME: 2026-04-17T23:38:16.551415 getApplicationsByEventId called | id: 398715df-35d0-40e8-84fe-738ff3447791
[D] TIME: 2026-04-17T23:38:16.618158 getApplicationsByEventId called | id: b251c0e0-d374-457e-99f1-83a815e081d3
[D] TIME: 2026-04-17T23:38:16.680409 getApplicationsByEventId called | id: c4c9f47d-2c9f-478e-b66d-99ec5ecec536
[D] TIME: 2026-04-17T23:38:16.739067 getApplicationsByEventId called | id: ce68c123-6e29-4e97-8b04-0f862dda3639
[D] TIME: 2026-04-17T23:38:16.815337 getApplicationsByEventId called | id: 5b8dd35d-37ec-4bd4-9f86-0240215ba503
[D] TIME: 2026-04-17T23:38:16.883820 getApplicationsByEventId called | id: 5368e443-7d9e-4576-92bb-7a1de74ae7db
[D] TIME: 2026-04-17T23:38:16.930604 getApplicationsByEventId called | id: a1c310f2-0670-413a-b786-fefbeb74f3b4
[D] TIME: 2026-04-17T23:38:16.984341 getApplicationsByEventId called | id: 1cee3fe5-f9f5-4997-8925-b89d98e78bfe
[D] TIME: 2026-04-17T23:38:17.046902 getApplicationsByEventId called | id: 993ebe5a-7a8d-4697-99a1-342eca1f1fad
[D] TIME: 2026-04-17T23:38:17.097298 getApplicationsByEventId called | id: 43488e27-c736-4c66-858d-f8a6a9bb041e
[D] TIME: 2026-04-17T23:38:17.150130 getApplicationsByEventId called | id: 1f0f6c75-870b-49eb-b150-0043cef1d4cc
[D] TIME: 2026-04-17T23:38:17.218489 getApplicationsByEventId called | id: 6549b195-f008-485c-8e0d-aebdfb77b149
[D] TIME: 2026-04-17T23:38:17.274652 getApplicationsByEventId called | id: c2e8b09a-eca3-4d1d-829c-bc8649a535eb
[D] TIME: 2026-04-17T23:38:17.338389 getApplicationsByEventId called | id: 6eff63bb-df82-4cae-9de0-73a8986cf842
[D] TIME: 2026-04-17T23:38:17.402160 getApplicationsByEventId called | id: 3735c83e-483e-4420-a148-24f262e6e701
[D] TIME: 2026-04-17T23:38:17.468714 getApplicationsByEventId called | id: 3e424f53-ab6a-4577-8f00-7f5b8819ecce
[D] TIME: 2026-04-17T23:38:17.558826 getApplicationsByEventId called | id: c14d5d8b-6f97-4fb9-b837-41a32435ec51
[D] TIME: 2026-04-17T23:38:17.617431 getApplicationsByEventId called | id: 313190d1-65b0-4e80-b329-4cd7675c48c1
[D] TIME: 2026-04-17T23:38:17.685376 getApplicationsByEventId called | id: 446e3860-339b-4324-922b-7c96e2579013
[D] TIME: 2026-04-17T23:38:17.742007 getApplicationsByEventId called | id: e2b35da8-9305-4cc5-b058-74574940881f
[D] TIME: 2026-04-17T23:38:17.803086 getApplicationsByEventId called | id: 24943f7b-6f2f-4f01-8925-c3ca495c869a
[D] TIME: 2026-04-17T23:38:17.864349 getApplicationsByEventId called | id: 0b87118c-46af-4e57-b567-d8101a2e264b
[D] TIME: 2026-04-17T23:38:17.918453 getApplicationsByEventId called | id: 124da1d5-cd30-49c4-b4e7-92835b5b2c2b
[D] TIME: 2026-04-17T23:38:17.967846 getApplicationsByEventId called | id: 4c45ddd1-d6b0-4578-a556-828895a0ebdf
[D] TIME: 2026-04-17T23:38:18.022949 getApplicationsByEventId called | id: f1540818-0b6f-4116-b5ba-40a22d3046b5
[D] TIME: 2026-04-17T23:38:18.083763 getApplicationsByEventId called | id: c10078bf-a4d2-4e79-8aaa-899d8897a5da
[D] TIME: 2026-04-17T23:38:18.134914 getApplicationsByEventId called | id: 591240f2-b69c-41a2-a0d5-4ae6d0cb4772
[D] TIME: 2026-04-17T23:38:18.189101 getApplicationsByEventId called | id: 02825dc9-26c0-4e85-94ec-cefbd1234081
[D] TIME: 2026-04-17T23:38:18.237464 getApplicationsByEventId called | id: ef7cd1aa-0f1e-4e6e-88d9-7297472a990a
[D] TIME: 2026-04-17T23:38:18.279130 getApplicationsByEventId called | id: e4a39939-2334-4547-bcea-b35dc4f488b5
[D] TIME: 2026-04-17T23:38:18.363767 getApplicationsByEventId called | id: 25b29ea4-4e57-4093-b3fd-e905198e763d
[D] TIME: 2026-04-17T23:38:18.405295 getApplicationsByEventId called | id: 6a1ac4e6-a0d7-486f-aaf5-ec0d3400888f
[D] TIME: 2026-04-17T23:38:18.454134 getApplicationsByEventId called | id: 2caa43eb-05e9-49ac-9acb-0dabfc8f9f29
[D] TIME: 2026-04-17T23:38:18.567001 getApplicationsByEventId called | id: b6b72b2c-3275-4e1d-9604-95cbab7c15ce
[D] TIME: 2026-04-17T23:38:18.618204 getApplicationsByEventId called | id: ba78a0b8-a0cb-4d55-ba94-1dc58445b7a6
[D] TIME: 2026-04-17T23:38:18.671364 getApplicationsByEventId called | id: 4f5bccb2-ac2e-454c-b521-2089c99137f3
[D] TIME: 2026-04-17T23:38:18.782586 getApplicationsByEventId called | id: 4ea512b9-b008-4cdb-93d5-e31ba41bcbf6
[D] TIME: 2026-04-17T23:38:18.840521 getApplicationsByEventId called | id: 9a10673e-528f-47de-a6bf-f0c38cd2240e
[D] TIME: 2026-04-17T23:38:18.899298 getApplicationsByEventId called | id: 774f5c42-dca9-4a20-9868-147e70d59ad3
[D] TIME: 2026-04-17T23:38:18.952197 getApplicationsByEventId called | id: 5a560933-344b-4a2c-90b0-b170c8ab99d3
[D] TIME: 2026-04-17T23:38:19.003028 getApplicationsByEventId called | id: fc5d02f1-1a0a-414c-b917-49435cd2707b
[D] TIME: 2026-04-17T23:38:19.082520 getApplicationsByEventId called | id: 66f9f21e-9fca-4657-af3c-bde17ae55167
[D] TIME: 2026-04-17T23:38:19.133512 getApplicationsByEventId called | id: 0c957827-32cc-43e1-970c-8bc0146751ee
[D] TIME: 2026-04-17T23:38:19.185211 getApplicationsByEventId called | id: 7bc3508a-a2bf-4823-91ff-6254f747d85e
[D] TIME: 2026-04-17T23:38:19.239872 getApplicationsByEventId called | id: 774cd412-7c75-4018-a253-81358a363018
[D] TIME: 2026-04-17T23:38:19.280810 getApplicationsByEventId called | id: 9a53f5de-b0ab-4eda-b9af-6799c6a36016
[D] TIME: 2026-04-17T23:38:19.328639 getApplicationsByEventId called | id: ba2c632e-c360-4a36-9cac-633cc34cf836
[D] TIME: 2026-04-17T23:38:19.397367 getApplicationsByEventId called | id: 8037a23c-da56-4fb8-a2b7-381beeb6c5c7
[D] TIME: 2026-04-17T23:38:19.438266 getApplicationsByEventId called | id: 35429b03-fcc5-48cb-a5cd-63f74fa82084
[D] TIME: 2026-04-17T23:38:19.487079 getApplicationsByEventId called | id: 598a8fd8-cde2-49a3-be66-314817e9cf6a
[D] TIME: 2026-04-17T23:38:19.598325 getApplicationsByEventId called | id: c249dc52-7244-4dad-a0ab-ac1b0f9afd83
[D] TIME: 2026-04-17T23:38:19.649056 getApplicationsByEventId called | id: c26bcd5e-d1d2-4882-81a3-7f64e9ae5b95
[D] TIME: 2026-04-17T23:38:19.702843 getApplicationsByEventId called | id: c75b0ce1-3e23-410d-8ae2-c2cc9b0de1bd
[D] TIME: 2026-04-17T23:38:19.784808 getApplicationsByEventId called | id: 6fc30e51-8c9a-4460-86b5-e45d7f9efa3c
[D] TIME: 2026-04-17T23:38:19.834270 getApplicationsByEventId called | id: 4b4fbec9-2325-4b23-9df2-2ba6080e5b2a
[D] TIME: 2026-04-17T23:38:19.883942 getApplicationsByEventId called | id: e639837d-acf8-45dd-8a11-efc0640a3dc6
[D] TIME: 2026-04-17T23:38:19.964050 getApplicationsByEventId called | id: a618a880-100e-4569-84af-0f38fe8fdf38
[D] TIME: 2026-04-17T23:38:20.011719 getApplicationsByEventId called | id: 5b2ce73c-2e59-4ae3-ae1b-5e44a065475f
[D] TIME: 2026-04-17T23:38:20.058975 getApplicationsByEventId called | id: aecde574-22b3-49b9-89d6-dbf810de28bc
[D] TIME: 2026-04-17T23:38:20.103142 getApplicationsByEventId called | id: cc70e85c-509d-4c42-b695-a6ed5d906b0a
[D] TIME: 2026-04-17T23:38:20.152974 getApplicationsByEventId called | id: a06592f8-3dc3-47b8-b316-a993f3631813
[D] TIME: 2026-04-17T23:38:20.214241 getApplicationsByEventId called | id: 5cb7e5cd-b1fd-4ebf-960d-1e66915904bc
[D] TIME: 2026-04-17T23:38:20.284757 getApplicationsByEventId called | id: 07047e79-a69f-4184-a1f3-1dcbbae6a2f1
[D] TIME: 2026-04-17T23:38:20.341645 getApplicationsByEventId called | id: fd371175-95f8-4dfb-8b41-5e59605c0281
[D] TIME: 2026-04-17T23:38:20.388279 getApplicationsByEventId called | id: 2958bb9f-1378-4e4c-806d-037145b087b2
[D] TIME: 2026-04-17T23:38:20.437800 getApplicationsByEventId called | id: 78e73794-85d3-456f-85ca-074c7eb86448
[D] TIME: 2026-04-17T23:38:20.496667 getApplicationsByEventId called | id: 12939957-76c4-49fb-a506-cb2763b16924
[D] TIME: 2026-04-17T23:38:20.546550 getApplicationsByEventId called | id: d14b2461-2c6e-4c7e-82d4-23ea21498b2b
[D] TIME: 2026-04-17T23:38:20.596027 getApplicationsByEventId called | id: 403f7caf-d86c-4550-affd-894e8583de0e
[D] TIME: 2026-04-17T23:38:20.642715 getApplicationsByEventId called | id: 56122d84-ab58-4ead-a4eb-742aa562632c
[D] TIME: 2026-04-17T23:38:20.685935 getApplicationsByEventId called | id: 3a926aa4-bd24-4cb7-b1c2-b80c28f07e41
[D] TIME: 2026-04-17T23:38:20.744845 getApplicationsByEventId called | id: 4cb42254-7ba6-4adb-9c8e-330ab93ad57d
[D] TIME: 2026-04-17T23:38:20.794458 getApplicationsByEventId called | id: 8baa62b5-fcd6-44de-bfe6-338c378430b6
[D] TIME: 2026-04-17T23:38:20.847815 getApplicationsByEventId called | id: 51475d9b-09a5-433e-a59f-25f32d6fb87e
[D] TIME: 2026-04-17T23:38:20.897568 getApplicationsByEventId called | id: 035f57d5-972b-495a-a503-fe53b5468805
[D] TIME: 2026-04-17T23:38:21.016811 getApplicationsByEventId called | id: 28a29203-5db1-4129-a01f-0c127d114046
[D] TIME: 2026-04-17T23:38:21.067845 getApplicationsByEventId called | id: 6fb31142-83e6-4aef-8a03-3e3704544d9b
[D] TIME: 2026-04-17T23:38:21.119373 getApplicationsByEventId called | id: 79248985-7cec-4542-814f-a9161b89d02c
[D] TIME: 2026-04-17T23:38:21.177701 getApplicationsByEventId called | id: 354e90e4-0043-4500-8e17-a9a8693641a3
[D] TIME: 2026-04-17T23:38:21.227124 getApplicationsByEventId called | id: eb75fabb-27d3-4dde-aa02-40875d21540e
[D] TIME: 2026-04-17T23:38:21.278935 getApplicationsByEventId called | id: ec02a041-dda3-4d81-a4c8-3ae7fcb51579
[D] TIME: 2026-04-17T23:38:21.330495 getApplicationsByEventId called | id: 14376da0-6f95-4ee5-96ea-44e8b2af4137
[D] TIME: 2026-04-17T23:38:21.379121 getApplicationsByEventId called | id: 4ad754ab-a87f-461b-973c-36b33ab13884
[D] TIME: 2026-04-17T23:38:21.428335 getApplicationsByEventId called | id: 12b394c0-98a0-4d19-92aa-99627ad68d3b
[D] TIME: 2026-04-17T23:38:21.474812 getApplicationsByEventId called | id: 50072d82-efba-4698-b4be-91a5358696a4
[D] TIME: 2026-04-17T23:38:21.518819 getApplicationsByEventId called | id: 3200a102-66da-4e44-a245-9b2a93e744f7
[D] TIME: 2026-04-17T23:38:34.900430 getApplicationsByEventId called | id: 73dcb4f1-c532-49b6-b942-fb43bd1e8a4c
[D] TIME: 2026-04-17T23:38:34.950255 getApplicationsByEventId called | id: 6649e892-baa9-46c3-928e-f73926f4af29
[D] TIME: 2026-04-17T23:38:35.007449 getApplicationsByEventId called | id: 78a0273a-0c4c-43f7-be81-cfb85ac22f99
[D] TIME: 2026-04-17T23:38:35.056505 getApplicationsByEventId called | id: 398715df-35d0-40e8-84fe-738ff3447791
[D] TIME: 2026-04-17T23:38:35.101366 getApplicationsByEventId called | id: b251c0e0-d374-457e-99f1-83a815e081d3
[D] TIME: 2026-04-17T23:38:35.148058 getApplicationsByEventId called | id: c4c9f47d-2c9f-478e-b66d-99ec5ecec536
[D] TIME: 2026-04-17T23:38:35.198766 getApplicationsByEventId called | id: ce68c123-6e29-4e97-8b04-0f862dda3639
[D] TIME: 2026-04-17T23:38:35.240744 getApplicationsByEventId called | id: 5b8dd35d-37ec-4bd4-9f86-0240215ba503
[D] TIME: 2026-04-17T23:38:35.297842 getApplicationsByEventId called | id: 5368e443-7d9e-4576-92bb-7a1de74ae7db
[D] TIME: 2026-04-17T23:38:35.342316 getApplicationsByEventId called | id: a1c310f2-0670-413a-b786-fefbeb74f3b4
[D] TIME: 2026-04-17T23:38:35.404162 getApplicationsByEventId called | id: 1cee3fe5-f9f5-4997-8925-b89d98e78bfe
[D] TIME: 2026-04-17T23:38:35.455090 getApplicationsByEventId called | id: 993ebe5a-7a8d-4697-99a1-342eca1f1fad
[D] TIME: 2026-04-17T23:38:35.503329 getApplicationsByEventId called | id: 43488e27-c736-4c66-858d-f8a6a9bb041e
[D] TIME: 2026-04-17T23:38:35.556515 getApplicationsByEventId called | id: 1f0f6c75-870b-49eb-b150-0043cef1d4cc
[D] TIME: 2026-04-17T23:38:35.617522 getApplicationsByEventId called | id: 6549b195-f008-485c-8e0d-aebdfb77b149
[D] TIME: 2026-04-17T23:38:35.674723 getApplicationsByEventId called | id: c2e8b09a-eca3-4d1d-829c-bc8649a535eb
[D] TIME: 2026-04-17T23:38:35.725528 getApplicationsByEventId called | id: 6eff63bb-df82-4cae-9de0-73a8986cf842
[D] TIME: 2026-04-17T23:38:35.784506 getApplicationsByEventId called | id: 3735c83e-483e-4420-a148-24f262e6e701
[D] TIME: 2026-04-17T23:38:35.840789 getApplicationsByEventId called | id: 3e424f53-ab6a-4577-8f00-7f5b8819ecce
[D] TIME: 2026-04-17T23:38:35.901479 getApplicationsByEventId called | id: c14d5d8b-6f97-4fb9-b837-41a32435ec51
[D] TIME: 2026-04-17T23:38:35.953084 getApplicationsByEventId called | id: 313190d1-65b0-4e80-b329-4cd7675c48c1
[D] TIME: 2026-04-17T23:38:36.011615 getApplicationsByEventId called | id: 446e3860-339b-4324-922b-7c96e2579013
[D] TIME: 2026-04-17T23:38:36.087172 getApplicationsByEventId called | id: e2b35da8-9305-4cc5-b058-74574940881f
[D] TIME: 2026-04-17T23:38:36.143289 getApplicationsByEventId called | id: 24943f7b-6f2f-4f01-8925-c3ca495c869a
[D] TIME: 2026-04-17T23:38:36.214019 getApplicationsByEventId called | id: 0b87118c-46af-4e57-b567-d8101a2e264b
[D] TIME: 2026-04-17T23:38:36.286808 getApplicationsByEventId called | id: 124da1d5-cd30-49c4-b4e7-92835b5b2c2b
[D] TIME: 2026-04-17T23:38:36.350352 getApplicationsByEventId called | id: 4c45ddd1-d6b0-4578-a556-828895a0ebdf
[D] TIME: 2026-04-17T23:38:36.399359 getApplicationsByEventId called | id: f1540818-0b6f-4116-b5ba-40a22d3046b5
[D] TIME: 2026-04-17T23:38:36.451425 getApplicationsByEventId called | id: c10078bf-a4d2-4e79-8aaa-899d8897a5da
[D] TIME: 2026-04-17T23:38:36.501363 getApplicationsByEventId called | id: 591240f2-b69c-41a2-a0d5-4ae6d0cb4772
[D] TIME: 2026-04-17T23:38:36.549872 getApplicationsByEventId called | id: 02825dc9-26c0-4e85-94ec-cefbd1234081
[D] TIME: 2026-04-17T23:38:36.595450 getApplicationsByEventId called | id: ef7cd1aa-0f1e-4e6e-88d9-7297472a990a
[D] TIME: 2026-04-17T23:38:36.631391 getApplicationsByEventId called | id: e4a39939-2334-4547-bcea-b35dc4f488b5
[D] TIME: 2026-04-17T23:38:36.667614 getApplicationsByEventId called | id: 25b29ea4-4e57-4093-b3fd-e905198e763d
[D] TIME: 2026-04-17T23:38:36.706337 getApplicationsByEventId called | id: 6a1ac4e6-a0d7-486f-aaf5-ec0d3400888f
[D] TIME: 2026-04-17T23:38:36.755634 getApplicationsByEventId called | id: 2caa43eb-05e9-49ac-9acb-0dabfc8f9f29
[D] TIME: 2026-04-17T23:38:36.813257 getApplicationsByEventId called | id: b6b72b2c-3275-4e1d-9604-95cbab7c15ce
[D] TIME: 2026-04-17T23:38:36.865584 getApplicationsByEventId called | id: ba78a0b8-a0cb-4d55-ba94-1dc58445b7a6
[D] TIME: 2026-04-17T23:38:36.917725 getApplicationsByEventId called | id: 4f5bccb2-ac2e-454c-b521-2089c99137f3
[D] TIME: 2026-04-17T23:38:37.007890 getApplicationsByEventId called | id: 4ea512b9-b008-4cdb-93d5-e31ba41bcbf6
[D] TIME: 2026-04-17T23:38:37.066165 getApplicationsByEventId called | id: 9a10673e-528f-47de-a6bf-f0c38cd2240e
[D] TIME: 2026-04-17T23:38:37.122931 getApplicationsByEventId called | id: 774f5c42-dca9-4a20-9868-147e70d59ad3
[D] TIME: 2026-04-17T23:38:37.174571 getApplicationsByEventId called | id: 5a560933-344b-4a2c-90b0-b170c8ab99d3
[D] TIME: 2026-04-17T23:38:37.231869 getApplicationsByEventId called | id: fc5d02f1-1a0a-414c-b917-49435cd2707b
[D] TIME: 2026-04-17T23:38:37.280451 getApplicationsByEventId called | id: 66f9f21e-9fca-4657-af3c-bde17ae55167
[D] TIME: 2026-04-17T23:38:37.332150 getApplicationsByEventId called | id: 0c957827-32cc-43e1-970c-8bc0146751ee
[D] TIME: 2026-04-17T23:38:37.386477 getApplicationsByEventId called | id: 7bc3508a-a2bf-4823-91ff-6254f747d85e
[D] TIME: 2026-04-17T23:38:37.504738 getApplicationsByEventId called | id: 774cd412-7c75-4018-a253-81358a363018
[D] TIME: 2026-04-17T23:38:37.566516 getApplicationsByEventId called | id: 9a53f5de-b0ab-4eda-b9af-6799c6a36016
[D] TIME: 2026-04-17T23:38:37.621289 getApplicationsByEventId called | id: ba2c632e-c360-4a36-9cac-633cc34cf836
[D] TIME: 2026-04-17T23:38:37.681619 getApplicationsByEventId called | id: 8037a23c-da56-4fb8-a2b7-381beeb6c5c7
[D] TIME: 2026-04-17T23:38:37.736338 getApplicationsByEventId called | id: 35429b03-fcc5-48cb-a5cd-63f74fa82084
[D] TIME: 2026-04-17T23:38:37.791218 getApplicationsByEventId called | id: 598a8fd8-cde2-49a3-be66-314817e9cf6a
[D] TIME: 2026-04-17T23:38:37.848840 getApplicationsByEventId called | id: c249dc52-7244-4dad-a0ab-ac1b0f9afd83
[D] TIME: 2026-04-17T23:38:37.903903 getApplicationsByEventId called | id: c26bcd5e-d1d2-4882-81a3-7f64e9ae5b95
[D] TIME: 2026-04-17T23:38:37.966223 getApplicationsByEventId called | id: c75b0ce1-3e23-410d-8ae2-c2cc9b0de1bd
[D] TIME: 2026-04-17T23:38:38.017937 getApplicationsByEventId called | id: 6fc30e51-8c9a-4460-86b5-e45d7f9efa3c
[D] TIME: 2026-04-17T23:38:38.059886 getApplicationsByEventId called | id: 4b4fbec9-2325-4b23-9df2-2ba6080e5b2a
[D] TIME: 2026-04-17T23:38:38.098125 getApplicationsByEventId called | id: e639837d-acf8-45dd-8a11-efc0640a3dc6
[D] TIME: 2026-04-17T23:38:38.142906 getApplicationsByEventId called | id: a618a880-100e-4569-84af-0f38fe8fdf38
[D] TIME: 2026-04-17T23:38:38.190004 getApplicationsByEventId called | id: 5b2ce73c-2e59-4ae3-ae1b-5e44a065475f
[D] TIME: 2026-04-17T23:38:38.249161 getApplicationsByEventId called | id: aecde574-22b3-49b9-89d6-dbf810de28bc
[D] TIME: 2026-04-17T23:38:38.294595 getApplicationsByEventId called | id: cc70e85c-509d-4c42-b695-a6ed5d906b0a
[D] TIME: 2026-04-17T23:38:38.335904 getApplicationsByEventId called | id: a06592f8-3dc3-47b8-b316-a993f3631813
[D] TIME: 2026-04-17T23:38:38.387798 getApplicationsByEventId called | id: 5cb7e5cd-b1fd-4ebf-960d-1e66915904bc
[D] TIME: 2026-04-17T23:38:38.436498 getApplicationsByEventId called | id: 07047e79-a69f-4184-a1f3-1dcbbae6a2f1
[D] TIME: 2026-04-17T23:38:38.497076 getApplicationsByEventId called | id: fd371175-95f8-4dfb-8b41-5e59605c0281
[D] TIME: 2026-04-17T23:38:38.555172 getApplicationsByEventId called | id: 2958bb9f-1378-4e4c-806d-037145b087b2
[D] TIME: 2026-04-17T23:38:38.617073 getApplicationsByEventId called | id: 78e73794-85d3-456f-85ca-074c7eb86448
[D] TIME: 2026-04-17T23:38:38.667816 getApplicationsByEventId called | id: 12939957-76c4-49fb-a506-cb2763b16924
[D] TIME: 2026-04-17T23:38:38.730498 getApplicationsByEventId called | id: d14b2461-2c6e-4c7e-82d4-23ea21498b2b
[D] TIME: 2026-04-17T23:38:38.783942 getApplicationsByEventId called | id: 403f7caf-d86c-4550-affd-894e8583de0e
[D] TIME: 2026-04-17T23:38:38.838854 getApplicationsByEventId called | id: 56122d84-ab58-4ead-a4eb-742aa562632c
[D] TIME: 2026-04-17T23:38:38.884117 getApplicationsByEventId called | id: 3a926aa4-bd24-4cb7-b1c2-b80c28f07e41
[D] TIME: 2026-04-17T23:38:38.931683 getApplicationsByEventId called | id: 4cb42254-7ba6-4adb-9c8e-330ab93ad57d
[D] TIME: 2026-04-17T23:38:38.969760 getApplicationsByEventId called | id: 8baa62b5-fcd6-44de-bfe6-338c378430b6
[D] TIME: 2026-04-17T23:38:39.010227 getApplicationsByEventId called | id: 51475d9b-09a5-433e-a59f-25f32d6fb87e
[D] TIME: 2026-04-17T23:38:39.053428 getApplicationsByEventId called | id: 035f57d5-972b-495a-a503-fe53b5468805
[D] TIME: 2026-04-17T23:38:39.099585 getApplicationsByEventId called | id: 28a29203-5db1-4129-a01f-0c127d114046
[D] TIME: 2026-04-17T23:38:39.144473 getApplicationsByEventId called | id: 6fb31142-83e6-4aef-8a03-3e3704544d9b
[D] TIME: 2026-04-17T23:38:39.184788 getApplicationsByEventId called | id: 79248985-7cec-4542-814f-a9161b89d02c
[D] TIME: 2026-04-17T23:38:39.231505 getApplicationsByEventId called | id: 354e90e4-0043-4500-8e17-a9a8693641a3
[D] TIME: 2026-04-17T23:38:39.307200 getApplicationsByEventId called | id: eb75fabb-27d3-4dde-aa02-40875d21540e
[D] TIME: 2026-04-17T23:38:39.345144 getApplicationsByEventId called | id: ec02a041-dda3-4d81-a4c8-3ae7fcb51579
[D] TIME: 2026-04-17T23:38:39.386339 getApplicationsByEventId called | id: 14376da0-6f95-4ee5-96ea-44e8b2af4137
[D] TIME: 2026-04-17T23:38:39.432749 getApplicationsByEventId called | id: 4ad754ab-a87f-461b-973c-36b33ab13884
[D] TIME: 2026-04-17T23:38:39.482457 getApplicationsByEventId called | id: 12b394c0-98a0-4d19-92aa-99627ad68d3b
[D] TIME: 2026-04-17T23:38:39.539926 getApplicationsByEventId called | id: 50072d82-efba-4698-b4be-91a5358696a4
[D] TIME: 2026-04-17T23:38:39.598233 getApplicationsByEventId called | id: 3200a102-66da-4e44-a245-9b2a93e744f7
[I] TIME: 2026-04-17T23:38:56.153902 🧭 [Nav] PUSH: /more | args: {}
[I] TIME: 2026-04-17T23:38:58.396001 🧭 [Nav] PUSH: parties (from /more) | args: {}
[D] TIME: 2026-04-17T23:38:58.401322 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-17T23:38:58.549853 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-17T23:38:58.629492 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-17T23:39:11.030760 🧭 [Nav] PUSH: create (from parties) | args: {}
[I] TIME: 2026-04-17T23:39:22.561560 🧭 [Nav] POP: create (from parties) | args: {}
[I] TIME: 2026-04-17T23:39:36.009196 🧭 [Nav] POP: parties (from /more) | args: {}
[I] TIME: 2026-04-17T23:39:37.278272 🧭 [Nav] PUSH: verifications/manage (from /more) | args: {}
[D] TIME: 2026-04-17T23:39:37.360555 getPartnerVerifications called | partnerId: c518ec3d-0988-4b47-9abc-6655763a45bb, isActive: true
[D] TIME: 2026-04-17T23:39:37.361968 getPartnerVerifications called | partnerId: c518ec3d-0988-4b47-9abc-6655763a45bb, isActive: false
[D] TIME: 2026-04-17T23:39:37.687480 getPartnerVerifications success | count: 0
[D] TIME: 2026-04-17T23:39:37.693575 getPartnerVerifications success | count: 0
[I] TIME: 2026-04-17T23:39:47.220573 🧭 [Nav] PUSH: verifications/create (from verifications/manage) | args: {}
[I] TIME: 2026-04-17T23:39:58.771361 🧭 [Nav] POP: verifications/create (from verifications/manage) | args: {}
[I] TIME: 2026-04-17T23:40:00.065622 🧭 [Nav] POP: verifications/manage (from /more) | args: {}
[I] TIME: 2026-04-17T23:40:01.561031 🧭 [Nav] PUSH: account (from /more) | args: {}
[I] TIME: 2026-04-17T23:40:09.847721 🧭 [Nav] PUSH: Unknown Route
[I] TIME: 2026-04-17T23:40:19.270532 🧭 [Nav] POP: Unknown Route
[I] TIME: 2026-04-17T23:40:19.620052 🧭 [Nav] PUSH: /login | args: {}
[I] TIME: 2026-04-17T23:40:19.620299 🧭 [Nav] REMOVE: Unknown Route | args: {}
[I] TIME: 2026-04-17T23:40:20.017925 👋 [AuthRepo] Sign-Out successful
[I] TIME: 2026-04-17T23:41:58.918620 🧭 [Nav] PUSH: /dev/user-switch (from /login) | args: {}
[D] TIME: 2026-04-17T23:42:10.475972 🔐 [AuthRepo] Email Sign-In started: partner_hotplace_0@test.com
[I] TIME: 2026-04-17T23:42:10.886731 🎉 [AuthRepo] Email Sign-In successful!
[D] TIME: 2026-04-17T23:42:10.945512 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[I] TIME: 2026-04-17T23:42:10.950584 🧭 [Nav] PUSH: /welcome (from /dev/user-switch) | args: {}
[I] TIME: 2026-04-17T23:42:10.950784 🧭 [Nav] REMOVE: /dev/user-switch | args: {}
[I] TIME: 2026-04-17T23:42:10.950884 🧭 [Nav] REMOVE: /login | args: {}
[D] TIME: 2026-04-17T23:42:11.260497 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-17T23:42:11.405926 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-17T23:42:11.423500 🧭 [Nav] PUSH: Unknown Route (from /welcome) | args: {}
[I] TIME: 2026-04-17T23:42:11.423887 🧭 [Nav] REMOVE: /welcome | args: {}
[I] TIME: 2026-04-17T23:42:11.442311 🧭 [Nav] PUSH: / | args: {}
[D] TIME: 2026-04-17T23:42:11.448014 getMyManagedPartners called | user: af5b1192-90dd-4e4a-83c9-15080569be11
[D] TIME: 2026-04-17T23:42:11.574656 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: 3605a8d9-a57b-4760-b9a4-20a93957b61c}, {partner_id: d3ab9da0-e222-426f-be66-76137513ea33}, {partner_id: 3ca1e0bb-1000-4990-a64e-c5d8257e70c4}, {partner_id: 510a2056-8660-40e8-b810-695377be737f}, {partner_id: fb8d615f-bbd7-4659-bf34-998b3bfcb9ab}, {partner_id: 6e2a596a-2e14-4f77-af9f-57d51b0ffa05}, {partner_id: 14a94443-532a-4188-9b12-4b53434080ba}, {partner_id: 206040a8-1399-460a-b5d8-0371ca40da0b}, {partner_id: 2bd9c24d-dcc3-45e8-9437-3c144d46540e}, {partner_id: e35b85e4-0a41-4eb0-b89f-a4e497f8b2e9}, {partner_id: ddee7b49-a348-4897-808e-161a64cac26f}, {partner_id: e5aa2a9f-02e1-405b-bead-2ea62c8e87c6}, {partner_id: a599be14-c23d-4a0f-84e4-6553c3ba32d1}, {partner_id: 88be9983-c6d2-4b94-bd17-a4a487ce393f}, {partner_id: 0ddfad46-0077-4b76-bdca-c069d1f044cb}, {partner_id: 3ddd0dee-378e-4e38-b250-454a3332af45}, {partner_id: c5ef36f9-8c7b-40d3-9e85-084afcfd5e58}, {partner_id: b5aa5dd2-d2cb-4019-9e16-bc7991c293f8}, {partner_id: c518ec3d-0988-4b47-9abc-6655763a45bb}]
[D] TIME: 2026-04-17T23:42:11.699235 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-17T23:42:48.668473 🧭 [Nav] PUSH: /more | args: {}
[I] TIME: 2026-04-17T23:43:06.519835 🧭 [Nav] PUSH: Unknown Route
[I] TIME: 2026-04-17T23:43:15.634646 🧭 [Nav] POP: Unknown Route
[I] TIME: 2026-04-17T23:43:15.649708 🧭 [Nav] PUSH: /login | args: {}
[I] TIME: 2026-04-17T23:43:15.649897 🧭 [Nav] REMOVE: Unknown Route | args: {}
[I] TIME: 2026-04-17T23:43:16.470612 👋 [AuthRepo] Sign-Out successful
[I] TIME: 2026-04-17T23:43:33.311022 🧭 [Nav] PUSH: /dev/user-switch (from /login) | args: {}
[I] TIME: 2026-04-17T23:45:19.727952 🧭 [Nav] POP: /dev/user-switch (from /login) | args: {}
[I] TIME: 2026-04-17T23:45:24.418272 🧭 [Nav] PUSH: /dev/user-switch (from /login) | args: {}
[D] TIME: 2026-04-17T23:46:51.157208 🔐 [AuthRepo] Email Sign-In started: partner_hotplace_2@test.com
[I] TIME: 2026-04-17T23:46:51.637984 🎉 [AuthRepo] Email Sign-In successful!
[D] TIME: 2026-04-17T23:46:51.670453 getMyManagedPartners called | user: cbce322c-f27a-440e-85dc-72d048545244
[I] TIME: 2026-04-17T23:46:51.682646 🧭 [Nav] PUSH: /welcome (from /dev/user-switch) | args: {}
[I] TIME: 2026-04-17T23:46:51.683332 🧭 [Nav] REMOVE: /dev/user-switch | args: {}
[I] TIME: 2026-04-17T23:46:51.683404 🧭 [Nav] REMOVE: /login | args: {}
[D] TIME: 2026-04-17T23:46:52.160748 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: fde44196-eb64-444d-a093-4590471eb19c}, {partner_id: 777f740d-608c-421a-85be-5729854039e7}, {partner_id: 6dbb3a22-76d1-4e01-a7a2-2c3d4b1b533a}, {partner_id: a95be267-9a59-4ab1-9d14-33811a2a1f25}, {partner_id: d2791e50-4cfa-4220-988b-f3c1af1a380f}, {partner_id: 7e62f477-8cdd-452c-b456-8b713c79339b}, {partner_id: 53779483-de69-46f8-aebb-8de37c931d9c}, {partner_id: be24b99c-9b5b-4dbf-8baf-6a8cbf233405}, {partner_id: e5ac549b-f0cb-46c9-bafe-371bd0bcec01}, {partner_id: c2ae19f8-c9b2-48be-a4c4-f99bec3d61ad}, {partner_id: 197f6726-c450-4be5-b6ec-0c6b9f7788ba}, {partner_id: 31cf58ad-38bf-483d-8365-4b7fc5cd3b30}, {partner_id: 703732c0-c333-44ee-a036-2d2aa000b70a}, {partner_id: 9a6ad7d0-e2d7-4e6b-a0cc-57b873326cb5}, {partner_id: 5eea30df-7b59-4a68-8b06-09564f6d253a}, {partner_id: 9a1dbcb5-3039-4882-87aa-7acaff35d86a}, {partner_id: de3492b4-fb11-46e2-a978-fc01eded8b08}, {partner_id: 51f06bff-f3e4-466f-9b00-74a4ae81e373}, {partner_id: 796bca06-fdc3-44ac-b605-5398429772c5}]
[D] TIME: 2026-04-17T23:46:52.297039 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-17T23:46:52.329543 🧭 [Nav] PUSH: Unknown Route (from /welcome) | args: {}
[I] TIME: 2026-04-17T23:46:52.330487 🧭 [Nav] REMOVE: /welcome | args: {}
[I] TIME: 2026-04-17T23:46:52.360389 🧭 [Nav] PUSH: / | args: {}
[D] TIME: 2026-04-17T23:46:52.371277 getMyManagedPartners called | user: cbce322c-f27a-440e-85dc-72d048545244
[D] TIME: 2026-04-17T23:46:52.549315 🔍 [PartnerRepo] Found permissions raw data: [{partner_id: fde44196-eb64-444d-a093-4590471eb19c}, {partner_id: 777f740d-608c-421a-85be-5729854039e7}, {partner_id: 6dbb3a22-76d1-4e01-a7a2-2c3d4b1b533a}, {partner_id: a95be267-9a59-4ab1-9d14-33811a2a1f25}, {partner_id: d2791e50-4cfa-4220-988b-f3c1af1a380f}, {partner_id: 7e62f477-8cdd-452c-b456-8b713c79339b}, {partner_id: 53779483-de69-46f8-aebb-8de37c931d9c}, {partner_id: be24b99c-9b5b-4dbf-8baf-6a8cbf233405}, {partner_id: e5ac549b-f0cb-46c9-bafe-371bd0bcec01}, {partner_id: c2ae19f8-c9b2-48be-a4c4-f99bec3d61ad}, {partner_id: 197f6726-c450-4be5-b6ec-0c6b9f7788ba}, {partner_id: 31cf58ad-38bf-483d-8365-4b7fc5cd3b30}, {partner_id: 703732c0-c333-44ee-a036-2d2aa000b70a}, {partner_id: 9a6ad7d0-e2d7-4e6b-a0cc-57b873326cb5}, {partner_id: 5eea30df-7b59-4a68-8b06-09564f6d253a}, {partner_id: 9a1dbcb5-3039-4882-87aa-7acaff35d86a}, {partner_id: de3492b4-fb11-46e2-a978-fc01eded8b08}, {partner_id: 51f06bff-f3e4-466f-9b00-74a4ae81e373}, {partner_id: 796bca06-fdc3-44ac-b605-5398429772c5}]
[D] TIME: 2026-04-17T23:46:52.664518 getMyManagedPartners success | count: 19
[I] TIME: 2026-04-17T23:46:59.187364 🧭 [Nav] PUSH: /settlement | args: {}
[D] TIME: 2026-04-17T23:46:59.335069 getSettlementDashboard called | partnerId: 796bca06-fdc3-44ac-b605-5398429772c5
[D] TIME: 2026-04-17T23:46:59.483862 getSettlementDashboard success | total: 0
[D] TIME: 2026-04-17T23:47:23.735466 getSettlementDashboard called | partnerId: 796bca06-fdc3-44ac-b605-5398429772c5
[D] TIME: 2026-04-17T23:47:23.981125 getSettlementDashboard success | total: 0
[D] TIME: 2026-04-17T23:47:41.730672 getSettlementDashboard called | partnerId: 796bca06-fdc3-44ac-b605-5398429772c5
[D] TIME: 2026-04-17T23:47:41.949444 getSettlementDashboard success | total: 0
[I] TIME: 2026-04-17T23:47:42.993389 QaBugReportChannel: received triggerBugReport title="[QA] P-S11 — 정산 탭에서 계좌 관리(/settlement/bank-account) 진입 경로를 찾을 수 없음" scenario=null session=null
[D] TIME: 2026-04-17T23:47:44.941149 Uploading bytes to bug-report-attachments/layout-dumps/e44d5106-e019-40ee-9fa9-c8142a87a770.txt...
[D] TIME: 2026-04-17T23:47:44.995796 Uploading bytes to bug-report-attachments/screenshots/0ff1f7e3-45c5-46aa-8bbc-0aeb417f736a.png...
[D] TIME: 2026-04-17T23:47:45.488087 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/0ff1f7e3-45c5-46aa-8bbc-0aeb417f736a.png
[D] TIME: 2026-04-17T23:47:45.556256 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/e44d5106-e019-40ee-9fa9-c8142a87a770.txt
```

</details>


## Screenshot
![Screenshot](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/0ff1f7e3-45c5-46aa-8bbc-0aeb417f736a.png)


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
[📐 View Layout Dump](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/e44d5106-e019-40ee-9fa9-c8142a87a770.txt)


## Comments (10)

### Comment 1 — @Mark-Yun on 2026-04-18

🤖 **needs-qa-claude-1** 작업 시작합니다.

P-S11 결과로 보고된 "정산 탭에서 BankAccountPage 진입 경로 미발견" 케이스를 코드 기준으로 검증하고, 의도적 제거인지 미구현/회귀인지 판정합니다.

### Comment 2 — @Mark-Yun on 2026-04-18

## ✅ QA 검증 결과 — 진성 버그 (UI 진입 경로 누락)

### 코드 기준 확인

| 항목 | 상태 | 위치 |
|------|------|------|
| 라우트 등록 | ✅ 존재 | `apps/app_partner/lib/src/routing/app_routes.dart:135` (`TypedGoRoute<BankAccountRoute>(path: 'bank-account')`) |
| 페이지 클래스 | ✅ 존재 | `apps/app_partner/lib/src/features/settlement/bank_account_page.dart` |
| Coordinator 헬퍼 | ✅ 존재 | `settlement_coordinator.dart:28` `goToBankAccount()` |
| **UI 진입 버튼** | ❌ **없음** | `settlement_page.dart` AppBar에 actions 슬롯 비어 있음, Dashboard/List 탭에도 버튼 없음 |
| Coordinator 호출 | ❌ **테스트 외 0건** | `grep goToBankAccount` → `settlement_coordinator_test.dart:65`만 호출. 프로덕션 코드 호출 없음 |

→ `goToBankAccount()` 메서드는 **사실상 dead code**. 라우트/페이지/리포지토리는 모두 작동하는데 UI 버튼만 없어서 직접 URL 입력 외에 도달 불가.

### 문서 기준

`docs/qa/test-cases/app-partner-smoke.md:156` (5.4 정산 액션 매트릭스):
> | 계좌 관리 | `/settlement/bank-account`로 이동 | - |

→ 카탈로그 상 **명시된 액션이 UI에서 사라진/구현되지 않은 상태**. P-S11 케이스 자체(직접 URL 진입)는 페이지 도달 가능하므로 통과지만, 실 사용자가 도달할 수 없음.

### 비즈니스 임팩트 — P1 후보

- 파트너가 **은행 계좌를 등록/변경할 UI 경로가 없음** → 정산 수령 불가 (`SETTLEMENT_EDIT` 권한 보유자도 마찬가지)
- 정산 수령은 파트너 핵심 monetization 플로우 → `P1-high` 라벨 권장

### 권장 수정 (SWE)

**파일**: `apps/app_partner/lib/src/features/settlement/settlement_page.dart` (l.42-59 `AppBar`)

```dart
appBar: AppBar(
  title: const Text('정산'),
  actions: [
    if (hasSettlementEditAccess)  // 권한 게이트 (아래 참고)
      IconButton(
        icon: const Icon(Icons.account_balance_outlined),
        tooltip: '계좌 관리',
        onPressed: () => ref
            .read(settlementCoordinatorProvider.notifier)
            .goToBankAccount(),
      ),
  ],
  bottom: TabBar(...),
),
```

**권한 게이트** — PR #1544의 `hasSettlementAccessProvider` 패턴을 따라 `hasSettlementEditAccessProvider` 추가 권장:
- 계좌 조회/수정은 `SETTLEMENT_EDIT` 권한 필요 (`partner-manage-settlement/index.ts:133`, `docs/features/partner-settlement/architecture.md:794`)
- `SETTLEMENT_VIEW`만 있는 멤버에게는 버튼 미노출 (서버 403 방어)

### 회귀 방지 테스트 (필수 — P1 이상 정책)

`apps/app_partner/test/src/features/settlement/settlement_page_test.dart` (신규 또는 기존):

| # | 케이스 | 검증 |
|---|--------|------|
| T1 | `SETTLEMENT_EDIT` 권한 보유 → SettlementPage 렌더 | AppBar actions에 `Icons.account_balance_outlined` IconButton 1개 존재 |
| T2 | `SETTLEMENT_VIEW`만 보유 → SettlementPage 렌더 | 계좌 관리 버튼 미노출 |
| T3 | T1 상태에서 IconButton 탭 | `goRouter.push('/settlement/bank-account')` 호출됨 (mock router 또는 `location` 검증) |
| T4 | 카탈로그 정합성 (선택) | `docs/qa/test-cases/app-partner-smoke.md` 5.4 매트릭스의 "계좌 관리" 항목과 실제 위젯이 일치하는지 골든/스냅샷 |

### 카탈로그 후속 (QA 본인 처리 예정)

- 본 PR 머지 후 `docs/qa/test-cases/app-partner-smoke.md` P-S11 "비고" 컬럼에 "AppBar 계좌 관리 IconButton 경유" 추가
- 5.4 매트릭스의 "계좌 관리" 행은 변경 없이 유지 (이미 정확)

### 라벨 변경

- `needs-qa` 제거
- `needs-swe` 추가
- `P1-high` 추가 (정산 수령 불가 → monetization 차단)
- `bug` 추가 (확정 버그)

— **needs-qa-claude-1**

### Comment 3 — @Mark-Yun on 2026-04-18

🤖 **needs-swe-sonnet-1** 작업 시작합니다.

### Comment 4 — @Mark-Yun on 2026-04-18

🤖 **needs-tpm-claude-1** `needs-review` 라벨은 PR용입니다 (이슈 아님) — 제거했습니다. PR #1570에만 `needs-review`를 붙이세요. 이슈는 `needs-swe` 유지.

### Comment 5 — @Mark-Yun on 2026-04-18

🤖 **needs-qa-claude-1** 라벨 정리 사이클. QA 분석+테스트 플랜 제출 완료, SWE가 PR #1570 CI 진행 중 (현재 test-flutter-apps partner 러닝). `needs-qa`는 이전 사이클에서 제거됐어야 할 잔여 라벨이므로 제거한다. PR #1570 머지 후 `docs/qa/test-cases/app-partner-smoke.md` P-S11 비고란에 "AppBar 계좌 관리 IconButton 경유" 추가하는 카탈로그 업데이트는 별도 PR로 처리 예정.

### Comment 6 — @onlyhyeok-cmd on 2026-04-18

needs-uiux: 이 이슈는 정산 탭 AppBar에 계좌 관리 버튼 추가 + more_page에서 계좌 관리 동선 변경을 포함합니다. PR #1570 리뷰에서 ux-designer 가이드가 없어 request-changes되었습니다. ux-designer 가이드(레이아웃, 버튼 위치, 권한 표시 방식)를 이슈에 코멘트로 남겨주시면 PR 본문에 인용 후 재요청하겠습니다.

### Comment 7 — @Mark-Yun on 2026-04-18

🤖 **needs-uiux-gemini-1** 가이드 제공합니다.

### 🎨 UI/UX 가이드: 정산 계좌 관리 진입점 개선

**1. 정산 탭 (SettlementPage) AppBar 개선**
- **위치**: 의 AppBar  영역 (우측 상단)
- **아이콘**:  (정산/계좌의 의미를 명확히 전달)
- **툴팁**: '계좌 관리'
- **동작**: 클릭 시 로 이동 ( 호출)
- **노출 조건**:  권한이 있는 멤버에게만 노출. 권한이 없는 경우 버튼을 숨겨 UI 복잡도를 낮춥니다.

**2. 네비게이션 전략**
- 계좌 관리는 정산 기능과 밀접하게 연관되어 있으므로, 정산 메인 화면(SettlementPage) 상단에 배치하는 것이 가장 발견하기 쉬운 구조(Discoverability)입니다.
- 기존에 '더보기' 탭에 관련 진입점이 없었으므로, 이번에 정산 탭으로 집중시키는 방향이 적절합니다.

**3. 디자인 일관성**
- 의 디자인 시스템을 준수하며, AppBar의 기본 아이콘 버튼 스타일을 따릅니다.
-  진입 후에도 상단 타이틀이 '계좌 관리'로 명확히 표시되는지 확인 부탁드립니다.

이 가이드를 PR #1570 본문에 인용해 주시면 감사하겠습니다.

### Comment 8 — @Mark-Yun on 2026-04-18

🤖 **needs-uiux-gemini-1** 가이드 제공합니다.

### 🎨 UI/UX 가이드: 정산 계좌 관리 진입점 개선

**1. 정산 탭 (SettlementPage) AppBar 개선**
- **위치**: `SettlementPage`의 AppBar `actions` 영역 (우측 상단)
- **아이콘**: `Icons.account_balance_outlined` (정산/계좌의 의미를 명확히 전달)
- **툴팁**: '계좌 관리'
- **동작**: 클릭 시 `BankAccountRoute`로 이동 (`settlementCoordinator.goToBankAccount()` 호출)
- **노출 조건**: `SETTLEMENT_EDIT` 권한이 있는 멤버에게만 노출. 권한이 없는 경우 버튼을 숨겨 UI 복잡도를 낮춥니다.

**2. 네비게이션 전략**
- 계좌 관리는 정산 기능과 밀접하게 연관되어 있으므로, 정산 메인 화면(SettlementPage) 상단에 배치하는 것이 가장 발견하기 쉬운 구조(Discoverability)입니다.
- 기존에 '더보기' 탭에 관련 진입점이 없었으므로, 이번에 정산 탭으로 집중시키는 방향이 적절합니다.

**3. 디자인 일관성**
- `minglit_kit`의 디자인 시스템을 준수하며, AppBar의 기본 아이콘 버튼 스타일을 따릅니다.
- `BankAccountPage` 진입 후에도 상단 타이틀이 '계좌 관리'로 명확히 표시되는지 확인 부탁드립니다.

이 가이드를 PR #1570 본문에 인용해 주시면 감사하겠습니다.

### Comment 9 — @Mark-Yun on 2026-04-18

## 🎨 ux-designer 가이드 — 정산 계좌 관리 진입 동선

Scheduler: needs-uiux-claude-1

PR #1570 리뷰어 요청에 따라 **레이아웃 / 버튼 위치 / 권한 표시 방식** 세 축으로 승인 가이드를 남깁니다. 현재 구현은 큰 방향에서 올바르며, 한 가지 IA 배치만 조정 권장.

---

### 1. 레이아웃 (Layout)

| 진입점 | 컴포넌트 | 아이콘 | 레이블 | 평가 |
|--------|---------|-------|-------|------|
| 정산 탭 AppBar | `IconButton` | `account_balance_wallet_outlined` | (tooltip) "계좌 관리" | ✅ 승인 |
| 더보기 탭 | `MinglitSettingsTile` | `account_balance_wallet_outlined` | "정산 계좌 관리" | ✅ 승인 (배치만 조정) |

- **아이콘**: `account_balance_wallet_outlined` 는 "내 지갑/내 돈"의 메타포로 적절. `account_balance_outlined`(은행 건물)는 "은행 입점/B2B" 뉘앙스라 파트너 앱 문맥에 맞지 않음 → 현재 선택 유지.
- **아이콘 일관성**: 두 진입점 모두 동일 아이콘 사용 ✅. 유저가 동일 기능임을 즉시 인지.
- **레이블 톤**: AppBar tooltip은 맥락("정산" 탭 안)에서 "계좌 관리"만으로 충분. 더보기 탭은 맥락이 없으므로 "**정산** 계좌 관리"로 prefix 유지 — 다른 "계좌"(로그인 계정 등)와 혼동 방지. ✅

### 2. 버튼 위치 (Position)

#### 2-1. 정산 탭 AppBar — 현재 배치 승인

```
┌────────────────────────────────────┐
│ 정산                      [💳]     │  ← AppBar.actions 마지막 슬롯
├────────────────────────────────────┤
│  대시보드  │  내역                  │  ← TabBar
└────────────────────────────────────┘
```
- AppBar `actions` 슬롯 배치 → iOS/Android 표준. 우상단 trailing action은 "현재 화면의 보조 액션"이 기본이고, "내 계좌 설정"은 정확히 그 역할.
- 월 네비게이션(이전/다음달)은 AppBar가 아니라 **대시보드 탭 본문 상단**에 있어야 맞지만, 본 PR 스코프 밖이므로 별도 이슈로 분리 권장(후속).

#### 2-2. 더보기 탭 — "비즈니스 관리" 그룹 **최하단**으로 이동 권장

**현재 (PR #1570)**: 파티 관리 → 인증 심사 관리 → **정산 계좌 관리** → 멤버 관리

**권장**: 파티 관리 → 인증 심사 관리 → 멤버 관리 → **정산 계좌 관리**

근거:
- 사용 빈도: 파티/인증/멤버는 반복 운영 작업, 정산 계좌는 1~2회성 등록 설정 → 자주 쓰는 항목이 위.
- 의미 그룹핑: "운영 대상(파티/인증/멤버)" → "운영 기반(정산 계좌)" 순서가 IA상 자연스러움.
- 향후 확장: "정산 내역 다운로드", "정산 주기 설정" 등 추가 시 "정산 계좌 관리" 근처에 묶기 편함.

구체 수정(`apps/app_partner/lib/src/features/more/more_page.dart`):
```dart
// Group 2: Business Management
MinglitSettingsGroup(
  header: '비즈니스 관리',
  children: [
    MinglitSettingsTile(  // 파티 관리
      leading: Icons.event_note_outlined,
      title: '파티 관리',
      onTap: moreCoordinator.pushPartyList,
    ),
    MinglitSettingsTile(  // 인증 심사 관리
      leading: Icons.verified_user_outlined,
      title: '인증 심사 관리',
      onTap: moreCoordinator.pushVerificationManage,
    ),
    MinglitSettingsTile(  // 멤버 관리
      leading: Icons.people_outline,
      title: '멤버 관리',
      onTap: () { /* ... */ },
    ),
    if (canEditSettlement)  // ← 그룹 최하단으로 이동
      MinglitSettingsTile(
        leading: Icons.account_balance_wallet_outlined,
        title: '정산 계좌 관리',
        onTap: moreCoordinator.pushBankAccountManagement,
      ),
  ],
),
```

### 3. 권한 표시 방식 (Permission Gating)

**현재 방식 — `SETTLEMENT_EDIT` 미보유 시 버튼 자체 숨김 (not disabled). ✅ 승인.**

근거:
- 토스/Linear 등 모범 사례: 권한 기반 UI는 **"숨기는 것"이 기본**, "비활성화+툴팁"은 혼란을 유발 (왜 막혔는지 모름 → 지원 문의 증가).
- SETTLEMENT_VIEW 전용 사용자는 애초에 계좌 정보 편집 대상이 아니므로, 엔트리포인트를 노출하지 않는 편이 서버 403 방어막으로도 작동.
- 스크린 리더: 숨기면 semantic tree에서도 빠지므로 TalkBack/VoiceOver 탐색 중 혼란 없음.

다만 **로딩 깜빡임(flash) 주의**:
- 현재 `ref.watch(currentMemberPermissionsProvider).asData?.value ?? []` → 로딩 중엔 항상 "권한 없음"으로 취급 → 화면 진입 직후 버튼이 잠시 안 보이다가 권한 로드 후 "뽁" 하고 나타남.
- **옵션 A (현 상태 유지)**: 깜빡임 수백 ms — 허용 가능 (파트너 정보 캐시되면 실질 영향 낮음).
- **옵션 B (권장, 작은 개선)**: `AnimatedSwitcher(duration: 150ms)`로 감싸서 fade-in. 추후 개선 아이템으로 남겨도 됨.

### 4. 접근성 (Accessibility)

- IconButton `tooltip: '계좌 관리'` → TalkBack이 "계좌 관리 버튼"으로 announce ✅
- MinglitSettingsTile `title: '정산 계좌 관리'` → semantic 라벨 자동 노출 ✅
- 터치 타겟: Material IconButton 48×48dp 기본, 정산 설정 타일은 `MinglitSettingsTile` 컴포넌트 내 48dp 이상 보장 ✅

---

### 최종 요청사항 (PR #1570 반영)

1. **[필수]** 더보기 페이지 "정산 계좌 관리" 타일을 "비즈니스 관리" 그룹 **최하단**으로 이동 (멤버 관리 아래).
2. **[필수]** PR 본문에 이 코멘트 링크를 `ux-designer 가이드` 항목으로 인용.
3. **[선택]** 로딩 깜빡임 `AnimatedSwitcher` 래핑은 후속 개선(본 PR 스코프 밖).

1번 반영 후 `needs-review` 재부여 → 리뷰어 통과 예상.

### 라우팅

- `needs-uiux` 제거
- `needs-swe` 재부여 (1번 수정 후 PR 본문 업데이트)

— **needs-uiux-claude-1**


### Comment 10 — @Mark-Yun on 2026-04-18

🤖 **needs-swe-sonnet-1** PR #1570 리뷰 결과 대응.

리뷰어가 지적한 내용: PR #1570에서 정산 AppBar에 버튼 추가 + More 페이지에서 계좌 관리 제거는 **네비게이션 동선 수정**에 해당하여 ux-designer 가이드 인용이 PR body에 필요합니다.

`needs-uiux` 라벨 추가하여 ux-designer 가이드를 요청합니다. 가이드 코멘트 확인 후 PR #1570 body에 인용하여 재요청 예정입니다.
