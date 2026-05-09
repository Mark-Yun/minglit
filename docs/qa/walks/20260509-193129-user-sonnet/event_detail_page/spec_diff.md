# EventDetailRoute spec 비교
- spec: apps/mds/docs/public/specs/event_detail_page.html
- 캡처 시각: 2026-05-09 19:52:00

## 발견

spec엔 있음 + uidump 확인:
- 뒤로가기: content-desc="뒤로" ✓
- 메뉴: content-desc="메뉴 표시" ✓
- 이미지 갤러리: content-desc="이미지 1 / 1" ✓
- 탭 5개: 기본 정보, 상세 소개, 참가 현황, 필요 인증, 환불 정책 ✓
- 파트너: content-desc="서울 강남 소셜클럽" ✓
- 이벤트 이름, 날짜, 장소 ✓
- 좋아요: content-desc="좋아요" ✓
- 공유하기: content-desc="공유하기" ✓
- 가격: content-desc="최저가 / 0원~" ✓

spec엔 있음 + uidump엔 없음:
- 신청 버튼: "이미 신청한 이벤트"로 표시 (이미 신청 상태이므로 정상 — 조건부)

uidump엔 있음 + spec엔 없음:
- 차이 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 0건
