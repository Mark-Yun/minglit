# Spec: 알림 인박스

> **참조**
> - PRD: [prd.md](./prd.md)
> - MDS specs:
>   - [`notification_list_screen`](../../../../apps/mds/docs/public/specs/notification_list_screen/) — 인박스 화면 (5 states)
>   - [`notification_settings_screen`](../../../../apps/mds/docs/public/specs/notification_settings_screen/) — 카테고리별 알림 설정 (관련)
>   - [`home_page`](../../../../apps/mds/docs/public/specs/home_page/) — 홈 벨 아이콘 위치
>   - [`partner_home_page`](../../../../apps/mds/docs/public/specs/partner_home_page/) — 파트너 홈 벨 (이미 배지 구현)

## CUJs

> CUJ ID 컨벤션: `<scenario>-<cuj>` (예: `1-1` = PRD Scenario 1 의 첫 CUJ). 새 CUJ 추가 시 본 테이블 row 추가 + `apps/app_user/integration_test/cuj/notification/notification_inbox_test.dart` 의 `cujGroup` 블록 추가.

| ID  | Priority | CUJ Name | Details | FR | NFR |
|-----|----------|----------|---------|----|----|
| 1-1 | P0 | 미읽음 알림 있을 때 벨 배지 노출 | • 푸시 받고 dismiss → 앱 진입<br>• 홈 AppBar 벨 아이콘 우상단에 빨간 원 + 카운트<br>• 99 초과 시 "99+" | FR-1, FR-2 | NFR-1, NFR-4 |
| 1-2 | P0 | 벨 아이콘 탭 → 인박스 진입 | • 벨 아이콘 탭<br>• `/notifications` 라우트 진입<br>• 초기 20건 알림 카드 노출 | FR-3 | NFR-1 |
| 1-3 | P0 | 알림 카드 탭 → 읽음 + 딥링크 이동 | • 알림 카드 탭<br>• markAsRead optimistic + deep_link 라우트 push<br>• 인박스 재방문 시 읽음 처리 반영 | FR-4, FR-5 | NFR-2 |
| 1-4 | P0 | 모두 읽음 버튼 → 일괄 읽음 처리 | • 상단바 "모두 읽음" 탭<br>• 모든 알림 읽음 상태로 일괄 변경<br>• 벨 배지 사라짐 | FR-6 | NFR-2 |
| 1-5 | P0 | 미읽음 카드 시각 강조 | • 미읽음 카드 좌측 3px primary 컬러 세로 바<br>• 배경 primary@8%<br>• 타이틀 굵게 | FR-7 | NFR-3 |
| 1-6 | P1 | 카테고리 아이콘 + 상대 시간 표시 | • 카테고리 아이콘 (event / matching / ticket / payment / service)<br>• 상대 시간 ("방금 전" / "3시간 전" / "2일 전")<br>• 7일 이상은 절대 시간 (`yyyy-MM-dd`) | FR-8, FR-9 | NFR-3 |
| 2-1 | P0 | 무한 스크롤로 과거 알림 로드 | • 인박스 하단까지 스크롤<br>• 자동으로 다음 20건 fetch<br>• 로딩 인디케이터 (40x40) + "불러오는 중…" | FR-10, FR-11 | NFR-1, NFR-2 |
| 2-2 | P2 | 안 읽음 필터 탭 (v2) | • 상단바 필터 아이콘 탭<br>• `[모두]` `[안 읽음 (N)]` chip 노출<br>• `[안 읽음]` 선택 시 안 읽음 알림만 표시 | FR-12 | NFR-2 |
| 2-3 | P2 | 카테고리 필터 탭 (v2 — notification-worker 카테고리 주입 후) | • `[이벤트]` `[매칭]` `[티켓]` `[시스템]` chip<br>• 선택 시 해당 카테고리만 필터링 | FR-12, FR-13 | NFR-2 |
| 2-4 | P1 | Swipe 로 알림 삭제 + 확인 다이얼로그 | • 카드 좌→우 스와이프<br>• 확인 다이얼로그 ("이 알림을 삭제할까요?")<br>• 확정 시 deleteNotification | FR-14, FR-15 | NFR-2 |
| 3-1 | P2 | Realtime 으로 새 알림 자동 prepend (v2) | • 앱 포그라운드 + 인박스 열림<br>• `user_notifications` INSERT 이벤트 수신<br>• 리스트 상단에 prepend | FR-16, FR-17 | NFR-2 |
| 3-2 | P1 | markAsRead 실패 시 rollback | • 탭 → optimistic update<br>• 서버 실패 시 state rollback<br>• 상단 스낵바 "읽음 처리에 실패했어요" | FR-18 | NFR-2 |
| 3-3 | P1 | 삭제 실패 시 리스트 재조회 | • Dismissible 후 deleteNotification 실패<br>• 리스트 재조회 → 알림 복원<br>• 스낵바 "삭제에 실패했어요" | FR-19 | NFR-2 |
| 3-4 | P1 | 빈 상태 (알림 0건) | • 일러스트 + "아직 알림이 없어요"<br>• "첫 이벤트를 찾아 신청해보세요" 안내<br>• "이벤트 둘러보기 →" CTA → 홈 이동 | FR-20 | NFR-1 |
| 3-5 | P0 | 네트워크 에러 시 재시도 UI | • 인박스 진입 중 네트워크 실패<br>• 중앙 cloud_off 아이콘 + "알림을 불러올 수 없어요"<br>• "다시 시도" 버튼 | FR-21 | NFR-2 |

