# 이벤트 상세 — "상세 소개" 빈 상태 UX

Issue: [#1757](https://github.com/Mark-Yun/minglit/issues/1757)

## 1. 배경

유저 앱 이벤트 상세 페이지의 "상세 소개" 섹션(`_QuillViewer`)이 비어 있을 때
현재는 스타일 없는 평문 한 줄만 노출된다.

```dart
// 현재 (apps/app_user/lib/src/features/event/detail/event_quill_viewer.dart:10)
if (description.isEmpty) return const Text('상세 소개 정보가 없습니다.');
```

### 문제점

1. **톤 불일치** — 앱 전역의 빈 상태는 `MinglitEmptyState.card` / `.inline` 패턴을
   쓰는데(예: 티켓 선택, 파트너 인증 관리) 이 화면만 평문이다.
2. **시각적 무게 부재** — 섹션 타이틀도 없고 구분도 없어서 "버그로 인한 렌더 실패"
   처럼 보인다. 호스트가 의도적으로 소개를 생략한 경우에도 앱의 완성도가 낮아 보인다.
3. **문구가 건조하다** — "~없습니다" 는 선언형이라 거리감을 준다. 밍글릿의
   브랜드 보이스(부드럽고 대화적)와 맞지 않는다.

---

## 2. 개선 방향

### 2.1 컴포넌트 — `MinglitEmptyState.card`

이미 디자인 시스템에 존재하는 card variant을 그대로 사용한다.
(`shared/packages/minglit_kit/lib/src/ui/widgets/common/minglit_empty_state.dart`)

| Slot | 값 | 근거 |
|---|---|---|
| `icon` | `Icons.description_outlined` | 섹션 성격(본문/설명)과 중립적으로 일치 |
| `title` | **"아직 상세 소개가 없어요"** | 부드러운 진행형. 호스트를 탓하지 않음 |
| `subtitle` | **"궁금한 점은 호스트에게 문의해 보세요."** | 대안 액션 제시 — 유저가 다음에 할 일 |

### 2.2 카피 선정 근거

| 후보 | 채택 여부 | 이유 |
|---|---|---|
| ~~"상세 소개 정보가 없습니다."~~ | X (현재) | 건조, 에러 메시지처럼 보임 |
| ~~"상세 소개가 없습니다."~~ | X | 위와 동일 |
| **"아직 상세 소개가 없어요"** | ✅ | "아직"이 미래 가능성을 암시, "~어요" 가 대화적 |
| ~~"호스트가 소개를 준비하고 있어요"~~ | X | 사실 여부 단정 불가 — 준비 중인지 포기했는지 모름 |
| ~~"상세 소개 없이 준비된 이벤트예요"~~ | X | 호스트 태만을 정당화하는 톤 |

Subtitle은 **액션 제안**을 우선으로 한다. 유저가 "정보가 없네" 에서 끝나지 않고
"그럼 물어봐야지" 로 이어지게.

### 2.3 Placement

섹션 2의 기존 래핑을 그대로 유지한다 — `SliverToBoxAdapter` → `Padding`(좌우
`MinglitSpacing.screenEdge`, 상단 `MinglitSpacing.sectionGap`). `MinglitEmptyState.card`
는 내부에 `MinglitSpacing.xlarge`(32px) 패딩과 `surfaceContainerLowest` 배경,
`MinglitRadius.card` 라운드를 자체 제공하므로 추가 래핑 불필요.

```
┌──────────────────────────────────────┐ ← screenEdge 16px
│                                      │   sectionGap 40px above
│    ┌────────────────────────────┐   │
│    │                            │   │
│    │        📄 (32px)          │   │   ← MinglitEmptyState.card
│    │                            │   │     • surfaceContainerLowest bg
│    │   아직 상세 소개가 없어요    │   │     • 16px radius
│    │                            │   │     • xlarge(32px) padding
│    │  궁금한 점은 호스트에게     │   │
│    │      문의해 보세요.         │   │
│    │                            │   │
│    └────────────────────────────┘   │
│                                      │
└──────────────────────────────────────┘
```

---

## 3. 구현 가이드 (SWE용)

### 3.1 변경 파일

`apps/app_user/lib/src/features/event/detail/event_quill_viewer.dart`

### 3.2 Diff

```dart
// Before
if (description.isEmpty) return const Text('상세 소개 정보가 없습니다.');

// After — Fix #1757: 빈 상태 일관성 (MinglitEmptyState.card)
if (description.isEmpty) {
  return const MinglitEmptyState.card(
    icon: Icons.description_outlined,
    title: '아직 상세 소개가 없어요',
    subtitle: '궁금한 점은 호스트에게 문의해 보세요.',
  );
}
```

`MinglitEmptyState` 는 `minglit_kit` 의 public export 에 이미 포함되어 있으므로
import 한 줄 추가 또는 기존 import에 병합.

### 3.3 추가로 고려할 엣지 케이스 (선택)

Quill document 구조 특성상 `description` 이 `{"ops": [{"insert": "\n"}]}` 같이
"구조만 존재하고 실질 콘텐츠가 없는" 경우 `description.isEmpty` 는 false 지만
렌더링 결과는 사실상 빈 문자열이다.

이번 수정 범위는 **#1757 의 명시적 케이스(빈 map)** 에 한정하고, Quill 문서가
텍스트/이미지 delta 가 전무한 케이스는 별도 이슈로 다루는 것을 권장한다. 본
PR 에서 범위를 넓히면 Quill delta 검사 로직(`ops` 배열 내 실제 insert 존재 여부)이
더해져야 하므로 리뷰 복잡도가 증가한다.

### 3.4 테스트

회귀 방지 Widget 테스트를 `_QuillViewer` 에 대해 추가:

| 케이스 | 기대 |
|---|---|
| `description = {}` | `MinglitEmptyState` 가 렌더되고 아이콘 `description_outlined`, 타이틀 "아직 상세 소개가 없어요" 노출 |
| `description = {"ops": [{"insert": "hello\n"}]}` | `QuillEditor.basic` 렌더 (기존 동작 유지) |

---

## 4. 체크리스트

- [ ] `event_quill_viewer.dart` 의 `Text` 를 `MinglitEmptyState.card` 로 교체
- [ ] `Fix #1757:` 주석 추가 (프로젝트 규칙)
- [ ] 기존 Quill 렌더 케이스 회귀 없음 확인 (description 이 있을 때)
- [ ] Widget 테스트 2건 추가 (3.4)
- [ ] 라이트/다크 모드 골든 이미지 캡처 — 카드 배경/텍스트 대비 확인
- [ ] PR body 에 본 가이드 링크 인용 (`docs/features/event-detail-empty-state/ui-ux-design.md`)

---

## 5. 참조

- 원본 이슈: [#1757](https://github.com/Mark-Yun/minglit/issues/1757)
- 관련 위젯: `MinglitEmptyState` (`shared/packages/minglit_kit/lib/src/ui/widgets/common/minglit_empty_state.dart`)
- 유사 적용 사례:
  - `apps/app_user/lib/src/features/ticket/ui/ticket_selection_widgets.dart:175`
  - `apps/app_partner/lib/src/features/verification/manage/verification_manage_page.dart:122`
- 와이어프레임: [wireframe.html](./wireframe.html)
