# EventApplicationRoute spec 비교
- spec: apps/mds/docs/public/specs/event_application_wizard_page.html
- 캡처 시각: 2026-05-09 19:57:00

## 발견

spec엔 있음 + uidump 확인:
- 티켓 선택 제목: content-desc="티켓 선택" ✓
- 추천 티켓 섹션: content-desc="추천 티켓" ✓
- 티켓 항목: content-desc="일반 참가권/0원/추천" ✓
- 수량: content-desc="수량" ✓
- 총 결제 금액: content-desc="총 결제 금액", "0원" ✓
- 다음 버튼: content-desc="다음" ✓

spec엔 있음 + uidump엔 없음:
- 차이 없음

uidump엔 있음 + spec엔 없음:
- content-desc="스크림": 배경 레이어 요소

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 0건
