# PrivacyRoute spec 비교
- spec: apps/mds/docs/public/specs/privacy_page.html
- 캡처 시각: 2026-05-09 19:48:00

## 발견

spec엔 있음 + uidump 확인:
- 개인정보 제목: content-desc="개인정보" ✓
- 뒤로가기: content-desc="뒤로" ✓
- 동의 현황: content-desc="동의 현황" ✓
- 서비스 이용약관: content-desc="서비스 이용약관/동의됨" ✓
- 개인정보 수집·이용: content-desc="개인정보 수집·이용/동의됨" ✓
- 마케팅 정보 수신: content-desc="마케팅 정보 수신" ✓
- 위치정보 이용 동의: content-desc="위치정보 이용 동의" ✓
- 약관 보기 섹션: content-desc="약관 보기" ✓
- 서비스 이용약관, 개인정보처리방침, 위치정보 이용약관 ✓

spec엔 있음 + uidump엔 없음:
- 계정 삭제(탈퇴) 버튼: 스크롤 필요할 수 있음

uidump엔 있음 + spec엔 없음:
- 본인인증 정보/동의됨: spec에 별도 언급 없음

## 비교 방식
spec html 텍스트 추출 vs uidump content-desc 매칭

## 차이 건수: 1건
