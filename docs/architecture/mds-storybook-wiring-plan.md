# mds_storybook Wiring Plan — Follow-up #1

**Status:** PoC, feature/mds-storybook-wiring 브랜치
**Goal:** mds_storybook이 mds 패키지 import + 인앱 디자인 카탈로그를 mds_storybook으로 일원화
**Predecessor:** PR #1869 (MDS extraction PoC, 머지됨)

## 결정사항 (이전 논의 기반)

**옵션 C 채택** — 인앱 카탈로그 제거, mds_storybook이 디자인 시스템 카탈로그의 단일 공식 소스가 됨.

이유: 앞선 논의에서 "Storybook(격리 환경)과 인앱 카탈로그(real Provider context)는 다른 도구"라고 정리했지만, 실제로 minglit 팀 규모에서 두 도구를 병행 유지하는 비용보다 일원화 가치가 큼. 디자이너 협업, golden test 입력, SSOT 검증 모두 mds_storybook 한 곳에서 처리.

## 삭제 대상 (minglit_kit)

**Catalog 코어 (확정 삭제):**
- `lib/src/features/dev/design_catalog_page.dart`
- `lib/src/features/dev/catalog_tabs/` 디렉토리 전체:
  - `catalog_tabs.dart`, `pattern_list_section.dart`
  - `patterns/` (6 files): card_layouts, data_states, detail_page, transaction_flow, async_wrapper, mock_data
  - `tokens/` (6 files): animation, colors, icon_size, radius, spacing, typography
  - `widgets/` (9 files): buttons, cards, data, feedback, inputs, layout, loading, overlay, settings

**테스트 삭제:**
- `test/src/features/dev/design_catalog_page_test.dart`
- `test/src/features/dev/catalog_tabs/**`

**잔존 (도메인 결합, 카탈로그 무관 — 건드리지 말 것):**
- `lib/src/features/dev/dev_config.dart`
- `lib/src/features/dev/dev_user_switch_screen.dart` + `.g.dart` — 유저 스위처 (auth coupled)
- `lib/src/features/dev/partner_list_preview_screen.dart` + `.g.dart` — 파트너 데이터 미리보기
- `lib/src/features/dev/party_list_preview_screen.dart` + `.g.dart` — 파티 데이터 미리보기
- `lib/src/features/dev/widgets/partner_detail_view.dart` + `.g.dart`
- `lib/src/features/dev/widgets/party_detail_view.dart`

**Barrel export 정리:**
- `lib/minglit_dev.dart` — `DesignCatalogPage` 관련 export 제거

## 앱 코드 수정 대상

**`apps/app_user/lib/src/features/home/my_page.dart`:**
- DesignCatalogPage import 제거
- Settings 리스트에서 "디자인 카탈로그" 항목 제거
- 라우팅 정의가 있다면 그것도 제거

**`apps/app_partner/lib/src/features/more/more_page.dart`:**
- 동일 처리

**라우팅:**
- 각 앱의 `app_router.dart` 또는 `app_routes.dart`에 `DesignCatalogPage` 라우트가 있다면 제거
- 라우트 테스트(snapshot, redirect)에서 관련 항목 제거

## mds_storybook 신규 작성

**의존성 추가:**
- `pubspec.yaml`에 `mds: { path: ../../shared/packages/mds }`
- (mds_tokens는 아직 안 씀 — follow-up #2에서)

**Widgetbook 스토리 작성:**

mds_storybook의 `lib/main.dart`를 placeholder에서 실제 카탈로그로 교체. Widgetbook의 `directories: [...]` 구조로:

```
Tokens
  - Colors          (mds 컬러 팔레트 시연)
  - Spacing         (spacing scale)
  - Radius
  - Typography
Widgets
  - Buttons         (MinglitButton variants)
  - Inputs          (MinglitTextField, MinglitChip, etc.)
  - Cards           (MinglitContentCard, MinglitListTile, etc.)
  - Feedback        (MinglitAlert, MinglitDialog, MinglitEmptyState, MinglitErrorState)
  - Layout          (MinglitSection, MinglitContentLayout, MinglitSectionDivider)
  - Loading         (LoadingIndicator, MinglitSkeleton, MinglitAsyncValueWidget)
Patterns
  - CardLayouts
  - DataStates
  - DetailPage
  - TransactionFlow
  - AsyncWrapper
```

**스토리 작성 가이드:**
- 삭제되는 `catalog_tabs/`의 각 section 코드는 좋은 reference — Widgetbook UseCase로 변환
- 단, **그대로 복사하지 말 것**. Widgetbook 패턴 (UseCase, knobs)에 맞춰 재작성
- 각 컴포넌트마다 최소 2-3개 UseCase: default, edge case, dark theme variant
- mock_data는 `lib/fixtures/`로 이전 (storybook 전용 fixture)

**Scope 컷 허용:**
- Patterns 섹션 (5개)은 시간 부족 시 생략 가능. Tokens + Widgets 우선.
- 디자이너 검수가 가장 가치 있는 영역부터.
- "10-15 components를 양질로" > "30 components를 어설프게".

## CI 변경

**`.github/workflows/ci.yml`:**
- `test-flutter-apps` matrix에 `mds_storybook` 엔트리 추가:
  ```yaml
  - app: mds_storybook
    change_key: mds_storybook
    directory: apps/mds_storybook
    report_name: 'MDS Storybook Tests'
    artifact_name: mds-storybook-coverage
    coverage_flag: mds-storybook
    coverage_flag_logic: ''
  ```
- `paths-filter`에 `mds_storybook: 'apps/mds_storybook/**'` 복원 (#1869에서 제거됐던 것)
- `test-flutter-apps` `if` 조건에 `mds_storybook == 'true'` 추가
- mds_storybook의 `app_*_or_kit_or_storybook` aggregate은 만들지 않음 — storybook 변경이 앱 빌드 트리거할 필요 없음

## 검증 게이트

1. `cd apps/mds_storybook && flutter analyze` — 0 errors
2. `cd apps/app_user && flutter analyze` — 0 errors (DesignCatalogPage 참조 제거 확인)
3. `cd apps/app_partner && flutter analyze` — 0 errors
4. `cd shared/packages/minglit_kit && flutter analyze` — 0 errors
5. `cd shared/packages/minglit_kit && flutter test` — 머지된 #1869 기준 동일한 pre-existing 골든 실패만 (NEW 실패 없음)
6. `cd apps/mds_storybook && flutter build apk --flavor dev --debug --dart-define-from-file=../../minglit_env/dev/flutter.env` — 빌드 성공
7. minglit_kit에서 catalog 관련 dead code 0 (grep으로 검증)

## PR

- Base: dev
- Title: `feat(mds_storybook): wire to mds package + migrate design catalog`
- Body: plan 링크 + 작업 요약 + before/after 비교
- Auto-merge: ON
- Closes: (관련 이슈 있으면 링크)

## 위험

- 인앱 카탈로그가 익숙한 사용자 (개발자/디자이너) 워크플로우 변경 — README + 마이그레이션 노트 필요
- `more_page.dart`, `my_page.dart`의 settings UI 변경이 회귀 트리거 가능 — golden test 영향 확인
- mds_storybook 빌드 시간이 길어짐 (story 추가로) — 허용 범위

## 후속 PR (이번 범위 X)

- mds 컴포넌트가 mds_tokens 사용하도록 wiring (follow-up #2)
- Golden test 도입 (alchemist 기반)
- 디자이너 검수 결과 반영
- Patterns 섹션 미완성 시 보강

---

**Date:** 2026-04-27
