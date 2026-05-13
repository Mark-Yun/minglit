# MyPageRoute spec 비교
- spec: apps/mds/docs/public/specs/my_page.html
- 캡처 시각: 2026-05-10 10:08:00

## 발견

**① AppBar — "마이페이지"**
- uidump: content-desc="마이페이지" ✓

**② ProfileGroup — avatar + name + email**
- spec: 아바타 + 이름 + 이메일 표시
- uidump: content-desc="유저\nqa_fresh@test.com" ✓

**③ ActivityGroup — 구매 내역 / 내 티켓**
- spec: "구매 내역" ✓, "내 티켓" ✓
- uidump: content-desc="활동" (그룹 헤더) ✓, content-desc="구매 내역" ✓, content-desc="내 티켓" ✓

**④ SettingsGroup — 알림 / 테마**
- spec: "알림 설정" ✓, "테마 설정" (표기: 테마)
- uidump: content-desc="설정" (그룹 헤더) ✓, content-desc="알림 설정" ✓, content-desc="테마\n시스템 설정" ✓

**⑤ PrivacyGroup — 개인정보 / 권한 / 차단**
- spec: "개인정보" ✓, "권한 설정" ✓, "차단 목록" ✓
- uidump: content-desc="개인정보 및 보안" (그룹 헤더), content-desc="개인정보" ✓, content-desc="권한 설정" ✓, content-desc="차단 목록" ✓

**spec엔 있는데 uidump에 없는 요소**
- 앱 버전 (26.04.x-dev) — 화면 스크롤 필요할 수 있음 또는 현재 미표시
- 이용약관, 개인정보처리방침

**uidump엔 있는데 spec엔 없는 요소**
- content-desc="개인정보 및 보안" (그룹 헤더 — spec은 "PrivacyGroup"으로 설명)

차이 건수: 1건 (앱 버전, 이용약관 등 하단 항목 uidump 미확인 — 스크롤 필요)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
