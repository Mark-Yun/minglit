# Automation Test Guide

새 피쳐를 구현할 때 따라야 하는 자동화 테스트 가이드.

> 📖 Taxonomy SSOT: [`test-strategy.md`](test-strategy.md) — Layer 정의 / 책임 / 커버리지 수치
>
> 이 문서는 각 Layer 의 **작성 규칙 + 샘플 코드 + 체크리스트** 를 다룬다.

---

## 1. Layer 선택 결정 트리

구현 전 반드시 본 트리로 어느 Layer 에 테스트를 추가할지 결정한다.

```
새 테스트 추가 필요?
│
├── DB 스키마 / RLS / RPC 계약 변경?         → Layer 4 (pgTAP)
├── 신규 Edge Function 로직?                 → Layer 5 (Deno EF)
├── 네이티브 surface 필요?
│   (카카오 로그인, PG SDK, 시스템 권한)      → Layer 3 (Patrol emulator)
├── 다화면 플로우 / GoRouter guard / redirect? → Layer 2a (widget flow)
├── 디자인 토큰 / 시각 회귀 감지?             → Layer 2b (Alchemist golden)
├── repository / controller / util / model?   → Layer 1 (unit)
├── 매시간 실 DB 데이터 이상 감시?            → Layer 6 (DB monitor RPC)
└── 파이프라인 연쇄 동작 (tick) 감시?         → Layer 7 (backend-simulator)
```

**복수 Layer 필요 사례**:

- 신규 EF + 소비하는 controller → Layer 5 + Layer 1
- 신규 테이블 + RLS + 읽는 repository → Layer 4 + Layer 1
- 신규 화면 + 디자인 신규 컴포넌트 → Layer 2b (골든) + Layer 1 (controller) + Layer 2a (flow)
- 신규 CUJ + 네이티브 결제 → Layer 3 (Patrol) **필수**, Layer 2a 는 생략 가능

---

## 2. Layer 별 작성 규칙

### 📱 Layer 1 — Unit test

**위치**:
- `shared/packages/minglit_kit/test/src/`
- `apps/app_user/test/src/features/{feature}/`
- `apps/app_partner/test/src/features/{feature}/`

**파일 명**: `{name}_test.dart` (controller 는 `{name}_controller_test.dart`)

**프레임워크**: `flutter_test` (headless), `mocktail`

