---
source_url: https://github.com/Mark-Yun/minglit/issues/2412
captured_at: 2026-05-10
issue_number: 2412
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] TicketSelectionSheet — 결제 진입 게이트 시트 코드 존재, spec 없음 (PR #2364 인용 spec 부재 root cause)"
---

# [audit-uiux/차이] TicketSelectionSheet — 결제 진입 게이트 시트 코드 존재, spec 없음 (PR #2364 인용 spec 부재 root cause)

> Issue #2412 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2412

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

- code: `apps/app_user/lib/src/features/ticket/ui/ticket_selection_sheet.dart`
- code (위젯): `apps/app_user/lib/src/features/ticket/ui/ticket_selection_widgets.dart`
- 진입 경로: `apps/app_user/lib/src/logic/event_coordinator.dart`, `apps/app_user/lib/src/features/ticket/logic/ticket_coordinator.dart`
- spec: **없음**
- 인접 spec: `apps/mds/docs/public/specs/event_bottom_ticket_bar/index.md` (시트를 띄우는 트리거), `apps/mds/docs/public/specs/event_detail_page/index.md` (시트 진입 화면)

## 현재 / 권장

### 현재 (drift)

`TicketSelectionSheet` 는 **결제 진입의 핵심 시트**:

- 티켓 옵션 리스트 (selected/locked/recommended/ineligible 4-state)
- 추천 자동 선택 (`TicketRecommendationResult` — 잔액 / 자격 / 가격 기준)
- 수량 stepper (`buildQuantityStepper` — `−` / `+` IconButton, tooltip "수량 감소" / "수량 증가" — Fix #2358)
- 잔액 상태 fetch / user verification fetch
- CTA: 결제 진입

이 시트는 **이벤트 → 결제** 메인 경로의 단일 게이트 — 모든 유료 이벤트 구매가 이 시트를 거친다. 그런데:

1. `apps/mds/docs/public/specs/` 어디에도 `ticket_selection_sheet`(또는 유사) spec 폴더 없음.
   ```
   $ ls apps/mds/docs/public/specs/ | grep -i ticket
   event_bottom_ticket_bar
   my_tickets_page
   ticket_create_page
   ticket_edit_page
   ticket_qr_screen
   ```
2. `apps/mds/docs/src/lib/flow-data.ts` 에 `ticket_selection` 관련 route 없음.
3. PR #2364 (Fix #2358) 본문은 `event_application_wizard_page.html` 의 "수량 stepper 섹션"을 인용했지만 — `event_application_wizard_page/index.html` 와 `index.md` 모두 `tooltip` / `수량` / `stepper` / `quantity` 매치 0건. 즉 PR 인용이 사실상 부재한 spec 을 가리킴.

### 권장

`apps/mds/docs/public/specs/ticket_selection_sheet/` 신규 spec 작성 (Mark 영역). 최소 다음을 다뤄야 함:

1. **Header / Overview** — 결제 진입 게이트 역할, event_detail_page → event_bottom_ticket_bar → 본 시트 → 결제 흐름 명시.
2. **Layout / blueprint**
   - 헤더 (이벤트 타이틀 / 닫기)
   - 티켓 옵션 리스트 (Card row · 4-state visualization)
   - 수량 stepper (− / + IconButton 24px · 가운데 숫자 · tooltip 의무)
   - 가격 합계 row
   - CTA 버튼 (full-width, primary, "결제하기")
3. **Sub-anatomy**
   - 티켓 옵션 카드: border / fill / opacity per state — `MinglitSpacing.medium` padding · `MinglitRadius.input` · selected outline 2px primary · locked opacity 0.5 · `MinglitOpacity.tintFill` selected fill
   - Quantity stepper: `IconButton(remove, tooltip "수량 감소")` / 숫자 / `IconButton(add, tooltip "수량 증가")` · disabled rule
   - 추천 배지 / 잠금 사유 텍스트 (`onSurfaceVariant`)
4. **States**
   - loading (잔액·유저 fetch 진행)
   - all-locked (선택 가능 티켓 없음)
   - selected + valid quantity
   - selected + over-quantity (재고 한계)
   - empty (티켓 0개) — 현재 코드 동작 확인 필요
5. **Global Behavior**
   - 자동 추천 선택 (`_hasAutoSelected` 가드)
   - 수량 변경 시 잔액 재검증 트리거
   - 잠긴 티켓 탭 시 무동작 + 사유 텍스트 인라인 표시
6. **Reference**
   - Implementation source 표: `TicketSelectionSheet` / `_TicketSelectionWidgets` / `TicketRecommendationUtil` / `TicketCoordinator` 매핑
   - 진입 spec: `event_bottom_ticket_bar` · `event_detail_page`
   - 다음 spec: `payment_*` (있다면)

## reference

- canonical 작성 톤: `apps/mds/docs/public/specs/event_bottom_ticket_bar/index.md` (시트 트리거 spec — 본 시트와 페어로 작성되면 단일 결제 진입 흐름 완성)
- 트리거 PR: #2364 (Fix #2358) 가 spec 인용했지만 대상 섹션이 spec 에 부재 — root cause 는 시트 spec 자체 부재
- 관련 refactor 이슈: #1519 (디자인 시스템 위젯 적용), #453 (event ↔ ticket 순환 참조)

## 노트

- 코드는 정상 동작 / 사용자 차단 없음. 다만 결제 메인 경로의 단일 게이트가 spec 없이 운영되는 건 audit / a11y / 디자인 일관성 측면에서 부채.
- spec 변경은 Mark 영역 — ux-designer 워커는 진단 + 이슈 파일링까지.
- 본 발견은 `2222 (TBD spec 일괄 — partner 측)` 와 별개의 user-side 시트 누락. 2222 와 묶지 말고 단독으로 처리 권장.
- 후속 권장: spec 작성 후 #2364 의 "수량 stepper tooltip" 회귀 테스트가 spec 의 `tooltip "수량 감소"` / `tooltip "수량 증가"` 를 명시 인용하도록 PR 본문 보강.

— needs-uiux-claude-1

