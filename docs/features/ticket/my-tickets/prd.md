# PRD: 내 티켓 (My Tickets)

## Summary

다가오는 이벤트 티켓을 시간순으로 확인하고 한 탭으로 입장 QR 에 접근하는 전용 화면을 제공한다. 기존 "구매 내역"과 역할을 분리해 입장 시점의 사용성을 강화한다.

## Motivation / Problem to Solve

- 현재 MyPage 의 "내 티켓" 메뉴가 잘못 연결되어 구매 내역 페이지로 이동 (버그)
- 구매 내역은 결제 이력 조회/환불 용도 — 입장 시점에 사용하기에는 정렬(최신 결제 순)과 필터(모든 상태) 부적합
- 유저가 입장 직전에 오늘 이벤트 QR 까지 도달하는 동선이 길고 모호
- 여러 티켓을 보유한 유저가 오늘 사용할 티켓을 시각적으로 구분하기 어려움

## Goals

### Target Users

- **이벤트 참가 직전 유저**: 입구에서 오늘 티켓 QR 을 빠르게 호출
- **다중 티켓 보유 유저**: 다가오는 이벤트를 시간순으로 한눈에 확인
- **참석 기록을 보고 싶은 유저**: 지난 이벤트를 회색 처리된 카드로 확인

### Key Goals

- **P0**: 유효 티켓(`paid`/`approved`)을 이벤트 시작 시각 기준으로 정렬 표시
- **P0**: 각 티켓 카드에서 한 탭으로 TicketQRScreen 진입
- **P0**: 오늘 이벤트가 있을 때 상단 D-Day 배너로 강조
- **P0**: 지난 이벤트 섹션을 회색 처리 + QR 버튼 비활성
- **P0**: MyPage 의 "내 티켓" 메뉴를 본 화면(`/tickets/my`)으로 정정
- **P1**: 빈 상태에서 "이벤트 둘러보기" CTA → 홈 진입
- **P1**: 카드 탭 시 EventDetailPage 이동

### Non-Goals

- Apple/Google Wallet 연동 — 별도 PR
- 오프라인 캐시 (네트워크 없을 때 카드 표시) — 향후 확장
- 티켓 양도/공유 — 별도 피처
- 환불/취소 액션 — 구매 내역에서 처리
- 검색/필터링 — 시간 정렬로 충분 (Open Q)

## Product Principles

1. **시간 기반 정렬**: 가장 임박한 이벤트가 최상단 — 입장 직전 사용성 최우선
2. **한 탭 QR**: 카드에서 바로 QR 화면 진입, 추가 탐색 단계 없음
3. **오늘 강조**: D-Day 배너로 현장 접근성 극대화
4. **지난 이벤트 보존**: 참석 기록은 muted 처리로 함께 노출 (별도 화면 안 만듦)

## Technical Approach

- **화면**: `MyTicketsPage` 신규 (`/tickets/my`), MyPage 메뉴 연결 정정, HomeCoordinator 메서드 추가
- **데이터**: `event_applications` JOIN `events`, `parties`, `locations`, `tickets` — 본인의 `paid`/`approved` 신청만
- **클라이언트 분리**: PostgREST 가 관계 테이블 정렬 미지원 → 클라이언트에서 upcoming/past 분리 + 정렬
- **재사용**: `TicketQRScreen`, `TicketWalletRepository`, `TicketToken`, `_StatusBadge`(공통화), `MinglitImage`, `MinglitAsyncValueWidget`
- **가드**: `/tickets/my` 는 protectedPrefixes 등록 — 인증 가드 자동 적용

## User Journey

### Scenario 1: 오늘 이벤트 입장 직전 (CUJ 1-x)

유저가 MyPage → 내 티켓 진입 → 상단 D-Day 배너의 "입장 QR" 탭 → TicketQRScreen.

### Scenario 2: 다가오는 이벤트 확인 (CUJ 2-x)

유저가 며칠 전 다가오는 이벤트 목록을 시간순으로 확인. 카드 탭 → 이벤트 상세 또는 "입장 QR" 버튼 → QR.

### Scenario 3: 지난 이벤트 확인 (CUJ 3-x)

유저가 스크롤로 지난 이벤트 섹션 확인 — 카드는 muted 처리, QR 버튼 없음. 카드 탭 → 이벤트 상세.

### Scenario 4: 빈 상태에서 이벤트 탐색 (CUJ 4-x)

티켓이 없는 유저 → 빈 상태 일러스트 + "이벤트 둘러보기" CTA → 홈 진입.

## Data Flow

### Scenario 1 / 2

MyPage → 내 티켓 탭 → `/tickets/my` → 본인의 `paid`/`approved` 신청 조회 (events JOIN) → 클라이언트에서 upcoming/past 분리 + 정렬 → 오늘 이벤트 감지 → 배너 노출 → 카드 "입장 QR" 탭 → TicketQRScreen(ticketId, eventMeta)

### Scenario 3

upcoming 아래에 past 섹션 표시 (시간 DESC, 최대 20개) → 카드 탭 → EventDetailPage

### Scenario 4

빈 상태 → "이벤트 둘러보기" → 홈 라우트(`/`)

## KPIs / Success Metrics

- **내 티켓 → QR 진입 전환율**: 다가오는 이벤트 보유 세션 중 QR 진입 비율 ≥ 50%
- **D-Day 배너 클릭률**: 오늘 이벤트 보유 세션 중 배너 탭 비율 ≥ 70%
- **MyPage → 내 티켓 진입율**: 메뉴 진입 전환 (정상 라우팅 검증)
- **빈 상태 CTA 전환율**: 빈 상태 노출 → 홈 이동 비율 (cold-start 유저 가이드 효과)

## Launch Strategy

- 단일 PR 로 출시 — MyPage 라우팅 버그 수정과 함께
- A/B 없음 — 기능 추가 + 기존 버그 정정 성격

## References

- **Eventbrite**: 전용 Tickets 탭 + Apple/Google Wallet 연동 (Wallet 은 V2)
- **NOL 티켓 (인터파크)**: 당일 퀵 배너 + 모바일 QR
- **Fever**: 앱+이메일 듀얼 QR + 전용 Tickets 섹션
