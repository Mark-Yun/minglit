# 내 티켓 (My Tickets) 스펙

## 개요

**핵심 원칙**: 내 티켓은 "다가올 이벤트를 시간순으로 빠르게 확인하고 입장 준비를 하는 화면"이다. 구매내역(전체 결제 기록)과 명확히 분리한다.

**현재 문제** (Issue #576):
- 마이페이지의 "내 티켓" 메뉴가 `pushPurchaseHistory`를 호출하여 구매내역과 동일하게 동작
- `/tickets/my` 경로에 guard는 존재하지만 라우트가 미정의 상태
- 유저가 다가올 이벤트 티켓을 빠르게 찾을 수 없음

**참고 패턴**:
- Eventbrite: Upcoming/Past 탭 분리, 가까운 이벤트 순 정렬, QR 즉시 접근
- 프립(Frip): 예약 내역에서 "예정된 체험" 우선 표시, 날짜 카운트다운
- 소모임: 참여 예정 모임을 별도 섹션으로 분리, D-day 배지

## 구매내역 vs 내 티켓 역할 분리

| 항목 | 구매내역 (`/purchase-history`) | 내 티켓 (`/tickets/my`) |
|------|-------------------------------|------------------------|
| 목적 | 전체 결제/환불 이력 조회 | 다가올 이벤트 빠른 확인 + 입장 준비 |
| 데이터 범위 | 모든 EventApplication (과거 포함) | 활성 티켓만 (paid/approved + 이벤트 미종료) |
| 정렬 | 결제일 내림차순 (최신 먼저) | 이벤트 시작시간 오름차순 (가까운 먼저) |
| 주요 액션 | 영수증, 문의, 예매취소 | QR 보기, 이벤트 상세, 길찾기 |
| 빈 상태 | "구매 내역이 없습니다" | "예정된 이벤트가 없습니다" + 이벤트 탐색 CTA |

## 구성 요소

### 1. AppBar
- 제목: "내 티켓"
- 스타일: `MinglitTheme.simpleAppBar` (고정, 뒤로가기 자동)

### 2. 티켓 카드 (위→아래)

각 활성 티켓을 카드로 표시. 카드 구조:

```
┌─────────────────────────────────────┐
│ [D-day 배지]              [상태 칩] │
│                                     │
│ [이벤트 이미지 80x80] [이벤트명]    │
│                       [날짜/시간]   │
│                       [장소명]      │
├─────────────────────────────────────┤
│ [티켓명]              [QR 보기 →]   │
└─────────────────────────────────────┘
```

#### 2.1 D-day 배지
- D-day: `primary` 배경, 흰색 텍스트 "오늘!"
- D-1~D-3: `secondary` 배경, "D-N"
- D-4 이상: `textSecondary` 색상, "M월 D일"

#### 2.2 상태 칩
- `paid`: "결제완료" — `success` 색상
- `approved`: "승인완료" — `primary` 색상

#### 2.3 이벤트 정보
- 이미지: 80x80, `MinglitRadius.small` (8px) 라운딩
- 이벤트명: `titleMedium` (16px, bold), 1줄 ellipsis
- 날짜/시간: `bodySmall` (13px), "M월 d일 (요일) HH:mm" 형식
- 장소: `bodySmall`, `onSurfaceVariant` 색상

#### 2.4 하단 액션 영역
- 티켓명: `bodyMedium`
- QR 보기 버튼: `TextButton` + `Icons.qr_code` 아이콘, primary 색상

### 3. 카드 탭 동작
- 카드 전체 영역 탭 → 이벤트 상세 (`/events/:eventId`)로 이동
- QR 보기 버튼 → `TicketQRScreen`으로 이동 (기존 구현 활용)

### 4. 빈 상태
- 아이콘: `Icons.confirmation_number_outlined`, `MinglitIconSize.xlarge` (32px)
- 제목: "예정된 이벤트가 없습니다"
- 설명: "이벤트에 참여하면 여기서 티켓을 확인할 수 있어요"
- CTA: `OutlinedButton` "이벤트 둘러보기" → 홈(`/`)으로 이동

### 5. 에러 상태
- `MinglitAsyncValueWidget` 기본 에러 UI 사용

### 6. 로딩 상태
- `MinglitAsyncValueWidget` 기본 로딩 UI 사용

## 데이터 소스

### 기존 활용
- `EventRepository.getMyPurchaseHistory(userId)` — 전체 application 목록 조회
- `PurchaseHistoryController.isActiveTicket(application)` — `paid`/`approved` 필터링 로직
- `TicketWalletRepository.getTicket(ticketId)` — QR 표시용 토큰 조회
- `TicketCoordinator.pushEventDetail(eventId)` — 이벤트 상세 이동

### 신규 필요
- `MyTicketsController` (Riverpod AsyncNotifier):
  - `getMyPurchaseHistory()` 결과에서 활성 티켓만 필터링
  - 이벤트 미종료 (`event.endTime > now`) 조건 추가
  - `event.startTime` 오름차순 정렬 (가까운 이벤트 먼저)
  - D-day 계산 유틸리티

## 라우트 변경

### 신규 라우트
| Route | Path | Page | 비고 |
|-------|------|------|------|
| `MyTicketsRoute` | `/tickets/my` | `MyTicketsPage` | 보호됨 (기존 guard 활용) |

### 기존 변경
- `my_page.dart:113`: `homeCoordinator.pushPurchaseHistory` → `homeCoordinator.pushMyTickets` 로 변경
- `HomeCoordinator`에 `pushMyTickets()` 메서드 추가
- `app_routes.dart`에 `MyTicketsRoute` TypedGoRoute 추가

## 에러/로딩 상태

| 섹션 | 로딩 | 에러 | 빈 상태 |
|------|------|------|---------|
| 티켓 목록 | MinglitAsyncValueWidget 기본 | MinglitAsyncValueWidget 기본 (재시도 버튼) | 빈 상태 화면 + CTA |

## 구현 이슈 분할 (예상)

| # | 제목 | 의존성 | 예상 크기 |
|---|------|--------|----------|
| 1 | `MyTicketsController` 구현 — 활성 티켓 필터링 + 정렬 로직 | 없음 | S |
| 2 | `MyTicketsPage` UI 구현 — 티켓 카드 + 빈 상태 | #1 | M |
| 3 | `MyTicketsRoute` 라우트 등록 + Coordinator 연결 | #2 | S |
| 4 | `my_page.dart` "내 티켓" 메뉴 핸들러 수정 | #3 | XS |
| 5 | 위젯 테스트 — MyTicketsPage, MyTicketsController | #2 | S |
