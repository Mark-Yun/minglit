# 내 티켓 (My Tickets) — 기술 설계

## 개요

기존 "구매 내역"에서 **활성 티켓 조회 + QR 입장** 역할을 분리하여 전용 "내 티켓" 화면을 신설한다.
데이터 소스(`getMyPurchaseHistory`)를 재활용하되, 활성 티켓만 필터링하는 전용 쿼리를 추가하여 불필요한 데이터 전송을 줄인다.

## 구현 이슈 분할

| 순서 | 제목 | 라벨 | 의존성 | 비고 |
|------|------|------|--------|------|
| 1 | `getMyTickets()` Repository 메서드 추가 | `enhancement` | 없음 | DB 레벨 status 필터링 |
| 2 | `StatusBadge` 공유 위젯 추출 | `refactor` | 없음 | `_StatusBadge` → 공유 위젯으로 승격 |
| 3 | `MyTicketsController` + Provider 생성 | `enhancement` | #1 | upcoming/past 분리, 오늘 이벤트 감지 |
| 4 | `MyTicketsPage` UI 구현 | `enhancement` | #2, #3 | 카드, 배너, 빈 상태 |
| 5 | 라우트 등록 + MyPage 네비게이션 연결 | `enhancement` | #4 | GoRouter 라우트, Coordinator 메서드 |

## 수정 대상 파일

### 백엔드 (신규 없음)

DB 스키마 변경 없음. 기존 `event_applications` 테이블 + RLS 그대로 사용.

### 프론트엔드

| 파일 | 변경 내용 |
|------|----------|
| `shared/packages/minglit_kit/lib/src/data/repositories/event_repository_queries.dart` | `getMyTickets(userId)` 추가 — `inFilter('status', ['paid', 'approved'])` |
| `apps/app_user/lib/src/features/payment/ui/purchase_history_status_badge.dart` | `_StatusBadge` → `StatusBadge`로 공개 클래스 승격, `part of` 해제 후 독립 파일로 분리 |
| `apps/app_user/lib/src/features/payment/ui/purchase_history_page.dart` | `part` 지시문 업데이트 (status_badge 분리 반영) |
| **신규** `apps/app_user/lib/src/features/my_tickets/logic/my_tickets_controller.dart` | Controller: upcoming/past 분리, todayEvent 감지 |
| **신규** `apps/app_user/lib/src/features/my_tickets/ui/my_tickets_page.dart` | 메인 페이지 UI (배너 + 카드 리스트 + 빈 상태) |
| **신규** `apps/app_user/lib/src/features/my_tickets/ui/my_ticket_card.dart` | 티켓 카드 위젯 (D-Day 칩, 썸네일, QR 버튼) |
| `apps/app_user/lib/src/routing/app_routes.dart` | `MyTicketsRoute` 추가 (`/tickets/my`) |
| `apps/app_user/lib/src/features/home/logic/home_coordinator.dart` | `pushMyTickets()` 메서드 추가 |
| `apps/app_user/lib/src/features/home/my_page.dart` | "내 티켓" onTap → `pushMyTickets()` 으로 변경 (line 113) |

## 설계 결정

### 1. 전용 쿼리 vs 기존 쿼리 재활용

`getMyPurchaseHistory()`는 모든 상태의 신청을 가져온다. 내 티켓은 `paid`/`approved`만 필요하므로 DB 레벨에서 필터링하는 `getMyTickets()`를 추가한다.

```dart
Future<List<EventApplication>> getMyTickets(String userId) async {
  final data = await supabaseClient
      .from('event_applications')
      .select('*, event:events(*, party:parties(*, location:locations(*))), ticket:tickets(*)')
      .eq('user_id', userId)
      .inFilter('status', ['paid', 'approved'])
      .order('created_at', ascending: false);
  return data.map(EventApplication.fromJson).toList();
}
```

클라이언트 분리: PostgREST에서 관계 테이블(`events.start_time`) 기준 정렬이 불가하므로, Controller에서 `event.startTime` 기준 upcoming/past 분리 + 정렬.

### 2. TicketQRScreen 연동

`TicketQRScreen`은 `ticketId`를 받아 `TicketWalletRepository`에서 로컬 저장된 `TicketToken`을 조회한다.
QR 버튼 탭 시 `Navigator.push`로 `TicketQRScreen(ticketId: application.ticketId)`를 호출한다.

> **주의**: QR 표시를 위해서는 사전에 `CheckinRepository.mintTicket(eventId)`가 호출되어 토큰이 로컬에 저장되어 있어야 한다. 토큰이 없으면 TicketQRScreen이 에러 UI를 표시한다 (기존 동작).

### 3. StatusBadge 공유

현재 `_StatusBadge`는 `purchase_history_page.dart`의 private `part`이다. 내 티켓 카드에서도 동일한 배지가 필요하므로:
- `purchase_history_status_badge.dart`를 `part of` 해제
- 클래스명 `_StatusBadge` → `StatusBadge`로 변경
- `shared/packages/minglit_kit`이 아닌 `app_user` 내 공유 위젯으로 위치 (앱 외부에서 사용하지 않으므로)
- 위치: `apps/app_user/lib/src/common/widgets/status_badge.dart`

### 4. Feature 디렉토리 구조

```
apps/app_user/lib/src/features/my_tickets/
├── logic/
│   └── my_tickets_controller.dart
└── ui/
    ├── my_tickets_page.dart
    └── my_ticket_card.dart
```

Feature-first 원칙에 따라 `my_tickets` feature를 독립 디렉토리로 생성. `payment` feature와 분리.

### 5. 이벤트 상세 네비게이션

카드 전체 탭 → `EventDetailPage(eventId)` 이동은 HomeCoordinator의 기존 `pushEventDetail(eventId)` 재활용.

## 리스크 및 대응

| 리스크 | 확률 | 대응 |
|--------|------|------|
| TicketToken이 로컬에 없는 경우 (mint 미완료) | 중 | TicketQRScreen 기존 에러 UI가 처리. 향후 on-demand mint 추가 가능 |
| `event.startTime` 기준 정렬이 클라이언트 부담 | 낮 | 활성 티켓 수가 적음 (일반적으로 <10건). 성능 이슈 없음 |
| `_StatusBadge` 승격 시 purchase_history 기존 코드 영향 | 낮 | part 지시문 변경 + import 경로만 수정. 동작 변경 없음 |
| `chore/misc-fixes` 브랜치의 spec.md가 아직 dev 미머지 | 중 | 이 PR에 spec.md + wireframe.html 포함하여 함께 머지 |
| `protectedPrefixes`에 `/tickets/my` 이미 등록 | - | 리스크 아님. 인증 가드 추가 작업 불필요 (이미 보호됨) |
