# PR D — MDS Folder Nesting Refactor

**Status:** Mechanical refactor PoC, feature/mds-nesting 브랜치
**Goal:** mds 관련 4 패키지를 nested 구조로 이전 — `shared/packages/mds/{core,tokens}` + `apps/mds/{storybook,docs}`
**Predecessors:** #1869, #1887, #1899, #1904 (모두 머지 완료)

## 동기

현재 flat 구조에서 mds family 패키지들이 다른 패키지(minglit_kit, app_user 등)와 같은 깊이에 흩어져 있음. mds_icons 등 추가 시 더 산만해짐. 사용자 결정: nesting first, 그 다음 다른 mds 작업.

## Before / After

```
[Before]
shared/packages/
  mds/                        ← Flutter 패키지 (name: mds)
  mds_tokens/                 ← Dart-only (name: mds_tokens)
  minglit_kit/
apps/
  mds_storybook/              ← Flutter app (name: mds_storybook)
  mds_docs/                   ← Next.js app (name: mds_docs)
  app_user/, app_partner/, landing_*

[After]
shared/packages/
  mds/                        ← parent folder (NOT a package)
    core/                     ← was shared/packages/mds/, name: mds 유지
    tokens/                   ← was shared/packages/mds_tokens/, name: mds_tokens 유지
  minglit_kit/                (변경 없음)
apps/
  mds/                        ← parent folder (NOT a package)
    storybook/                ← was apps/mds_storybook/, name: mds_storybook 유지
    docs/                     ← was apps/mds_docs/, name: mds_docs 유지
  app_user/, app_partner/, landing_* (변경 없음)
```

**핵심 원칙:**
- 폴더 이름 ≠ 패키지 이름 (Dart pubspec `name:`, npm package.json `name`은 변경 X)
- `package:mds/...`, `package:mds_tokens/...` import 경로 그대로 유지
- 변경되는 건 **파일 시스템 경로** (`path:` 의존, CI paths-filter, vercel.json, README 참조)

## 변경 항목 체크리스트

### 1. 폴더 이동 (git mv로 history 보존)

```bash
git mv shared/packages/mds shared/packages/mds_core_tmp
git mv shared/packages/mds_tokens shared/packages/mds/tokens
mkdir -p shared/packages/mds
git mv shared/packages/mds_core_tmp shared/packages/mds/core
# 결과: shared/packages/mds/core/ + shared/packages/mds/tokens/

git mv apps/mds_storybook apps/mds_storybook_tmp
mkdir -p apps/mds
git mv apps/mds_storybook_tmp apps/mds/storybook
git mv apps/mds_docs apps/mds/docs
# 결과: apps/mds/storybook/ + apps/mds/docs/
```

(주의: 위는 개념. 실제로는 한 단계씩 안전하게 — `shared/packages/mds`가 이미 패키지인 채로 그 아래 폴더 생성하면 conflict. 임시 이름으로 옮긴 후 재배치 필요.)

### 2. `path:` 의존 갱신

**`shared/packages/minglit_kit/pubspec.yaml`:**
```yaml
dependencies:
  mds:
    path: ../mds       # was: same
    # 실제로는 변화 없음 — minglit_kit은 shared/packages/ 직속, mds도 shared/packages/mds 디렉토리(parent)로 가는 데 path는 그대로 ../mds.
    # BUT mds 폴더는 더 이상 패키지가 아니라 parent. 패키지는 ../mds/core.
    # 따라서 path: ../mds/core
```

수정 필요:
- `shared/packages/minglit_kit/pubspec.yaml`: `mds: { path: ../mds }` → `path: ../mds/core`
- `shared/packages/mds/core/pubspec.yaml` (원래 mds/pubspec.yaml): `mds_tokens: { path: ../mds_tokens }` → `path: ../tokens` (sibling이 됨)
- `apps/mds/docs/package.json` 또는 `next.config.ts` 또는 `globals.css`의 tokens.css 참조 경로 갱신

### 3. `apps/mds/docs/src/app/globals.css` — tokens.css 경로 갱신

**Before:**
```css
@import "../../../../shared/packages/mds_tokens/lib/generated/tokens.css";
```

**After:**
```css
@import "../../../../../shared/packages/mds/tokens/lib/generated/tokens.css";
```

- 깊이가 한 단계 늘어남 (`apps/mds/docs/` 4 → `apps/mds/docs/` 5 levels deep relative)
  - 정확히 `apps/mds/docs/src/app/` 5단계라 `../../../../../`로 repo root 도달

### 4. CI paths-filter 갱신 (`.github/workflows/ci.yml`)

```yaml
# Before:
mds:
  - 'shared/packages/mds/**'
mds_tokens:
  - 'shared/packages/mds_tokens/**'
mds_storybook:
  - 'apps/mds_storybook/**'
mds_docs:
  - 'apps/mds_docs/**'

# After:
mds_core:
  - 'shared/packages/mds/core/**'
mds_tokens:
  - 'shared/packages/mds/tokens/**'
mds_storybook:
  - 'apps/mds/storybook/**'
mds_docs:
  - 'apps/mds/docs/**'
```

