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

<!-- TODO: 커스텀 위젯 (MinglitChip, MinglitFilterChip 등)의 최소 터치 영역 검증 필요 -->

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

> `success`와 `warning` 색상은 배경색 위에서 단독 텍스트로 사용하면 대비 부족. 아이콘+텍스트 조합 또는 배경색 변경으로 보완 필요.

<!-- TODO: success, warning 색상 대비 개선 필요 -->

### Dark Mode 대비 검증

배경: `#0F0F0F` (`MinglitColorsDark.background`, `minglit_design_tokens.dart:45`)

| 토큰 | Hex | 대비 비율 (vs #0F0F0F) | 기준 | 충족 |
| :--- | :--- | :--- | :--- | :--- |
| `textPrimary` | `#FFFFFF` | 19.3:1 | 4.5:1 | O |
| `textSecondary` | `#AAAAAA` | 8.9:1 | 4.5:1 | O |
| `primary` | `#AA33FF` | 4.8:1 | 3:1 | O |

<!-- TODO: 다크 모드 전체 색상 대비 검증 완료 필요 -->

---

## 3. Semantics (스크린리더)

<!-- TODO: Semantics 위젯 적용 가이드 상세화 필요 -->

### 기본 원칙

- 모든 인터랙티브 요소에 `Semantics` 라벨 제공
- 이미지에 `semanticLabel` 속성 필수
- 장식용 이미지는 `excludeFromSemantics: true`

### 권장 패턴

```dart
// 버튼
Semantics(
  button: true,
  label: '이벤트 신청하기',
  child: ElevatedButton(...),
)

// 이미지
Image.network(
  url,
  semanticLabel: '파티 대표 이미지',
)

// 상태 표시
Semantics(
  label: '신청 상태: 승인 대기 중',
  child: StatusBadge(...),
)
```

### 공용 위젯 Semantics 현황

| 위젯 | Semantics 적용 | 비고 |
| :--- | :--- | :--- |
| `MinglitImage` | <!-- TODO: 확인 필요 --> | `minglit_kit` 공용 이미지 |
| `MinglitImageCarousel` | <!-- TODO: 확인 필요 --> | 이미지 캐러셀 |
| `MinglitChip` | <!-- TODO: 확인 필요 --> | 정보 칩 |
| `MinglitAlert` | <!-- TODO: 확인 필요 --> | 알림 팝업 |
| `MinglitDialog` | <!-- TODO: 확인 필요 --> | 다이얼로그 |
| `EventCard` | <!-- TODO: 확인 필요 --> | 이벤트 카드 |

---

## 4. 포커스 순서 (키보드/스위치 접근)

<!-- TODO: 포커스 순서 가이드 상세화 필요 -->

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

---

## 5. 텍스트 크기 조절

<!-- TODO: 텍스트 크기 조절 (Dynamic Type / Text Scaling) 대응 검증 필요 -->

### 기본 원칙

- `MediaQuery.textScaleFactor` 1.0~2.0 범위에서 레이아웃 깨지지 않아야 함
- `overflow: TextOverflow.ellipsis` 또는 `maxLines` 적용으로 오버플로우 방지
- 고정 높이 컨테이너 지양, `Flexible`/`Expanded` 활용

---

## 6. 체크리스트

| 항목 | 기준 | 상태 |
| :--- | :--- | :--- |
| 최소 터치 영역 48x48dp | WCAG 2.5.8 | 기본 컴포넌트 충족, 커스텀 위젯 확인 필요 |
| 색상 대비 (일반 텍스트) | WCAG AA 4.5:1 | textPrimary, textSecondary 충족 |
| 색상 대비 (대형 텍스트/UI) | WCAG AA 3:1 | primary, error 충족. success, warning 미충족 |
| Semantics 라벨 | 모든 인터랙티브 요소 | <!-- TODO: 전수 검사 필요 --> |
| 포커스 순서 | 시각적 순서와 일치 | <!-- TODO: 검증 필요 --> |
| 텍스트 크기 조절 | 1.0x ~ 2.0x 대응 | <!-- TODO: 검증 필요 --> |
| 다크 모드 | 전체 화면 대응 | <!-- TODO: golden test 확충 필요 --> |

---

## 관련 문서

- [01-foundation.md](01-foundation.md) -- 색상 토큰 (대비 비율 기준)
- [06-ux-writing.md](06-ux-writing.md) -- 스크린리더 텍스트 작성

---

*소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
