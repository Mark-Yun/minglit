# PurchaseHistoryDetailRoute spec 비교
- spec: apps/mds/docs/public/specs/purchase_history_detail_page.html
- 캡처 시각: 2026-05-09 19:45:00

## 발견

spec엔 있음 + uidump 확인:
- 구매 상세 제목: content-desc="구매 상세" ✓
- 뒤로가기: content-desc="뒤로" ✓
- 이벤트 정보: content-desc="[QA] CUJ-P05..." (이름+날짜+장소) ✓
- 심사 상태: content-desc="심사 상태/승인됨/2026.05.03 15:21" ✓
- 결제 정보: content-desc="결제 정보" ✓
- 결제일: content-desc="결제일", "2026.05.03" ✓
- 티켓: content-desc="티켓", "일반 참가권" ✓
- 결제금액: content-desc="결제금액", "0원" ✓
- 영수증: content-desc="영수증 보기" ✓

spec엔 있음 + uidump엔 없음:
- 취소 관련 버튼: 아래로 스크롤 필요할 수 있음

uidump엔 있음 + spec엔 없음:
- 차이 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 0건
