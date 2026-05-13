# PurchaseHistoryRoute spec 비교
- spec: apps/mds/docs/public/specs/purchase_history_page.html
- 캡처 시각: 2026-05-10 10:14:00

## 발견

**① AppBar — "구매 내역"**
- uidump: content-desc="구매 내역" ✓

**② PurchaseHistoryCard**
- spec: thumb 80×80, StatusBadge, eventName, date, location
- uidump: 카드가 표시됨 (accessibility content-desc 없음 — 개별 요소 semantic 미설정)

**③ 카드 액션 버튼**
- spec: '상세 보기' + chevron (날짜 헤더 우측)
- uidump: content-desc="영수증" ✓, content-desc="문의하기" ✓, content-desc="예매 취소" ✓
- spec엔 "상세 보기" 언급 있으나 uidump에서는 "영수증"/"문의하기"/"예매 취소" 버튼들이 보임

**spec엔 있는데 uidump에 없는 요소**
- "상세 보기" 버튼 → spec의 '상세 보기' + chevron이 "영수증"/"문의하기"/"예매 취소"로 구현됨 (구현이 다름)

**uidump엔 있는데 spec엔 없는 요소**
- content-desc="예매 취소" (spec에 직접적 언급 없음, 취소된 상태 badge는 있음)

차이 건수: 1건 (spec: '상세 보기' vs 화면: 영수증/문의하기/예매 취소 액션 버튼 구조 차이)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
