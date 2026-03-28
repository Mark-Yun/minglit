# 내 티켓 (My Tickets) 스펙

## 개요

"내 티켓"은 유저가 다가오는 이벤트 티켓을 시간순으로 빠르게 확인하고, QR 입장권에 한 탭으로 접근할 수 있는 화면이다.

기존 "구매 내역"과 역할을 분리한다:

| 화면 | 목적 | 정렬 | 대상 |
|------|------|------|------|
| **내 티켓** | 다가오는 이벤트 확인 + 입장 | `event.startTime ASC` (가까운 순) | 유효 티켓 (paid, approved) |
| **구매 내역** | 전체 결제 이력 조회 + 환불 | `created_at DESC` (최신 순) | 모든 신청 (전 상태) |

### 핵심 원칙

1. **시간 기반 정렬** — 가장 임박한 이벤트가 최상단
2. **한 탭 QR** — 티켓 카드에서 바로 QR 화면 진입
3. **오늘 이벤트 강조** — D-Day 배너로 현장 접근성 극대화
4. **지난 이벤트 보존** — 참석 기록을 아래쪽에 회색 처리로 보여줌

### 참고 앱

- **Eventbrite**: 전용 Tickets 탭, Apple/Google Wallet 연동, QR 직접 표시
- **NOL 티켓 (인터파크)**: 당일 퀵 배너, 수집용 티켓 이미지, 모바일 QR 2종
- **Fever**: 앱+이메일 듀얼 QR 접근, 전용 Tickets 섹션

## 구성 요소

### 1. AppBar

- 타이틀: "내 티켓"
- 뒤로가기 버튼 (← MyPage)

### 2. 오늘 이벤트 배너 (조건부)

오늘 시작하는 이벤트가 있을 때만 상단에 강조 배너 표시.

