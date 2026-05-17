# minglit_kit/ui — Design System 상세

화면·컴포넌트 spec 의 시각 SSOT 는 [`apps/mds/docs/`](../../../../../../apps/mds/docs/). 본 폴더는 그 spec 의 Flutter 구현.

## SSOT 위치

| 아티팩트 | 위치 | 용도 |
|---|---|---|
| 화면 spec | `apps/mds/docs/public/specs/{screen}.html` | 레이아웃·상태·동작 명세 (68 개 화면) |
| 컴포넌트 카탈로그 | `apps/mds/docs/src/lib/components.ts` | 컴포넌트 manifest SSOT |
| 컴포넌트 spec | `apps/mds/docs/src/components/specs/*Spec.tsx` | 시각 playground (~14k LOC) |

UI 변경 PR 본문에 spec 파일 경로·섹션을 **반드시 인용** (CLAUDE.md "UI 변경 게이트"). Spec 자체는 Mark(디자인 시스템 오너)만 수정.

## Design Tokens

`minglit_design_tokens.dart` 의 `MinglitColors`·spacing·typography. 모노레포 SSOT 는 [`shared/packages/mds/tokens/`](../../../../mds/tokens/) (Style Dictionary → Dart 상수 코드젠).

## Theme System

| 파일 | 역할 |
|---|---|
| `minglit_theme.dart` | Material theme |
| `minglit_component_theme.dart` | 컴포넌트 테마 |
| `minglit_quill_theme.dart` | 리치 텍스트 |
| `theme_controller.dart` | Riverpod 기반 (라이트·다크·시스템), `SharedPreferences` 영속화 |

## Feedback

`feedback_ext.dart` + `feedback_components.dart`:

```dart
showMinglitSuccess('저장 완료');
showMinglitWarning('네트워크 느림');
showMinglitAlert('서버 오류');
showMinglitConfirm('정말 삭제할까요?');
```

## Global Loading Overlay

`global_loading_controller.dart` + `minglit_global_loading_overlay.dart` — 앱 전역 로딩 표시. Feature 안에서 직접 `CircularProgressIndicator` 띄우지 않고, controller 호출로 일관성 유지.

## Common Widgets (`widgets/`)

`minglit_skeleton`, `minglit_image`, `minglit_image_carousel`, `minglit_file_picker`, `minglit_dialog`, `event_card`, `location_map_view`, `minglit_participant_gauge` 등. 각 위젯은 `apps/mds/docs/` 의 spec 에 대응되는 구현.

## 관련

- [BLUEDOC](./BLUEDOC.md)
- [minglit_kit/architecture.md](../../architecture.md) — 5 계층 개요
- [`apps/mds/docs/`](../../../../../../apps/mds/docs/) — 시각 spec 카탈로그
- [`shared/packages/mds/`](../../../../mds/) — Design System 모노레포 패키지
