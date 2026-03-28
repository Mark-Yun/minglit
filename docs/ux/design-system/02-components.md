# 02. Components — 컴포넌트 테마

밍릿 디자인 시스템의 Material 3 기반 컴포넌트 커스터마이징 설정입니다.

**소스**: `shared/packages/minglit_kit/lib/src/theme/minglit_component_theme.dart`

---

## 1. AppBar

**소스**: `minglit_component_theme.dart:5-17`

| 속성 | Light Mode | Dark Mode | 라인 |
| :--- | :--- | :--- | :--- |
| backgroundColor | `#FFFFFF` (`MinglitColors.background`) | `#0F0F0F` (`MinglitColorsDark.background`) | :6 |
| elevation | 0 | 0 | :7 |
| centerTitle | true | true | :8 |
| iconTheme.color | `#111827` (`MinglitColors.textPrimary`) | `#FFFFFF` (`MinglitColorsDark.textPrimary`) | :9 |
| titleTextStyle.fontSize | 18 | 18 | :12 |
| titleTextStyle.fontWeight | w600 | w600 | :13 |
| titleTextStyle.fontFamily | NotoSansKR | NotoSansKR | :14 |
| titleTextStyle.color | `#111827` | `#FFFFFF` | :11 |

Dark Mode 소스: `minglit_theme.dart:168-180`

---

## 2. Button — ElevatedButton (Primary)

**소스**: `minglit_component_theme.dart:19-35`

| 속성 | 값 | 라인 |
| :--- | :--- | :--- |
| backgroundColor | `#9900FF` (`MinglitColors.primary`) | :21 |
| foregroundColor | `#FFFFFF` (white) | :22-23 |
| minimumSize | `infinity x 56` (전체 너비, 높이 56) | :24 |
| borderRadius | 16 (`MinglitRadius.button`) | :25-27 |
| elevation | 0 | :28 |
| textStyle.fontSize | 16 | :31 |
| textStyle.fontWeight | bold | :32 |

---

## 3. Button — OutlinedButton (Secondary)

**소스**: `minglit_component_theme.dart:37-51`

| 속성 | 값 | 라인 |
| :--- | :--- | :--- |
| foregroundColor | `#9900FF` (`MinglitColors.primary`) | :39 |
| minimumSize | `infinity x 56` | :40 |
| borderRadius | 16 (`MinglitRadius.button`) | :41-43 |
| borderSide.color | `#9900FF` (`MinglitColors.primary`) | :44 |
| textStyle.fontSize | 16 | :47 |
| textStyle.fontWeight | bold | :48 |

---

## 4. Button — TextButton

**소스**: `minglit_component_theme.dart:53-62`

| 속성 | 값 | 라인 |
| :--- | :--- | :--- |
| foregroundColor | `#9900FF` (`MinglitColors.primary`) | :55 |
| textStyle.fontSize | 14 | :58 |
| textStyle.fontWeight | bold | :59 |

<!-- TODO: Destructive 버튼 (error 색상) 테마 정의 필요 -->

---

## 5. Card

**소스**: `minglit_component_theme.dart:64-71`

| 속성 | Light Mode | Dark Mode | 라인 |
| :--- | :--- | :--- | :--- |
| borderRadius | 24 (`MinglitRadius.card`) | 24 | :65-67 |
| elevation | 0 | 0 | :68 |
| color | `#F9FAFB` (`MinglitColors.surface`) | `#212121` (`MinglitColorsDark.surface`) | :69 |
| margin | EdgeInsets.zero | EdgeInsets.zero | :70 |

Dark Mode 소스: `minglit_theme.dart:184-191`

---

## 6. Input Field — InputDecoration

**소스**: `minglit_component_theme.dart:73-94`

| 속성 | Light Mode | Dark Mode | 라인 |
| :--- | :--- | :--- | :--- |
| filled | true | true | :74 |
| fillColor | `#F9FAFB` (`MinglitColors.surface`) | `#212121` (`MinglitColorsDark.surface`) | :75 |
| borderRadius | 12 (`MinglitRadius.input`) | 12 | :77 |
| border | none | none | :78 |
| enabledBorder | none | none | :81 |
| focusedBorder.color | `#9900FF` (`MinglitColors.primary`) | `#AA33FF` (`MinglitColorsDark.primary`) | :85 |
| focusedBorder.width | 2 | 2 | :85 |
| contentPadding | 16 (`MinglitSpacing.medium`) all | 16 all | :88 |
| hintStyle.color | `#4B5563` (`MinglitColors.textSecondary`) | `#AAAAAA` (`MinglitColorsDark.textSecondary`) | :91 |
| hintStyle.fontSize | 14 | 14 | :92 |

