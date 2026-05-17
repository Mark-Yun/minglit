# PRD: 티켓 QR Boarding Pass 리디자인 (Ticket QR Improvement)

## Summary

티켓 QR 화면을 흰 배경 + QR 코드 단일 구성에서 **항공 보딩패스 오마주 카드**로 재설계해, 이벤트 입장 직전의 감성과 맥락 정보(이벤트명/일시/장소/상태)를 함께 제공한다.

## Motivation / Problem to Solve

- 현재 QR 화면은 흰 배경에 QR 만 노출 — 어떤 이벤트의 티켓인지 맥락 정보 부재
- 여러 티켓 보유 유저가 오늘 사용할 티켓을 시각적으로 구분하기 어려움
- 입장이라는 "특별한 순간"의 감성/브랜드 자산 결여 — SNS 공유 가치 낮음
- 파트너가 스캔 전 시각적 1차 확인 어려움(올바른 이벤트 티켓인지)
- 위조 방지 안내(스크린샷 무효) 부재

## Goals

### Target Users

- **첫 이벤트 참가자**: 입구에서 "이게 맞는 티켓인지" 즉시 확인하고 자신 있게 제시
- **이벤트 단골 유저**: 여러 티켓 중 오늘 것을 빠르게 식별
- **SNS 공유 유저**: 보딩패스 디자인을 인스타 등에 공유
- **파트너 입구 직원**: 스캔 전 이벤트명/상태로 시각 1차 확인

### Key Goals

- **P0**: 보딩패스 카드 레이아웃 (헤더 + 이벤트 정보 + 절취선 + QR stub)
- **P0**: 이벤트명/일시/장소를 QR 와 함께 표시 (맥락 정보)
- **P0**: 상태 배지 (오늘: BOARDING / 미래: CONFIRMED / 과거: USED)
- **P0**: 위조 방지 안내 ("스크린샷은 입장에 사용할 수 없습니다")
- **P1**: 절취선 디테일(반원 노치 + dashed)로 물리적 티켓 감각
- **P1**: 헤더 brand gradient + 로고
- **P2**: 헤더 shimmer 애니메이션, QR 중앙 로고 오버레이

### Non-Goals

- Apple Wallet / Google Wallet 연동 (별도 PR)
- 이벤트 아트워크 통합 (Dice 패턴) — V2
- QR 스캔 로직 변경 — 기존 `TicketTokenService` 유지
- 티켓 양도/공유 — 별도 피처
- 다국어 — 현재 한국어 기준

## Product Principles

1. **진짜 티켓 느낌**: 화면 안의 UI 가 아닌 손에 든 입장권처럼
2. **입장 승인 감성**: 항공 게이트 통과 경험을 디지털로 오마주
3. **맥락 우선**: QR 만이 아닌 이벤트명/일시/장소를 즉시 확인 가능
4. **브랜드 일관성**: 밍글릿 primary gradient + 로고로 정체성 강화

## Technical Approach

- **화면**: 기존 `TicketQRScreen(ticketId)` 라우트 유지. 내부 위젯을 `BoardingPassCard` 로 교체
- **위젯**: `BoardingPassCard` (헤더 + 이벤트 정보 + 절취선 + QR stub), `PerforationClipper` (커스텀 페인터)
- **데이터**: 기존 `TicketTokenService.getToken(ticketId)` 유지 + 이벤트 메타(`eventTitle`, `startTime`, `venue`, `ticketType`) 추가 주입
- **상태 분기**: `event.startTime` 비교로 오늘/미래/과거 판정 → 상태 배지 + opacity 분기
- **외부 의존성**: `qr_flutter`(기존), brand SVG 로고
- **가드**: 없음 — UI 리디자인만

## User Journey

### Scenario 1: 오늘 이벤트 입장 (CUJ 1-x)

유저가 내 티켓 → 입장 QR 탭 → BOARDING 배지 + 이벤트 정보가 보이는 보딩패스 카드 표시 → 파트너에게 화면 제시 → 입장.

### Scenario 2: 미래 이벤트 미리 확인 (CUJ 2-x)

유저가 며칠 전 미리 확인 → CONFIRMED 배지 + 이벤트명/일시/장소 확인.

### Scenario 3: 지난 이벤트 기록 (CUJ 3-x)

유저가 지난 티켓 진입 → 카드 opacity 다운 + USED 배지 + QR 스캔 라인 비활성.

## Data Flow

### Scenario 1 / 2

내 티켓 → 카드 "입장 QR" 탭 → `TicketQRScreen(ticketId, eventMeta)` → `TicketTokenService.getToken(ticketId)` → QR 인코딩 + 보딩패스 카드 렌더링 → `event.startTime` 비교 → 상태 배지/스캔 라인 분기

### Scenario 3

지난 이벤트 카드는 QR 버튼 비노출이 디폴트. 직접 라우트 진입 시 USED 상태로 표시.

## KPIs / Success Metrics

- **입장 QR 진입 → 카드 first paint**: 500ms 이내 (NFR 측정)
- **유저 만족도**: 인앱 피드백/스토어 리뷰에서 "QR 화면" 멘션 긍정 비율
- **SNS 자발 공유**: "#밍글릿" 해시태그 카드 공유 빈도 (정성 트래킹)
- **파트너 스캔 오류율**: 잘못된 이벤트 QR 제시 → 스캔 거부 비율 감소

## Launch Strategy

- Phase 1: P0 항목 모두 (카드 레이아웃 + 상태 배지 + 위조 방지)
- Phase 2: P1 (절취선 + brand gradient)
- Phase 3: P2 (shimmer, 중앙 로고)

## References

- **대한항공/아시아나 보딩패스**: 헤더 바, 격자형 정보 레이아웃, 절취선
- **Apple Wallet 패스**: 세로형 카드, 상단 로고 스트립, 하단 바코드 영역
- **Eventbrite / Dice**: QR 중심 + 이벤트 메타 통합
- **Airbnb Experiences**: 예약 확인서 카드 스타일
