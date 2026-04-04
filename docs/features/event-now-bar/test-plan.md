# Event Now Bar — 테스트 보강 계획

## 개요

Event Now Bar는 홈 하단에 당일 이벤트 상태를 실시간 안내하는 퍼시스턴트 UI다.
6-state 상태 머신, Supabase Realtime (프로젝트 최초), 멀티 이벤트 스택이 핵심이다.
백엔드 변경 없음 (기존 테이블/EF/RPC 활용) → DB/EF 테스트 불필요.

**참고**: `docs/qa/automation-test-guide.md`

### 피처 파이프라인

| 단계 | 담당 | 이슈 | PR | 산출물 | 상태 |
|------|------|------|-----|--------|------|
| 기획 | pm-staff | #580 | #584 | spec.md, wireframe.html | 완료 |
| UX 리뷰 | audit-uiux | #585 | - | 리뷰 코멘트 | 완료 |
| 기술 설계 | audit-arch | #587 | #598 | plan.md | 완료 |
| 테스트 계획 | audit-qa | #602 | 현재 PR | test-plan.md | 진행 중 |
| 이슈 파일링 | tpm-staff | - | - | 에픽 + 서브이슈 | 대기 |

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

## Supabase Realtime 모킹 가이드

프로젝트 최초 Realtime 사용이므로 Mock 패턴을 수립한다.

### Mock 구조

```dart
// test/utils/realtime_mocks.dart
class MockRealtimeChannel extends Mock implements RealtimeChannel {}
class MockSupabaseClient extends Mock implements SupabaseClient {
  final MockRealtimeChannel _channel = MockRealtimeChannel();

  @override
  RealtimeChannel channel(String name, [RealtimeChannelConfig? config]) {
    return _channel;
  }
}
```

### 핵심 Mock 시나리오

```text
1. 정상 구독:
   - channel() 호출 → MockRealtimeChannel 반환
   - onPostgresChanges() 체이닝 → subscribe() 호출 검증
   - callback 직접 호출로 change 이벤트 시뮬레이션

2. 연결 끊김 시뮬레이션:
   - subscribe()의 status callback에 RealtimeSubscribeStatus.closed 전달
   - 30초 폴링 fallback 전환 검증 (Timer.periodic 호출 확인)

3. 재연결:
   - closed 후 다시 subscribe → 폴링 중지 + Realtime 복귀 검증

4. dispose 정리:
   - ref.onDispose 트리거 → unsubscribe() 호출 검증
   - 채널 null 처리 검증
```

### 테스트 예시

```dart
test('Realtime closed → 30초 폴링 fallback', () async {
  late void Function(RealtimeSubscribeStatus, [Object?]) statusCallback;

  when(() => mockChannel.subscribe(any())).thenAnswer((inv) {
    statusCallback = inv.positionalArguments[0];
    return mockChannel;
  });

  // Provider 생성 → subscribe 호출
  container.read(eventRealtimeProvider('event_1'));
  verify(() => mockChannel.subscribe(any())).called(1);

  // 연결 끊김 시뮬레이션
  statusCallback(RealtimeSubscribeStatus.closed);

  // 폴링 fallback 전환 검증
  // (Timer.periodic 호출 또는 폴링 provider invalidate 확인)
});
```

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

### P1 (필수) — 50 test cases

| # | 테스트 그룹 | 파일 | 케이스 수 |
|---|-----------|------|----------|
| 1 | `eventNowBarStateProvider` 상태 머신 | `home/logic/event_now_bar_state_provider_test.dart` | 10 |
| 2 | `todayActiveEventsProvider` 이벤트 조회 | `home/logic/today_active_events_provider_test.dart` | 6 |
| 3 | `eventRealtimeProvider` Realtime + fallback | `home/logic/event_realtime_provider_test.dart` | 5 |
| 4 | `EventNowBar` 위젯 | `home/ui/event_now_bar_test.dart` | 9 |
| 5 | `EventNowBottomSheet` Phase 1~5 | `home/ui/event_now_bottom_sheet_test.dart` | 13 |
| 6 | `MatchingVoteContent` 추출 검증 | `event/ui/matching_vote_content_test.dart` | 3 |
| 7 | 엣지: 이벤트 취소/환불 | (1, 4번에 포함) | 2 |
| 8 | 엣지: Realtime 끊김 → 폴링 | (3번에 포함) | 1 |
| 9 | 엣지: 매칭 결과 0건 | (5번에 포함) | 1 |

> 엣지 케이스(7~9번)는 별도 파일이 아니라 해당 Provider/Widget 테스트 파일 내 group으로 작성.

### P2 (권장) — 27 test cases

| # | 테스트 그룹 | 파일 | 케이스 수 |
|---|-----------|------|----------|
| 1 | 멀티 이벤트 정렬 로직 | `home/logic/event_now_multi_stack_test.dart` | 5 |
| 2 | `EventNowMultiStack` 위젯 | `home/ui/event_now_multi_stack_test.dart` | 5 |
| 3 | `HomePage` + `EventNowBar` 통합 | `home/ui/home_page_now_bar_test.dart` | 3 |
| 4 | Golden: EventNowBar 6개 상태 | `goldens/event_now_bar_golden_test.dart` | 6 |
| 5 | Golden: EventNowBottomSheet 5개 Phase | `goldens/event_now_bottom_sheet_golden_test.dart` | 5 |
| 6 | 엣지: 자정 넘긴 이벤트 | (P1-2번에 포함) | 1 |
| 7 | 엣지: 멀티 Realtime 채널 격리 | (P1-3번에 포함) | 1 |
| 8 | 엣지: 앱 킬 → 복원 | (P1-1번에 포함) | 1 |

### P3 (선택) — 6 test cases

| # | 테스트 그룹 | 파일 | 케이스 수 |
|---|-----------|------|----------|
| 1 | Golden: EventNowMultiStack | `goldens/event_now_multi_stack_golden_test.dart` | 2 |
| 2 | Golden: 오프라인/빈 매칭 변형 | (P2-4, P2-5번에 시나리오 추가) | 2 |
| 3 | pulse 애니메이션 검증 | (P1-4번에 포함) | 1 |
| 4 | 긴 이벤트명 말줄임 | (P1-4번에 포함) | 1 |

---

**총 83 test cases** (P1: 50건, P2: 27건, P3: 6건)

> 모든 파일 경로는 `apps/app_user/test/src/features/` 기준 상대 경로.
> Golden 테스트는 `apps/app_user/test/goldens/` 기준.
