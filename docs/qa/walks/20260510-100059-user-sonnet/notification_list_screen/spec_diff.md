# NotificationCenterRoute spec 비교
- spec: apps/mds/docs/public/specs/notification_list_screen.html
- 캡처 시각: 2026-05-10 10:06:00

## 발견

**① AppBar — "알림 센터" + done_all action**
- spec: "알림 센터" 제목, done_all(모두 읽음) 액션 버튼
- uidump: content-desc="알림 센터" ✓, content-desc="모두 읽음" ✓

**빈 상태**
- uidump: content-desc="알림이 없습니다." — 알림 없는 빈 상태 표시

**spec엔 있는데 uidump에 없는 요소**
- 알림 타일 (② Tile #0~#2) — 현재 알림 없는 빈 상태이므로 미표시 (조건부)

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건 (빈 상태 정상 표시)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
