---
source_url: https://github.com/Mark-Yun/minglit/issues/2408
captured_at: 2026-05-10
issue_number: 2408
state: open
labels: [bug]
author: Mark-Yun
title: "[audit-uiux/차이] search_page Error state — Text 위젯 명시 style 없음 (spec: bodyMedium · onSurfaceVariant · padding-xlarge)"
---

# [audit-uiux/차이] search_page Error state — Text 위젯 명시 style 없음 (spec: bodyMedium · onSurfaceVariant · padding-xlarge)

> Issue #2408 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2408

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

`apps/app_user/lib/src/features/search/search_page.dart:203-205`

```dart
error: (e, _) => const Center(
  child: Text('검색 중 오류가 발생했습니다'),
),
```

## 현재 / 권장

- **현재**: 명시적 `style` 없는 `Text` + `Center` (Padding 없음)
  - 색상은 가까운 `DefaultTextStyle` / Theme의 `bodyMedium`을 따라가지만, 통상 `onSurface`(본문 진한 색)에 가깝다.
  - 좌우 여백이 없어 긴 메시지가 viewport edge에 닿을 가능성.
- **권장**: spec의 `.search-error` 정의와 동일하게 명시
  ```dart
  error: (e, _) => Center(
    child: Padding(
      padding: const EdgeInsets.all(MinglitSpacing.xlarge),
      child: Text(
        '검색 중 오류가 발생했습니다',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  ),
  ```

## reference

- spec: `apps/mds/docs/public/specs/search_page/index.html#states` State 6 (Error)
  - spec CSS `.search-error` (line 206-213):
    ```css
    padding: var(--spacing-xlarge);
    font-size: 16px;
    color: var(--color-text-secondary);
    text-align: center;
    ```
  - spec mini-table 토큰 row (line 812):
    > 메시지는 기본 Text 스타일 — bodyMedium · onSurfaceVariant
- 비교: 같은 spec의 Empty/NoResult state는 코드에서 명시적으로 `Theme.textTheme.bodyMedium?.copyWith(color: onSurfaceVariant)` + `Padding(EdgeInsets.all(MinglitSpacing.xlarge))`를 사용 중 (line 84, 167-176). Error state만 누락.

## 영향도

P3 — 사용자가 자주 보는 화면은 아니지만 (네트워크 오류 시에만 노출), 같은 화면의 다른 빈 상태와 visual treatment가 어긋난다. 디자인 시스템 일관성 / 토큰 사용 관점의 작은 drift.
