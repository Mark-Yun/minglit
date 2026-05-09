# SearchRoute spec 비교
- spec: apps/mds/docs/public/specs/search_page.html
- 캡처 시각: 2026-05-09 19:38:00

## 발견

spec엔 있음 + uidump 확인:
- 검색어 입력 필드: content-desc="검색어를 입력하세요" ✓
- 추천 키워드 섹션: content-desc="이런 키워드는 어때요?" ✓
- 추천 키워드 칩: 파티, 클래스, 스포츠, 아트 ✓
- 뒤로가기: content-desc="뒤로" ✓

spec엔 있음 + uidump엔 없음:
- 최근 검색어 섹션: 없음 (초기 상태에서 검색 기록 없을 수 있음 — 조건부)
- 검색 결과 EventCard: 없음 (검색어 입력 전 상태 — 조건부)

uidump엔 있음 + spec엔 없음:
- 차이 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc/text 매칭

## 차이 건수: 0건 (조건부 항목 제외)
