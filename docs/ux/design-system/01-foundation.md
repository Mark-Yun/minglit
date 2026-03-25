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

| TextTheme 슬롯 | fontSize | fontWeight | color (Light) | 라인 (Light) |
| :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | 32 | bold | `#111827` (textPrimary) | :77-81 |
| `titleLarge` | 20 | bold | `#111827` (textPrimary) | :83-87 |
| `titleMedium` | 16 | bold | `#111827` (textPrimary) | :89-93 |
| `titleSmall` | 14 | bold | `#111827` (textPrimary) | :95-99 |
| `bodyMedium` | 16 | normal | `#4B5563` (textSecondary) | :101-104 |

> 다크 모드: 동일 fontSize/fontWeight, color만 `MinglitColorsDark` 값으로 대체 (`minglit_theme.dart:137-166`)

<!-- TODO: bodySmall, bodyLarge, labelLarge 등 나머지 TextTheme 슬롯 정의 필요 -->

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

---

## 5. Border Radius — `MinglitRadius`

**소스**: `minglit_design_tokens.dart:92-104`

| 토큰명 | 값 (px) | 용도 | 라인 |
| :--- | :--- | :--- | :--- |
| `small` | 8 | 작은 요소 (뱃지, 체크박스 등) | :94 |
| `input` | 12 | 입력 필드 (TextField) | :103 |
| `button` | 16 | 버튼 (ElevatedButton, OutlinedButton) | :97 |
| `card` | 24 | 카드, 바텀 시트, 이미지 클리핑 | :100 |

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

<!-- TODO: MinglitElevation 클래스 정의 필요 — 현재는 MinglitShadows만 존재 -->

---

## 8. Animation Duration — `MinglitAnimation`

**소스**: `minglit_design_tokens.dart:125-134`

| 토큰명 | 값 (ms) | 용도 | 라인 |
| :--- | :--- | :--- | :--- |
| `fast` | 200 | 간단한 상태 변화 (선택, 토글) | :127 |
| `medium` | 350 | 화면 전환, 모달 등장 | :130 |
| `slow` | 500 | 복잡한 레이아웃 변화 | :133 |

<!-- TODO: 표준 Curve 토큰 (easeInOut, easeOut 등) 정의 필요 -->

---

## 관련 문서

- [02-components.md](02-components.md) -- 컴포넌트 테마
- [05-motion.md](05-motion.md) -- 모션 가이드
- [기존 파트너 앱 디자인 시스템](../partner-app/design-system.md)

---

*이 문서의 모든 값은 소스 코드에서 직접 추출되었습니다. 소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
