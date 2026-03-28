# Event Now Bar — 테스트 보강 계획

## 개요

Event Now Bar는 홈 하단에 당일 이벤트 상태를 실시간 안내하는 퍼시스턴트 UI다.
6-state 상태 머신, Supabase Realtime (프로젝트 최초), 멀티 이벤트 스택이 핵심이다.
백엔드 변경 없음 (기존 테이블/EF/RPC 활용) → DB/EF 테스트 불필요.

**참고**: `docs/qa/AUTOMATION_TEST_GUIDE.md`

---

## 계층별 테스트 계획

### Layer 1: Edge Function 테스트 (Deno)

해당 없음 — 신규 백엔드 변경 없음.

### Layer 2: Controller/Provider 테스트 (순수 로직)

| 대상 | 파일 | 테스트 케이스 | 우선순위 |
|------|------|-------------|---------|
| `todayActiveEventsProvider` | `apps/app_user/test/src/features/home/logic/today_active_events_provider_test.dart` | 아래 상세 | P1 |
| `eventNowBarStateProvider` | `apps/app_user/test/src/features/home/logic/event_now_bar_state_provider_test.dart` | 아래 상세 | P1 |
| `eventRealtimeProvider` | `apps/app_user/test/src/features/home/logic/event_realtime_provider_test.dart` | 아래 상세 | P1 |
| 멀티 이벤트 정렬 로직 | `apps/app_user/test/src/features/home/logic/event_now_multi_stack_test.dart` | 아래 상세 | P2 |

#### `todayActiveEventsProvider` — 오늘 활성 이벤트 목록 조회

```
✅ happy path: 오늘 시작 3시간 전 ~ 종료 범위 이벤트 반환
✅ 활성 이벤트 0건 → 빈 리스트 반환 (나우바 비표시 조건)
✅ 취소된 이벤트(status='cancelled') 포함 여부 — 취소도 반환해야 나우바에서 "취소됨" 표시 가능
✅ 환불(status='refunded') 참가자 → 해당 이벤트 제외
✅ 자정 넘긴 이벤트 — endTime 기준으로 활성 판단
✅ 에러 시 MingleException throw
```

#### `eventNowBarStateProvider` — 6-state 상태 머신

```
✅ WAITING: 시작 3시간 전 ~ 시작 시간 전
✅ CHECK_IN_READY: 시작 시간 도달 + participant.status ≠ 'checked_in'
✅ CHECKED_IN: participant.status = 'checked_in' + matchCandidates 비어있음
✅ MATCHING: matchCandidatesProvider가 비어있지 않음
✅ RESULTS: myMatchesProvider 결과 존재
✅ ENDED: events.status = 'completed'
✅ 취소 이벤트: events.status = 'cancelled' → 별도 상태 또는 ENDED 변형
✅ 상태 전이 순서 보장: WAITING → CHECK_IN_READY → CHECKED_IN → MATCHING → RESULTS → ENDED
✅ 역방향 전이 불가 (예: CHECKED_IN → WAITING 안 됨)
✅ 매칭 결과 0건일 때 RESULTS 상태 진입 (빈 매칭도 결과임)
```

#### `eventRealtimeProvider` — Realtime 구독 + 폴링 fallback

```
✅ 구독 시작 시 채널 생성 + subscribe 호출
✅ Postgres change 수신 시 eventNowBarStateProvider invalidate
✅ 구독 closed → 30초 폴링 fallback 전환
✅ dispose 시 unsubscribe 호출 (리소스 정리)
✅ 여러 이벤트 동시 구독 시 채널 격리
```

#### 멀티 이벤트 정렬 로직

```
✅ 진행 중(CHECK_IN~RESULTS) > 대기(WAITING) > 종료(ENDED) 순서
✅ 같은 상태 내 시작 시간 빠른 순
✅ 이벤트 1건 → 스택 UI 안 보임 (배지 없음)
✅ 이벤트 2건+ → 우선순위 정렬 + 카운트 배지
✅ 종료된 이벤트가 스택 하단에 유지 (리뷰 작성용)
```

### Layer 3: Widget 테스트 (Flutter)

