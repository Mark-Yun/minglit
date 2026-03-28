# 01. Foundation — 기반 디자인 토큰

밍릿 디자인 시스템의 기반 토큰입니다. 모든 값은 코드에서 직접 추출했습니다.

**소스**: `shared/packages/minglit_kit/lib/src/theme/minglit_design_tokens.dart`

---

## 1. Color Palette (Light Mode) — `MinglitColors`

**소스**: `minglit_design_tokens.dart:5-41`

| 토큰명 | Hex | 용도 | 라인 |
| :--- | :--- | :--- | :--- |
| `background` | `#FFFFFF` | 기본 배경색 | :7 |
| `primary` | `#9900FF` | 브랜드 주색상 (Purple) | :10 |
| `secondary` | `#FF9900` | 보조 색상 (Amber) | :13 |
| `tertiary` | `#48C9B0` | 강조 색상 (Mint) | :16 |
| `surface` | `#F9FAFB` | 카드/입력 필드 배경 | :19 |
| `error` | `#EF4444` | 에러 상태 | :22 |
| `textPrimary` | `#111827` | 주요 텍스트 (Near-black) | :25 |
| `textSecondary` | `#4B5563` | 보조 텍스트 (Dark gray) | :28 |
| `success` | `#22C55E` | 성공 상태 | :31 |
| `warning` | `#F59E0B` | 경고 상태 | :34 |
| `transparent` | `#00000000` | 완전 투명 | :37 |
| `scrim` | `#80000000` | 오버레이 배경 (50% 불투명) | :40 |

---

## 2. Color Palette (Dark Mode) — `MinglitColorsDark`

**소스**: `minglit_design_tokens.dart:43-59`

| 토큰명 | Hex | 비고 | 라인 |
| :--- | :--- | :--- | :--- |
| `background` | `#0F0F0F` | 다크 배경 | :45 |
| `surface` | `#212121` | 다크 서피스 | :47 |
| `textPrimary` | `#FFFFFF` | 밝은 텍스트 | :49 |
| `textSecondary` | `#AAAAAA` | 보조 텍스트 | :51 |
| `primary` | `#AA33FF` | 라이트보다 밝게 조정 | :53 |
| `secondary` | `#FF9900` | 라이트 모드와 동일 | :54 |
| `tertiary` | `#48C9B0` | 라이트 모드와 동일 | :55 |
| `error` | `#EF4444` | 라이트 모드와 동일 | :56 |
| `divider` | `#3D3D3D` | 다크 모드 전용 구분선 | :58 |

---

## 3. Typography Scale

**소스**: `minglit_theme.dart:62-106` (Light), `minglit_theme.dart:121-167` (Dark)

기본 폰트 패밀리: `NotoSansKR` (`minglit_theme.dart:64`)

| TextTheme 슬롯 | fontSize | fontWeight | height | 실제 line-height | color (Light) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | 32 | bold | 1.25 | 40px | `#111827` (textPrimary) |
| `headlineSmall` | 24 | bold | 1.33 | 32px | `#111827` (textPrimary) |
| `titleLarge` | 20 | bold | 1.4 | 28px | `#111827` (textPrimary) |
| `titleMedium` | 16 | bold | 1.5 | 24px | `#111827` (textPrimary) |
| `titleSmall` | 14 | bold | 1.43 | 20px | `#111827` (textPrimary) |
| `bodyLarge` | 18 | normal | 1.33 | 24px | `#4B5563` (textSecondary) |
| `bodyMedium` | 16 | normal | 1.5 | 24px | `#4B5563` (textSecondary) |
| `bodySmall` | 13 | normal | 1.5 | 20px | `#4B5563` (textSecondary) |
| `labelLarge` | 14 | w500 | 1.43 | 20px | `#111827` (textPrimary) |
| `labelMedium` | 12 | w500 | 1.5 | 18px | `#111827` (textPrimary) |
| `labelSmall` | 11 | w500 | 1.45 | 16px | `#111827` (textPrimary) |

> 다크 모드: 동일 fontSize/fontWeight/height, color만 `MinglitColorsDark` 값으로 대체

### line-height 매핑 (4pt grid 기반)

