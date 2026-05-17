# Render Catalog Engine — Architecture

77 MDS 화면 × 평균 4 state = **300+ 케이스**를 단순 test 가 아니라 **선언적 render catalog** 로 다룬다. 데이터(catalog) 와 코드(engine) 의 분리, 합성(composition) 가능한 state, 자동 manifest, 인스펙션-친화적 페어링이 핵심.

## 구현 상태 (Phase 1 / Phase 2)

본 문서는 **목표 설계** + **현재 구현 상태** 를 함께 명시한다. 미구현 항목은 시도하면 compile error. 추가 작업은 follow-up PR.

| 영역 | Phase 1 (현재 구현됨) | Phase 2 (TODO, 후속 PR) |
|------|--------------------|-------------------------|
| `_engine/state.dart` | `MdsState` 클래스 (name + setup + mdsIndex + tags) | `MdsState.compose([...])` 자동 합성 |
| `_engine/builder.dart` | `MdsScreenBuilder<W>` base, `useDarkTheme()`, `addOverride()` | provider slot dedup (`setSlot`), `requiredSlots` 검증 |
| `_engine/catalog.dart` | `MdsCatalog` (screen + mdsSpec + builder + states) | — |
| `_engine/runner.dart` | catalog → testWidgets per state | `decorators:` 파라미터 (cross-cutting) |
| `_engine/decorator.dart` | (없음) | `WithKoreanLocale`, `WithViewport`, `WithTimezone` 등 |
| `_engine/primitive.dart` | (없음) | `Primitive.empty()`, `Primitive.loading()`, `Primitive.error()` 공용 factory |
| `_engine/manifest.dart` | (없음) | `_manifest.yaml` writer (mds_index, builder hash, setup chain) |
| `_registry.dart` | (없음) | 모든 catalog 자동 발견 + shard 실행 |
| `scripts/mds_render_coverage.dart` | (없음) | MDS ↔ catalog gap report (CLI) |
| `scripts/scaffold_mds_render.dart` | (없음) | 새 screen 자동 폴더+빌더+test 생성 |
| `.github/workflows/monitor-mds-render-coverage.yml` | (없음) | daily cron, 100% 미만 시 이슈 |

**현재 상태**: Phase 1 만 사용 가능. 신규 화면 추가는 `home_page/` 패턴 그대로 복제하면 됨.

## 데이터 흐름

```
                          ┌─────────────────────────────────┐
                          │  MDS specs (Mark, 디자인 SSoT)  │
                          │  apps/mds/docs/public/specs/    │
                          │  └─ <screen>/                   │
                          │     ├─ index.md (메타)          │
                          │     └─ state_*.png (디자인)     │
                          └────────────┬────────────────────┘
                                       │
                          ┌────────────▼────────────────────┐
                          │  Coverage Reconciler            │
                          │  scripts/mds_render_coverage    │
                          │  - MDS 77 screen 스캔           │
                          │  - test catalog 와 join         │
                          │  - gap / drift / orphan 리포트  │
                          └────────────┬────────────────────┘
                                       │
            ┌──────────────────────────┴──────────────────────────┐
            │                                                      │
   ┌────────▼─────────────┐                            ┌─────────▼──────────┐
   │  Render Engine        │                            │  Inspection         │
   │  (custom framework)   │                            │  Workflow          │
   │                       │                            │                    │
   │  ┌─────────────────┐  │                            │  PNG 비교:         │
   │  │ Catalog (data)  │  │  consumed by               │  MDS state ↔       │
   │  └────────┬────────┘  │ ─────────────►             │  emulator render  │
   │           │           │                            │                    │
   │  ┌────────▼────────┐  │                            │  → 이슈 파일링    │
   │  │ Builder         │  │                            └────────────────────┘
   │  │ (fluent API)    │  │
   │  └────────┬────────┘  │
   │           │           │
   │  ┌────────▼────────┐  │
   │  │ Decorator       │  │
   │  │ (theme/locale)  │  │
   │  └────────┬────────┘  │
   │           │           │
   │  ┌────────▼────────┐  │
   │  │ Runner          │  │ ──► testWidgets per state
   │  └────────┬────────┘  │
   └───────────┼───────────┘
               │ outputs
               ▼
   ┌──────────────────────────────────────────────────┐
   │  docs/infra/mds-emulator-render/                 │
   │  └─ <screen>/                                    │
   │     ├─ state-*.png            (engine 생성)      │
   │     └─ _manifest.yaml         (페어링 메타)      │
   └──────────────────────────────────────────────────┘
```

