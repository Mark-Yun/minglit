# BlockedPartnersRoute spec 비교
- spec: apps/mds/docs/public/specs/blocked_partners_page.html
- 캡처 시각: 2026-05-09 19:50:00

## 발견

spec엔 있음 + uidump 확인:
- 차단 목록 제목: content-desc="차단 목록" ✓
- 뒤로가기: content-desc="뒤로" ✓
- 빈 상태: content-desc="차단된 파트너가 없습니다" ✓

spec엔 있음 + uidump엔 없음:
- 차단 항목 (빈 상태이므로 없음 — 조건부)

uidump엔 있음 + spec엔 없음:
- 차이 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 0건 (빈 상태 정상)
