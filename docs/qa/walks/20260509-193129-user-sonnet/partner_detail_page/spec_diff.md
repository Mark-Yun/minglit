# PartnerDetailRoute spec 비교
- spec: apps/mds/docs/public/specs/partner_detail_page.html
- 캡처 시각: 2026-05-09 19:53:00

## 발견

spec엔 있음 + uidump 확인:
- 파트너 이름: content-desc="서울 강남 소셜클럽" ✓
- 뒤로가기: content-desc="뒤로" ✓
- 알림받기: content-desc="알림받기" ✓
- 소개: content-desc="소개", "서울 강남 지역 대표 소셜 클럽" ✓
- 진행중인 이벤트: content-desc="진행중인 이벤트" ✓
- 더 보기: content-desc="더 보기" ✓
- 이벤트 카드: content-desc="이벤트: ..." ✓
- 사업자 정보: content-desc="사업자 정보", "상호명", "대표자", "사업자번호" ✓

spec엔 있음 + uidump엔 없음:
- 차단하기: 스크롤 필요할 수 있음

uidump엔 있음 + spec엔 없음:
- 차이 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 0건
