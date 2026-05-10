---
source_url: https://github.com/Mark-Yun/minglit/issues/2413
captured_at: 2026-05-10
issue_number: 2413
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] notification_list_screen Error state — inline override (raw err toString) vs canonical MinglitAsyncValueWidget _DefaultErrorView"
---

# [audit-uiux/차이] notification_list_screen Error state — inline override (raw err toString) vs canonical MinglitAsyncValueWidget _DefaultErrorView

> Issue #2413 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2413

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

- code: `shared/packages/minglit_kit/lib/src/features/notification/notification_list_screen.dart:137`
  ```dart
  error: (err, stack) => Center(child: Text('에러: $err')),
  ```
- spec (acknowledged drift): `apps/mds/docs/public/specs/notification_list_screen/index.md`
  - line 131: 후속 작업에서 표준 오류 화면(\"오류가 발생했습니다.\" + 다시 시도)으로 통일 권장
  - line 132: 컴포넌트: `↔ list 전체 → Center + Text('에러: $err') (inline override). Default error UI 미적용.`
  - line 134: 노트: 원본 오류 메시지가 그대로 노출되므로 민감 정보가 보일 위험이 있음

## 현재 / 권장

### 현재 (drift)

`NotificationListScreen` 은 `MinglitAsyncValueWidget` 의 `error` 콜백을 inline override 해서 raw `err.toString()` 을 그대로 노출:

```dart
MinglitAsyncValueWidget(
  value: notificationState,
  data: (notifications) { ... },
  error: (err, stack) => Center(child: Text('에러: $err')),  // ← override
)
```

결과:
- 본문 영역 가운데에 `에러: <raw err toString>` 평문 노출 — 아이콘 없음, MDS 토큰 미적용 (bodyMedium default).
- `err` 가 Supabase / network exception 이면 stack-ish 메시지나 내부 식별자가 보일 수 있음 — 사용자 친화도 낮고 약한 정보 누출 가능성.

### 캐노니컬 패턴 (sibling 참조)

`MinglitAsyncValueWidget` 는 `error` 미지정 시 자동으로 `_DefaultErrorView` 를 그림:

```
Icon(Icons.error_outline · xlarge · color: error)
SizedBox(spacing-medium)
Text('오류가 발생했습니다.', titleMedium · bold)
// showErrorDetails=false 가 default → raw err 노출 안 됨
```

같은 kit-shared 알림 패밀리의 sibling **`NotificationSettingsScreen`** 은 이미 default 사용 (override 없음, line 20-22):

```dart
MinglitAsyncValueWidget(
  value: settingsAsync,
  data: (settings) { ... },
)  // ← error 생략 → _DefaultErrorView 자동 적용
```

→ 두 kit-shared 알림 화면이 같은 wrapper 를 다르게 쓰고 있음 = 인터널 컨플릭.

### 권장 수정

`error:` 콜백을 제거. spec 의 컴포넌트 row / 노트도 동기화 (별도 spec PR — Mark 영역).

```diff
 MinglitAsyncValueWidget(
   value: notificationState,
   data: (notifications) { ... },
-  error: (err, stack) => Center(child: Text('에러: $err')),
 )
```

부수 효과:
- Error state 가 자동으로 `_DefaultErrorView` 로 전환 → spec 의 `notification_settings_screen` Error state 와 동일한 시각.
- raw err 노출 제거 → 운영 환경 UX/보안 안정.
- 코드 -1줄 (override 삭제만으로 충분).

## reference

- canonical 사례: `shared/packages/minglit_kit/lib/src/features/notification/notification_settings_screen.dart` (line 20-22) — same wrapper, default error 사용.
- kit wrapper: `shared/packages/mds/core/lib/src/ui/widgets/common/minglit_async_value_widget.dart:38-51` — `error ?? (err, stack) => _DefaultErrorView(...)`.
- `_DefaultErrorView` 구현: 같은 파일 line 54-101 (showErrorDetails default false → raw err 가려짐).
- spec: `apps/mds/docs/public/specs/notification_list_screen/index.md` Error state section (line 122-134) — drift 를 명시적으로 인지하고 통일 권장.

## 노트

- 같은 kit-shared 패밀리(`notification_*`) 의 시각/패턴 통일 — design system 일관성 ROI 가 명확.
- spec 변경 (Error state 컴포넌트 row 갱신) 은 Mark 영역. 본 이슈는 코드 fix (override 제거) + spec 동기화 후속 트리거 두 단계로 해결.
- `notification_list_screen` 에 별도 추가 발견(Empty state 가 plain `Text` — `MinglitEmptyState` atom 미사용, spec line 106-108) 도 있지만 1 issue = 1 finding 정책에 따라 분리 검토 권장 (별도 이슈로 파일링 가능).

— needs-uiux-claude-1
