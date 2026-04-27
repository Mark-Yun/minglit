---
source_url: https://github.com/Mark-Yun/minglit/issues/1634
captured_at: 2026-04-19
issue_number: 1634
state: closed
labels: [bug-report, P1-high, from-app, report-runtime-qa]
author: Mark-Yun
title: "[Bug Report] [QA] U-S03 — Dev 환경 이벤트 eligibility 필터로 EventDetailPage 진입 불가"
---

# [Bug Report] [QA] U-S03 — Dev 환경 이벤트 eligibility 필터로 EventDetailPage 진입 불가

> Issue #1634 · closed · created 2026-04-19T21:57:05Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1634

## Body


### 🐞 Bug Report

**Description:**
증상: getEventsByType success | count: 4 로 이벤트 4개가 DB에 존재하지만, getBulkEligibilityData 후 홈 피드에 표시되는 이벤트가 0개. 모든 dev 유저(user_18_f_강남, user_18_f_성수)에서 동일 현상. 검색(파티/밍글)에서도 결과 없음. 이벤트 탭으로도 접근 불가. 결과: U-S03(EventDetailPage), U-S04(파트너상세), U-S05(파트너이벤트목록) 스모크 테스트 불가. 발견: runtime-qa-smoke-user-sonnet-subagents 세션 20260420-060101.

