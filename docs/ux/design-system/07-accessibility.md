# 07. Accessibility — 접근성 가이드

밍릿 앱의 접근성 기준과 구현 가이드입니다.

---

## 1. 최소 터치 영역

### 기준

- **최소 48x48dp** (Material Design 권장, WCAG 2.5.8)
- 시각적 크기가 작더라도 터치 영역은 48x48dp 이상 확보

### 현재 코드 적용

| 컴포넌트 | 최소 크기 | 소스 | 충족 여부 |
| :--- | :--- | :--- | :--- |
| ElevatedButton | `infinity x 56` | `minglit_component_theme.dart:24` | O |
| OutlinedButton | `infinity x 56` | `minglit_component_theme.dart:40` | O |
| TextButton | 기본값 (48x48) | `minglit_component_theme.dart:53` | O |
| AppBar icon | 48x48 (Material 기본) | Material 기본값 | O |
| Checkbox | 48x48 (Material 기본) | Material 기본값 | O |
| IconButton | 48x48 (Material 기본) | Material 기본값 | O |
| MinglitChip | `ConstrainedBox(minHeight: 48, minWidth: 48)` | `minglit_chip.dart` (Fix #1376) | O |
| MinglitFilterChip | `ConstrainedBox(minHeight: 48, minWidth: 48)` | `minglit_filter_chip.dart` (Fix #1376) | O |

---

## 2. 색상 대비 (WCAG AA)

### 기준

| 텍스트 유형 | 최소 대비 비율 |
| :--- | :--- |
| 일반 텍스트 (< 18px) | 4.5:1 |
| 대형 텍스트 (>= 18px bold 또는 >= 24px) | 3:1 |
| UI 컴포넌트 (아이콘, 테두리 등) | 3:1 |

### Light Mode 대비 검증

배경: `#FFFFFF` (`MinglitColors.background`, `minglit_design_tokens.dart:7`)

| 토큰 | Hex | 대비 비율 (vs #FFFFFF) | 기준 | 충족 |
| :--- | :--- | :--- | :--- | :--- |
| `textPrimary` | `#111827` | 16.8:1 | 4.5:1 | O |
| `textSecondary` | `#4B5563` | 7.1:1 | 4.5:1 | O |
| `primary` | `#9900FF` | 4.6:1 | 3:1 (대형 텍스트/UI) | O |
| `error` | `#EF4444` | 3.9:1 | 3:1 (대형 텍스트/UI) | O |
| `success` | `#22C55E` | 2.8:1 | 3:1 | **X** |
| `warning` | `#F59E0B` | 2.1:1 | 3:1 | **X** |

#### success / warning 색상 대비 가이드

`success`(2.8:1)와 `warning`(2.1:1)은 흰색 배경 위에서 단독 텍스트로 사용하면 WCAG AA 미충족이다. 현재 코드에서 이 색상들은 주로 배지, 아이콘, 상태 표시에 사용되며 다음 규칙을 적용한다:

| 사용 방식 | 허용 여부 | 보완 방법 |
| :--- | :--- | :--- |
| 아이콘 + 텍스트 조합 (텍스트는 `textPrimary`) | O | 색상이 정보 전달의 유일한 수단이 아님 |
| 배경색으로 사용 (위에 흰색/어두운 텍스트) | O | 충분한 대비 확보 가능 |
| 단독 텍스트 색상 | **X** | 사용 금지 — `textPrimary`와 아이콘 조합으로 대체 |

> **향후 개선 시 권장 대체색**:
> - success: `#16A34A` (green-600, 대비 4.6:1) 또는 `#15803D` (green-700, 대비 6.2:1)
> - warning: `#D97706` (amber-600, 대비 3.2:1) 또는 `#B45309` (amber-700, 대비 4.4:1)
>
> 색상 변경 시 디자인 시스템 전체 영향도 검토 필요. 현재는 사용 규칙 준수로 대비 요건을 충족한다.

### Dark Mode 대비 검증

배경: `#0F0F0F` (`MinglitColorsDark.background`, `minglit_design_tokens.dart:45`)

| 토큰 | Hex | 대비 비율 (vs #0F0F0F) | 기준 | 충족 |
| :--- | :--- | :--- | :--- | :--- |
| `textPrimary` | `#FFFFFF` | 19.3:1 | 4.5:1 | O |
| `textSecondary` | `#AAAAAA` | 8.9:1 | 4.5:1 | O |
| `primary` | `#AA33FF` | 4.8:1 | 3:1 | O |
| `error` | `#EF4444` | 5.1:1 | 3:1 | O |
| `success` | `#4ADE80` | 11.1:1 | 3:1 | O |
| `warning` | `#FBBF24` | 11.5:1 | 3:1 | O |
| `info` | `#60A5FA` | 7.7:1 | 3:1 | O |

> 다크 모드 시맨틱 색상은 라이트 모드보다 밝은 톤을 사용하여 전체 WCAG AA 충족.

---

## 3. Semantics (스크린리더)

### 기본 원칙

- 모든 인터랙티브 요소에 `Semantics` 라벨 제공
- 이미지에 `semanticLabel` 속성 필수
- 장식용 이미지는 `excludeFromSemantics: true`

### 위젯 유형별 적용 가이드

#### 이미지 위젯

```dart
// 콘텐츠 이미지 — 의미를 전달하는 이미지
MinglitImage(
  imageUrl: url,
  semanticLabel: '파티 대표 이미지',  // 내용을 설명하는 라벨
)

// 장식용 이미지 — 정보 전달 목적이 아닌 이미지
Image.network(
  url,
  excludeFromSemantics: true,
)

// 캐러셀 — 현재 위치 정보 포함
Semantics(
  label: '이미지 ${currentIndex + 1}/${totalCount}',
  image: true,
  child: MinglitImageCarousel(...),
)
```

#### 인터랙티브 위젯

```dart
// 칩 — 선택 상태와 내용 전달
Semantics(
  button: true,
  selected: isSelected,
  label: '카테고리: 파티',
  child: MinglitChip(...),
)

// 필터 칩 — 토글 상태 전달
Semantics(
  toggled: isActive,
  label: '필터: 강남구',
  child: MinglitFilterChip(...),
)
```

#### 알림/다이얼로그

```dart
// Alert — Material AlertDialog 기반으로 기본 시맨틱스 제공
// title, content 텍스트가 자동으로 읽힘
MinglitAlert(
  title: '신청 완료',      // 스크린리더가 자동으로 읽음
  content: '신청되었습니다', // 스크린리더가 자동으로 읽음
)

// Dialog — 복잡한 콘텐츠일 때 요약 라벨 추가
Semantics(
  label: '이벤트 상세 정보',
  namesRoute: true,  // 새 화면으로 인식
  child: MinglitDialog(...),
)
```

#### 카드 위젯

```dart
// EventCard — 핵심 정보를 하나의 시맨틱 노드로 병합
Semantics(
  button: true,
  label: '이벤트: 강남 파티, 4월 20일, 참가자 5/10명',
  excludeSemantics: true,  // 하위 요소 중복 읽기 방지
  child: EventCard(...),
)
```

### 공용 위젯 Semantics 현황

| 위젯 | Semantics 적용 | 비고 |
| :--- | :--- | :--- |
| `MinglitImage` | X — 미적용 | `semanticLabel` 파라미터 추가 필요 |
| `MinglitImageCarousel` | X — 미적용 | 페이지 위치 시맨틱스 필요 |
| `MinglitChip` | X — 미적용 | 선택 상태 시맨틱스 필요 |
| `MinglitAlert` | △ — Material 기본 | `AlertDialog` 기반으로 title/content는 자동 읽힘 |
| `MinglitDialog` | △ — Material 기본 | `AlertDialog` 기반으로 기본 시맨틱스 제공 |
| `EventCard` | X — 미적용 | 카드 전체를 하나의 시맨틱 노드로 병합 필요 |
| `MinglitTextField` | **O** | `Semantics(textField: true, label: label)` 적용 |
| `MinglitListTile` | **O** | `Semantics(button: onTap != null, enabled: enabled)` 적용 |
| `MinglitEventCard` | **O** (부분) | `_ParticipantDDayOverlay`에 참가 현황 시맨틱스 적용 |

> 미적용 위젯(X)은 각 위젯에 `Semantics` 래핑 추가가 필요하다. 위의 유형별 가이드를 참고하여 구현한다.

---

## 4. 포커스 순서 (키보드/스위치 접근)

### 기본 원칙

- 시각적 순서와 포커스 순서가 일치해야 함
- `FocusTraversalGroup`으로 논리적 그룹핑
- 모달/다이얼로그 열릴 때 포커스 트래핑 (외부 요소로 이동 차단)

### 권장 포커스 순서

| 화면 유형 | 포커스 순서 |
| :--- | :--- |
| 폼 화면 | AppBar 액션 → 입력 필드 순서대로 → 제출 버튼 |
| 목록 화면 | AppBar 액션 → 필터/검색 → 리스트 아이템 순서대로 |
| 다이얼로그 | 제목 → 본문 → Secondary 버튼 → Primary 버튼 |
| BottomSheet | 드래그 핸들 → 옵션 순서대로 → 확인 버튼 |

### 구현 가이드

Flutter는 위젯 트리 순서대로 포커스가 이동한다 (`ReadingOrderTraversalPolicy` 기본). 대부분의 경우 위젯 트리 구조만 올바르게 구성하면 포커스 순서가 자연스럽게 보장된다.

**명시적 포커스 제어가 필요한 경우:**

```dart
// 논리적 그룹핑 — 필터 영역과 목록을 분리
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(
        order: NumericFocusOrder(1),
        child: FilterSection(...),
      ),
      FocusTraversalOrder(
        order: NumericFocusOrder(2),
        child: EventListSection(...),
      ),
    ],
  ),
)

// 다이얼로그 포커스 트래핑 — Material Dialog가 자동 처리
// showDialog, showModalBottomSheet는 FocusTrap을 자동 적용한다.
// 커스텀 오버레이를 사용할 때만 수동 FocusScope 필요:
FocusScope(
  autofocus: true,
  child: CustomOverlay(...),
)
```

**현재 상태:** Flutter Material 위젯(`showDialog`, `showModalBottomSheet`)을 사용하므로 포커스 트래핑은 자동 적용됨. 커스텀 위젯에서는 위젯 트리 순서가 시각적 순서와 일치하는지 확인 필요.

---

## 5. 텍스트 크기 조절

### 기본 원칙

- `MediaQuery.textScaleFactor` 1.0~2.0 범위에서 레이아웃 깨지지 않아야 함
- `overflow: TextOverflow.ellipsis` 또는 `maxLines` 적용으로 오버플로우 방지
- 고정 높이 컨테이너 지양, `Flexible`/`Expanded` 활용

### 현재 코드 적용

| 항목 | 현황 | 비고 |
| :--- | :--- | :--- |
| 타이포그래피 | `MinglitTypo`로 일관 관리 | 상대적 크기 사용, 스케일링 자동 대응 |
| 텍스트 오버플로우 | `TextOverflow.ellipsis` + `maxLines` 패턴 사용 | 카드, 리스트 타일 등에 적용 |
| 컨테이너 높이 | 고정 높이 일부 존재 | 버튼(56dp), 칩(48dp) 등은 최소 높이로 설정 |

> **검증 방법:** 기기 설정에서 텍스트 크기를 최대(2.0x)로 변경 후 주요 화면(홈, 이벤트 상세, 프로필)에서 레이아웃 깨짐 여부를 확인한다. 오버플로우 발생 시 해당 위젯에 `Flexible` 래핑 또는 `maxLines` 추가로 대응한다.

---

## 6. 체크리스트

| 항목 | 기준 | 상태 |
| :--- | :--- | :--- |
| 최소 터치 영역 48x48dp | WCAG 2.5.8 | **충족** — 기본 컴포넌트 + MinglitChip, MinglitFilterChip 모두 48dp 이상 |
| 색상 대비 (일반 텍스트) | WCAG AA 4.5:1 | **충족** — textPrimary(16.8:1), textSecondary(7.1:1) |
| 색상 대비 (대형 텍스트/UI) | WCAG AA 3:1 | **부분 충족** — success(2.8:1), warning(2.1:1) 미충족. 사용 규칙으로 보완 (§2 참고) |
| Semantics 라벨 | 모든 인터랙티브 요소 | **부분 적용** — MinglitTextField, MinglitListTile 적용 완료. 6개 위젯 미적용 (§3 참고) |
| 포커스 순서 | 시각적 순서와 일치 | **기본 충족** — Material 위젯 기반으로 자동 보장. 커스텀 오버레이 검증 필요 |
| 텍스트 크기 조절 | 1.0x ~ 2.0x 대응 | **기본 대응** — MinglitTypo 상대적 크기 사용. 2.0x 실기기 검증 필요 |
| 다크 모드 | 전체 화면 대응 | **색상 대비 충족** — 시맨틱 색상 전체 WCAG AA 통과. 골든 테스트 확충 필요 |

---

## 관련 문서

- [01-foundation.md](01-foundation.md) -- 색상 토큰 (대비 비율 기준)
- [06-ux-writing.md](06-ux-writing.md) -- 스크린리더 텍스트 작성

---

*소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