| fontSize | height 값 | 실제 px |
| :--- | :--- | :--- |
| 11px | 1.45 | 16px |
| 12-13px | 1.5 | 18-20px |
| 14px | 1.43 | 20px |
| 16px | 1.5 | 24px |
| 18px | 1.33 | 24px |
| 20px | 1.4 | 28px |
| 24px | 1.33 | 32px |
| 32px | 1.25 | 40px |

---

## 4. Spacing — `MinglitSpacing`

**소스**: `minglit_design_tokens.dart:62-89`

| 토큰명 | 값 (px) | 용도 | 라인 |
| :--- | :--- | :--- | :--- |
| `zero` | 0 | 간격 없음 | :64 |
| `xxsmall` | 2 | 미세 간격 | :67 |
| `xsmall` | 4 | 요소 내 좁은 간격 | :70 |
| `xsmall2` | 6 | 중간 좁은 간격 | :73 |
| `small` | 8 | 일반 좁은 간격 | :76 |
| `sm` | 12 | 요소 간 중간 간격 | :79 |
| `medium` | 16 | 기본 여백 (Standard padding) | :82 |
| `large` | 24 | 섹션 간 간격 | :85 |
| `xlarge` | 32 | 큰 섹션 간 간격 | :88 |
| `xxlarge` | 48 | 대형 간격 | |
| `xxxlarge` | 64 | 대형 섹션 구분 | |

### 시맨틱 Spacing 토큰

용도별로 이름이 붙은 시맨틱 토큰입니다. 기본 scale 값을 참조하되 의미를 명확히 합니다.

| 토큰명 | 값 (px) | 용도 |
| :--- | :--- | :--- |
| `screenEdge` | 20 | 화면 좌우 패딩 (토스 20dp 표준) |
| `cardGap` | 12 | 카드 간 간격 |
| `cardContentV` | 16 | 카드 내부 vertical 패딩 |
| `titleToBody` | 4 | 제목-본문 간격 |
| `sectionGap` | 40 | 섹션 간 간격 |

---

## 5. Border Radius — `MinglitRadius`

**소스**: `minglit_design_tokens.dart:92-104`

| 토큰명 | 값 (px) | 용도 | 라인 |
| :--- | :--- | :--- | :--- |
| `small` | 8 | 작은 요소 (뱃지, 체크박스 등) | :94 |
| `button` | 12 | 버튼 (ElevatedButton, OutlinedButton) | :97 |
| `input` | 12 | 입력 필드 (TextField) | :103 |
| `card` | 16 | 카드, 바텀 시트, 이미지 클리핑 | :100 |
| `chip` | 100 | 칩 (fully rounded) | |

---

## 6. Icon Size — `MinglitIconSize`

**소스**: `minglit_design_tokens.dart:107-122`

| 토큰명 | 값 (px) | 용도 | 라인 |
| :--- | :--- | :--- | :--- |
| `xsmall` | 16 | 인라인 텍스트 옆 아이콘 | :109 |
| `small` | 20 | 리스트 아이템 보조 아이콘 | :112 |
| `medium` | 24 | 기본 아이콘 (Material 기본값) | :115 |
| `large` | 28 | 강조 아이콘 | :118 |
| `xlarge` | 32 | 대형 아이콘 (빈 상태 화면 등) | :121 |

---

## 7. Elevation / Shadow — `MinglitShadows`

**소스**: `minglit_design_utils.dart:4-13`

| 프리셋 | 값 | 라인 |
| :--- | :--- | :--- |
| `cardSelected(accentColor)` | blurRadius: 8 (`MinglitSpacing.small`), offset: (0, 4), color: accentColor 10% alpha | :7-11 |

> 대부분의 컴포넌트는 `elevation: 0`을 사용합니다 (flat design).

<!-- Note: flat design 기조(elevation: 0)에 따라 MinglitShadows만 사용. 별도 MinglitElevation 불필요. -->

---

## 8. Borders — `MinglitBorders`

**소스**: `minglit_design_utils.dart:16-22`

| 메서드 | 파라미터 | 반환 | 용도 |
| :--- | :--- | :--- | :--- |
| `card()` | `ColorScheme colorScheme`, `{bool isSelected = false}` | `Border` | 선택 가능 카드 테두리 |

동작:
- `isSelected: false` → `colorScheme.outlineVariant` (기본 테두리)
- `isSelected: true` → `colorScheme.secondary` (amber 강조)

---

