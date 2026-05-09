# MyTicketsRoute spec 비교
- spec: apps/mds/docs/public/specs/my_tickets_page.html
- 캡처 시각: 2026-05-09 19:46:00

## 발견

spec엔 있음 + uidump 확인:
- 내 티켓 제목: content-desc="내 티켓" ✓
- 뒤로가기: content-desc="뒤로" ✓
- 티켓 배너 (OngoingBanner): 입장 대기 상태, 이벤트명, 날짜, 장소 ✓
- 입장 QR 미리 보기: content-desc="입장 QR 미리 보기" ✓
- 길찾기: content-desc="길찾기" ✓

spec엔 있음 + uidump엔 없음:
- 빈 상태 CTA ("구매내역 보기", "이벤트 둘러보기"): 티켓 있으므로 미노출 — 조건부

uidump엔 있음 + spec엔 없음:
- 차이 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 0건
