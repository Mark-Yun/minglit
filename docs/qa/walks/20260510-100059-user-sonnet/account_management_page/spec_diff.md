# AccountManagementRoute spec 비교
- spec: apps/mds/docs/public/specs/account_management_page.html
- 캡처 시각: 2026-05-10 10:18:00

## 발견

**① AppBar — "계정 관리"**
- uidump: content-desc="계정 관리" ✓, 뒤로 ✓

**② ProfileCard + 본인인증**
- spec: 본인인증 상태 표시
- uidump: content-desc="본인인증\n인증 완료" ✓

**③ "계정 관리" group header**
- uidump: content-desc="계정 관리" ✓

**④ DangerCard — 로그아웃 + 회원 탈퇴**
- uidump: content-desc="로그아웃" ✓, content-desc="회원 탈퇴" ✓

**spec엔 있는데 uidump에 없는 요소**
- 없음

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
