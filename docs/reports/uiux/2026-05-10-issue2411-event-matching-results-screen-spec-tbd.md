---
source_url: https://github.com/Mark-Yun/minglit/issues/2411
captured_at: 2026-05-10
issue_number: 2411
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] event_matching_results_screen spec 'TBD' — MatchResultsContent 이미 완전 구현 + 출시 중 (route 가정도 어긋남)"
---

# [audit-uiux/차이] event_matching_results_screen spec 'TBD' — MatchResultsContent 이미 완전 구현 + 출시 중 (route 가정도 어긋남)

> Issue #2411 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2411

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

- spec: `apps/mds/docs/public/specs/event_matching_results_screen/index.md`
  - Status: `📝 TBD — 별도 디자인 라운드 예정` (line 7)
  - Implementation source 표 4행 모두 `— (TBD)` (lines 55–59)
  - Route 가정: `EventMatchingResultsRoute · /event/:id/matching/results (예정 · 확정 전)` (line 11)
- code (이미 production 운영 중):
  - `apps/app_user/lib/src/common/widgets/match_results_content.dart` (218 lines, `MatchResultsContent`)
  - 사용처:
    - `apps/app_user/lib/src/features/event/admission/event_admission_controller.dart:260` — `eventEndedWithResults` CTA → modal sheet 콘텐츠
    - `apps/app_user/lib/src/features/home/widgets/event_now_phases/results_content.dart` — `EventNowBottomSheet` phase 6 콘텐츠 (re-export)

## 현재 / 권장

### 현재 (drift)

spec은 `TBD` placeholder + 별도 route 가정인데, **코드는 이미 완전 구현 + 출시 중**. 게다가 구현 패턴이 spec 가정(`EventMatchingResultsRoute`)과 **다름** — 별도 route가 아니라 두 곳에서 쓰이는 **shared bottom sheet content widget**.

구현된 anatomy:
- DragHandle (width 40 · height 4 · radius 2 · textSecondary muted)
- Hero badge: 64×64 primary 원형 + `Icons.favorite` 36px (background color)
- Title `매칭 결과` titleLarge bold (gap medium)
- Subtitle: event.title bodyMedium textSecondary center (gap xlarge)
- Match list:
  - Header: `${matches.length}명과 매칭되었어요!` titleSmall primary w600 (gap medium)
  - Card per match (`_MatchResultCard`):
    - padding `MinglitSpacing.medium`, radius `MinglitRadius.card`, surface bg, 1px primary muted border
    - leading: `MinglitAvatarImage(radius: 24, url: partnerProfileImage)` — primary highlight bg + primary separator fallbackIconColor
    - title: `match.partnerName` bodyLarge bold (fallback `'알 수 없음'`)
    - subtitle: masked phone (`_maskPhone` Fix #1925 — `010-****-5678`) bodySmall textSecondary
    - trailing: `Icons.favorite` primary small
    - 카드 사이 gap small
- Empty state (mutual 0건):
  - `Icons.sentiment_neutral` 48px textSecondary strong
  - `'이번엔 아쉽지만, 다음 기회에!'` bodyMedium textSecondary center
- Loading: `MinglitCircularProgressIndicator` height 120 center
- Error fallback → empty state 와 동일

### 권장

spec 갱신 (Mark 영역 — 본 이슈는 진단만):

1. **Route 가정 정정** — `EventMatchingResultsRoute · /event/:id/matching/results (예정)` → 실제 패턴 명시:
   - "단독 route 없음. `MatchResultsContent` shared widget 으로 ① `EventNowBottomSheet phase 6` (home) ② `event_admission_controller eventEndedWithResults CTA` modal sheet 두 surface 에서 렌더링."
2. **Status: TBD → 'v1.0 (live)'** 또는 v1.0 — 코드가 이미 출시되어 단일 진실(spec)이 코드보다 stale.
3. **Implementation source 표** 4행 채움:
   - Widget class: `MatchResultsContent` (+ 내부 `_MatchResultCard` / `_DragHandle` private)
   - File path: `apps/app_user/lib/src/common/widgets/match_results_content.dart`
   - Provider: `myMatchesProvider(event.id)`
   - Route: — (단독 라우트 없음. 두 surface 의 modal sheet content)
4. **Layout / States 섹션 추가** — 위 anatomy 대로 채움 + 4 state (Default · Empty · Loading · Error) 명시.
5. **Hierarchy 갱신**: parent 가 `MyTicketsPage 또는 EventMatchingScreen phase 전환` (line 12) → 실제는 `EventNowBottomSheet (home) + event_admission_controller (event/admission)`. 본 widget 이 reuse 대상이라는 점을 더 명확히.
6. **Reference · Related screens** 에 `EventOngoingBanner` (lifecycle hub · phase 5 → 6 전환 시점) 외에 `EventNowBottomSheet` / `eventEndedWithResults CTA` 명시.

코드 회귀 (구현 제거)는 권장하지 않음 — Fix #1925 (PII 마스킹), Fix #1934 (`results_content.dart` → `common/widgets/` 이관), Fix #1936 (`MinglitAvatarImage`) 누적된 정착물.

## reference

- spec (drift): `apps/mds/docs/public/specs/event_matching_results_screen/index.md` (lines 7, 11–14, 55–59, 64–67)
- 인접 patterns:
  - `MatchResultsContent` 재사용 패턴 export: `apps/app_user/lib/src/features/home/widgets/event_now_phases/results_content.dart:1-8` (`Fix #1934: widget moved to common/widgets/...`)
  - PII 마스킹: `_maskPhone` (Fix #1925, line 184–202)
  - 아바타: `MinglitAvatarImage` (Fix #1936, line 137–147) — `apps/mds/docs/public/specs/more_page/index.md` 의 canonical 패턴 참조
- 유사한 TBD-vs-implemented 패턴 이슈:
  - #2402 — `review_verification_screen` Flutter 구현 + 라우트 등록 vs spec 누락
  - #2404 — `event_application_review_page` spec `'TBD'` vs 실제 구현 완료

## 카테고리

`[audit-uiux/차이]` — 코드 ↔ 단일 진실(spec) drift. spec 이 stale 한 케이스. tpm 이 트리아지로 `needs-uiux` 또는 `needs-tpm` 부여 후 Mark 가 spec 작성 / 갱신 수행.

— needs-uiux-claude-1