| 위젯 | 파일 | 테스트 케이스 | 우선순위 |
|------|------|-------------|---------|
| `EventNowBar` | `apps/app_user/test/src/features/home/ui/event_now_bar_test.dart` | 아래 상세 | P1 |
| `EventNowBottomSheet` | `apps/app_user/test/src/features/home/ui/event_now_bottom_sheet_test.dart` | 아래 상세 | P1 |
| `EventNowMultiStack` | `apps/app_user/test/src/features/home/ui/event_now_multi_stack_test.dart` | 아래 상세 | P2 |
| `MatchingVoteContent` 추출 | `apps/app_user/test/src/features/event/ui/matching_vote_content_test.dart` | 아래 상세 | P1 |
| `HomePage` 통합 | `apps/app_user/test/src/features/home/ui/home_page_now_bar_test.dart` | 아래 상세 | P2 |

#### `EventNowBar` — 퍼시스턴트 미니바

```
✅ 활성 이벤트 있을 때 나우바 렌더링 (56px 높이)
✅ 활성 이벤트 없을 때 나우바 비표시
✅ 상태별 dot 색상 변경 (WAITING=textSecondary, CHECK_IN_READY=primary, ...)
✅ 이벤트명 1줄 말줄임 (긴 제목)
✅ 상태 텍스트 표시 (체크인 대기 중, 매칭 투표 중 등)
✅ 시작 전: 시작 시간 표시 / 진행 중: 화살표 아이콘
✅ 탭 시 바텀시트 열림 (showModalBottomSheet 호출)
✅ 로딩 상태: Shimmer placeholder
✅ 오프라인 상태: "(오프라인)" 텍스트 + 캐시 상태 유지
```

#### `EventNowBottomSheet` — 상태별 바텀시트

```
Phase 1 (체크인 전):
  ✅ QR 코드 표시 (TicketQRViewer 렌더링)
  ✅ 이벤트명 + 시간 + 장소 표시
  ✅ "위치 안내 보기" 탭 → 딥링크 호출
  ✅ QR 로딩 실패 → 재시도 버튼 + 에러 메시지

Phase 2 (체크인 완료 → 매칭 대기):
  ✅ "체크인 완료!" 표시
  ✅ 참석자 수 표시 (실시간)
  ✅ 아바타 row (최대 5개 + 나머지 카운트)
  ✅ 참석자 정보 로딩 실패 → placeholder circle

Phase 3 (매칭 투표 중):
  ✅ MatchingVoteContent 위젯 임베드 렌더링
  ✅ 남은 투표 수 표시
  ✅ DraggableScrollableSheet로 풀스크린 확장 가능
  ✅ 매칭 후보 로딩 → 스켈레톤 카드 3개

Phase 4 (매칭 결과):
  ✅ 매칭 결과 프로필 카드 표시
  ✅ 매칭 0건 → 빈 상태 ("이번엔 아쉽지만, 다음 기회에!")

Phase 5 (이벤트 종료):
  ✅ 별점 리뷰 UI 표시
  ✅ "리뷰 작성하기" CTA 버튼
  ✅ 다음 추천 이벤트 카드 표시
```

#### `EventNowMultiStack` — 멀티 이벤트 드롭다운

```
✅ 이벤트 1건 → 카운트 배지 + 드롭다운 아이콘 없음
✅ 이벤트 2건+ → 카운트 배지 + 드롭다운 아이콘 표시
✅ 탭 시 이벤트 목록 바텀시트 열림
✅ 이벤트 선택 → 해당 이벤트 상세 시트 전환
✅ 우선순위 순서로 정렬되어 표시
```

#### `MatchingVoteContent` 추출 리팩터링 검증

```
✅ 기존 MatchingVoteScreen이 MatchingVoteContent를 사용하여 동일 렌더링
✅ MatchingVoteContent 단독 렌더링 (Scaffold 없이)
✅ 바텀시트 내 임베드 시 스크롤 충돌 없음
```

#### `HomePage` + `EventNowBar` 통합

```
✅ HomePage에 EventNowBar가 하단 고정 배치
✅ CustomScrollView 스크롤 시 나우바 위치 유지
✅ safe area 처리 (MediaQuery.padding.bottom)
```

### Layer 4: Golden 테스트 (시각적 회귀)

| 화면 | 변형 | 파일 | 우선순위 |
|------|------|------|---------|
| EventNowBar | 6개 상태 × 각각 | `apps/app_user/test/goldens/event_now_bar_golden_test.dart` | P2 |
| EventNowBar | 오프라인 상태 | 동일 | P3 |
| EventNowBottomSheet | Phase 1~5 각각 | `apps/app_user/test/goldens/event_now_bottom_sheet_golden_test.dart` | P2 |
| EventNowBottomSheet | Phase 4 빈 매칭 | 동일 | P3 |
| EventNowMultiStack | 1건 / 2건+ | `apps/app_user/test/goldens/event_now_multi_stack_golden_test.dart` | P3 |

