# BlockedPartnersRoute spec 비교
- spec: apps/mds/docs/public/specs/blocked_partners_page.html
- 캡처 시각: 2026-05-10 10:28:00

## 발견

**① AppBar — "차단 목록"**
- uidump: content-desc="차단 목록" ✓

**② Body — 빈 상태**
- spec: 차단된 파트너 없을 때 빈 상태
- uidump: content-desc="차단된 파트너가 없습니다" ✓

**spec엔 있는데 uidump에 없는 요소**
- ③ ListTile (차단된 파트너가 없어 미표시 — 정상)
- "차단 해제" 버튼 (조건부 — 차단 파트너 없음)

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건 (빈 상태 정상 표시)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
