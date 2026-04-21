# 알림 인박스 스펙

> **이슈**: #1688 [Notification] 알림 인박스 화면 구현 — 과거 알림 확인 경로 부재
> **작성자**: needs-pm-claude-1 (PM)
> **작성일**: 2026-04-21

## 개요

밍글릿의 알림은 `notification-worker` Edge Function이 FCM 푸시를 쏘면서 동시에 `user_notifications` 테이블에 레코드를 쌓는다. 그러나 사용자가 푸시를 놓치면 앱 안에서 지난 알림을 다시 확인할 수 있는 경로가 **부분적으로만** 연결돼 있다.

### 구현 현황 (이슈 본문 stale)

이슈 본문은 "어떤 화면에서도 호출하지 않음"이라고 적혀 있으나 실제 코드베이스는 다음과 같다:

| 요소 | 상태 | 경로 |
|------|------|------|
| `/notifications` 라우트 | ✅ 양쪽 앱 정의 | `app_user/lib/src/routing/app_routes.dart:210`, `app_partner/lib/src/routing/app_routes.dart:91` |
| `NotificationListScreen` | ✅ 구현 완료 | `shared/packages/minglit_kit/lib/src/features/notification/notification_list_screen.dart` |
| `NotificationListController` | ✅ Riverpod provider + refresh/markAsRead/markAllAsRead/delete | `.../notification_list_controller.dart` |
| `NotificationRepository` API | ✅ CRUD 전부 구현 | `shared/packages/minglit_kit/lib/src/data/repositories/notification_repository.dart:44-74` |
| 홈 벨 아이콘 — **app_partner** | ✅ 배지 + 카운트 (99+ 처리) | `app_partner/lib/src/features/home/partner_home_page.dart:42-75` |
| 홈 벨 아이콘 — **app_user** | ⚠️ **배지 없음** (plain IconButton) | `app_user/lib/src/features/home/home_page.dart:120-124` |
| CUJ 테스트 | ✅ 존재 | `apps/app_user/test/integration/cuj_notification_test.dart` |

### 실제 gap (이번 스펙의 범위)

이슈는 "구현 부재"로 기술돼 있으나 실제 gap은 **UX 완성도**와 **app_user 엔트리 포인트**다:

| # | Gap | 영향 | 우선순위 |
|---|-----|------|----------|
| G1 | app_user 홈 벨 아이콘에 미읽음 카운트 배지 부재 | 유저가 새 알림 여부를 앱 안에서 인지 불가 | **P1** |
| G2 | 페이지네이션 미지원 (`limit: 20` hardcoded, 무한 스크롤 없음) | 알림 누적 시 과거 알림 접근 불가 | **P1** |
| G3 | 카테고리 구분 시각화 부재 (스키마엔 `notification_category` enum 있음) | 이벤트/매칭/티켓/시스템 혼재, 인지 부하 증가 | **P2** |
| G4 | 상대 시간 (방금 전, 1시간 전) 미표시 — 절대 시간 `MM/dd HH:mm`만 | 최근 알림의 시간 감각 저하 | **P2** |
| G5 | 실시간 미지원 (Supabase Realtime 미사용) — 앱 열려 있어도 새 알림이 인박스에 반영 안 됨 | 백그라운드 → 포그라운드 전환 시 수동 새로고침 필요 | **P2** |
| G6 | 빈 상태가 밋밋한 텍스트 1줄 | 신규 유저 첫 진입 시 구조 이해 어려움 | **P3** |
| G7 | 삭제 확인 UX 없음 (즉시 Dismissible) | 오삭제 복구 불가 | **P3** |
| G8 | 필터 탭 (모두/안 읽음) 부재 | 누적 시 안 읽은 알림 탐색 비용 증가 | **P3** |

## 참고한 앱/트렌드

