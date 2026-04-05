# Automation Test Guide

Claude가 새 피쳐를 구현할 때 반드시 따라야 하는 자동화 테스트 가이드.

---

## 1. 현재 테스트 커버리지 현황

### 요약 통계 (2026-04-05 기준)

| 계층 | 테스트 파일 수 | 커버리지 상태 |
|------|-------------|-------------|
| minglit_kit (공유 로직) | 80 | 양호 — 핵심 repository 대부분 커버 |
| app_user (사용자 앱) | 85 | 양호 (P0 Integration +3건, Smoke +2건) |
| app_partner (파트너 앱) | 73 | 개선됨 (Integration +4건, Smoke +5건) |
| Supabase DB (pgTAP) | 54 | 양호 |
| Edge Functions (Deno) | 61 | 양호 |
| Client CUJ (E2E) | 6 | 핵심 경로만 |

### 커버리지 갭

#### 🟡 SEVERE — 40% 미만
| 영역 | 소스 파일 | 테스트 파일 | 상태 |
|------|----------|-----------|---------|
| app_partner/party | 70 | 12 | 개선됨 (1.4% → 17%) |
| app_partner/ticket | 12 | 1 | 심각 — 미결 |
| app_partner/settlement | 14 | 6 | 개선됨 (21% → 43%) |
| app_partner/verification | 6 | 4 | 개선됨 (17% → 67%) |
| app_user/event | 31 | 19 | 개선됨 (24% → 61%) |

#### 해소된 갭 (2026-04 기준)
- `app_user/settings`: 2 테스트 추가 ✅
- `app_user/search`: 2 테스트 추가 ✅
- `app_user/payment`: 6 테스트 (완전 커버) ✅
- `app_partner/checkin`: 2 테스트 추가 ✅
- `minglit_kit/iamport`: 3 테스트 추가 ✅

#### 미테스트 Repository (minglit_kit)
- `party_event_repository.dart`
- `party_matching_repository.dart`

#### 해소된 Repository 갭
- `auth_repository.dart` ✅
- `event_repository_commands.dart` / `event_repository_queries.dart` ✅
- `kakao_location_repository.dart` ✅
- `policy_repository.dart` ✅
- `staff_repository.dart` ✅
- `user_repository.dart` ✅
- `verification_repository.dart` ✅

---

## 2. 테스트 계층별 작성 규칙

### Layer 1: Repository 테스트 (minglit_kit)

**위치:** `shared/packages/minglit_kit/test/src/data/repositories/`
**우선순위:** 가장 높음 — 모든 비즈니스 로직의 기반

```dart
// 파일명: {feature}_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/event_repository.dart';
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

  group('EventRepository', () {
    group('getEventById', () {
      test('returns event when found', () async {
        mockTable(mockClient, 'events', singleData: {
          'id': 'event_1',
          'title': 'Test Event',
          'status': 'scheduled',
          // ... 필수 필드
        });

        final result = await repository.getEventById('event_1');
        expect(result.id, 'event_1');
      });

      test('throws MingleException when not found', () async {
        mockTable(mockClient, 'events',
          shouldThrow: PostgrestException(message: 'not found'),
        );

        expect(
          () => repository.getEventById('nonexistent'),
          throwsA(isA<MingleException>()),
        );
      });
    });
  });
}
```

**핵심 패턴:**
- `createMockSupabase()` — Supabase 클라이언트 Mock 생성
- `mockTable()` — 테이블 쿼리 결과 Fake 설정
- Mock은 `mocktail` 사용 (mockito 아님)
- JSON mock 데이터는 실제 DB 스키마와 일치해야 함

### Layer 2: Controller/Provider 테스트 (앱별)

**위치:** `apps/app_user/test/src/features/{feature}/logic/`
**우선순위:** 높음 — UI와 데이터를 연결하는 상태 관리

```dart
// 파일명: {feature}_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockRepo;

  setUp(() {
    mockRepo = MockEventRepository();
  });

  group('EventDetailController', () {
    test('loads event data on init', () async {
      when(() => mockRepo.getEventById(any()))
          .thenAnswer((_) async => testEvent);

      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final state = await container.read(
        eventDetailControllerProvider('event_1').future,
      );

      expect(state.event.id, 'event_1');
      verify(() => mockRepo.getEventById('event_1')).called(1);
    });
  });
}
```

