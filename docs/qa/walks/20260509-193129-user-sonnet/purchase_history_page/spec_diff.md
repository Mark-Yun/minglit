# PurchaseHistoryRoute spec 비교
- spec: apps/mds/docs/public/specs/purchase_history_page.html
- 캡처 시각: 2026-05-09 19:44:00

## 발견

spec엔 있음 + uidump 확인:
- 구매 내역 제목: content-desc="구매 내역" ✓
- 뒤로가기: content-desc="뒤로" ✓
- 구매 항목: 날짜, 승인 상태, 이벤트명, 장소 포함 ✓
- 영수증: content-desc="영수증" ✓
- 문의하기: content-desc="문의하기" ✓
- 예매 취소: content-desc="예매 취소" ✓

spec엔 있음 + uidump엔 없음:
- 차이 없음

uidump엔 있음 + spec엔 없음:
- 차이 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 0건
