# PR F — mds_icons PoC

**Status:** PoC, feature/mds-icons-poc 브랜치
**Goal:** 디자인 시스템 아이콘 패키지 부트스트랩 — SVG SSOT, Dart 코드젠, mds_docs `/icons` 자동 카탈로그
**Predecessors:** #1869, #1887, #1899, #1904, #1916 (nesting refactor)

## 사용자 결정 (이전 논의)

| 항목 | 결정 |
|---|---|
| 포맷 | **SVG** (currentColor 기반 theme 결합, recolorable) |
| 초기 셋 | **핵심 5-10개** (현재 앱에서 가장 많이 쓰는 아이콘 우선) |
| 마이그레이션 전략 | **점진적** — 신규는 mds_icons 사용, 기존 Material Icons는 천천히 |

## 패키지 구조

```
shared/packages/mds/icons/
  pubspec.yaml                     ← Dart-only, name: mds_icons
  package.json                     ← npm (svgo + codegen 도구)
  build.config.mjs                 ← codegen 스크립트 entry
  icons/                           ← SVG 소스 (SSOT)
    profile.svg
    settings.svg
    notification.svg
    ...
  manifest.json                    ← [{ name, viewBox, defaultColor, categories }]
  scripts/
    build.mjs                      ← svgo 최적화 + Dart codegen
  lib/
    mds_icons.dart                 ← barrel export
    generated/
      icons.g.dart                 ← class MdsIcons { static SvgPicture profile() => ... }
  README.md
  .gitignore                       ← node_modules
```

## 초기 아이콘 셋 결정 (Agent에게 위임)

Agent가 먼저 조사:
1. `apps/app_user/`, `apps/app_partner/`, `shared/packages/minglit_kit/`의 Dart 파일에서 `Icons.X` 사용 빈도 grep
2. 상위 10-15개 추출 → 그 중 핵심 5-10개 선정 기준:
   - 자주 쓰임 (사용 빈도)
   - 도메인 중요도 (브랜드 핵심 액션 — 예: party 관련, partner 관련)
   - SVG로 만들 가치 있음 (Material Icons 그대로 두면 되는 너무 generic한 건 제외)

**예상 후보 (실제 grep 결과로 확정):**
- `arrow_back` — 네비게이션 (고빈도)
- `more_vert` / `more_horiz`
- `close`
- `check`
- `search`
- `settings`
- `person` / `account_circle`
- `notifications`
- `add`
- `edit`

처음엔 **5개**만으로 시작 — too thin이면 나중에 확장. 너무 많으면 codegen 검증 부담.

## SVG 소스 전략

**옵션 A**: Lucide (https://lucide.dev) — 1500+ 아이콘, MIT, 깔끔한 디자인. 기본 stroke style.
**옵션 B**: Phosphor Icons — 비슷한 규모, MIT, 6 weight variants.
**옵션 C**: Heroicons — Tailwind 팀 제작, MIT, 적은 수지만 일관됨.
**옵션 D**: 직접 디자인 — 디자이너 의존, 시간 큼.

**PoC 권장: Lucide** — 풍부한 카탈로그, brand-neutral, 향후 minglit 디자이너가 커스텀으로 교체할 때 baseline 좋음.

## Codegen 파이프라인

`shared/packages/mds/icons/scripts/build.mjs`:

```js
// 1. icons/*.svg 모두 읽기
// 2. svgo로 최적화 (다음 옵션):
//    - removeXMLNS (이미 지원), removeViewBox (false — 유지),
//      removeComments, cleanupAttrs, mergePaths, convertColors
//    - inlineStyles (단순화)
//    - 모든 fill/stroke을 currentColor로 변환 (theme 결합)
// 3. manifest.json 갱신 (자동)
// 4. lib/generated/icons.g.dart 생성:
//    class MdsIcons {
//      MdsIcons._();
//      static const String _profileSvg = '''<svg ...>''';
//      static SvgPicture profile({double? size, Color? color}) =>
//        SvgPicture.string(_profileSvg, height: size, width: size, colorFilter: ...);
//    }
```

`package.json`:
```json
{
  "name": "@minglit/mds-icons",
  "private": true,
  "scripts": {
    "build": "node scripts/build.mjs"
  },
  "devDependencies": {
    "svgo": "^3.x"
  }
}
```

`pubspec.yaml`:
```yaml
name: mds_icons
description: "Minglit Design System icons — SVG-based, theme-aware via currentColor."
version: 26.04.1922-dev
resolution: workspace
environment:
  sdk: ">=3.7.0 <4.0.0"
  flutter: ">=3.41.0"
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.x   # SvgPicture rendering
```

## mds_docs `/icons` 페이지

`apps/mds/docs/src/app/icons/page.tsx`:
- manifest.json 또는 generated/icons.g.dart 파싱하여 자동 카탈로그
- 각 아이콘: 시각 미리보기 + 이름 + 사용 코드 스니펫 (`MdsIcons.profile()`)
- 카테고리 그룹화 (manifest에 categories 필드)
- search 기능 (선택, scope cut 가능)

iframe으로 SVG 직접 렌더 가능 (mds_icons/icons/*.svg를 mds_docs/public/mds-icons/로 build time 복사 또는 CSS background-image).

## CI

`.github/workflows/ci.yml` paths-filter:
```yaml
mds_icons:
  - 'shared/packages/mds/icons/**'
```

mds_docs 변경 트리거에 mds_icons도 포함 (icons page는 mds_icons에 의존).

별도 lint-mds-icons job은 처음엔 생략 — npm build script가 핵심이고, Dart 쪽은 mds 패키지가 transitively 검증.

## 마이그레이션 가이드 (README)

새 아이콘 사용:
```dart
// Before:
Icon(Icons.person)

// After:
MdsIcons.profile(size: 24, color: theme.colorScheme.primary)
```

기존 코드는 **수정 강요 X**. 새 코드 작성 시 mds_icons 우선 사용.

## 검증 게이트

```bash
cd shared/packages/mds/icons && npm install && npm run build
# → lib/generated/icons.g.dart 생성됨, manifest.json 갱신됨
ls lib/generated/icons.g.dart manifest.json icons/*.svg

cd shared/packages/mds/icons && dart pub get && dart analyze
# → 0 errors

cd apps/mds/docs && npm install && npm run lint && npm run build
# → /icons 페이지 정상 렌더 (5-10 아이콘 카드)
```

## 위험

- **Lucide SVG → Flutter currentColor 변환** — Lucide는 stroke 기반이라 fill 변환 룰이 단순. 그러나 일부 아이콘에 multiple paths/groups가 있을 수 있음 — svgo 변환 후 검증 필요.
- **flutter_svg 의존 추가** — mds 패키지가 이미 flutter_svg 사용 중이라 새 의존성 X.
- **Codegen 결과 git tracked vs ignored** — tracked 권장 (mds_tokens 패턴 따름). consumer가 codegen 안 돌려도 됨.

## PR

- Base: dev
- Title: `feat(mds_icons): bootstrap design system icons package (PoC)`
- Auto-merge: ON
- Body: plan 링크 + 선정된 아이콘 목록 + 사용 예시

## 후속 PR (이번 범위 X)

- 추가 아이콘 25-50개 확장
- 디자이너 커스텀 아이콘 교체
- Web codegen target (CSS sprite 또는 React component)
- 기존 `Icons.X` 사용처 점진 마이그레이션 가이드

---

**Date:** 2026-04-27
