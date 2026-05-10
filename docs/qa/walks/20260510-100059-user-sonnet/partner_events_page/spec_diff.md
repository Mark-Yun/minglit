# PartnerEventsRoute spec 비교
- spec: apps/mds/docs/public/specs/partner_events_page.html
- 캡처 시각: 2026-05-10 10:34:00

## 발견

**① AppBar — "{partnerName} 이벤트"**
- spec: "{partnerName} 이벤트" 형식
- uidump: content-desc="밍글 스튜디오 이벤트" ✓

**② MinglitEventCard 목록**
- uidump: 이벤트 카드 목록 표시되나 accessibility semantic content-desc 없음 (화면에 카드는 보이나 uidump 내 description 없음)

**spec엔 있는데 uidump에 없는 요소**
- 이벤트 카드 개별 semantic 정보 (MinglitEventCard 텍스트)

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
