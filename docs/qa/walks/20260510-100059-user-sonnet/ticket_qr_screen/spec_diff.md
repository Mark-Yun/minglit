# TicketQRRoute spec 비교
- spec: apps/mds/docs/public/specs/ticket_qr_screen.html
- 캡처 시각: 2026-05-10 10:12:00

## 발견

**① AppBar — "내 티켓"**
- spec: h=56, "내 티켓" 제목
- uidump: content-desc="내 티켓" ✓, 뒤로 버튼 ✓

**② BoardingPassCard**
- spec: brand header · event info · perforation · QR stub
- uidump: QR 코드 영역이 android.view.View로 렌더링됨 (QR 이미지는 semantic 없음 — accessibility 미설정)
- 작은 View (504,1175)~(576,1247) 하나만 노출 — QR 이미지로 추정

**③ 입장 안내 / ④ 캡처 방지 안내**
- uidump에서 text/content-desc 없음 (시각적 텍스트이나 semantic 미설정)

**spec엔 있는데 uidump에 없는 요소**
- 입장 안내 텍스트 (③), 캡처 방지 안내 (④) — accessibility semantic 없음

**uidump엔 있는데 spec엔 없는 요소**
- 없음

차이 건수: 1건 (입장 안내/캡처 방지 안내 텍스트 accessibility semantic 누락)

## 비교 방식
spec html의 주요 섹션 텍스트 vs uidump의 text/content-desc