## Functional Requirements

> 제품 행동 정의 — DB schema SQL / Provider 이름 / Repository 메서드 시그니처 같은 dev detail 은 제외 (코드/migration 이 SSoT).

- **FR-1**: app_user / app_partner 양쪽 홈 AppBar 벨 아이콘에 미읽음 카운트 배지 표시 (공용 위젯 — 시각 / 동작 동일).
- **FR-2**: 미읽음 카운트가 0 이면 배지 미노출, 1 ~ 99 면 정확한 숫자, 100 이상이면 "99+".
- **FR-3**: 벨 아이콘 탭 시 `/notifications` 라우트 진입. 초기 20 건 알림 카드 노출.
- **FR-4**: 알림 카드 탭 시 (a) markAsRead optimistic, (b) deep_link 가 있으면 라우트 push.
- **FR-5**: 인박스 재방문 시 이미 읽은 알림은 읽음 시각으로 표시.
- **FR-6**: AppBar "모두 읽음" 버튼 탭 시 현재 유저의 모든 미읽음 알림 일괄 처리. 벨 배지 즉시 사라짐.
- **FR-7**: 미읽음 카드는 좌측 3px primary 컬러 세로 바 + 배경 primary@8% + 타이틀 굵게로 시각 구분.
- **FR-8**: 알림 카드는 카테고리에 대응하는 아이콘을 좌측에 표시 (event / matching / ticket / payment / service).
- **FR-9**: 시간은 (a) < 1분 "방금 전", (b) < 1시간 "N분 전", (c) < 24시간 "N시간 전", (d) < 7일 "N일 전", (e) ≥ 7일 `yyyy-MM-dd` 절대 시간.
- **FR-10**: 인박스 리스트 하단 도달 시 자동으로 다음 20 건 fetch (limit 20, offset = 로딩된 카운트).
- **FR-11**: 페이지 추가 로딩 중 리스트 하단에 진행 인디케이터 (40x40) + "불러오는 중…" 표시.
- **FR-12**: (v2) AppBar 필터 아이콘 탭 → FilterChip 슬라이드 다운. `[모두]` / `[안 읽음 (N)]` 2종 (v1 후속), 카테고리 4종 (v2 후속).
- **FR-13**: (v2) 카테고리 필터는 notification-worker 가 `notification_category` enum 을 실제 주입한 후에만 의미 있음. v1 에선 모든 카테고리가 `service` default 일 가능성.
- **FR-14**: 알림 카드 좌→우 스와이프 시 삭제 확인 다이얼로그 노출. dismiss 즉시 삭제 금지.
- **FR-15**: 다이얼로그에서 "삭제" 확정 시 deleteNotification 호출. "취소" 시 카드 원복.
- **FR-16**: (v2) 앱 포그라운드 + 인박스 열림 상태에서 `user_notifications` INSERT realtime 이벤트 수신 시 리스트 상단에 prepend.
- **FR-17**: (v2) 백그라운드 진입 시 realtime 구독 해제. 포그라운드 복귀 시 재구독.
- **FR-18**: markAsRead 실패 시 클라이언트 state rollback + 상단 스낵바 "읽음 처리에 실패했어요" 표시.
- **FR-19**: deleteNotification 실패 시 리스트 재조회로 알림 복원 + 스낵바 "삭제에 실패했어요" 표시.
- **FR-20**: 알림 0 건일 때 일러스트 + 안내 + "이벤트 둘러보기 →" CTA (홈 라우트 이동).
- **FR-21**: 네트워크 에러 시 중앙에 cloud_off 아이콘 + "알림을 불러올 수 없어요" + "다시 시도" 버튼.