**샘플 (repository)**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late EventRepository repository;

  setUp(() {
    mockClient = createMockSupabase(currentUser: MockUser());
    repository = EventRepository(supabase: mockClient);
  });

  group('EventRepository.getEventById', () {
    test('returns event when found', () async {
      mockTable(mockClient, 'events', singleData: {
        'id': 'event_1', 'title': 'Test', 'status': 'scheduled',
      });

      final result = await repository.getEventById('event_1');
      expect(result.id, 'event_1');
    });

    test('throws MingleException when not found', () async {
      mockTable(mockClient, 'events',
        shouldThrow: PostgrestException(message: 'not found'));
      expect(() => repository.getEventById('x'), throwsA(isA<MingleException>()));
    });
  });
}
```

**샘플 (controller / provider)**:

```dart
test('loads event data on init', () async {
  when(() => mockRepo.getEventById(any())).thenAnswer((_) async => testEvent);

  final container = createContainer(overrides: [
    eventRepositoryProvider.overrideWithValue(mockRepo),
  ]);

  final state = await container.read(
    eventDetailControllerProvider('event_1').future,
  );

  expect(state.event.id, 'event_1');
  verify(() => mockRepo.getEventById('event_1')).called(1);
});
```

**핵심 패턴**:
- `createMockSupabase()` — Supabase 클라이언트 Mock (`minglit_kit/test/helpers/supabase_mock_helpers.dart`)
- `mockTable()` — 테이블 쿼리 Fake 결과
- `createContainer()` — Riverpod 테스트 컨테이너 (`apps/{app}/test/utils/test_utils.dart`)
- `mocktail` 사용 (mockito 아님)

---

### 📱 Layer 2a — Widget flow test

**위치**: `apps/app_*/test/integration/` (향후 `test/flows/` rename 검토)

**파일 명**: `{scenario}_test.dart` 또는 `cuj_*_test.dart`

**프레임워크**: `flutter_test` (headless) + `createTestApp()` 헬퍼

**샘플**:

```dart
void main() {
  testWidgets('비로그인 사용자 → 보호 경로 리다이렉트', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        isLoggedIn: false,
        initialLocation: '/events/event-1/apply',
        additionalOverrides: [
          eventDetailControllerProvider('event-1').overrideWith(
            () => _FakeEventDetailController(AsyncData(testEvent)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('로그인'), findsOneWidget);
  });
}
```

**핵심 패턴**:
- `createTestApp()` / `createPartnerTestApp()` — 라우터 + Provider 설정 (Supabase 불필요)
- `overrideWith()` — AsyncNotifier/Notifier 를 Fake 구현으로 교체
- `overrideWithValue()` — NotifierProvider 를 특정 상태 값으로 교체
- 실 네트워크 / 실 DB 호출 **금지** (→ Layer 3 에서 처리)

---

### 📱 Layer 2b — Golden image test (Alchemist)

**위치**: `apps/app_*/test/alchemist/` (`shared/packages/minglit_kit/test/goldens/` 예외)

**파일 명**: `{widget_name}_golden_test.dart`

**프레임워크**: [alchemist](https://pub.dev/packages/alchemist) (VGV + Betterment)

Golden Test는 위젯 렌더링 결과를 이미지로 저장해두고 이후 픽셀 비교로 시각적 회귀를 감지한다.
Alchemist를 사용하여 CI(Ahem 폰트) / 로컬(플랫폼 폰트) 골든을 분리 관리한다.

**샘플**:

```dart
// 파일명: status_badge_golden_test.dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  goldenTest(
    'StatusBadge renders correctly for all states',
    fileName: 'status_badge',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'active',
          child: const StatusBadge(status: 'active'),
        ),
        GoldenTestScenario(
          name: 'closed',
          child: const StatusBadge(status: 'closed'),
        ),
      ],
    ),
  );
}
```

---

## 4. 새 피쳐 구현 시 체크리스트

### MUST

- [ ] **Layer 1 unit** — 새 repository 메서드 / controller 마다 happy path + error case
- [ ] **Layer 4 pgTAP** — 새 테이블 / 컬럼 / RLS 정책 추가 시
- [ ] **Layer 5 Deno EF** — 새 Edge Function 추가 시
- [ ] **Layer 2a widget flow** — 신규 CUJ 또는 신규 화면 플로우 추가 시 `test/integration/cuj_*_test.dart`
- [ ] **Layer 2b golden** — 신규 컴포넌트 / 디자인 토큰 변경 시 (`@Tags(['golden'])`)

### SHOULD

- [ ] **Layer 3 Patrol** — 네이티브 surface 또는 실 DB 경로 검증이 핵심인 CUJ
- [ ] **Layer 1 widget** — 복잡한 상태 분기가 있는 UI 위젯
- [ ] **에러 핸들링** — 네트워크 오류, 인증 만료, 엣지 케이스

### MAY

- [ ] **Layer 6 invariant** — 새 테이블이 "절대 N 초과하면 안 된다" 같은 런타임 제약을 가질 때
- [ ] **Layer 7 tick** — 새 파이프라인 단계가 시간 기반 trigger 에 의존할 때

---

## 5. 현재 커버리지 현황 (2026-04-18)

> 전체 수치 / 갭 상세는 [`test-strategy.md §4`](test-strategy.md#4-현재-커버리지-수치-2026-04-18) 참고.

| Layer | 위치 | 파일 수 |
|-------|------|--------|
| 1 (unit) | minglit_kit / app_user / app_partner `test/src/` | 99 / 65 / 71 |
| 2a (widget flow) | app_user / app_partner `test/integration/` | 26 / 11 |
| 2b (golden) | app_user / app_partner `test/alchemist/**_golden_test.dart` | 14 / 15 |
| 3 (Patrol) | app_user / app_partner `emulator_test/` | 5 / 1 (native surface 전용) |
| 4 (pgTAP) | `supabase/tests/database/*.sql` | 80 |
| 5 (Deno EF) | `supabase/functions/**/*_test.ts` | 75 |
| 6 (DB monitor) | `check_db_invariants()` RPC | 1 RPC (매시간) |
| 7 (tick simulator) | `backend-simulator` EF + 2 workflows | 매시간 + 매일 |

**핵심 갭**:
- 🔴 **Layer 3 CUJ 이관 0%** — 37 widget flow 를 Patrol 로 전환 필요 (#1586 Phase D-2)
- 🟡 **Layer 2a 일부 feature 부족** — app_partner integration 11 vs 요구 20+

---

## 6. 실행 명령어

```bash
# Layer 1 + 2a + 2b — Flutter 앱별
cd apps/app_user && flutter test
cd apps/app_partner && flutter test
cd shared/packages/minglit_kit && flutter test

