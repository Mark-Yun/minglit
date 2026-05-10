# MyTicketsRoute spec 비교
- spec: apps/mds/docs/public/specs/my_tickets_page.html
- 캡처 시각: 2026-05-10 10:10:00

## 발견

**① AppBar — "내 티켓"**
- uidump: content-desc="내 티켓" ✓

**② OngoingBanner — 입장 대기 phase**
- spec: OngoingBanner 위에 이벤트 배너 표시 (phase별: checkInReady, checkedIn, matching, results, review)
- uidump: content-desc="입장 대기\n5월 19일 (화) 22:27\n[QA] 스포츠 소셜 이벤트\n서울 강남" ✓ (checkInReady phase)
- uidump: content-desc="입장 QR 미리 보기" ✓, content-desc="길찾기" ✓

**spec엔 있는데 uidump에 없는 요소**
- "입장 QR 보기" → uidump에 "입장 QR 미리 보기"로 표시 (label 차이)
- 구매 내역 보기 / 이벤트 둘러보기 CTA (빈 상태 — 현재 활성 배너 있으므로 미표시)

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 1건 (spec: "입장 QR 보기" vs 화면: "입장 QR 미리 보기" label 차이)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
