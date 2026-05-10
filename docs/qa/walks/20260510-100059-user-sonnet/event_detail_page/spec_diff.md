# EventDetailRoute spec 비교
- spec: apps/mds/docs/public/specs/event_detail_page.html
- 캡처 시각: 2026-05-10 10:30:00

## 발견

**① Hero image**
- uidump: content-desc="이미지 1 / 1" ✓

**② Pinned TabBar — 5개 탭**
- spec: 기본 정보, 상세 소개, 참가 현황, 필요 인증, 환불 정책 (5개)
- uidump: "기본 정보\n탭 5개 중 1번째" ✓, "상세 소개\n탭 5개 중 2번째" ✓, "참가 현황\n탭 5개 중 3번째" ✓, "필요 인증\n탭 5개 중 4번째" ✓, "환불 정책\n탭 5개 중 5번째" ✓

**③ 기본 정보 섹션**
- uidump: content-desc="[QA] 스포츠 소셜 모임" ✓, content-desc="5월 19일 (화) 22:27" ✓, content-desc="서울 강남" ✓, content-desc="좋아요" ✓, content-desc="공유하기" ✓
- uidump: 파트너명 "밍글 스튜디오" ✓

**⑥ BottomTicketBar**
- spec: 구매하기 / 이미 신청한 이벤트 등 6 state
- uidump: content-desc="이미 신청한 이벤트" ✓

**AppBar**
- spec: 뒤로, 메뉴(공유/신고 등)
- uidump: content-desc="뒤로" ✓, content-desc="메뉴 표시" ✓

**spec엔 있는데 uidump에 없는 요소**
- 환불 정책 상세 (스크롤 필요)
- 참가 현황 Entry group card (다른 탭)

**uidump엔 있는데 spec엔 없는 요소**
- content-desc="3시간 진행" (진행 시간 — spec에 직접 언급 없음)
- content-desc="최저가" + "0원~"

차이 건수: 1건 ("3시간 진행", "최저가" 표기 — spec에서 직접 확인 필요)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
