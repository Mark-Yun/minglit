# PartnerDetailRoute spec 비교
- spec: apps/mds/docs/public/specs/partner_detail_page.html
- 캡처 시각: 2026-05-10 10:32:00

## 발견

**⓪ AppBar — partner.name**
- spec: centerTitle: partner.name
- uidump: content-desc="밍글 스튜디오" ✓

**① Header Row**
- uidump: content-desc="알림받기" ✓

**② 소개 (MinglitSection)**
- spec: 소개 섹션
- uidump: content-desc="소개" ✓, content-desc="서울 강남에서 운영하는 프리미엄 소셜 라운지" ✓

**③ 진행중인 이벤트**
- uidump: content-desc="진행중인 이벤트" ✓, content-desc="더 보기" ✓

**④ 사업자 정보**
- spec: 상호명, 대표자, 사업자번호 (label+value)
- uidump: content-desc="사업자 정보" ✓, content-desc="상호명" ✓, content-desc="(주)밍글스튜디오" ✓, content-desc="대표자" ✓, content-desc="-" ✓, content-desc="사업자번호" ✓, content-desc="123-45-67890" ✓

**spec엔 있는데 uidump에 없는 요소**
- ⑤ 연락처 섹션 — 스크롤 아래 있거나 미표시

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 0건

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
