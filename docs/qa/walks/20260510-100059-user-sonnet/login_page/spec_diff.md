# LoginRoute spec 비교
- spec: apps/mds/docs/public/specs/login_page.html
- 캡처 시각: 2026-05-10 10:40:00

## 발견

**② Brand block**
- spec: 로고 영역
- uidump: content-desc="Verified Vibe, Spark Your Moment" ✓ (브랜드 슬로건)

**④ Button group**
- spec: Google로 시작하기, Kakao로 시작하기, Apple로 시작하기 3개 버튼
- uidump: content-desc="Google로 시작하기" ✓, content-desc="Kakao로 시작하기" ✓
- spec에 있는 "Apple로 시작하기" → uidump에 없음

**⑤ Terms**
- spec: "로그인 시 " + 이용약관 + " 및 " + 개인정보처리방침 + "에 동의하게 됩니다."
- uidump: 모두 일치 ✓

**spec엔 있는데 uidump에 없는 요소**
- "Apple로 시작하기" 버튼 — Android 버전에서 미표시 (iOS 전용으로 추정, 정상)
- "파트너 입점 문의" — uidump에서 미확인

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 1건 (Apple 로그인 버튼 미표시 — Android 대상)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