# 특정 파일만
flutter test test/src/features/event/logic/event_detail_controller_test.dart

# Layer 2a 만 (widget flow)
cd apps/app_user && flutter test test/integration/
cd apps/app_partner && flutter test test/integration/

# Layer 2b 만 (golden)
cd apps/app_user && flutter test --tags golden --dart-define=CI=true
# Golden 갱신
cd apps/app_user && flutter test --update-goldens --tags golden --dart-define=CI=true

# Layer 2a 특정 CUJ (flutter_test / WidgetTester)
cd apps/app_user && flutter test test/integration/cuj_signup_to_apply_test.dart

# Layer 3 (Patrol) — 로컬 emulator 필요
cd apps/app_user && patrol test --target patrol_test/permission_grant_test.dart
# 여러 파일: --target 반복 또는 --targets 콤마 구분
# CI 에서는 patrol-e2e.yml 워크플로우

# Layer 4 pgTAP
supabase test db

# Layer 5 Deno EF
deno test --allow-all supabase/functions/
deno test --allow-all supabase/functions/payment-verify/

# Layer 6 — 수동 실행
psql -c "SELECT * FROM check_db_invariants();"

# Layer 7 — workflow_dispatch 로 수동 trigger
gh workflow run daily-backend-simulation.yml --ref dev
```

---

## 7. 주의사항

### DO

- Mock 데이터는 실제 DB 스키마(`supabase/migrations/`) 컬럼명과 일치
- `group()` 으로 논리 묶음 (클래스 → 메서드)
- Happy path + Error case 둘 다 작성
- `setUp()` 에서 Mock 초기화 — 테스트 격리
- Layer 5 EF 테스트에서 외부 API 는 **반드시 mock**

### DON'T

- Layer 1 / 2a / 2b 에서 실제 네트워크 호출 금지 (실 호출은 Layer 3 만)
- 테스트 간 상태 공유 금지
- Mock 반환값 하드코딩 금지 — 변수로 재사용
- `sleep()` / `Future.delayed()` 로 비동기 대기 금지
- generated 파일 (`*.g.dart`, `*.freezed.dart`) 테스트 대상 제외

---

## 8. CI 파이프라인 연동

`.github/workflows/ci.yml` 이 PR 마다 Layer 1 / 2a / 2b / 4 / 5 를 실행.

| 변경 영역 | 실행 Layer |
|----------|-----------|
| `apps/app_user/**`, `apps/app_partner/**` | 1 + 2a + 2b (해당 앱) |
| `shared/packages/minglit_kit/**` | 1 (모든 앱) |
| `supabase/migrations/**`, `supabase/tests/**` | 4 |
| `supabase/functions/**` | 5 |
| `apps/landing_*/**` | npm lint + build |

추가 워크플로우:
- `patrol-e2e.yml` — Layer 3 (주 1회 예정, 현재 런 0건)
- `db-invariants.yml` — Layer 6 (매시간)
- `daily-backend-simulation.yml` / `hourly-user-activity.yml` — Layer 7

---

## 9. Mock 유틸 참조

### Dart

| 유틸 | 위치 | 용도 |
|------|------|------|
| `createMockSupabase()` | `minglit_kit/test/helpers/supabase_mock_helpers.dart` | Supabase 클라이언트 Mock |
| `mockTable()` | 동일 | 테이블 쿼리 Fake |
| `MockSupabaseClient` | `minglit_kit/test/helpers/mocks.dart` | 기본 Mock 클래스 |
| `createContainer()` | `apps/{app}/test/utils/test_utils.dart` | Riverpod 컨테이너 |
| Repository Mocks | `apps/{app}/test/utils/mocks.dart` | `MockEventRepository` 등 |
| `createTestApp()` | `apps/app_user/test/integration/utils/test_app.dart` | Layer 2a 라우터 + Provider |
| `createPartnerTestApp()` | `apps/app_partner/test/integration/utils/test_app.dart` | 동일 (partner) |

### Deno (Edge Functions)

| 유틸 | 위치 | 용도 |
|------|------|------|
| `captureServeHandler()` | `supabase/functions/_test_utils/mock_http.ts` | EF handler 캡처 |
| `createFetchMock()` | 동일 | HTTP fetch Mock |
| `authenticatedJsonRequest()` | 동일 | 인증 JSON 요청 |
| `withEnv()` | 동일 | env 주입 |
| `withMockedFetch()` | 동일 | fetch 대체 |
| fixtures | `supabase/functions/_test_utils/fixtures.ts` | Mock 데이터 |
