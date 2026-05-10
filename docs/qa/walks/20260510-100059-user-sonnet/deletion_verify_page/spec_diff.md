# DeletionVerifyRoute spec 비교
- spec: apps/mds/docs/public/specs/deletion_verify_page.html
- 캡처 시각: 2026-05-10 10:26:00

## 발견

**① AppBar — "본인 확인"**
- uidump: content-desc="본인 확인" ✓, 뒤로 ✓

**② 본문 — heading + sub copy**
- spec: "회원 탈퇴 전에 본인 확인이 필요해요." + 안내 문구
- uidump: content-desc="회원 탈퇴 전에 본인 확인이 필요해요." ✓
- uidump: content-desc="탈퇴 요청이 접수되면 7일 동안 복구할 수 있어요." ✓

**③ Bottom CTA — "탈퇴 요청"**
- uidump: content-desc="탈퇴 요청" ✓

**spec엔 있는데 uidump에 없는 요소**
- ㉡ reason recap (사유 선택 없이 진행 — 조건부 표시 안됨, 정상)
- ㉢ auth input (비밀번호 텍스트필드 또는 소셜 카드) — accessibility semantic 미설정

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건 (auth input semantic 누락은 spec 범위 외)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