### 1. Instagram (Professional Inbox, 2026)
- **필터**: 우상단 필터 아이콘 → Unread / Flagged / by type (출처: [Instagram Help — Filter messages](https://help.instagram.com/))
- **Swipe quick actions**: Mark as Unread, Archive, Flag, Delete (swipe 좌측으로)
- **Pinned conversations** 상단 3개 고정
- **적용 가능성**: 밍글릿에선 "Flagged/Archive"는 스코프 과다. **Unread 필터만** 도입 가치 있음 (G8)

### 2. Meetup (2025 UX redesign proposals)
- **Unified Updates section**: messages + notifications + updates 통합 (출처: [Medium - UI Redesign Meet Up App](https://medium.com/@eggmayr/redesign-meet-up-d85c26a4c158))
- **주간 briefing email**: 빈도 조절
- **적용 가능성**: 밍글릿은 이미 DM(채팅) 미지원이므로 통합 불필요. 다만 "알림 빈도가 과하다"는 피드백이 Meetup의 주요 불만 — **밍글릿은 `notification_category` 기반 설정 노출**로 이 리스크를 사전 차단 (`/my/notification-settings`에 이미 존재)

### 3. Material Design / Android 2026 가이드
- **적게 보내고, 리스트로 재조회**: push 과다 대신 인박스에 쌓고 badge로 알림 (출처: [Muzli — 2026 mobile UI patterns](https://muz.li/blog/whats-changing-in-mobile-app-design-ui-patterns-that-matter-in-2026/))
- **Avatar on right**: 사람 관련 알림은 아바타 우측 배치
- **Glassmorphism overlay**: 2026 트렌드는 표면적 글래스 사용 (notification panels, bottom sheets)
- **적용 가능성**: Avatar 우측 배치는 밍글릿의 파트너/이벤트 알림과 매치. Glass 효과는 범위 과다 — 배제.

### 4. Slack / Linear (앱 내 인박스 베스트 프랙티스)
- **카테고리 그룹핑**: Mentions / Threads / Reactions 탭
- **적용 가능성**: 밍글릿은 알림 카테고리가 단순(event/matching/ticket/system)하므로 **탭보단 아이콘 배지** (G3)

## 타깃 페르소나 & 시나리오

### 페르소나 A: 이벤트 신청자 "지수" (28세, 직장인)
- **맥락**: 퇴근 중 지하철에서 이벤트 신청 → 파트너가 승인했다는 푸시가 왔지만 지하철이라 스와이프로 꺼버림
- **기대 동선**: 앱 오픈 → 홈 벨 아이콘에 **빨간 점/숫자** → 탭 → 인박스 → 승인 알림 탭 → 이벤트 상세 진입
- **현재 불만 (app_user)**:
  - 홈 벨 아이콘에 아무 표시 없어 새 알림 유무 인지 불가 → **G1**
  - 인박스 진입해도 "이벤트 승인 완료" / "이벤트 마감 임박" / "정산 완료" 등이 텍스트로만 구분됨 → **G3**

### 페르소나 B: 헤비 유저 "민재" (22세, 대학생)
- **맥락**: 매주 2~3개 이벤트 신청, 파트너 팔로우 5개 → 알림이 주당 15~20건 쌓임
- **기대 동선**: 인박스 하단 스크롤로 2주 전 "환불 완료" 알림 재확인
- **현재 불만**:
  - 20건 이상 쌓이면 더 이상 안 보임 (pagination 없음) → **G2**
  - 안 읽은 것만 빠르게 보고 싶은데 전부 섞여 있음 → **G8**
  - "방금 전" vs "3일 전" 시간 감각이 안 옴 (`04/18 14:23` 포맷) → **G4**

### 페르소나 C: 파트너 "스테이지42 운영자 현수" (34세, 소상공인)
- **맥락**: 공연 시작 1시간 전 앱 열어놓고 대기 → "신규 신청자" 알림이 실시간 들어와야 함
- **기대 동선**: 앱을 포그라운드에 유지 → 새 신청이 들어오면 벨 아이콘에 바로 +1
- **현재 불만**:
  - 앱을 열어둔 상태에선 바뀌지 않음 (pull 기반) → **G5**
  - 배지는 이미 있음 ✅ (app_partner는 #1688 이전에 구현 완료)

### 엣지 케이스
- **오프라인**: 푸시는 도착 안 하지만 온라인 복귀 시 인박스에서 놓친 알림 복구 가능 (이미 동작 — `getNotifications()`가 서버 데이터 fetch)
- **알림 0건**: 신규 유저 첫 진입 → 빈 텍스트 1줄 → **G6 (빈 상태 일러스트 + "아직 알림이 없어요, 첫 이벤트를 찾아보세요" CTA)**
- **deep_link null**: 이미 SnackBar로 처리됨 ✅
- **deep_link 비정상 (외부 URL / scheme)**: 이미 `startsWith('/')` 검증됨 ✅
- **읽음 처리 실패 (네트워크 오류)**: 현재 optimistic update로 UI만 업데이트 → 서버 실패 시 이상 상태. **rollback 로직 추가 필요 (G2 범위)**
- **동시 탭 (여러 알림 빠르게 탭)**: deep_link 여러 개 push 스택 쌓임 → **첫 탭 이후 disable 로직 (G2 범위)**

## 구성 요소

### 1. 홈 벨 아이콘 배지 (app_user 신규, app_partner 유지)

**app_user 홈 AppBar**:
```
[버그리포트] [검색 🔍] [알림 🔔 (배지)] [아바타]
                            ↑ P1: unreadCount > 0일 때 빨간 원 + 숫자 (99+)
```

- 위치: `app_user/lib/src/features/home/home_page.dart:120-124` `IconButton`을 `Stack`으로 감싸기
- 스타일: **app_partner의 구현과 동일** (DRY — `NotificationBellWithBadge` 공용 위젯으로 `minglit_kit`에 승격 권장)
- 데이터 소스: `ref.watch(notificationListProvider).maybeWhen(data: ...).where(!is_read).length`
- **접근성**: `Semantics(label: '알림 $unreadCount건 안 읽음')`

### 2. 인박스 화면 (`NotificationListScreen` 개량)

**섹션 순서 (위→아래)**:

#### 2.1 AppBar
```
[← 뒤로] 알림 센터                    [필터 🎚] [모두 읽음 ✓]
```
- `[모두 읽음 ✓]` — 현재 구현 유지 (아이콘 `Icons.done_all`)
- `[필터 🎚]` — **신규**: 누르면 `FilterChip`이 body 최상단에 슬라이드 다운 (G8)

#### 2.2 Filter Bar (접힘/펼침)
```
┌─────────────────────────────────────────┐
│  [모두] [안 읽음 (3)] [이벤트] [매칭] [티켓]  │
└─────────────────────────────────────────┘
```
- Default: `[모두]` 선택
- 카테고리는 `notification_category` enum 값에 따름 (현재 `service` default만 있음 → notification-worker가 카테고리 주입하도록 후속 요청)
- 읽지않음 카운트는 `unreadCount` 재사용
- **v1 범위**: `[모두]` / `[안 읽음]` **두 개만**. 카테고리 필터는 notification-worker가 카테고리 실제 주입할 때 (**v2**)

#### 2.3 알림 카드 (ListTile 개량)

**현재**:
```
┌─────────────────────────────────────┐
│ 이벤트 승인 완료                       │
│ "한남 재즈 나이트" 신청이 승인됐어요.        │
│ 04/18 14:23                          │
└─────────────────────────────────────┘
```

**개선 후**:
```
┌─────────────────────────────────────┐
│ 🎫  이벤트 승인 완료                    │  ← 카테고리 아이콘 (G3)
│    "한남 재즈 나이트" 신청이 승인됐어요.     │
│    3시간 전 · 이벤트                    │  ← 상대시간 + 카테고리 라벨 (G4)
└─────────────────────────────────────┘
```

- **미읽음 표시**: 좌측 3px primary 색상 세로 바 + 배경 `primary@8%` (현재도 유사하나 더 명확하게)
- **아이콘 매핑** (G3):
  - `event` → `Icons.event`
  - `matching` → `Icons.favorite`
  - `ticket` → `Icons.confirmation_number`
  - `payment` → `Icons.payments`
  - `service` (default) → `Icons.campaign`
- **상대시간 포맷** (G4):
  - < 1분: "방금 전"
  - < 1시간: "N분 전"
  - < 24시간: "N시간 전"
  - < 7일: "N일 전"
  - ≥ 7일: `yyyy-MM-dd` (절대)
  - **util**: `minglit_kit/src/utils/relative_time.dart` 신규 (유저앱/파트너앱 공용)

#### 2.4 무한 스크롤 (G2)

- `ListView.separated` → `ListView.builder` + `ScrollController` + `InfiniteScrollPagination` 패턴
- **옵션 A (권장)**: `infinite_scroll_pagination` 패키지 도입 (이미 퍼플리시 안정적)
- **옵션 B (의존성 추가 회피)**: 커스텀 `ScrollController` + `PagingState` 내부 구현
- **Controller 변경**: `NotificationListController`가 `List<Map>` 대신 `PagedState<int, Map>` 또는 `{ items, hasMore, offset }` 상태 보유
- **fetch 파라미터**: `getNotifications(limit: 20, offset: loadedCount)` 이미 repository 지원 ✅

#### 2.5 빈 상태 (G6)

```
┌─────────────────────────────────────┐
│                                     │
│          📭 (일러스트)                 │
│                                     │
│     아직 알림이 없어요                   │
│   첫 이벤트를 찾아 신청해보세요               │
│                                     │
│      [이벤트 둘러보기 →]                │
│                                     │
└─────────────────────────────────────┘
```
- **일러스트**: 밍글릿 tone에 맞는 간단한 bell-off SVG (임시 emoji 허용 — ux-designer가 최종 asset 결정)
- **CTA**: `go('/')` (홈으로)

#### 2.6 삭제 확인 (G7)

- 현재 `Dismissible` 즉시 처리 → **Confirm dialog** 추가:
  ```
  [알림 삭제]
  이 알림을 삭제할까요? 삭제된 알림은 복구할 수 없어요.
     [취소]    [삭제]
  ```
- `confirmDismiss: (direction) async => showDialog<bool>(...)`

#### 2.7 실시간 구독 (G5) — v2 범위

- Supabase Realtime: `user_notifications` 테이블 `INSERT` 이벤트 구독
- 앱이 포그라운드일 때만 active (lifecycle aware)
- `NotificationListController`가 초기 fetch 후 stream subscribe → 새 레코드 prepend
- **Riverpod 구조**: `notificationListProvider`를 `StreamNotifier`로 변경 또는 `unreadCountProvider = StreamProvider`로 분리
- **부하 주의**: RLS로 user_id 필터됨, 폴리필 불필요

## 데이터 소스

### API (기존 사용)
| Repository method | 설명 | 사용처 |
|-------------------|------|--------|
| `NotificationRepository.getNotifications(limit, offset)` | 페이지네이션 지원 | 인박스 리스트 (신규: 무한 스크롤) |
| `markAsRead(id)` | 단건 읽음 처리 | 탭 시 |
| `markAllAsRead(userId)` | 전체 읽음 처리 | AppBar 버튼 |
| `deleteNotification(id)` | 단건 삭제 | Swipe |

### Provider (신규/변경)
| Provider | 타입 | 설명 |
|----------|------|------|
| `notificationListProvider` | `AsyncNotifier<PagedState>` **변경** | 기존 `List<Map>` → 페이지 상태 포함 |
| `unreadCountProvider` | `Provider<int>` **신규** | `notificationListProvider.select((s) => s.items.where(!is_read).length)` — **v1에선 현재 페이지 기준 근사값**. 정확도 필요 시 별도 count query |
| `notificationFilterProvider` | `StateProvider<NotificationFilter>` **신규 (v2)** | `.all`, `.unread` |

### DB 스키마 (변경 없음)
- `user_notifications` (기존): `id, user_id, title, body, category, deep_link, is_read, metadata, created_at`
- 인덱스 기존 3종 충분 (특히 `idx_user_notifications_unread`)

### notification-worker 변경 (후속)
- 현재 `category` default = `'service'`
- **v1 후속**: 이벤트/매칭/티켓 발행 경로별로 적절한 `notification_category` enum 값 주입
- Issue 별도 분리 권장 (edge function 변경 범위)

## 라우트 변경

변경 없음. 기존 `/notifications` 경로 유지.

## 에러/로딩 상태

| 상태 | UX | 비고 |
|------|----|------|
| 초기 로딩 | `MinglitAsyncValueWidget` default (shimmer or progress) | 기존 유지 |
| 페이지 추가 로딩 | 리스트 하단 `CircularProgressIndicator` (40x40) + "불러오는 중…" | 신규 |
| 빈 결과 | G6 빈 상태 (아이콘 + CTA) | 신규 |
| 네트워크 에러 | 중앙에 `Icons.cloud_off` + "알림을 불러올 수 없어요" + "[다시 시도]" 버튼 | 기존 `"에러: $err"` 개선 |
| markAsRead 실패 | 현재 optimistic → **실패 시 rollback + 상단 SnackBar "읽음 처리에 실패했어요"** | 신규 |
| delete 실패 | Dismissible 후 실패 시 **리스트 재조회 + SnackBar** | 신규 |
| deep_link 없음 | 기존 SnackBar 유지 ✅ | |
| deep_link 비정상 | 기존 SnackBar 유지 ✅ | |

## 접근성 (a11y)

- 벨 아이콘: `Semantics(label: '알림 ${unreadCount > 0 ? "$unreadCount건 안 읽음" : "없음"}')`
- 알림 카드: `Semantics(label: '${isRead ? "읽음" : "안 읽음"} $title, $body, $relativeTime')`
- `Dismissible` → `SemanticsAction.dismiss` 제공 (Flutter 기본)
- 미읽음 표시는 색상뿐 아니라 **굵기**로도 구분 (현재 구현 유지)

## 구현 이슈 분할 (예상)

v1 (MVP) — `needs-swe` 라벨로 이어서:

| # | 제목 | 의존성 | 복잡도 |
|---|------|--------|--------|
| 1 | app_user 홈 벨 아이콘 unread 배지 추가 + `NotificationBellWithBadge` 공용 위젯 승격 | 없음 | S |
| 2 | `notificationListProvider` 페이지네이션 + 무한 스크롤 | 1 | M |
| 3 | 알림 카드 UX 개량: 상대시간 + 카테고리 아이콘/라벨 + 미읽음 좌측 바 | 1 | S |
| 4 | 빈 상태 개선 (일러스트 + CTA) | 1 | XS |
| 5 | 에러/실패 처리 강화 (rollback, 재시도, SnackBar) | 2 | S |
| 6 | 삭제 확인 다이얼로그 | 1 | XS |

v2 — 별도 이슈로:

| # | 제목 | 복잡도 |
|---|------|--------|
| 7 | Supabase Realtime 구독 (`StreamNotifier` 전환) | M |
| 8 | 카테고리 필터 탭 (`FilterChip`) — notification-worker 카테고리 주입 완료 후 | M |
| 9 | notification-worker: 이벤트/매칭/티켓/payment 카테고리 실제 주입 | S (worker 코드 변경) |

## 테스트 계획 (qa-lead 인수 후 확장)

### Unit (minglit_kit)
- `NotificationListController`:
  - 페이지네이션: 초기 20개 → `loadMore()` → 40개 (mock repository)
  - `markAsRead` 실패 시 state rollback
  - `deleteNotification` 실패 시 리스트 재조회 트리거
- `relative_time_util`: 10 cases (방금 전 / 분 / 시간 / 일 / 절대)
- `unreadCountProvider` select 정확도

### Widget
- 벨 배지: 0 → 숨김, 1~99 → 숫자, 100+ → "99+"
- 빈 상태: 0건일 때 일러스트 + CTA 렌더
- 필터 (v2): `[안 읽음]` 선택 시 `is_read=false`만 필터링

### Integration (CUJ)
- **CUJ-N01**: 푸시 받고 앱 닫음 → 앱 열기 → 벨 배지 1 → 탭 → 인박스 → 알림 탭 → 딥링크 이동 → 인박스 재방문 시 읽음 처리 확인
- **CUJ-N02**: 20건 이상 누적 → 스크롤 → 자동 로드 → 총 40건 확인
- **CUJ-N03**: 오프라인 상태에서 인박스 진입 → 에러 UI → 온라인 복귀 → 재시도 → 로드 성공
- 기존 `cuj_notification_test.dart`, `flow_notification_routing_test.dart` 시나리오 유지 + 확장

## 영향 범위

### 변경 파일 (v1)
| 파일 | 변경 유형 |
|------|-----------|
| `shared/packages/minglit_kit/lib/src/features/notification/notification_list_controller.dart` | 페이지네이션 + 에러 처리 |
| `shared/packages/minglit_kit/lib/src/features/notification/notification_list_screen.dart` | UX 개량 |
| `shared/packages/minglit_kit/lib/src/features/notification/widgets/notification_bell.dart` | **신규** (app_partner에서 이관) |
| `shared/packages/minglit_kit/lib/src/utils/relative_time.dart` | **신규** |
| `apps/app_user/lib/src/features/home/home_page.dart` | 벨 아이콘 → `NotificationBellWithBadge` 교체 |
| `apps/app_partner/lib/src/features/home/partner_home_page.dart` | 기존 인라인 → `NotificationBellWithBadge` 교체 (DRY) |

### 비변경
- DB 스키마, RLS
- `NotificationRepository` API (추가 없음 — 기존 `limit/offset` 활용)
- `/notifications` 라우트

## 성공 지표 (릴리스 후 2주)

| KPI | 측정 | 목표 |
|-----|------|------|
| 벨 아이콘 탭 CTR | 푸시 받은 유저 중 인박스 진입률 | 베이스라인 + 15%p |
| 딥링크 전환 | 인박스 → 딥링크 진입 / 인박스 진입 | ≥ 40% |
| markAllAsRead 사용률 | 활성 유저 중 / 주 | 참고 지표 |
| 무한 스크롤 발동 | offset ≥ 20 fetch 이벤트 수 | 헤비 유저 분류 |

## Open Questions (승인 전 Mark에게 확인)

1. **v1 범위**: 위 1~6번을 한 번에 ship할지 (배지 + 페이지네이션 + UX 개량 묶음), 아니면 배지만 먼저 빠르게 나눌지?
2. **실시간 (G5)**: v2로 뒤로 미뤄도 되는지 — 파트너 헤비 유저 현수 페르소나는 실시간이 강한 니즈
3. **v2 카테고리 필터**: notification-worker 카테고리 주입 선행 작업(이슈 #9)을 PM이 별도 이슈로 생성할지, swe가 구현 중 스핀오프할지
4. **일러스트 asset**: G6 빈 상태 일러스트를 ux-designer에게 넘기는지 (기본 제안), 아니면 emoji 임시본으로 v1 진행하는지

## Workflow

- [x] PM: spec.md + wireframe.html 작성
- [ ] **Mark 승인** (`report-exec`)
- [ ] ux-designer: 인박스 카드 / 필터 chip / 빈 상태 일러스트 / 벨 배지 시각 최종 확정
- [ ] qa-lead: test-plan.md (CUJ-N01~03 확장, 엣지 케이스 매트릭스)
- [ ] swe: v1 6개 PR 순차 구현 (의존성 순서)
