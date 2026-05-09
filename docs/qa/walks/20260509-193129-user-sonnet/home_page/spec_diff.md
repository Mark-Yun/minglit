# HomeRoute spec 비교
- spec: apps/mds/docs/public/specs/home_page.html
- 캡처 시각: 2026-05-09 19:37:00

## 발견

spec엔 있음 + uidump:
- SliverAppBar: 있음 (Bug Report fab, 검색 icon 확인)
- ExploreFilterChipBar: 추천순, 마감임박, 가까운날짜, 가까운 거리 — 모두 확인
- FeaturedTagChipBar: uidump text/content-desc에 별도 태그칩 없음 (spec엔 "hidden if empty" — 조건부이므로 차이 없음)
- EventNowBar: uidump에 content-desc 없음 — 현재 active event 없거나 hidden 상태 (spec: "visible when active events > 0" — 조건부)
- MinglitEventCard: 이벤트 카드 3개 확인 (content-desc="이벤트: ...")
- BugReportFab: content-desc="Bug Report" 확인

spec엔 있음 + uidump엔 없음:
- 알림(notifications) icon: spec엔 authenticated state에 알림 아이콘 명시, uidump에 content-desc="알림" 없음 (로그인 상태 여부 불명확)

uidump엔 있음 + spec엔 없음:
- content-desc="마이페이지": spec엔 CircleAvatar/person_outline으로 기술, "마이페이지" 라벨은 미기재

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc/text 매칭

## 차이 건수: 2건