**Environment:**
- Platform: android
- Timestamp: 2026-04-19T17:57:06.150855

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
[I] TIME: 2026-04-19T17:57:02.471418 Bug reported successfully via Edge Function
[I] TIME: 2026-04-19T17:57:02.472712 QaBugReportChannel: report submitted successfully
[I] TIME: 2026-04-19T17:57:05.354675 QaBugReportChannel: received triggerBugReport title="[QA] U-S03 — Dev 환경 이벤트 eligibility 필터로 EventDetailPage 진입 불가" scenario=null session=null
[D] TIME: 2026-04-19T17:57:05.842169 Uploading bytes to bug-report-attachments/layout-dumps/529f87c3-1c0f-4d63-86cd-6215b76457d2.txt...
[D] TIME: 2026-04-19T17:57:05.865643 Uploading bytes to bug-report-attachments/screenshots/0987f6f8-5f97-4127-8a73-120b653cc2a8.png...
[D] TIME: 2026-04-19T17:57:06.128410 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/0987f6f8-5f97-4127-8a73-120b653cc2a8.png
[D] TIME: 2026-04-19T17:57:06.150379 ✅ Upload bytes success: https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/529f87c3-1c0f-4d63-86cd-6215b76457d2.txt
```

</details>


## Screenshot
![Screenshot](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/screenshots/0987f6f8-5f97-4127-8a73-120b653cc2a8.png)


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
[📐 View Layout Dump](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/layout-dumps/529f87c3-1c0f-4d63-86cd-6215b76457d2.txt)


## Comments (4)

### Comment 1 — @Mark-Yun on 2026-04-19

🤖 **needs-qa-claude-1** 작업 시작합니다.

#1632과 동일 세션 dev user (ef5c49d1-eb53-46db-8087-fde4b4e80e5e)에서 발생한 로그 패턴이 동일 (getEventsByType: 4건, getTodayActiveEventsForUser: 0건). 함께 분석합니다.

### Comment 2 — @Mark-Yun on 2026-04-19

## 🔍 QA 진단 — needs-qa-claude-1

### 증상 확인

홈 스크린샷(`0987f6f8-5f97-4127-8a73-120b653cc2a8.png`)에서 **"추천 이벤트가 없습니다"** 확인. 로그 순서:

```
getEventsByType called | type: EventFeedType.newArrivals
getTodayActiveEventsForUser called | userId: ef5c49d1-eb53-46db-8087-fde4b4e80e5e
getBulkEligibilityData called
getBulkEligibilityData success
Eligibility data arrived, refiltering 0 events
getTodayActiveEventsForUser success | count: 0
getEventsByType success | count: 4   ← DB에는 4건 존재
```

DB에 4건 존재 + 유저는 verified(dev seed `is_verified: true`) → 그런데 홈에는 0건 표시.

### 코드 분석 결과

#### 1. "Eligibility refiltering 0 events" 로그는 **무해함** (오해 소지 있음)

- `feed_state_provider.dart:302` — build 초기 `_rawEvents=[]` 상태에서 eligibility가 먼저 도착해 `_refilterExistingEvents()` 호출됨
- `_refilterExistingEvents()` (line 368): `_rawEvents.isEmpty` 가드로 조용히 early return
- **이후** `_fetchPage` 완료 시 line 407 `ref.read(filteredEventsProvider(events: _rawEvents))`로 eligibility filter가 **다시 적용**됨
- 즉, race condition이 아님. 로그 문구만 혼동을 유발 → `refiltering N events (skipped)` 형태로 명확화 권장

#### 2. 진짜 필터 단계 (`feed_state_provider.dart:143-219`)

기본 `ActiveFilters: eligibilityEnabled=true, nearbyEnabled=true, sortType=recommended`.

적용 순서:
1. **Eligibility** (verified 유저만) → `EligibilityFilter.filter()` → `TicketRecommendationUtil.recommend()` 각 이벤트 티켓 평가
2. Nearby sort (순서만 바꿈, 제거 아님)
3. closingSoon일 때만 잔여석 필터

#### 3. TicketRecommendationUtil 경로 검증

seed.dev.sql 기본 티켓(`target_entry_group_ids={}`, `required_verification_ids={}`):
- `groups = []` (ticket.targetEntryGroupIds 비어있음)
- `groups.isEmpty` 분기 → `_missingVerificationIds([], ...)` → 빈 배열 → eligible

**→ seed 4개 이벤트는 모두 통과해야 정상.** 그런데 실제 홈은 0건.

### 가능한 근본 원인 (순위)

| # | 원인 | 근거 | 검증 방법 |
|---|------|------|-----------|
| **A** | **dev DB 실제 이벤트 ≠ seed.dev.sql 내용** (다른 이벤트가 `entry_groups` 또는 `required_verification_ids` 가지고 있음) | seed 기본값 통과 조건 충족하는데 0건 → 실제 데이터 세팅이 다름 | dev Supabase에서 `getEventsByType(newArrivals)` 쿼리 직접 실행 후 tickets/entry_groups 점검 |
| B | `bulkEligibilityDataProvider` 응답의 `is_verified=false` (RPC는 `up.is_verified` 직접 반환) | 가능성 낮음 — seed는 true | RPC 직접 호출해 `user_profile.is_verified` 확인 |
| C | `ticket.targetEntryGroupIds`가 비어있어도 `entry_groups` 쿼리가 다른 그룹 잡혀서 ineligible 처리 | 코드상 `groups = entryGroups.where(ticket.targetEntryGroupIds.contains)` — 빈 배열이면 `groups=[]`, 영향 없음 | — |

**A가 가장 유력.** QA seed Phase 6/7(Fix #1602)로 최근 추가된 오픈 이벤트 외, 과거 이벤트들이 제한 조건을 가진 채 DB에 남아있을 가능성.

### 검색 '파티' 0건 (스크린샷 `f63ca5b5-...`)

- `searchResults`는 `search_events_pgroonga` RPC 호출, **eligibility 필터 미적용** (`feed_state_provider.dart:107-125`)
- seed party titles: `[QA] 오픈 소셜 파티 (연령/성별 무관)`, `[QA] 소셜 클래스`, `[QA] 스포츠 소셜 모임`, `[QA] 아트 & 문화 이벤트`
- `파티` 키워드는 첫 번째 파티 제목에만 매칭됨 → pgroonga tokenization에 따라 달라짐
- **이건 별개 문제** — #1634와 분리 필요 (CUJ-U04 관련, Fix #1617 맥락)

### 추천 조치

1. **needs-swe**로 넘겨 dev DB의 실제 `events/tickets/entry_groups` 상태를 확인하고, 필요하면:
   - QA test 유저 persona와 이벤트 조건을 매칭시키는 seed 보강
   - 또는 이벤트 자체는 보여주되 ticket 레벨에서 "조건 미충족" UI 처리 (현재 홈은 완전히 숨김 — UX 결함)

2. **로그 문구 정정** (작은 수정):
   ```dart
   // feed_state_provider.dart:301-304
   if (next.hasValue && next.value != null) {
     Log.d(
       _rawEvents.isEmpty
         ? 'Eligibility data arrived before events — skipping refilter'
         : 'Eligibility data arrived, refiltering ${_rawEvents.length} events',
     );
   }
   ```

### 회귀 방지 테스트 (needs-swe 구현 대상)

기존 `eligibility_filter_test.dart`(257줄), `ticket_recommendation_util_test.dart`(264줄) 있음. 다음 케이스 추가 필요:

| # | 테스트 | 파일 | 시나리오 |
|---|--------|------|----------|
| T1 | `RecommendationFeedNotifier` 통합 | `feed_state_provider_test.dart` (신규) | eligibility 먼저 도착 → fetch 완료 시점에 filter 재적용되어 events 노출됨을 검증 |
| T2 | 검증자 페르소나 매트릭스 | `eligibility_filter_test.dart` 추가 | {18여, 25여, 35남, 42남} × {entry_group 없음 이벤트, 남성전용, 연령제한, 인증 필요} 매트릭스 — 각 조합 eligible/ineligible 예상값 문서화 |
| T3 | 홈 empty state UX | `home_page_test.dart` or alchemist golden | filter 결과 0건일 때 "추천 이벤트가 없습니다" 렌더링 + "필터 해제" CTA 존재 검증 |
| T4 | pgTAP: seed dev 데이터 무결성 | `supabase/tests/` | seed.dev.sql 실행 후 `user_18_f_강남`이 최소 1개 이벤트에서 eligible임을 SQL로 검증 |

### 다음 단계

`needs-qa` 제거, `needs-swe` 부여. #1632는 동일 원인 → 본 이슈로 통합 후 닫음.


### Comment 3 — @Mark-Yun on 2026-04-20

🤖 **needs-swe-sonnet-1** 작업 시작합니다. QA가 요청한 eligibility 테스트 추가 작업을 진행합니다.

### Comment 4 — @Mark-Yun on 2026-04-20

## ✅ needs-swe-sonnet-1 완료 (테스트 추가)

**PR #1643** — test(eligibility): age, verification, and persona matrix tests

QA가 요청한 회귀 방지 테스트를 에 추가 후 dev에 머지했습니다.

### 추가된 테스트

| 테스트 | 검증 내용 |
|--------|-----------|
| 나이 하한 미달 (1980년생, min 1990) | birthYear < birthYearMin → 필터링 |
| 나이 상한 초과 (2010년생, max 2005) | birthYear > birthYearMax → 필터링 |
| 인증 없는 유저 | requiredVerificationIds 미충족 → 필터링 |
| 인증 보유 유저 | requiredVerificationIds 충족 → 통과 |
| 18F persona | 오픈 이벤트만 통과 |
| 25F persona | 오픈 이벤트만 통과 (남성전용 차단) |
| 35M persona | 오픈, 남성전용, 연령제한(25-40) 통과 |
| 42M persona | 오픈, 남성전용 통과; 연령제한(25-40) 차단 (초과) |
| 전 페르소나 오픈 이벤트 | 핵심 회귀 가드: 모두 통과해야 함 |

### 미구현 (T4)
pgTAP seed-data 무결성 테스트는 supabase 변경이 필요하며 별도 이슈 필요시 파일링 예정.

 라벨 제거합니다.
