---
source_url: https://github.com/Mark-Yun/minglit/issues/2409
captured_at: 2026-05-10
issue_number: 2409
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/개선] event_detail §3 참가 현황 — \"N명 참여\" caption 과 gauge \"현재/정원\" 의미 충돌 (참여 인원 vs 티켓 판매)"
---

# [audit-uiux/개선] event_detail §3 참가 현황 — "N명 참여" caption 과 gauge "현재/정원" 의미 충돌 (참여 인원 vs 티켓 판매)

> Issue #2409 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2409

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

- code: `apps/app_user/lib/src/features/event/detail/event_entry_conditions_section.dart:36-95`
- spec: `apps/mds/docs/public/specs/event_detail_page/index.md` §3 참가 현황 sub-anatomy (lines 104-118)
- visual: `apps/mds/docs/public/specs/event_detail_page/state_4.png`, `blueprint_5.png`

## 문제 요약

§3 참가 현황의 entry group card에는 같은 카드 row에 **두 카운트가 라벨 차별화 없이** 함께 노출된다:

- 좌측 caption **"N명 참여"** — `participantCount = counts[group.id]` (entryGroupParticipantCountsProvider) → **실제 그룹 합류한 사용자 수**
- 우측 gauge label **"현재/정원"** — `soldCount/totalQuantity` (matchingTickets fold) → **매칭 티켓의 판매량/capacity**

state_4 mockup 재현:
- 일반 참여 (남성) — `8명 참여` + `13/20`
- 일반 참여 (여성) — `10명 참여` + `16/20`

두 숫자는 **서로 다른 개념** (entry group join 카운트 vs ticket sold 카운트) 이지만, 동일 카드 안에 라벨 차별화 없이 배치되어 사용자는 "왜 8과 13이 다른가?" 를 즉시 의심한다. spec sub-anatomy(lines 110-118)도 의미 차이를 명시하지 않아 디자이너 / 구현자 / 사용자 셋 다 혼선이 발생한다.

## 현재 / 권장

### 현재 (drift)

```dart
// event_entry_conditions_section.dart:77 — caption (참여 인원)
Text('$participantCount명 참여', ...)
// event_entry_conditions_section.dart:89-92 — gauge (티켓 판매량)
MinglitParticipantGauge(current: soldCount, max: totalQuantity)
```

spec sub-anatomy 본문 (lines 110-118):
- `· _"N명 참여"_ (bodySmall · text-secondary)`
- `· _"현재/정원"_ 라벨 (10 · w600 · text-secondary)`

→ 두 숫자가 같은 카드에 있지만 라벨에서 의미 차이가 드러나지 않음. blueprint_5도 "name + count + gauge" 로 묶어 표기 — count 와 gauge 가 **같은 그룹의 같은 의미** 라는 인상을 준다.

### 권장 (3가지 옵션 — Mark 판단)

**Option A — 라벨 차별화 (변경 가장 작음)**
- caption: `"참여 8명"` 유지
- gauge label: `"티켓 13/20"` 으로 prefix 추가 → 두 숫자 의미를 명시

**Option B — 단일 카운트로 통합 (정보 노이즈 ↓)** ⭐ 권장
- caption "N명 참여" 제거, gauge label 만 노출 (`"신청 13/20"` 또는 `"참여 13/20"`)
- 일반 사용자에게 entry group "join" 과 ticket "sold" 의 차이는 의미 없음 — 정보를 줄이는 것이 명료성 ↑.
- 토스 / Airbnb / 당근 등 frontier 패턴은 모두 **단일 카운트** 노출.

**Option C — 의미 차를 명시하는 부연 설명**
- 참여 캡션 옆 info icon → 탭 시 "참여 = 그룹 합류, 신청 = 티켓 결제 완료" tooltip
- 정보를 모두 보여주되 사용자가 필요 시에만 확인 — 가장 무거움.

추천: **Option B**. 단일 진실(spec) 단순화 + 코드 line 76-81 caption 제거 + gauge label semantic 정리. spec §3 sub-anatomy 갱신이 필요 (Mark 영역).

## reference

- code: `apps/app_user/lib/src/features/event/detail/event_entry_conditions_section.dart`
  - line 53: `participantCount = counts[group.id] ?? 0` (entry group join count)
  - line 44-51: `soldCount / totalQuantity` fold (ticket sold count)
  - line 76-81: caption render
  - line 89-92: gauge render
- spec: `apps/mds/docs/public/specs/event_detail_page/index.md`
  - line 110-118: §3 sub-anatomy 본문 + 토큰 row
- blueprint: `apps/mds/docs/public/specs/event_detail_page/blueprint_5.png` ("name + count + gauge" 묶음)
- state mockup: `apps/mds/docs/public/specs/event_detail_page/state_4.png` (남성 8 vs 13/20, 여성 10 vs 16/20)

### Frontier 비교

| 앱 | 패턴 |
|---|---|
| 토스 이벤트 | 단일 "신청자 N명" |
| Airbnb 숙소 | 단일 "남은 객실 N개" |
| 당근마켓 모임 | 단일 "참여자 N/M명" |

→ 모두 **단일 카운트** 노출. 듀얼 카운트는 frontier 패턴에서 발견되지 않음.

## 노트

- 이 발견은 단순 typography / token drift 가 아닌 **데이터 모델 노출 의도** 이슈. spec 과 코드 둘 다 "두 카운트 노출" 을 의도한 것으로 보이지만, frontier 사례와 비교하면 정보 줄임이 더 자연스럽다.
- spec 변경 (sub-anatomy 정리) + 코드 변경 (caption 제거 또는 라벨 prefix) 양쪽 다 검토 필요.
- 라우팅 의견: **Option 결정 → Mark / pm**, 결정 후 spec 정리 → Mark, 코드 픽스 → swe.

