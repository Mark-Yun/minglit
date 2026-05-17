# mds-emulator-render

MDS spec 의 각 화면을 실제 Flutter 앱으로 에뮬레이터 렌더링 → PNG 캡처. MDS 의 `apps/mds/docs/public/specs/<screen>/state_*.png` (디자인) 와 1:1 비교 대상.

## 핵심 설계 문서

> **[architecture.md](./architecture.md)** — 전체 architecture (Engine + Catalog + Manifest 3축, 합성, coverage reconciler, scaffold, CI 병렬화). 새 화면 추가 / framework 확장 시 반드시 먼저 읽을 것.

## 산출물

엔진이 생성하는 모든 파일과 출처:

| 산출물 | 위치 | 생성 주체 |
|--------|------|---------|
| state PNG | `docs/infra/mds-emulator-render/<screen>/state-*.png` | runner (per testWidgets) |
| `_manifest.yaml` | `docs/infra/mds-emulator-render/<screen>/_manifest.yaml` | runner (state별 mds_index, setup chain, builder hash) |
| coverage report | stdout (`dart run scripts/mds_render_coverage.dart`) | coverage reconciler |
| scaffold 결과 | `<screen>/builder.dart` + `<screen>/<screen>_test.dart` + `_registry.dart` 갱신 | scaffold 스크립트 |

## 폴더 컨벤션

MDS spec 디렉토리명과 동일 (per-screen, snake_case). 화면당 `builder.dart` + `<screen>_test.dart` 2 파일.

```
integration_test/mds-emulator-render/
├── _engine/                # framework (architecture.md 참고)
├── _mocks/                 # 공통 mock 풀
├── home_page/
│   ├── builder.dart        # HomePageBuilder
│   └── home_page_test.dart # catalog 정의 + runner
└── event_detail_page/...
```

## 테스트 코드 룰

1. **Patrol 안 씀** — `testWidgets` 사용
2. **선언적 catalog** — `MdsCatalog` + state list (testWidgets 직접 작성 금지)
3. **Builder fluent API** — `.empty()`, `.withEvents(3)`, `.dark()` chainable
4. **screen 명시** — `takeScreenshot('<screen>__<state>')` (Android args 미지원)
5. **assertion 금지** — 캡처만, 검증은 인스펙션 워크플로우 담당
6. **State 명** — `state-<short-label>` kebab-case (composed 자동 생성)

## 실행 / coverage / scaffold

명령 + CI 병렬화는 [architecture.md](./architecture.md) 참고.

## 관련

- [상위 BLUEDOC](../BLUEDOC.md) — integration_test 폴더 entry
- 워크플로우 페어: `sync-mds-mockups.yml` (디자인) ↔ `mds-emulator-render.yml` (실제, 예정)