## 9. Decorations — `MinglitDecorations`

**소스**: `minglit_design_utils.dart:25-42`

| 메서드 | 파라미터 | 반환 | 용도 |
| :--- | :--- | :--- | :--- |
| `selectableCard()` | `BuildContext context`, `{required bool isSelected}` | `BoxDecoration` | 선택 가능 카드 전체 데코레이션 |

동작:
- 미선택: `theme.cardColor` 배경 + `MinglitBorders.card(isSelected: false)`
- 선택: secondary 5% alpha 배경 + secondary 보더 + `MinglitShadows.cardSelected()` 그림자

---

## 10. TextStyles — `MinglitTextStyles`

**소스**: `minglit_design_utils.dart:45-82`

| 메서드 | 기반 스타일 | 커스텀 | 용도 | 라인 |
| :--- | :--- | :--- | :--- | :--- |
| `selectableCardTitle()` | `titleSmall` | 선택 시 secondary 색상 | 카드 제목 | :47-55 |
| `selectableCardSubtitle()` | `labelSmall` | onSurfaceVariant 70% alpha | 카드 부제 | :59-64 |
| `selectableCardDescription()` | `bodySmall` | onSurfaceVariant 색상 | 카드 설명 | :67-72 |
| `infoText()` | `bodySmall` | onSurfaceVariant 색상 | 정보 텍스트 | :76-81 |

> `selectableCardSubtitle`과 `infoText`의 하드코딩 fontSize는 #474 (Typography 시스템 정비)에서 TextTheme/ThemeExtension으로 전환 예정.

---

## 11. Opacity — `MinglitOpacity`

**소스**: `minglit_design_tokens.dart`

| 토큰명 | 값 | 용도 |
| :--- | :--- | :--- |
| `tintFill` | 0.05 | 틴트 채우기, 선택된 카드 배경 |
| `placeholder` | 0.15 | 아바타 플레이스홀더 배경 |
| `subtle` | 0.2 | 미충족 게이지 세그먼트 |
| `muted` | 0.3 | 비활성/빈 요소 |
| `gradient` | 0.45 | 그라디언트 오버레이 |
| `overlay` | 0.55 | 오버레이 배경 (뱃지, 이미지 위 칩) |
| `separator` | 0.6 | 구분자/디바이더 텍스트 |
| `scrimLight` | 0.8 | 라이트 스크림 |

---

## 12. Partner Colors — `MinglitPartnerColors`

**소스**: `minglit_design_tokens.dart`

파트너 앱 전용 브랜드 색상. 유저 앱 보라색보다 톤 다운된 인디고 계열.

### Light

| 토큰명 | Hex | 용도 |
| :--- | :--- | :--- |
| `primary` | `#6C3CE1` | 파트너 브랜드 인디고 |
| `primaryLight` | `#8B5CF6` | 그라디언트용 밝은 변형 |
| `primarySurface` | `#F5F0FF` | 카드/컨테이너 표면 틴트 |
| `primaryBorder` | `#E8E0FF` | 하이라이트 카드 테두리 |
| `primaryContainer` | `#F0EDFF` | 보조 버튼 컨테이너 채우기 |

### Dark

| 토큰명 | Hex | 용도 |
| :--- | :--- | :--- |
| `primary` | `#9B7BEC` | 다크 모드 파트너 인디고 |
| `primaryLight` | `#B39DFF` | 다크 모드 밝은 변형 |

---

## 13. Animation Duration — `MinglitAnimation`

**소스**: `minglit_design_tokens.dart`

| 토큰명 | 값 (ms) | 용도 |
| :--- | :--- | :--- |
| `micro` | 100 | 마이크로 인터랙션 |
| `fast` | 200 | 간단한 상태 변화 (선택, 토글) |
| `medium` | 350 | 화면 전환, 모달 등장 |
| `slow` | 500 | 복잡한 레이아웃 변화 |

<!-- TODO: 표준 Curve 토큰 (easeInOut, easeOut 등) 정의 필요 -->

---

## 관련 문서

- [02-components.md](02-components.md) -- 컴포넌트 테마
- [05-motion.md](05-motion.md) -- 모션 가이드
- [기존 파트너 앱 디자인 시스템](../partner-app/design-system.md)

---

*이 문서의 모든 값은 소스 코드에서 직접 추출되었습니다. 소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
