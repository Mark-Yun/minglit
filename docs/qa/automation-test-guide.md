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

**위치**: `apps/app_*/test/goldens/` (향후 `test/alchemist/` rename — PR #1582)

**파일 명**: `{widget_name}_golden_test.dart`

**프레임워크**: [alchemist](https://pub.dev/packages/alchemist)

**샘플**:

```dart
@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/golden_test_helpers.dart';

void main() {
  goldenTest(
    'EventCard scheduled',
    fileName: 'event_card_scheduled',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(420),
      children: [
        GoldenTestScenario(
          name: 'scheduled',
          child: GoldenComponentWrapper(
            child: EventCard(event: mockEvent, onTap: () {}),
          ),
        ),
      ],
    ),
  );
}
```

**CI 비교 모드**:
- CI (`flutter test --dart-define=CI=true --tags golden`) — Ahem 폰트 기반 CI 골든 비교 → 다르면 FAIL + `failures/` diff artifact
- 로컬 — 플랫폼별 골든(`macos/`, `linux/`). `.gitignore` 로 제외

**의도된 UI 변경 시**:
1. 로컬에서 `flutter test --update-goldens --tags golden --dart-define=CI=true`
2. 새 CI 골든 PNG 커밋 → push
3. CI 재실행 → PASS

**핵심 규칙**:
- `@Tags(['golden'])` 태깅 — 일반 테스트와 분리 실행
- `flutter_test_config.dart` 의 `AlchemistConfig` 가 CI/플랫폼 모드 자동 전환
- CI 골든 = Ahem 폰트 (OS 무관)

---

### 📱 Layer 3 — Emulator test (Patrol)

**위치**: `apps/app_*/integration_test/` (향후 `emulator_test/` rename — PR #1582)

**파일 명**: `cuj_{scenario}_test.dart` (CUJ) 또는 `{feature}_native_test.dart` (native surface)

**프레임워크**: [Patrol](https://patrol.leancode.co/) + 실 dev Supabase

**샘플** (CUJ):

```dart
import 'package:patrol/patrol.dart';

import 'helpers/e2e_init.dart';

void main() {
  patrolTest('U01 — 유저가 이벤트 신청한다', ($) async {
    await initializeE2E();
    await signInAsTestUser($, email: $testEmail);

    await $.pumpWidgetAndSettle(const MinglitApp());
    await $.native.screenshot(name: 'u01_step1_home');

    await $('신청하기').tap();
    await $.native.screenshot(name: 'u01_step2_apply_sheet');

    await $('결제').waitUntilVisible();
    await $.native.screenshot(name: 'u01_step3_payment');
  });
}
```

**핵심 패턴**:
- `find.text` → `$('text')`
- `pumpAndSettle` → `waitUntilVisible` / `waitUntilExists`
- 스텝별 `$.native.screenshot(name: ...)` 삽입 → Tier B ("시나리오 스크린샷") 생성
- `SUPABASE_DEV_*` secret 만 사용 (main 도달 구조적 불가)

**상태 (2026-04-18)**: CUJ 이관률 **0%**. 이관 계획은 #1586 Phase D-2 참고.

**네이티브 surface 전용 기존 파일** (유지):
- `apple_sign_in_test.dart`, `kakao_login_test.dart`, `payment_pg_test.dart`, `permission_grant_test.dart`

---

### 🗄️ Layer 4 — pgTAP test

**위치**: `supabase/tests/database/`

**파일 명**: `{번호}_{feature}_test.sql`

**번호 규칙**: `ls supabase/tests/database/` 로 기존 번호 확인 후 다음 번호 사용.

**샘플**:

```sql
BEGIN;
SELECT plan(3);

SELECT has_table('public', 'new_feature_table', 'table exists');
SELECT has_column('public', 'new_feature_table', 'name', 'has name column');

SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "user_1"}';

SELECT results_eq(
  $$SELECT count(*) FROM new_feature_table$$,
  $$VALUES (0::bigint)$$,
  'user cannot see other users data'
);

SELECT * FROM finish();
ROLLBACK;
```

**핵심 규칙**:
- 파일 시작 `BEGIN;` + 끝 `ROLLBACK;` — 테스트 격리
- `SET LOCAL role` + `SET LOCAL request.jwt.claims` — RLS 시뮬
- 새 migration 과 **반드시 동반** (테이블/컬럼/RLS 추가 시)

---

### 🗄️ Layer 5 — Deno EF test

**위치**: `supabase/functions/{function_name}/{function_name}_test.ts`

**프레임워크**: `deno test`

**샘플**:

```typescript
import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest, captureServeHandler, createFetchMock,
  withEnv, withMockedFetch, withNoIntervals,
} from "../_test_utils/mock_http.ts";

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

Deno.test("function-name - happy path", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([/* routes */]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { /* body */ });
        const response = await handler(request);
        assertEquals(response.status, 200);
      });
    });
  });
});
```

**핵심 패턴**:
- `captureServeHandler()` — handler 캡처
- `createFetchMock()` — 외부 API 모킹 (Iamport, Supabase REST 등)
- `withEnv()` — 환경변수 주입
- `withMockedFetch()` — `fetch` 대체
- `withNoIntervals()` — `setInterval` 비활성화 (타이머 기반 로직)
- 외부 API 호출은 **반드시 mock**

---

### 🗄️ Layer 6 — DB monitor

**위치**: `supabase/migrations/` 내부 `check_db_invariants()` RPC + `.github/workflows/db-invariants.yml`

**샘플 (migration)**:

```sql
CREATE OR REPLACE FUNCTION public.check_db_invariants()
RETURNS TABLE(invariant_name text, violation_count int, details text) AS $$
BEGIN
  -- 고아 party_application (event 삭제됨)
  RETURN QUERY
    SELECT 'orphan_party_applications'::text,
           COUNT(*)::int,
           'party_applications with deleted event'::text
    FROM party_applications pa
    LEFT JOIN events e ON e.id = pa.event_id
    WHERE e.id IS NULL;

  -- 추가 invariant ...
END;
$$ LANGUAGE plpgsql;
```

**워크플로우**: 매시간 cron — 위반 수 > 0 이면 alert.

**핵심 규칙**:
- **계약 회귀가 아닌 runtime 이상 감시** (계약은 Layer 4)
- RPC 는 read-only — 데이터 수정 금지
- 신규 invariant 추가 시 `db-invariants.yml` 도 업데이트

---

### 🗄️ Layer 7 — Tick simulator

**위치**: `supabase/functions/backend-simulator/` EF + 워크플로우:
- `daily-backend-simulation.yml` — 매일 실행 (시간 전진 시뮬)
- `hourly-user-activity.yml` — 매시간 user 활동 시뮬

**성격**: 기능 테스트가 아니라 **파이프라인 관통 시뮬**. 매칭/결제/정산/알림 파이프라인이 엔드투엔드로 동작하는지 감시.

**작성 대상 아님** (신규 EF 단위 테스트는 Layer 5). Layer 7 은 시뮬 시나리오 확장 시에만 수정.

---

## 3. 파일 네이밍 & 위치 규칙

```
# Layer 1 — Unit
shared/packages/minglit_kit/test/src/data/repositories/{name}_repository_test.dart
shared/packages/minglit_kit/test/src/data/models/{name}_test.dart
apps/{app}/test/src/features/{feature}/logic/{name}_controller_test.dart
apps/{app}/test/src/features/{feature}/logic/{name}_coordinator_test.dart
apps/{app}/test/src/features/{feature}/ui/{widget}_test.dart

# Layer 2a — Widget flow
apps/{app}/test/integration/{scenario}_test.dart
apps/{app}/test/integration/cuj_{scenario}_test.dart

# Layer 2b — Golden (Alchemist)
apps/{app}/test/goldens/{widget}_golden_test.dart
shared/packages/minglit_kit/test/goldens/{widget}_golden_test.dart

# Layer 3 — Emulator (Patrol)
apps/{app}/integration_test/cuj_{scenario}_test.dart
apps/{app}/integration_test/{feature}_native_test.dart

# Layer 4 — pgTAP
supabase/tests/database/{번호}_{feature}_test.sql

# Layer 5 — Deno EF
supabase/functions/{function_name}/{function_name}_test.ts
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
| 2b (golden) | app_user / app_partner `test/goldens/**_golden_test.dart` | 14 / 15 |
| 3 (Patrol) | app_user / app_partner `integration_test/` | 5 / 1 (native surface 전용) |
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

# Layer 3 (Patrol) — 로컬 emulator 필요
cd apps/app_user && patrol test --target integration_test/cuj_signup_to_apply_test.dart
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
