# 05. Motion — 모션 가이드

밍릿 앱의 애니메이션과 전환 규칙입니다.

> **토스 원칙 참고**: 자연스러운 인터랙션을 위해 의미 있는 모션만 사용합니다. 장식 목적의 모션은 지양합니다.
> (출처: 토스 디자인 시스템 TDS — 모션 원칙)

---

## 1. Duration — `MinglitAnimation`

**소스**: `shared/packages/minglit_kit/lib/src/theme/minglit_design_tokens.dart:125-134`

| 토큰명 | 값 (ms) | 용도 | 라인 |
| :--- | :--- | :--- | :--- |
| `fast` | 200 | 간단한 상태 변화 (선택, 토글, 호버) | :127 |
| `medium` | 350 | 화면 전환, 모달/시트 등장/퇴장 | :130 |
| `slow` | 500 | 복잡한 레이아웃 변화, 확장/축소 | :133 |

### 사용 가이드

| 인터랙션 | 권장 Duration |
| :--- | :--- |
| 버튼 상태 변화 (pressed, disabled) | `fast` (200ms) |
| 체크박스/토글 전환 | `fast` (200ms) |
| 카드 선택 애니메이션 | `fast` (200ms) |
| 페이지 전환 (push/pop) | `medium` (350ms) |
| BottomSheet 등장/퇴장 | `medium` (350ms) |
| Dialog 등장/퇴장 | `fast` (200ms) |
| 리스트 아이템 등장 (staggered) | `medium` (350ms) |
| 레이아웃 재배치 | `slow` (500ms) |
| 스켈레톤 shimmer | `slow` (500ms) |

---

## 2. Curve

<!-- TODO: 표준 Curve 토큰 클래스 정의 필요. 현재 코드에 MinglitCurve 클래스 없음. -->

### 권장 Curve (Material 3 기반)

| 용도 | Curve | 설명 |
| :--- | :--- | :--- |
| 일반 전환 | `Curves.easeInOut` | 시작과 끝에서 감속 |
| 등장 애니메이션 | `Curves.easeOut` | 끝에서 감속 (자연스러운 진입) |
| 퇴장 애니메이션 | `Curves.easeIn` | 시작에서 가속 (빠른 퇴장) |
| 바운스 효과 | `Curves.elasticOut` | 탄성 효과 (최소한으로 사용) |
| BottomSheet | `Curves.easeOutCubic` | 부드러운 슬라이드 |

---

## 3. Transition 패턴

### Page Transition

| 전환 유형 | 애니메이션 | Duration | Curve |
| :--- | :--- | :--- | :--- |
| Forward (push) | Slide from right | `medium` (350ms) | `easeInOut` |
| Backward (pop) | Slide to right | `medium` (350ms) | `easeInOut` |
| Modal (BottomSheet) | Slide from bottom | `medium` (350ms) | `easeOutCubic` |
| Dialog | Fade + Scale | `fast` (200ms) | `easeOut` |

<!-- TODO: GoRouter 커스텀 CustomTransitionPage 적용 필요 -->

### 상태 변화 Transition

| 상태 변화 | 애니메이션 | Duration |
| :--- | :--- | :--- |
| 카드 선택/해제 | 배경색 + 테두리 + 그림자 fade | `fast` (200ms) |
| 로딩 → 콘텐츠 | Fade in | `medium` (350ms) |
| 에러 → 재시도 → 로딩 | Fade crossfade | `fast` (200ms) |
| 리스트 아이템 추가/제거 | `AnimatedList` slide + fade | `medium` (350ms) |

### 카드 선택 애니메이션 (코드 기반)

**소스**: `minglit_design_utils.dart:25-42` (`MinglitDecorations.selectableCard`)

선택 시 변화:
- 배경: `theme.cardColor` → `accentColor` 5% alpha
- 테두리: `outlineVariant` → `secondary`
- 그림자: 없음 → blurRadius 8, offset (0,4), accentColor 10% alpha

---

## 4. 모션 원칙

> 토스 디자인 시스템(TDS)의 모션 원칙을 참고합니다 (코드/에셋 복사 아님, 원칙만 참고).

1. **의미 있는 모션**: 사용자의 행동에 대한 피드백으로만 모션을 사용합니다
2. **일관된 타이밍**: 동일 유형의 인터랙션에는 동일한 duration을 적용합니다
3. **자연스러운 가감속**: 선형 애니메이션 대신 ease curve를 사용합니다
4. **과도하지 않게**: 복잡한 모션이나 긴 애니메이션은 사용성을 해칩니다

---

## 관련 문서

- [01-foundation.md](01-foundation.md) -- `MinglitAnimation` duration 토큰
- [04-navigation.md](04-navigation.md) -- 페이지 전환

---

*소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
