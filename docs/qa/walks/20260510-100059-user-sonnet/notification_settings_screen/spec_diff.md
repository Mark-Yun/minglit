# NotificationSettingsRoute spec 비교
- spec: apps/mds/docs/public/specs/notification_settings_screen.html
- 캡처 시각: 2026-05-10 10:16:00

## 발견

**① AppBar — "알림 설정"**
- uidump: content-desc="알림 설정" ✓

**② SwitchListTile #1 — 서비스 알림**
- spec: "서비스 알림" 토글
- uidump: content-desc="서비스 알림\n예약, 매칭 등 서비스 이용에 필수적인 알림을 받습니다." ✓

**④ SwitchListTile #2 — 마케팅 정보 수신 동의**
- spec: "마케팅 정보 수신 동의" 토글
- uidump: content-desc="마케팅 정보 수신 동의\n이벤트, 할인 혜택 등 유용한 소식을 받습니다." ✓

**spec엔 있는데 uidump에 없는 요소**
- 없음

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
