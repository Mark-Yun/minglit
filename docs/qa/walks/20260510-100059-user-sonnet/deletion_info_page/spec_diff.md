# DeletionInfoRoute spec 비교
- spec: apps/mds/docs/public/specs/deletion_info_page.html
- 캡처 시각: 2026-05-10 10:24:00

## 발견

**① AppBar — "탈퇴 전 확인"**
- uidump: content-desc="탈퇴 전 확인" ✓, 뒤로 ✓

**③ Bottom CTA — "계속 진행"**
- uidump: content-desc="계속 진행" ✓

**spec엔 있는데 uidump에 없는 요소**
- 삭제되는 정보 Card (㉡), 법정 보존 정보 Card (㉢), 유예 기간 안내 (㉣) — 화면에 있으나 accessibility semantic 없어 uidump에 미표시
- 선택한 탈퇴 사유 chip-card (㉠) — 사유 선택 없이 진행하여 미표시 (조건부)

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 1건 (본문 카드들 accessibility semantic 미설정)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
