# MDS (Minglit Design System) Extraction Plan — PoC

**Status:** PoC, feature/mds-extraction-poc 브랜치
**Goal:** `minglit_kit`에서 순수 디자인 시스템 레이어를 별도 패키지로 추출, Storybook 앱 + tokens 파이프라인 부트스트랩
**Non-goal (이번 PR에서 X):** features/, data/, utils/ 분해. demo 앱. mds-react. golden test 도입.

## 배경

`minglit_kit`은 현재 디자인 시스템 컴포넌트 + 비즈니스 로직 + features + repositories를 한 패키지에 담고 있다 (141 files, god node #2 with 407 edges). 디자인 시스템을 SSOT로 만들려면 비즈니스 로직과 분리되어야 한다.

이번 PoC의 목표는 **빅뱅 리팩터 없이** 디자인 시스템 레이어만 안전하게 분리하는 것. minglit_kit 자체는 비즈니스 로직 monolith로 그대로 유지 (이게 잘못된 게 아니라 의도된 설계 — user/partner 앱이 도메인을 공유함).

## 결정사항

### 1. 추출 범위 — 38 files (확정)

**MDS로 이동:**
- `src/theme/*` (6 files): minglit_theme, minglit_design_tokens, minglit_design_utils, minglit_quill_theme, minglit_text_theme_extension, minglit_component_theme
- `src/ui/widgets/common/minglit_*.dart` (~30 files): minglit_ prefix가 붙은 모든 위젯
- `src/ui/widgets/common/loading_indicator.dart`, `number_stepper_input.dart`: prefix 없지만 pure UI (외부 디펜던시 검증 후 포함)
- `src/ui/feedback/feedback_components.dart`

**추출 안 함 (business-coupled, minglit_kit에 잔존):**
- `features/*` 전체 — 실제 화면 (auth, iamport, notification, search, social, verification 등)
- `widgets/common/{add_action_card,entry_group_detail,verification_*}.dart` — business 결합
- `widgets/{map,partner,party,debug}/*`
- `pages/account_management_page.dart`
- `utils/*`
- `data/*`, `logic/*`, `services/*`, `config/*`

### 2. Re-export 어댑터 패턴

추출 후 `minglit_kit/lib/minglit_ui.dart`의 해당 export 라인들이 `mds` 패키지에서 re-export하도록 변경:

```dart
// Before:
export 'src/theme/minglit_theme.dart';
export 'src/ui/widgets/common/minglit_button.dart';
// ...

// After:
export 'package:mds/mds.dart';
// 비-MDS export는 그대로 유지
```

**효과:** app_user, app_partner의 import 라인 0줄 변경. 모든 앱 코드는 `package:minglit_kit/minglit_kit.dart`를 그대로 import해도 동작.

**장기 cleanup (이 PR 범위 X):** 후속 PR에서 점진적으로 앱 코드의 import을 `package:mds/mds.dart`로 직접 변경.

### 3. Storybook 앱 — apps/mds_storybook (skeleton만)

이번 PR에선 빈 Widgetbook 앱 + alchemist 의존성만 셋업. 실제 story 파일 이전 (`features/dev/catalog_tabs/*` 이전)은 후속 PR.

- 의존성: widgetbook, widgetbook_annotation, widgetbook_generator, alchemist
- main.dart: 빈 Widgetbook root (placeholder story 1-2개)
- pubspec: dev/release flavor
- CI: 일단 빌드만 확인, golden test는 후속 PR

### 4. Tokens 파이프라인 — shared/packages/mds_tokens

Style Dictionary로 tokens.json → Dart const codegen 셋업.

- `tokens/tokens.json`: 현재 MinglitTheme의 색/spacing/radius 값 추출
- `build.config.js`: Style Dictionary config (Dart transform)
- `lib/generated/tokens.g.dart`: 생성된 Dart const
- `package.json`: build script

이번 PR에선 **codegen 결과물을 mds 패키지가 아직 사용하지 않음** — tokens 파이프라인 존재만 증명. 후속 PR에서 mds 컴포넌트가 hardcoded 값 대신 tokens.g.dart를 import하도록 마이그레이션.

## 의존성 방향

```
mds_storybook ──> mds
                   │
mds_tokens (생성된 Dart) ──> mds (후속 PR에서 연결)
                   │
minglit_kit ──> mds (re-export 어댑터)
                   │
app_user, app_partner ──> minglit_kit (변경 없음)
```

**제약:** mds는 minglit_kit, app_*, mds_storybook, mds_tokens 어느 것도 import해선 안 됨. flutter material만 의존. 이게 깨지면 SSOT 의미 상실.

## 작업 분해 (3 agent 병렬)

### Agent A: mds-extractor

**Owner:** sonnet
**Working dir:** `/Users/mark/workspace/minglit/.claude/worktrees/mds-extraction`
**Deliverable:** `shared/packages/mds/` 신규 패키지 + minglit_kit re-export 어댑터

**Steps:**
1. `shared/packages/mds/` 생성, pubspec.yaml 작성 (deps: flutter material만)
2. 38 files를 `shared/packages/mds/lib/src/` 하위로 이동 (디렉토리 구조 유지: theme/, widgets/, feedback/)
3. `shared/packages/mds/lib/mds.dart` barrel export 작성
4. 이동된 파일들의 internal import 경로 업데이트 (`package:minglit_kit/...` → `package:mds/...`)
5. 만약 어떤 파일이 minglit_kit의 다른 부분 (data/, features/) 을 import하면 → 추출 후보에서 빼고 사용자(orchestrator)에게 보고
6. `minglit_kit/lib/minglit_ui.dart`의 해당 export 라인을 `export 'package:mds/mds.dart';` 한 줄로 교체
7. `minglit_kit/pubspec.yaml`에 `mds: { path: ../mds }` 추가
8. `cd shared/packages/mds && flutter analyze` 통과 확인
9. `cd shared/packages/minglit_kit && flutter analyze` 통과 확인
10. 커밋 메시지: `refactor(mds): extract design system into shared/packages/mds`

**Constraints:**
- 어떤 minglit_kit 파일도 mds를 통해 features/data/utils를 import해서는 안 됨 (역방향 의존 금지)
- minglit_kit 외부의 app_user/app_partner 코드는 절대 건드리지 말 것
- 만약 38 files 중 일부가 비-design-system 의존을 갖고 있다면 그 파일은 추출에서 제외하고 보고

### Agent B: storybook-bootstrapper

**Owner:** sonnet
**Working dir:** 동일 worktree
**Deliverable:** `apps/mds_storybook/` 빌드 가능한 Widgetbook 앱 skeleton

**Steps:**
1. `apps/mds_storybook/` 생성 — Flutter app template
2. pubspec.yaml: widgetbook ^3, widgetbook_annotation, widgetbook_generator (build_runner), alchemist
3. lib/main.dart: 최소 Widgetbook root, placeholder use case 1-2개 (예: Container, Text)
4. android/, ios/ 기본 구조 (대상 platform: android 우선)
5. Flavor: dev (CLAUDE.md의 build defaults에 맞춤)
6. README.md: 어떻게 실행하는지 짧게
7. pubspec.yaml에 mds 패키지 의존성은 **추가하지 말 것** — 이번 PR에선 독립적으로 빌드만 확인. 실제 mds 컴포넌트 import은 후속 PR.
8. `cd apps/mds_storybook && flutter pub get && flutter analyze` 통과 확인
9. 커밋 메시지: `feat(mds_storybook): bootstrap Widgetbook app skeleton`

**Constraints:**
- Agent A의 작업과 독립적으로 진행 가능. mds 패키지가 아직 없어도 OK.
- app_user/app_partner와 동일한 Flutter 버전 / SDK constraint 사용
- bump-version.sh 대상에 추가는 하지 말 것 (이번 PR 범위 X)

### Agent C: tokens-pipeline

**Owner:** sonnet
**Working dir:** 동일 worktree
**Deliverable:** `shared/packages/mds_tokens/` Style Dictionary 파이프라인

**Steps:**
1. `shared/packages/mds_tokens/` 생성 — pubspec.yaml (Dart-only, no flutter)
2. `tokens/tokens.json` 작성 — 현재 `shared/packages/minglit_kit/lib/src/theme/minglit_design_tokens.dart`를 읽고 색/spacing/radius/typography 값을 W3C Design Tokens 포맷으로 추출
3. `package.json` + `build.config.js` Style Dictionary 셋업 (Dart transform 포함)
4. `lib/generated/tokens.g.dart` 생성 결과 커밋 (codegen output도 git tracked)
5. `lib/mds_tokens.dart` barrel export
6. README.md: 어떻게 빌드하는지 (`npm run build`)
7. `cd shared/packages/mds_tokens && dart analyze` 통과 확인
8. 커밋 메시지: `feat(mds_tokens): bootstrap Style Dictionary tokens pipeline`

**Constraints:**
- minglit_design_tokens.dart는 **읽기만** 하고 수정하지 말 것 (Agent A의 작업과 충돌 방지)
- 생성된 Dart 토큰을 mds 패키지가 사용하도록 wiring은 이 PR에서 하지 말 것
- Style Dictionary는 npm 의존성 — 루트 package.json에 추가하지 말고 mds_tokens/ 자체에 격리

## 검증 게이트

3 agents 완료 후 orchestrator (Claude main session)가 수행:

1. **각 패키지 analyze** — `cd <pkg> && flutter analyze` 0 errors
2. **app_user, app_partner analyze + test** — 기존 동작 회귀 없음
3. **app_user APK debug build** — 실제 빌드 성공 (CLAUDE.md build defaults 따름)
4. **app_partner APK debug build** — 동일
5. **순환 의존성 체크** — mds가 minglit_kit/app_*를 import하지 않는지 grep으로 검증
6. **graphify update .** — 그래프 업데이트하여 새 god node 구조 확인 (선택)

## CI 변경

`.github/workflows/ci.yml`의 `test-flutter-apps` 트리거:
- 현재: `apps/app_user/**`, `apps/app_partner/**`, `shared/packages/minglit_kit/**`
- 추가 필요: `shared/packages/mds/**`, `shared/packages/mds_tokens/**`, `apps/mds_storybook/**`

이 변경은 orchestrator가 통합 단계에서 수행.

## PR

- Base: `dev`
- Title: `refactor(mds): extract design system + bootstrap Storybook & tokens pipeline (PoC)`
- Body: 이 plan 문서 링크 + agent별 산출물 요약 + screenshot (storybook 실행 화면)
- Auto-merge: ON (`gh pr merge --auto --squash`)
- Closes: (관련 issue 없음, 새로운 architecture 작업)

## 롤백

Worktree + 별도 브랜치이므로 dev 영향 0. 실패 시:
- `git worktree remove .claude/worktrees/mds-extraction`
- `git branch -D feature/mds-extraction-poc`

## 후속 PR (이번 PR 범위 X, 메모만)

1. mds_storybook이 mds 패키지 import + features/dev/catalog_tabs/* 이전
2. mds 컴포넌트가 mds_tokens.g.dart의 토큰을 사용하도록 wiring
3. golden test 도입 (alchemist 기반)
4. 앱 코드 import을 `minglit_kit` → `mds`로 점진 마이그레이션 (re-export 어댑터 제거 준비)
5. mds-react 패키지 (web SDK)
6. landing_user/landing_partner의 토큰 사용 통합

---

**Generated by:** Claude orchestrator session
**Date:** 2026-04-27
