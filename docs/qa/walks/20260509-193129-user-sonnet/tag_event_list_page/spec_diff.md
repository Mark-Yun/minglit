# TagEventListRoute spec 비교
- spec: apps/mds/docs/public/specs/tag_event_list_page.html
- 캡처 시각: 2026-05-09 19:59:00

## 발견

spec엔 있음 + uidump 확인:
- 태그 제목: content-desc="#20대" ✓
- 뒤로가기: content-desc="뒤로" ✓
- 빈 상태 텍스트: content-desc="아직 이 태그의 이벤트가 없어요" ✓
- 홈으로 돌아가기 CTA: content-desc="홈으로 돌아가기" ✓

spec엔 있음 + uidump엔 없음:
- 이벤트 카드: 없음 (태그에 이벤트 없는 상태 — 조건부)

uidump엔 있음 + spec엔 없음:
- 차이 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 0건 (빈 상태 정상)
