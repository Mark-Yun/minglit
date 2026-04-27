# mds_tokens Wiring Plan — Follow-up #2

**Status:** PoC, feature/mds-tokens-wiring 브랜치
**Goal:** mds 패키지가 mds_tokens.g.dart의 codegen된 const를 소비하도록 wiring
**Predecessors:** #1869 (MDS extraction), #1887 (storybook wiring)

## 문제

현재 상태:
- `mds/lib/src/theme/minglit_design_tokens.dart`의 `MinglitColors` 클래스는 hardcoded `Color(0xFFXXXXXX)` 상수들을 들고 있음
- `mds_tokens/lib/generated/tokens.g.dart`의 `MdsTokens` 클래스는 같은 값들을 `int` 상수로 codegen함
- 두 소스가 **이중 정의**되어 있어 SSOT 의미가 없음 — 디자이너가 `tokens.json`만 바꿔도 mds가 반영하지 않음

## 결정

**Approach: 단방향 단일 소스화**

`mds_tokens`을 SSOT로 두고, `mds`의 `MinglitColors`는 `MdsTokens`의 int 값을 `Color()`로 래핑하는 얇은 어댑터로 만든다.

```dart
// Before:
class MinglitColors {
  static const background = Color(0xFFFFFFFF);
  static const primary = Color(0xFF9900FF);
}

// After:
class MinglitColors {
  static const background = Color(MdsTokens.colorBackground);
  static const primary = Color(MdsTokens.colorPrimary);
}
```

**효과:**
- `tokens.json` → `npm run build` → `tokens.g.dart` → `MinglitColors`로 한 방향만 흐름
- `MinglitColors` API surface는 그대로 유지 → app code, mds 내부 widget 영향 0
- 디자이너 토큰 변경이 자동으로 mds 컴포넌트에 반영

## 작업 범위

### 1. 의존성 추가

`shared/packages/mds/pubspec.yaml`에:
```yaml
dependencies:
  mds_tokens:
    path: ../mds_tokens
```

### 2. MinglitColors 마이그레이션

`mds/lib/src/theme/minglit_design_tokens.dart`의 `MinglitColors` 클래스 — hardcoded `Color(0x...)`를 `Color(MdsTokens.colorX)`로 교체.

**매핑 (예상):**

| MinglitColors entry | MdsTokens entry |
|---|---|
| `background` | `colorBackground` |
| `primary` | `colorPrimary` |
| `secondary` | `colorSecondary` |
| `tertiary` | `colorTertiary` |
| `surface` | `colorSurface` |
| `error` | `colorError` |
| `textPrimary` | `colorTextPrimary` |
| `textSecondary` | `colorTextSecondary` |
| `success` | `colorSuccess` |
| `info` | `colorInfo` |
| `warning` | `colorWarning` |
| `transparent` | `colorTransparent` |
| `divider` | `colorDivider` |
| `scrim` | `colorScrim` |
| ... (기타) | ... |

**중요:** `MdsTokens`에 없는 항목 처리:
- 직접 매핑 없음 → 일단 hardcoded 유지 + `// TODO(mds-tokens): add to tokens.json` 주석
- 다크모드 variant도 동일 — `MdsTokens.colorBackgroundDark` 같은 게 있으면 사용, 없으면 TODO

**ABSOLUTE constraint:** 값을 절대 변경하지 말 것. 단순 `Color(0xFF...)` → `Color(MdsTokens.X)` 치환만. 16진수 값이 다르면 즉시 STOP하고 보고.

### 3. Spacing / Radius / Typography 검토 (best-effort)

`MinglitColors` 외에 `mds/lib/src/theme/`에 `MinglitSpacing`, `MinglitRadius`, `MinglitTypography` 등 비슷한 hardcoded 토큰 클래스가 있다면 동일 패턴으로 마이그레이션.

- 단, **Color 마이그레이션이 우선**. 시간/복잡도 부족하면 spacing/radius/typography는 후속 PR로 미룸.
- 마이그레이션하지 않은 카테고리는 plan 문서에 명시하고 TODO 코멘트 남김.

### 4. 검증

- `cd shared/packages/mds && flutter analyze` — 0 errors
- `cd shared/packages/mds && flutter test` (있다면) — pass
- `cd shared/packages/minglit_kit && flutter analyze && flutter test` — pre-existing 골든 실패 외 NEW 실패 없음
- `cd apps/app_user && flutter analyze` — 0 errors
- `cd apps/app_partner && flutter analyze` — 0 errors
- `cd apps/mds_storybook && flutter analyze && flutter test` — smoke test pass
- **시각 회귀 sanity check**: `MdsTokens.colorPrimary == 0xFF9900FF` 같이 spot-check 5-10개 색상 값이 일치하는지 grep으로 검증

### 5. CI 변경

이미 #1869에서 mds path filter가 추가됐으니 CI 워크플로우 자체는 변경 불필요. mds 내부 변경이므로 기존 `app_user_or_kit / app_partner_or_kit` 매트릭스 트리거.

## 위험

- **시각 회귀**: 토큰 값이 잘못 매핑되면 색이 미묘하게 달라짐. 골든 테스트가 잡아주지만 dev/CI 환경에서만 실행되니 PR 시 reviewer 확인 필요.
- **이중 정의 잔존**: `MdsTokens`에 없는 색상은 여전히 `MinglitColors`에 hardcoded — 부분적 SSOT. 후속 PR에서 토큰 보강.
- **패키지 의존 그래프**: `mds → mds_tokens` 의존 추가 — 순환은 아니지만 mds의 "pure UI" 약속에 톤이 약간 다름 (tokens도 SSOT의 일부니까 OK).

## PR

- Base: dev
- Title: `feat(mds): consume mds_tokens for color SSOT (Follow-up #2)`
- Auto-merge: ON
- Body: plan 링크 + 매핑 표 + 마이그레이션 안 한 토큰 카테고리 (있다면) 명시

## 후속 PR (이번 범위 X)

1. `MdsTokens`에 누락된 토큰들 추가 (다크모드 variants, 누락 색상)
2. Spacing/Radius/Typography wiring (이번 PR에서 미룸 시)
3. Web 타겟 codegen 추가 (CSS 변수 → mds-react로 공유)
4. 디자인 시스템 문서 업데이트 — `tokens.json`이 SSOT임을 명시

---

**Date:** 2026-04-27