## Non-Functional Requirements

> 측정 가능해야 함 — "빨라야 함" 금지. 환경 + 분위수 명시 (예: "에뮬레이터 baseline, p50 200ms 이내").

- **NFR-1**: 인박스 진입 → first paint 300ms 이내 (에뮬레이터 baseline, p50, 초기 20건 + 캐시 hit). 빈 상태 / 에러 화면도 동일.
- **NFR-2**: 알림 액션 (markAsRead / markAllAsRead / delete / loadMore) 응답 ≤ 1s (p95, 프로덕션 네트워크). 실패 시 NFR-2 의 rollback / 재시도 UI 활성.
- **NFR-3**: 접근성 — 벨 아이콘 `Semantics(label: '알림 N건 안 읽음')`. 알림 카드 `Semantics(label: '읽음/안 읽음 + 타이틀 + 본문 + 상대시간')`. 미읽음은 색상뿐 아니라 굵기 / 좌측 바로 구분.
- **NFR-4**: 벨 배지 카운트 정확도 — v1 에선 현재 로딩된 페이지 기준 근사값 허용. 정확도 필요 시 별도 count query (출시 후 데이터 보고 결정).

## Edge Cases

| CUJ ID | 케이스 | 기대 동작 |
|--------|--------|----------|
| 1-1 | 벨 배지 카운트 vs 실제 미읽음 불일치 (페이지네이션 근사) | v1 허용 (NFR-4). v2 별도 count query 검토 |
| 1-2 | 인박스 진입 직후 새 알림 도착 (v1 — realtime 미지원) | v1 미반영 (앱 재진입 시 fetch). v2 에서 자동 prepend |
| 1-3 | deep_link null | 기존 SnackBar "이동할 경로가 없어요" (이미 적용) |
| 1-3 | deep_link 비정상 (외부 URL / scheme) | 기존 `startsWith('/')` 검증으로 차단 (이미 적용) |
| 1-3 | 동시 탭 (여러 알림 빠르게 탭) | 첫 탭 이후 disable 로직 (다중 push 스택 방지) |
| 1-3 | 탭 후 markAsRead 실패 → deep_link 는 성공 | UI 는 deep_link 이동, 인박스 복귀 시 rollback 가시화 (스낵바) |
| 1-4 | 모두 읽음 중 일부 실패 | 전체 rollback + 스낵바. 부분 성공 금지 |
| 1-5 | 미읽음 강조와 카테고리 컬러 충돌 | 미읽음 좌측 바 우선 (카테고리는 아이콘으로만 구분) |
| 1-6 | 시간대 다른 디바이스 (해외 여행) | 디바이스 로컬 시간 기준 계산 |
| 2-1 | 무한 스크롤 fetch 실패 | 리스트 하단 에러 + "다시 시도" 버튼. 기존 알림은 유지 |
| 2-1 | hasMore false 인데 스크롤 도달 | fetch 호출 안 함 |
| 2-2 | (v2) 필터 변경 중 새 알림 도착 | realtime prepend 시 필터 적용 (mismatch 면 미노출) |
| 2-4 | Swipe 중 삭제 확인 다이얼로그 dismiss (백 탭) | 카드 원복. 삭제 안 함 |
| 3-1 | (v2) realtime INSERT 받았으나 본인 알림 아님 | RLS 로 본인 알림만 수신. 추가 클라이언트 필터 불필요 |
| 3-2 | markAsRead 실패 + 즉시 deep_link 이동 | rollback 은 인박스 복귀 시 가시화 |
| 3-3 | 삭제 실패 시 재조회 중 다른 카드 swipe | 재조회 완료까지 swipe disable |
| 3-4 | 빈 상태에서 CTA 탭 → 홈에 신청 가능 이벤트 0건 | 홈의 빈 상태 정책 (본 PRD 범위 외) |

## Open Questions

> 결정 못한 항목 — 1주 이상 방치 시 명시적으로 결정 또는 Non-Goal 로 이동.

