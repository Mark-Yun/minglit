# NotificationCenterRoute spec 비교
- spec: apps/mds/docs/public/specs/notification_list_screen.html
- 캡처 시각: 2026-05-09 19:51:00

## 발견

spec엔 있음 + uidump 확인:
- 알림 센터 제목: content-desc="알림 센터" ✓
- 뒤로가기: content-desc="뒤로" ✓
- 모두 읽음 버튼: content-desc="모두 읽음" ✓
- 빈 상태: content-desc="알림이 없습니다." ✓

spec엔 있음 + uidump엔 없음:
- 알림 항목: 없음 (알림 없는 상태 — 조건부)

uidump엔 있음 + spec엔 없음:
- 차이 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 0건 (빈 상태 정상)