## 3축 (Three Pillars)

### 1. Engine (코드, 변경 적음)
`_engine/` 하위. 모든 화면이 공유하는 framework.

- `state.dart` — `MdsState` (선언적 state, 합성 가능)
- `builder.dart` — `MdsScreenBuilder<W>` (화면별 fluent API base)
- `decorator.dart` — `WithDarkTheme`, `WithKoreanLocale`, `WithViewport` 등 cross-cutting
- `primitive.dart` — `Primitive.empty()`, `Primitive.loading()`, `Primitive.error()` 공용 state factory
- `catalog.dart` — `MdsCatalog` 컨테이너
- `runner.dart` — catalog → `testWidgets` 자동 변환
- `manifest.dart` — `_manifest.yaml` writer

### 2. Catalog (데이터, 화면별)
화면마다 `<screen>/builder.dart` + `<screen>/<screen>_test.dart`. test 파일이 **선언적 catalog 정의 + runner 호출** 만 함.

### 3. Manifest (산출물 메타)
각 화면의 PNG 옆에 `_manifest.yaml` 자동 생성. MDS state index 와 페어링, builder hash, setup chain 기록. 인스펙션 워크플로우의 입력.

## 파일 레이아웃

```
integration_test/mds-emulator-render/
├── BLUEDOC.md
├── architecture.md                   # ← 본 문서
├── _CATALOG_TEMPLATE.dart            # 새 화면 보일러플레이트
│
├── _engine/                          # ◀ 핵심 framework
│   ├── state.dart
│   ├── builder.dart
│   ├── decorator.dart
│   ├── primitive.dart
│   ├── catalog.dart
│   ├── runner.dart
│   └── manifest.dart
│
├── _mocks/                           # 공통 mock 풀
│   ├── coordinators.dart
│   ├── notifiers.dart
│   └── data.dart                     # mockEvents(n), mockUser(), mockTags(n)
│
├── _registry.dart                    # 모든 catalog 명시적 import (수동 list)
│
├── home_page/
│   ├── builder.dart                  # HomePageBuilder
│   └── home_page_test.dart           # catalog + main → runner
│
├── event_detail_page/
│   ├── builder.dart
│   └── event_detail_page_test.dart
│
└── ... (77 screens)
```

## 선언적 카탈로그 (per-screen, 15~30줄)

```dart
// home_page/home_page_test.dart
import '../_engine/runner.dart';
import '../_engine/state.dart';
import '../_engine/primitive.dart';
import 'builder.dart';

final homePageCatalog = MdsCatalog(
  screen: 'home_page',
  mdsSpec: 'apps/mds/docs/public/specs/home_page/',
  builder: HomePageBuilder.new,
  states: [
    Primitive.empty(),                                    // MDS state_1
    MdsState('with-events', (b) => b.events(3),  mdsIndex: 2),
    MdsState('with-tags',   (b) => b.tags(5),    mdsIndex: 3),
    MdsState('dark',        (b) => b.dark(),     mdsIndex: 4),
    Primitive.loading(),
    Primitive.error('Network'),
    MdsState.compose(['dark', 'with-events']),            // 자동 합성
  ],
);

void main() => MdsRenderEngine.run(homePageCatalog);
```

**새 state 추가 = list 한 줄**. **새 screen 추가 = builder + catalog 20줄 + scaffold 명령 1줄**.

## 합성 (Composition)

```dart
// Builder 메서드는 chainable
HomePageBuilder()
  .events(3)
  .tags(5)
  .dark()
  .build()

// State 도 합성 가능 — n × m × k 자동
MdsState.compose(['dark', 'with-events'])
  // setup 함수 순서대로 적용, 이름 자동 'dark-with-events'

// Decorator 는 외부에서 cross-cutting 적용
MdsRenderEngine.run(catalog, decorators: [
  WithViewport(devicePixelRatio: 3.0),
  WithKoreanLocale(),
  WithTimezone('Asia/Seoul'),
])
```

