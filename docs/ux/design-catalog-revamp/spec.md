# 디자인 카탈로그 리뉴얼 + Minglit 위젯 체계화

## 개요

디자인 카탈로그를 "Material 테마 프리뷰"에서 **"Minglit 위젯 라이브러리"**로 전환한다.
기존에 흩어져 있는 Minglit 위젯들을 카탈로그에 등록하고, 빠진 위젯을 추가한다.

## 현황

### 이미 존재하는 Minglit 위젯 (카탈로그 미등록)

| 위젯 | 파일 | 카테고리 |
|------|------|---------|
| `MinglitChip` | `minglit_chip.dart` | 입력/선택 |
| `MinglitFilterChip` | `minglit_filter_chip.dart` | 입력/선택 |
| `MinglitDialog` | `minglit_dialog.dart` | 오버레이 |
| `MinglitAlert` | `minglit_alert.dart` | 피드백 |
| `MinglitSectionDivider` | `minglit_section_divider.dart` | 레이아웃 |
| `MinglitSkeleton` | `minglit_skeleton.dart` | 로딩 |
| `MinglitImage` | `minglit_image.dart` | 미디어 |
| `MinglitImageCarousel` | `minglit_image_carousel.dart` | 미디어 |
| `MinglitFilePicker` | `minglit_file_picker.dart` | 입력 |
| `MinglitParticipantGauge` | `minglit_participant_gauge.dart` | 데이터 표시 |
| `MinglitAsyncValueWidget` | `minglit_async_value_widget.dart` | 상태 처리 |
| `MinglitCircularProgressIndicator` | `loading_indicator.dart` | 로딩 |
| `MinglitLinearProgressIndicator` | `loading_indicator.dart` | 로딩 |
| `MinglitEventCard` | `event_card.dart` | 카드 |
| `MinglitImageSourceSheet` | `minglit_image_source_sheet.dart` | 오버레이 |

### 신규 생성 중 (PR 대기)
| 위젯 | 카테고리 |
|------|---------|
| `MinglitSection` | 레이아웃 |
| `MinglitContentCard` | 레이아웃 |
| `MinglitKeyValueRow` | 레이아웃 |

### 아직 없는 위젯 (추가 필요)
| 위젯 | 용도 | 우선순위 |
|------|------|---------|
| `MinglitButton` | primary/secondary/text 버튼 통일 | P2 |
| `MinglitTextField` | 입력 필드 통일 (label, error, helper) | P2 |
| `MinglitBottomSheet` | 바텀시트 구조 통일 (헤더, 핸들, 패딩) | P2 |
| `MinglitBadge` | 상태 뱃지 (색상 + 라벨) | P1 |
| `MinglitEmptyState` | 빈 상태 (아이콘 + 메시지 + CTA) | P1 |
| `MinglitErrorState` | 에러 상태 (아이콘 + 메시지 + 재시도) | P1 |
| `MinglitListTile` | 리스트 항목 (아바타 + 제목/부제 + trailing) | P2 |
| `MinglitTag` | 태그 칩 (카테고리, 상태 표시) | P3 |

## 카탈로그 탭 재구성

### 현재 (15탭, Material 중심)
```
Colors | Typography | Spacing | Radius | Buttons | Cards | Inputs | Dialogs |
BottomSheet | Badge/Tag | Checkbox | TabBar | Divider | IconSize | Animation
```

### 변경 (2섹션, Minglit 중심)

**토큰 섹션** (디자인 기초값):
```
Colors | Typography | Spacing | Radius | IconSize | Animation
```

**위젯 섹션** (재사용 가능한 컴포넌트):
```
Layout | Buttons | Inputs | Cards | Feedback | Overlay | Data | Loading
```

| 탭 | 포함 위젯 |
|---|----------|
| **Layout** | `MinglitSection`, `MinglitContentCard`, `MinglitKeyValueRow`, `MinglitSectionDivider`, `MinglitListTile` |
| **Buttons** | `MinglitButton` (primary/secondary/text/icon), `MinglitChip`, `MinglitFilterChip` |
| **Inputs** | `MinglitTextField`, `MinglitFilePicker`, Checkbox |
| **Cards** | `MinglitEventCard`, `MinglitContentCard` (highlighted), `MinglitTag`, `MinglitBadge` |
| **Feedback** | `MinglitEmptyState`, `MinglitErrorState`, `MinglitAlert`, `MinglitDialog` |
| **Overlay** | `MinglitBottomSheet`, `MinglitImageSourceSheet`, `MinglitDialog` |
| **Data** | `MinglitParticipantGauge`, `MinglitKeyValueRow`, `MinglitImage`, `MinglitImageCarousel` |
| **Loading** | `MinglitSkeleton`, `MinglitCircularProgressIndicator`, `MinglitLinearProgressIndicator`, `MinglitAsyncValueWidget` |

총 14탭 (토큰 6 + 위젯 8)

## 구현 이슈 분할

| 순서 | 제목 | 내용 | 우선순위 |
|------|------|------|---------|
| 1 | feat: MinglitEmptyState + MinglitErrorState 위젯 | 앱 전체에서 가장 자주 쓰이는 빈/에러 상태 통일 | P1 |
| 2 | feat: MinglitBadge 위젯 | 상태 뱃지 통일 (정산, 파티, 이벤트 등에서 각자 구현 중) | P1 |
| 3 | refactor: 디자인 카탈로그 탭 재구성 (토큰/위젯 분리) | 기존 15탭 → 14탭 재구성 + 기존 Minglit 위젯 등록 | P1 |
| 4 | feat: MinglitButton 위젯 | primary/secondary/text/icon 버튼 팩토리 | P2 |
| 5 | feat: MinglitTextField 위젯 | label, error, helper 포함 입력 필드 | P2 |
| 6 | feat: MinglitBottomSheet 위젯 | 핸들 + 헤더 + 패딩 구조 통일 | P2 |
| 7 | feat: MinglitListTile 위젯 | 아바타 + 제목/부제 + trailing 구조 통일 | P2 |
| 8 | feat: MinglitTag 위젯 | 카테고리/상태 태그 | P3 |

## 위젯 설계 원칙

1. **테마 기반** — 하드코딩 금지, `Theme.of(context)` + `MinglitSpacing/Radius/Colors` 사용
2. **다크모드 자동 대응** — `colorScheme` 시맨틱 컬러만 사용
3. **Composable** — 위젯끼리 자유롭게 조합 (`MinglitSection` > `MinglitContentCard` > `MinglitKeyValueRow`)
4. **최소 API** — 필수 파라미터 최소화, 합리적 기본값
5. **접근성** — Semantics, 최소 터치 영역 48dp, 충분한 대비율

## 검증

- 카탈로그에서 모든 위젯의 라이트/다크 모드 확인
- 각 위젯의 사용 예시 코드가 카탈로그에 포함
- 기존 앱 코드에서 Minglit 위젯으로 교체 가능한 곳 식별 (후속 작업)
