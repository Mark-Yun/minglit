# Event Now Bar — 기술 설계

## 구현 이슈 분할

| 순서 | 제목 | 라벨 | 의존성 | 비고 |
|------|------|------|--------|------|
| 1 | `MatchingVoteScreen` → `MatchingVoteContent` 위젯 추출 리팩터링 | `refactor` | 없음 | Scaffold 분리, 바텀시트 임베드 준비 |
| 2 | `todayActiveEventsProvider` + Supabase 쿼리 구현 | `feat` | 없음 | `event_participants` JOIN `events` WHERE user_id = me AND 시간 범위 |
| 3 | `EventNowBarState` 상태 머신 + Controller | `feat` | #2 | 6-state 상태 머신, @riverpod class |
| 4 | Supabase Realtime 구독 패턴 수립 + `eventRealtimeProvider` | `feat` | #3 | 프로젝트 최초 Realtime 사용, 30초 폴링 fallback 포함 |
| 5 | 나우바 미니바 위젯 (EventNowBar) | `feat` | #3 | 56px 퍼시스턴트 바, 상태별 dot 색상, pulse 애니메이션 |
| 6 | 체크인 바텀시트 (Phase 1: QR 표시) | `feat` | #5 | `TicketQRViewer` 재사용, 위치 딥링크 |
| 7 | 매칭 바텀시트 (Phase 3: 투표 임베드) | `feat` | #1, #5 | `MatchingVoteContent` 임베드, DraggableScrollableSheet |
| 8 | 결과 + 종료 바텀시트 (Phase 4, 5) | `feat` | #5 | `myMatchesProvider` 재사용, 리뷰/추천 |
| 9 | 멀티 이벤트 스택 UI | `feat` | #5 | 우선순위 정렬, 드롭다운 선택 |
| 10 | 오프라인/에러 fallback + 통합 테스트 | `test` | 전체 | 캐시 유지, 오프라인 표시, Realtime 재연결 |

## 수정 대상 파일

### 프론트엔드 — 신규

| 파일 | 변경 내용 |
|------|----------|
| `apps/app_user/lib/src/features/home/widgets/event_now_bar.dart` | 퍼시스턴트 미니바 위젯 (56px, 상태별 dot, pulse 애니메이션) |
| `apps/app_user/lib/src/features/home/widgets/event_now_bar_controller.dart` | `EventNowBarState` 상태 머신 (@riverpod class), `todayActiveEventsProvider`, `eventNowBarStateProvider(eventId)` |
| `apps/app_user/lib/src/features/home/widgets/event_now_bottom_sheet.dart` | 상태별 바텀시트 (Phase 1~5), `showModalBottomSheet(isScrollControlled: true)` |
| `apps/app_user/lib/src/features/home/widgets/event_now_multi_stack.dart` | 멀티 이벤트 드롭다운 UI, 우선순위 정렬 로직 |

### 프론트엔드 — 기존 수정

| 파일 | 변경 내용 |
|------|----------|
| `apps/app_user/lib/src/features/event/matching/matching_vote_screen.dart` | `MatchingVoteContent` 위젯 추출 (Scaffold body → 독립 위젯) |
| `apps/app_user/lib/src/features/home/home_page.dart` | `EventNowBar` 위젯 통합 (BottomNavigationBar 위에 배치) |

### 백엔드 (신규)

| 파일 | 변경 내용 |
|------|----------|
| 없음 | 기존 테이블/EF/RPC로 충분. 신규 백엔드 변경 불필요. |

## 아키텍처 결정

### 1. 나우바 배치 위치

`app_user`에는 `StatefulShellRoute`가 없고, `HomePage`가 직접 `BottomNavigationBar`를 소유한다.
나우바는 `HomePage`의 `Scaffold.bottomNavigationBar` 위에 `Column`으로 배치한다.
새로운 Shell Route 도입은 불필요 — 나우바는 홈 화면 전용이며 다른 탭으로 이동하면 보이지 않아도 된다.

### 2. Supabase Realtime 패턴 (프로젝트 최초)

코드베이스에 Supabase Realtime 사용 사례가 없으므로 패턴을 새로 수립한다:

```dart
// eventRealtimeProvider — Riverpod StreamProvider 패턴
@riverpod
Stream<void> eventRealtime(Ref ref, String eventId) {
  final supabase = ref.watch(supabaseClientProvider);
  final channel = supabase.channel('event-now-$eventId');

  ref.onDispose(() => channel.unsubscribe());

  // event_participants 변경 감지 → 상태 재계산 트리거
  return channel
    .onPostgresChanges(...)
    .subscribe()
    .asStream();
}
```

**Fallback**: Realtime 연결 실패 시 `Timer.periodic(Duration(seconds: 30))` 폴링.

### 3. 상태 머신 구현

`EventAdmissionController`의 패턴을 따른다: `@riverpod class` + `FutureOr<State> build(eventId)`.
상태 전이는 `eventRealtimeProvider`가 invalidate할 때 `build()`가 재실행되어 자동으로 갱신된다.

### 4. 매칭 상태 파생

`events.status`는 `scheduled/cancelled/completed`만 가짐. MATCHING/RESULTS 상태는:
- MATCHING: `matchCandidatesProvider(eventId)`가 빈 리스트가 아닐 때
- RESULTS: `myMatchesProvider(eventId)`가 결과를 반환할 때

이 파생 로직은 `eventNowBarStateProvider` 내부에서 처리한다.

## 리스크 및 대응

| 리스크 | 확률 | 대응 |
|--------|------|------|
| Supabase Realtime 연결 불안정 (첫 도입) | 중 | 30초 폴링 fallback 구현, 연결 상태 모니터링 로그 추가 |
| BottomNavigationBar + NowBar 레이아웃 깨짐 (safe area) | 중 | 56px 고정 높이 + MediaQuery.padding.bottom 계산, 기기별 테스트 |
| MatchingVoteContent 추출 시 기존 기능 회귀 | 저 | 추출 전 기존 MatchingVoteScreen 테스트 보강 후 리팩터링 |
| 멀티 이벤트 동시 Realtime 채널 (채널 수 제한) | 저 | 한 유저가 동시 참여하는 이벤트는 현실적으로 2~3개 이하 |
| pulse 애니메이션 배터리 소모 | 저 | `MinglitAnimation.medium` (350ms) 기반, 결과 상태에서만 활성 |
