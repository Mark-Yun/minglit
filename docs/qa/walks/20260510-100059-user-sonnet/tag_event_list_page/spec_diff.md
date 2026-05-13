# TagEventListRoute spec 비교
- spec: apps/mds/docs/public/specs/tag_event_list_page.html
- 캡처 시각: 2026-05-10 10:36:00

## 발견

**① AppBar — "#{tagName}"**
- spec: centerTitle "#{tagName}"
- uidump: content-desc="#20대" ✓

**Empty 상태**
- spec: "홈으로 돌아가기" CTA 포함
- uidump: content-desc="아직 이 태그의 이벤트가 없어요" ✓, content-desc="홈으로 돌아가기" ✓

**spec엔 있는데 uidump에 없는 요소**
- MinglitEventCard (이벤트 없어 빈 상태 — 정상)

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건 (빈 상태 정상 표시)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