```dart
// Golden 테스트 예시
@Tags(['golden'])
library;

goldenTest(
  'EventNowBar states',
  fileName: 'event_now_bar_states',
  builder: () => GoldenTestGroup(
    children: [
      GoldenTestScenario(name: 'waiting', child: /* WAITING 상태 */),
      GoldenTestScenario(name: 'check_in_ready', child: /* CHECK_IN_READY */),
      GoldenTestScenario(name: 'checked_in', child: /* CHECKED_IN */),
      GoldenTestScenario(name: 'matching', child: /* MATCHING */),
      GoldenTestScenario(name: 'results', child: /* RESULTS + pulse */),
      GoldenTestScenario(name: 'ended', child: /* ENDED */),
    ],
  ),
);
```

### Layer 5: DB 테스트 (pgTAP)

해당 없음 — 신규 테이블/마이그레이션 없음.

---

## 엣지 케이스 테스트

| 케이스 | 테스트 위치 | 우선순위 |
|--------|-----------|---------|
| 이벤트 취소 → 나우바 "취소됨" 표시 → 1시간 후 해제 | state provider + widget | P1 |
| 환불 처리 → 나우바 해제 | state provider | P1 |
| 자정 넘긴 이벤트 (endTime 기준) | todayActiveEventsProvider | P2 |
| 앱 킬 → 재시작 → 나우바 복원 | state provider (re-fetch) | P2 |
| Realtime 연결 끊김 → 30초 폴링 전환 | eventRealtimeProvider | P1 |
| 멀티 이벤트 동시 Realtime 채널 | eventRealtimeProvider | P2 |
| pulse 애니메이션 (RESULTS 상태에서만) | widget + golden | P3 |
| 매칭 결과 0건 | bottom sheet widget | P1 |
| 긴 이벤트명 말줄임 | widget + golden | P3 |

---

## 리팩터링 회귀 방지

`MatchingVoteScreen` → `MatchingVoteContent` 추출 시, 기존 기능이 깨지지 않도록:

1. **추출 전**: 기존 `MatchingVoteScreen` 테스트 보강 (현재 테스트 부족 — `app_user/event` 커버리지 24%)
2. **추출 후**: `MatchingVoteScreen`이 `MatchingVoteContent`를 사용하여 동일 동작 검증
3. **임베드 검증**: 바텀시트 내 `MatchingVoteContent` 렌더링 + 스크롤 동작

---

## 실행 순서

### P1 (필수): 14건
- `eventNowBarStateProvider` 상태 머신 테스트 (10 케이스)
- `todayActiveEventsProvider` 테스트 (6 케이스)
- `eventRealtimeProvider` Realtime + fallback 테스트 (5 케이스)
- `EventNowBar` 위젯 테스트 (9 케이스)
- `EventNowBottomSheet` Phase 1~5 위젯 테스트 (13 케이스)
- `MatchingVoteContent` 추출 검증 (3 케이스)
- 이벤트 취소/환불 엣지 케이스 (2 케이스)
- Realtime 끊김 → 폴링 전환 (1 케이스)
- 매칭 결과 0건 빈 상태 (1 케이스)

→ 총 약 50 test cases

### P2 (권장): 8건
- 멀티 이벤트 정렬 로직 테스트 (5 케이스)
- `EventNowMultiStack` 위젯 테스트 (5 케이스)
- `HomePage` + `EventNowBar` 통합 테스트 (3 케이스)
- Golden: EventNowBar 6개 상태 (6 시나리오)
- Golden: EventNowBottomSheet 5개 Phase (5 시나리오)
- 자정 넘긴 이벤트 (1 케이스)
- 멀티 Realtime 채널 격리 (1 케이스)
- 앱 킬 → 복원 (1 케이스)

→ 총 약 27 test cases

### P3 (선택): 4건
- Golden: EventNowMultiStack (2 시나리오)
- Golden: 오프라인 상태 (1 시나리오)
- Golden: 빈 매칭 결과 (1 시나리오)
- pulse 애니메이션 검증 (1 케이스)
- 긴 이벤트명 말줄임 (1 케이스)

→ 총 약 6 test cases

---

**총 83 test cases** (P1: 50건, P2: 27건, P3: 6건)
