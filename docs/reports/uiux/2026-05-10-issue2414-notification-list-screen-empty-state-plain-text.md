---
source_url: https://github.com/Mark-Yun/minglit/issues/2414
captured_at: 2026-05-10
issue_number: 2414
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] notification_list_screen Empty state — plain Text vs canonical MinglitEmptyState atom"
---

# [audit-uiux/차이] notification_list_screen Empty state — plain Text vs canonical MinglitEmptyState atom

> Issue #2414 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2414

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

- code: `shared/packages/minglit_kit/lib/src/features/notification/notification_list_screen.dart:40-41`
  ```dart
  if (notifications.isEmpty) {
    return const Center(child: Text('알림이 없습니다.'));
  }
  ```
- spec (acknowledged drift): `apps/mds/docs/public/specs/notification_list_screen/index.md`
  - line 106: 컴포넌트 — `↔ ListView / RefreshIndicator → Center(child: Text('알림이 없습니다.')) 단일 — 전용 EmptyState atom 미사용 (plain Text)`
  - line 108: 노트 — `다른 화면들의 표준 Empty 비주얼(아이콘 + 안내 + CTA) 대비 매우 빈약한 안내. 후속 작업에서 보강 검토 가치.`

## 현재 / 권장

### 현재 (drift)

`MinglitEmptyState` atom 미사용 — 본문 가운데에 `Text('알림이 없습니다.')` 한 줄만 노출. 아이콘 / 부제 / CTA 모두 없음. MDS 토큰 미적용 (bodyMedium default).

### 캐노니컬 패턴

`MinglitEmptyState` (`shared/packages/mds/core/lib/src/ui/widgets/common/minglit_empty_state.dart`) — 디자인 시스템 표준 빈-상태 atom. `fullPage` variant 가 본 화면의 size 에 적합:

```dart
const MinglitEmptyState(
  title: '아직 도착한 알림이 없어요',
  subtitle: '서비스 알림이 도착하면 여기에서 확인할 수 있어요.',
  icon: Icons.notifications_none_outlined,
  // CTA 없음 — push 알림은 외부 트리거 기반이라 in-screen action 없음.
)
```

`fullPage` variant 가 그리는 형태:
- 48px outline-color icon
- title (titleMedium · bold)
- subtitle (bodyMedium · onSurfaceVariant)
- 옵셔널 CTA — 본 화면은 미사용

### 인접 사례 (이미 atom 채택)

같은 디자인 시스템에서 다른 list/grid 화면들은 모두 `MinglitEmptyState` 사용:

| 화면 | 사용 위치 |
|---|---|
| `my_tickets_page.dart` | 탭별 fullPage variant |
| `event_matching_screen.dart` | fullPage |
| `home_page.dart` | fullPage |
| `_settlement_list_tab.dart` (partner) | fullPage |
| `party_entry_group_management_screen.dart` (partner) | fullPage |

→ 알림 list 만 plain Text 라 시각 인터널 컨플릭.

### 권장 수정

```diff
 if (notifications.isEmpty) {
-  return const Center(child: Text('알림이 없습니다.'));
+  return const MinglitEmptyState(
+    title: '아직 도착한 알림이 없어요',
+    subtitle: '서비스 알림이 도착하면 여기에서 확인할 수 있어요.',
+    icon: Icons.notifications_none_outlined,
+  );
 }
```

부수 효과:
- 다른 list/grid 화면들과 시각/톤 통일.
- spec line 108 의 \"보강 검토 가치\" 권장 적용.
- spec Empty state 컴포넌트 row + \"전용 EmptyState atom 미사용\" 노트 동기화 (별도 spec PR — Mark 영역).

## reference

- canonical atom: `shared/packages/mds/core/lib/src/ui/widgets/common/minglit_empty_state.dart` (fullPage / card / inline 3 variant)
- 인접 채택 사례: `apps/app_user/lib/src/features/my_tickets/ui/my_tickets_page.dart`, `apps/app_user/lib/src/features/event/matching/ui/event_matching_screen.dart`, `apps/app_user/lib/src/features/home/home_page.dart`
- spec: `apps/mds/docs/public/specs/notification_list_screen/index.md` Empty state section (line 97-108)
- 디자인 시스템 카탈로그: `apps/mds/docs/src/lib/components.ts` (MinglitEmptyState 항목)
- 패턴 가이드: `docs/ux/design-system/03-patterns.md`

## 노트

- 관련 발견 #2413 (notification_list_screen Error state 도 동일 패턴의 인터널 컨플릭) 과 한 PR 로 묶어 처리 가능 — 같은 파일 / 같은 도메인 / 같은 design system 정합 의도.
- spec 동기화는 Mark 영역.

— needs-uiux-claude-1