- **배경**: `primary` (#9900FF) at 8% opacity
- **좌측**: 캘린더 아이콘 (primary color)
- **중앙**: 이벤트명 (1줄, ellipsis) + "오늘 HH:mm 시작"
- **우측**: "입장 QR" 버튼 → TicketQRScreen 이동
- 오늘 이벤트가 2개 이상이면 가장 임박한 것 1개만 표시
- 조건: `event.startTime`이 오늘 날짜 AND status가 paid/approved

### 3. 다가오는 이벤트 섹션

"다가오는 이벤트" 서브헤더 + 티켓 카드 리스트.

#### 티켓 카드 구성

```
┌─────────────────────────────────────┐
│ [D-3]                    [승인됨]   │  ← D-Day 카운트 + 상태 배지
│                                     │
│ [80x80 썸네일]  이벤트 제목          │  ← 이벤트 정보
│                 3월 31일 (화) 19:00  │
│                 강남 라운지바         │
│                                     │
│ ─────────────────────────────────── │
│ 일반 입장권              [입장 QR]   │  ← 티켓명 + QR 버튼
└─────────────────────────────────────┘
```

- **D-Day 카운트**: D-Day, D-1, D-2, ... D-N (primary color chip)
- **상태 배지**: 기존 `_StatusBadge` 재사용 (paid → "결제완료", approved → "승인됨")
- **썸네일**: 80×80, 8px radius, `MinglitImage`
- **이벤트명**: `titleMedium` bold, 1줄 ellipsis
- **일시**: `bodySmall`, `DateFormat('M월 d일 (E) HH:mm', 'ko_KR')`
- **장소**: `bodySmall`, `onSurfaceVariant` color
- **티켓명**: `bodyMedium`
- **입장 QR 버튼**: `FilledButton.tonal` → TicketQRScreen(eventId, ticketId)
- **카드 탭**: 전체 카드 탭 → EventDetailPage(eventId) 이동

#### 필터 조건

- `status` IN ('paid', 'approved')
- `event.startTime >= now()` (미래 이벤트만)
- 정렬: `event.startTime ASC` (가까운 순)

### 4. 지난 이벤트 섹션

"지난 이벤트" 서브헤더 + 지난 티켓 카드 리스트.

- 동일한 카드 레이아웃이지만:
  - D-Day 카운트 대신 "종료" 라벨 (gray chip)
  - 카드 전체 opacity 0.55 (muted)
  - QR 버튼 없음 (이벤트 종료)
  - 카드 탭 → EventDetailPage(eventId) 이동은 유지
- 필터: `status` IN ('paid', 'approved') AND `event.startTime < now()`
- 정렬: `event.startTime DESC` (최근 종료 순)
- 최대 20개 표시 (오래된 것은 구매내역에서 확인)

### 5. 빈 상태

티켓이 하나도 없을 때:

- 아이콘: `confirmation_number_outlined` (64px, `onSurfaceVariant`)
- 텍스트: "아직 티켓이 없어요"
- 서브텍스트: "이벤트에 참여하고 티켓을 받아보세요"
- CTA 버튼: "이벤트 둘러보기" → HomeRoute(/)

## 데이터 소스

### 새 Repository 메서드

`EventRepository`에 추가:

```dart
/// 내 티켓 목록 조회 (유효 티켓만, 이벤트 시작시간 기준 정렬)
Future<List<EventApplication>> getMyTickets(String userId) async {
  final response = await _client
      .from('event_applications')
      .select('*, event:events(*, party:parties(*, location:locations(*))), ticket:tickets(*)')
      .eq('user_id', userId)
      .inFilter('status', ['paid', 'approved'])
      .order('created_at', ascending: false);
  return response.map(EventApplication.fromJson).toList();
}
```

> 참고: Supabase PostgREST에서 관계 테이블(`events.start_time`) 기준 정렬이 불가하므로,
> 클라이언트에서 `event.startTime` 기준으로 upcoming/past 분리 + 정렬한다.

### 클라이언트 분리 로직

```dart
// Controller에서 처리
final now = DateTime.now();
final upcoming = tickets
    .where((a) => a.event != null && a.event!.startTime.isAfter(now))
    .toList()
  ..sort((a, b) => a.event!.startTime.compareTo(b.event!.startTime)); // ASC

final past = tickets
    .where((a) => a.event != null && a.event!.startTime.isBefore(now))
    .toList()
  ..sort((a, b) => b.event!.startTime.compareTo(a.event!.startTime)); // DESC

final todayEvent = upcoming.where((a) =>
    a.event!.startTime.year == now.year &&
    a.event!.startTime.month == now.month &&
    a.event!.startTime.day == now.day
).firstOrNull;
```

### 기존 인프라 재사용

| 컴포넌트 | 용도 |
|----------|------|
| `TicketQRScreen` | QR 코드 표시 (기존 구현) |
| `TicketWalletRepository` | 오프라인 티켓 저장 (기존 구현) |
| `TicketToken` | QR 서명 토큰 (기존 모델) |
| `_StatusBadge` | 상태 배지 위젯 (purchase_history에서 추출 or 공유) |
| `MinglitImage` | 이미지 위젯 (기존) |
| `MinglitAsyncValueWidget` | 비동기 상태 처리 (기존) |

## 라우트 변경

### 신규 라우트

```dart
@TypedGoRoute<MyTicketsRoute>(path: '/tickets/my')
class MyTicketsRoute extends GoRouteData {
  const MyTicketsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MyTicketsPage();
}
```

> `/tickets/my`는 이미 `protectedPrefixes`에 등록되어 있으므로 인증 가드 추가 불필요.

### MyPage 수정

```dart
// Before (버그)
onTap: homeCoordinator.pushPurchaseHistory,

// After
onTap: homeCoordinator.pushMyTickets,
```

### HomeCoordinator 추가

```dart
void pushMyTickets() => _router.push('/tickets/my');
```

## 에러/로딩 상태

| 상태 | 처리 |
|------|------|
| 로딩 | `MinglitAsyncValueWidget` 기본 로딩 (shimmer) |
| 에러 | `MinglitAsyncValueWidget` 기본 에러 + 재시도 |
| 빈 상태 | 섹션 5 참고 |
| 네트워크 오프라인 | 로컬 `TicketWalletRepository` 캐시 표시 (향후 확장) |

## 구현 이슈 분할 (예상)

| # | 제목 | 의존성 | 설명 |
|---|------|--------|------|
| 1 | `getMyTickets` Repository 메서드 추가 | 없음 | EventRepository에 쿼리 추가 |
| 2 | MyTicketsController 생성 | #1 | upcoming/past 분리, 오늘 이벤트 감지 |
| 3 | MyTicketsPage UI 구현 | #2 | 카드, 배너, 빈 상태 |
| 4 | 라우트 등록 + MyPage 연결 | #3 | GoRouter 라우트, coordinator 메서드 |
| 5 | StatusBadge 공유 모듈 추출 | 없음 | purchase_history → 공통 위젯 |
