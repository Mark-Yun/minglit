# PrivacyRoute spec 비교
- spec: apps/mds/docs/public/specs/privacy_page.html
- 캡처 시각: 2026-05-10 10:20:00

## 발견

**① AppBar — "개인정보"**
- uidump: content-desc="개인정보" ✓, 뒤로 ✓

**② "동의 현황" header**
- uidump: content-desc="동의 현황" ✓

**③ 6 tile (동의 항목들)**
- spec: 서비스 이용약관(read-only) ✓, 개인정보 수집·이용(read-only) ✓, 제3자 제공 동의 ✓, 마케팅 정보 수신 ✓, 위치정보 이용 동의 ✓, 본인인증 정보(read-only) ✓
- uidump: 모두 일치 ✓

**④ "약관 보기" header**
- uidump: content-desc="약관 보기" ✓

**⑤ 3 tile (약관 링크)**
- spec: 서비스 이용약관 ✓, 개인정보처리방침 ✓, 위치정보 이용약관 ✓
- uidump: content-desc="서비스 이용약관" ✓, content-desc="개인정보처리방침" ✓, content-desc="위치정보 이용약관" ✓

**spec엔 있는데 uidump에 없는 요소**
- 없음

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