- [ ] **v1 ship 단위** — 6 개 항목 한 번에 ship vs 배지만 먼저 빠르게 분리?
- [ ] **Realtime (G5) 우선순위** — v2 로 연기 vs 파트너 헤비 유저 (현수) 페르소나는 강한 니즈 — v1.5 분리?
- [ ] **notification-worker 카테고리 주입** — 별도 이슈 (PM) vs swe 가 구현 중 스핀오프?
- [ ] **빈 상태 일러스트 asset** — ux-designer 에게 의뢰 vs emoji 임시본으로 v1 진행?
- [ ] **벨 배지 카운트 정확도** — v1 페이지네이션 근사 허용 vs 별도 count query 도입?
- [ ] **카테고리 필터 chip 디자인** — 단순 chip vs 아이콘 chip?
- [ ] **삭제 confirm 다이얼로그 vs undo 스낵바** — 다이얼로그가 다크 패턴이 아닌지 재검토 (현재 다이얼로그 가정)

---

## 화면 구성 (참고)

> dev 가 아닌 product/UX detail 만. MDS spec 이 SSoT.

### 1. 홈 벨 아이콘 (배지 포함)

**위치**: app_user / app_partner 홈 AppBar 우상단.

```
[버그리포트] [검색 🔍] [알림 🔔 (배지)] [아바타]
                            ↑ unreadCount > 0 일 때 빨간 원 + 숫자 (최대 "99+")
```

**스타일**: app_partner 의 기존 구현과 동일. `NotificationBellWithBadge` 공용 위젯으로 추출.

### 2. 인박스 화면

#### 2.1 AppBar

```
[← 뒤로] 알림 센터              [필터 🎚 (v2)] [모두 읽음 ✓]
```

#### 2.2 Filter Bar (v2 — 접힘 / 펼침)

```
┌─────────────────────────────────────────┐
│  [모두] [안 읽음 (3)] [이벤트] [매칭] [티켓] │
└─────────────────────────────────────────┘
```

#### 2.3 알림 카드 (개선 후)

```
┌─────────────────────────────────────┐
│ 🎫  이벤트 승인 완료                  │  ← 카테고리 아이콘
│    "한남 재즈 나이트" 신청이 승인됐어요  │
│    3시간 전 · 이벤트                  │  ← 상대 시간 + 카테고리 라벨
└─────────────────────────────────────┘
```

미읽음 시 좌측 3px primary 컬러 세로 바 + 배경 primary@8% + 타이틀 굵게.

**카테고리 아이콘 매핑**:

| 카테고리 | 아이콘 |
|----------|--------|
| event | Icons.event |
| matching | Icons.favorite |
| ticket | Icons.confirmation_number |
| payment | Icons.payments |
| service (default) | Icons.campaign |

**상대 시간 포맷**:

| 조건 | 표기 |
|------|------|
| < 1분 | "방금 전" |
| < 1시간 | "N분 전" |
| < 24시간 | "N시간 전" |
| < 7일 | "N일 전" |
| ≥ 7일 | `yyyy-MM-dd` |

#### 2.4 빈 상태 (알림 0건)

```
┌─────────────────────────────────────┐
│                                     │
│          📭 (일러스트)               │
│                                     │
│     아직 알림이 없어요                │
│   첫 이벤트를 찾아 신청해보세요         │
│                                     │
│      [이벤트 둘러보기 →]             │
│                                     │
└─────────────────────────────────────┘
```

#### 2.5 삭제 확인 다이얼로그

```
[알림 삭제]
이 알림을 삭제할까요? 삭제된 알림은 복구할 수 없어요.

   [취소]    [삭제]
```

### 데이터 정의 (참고)

| 항목 | key | 설명 |
|------|-----|------|
| 알림 ID | `user_notifications.id` | UUID |
| 카테고리 | `user_notifications.category` | enum: event / matching / ticket / payment / service |
| 타이틀 | `user_notifications.title` | 알림 제목 |
| 본문 | `user_notifications.body` | 알림 본문 |
| 딥링크 | `user_notifications.deep_link` | 시작이 `/` 인 라우트 path 만 허용 |
| 읽음 여부 | `user_notifications.is_read` | boolean |
| 메타 | `user_notifications.metadata` | jsonb (확장 필드) |
| 생성 시각 | `user_notifications.created_at` | timestamptz |