**핵심 패턴:**
- `createContainer()` — Riverpod 테스트용 컨테이너 (`test_utils.dart`)
- Repository를 Mock으로 override
- `when()`으로 Mock 행동 정의 → 테스트 → `verify()`로 호출 검증

### Layer 2.5: Integration 테스트 (CUJ 기반)

**위치:**
- `apps/app_user/test/integration/cuj_*.dart` — app_user CUJ
- `apps/app_partner/test/integration/cuj_*.dart` — app_partner CUJ

**공통 헬퍼:**
- `apps/app_user/test/integration/utils/test_app.dart` — `createTestApp()`
- `apps/app_partner/test/integration/utils/test_app.dart` — `createPartnerTestApp()`

```dart
// app_user CUJ 테스트 패턴
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
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

// app_partner CUJ 테스트 패턴
void main() {
  testWidgets('needsApplication → /welcome 리다이렉트', (tester) async {
    await tester.pumpWidget(
      createPartnerTestApp(
        isLoggedIn: true,
        currentUser: testUser,
        onboardingState: OnboardingState.needsApplication,
        initialLocation: '/',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
```

**핵심 패턴:**
- `createTestApp()` / `createPartnerTestApp()` — 라우터 + Provider 설정 (Supabase 불필요)
- `overrideWith()` — AsyncNotifier/Notifier를 Fake 구현으로 교체
- `overrideWithValue()` — NotifierProvider를 특정 상태 값으로 교체
- `AsyncData/AsyncLoading/AsyncError` — 비동기 상태 시뮬레이션

### Layer 3: Widget/UI 테스트

**위치:** `apps/app_user/test/integration/` 또는 `apps/app_user/test/src/features/{feature}/ui/`
**우선순위:** 중간 — 렌더링과 사용자 인터랙션

```dart
// 파일명: {widget_name}_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('PurchaseHistoryScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          purchaseHistoryProvider.overrideWith(
            (_) => AsyncData([]),
          ),
        ],
        child: const MaterialApp(
          home: PurchaseHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('구매 내역이 없습니다'), findsOneWidget);
  });

  testWidgets('shows list when data exists', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          purchaseHistoryProvider.overrideWith(
            (_) => AsyncData([testPurchase]),
          ),
        ],
        child: const MaterialApp(
          home: PurchaseHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseHistoryCard), findsOneWidget);
  });
}
```

### Layer 3.5: Golden (Snapshot) 테스트 — Alchemist

