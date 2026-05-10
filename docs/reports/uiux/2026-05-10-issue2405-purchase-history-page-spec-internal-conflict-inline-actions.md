---
source_url: https://github.com/Mark-Yun/minglit/issues/2405
captured_at: 2026-05-10
issue_number: 2405
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/개선] purchase_history_page spec 내부 충돌 — verbal '인라인 액션 없음' vs layout tree '영수증/문의하기/예매 취소' 버튼"
---

# [audit-uiux/개선] purchase_history_page spec 내부 충돌 — verbal '인라인 액션 없음' vs layout tree '영수증/문의하기/예매 취소' 버튼

> Issue #2405 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2405

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

`apps/mds/docs/public/specs/purchase_history_page/index.html` 내부 self-contradictory.

## 내부 충돌 요약

같은 spec 안에서 v1.1 "책임 분리" intent와 layout tree / Fix #2076 history가 어긋나 있다.

### A. v1.1 책임 분리 intent (verbal description)

**line 348 (Versions table — 2026-05-05 v1.1)**
> v1.1 책임 분리 정리 (PR #2094 후속). 카드의 **인라인 액션(영수증 / 문의하기 / 예매 취소) + 환불 confirm 다이얼로그 state를 상세 페이지로 위임**. ... 카드는 header / info / divider / pay-row **4 region**.

**line 387-388 (Blueprint & tree intro)**
> 카드는 모두 동일 높이 — **인라인 액션 없이 InkWell 전체가 탭되어 상세 페이지로 push**.

→ 카드는 header / info / divider / pay-row 4 region, 인라인 액션 없음.

### B. Layout tree / blueprint 실제 묘사

**line 402 (Blueprint label)**
> header(date · 상세 보기) / info(thumb · badge+title+meta) / divider / pay-row

**line 432-441 (Layout tree)**
\`\`\`
PurchaseHistoryCard
  ├─ 1. Header Row: paidAt ↔ StatusBadge
  ├─ 2. Info Row: thumb + Column(title · date · location)
  ├─ Divider
  ├─ 3. Pay Row: ticket name ↔ amount
  └─ 4. Actions Row (IntrinsicHeight + Row stretch)
        ├─ TextButton "영수증" (flex 1)  // Fix #2076
        ├─ TextButton "문의하기" (flex 1)
        └─ if canCancel → ElevatedButton "예매 취소" (flex 2)
\`\`\`

**line 354-355 (Versions table — 2026-05-05)**
> Fix #2076 — 무료 티켓 영수증 버튼 동작 변경. ... **항상 "영수증" 버튼 노출**

→ Layout tree는 5 region이고 Actions Row가 명시. Fix #2076는 영수증 버튼이 살아있다는 전제.

### C. 코드 현재 상태

`apps/app_user/lib/src/features/payment/ui/purchase_history_card.dart:155-237` — 영수증 / 문의하기 / 예매 취소 TextButton/ElevatedButton 3개 인라인 노출. 코드는 B를 따른다.

## 현재 / 권장

- **현재**: spec 내부에서 verbal intent (A)와 layout tree (B)가 모순. 코드는 B 구현. 신규 독자가 spec을 읽을 때 어느 쪽이 진실인지 판단 불가.
- **권장**: Mark가 둘 중 하나로 정리.
  - 옵션 1 — **버튼 유지(현행)**: line 348 / 387-388 verbal description을 갱신해 "인라인 액션 (영수증/문의하기/예매 취소) + InkWell 전체 탭 가능 — 카드 5 region"으로 일치시킨다. v1.1 책임 분리 history 항목은 "(부분 적용 — 환불 confirm 다이얼로그만 상세로 위임)"으로 정확히 표시.
  - 옵션 2 — **v1.1 의도 완수**: 카드에서 Actions Row 제거 → 코드도 인라인 버튼 제거 → swe로 라우팅. layout tree / Fix #2076 항목 갱신.

## reference

- spec: `apps/mds/docs/public/specs/purchase_history_page/index.html` (lines 348, 387-388, 402, 432-441, 354-355)
- 코드: `apps/app_user/lib/src/features/payment/ui/purchase_history_card.dart:31-237`
- spec walk drift 발견: `docs/qa/walks/20260510-100059-user-sonnet/purchase_history_page/spec_diff.md` (PR #2372)
- 관련 Fix: #2076 (영수증 버튼 항상 노출), #2094 (책임 분리 PR), #1234 (예매 취소 버튼 flex), #1820 (IntrinsicHeight 통일)
