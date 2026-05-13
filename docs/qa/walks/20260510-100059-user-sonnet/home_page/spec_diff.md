# HomeRoute spec 비교
- spec: apps/mds/docs/public/specs/home_page.html
- 캡처 시각: 2026-05-10 10:02:00

## 발견

spec 정의 요소 vs uidump 매칭:

**AppBar (㉡ Actions — 40×40 IconButton × 3)**
- spec: 검색, 알림, 아바타(마이페이지) 3개 아이콘
- uidump: content-desc="검색" ✓, content-desc="알림" ✓, content-desc="마이페이지" ✓
- uidump 추가 발견: content-desc="Bug Report" (spec에 없음)

**② ExploreFilterChipBar — Sort chips (추천순, 마감임박, 가까운날짜, 가까운 거리)**
- spec: 추천순 ✓, 마감임박 ✓, 가까운날짜 ✓, 가까운 거리 ✓ — 모두 일치

**③ FeaturedTagChipBar**
- spec: 태그 칩 예시 (#루프탑파티, #보드게임, #소규모, #아트, #야외, #와인)
- uidump: #20대, #30대, #공연, #네트워킹, #대규모, #독서 (동적 데이터 — spec 예시와 다름, 데이터 의존적)

**④ SliverList — MinglitEventCard**
- uidump: 이벤트 카드 2개 표시 ("[QA] 스포츠 소셜 모임", "[QA] 아트 & 문화 이벤트")
- spec: event card 구조 (이미지 2:1, 제목, 메타, 태그칩) 정의됨 — 동적 데이터

**spec엔 있는데 uidump에 없는 요소**
- ⑤ EventNowBar (bottomSheet 64px) — 현재 진행 중인 이벤트 없어서 미표시 (조건부 위젯)

**uidump엔 있는데 spec엔 없는 요소**
- content-desc="Bug Report" 버튼 (debug 빌드 전용 개발 도구로 추정)

차이 건수: 2건 (Bug Report 버튼, EventNowBar 미표시)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
