# SearchRoute spec 비교
- spec: apps/mds/docs/public/specs/search_page.html
- 캡처 시각: 2026-05-10 10:04:00

## 발견

**① AppBar**
- spec: back · TextField · clear× 구조
- uidump: content-desc="뒤로" ✓, content-desc="검색어를 입력하세요" ✓

**② Body — 빠른 키워드 제안 (이런 키워드는 어때요?)**
- spec: "이런 키워드는 어때요?" + 제안 키워드 예시(파티, 클래스, 스포츠, 아트 등)
- uidump: content-desc="이런 키워드는 어때요?" ✓, content-desc="파티" ✓, content-desc="클래스" ✓, content-desc="스포츠" ✓, content-desc="아트" ✓

**spec엔 있는데 uidump에 없는 요소**
- 없음 (Empty 상태로 진입 — 정상)

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
