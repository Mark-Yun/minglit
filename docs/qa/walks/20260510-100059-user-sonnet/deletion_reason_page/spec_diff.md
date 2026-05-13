# DeletionReasonRoute spec 비교
- spec: apps/mds/docs/public/specs/deletion_reason_page.html
- 캡처 시각: 2026-05-10 10:22:00

## 발견

**① AppBar — "탈퇴 사유"**
- uidump: content-desc="탈퇴 사유" ✓, 뒤로 ✓

**② heading + sub copy**
- spec: heading + sub copy (떠나시는 이유)
- uidump: content-desc="떠나시는 이유를 알려주시면 더 나은 밍릿을 만드는 데 도움이 돼요." ✓
- uidump: content-desc="선택하지 않고 계속 진행해도 괜찮아요." ✓

**② 사유 카드 6개**
- spec: 6개 옵션 (항상 동일)
- uidump: "더 이상 쓰지 않아요" ✓, "원하는 이벤트가 없어요" ✓, "다른 서비스를 이용 중이에요" ✓, "개인정보가 걱정돼요" ✓
- uidump에 4개만 보임 — 나머지 2개는 스크롤 아래 있을 수 있음

**③ Bottom CTA**
- spec: "선택하지 않고 계속하기" + "다음" 버튼
- uidump: content-desc="선택하지 않고 계속하기" ✓, content-desc="다음" ✓

**spec엔 있는데 uidump에 없는 요소**
- 사유 카드 2개 미확인 (스크롤 필요)

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건 (스크롤 외 구조 일치)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