Dark Mode 소스: `minglit_theme.dart:192-216`

---

## 7. Chip

**소스**: `minglit_component_theme.dart:96-106`

| 속성 | Light Mode | Dark Mode | 라인 |
| :--- | :--- | :--- | :--- |
| borderRadius | 100 (pill shape) | 100 | :98 |
| side | none | none | :100 |
| backgroundColor | `#F9FAFB` (`MinglitColors.surface`) | `#212121` (`MinglitColorsDark.surface`) | :101 |
| secondarySelectedColor | `#9900FF` (`MinglitColors.primary`) | `#AA33FF` (`MinglitColorsDark.primary`) | :102 |
| labelStyle.fontSize | 13 | 13 | :104 |

Dark Mode 소스: `minglit_theme.dart:217-225`

---

## 8. Checkbox

**소스**: `minglit_component_theme.dart:108-122`

| 속성 | 값 | 라인 |
| :--- | :--- | :--- |
| fillColor (selected) | `#9900FF` (`MinglitColors.primary`) | :111 |
| fillColor (unselected) | null (기본값) | :113 |
| borderRadius | 4 | :116 |
| side.color | grey | :119 |
| side.width | 1.5 | :120 |

---

## 9. TabBar

**소스**: `minglit_component_theme.dart:124-142`

| 속성 | 값 | 라인 |
| :--- | :--- | :--- |
| labelColor | `#9900FF` (`MinglitColors.primary`) | :125 |
| unselectedLabelColor | `#4B5563` (`MinglitColors.textSecondary`) | :126 |
| indicatorColor | `#9900FF` (`MinglitColors.primary`) | :127 |
| indicatorSize | tab | :128 |
| dividerColor | transparent | :129 |
| labelStyle | 14px / bold / NotoSansKR | :130-134 |
| unselectedLabelStyle | 14px / w500 / NotoSansKR | :136-140 |

---

## 10. Divider

**소스**: `minglit_component_theme.dart:144-151`

| 속성 | Light Mode | Dark Mode | 라인 |
| :--- | :--- | :--- | :--- |
| color | `#E5E7EB` | `#3D3D3D` (`MinglitColorsDark.divider`) | :145-147 |
| thickness | 1 | 1 | :148 |
| space | 16 (`MinglitSpacing.medium`) | 16 | :149 |

Dark Mode 소스: `minglit_theme.dart:228-232`

---

## 11. BottomSheet

**기본 스타일**: `BottomSheetThemeData` 별도 설정 없음 — Flutter 기본 `showModalBottomSheet` 스타일 적용.

**밍릿 권장 패턴**:
- `showModalBottomSheet`로 호출
- 내부 패딩: `MinglitSpacing.large` (24px)
- 닫기/확인 버튼: 용도에 따라 `ElevatedButton` (CTA) 또는 `TextButton` (취소/닫기) 사용
- drag handle: Flutter 기본 제공

> 디자인 카탈로그 9번 탭에서 Modal BottomSheet 데모를 확인할 수 있습니다.

---

## 12. Badge / Tag

<!-- TODO: 커스텀 Badge/Tag 컴포넌트 테마 정의 필요. 현재는 Chip 기반으로 사용 중. -->

현재 뱃지/태그는 `MinglitChip` (`minglit_kit/lib/src/ui/widgets/common/minglit_chip.dart`) 및 `MinglitFilterChip` (`minglit_kit/lib/src/ui/widgets/common/minglit_filter_chip.dart`)으로 대체 사용합니다.

---

## 13. Toast / Snackbar

<!-- TODO: SnackBarTheme 정의가 minglit_component_theme.dart에 없음. 별도 SnackBar 테마 추가 필요. -->

현재 코드에 `SnackBarTheme` 설정이 없습니다. Flutter 기본 SnackBar 스타일이 적용됩니다.

---

## 관련 문서

- [01-foundation.md](01-foundation.md) -- 디자인 토큰 (색상, 간격, 곡률)
- [03-patterns.md](03-patterns.md) -- UI 패턴
- [기존 파트너 앱 디자인 시스템](../partner-app/design-system.md)

---

*이 문서의 모든 값은 소스 코드에서 직접 추출되었습니다. 소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