`outputs:` 섹션도 `mds → mds_core` 변수명 변경 반영.

### 5. test-flutter-apps matrix 경로 갱신

```yaml
# Before:
- app: minglit_kit
  directory: shared/packages/minglit_kit
- app: mds_storybook
  directory: apps/mds_storybook

# After:
- app: minglit_kit
  directory: shared/packages/minglit_kit       # 변경 없음
- app: mds_storybook
  directory: apps/mds/storybook
```

### 6. lint-mds-docs job 경로 갱신

```yaml
# Before:
defaults:
  run:
    working-directory: ./apps/mds_docs
...
cache-dependency-path: ./apps/mds_docs/package-lock.json

# After:
defaults:
  run:
    working-directory: ./apps/mds/docs
...
cache-dependency-path: ./apps/mds/docs/package-lock.json
```

### 7. deploy.yml — vercel deploy 경로

```yaml
# mds_docs deploy job — root directory 변경
- working-directory: apps/mds/docs   # was: apps/mds_docs
```

(Vercel 프로젝트 자체의 root directory 설정은 dashboard에서 수동 변경 필요 — README에 명시.)

### 8. Root workspace pubspec.yaml

Flutter 워크스페이스 melos 또는 pubspec 워크스페이스가 `shared/packages/*`, `apps/*`를 명시적으로 나열한다면 갱신 필요. Glob이면 자동.

```yaml
# 만약 명시적이라면:
workspace:
  - shared/packages/mds_tokens
  - shared/packages/mds
# →
workspace:
  - shared/packages/mds/tokens
  - shared/packages/mds/core
```

### 9. Root package.json npm workspaces

```json
"workspaces": ["apps/*"]
// → apps/mds/* 도 포함하려면:
"workspaces": ["apps/*", "apps/mds/*"]
```

또는 글로브 확장 (`apps/**` — Node v18+ 일부 npm 버전 지원 확인 필요).

### 10. README, CLAUDE.md, 기타 문서

`grep -rn 'shared/packages/mds' docs/ README.md CLAUDE.md AGENTS.md 2>/dev/null` 같은 검색으로 모든 경로 참조 발견 후 갱신.

특히:
- `apps/mds/docs/README.md`의 setup 안내
- `apps/mds/storybook/README.md`
- `docs/architecture/mds-extraction-plan.md`, `mds-storybook-wiring-plan.md`, `mds-tokens-wiring-plan.md`, `mds-docs-phase1-plan.md`, `mds-nesting-plan.md` (이 파일)

문서는 historical 기록이라 path를 강제 갱신하지 말 것 — 실제 코드 path만 갱신.

## 검증 게이트

```bash
# 1. Dart 패키지 그래프
cd shared/packages/mds/tokens && dart pub get
cd shared/packages/mds/core && flutter pub get && flutter analyze
cd shared/packages/minglit_kit && flutter pub get && flutter analyze

# 2. Flutter 앱
cd apps/mds/storybook && flutter pub get && flutter analyze && flutter test
cd apps/app_user && flutter pub get && flutter analyze
cd apps/app_partner && flutter pub get && flutter analyze

# 3. Next.js 앱
cd apps/mds/docs && npm install && npm run lint && npm run build

# 4. mds_tokens build
cd shared/packages/mds/tokens && npm install && npm run build
# → tokens.g.dart, tokens.css 정상 생성 확인

# 5. CI workflow YAML 문법
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy.yml'))"
```

모두 0 errors.

## 위험

- **Vercel 프로젝트 root directory** — Vercel dashboard에서 mds_docs 프로젝트의 root directory를 `apps/mds_docs` → `apps/mds/docs`로 수동 변경해야 deploy 동작. README와 PR body에 명시.
- **Path-resolution 도구** — graphify-out, IDE 인덱스 등 캐시가 stale해질 수 있음. PR 머지 후 graphify update 한 번 권장.
- **머지 충돌** — 4 패키지 폴더 이동은 다른 PR과 충돌 위험. **이 PR은 빠르게 머지** 권장 — 다른 mds_* 변경 PR 동시 진행 X.

## PR

- Base: dev
- Title: `chore(mds): nest mds_* packages under shared/packages/mds and apps/mds`
- Body: plan 링크 + before/after 다이어그램 + Vercel root 수동 변경 안내
- Auto-merge: ON

## 후속 PR

이번 PR 머지되면:
- **PR E**: mds_storybook deprecation 라벨 + README ("moved to mds_docs/components for view, will be removed in 26.06")
- **PR F**: mds_icons PoC at `shared/packages/mds/icons/` (자연스러운 새 위치)

---

**Date:** 2026-04-27
