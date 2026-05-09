# MyPageRoute spec 비교
- spec: apps/mds/docs/public/specs/my_page.html
- 캡처 시각: 2026-05-09 19:43:00

## 발견

spec엔 있음 + uidump 확인:
- 마이페이지 헤더: content-desc="마이페이지" ✓
- 유저 프로필: content-desc="유저 / user_18_f_강남@test.com" ✓
- 활동 섹션: content-desc="활동" ✓
- 구매 내역: content-desc="구매 내역" ✓
- 내 티켓: content-desc="내 티켓" ✓
- 알림 설정: content-desc="알림 설정" ✓
- 테마: content-desc="테마/시스템 설정" ✓
- 개인정보: content-desc="개인정보" ✓
- 차단 목록: content-desc="차단 목록" ✓

spec엔 있음 + uidump엔 없음:
- 로그아웃: content-desc에 없음 (스크롤 필요 또는 아래에 위치)
- 프로필 편집 버튼: 별도 content-desc 없음

uidump엔 있음 + spec엔 없음:
- content-desc="권한 설정": spec에 명시적 언급 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 2건
