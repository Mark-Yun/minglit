# 내 티켓 (My Tickets) — 테스트 보강 계획

## 계층별 테스트 계획

### Layer 1: Repository 테스트 (minglit_kit)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `getMyTickets(userId)` | `shared/packages/minglit_kit/test/src/data/repositories/event_repository_queries_test.dart` (기존 파일에 추가) | paid + approved 상태만 반환 | P1 |
| | | pending/rejected/refunded 상태 제외 | P1 |
| | | 결과에 event, party, location, ticket 관계 데이터 포함 | P1 |
| | | 빈 결과 (해당 유저 티켓 없음) → 빈 리스트 | P2 |
| | | Supabase 에러 → MingleException throw | P2 |

### Layer 2: Controller 테스트 (app_user)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `MyTicketsController` | `apps/app_user/test/src/features/my_tickets/logic/my_tickets_controller_test.dart` | upcoming/past 분리: 미래 이벤트 → upcoming, 과거 이벤트 → past | P1 |
| | | upcoming 정렬: `event.startTime` ASC (가까운 순) | P1 |
| | | past 정렬: `event.startTime` DESC (최근 종료 순) | P1 |
| | | todayEvent 감지: 오늘 시작하는 이벤트 중 가장 임박한 것 | P1 |
| | | todayEvent 없음: 오늘 이벤트 없으면 null | P2 |
| | | 오늘 이벤트 2개 이상 → 가장 임박한 1개만 todayEvent | P2 |
| | | event가 null인 application 필터링 (방어 코드) | P2 |
| | | 빈 리스트 → upcoming/past 모두 빈 리스트 | P3 |

### Layer 3: Widget 테스트 (UI)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `MyTicketsPage` | `apps/app_user/test/src/features/my_tickets/ui/my_tickets_page_test.dart` | 빈 상태 → "아직 티켓이 없어요" + "이벤트 둘러보기" CTA | P1 |
| | | upcoming 1건 → 카드 1개 + "다가오는 이벤트" 섹션 표시 | P1 |
| | | past 1건 → "지난 이벤트" 섹션 + opacity 0.55 | P2 |
| | | 오늘 이벤트 배너 표시 (todayEvent 있을 때) | P1 |
| | | 오늘 이벤트 배너 미표시 (todayEvent 없을 때) | P2 |
| | | 로딩 상태 → shimmer | P3 |
| | | 에러 상태 → 재시도 | P3 |
| `MyTicketCard` | `apps/app_user/test/src/features/my_tickets/ui/my_ticket_card_test.dart` | D-Day 카운트 표시 (D-3, D-1, D-Day) | P1 |
| | | 이벤트명, 일시, 장소 표시 | P1 |
| | | "입장 QR" 버튼 탭 → TicketQRScreen 이동 | P1 |
| | | 카드 전체 탭 → EventDetailPage 이동 | P2 |
| | | 지난 이벤트 카드: QR 버튼 없음 + "종료" 라벨 | P2 |
| | | 썸네일 이미지 표시 (80×80) | P3 |
| `StatusBadge` (공유 위젯 추출) | `apps/app_user/test/src/common/widgets/status_badge_test.dart` | paid → "결제완료" 텍스트 | P2 |
| | | approved → "승인됨" 텍스트 | P2 |
| | | 각 상태별 올바른 색상 적용 | P3 |

### Layer 4: Golden 테스트 (시각적 회귀)

| 화면 | 변형 | 테스트 파일 | 우선순위 |
|------|------|-----------|---------|
| `MyTicketsPage` | 빈 상태 (light/dark) | `apps/app_user/test/goldens/my_tickets_page_golden_test.dart` | P2 |
| | upcoming 2건 + past 1건 (light/dark) | 동일 | P2 |
| | 오늘 이벤트 배너 포함 (light/dark) | 동일 | P3 |
| `MyTicketCard` | upcoming 카드 (D-3) | `apps/app_user/test/goldens/my_ticket_card_golden_test.dart` | P2 |
| | past 카드 (종료, muted) | 동일 | P3 |
| | D-Day 카드 (강조) | 동일 | P3 |

### Layer 5: Coordinator/라우트 테스트

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `HomeCoordinator.pushMyTickets()` | `apps/app_user/test/src/features/home/logic/home_coordinator_test.dart` (기존 파일에 추가) | `pushMyTickets()` → `/tickets/my` 라우트 push | P1 |
| `MyTicketsRoute` | `apps/app_user/test/src/routing/app_routes_test.dart` (기존 파일에 추가) | `/tickets/my` 접근 → `MyTicketsPage` 렌더링 | P2 |

### 기존 테스트 회귀 검증

리팩터링 대상인 기존 파일의 테스트가 깨지지 않는지 확인:

| 기존 테스트 | 검증 포인트 |
|-----------|-----------|
| `purchase_history_screen_test.dart` | `StatusBadge` 추출 후 기존 구매내역 화면 테스트 pass |
| `purchase_history_card_test.dart` | `part` 지시문 변경 후 카드 테스트 pass |
| `home_coordinator_test.dart` | `pushMyTickets` 추가 후 기존 coordinator 테스트 pass |
| `my_page_golden_test.dart` | "내 티켓" onTap 변경 후 golden 업데이트 필요 여부 확인 |

## 실행 순서

**P1 (필수): 14건**
- `getMyTickets()` 필터링 (2건)
- `MyTicketsController` upcoming/past 분리 + 정렬 + todayEvent (4건)
- `MyTicketsPage` 빈 상태 + 카드 표시 + 배너 (3건)
- `MyTicketCard` D-Day + 정보 표시 + QR 버튼 (3건)
- `HomeCoordinator.pushMyTickets()` 라우트 (1건)
- `getMyTickets()` 관계 데이터 포함 (1건)

**P2 (권장): 14건**
- Repository 엣지 케이스 (2건)
- Controller 엣지 케이스 (3건)
- Widget 세부 (past opacity, 배너 미표시, 카드 탭, 지난 카드) (4건)
- StatusBadge 텍스트 (2건)
- Golden 메인 페이지 + 카드 (2건)
- 라우트 테스트 (1건)

**P3 (선택): 8건**
- Controller 빈 리스트 (1건)
- Widget 로딩/에러/썸네일 (3건)
- StatusBadge 색상 (1건)
- Golden 추가 변형 (3건)

**총 36건**