손으로 적었으면 폭발할 조합이 자동 생성.

## Manifest 스키마

```yaml
# docs/infra/mds-emulator-render/home_page/_manifest.yaml
schema: 1
screen: home_page
mds_spec: apps/mds/docs/public/specs/home_page/
generated_at: 2026-05-17T09:55:00Z
builder_hash: abc123def                # builder 변경 감지용

states:
  - name: state-empty
    mds_index: 1                       # MDS state_1.png 와 페어
    file: state-empty.png
    bytes: 59479
    setup_chain: []

  - name: state-with-events
    mds_index: 2
    file: state-with-events.png
    setup_chain: [events(3)]

  - name: state-dark-with-events
    mds_index: null                    # MDS 에 없는 합성 → orphan
    file: state-dark-with-events.png
    setup_chain: [dark(), events(3)]
    composed_from: [dark, with-events]
```

인스펙션 워크플로우가 manifest 만 읽으면 페어링/diff 가능. PNG 자체로 알 수 없는 의도·출처 보존.

## Coverage Reconciler

```
$ dart run scripts/mds_render_coverage.dart

═══════════════════════════════════════════════════════
  MDS ↔ Render Catalog Coverage
═══════════════════════════════════════════════════════
  Total MDS screens     : 77
  Cataloged screens     : 5  (6.5%)
  Uncataloged screens   : 72

  Total MDS states      : 318
  Captured states       : 27 (8.5%)

─── Per-screen ──────────────────────────────────────
  home_page                : 5/5 ✓ + 2 orphan (composed)
  login_page               : 2/3 ⚠ missing state_3 (dark)
  event_detail_page        : 0/8 ✗ NOT CATALOGED
  ...

─── Drift ──────────────────────────────────────────
  ⚠ event_card_screen — builder_hash changed since last capture
     → re-run shard

─── Priority next ──────────────────────────────────
  활동량 기반 추천:
  1. event_application_review_page (0/4) — 최근 12 PR
  2. event_now_bar (0/7) — 최근 8 PR
```

다음 작업 우선순위까지 자동 도출.

## Scaffold

```
$ dart run scripts/scaffold_mds_render.dart event_detail_page

✓ Created integration_test/mds-emulator-render/event_detail_page/
✓ Created builder.dart       (EventDetailPageBuilder stub)
✓ Created event_detail_page_test.dart (state-default)
✓ Added to _registry.dart

📋 Next:
  1. builder.dart 에 fluent 메서드 추가
  2. test 의 catalog 에 state 추가
  3. dart run scripts/run_render_shard.dart --screen event_detail_page
```

## CI 병렬화

```yaml
# .github/workflows/mds-emulator-render.yml
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: dart run scripts/run_render_shard.dart --shard ${{ matrix.shard }}/4
```

4 shard 분산 → 각 ~19 screen → 전체 ~20분.

## 확장 포인트

| 추가하고 싶은 것 | 어디에 |
|----------------|--------|
| 새 화면 | `<screen>/builder.dart` + `<screen>/<screen>_test.dart` (scaffold 자동) |
| 새 state | catalog 의 states list 에 entry 1개 |
| 새 cross-cutting (예: RTL, large text) | `_engine/decorator.dart` 에 `WithRTL`, `WithLargeText` 추가 |
| 새 primitive state | `_engine/primitive.dart` 에 `Primitive.skeleton()` 등 |
| 새 mock 데이터 | `_mocks/data.dart` 에 `mockNotifications(n)` 등 |

화면 코드는 **builder + catalog 2개 파일만** 작성. 나머지는 engine 이 처리.

## 관련

- [BLUEDOC](./BLUEDOC.md) — 폴더 컨벤션 + 테스트 작성 룰 간략
- [상위 BLUEDOC](../BLUEDOC.md) — integration_test 폴더 entry
- 워크플로우 페어: [sync-mds-mockups.yml](../../../../.github/workflows/sync-mds-mockups.yml) (MDS 디자인) ↔ `mds-emulator-render.yml` (실제 렌더링, 예정)