**위치:** `apps/{app}/test/goldens/`, `shared/packages/minglit_kit/test/goldens/`
**우선순위:** 디자인 토큰 변경, 레이아웃 회귀 방지
**패키지:** [alchemist](https://pub.dev/packages/alchemist) (VGV + Betterment)

Golden Test는 위젯 렌더링 결과를 이미지로 저장해두고 이후 픽셀 비교로 시각적 회귀를 감지한다.
Alchemist를 사용하여 CI(Ahem 폰트) / 로컬(플랫폼 폰트) 골든을 분리 관리한다.

```dart
// 파일명: {widget_name}_golden_test.dart
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

**CI 비교 모드 동작:**
- **CI** (`flutter test --dart-define=CI=true --tags golden`): Ahem 폰트 기반 CI 골든과 비교 → 다르면 FAIL + `failures/` diff 이미지 아티팩트 업로드
- **로컬**: 플랫폼별 골든(macOS/Linux)으로 비교 — `.gitignore`로 커밋 제외

**의도된 UI 변경 시 워크플로우:**
1. 로컬에서 `flutter test --update-goldens --tags golden --dart-define=CI=true`
2. 새 CI 골든 PNG 커밋 → push
3. CI 재실행 → PASS

**핵심 규칙:**
- `@Tags(['golden'])`으로 태깅하여 일반 테스트와 분리 실행
- `flutter_test_config.dart`에서 `AlchemistConfig`로 CI/플랫폼 모드 자동 전환
- CI 골든은 Ahem 폰트 → OS 무관 일관성 보장
- 플랫폼 골든(`test/**/goldens/macos/`, `linux/`)은 `.gitignore`로 제외
- CI에서 golden 불일치 시 diff 이미지가 `golden-failures-{app}` artifact로 업로드됨

### Layer 4: Database 테스트 (pgTAP)

**위치:** `supabase/tests/database/`
**우선순위:** DB 스키마나 RLS 변경 시 필수

```sql
-- 파일명: {번호}_{feature}_test.sql
BEGIN;
SELECT plan(3);

-- 스키마 검증
SELECT has_table('public', 'new_feature_table', 'new_feature_table exists');
SELECT has_column('public', 'new_feature_table', 'name', 'has name column');

-- RLS 검증
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

### Layer 5: Edge Function 테스트 (Deno)

**위치:** `supabase/functions/{function_name}/{function_name}_test.ts`
**우선순위:** 새 Edge Function 추가 시 필수

```typescript
// 파일명: {function_name}_test.ts
import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

Deno.test("function-name - happy path", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([/* mock routes */]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          /* payload */
        });
        const response = await handler(request);

        assertEquals(response.status, 200);
      });
    });
  });
});

Deno.test("function-name - missing params returns 400", async () => {
  // 에러 케이스 테스트
});
```

**핵심 패턴:**
- `captureServeHandler()` — Edge Function의 handler 캡처
- `createFetchMock()` — 외부 API 호출 Mock (Iamport, Supabase 등)
- `withEnv()` — 환경변수 설정
- `withMockedFetch()` — fetch 함수 대체
- `withNoIntervals()` — setInterval 비활성화 (타이머 기반 로직)

---

## 3. 새 피쳐 구현 시 테스트 체크리스트

Claude가 새 피쳐를 구현할 때 아래 체크리스트를 따른다:

### 필수 (MUST)

- [ ] **Repository 테스트** — 새로운 Repository 메서드마다 happy path + error case
- [ ] **Controller 테스트** — 새로운 Controller/Provider의 상태 변환 검증
- [ ] **DB Migration 테스트** — 새 테이블/컬럼 추가 시 pgTAP 스키마 테스트
- [ ] **RLS 테스트** — 새 테이블 또는 RLS 정책 변경 시 pgTAP RLS 테스트
- [ ] **Edge Function 테스트** — 새 Edge Function 추가 시 Deno 테스트

### 권장 (SHOULD)

- [ ] **Golden 테스트** — 디자인 토큰이나 레이아웃에 영향을 주는 UI 변경 시 (`@Tags(['golden'])`)
- [ ] **Widget 테스트** — 복잡한 상태 분기가 있는 UI 위젯
- [ ] **Coordinator 테스트** — 네비게이션 로직이 있는 Coordinator
- [ ] **에러 핸들링** — 네트워크 오류, 인증 만료 등 에러 시나리오
- [ ] **엣지 케이스** — 빈 목록, null 값, 경계값 등

### 필수 (MUST) — 추가 항목

- [ ] **Smoke 테스트** — 새 화면 추가 시 `test/src/features/{feature}/ui/{page}_smoke_test.dart` 작성
  - P0 화면: `event_application_wizard`, `purchase_history`, `settlement`, `checkin`, `partner_apply`, `party_create_wizard`, `application_manage`
  - 최소 1개: 정상 렌더링 + 로딩 상태
- [ ] **Integration 테스트** — 여러 화면을 걸치는 CUJ 플로우
  - 신규 CUJ 추가 시 `test/integration/cuj_*.dart` 작성 필수

---

## 4. 테스트 파일 네이밍 & 위치 규칙

```
# Repository 테스트 (minglit_kit)
shared/packages/minglit_kit/test/src/data/repositories/{name}_repository_test.dart

# Model 테스트 (minglit_kit)
shared/packages/minglit_kit/test/src/data/models/{name}_test.dart

# Controller 테스트 (앱별)
apps/{app}/test/src/features/{feature}/logic/{name}_controller_test.dart

# Coordinator 테스트 (앱별)
apps/{app}/test/src/features/{feature}/logic/{name}_coordinator_test.dart

# Widget 테스트 (앱별)
apps/{app}/test/src/features/{feature}/ui/{widget_name}_test.dart

# Golden 테스트 (앱별)
apps/{app}/test/goldens/{widget_name}_golden_test.dart

# Integration 테스트 (앱별)
apps/{app}/test/integration/{scenario_name}_test.dart

# DB 테스트 (pgTAP)
supabase/tests/database/{번호}_{feature}_test.sql

# Edge Function 테스트
supabase/functions/{function_name}/{function_name}_test.ts
```

**번호 규칙 (pgTAP):** `ls supabase/tests/database/`로 기존 번호 확인 후 다음 번호 사용.

---

## 5. Mock 유틸리티 참조

### Dart (minglit_kit)

| 유틸 | 위치 | 용도 |
|------|------|------|
| `createMockSupabase()` | `minglit_kit/test/helpers/supabase_mock_helpers.dart` | Supabase 클라이언트 Mock |
| `mockTable()` | 동일 파일 | 테이블 쿼리 Fake 결과 설정 |
| `MockSupabaseClient` | `minglit_kit/test/helpers/mocks.dart` | 기본 Supabase Mock 클래스들 |
| `createContainer()` | `apps/{app}/test/utils/test_utils.dart` | Riverpod 테스트 컨테이너 |
| Repository Mocks | `apps/{app}/test/utils/mocks.dart` | `MockEventRepository` 등 |

### Deno (Edge Functions)

| 유틸 | 위치 | 용도 |
|------|------|------|
| `captureServeHandler()` | `supabase/functions/_test_utils/mock_http.ts` | Edge Function handler 캡처 |
| `createFetchMock()` | 동일 파일 | HTTP fetch Mock |
| `authenticatedJsonRequest()` | 동일 파일 | 인증된 JSON 요청 생성 |
| `withEnv()` | 동일 파일 | 환경변수 설정 |
| `withMockedFetch()` | 동일 파일 | fetch 대체 |
| fixtures | `supabase/functions/_test_utils/fixtures.ts` | Mock 데이터 (mockOrder, mockPaidPayment 등) |

---

## 6. 테스트 실행 명령어

```bash
# Flutter 단위/위젯 테스트 (앱별)
cd apps/app_user && flutter test
cd apps/app_partner && flutter test
cd shared/packages/minglit_kit && flutter test

# Flutter 특정 파일만
flutter test test/src/features/event/logic/event_detail_controller_test.dart

# Flutter 통합 테스트 (Mock 기반) — app_user
cd apps/app_user && flutter test test/integration/

# Flutter 통합 테스트 (Mock 기반) — app_partner
cd apps/app_partner && flutter test test/integration/

# 태그로 분리 실행
cd apps/app_user && flutter test --tags integration

# pgTAP DB 테스트
supabase test db

# Edge Function 테스트
deno test --allow-all supabase/functions/

# 특정 Edge Function만
deno test --allow-all supabase/functions/payment-verify/

# CI 전체 재현
flutter analyze && flutter test  # Flutter
supabase test db                 # DB
deno test --allow-all functions/ # Edge Functions
```

---

## 7. 테스트 작성 시 주의사항

### DO

- Mock 데이터는 실제 DB 스키마 (`supabase/migrations/`)의 컬럼명과 일치시킨다
- `group()`으로 테스트를 논리적으로 묶는다 (클래스명 → 메서드명)
- Happy path와 Error case를 모두 작성한다
- `setUp()`에서 Mock을 초기화한다 (테스트 간 격리)
- Edge Function 테스트에서는 외부 API를 반드시 Mock한다

### DON'T

- 테스트에서 실제 네트워크 호출을 하지 않는다 (CUJ 통합 테스트 제외)
- 테스트 간 상태를 공유하지 않는다
- Mock의 반환값을 하드코딩하지 않는다 — 변수로 선언하여 재사용한다
- `sleep()`이나 `Future.delayed()`로 비동기를 기다리지 않는다
- generated 파일 (`*.g.dart`, `*.freezed.dart`)은 테스트 대상에서 제외한다

---

## 8. CI 파이프라인 연동

테스트는 `.github/workflows/ci.yml`에서 자동 실행된다:

| 변경 영역 | 실행되는 테스트 |
|----------|-------------|
| `apps/app_user/**` | Flutter analyze + test + **integration test** (app_user) |
| `apps/app_partner/**` | Flutter analyze + test + **integration test** (app_partner) |
| `shared/packages/minglit_kit/**` | Flutter analyze + test (모든 앱) |
| `supabase/**` | pgTAP + Edge Function 테스트 |
| `apps/landing_*/**` | npm lint + build |

커버리지는 Codecov에 업로드된다. `minglit_kit`은 60% patch 커버리지 목표.
