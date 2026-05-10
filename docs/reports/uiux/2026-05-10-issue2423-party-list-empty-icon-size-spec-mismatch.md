---
source_url: https://github.com/Mark-Yun/minglit/issues/2423
captured_at: 2026-05-11
issue_number: 2423
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] party_list_page _PartyListEmptyState — icon size 56 하드코딩 + spec 64 미일치 + Icons.celebration_outlined vs smile_outline"
---

# [audit-uiux/차이] party_list_page _PartyListEmptyState — icon size 56 하드코딩 + spec 64 미일치 + Icons.celebration_outlined vs smile_outline

> Issue #2423 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2423

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

`apps/app_partner/lib/src/features/party/list/party_list_page.dart:107-110`

```dart
Icon(
  Icons.celebration_outlined,   // ← spec: smile_outline
  size: 56,                      // ← spec: 64 (하드코딩 + spec 미일치)
  color: theme.colorScheme.outlineVariant,  // ← spec: --color-divider (= outlineVariant 매칭 OK)
),
```

## 현재 / 권장

| 항목 | 현재 코드 | spec |
|---|---|---|
| 아이콘 | `Icons.celebration_outlined` | `smile_outline` |
| 크기 | `56` (하드코딩) | **64×64** |
| 색 | `theme.colorScheme.outlineVariant` | `--color-divider` (= outlineVariant) ✅ |

### 권장

1. **size: 56 → 64** — spec과 정렬. 토큰화 (현재 `MinglitIconSize`에 64 토큰 없음 → `MinglitIconSize.xlarge * 2` 패턴이 다른 화면에서 사용 중. 단 #2422 결정 후 캐노니컬 / 토큰 변경 가능성 있음).
2. **icon: celebration_outlined → smile_outline 계열** — spec 의도(`smile_outline`)와 비교 시 `Icons.sentiment_satisfied_outlined` 또는 `Icons.mood_outlined`가 자연스러운 매칭. 다만 "파티" 컨텍스트에서 celebration이 더 적합하다는 판단이 가능 → spec 측 업데이트가 더 합리적일 수 있음 (Mark 판단).

## reference

- code: `apps/app_partner/lib/src/features/party/list/party_list_page.dart:107-110`
- spec: `apps/mds/docs/public/specs/party_list_page/index.html:902` ("smile_outline 64 · `--color-divider` 톤")
- 관련 이슈: #2422 (`MinglitEmptyState` fullPage 48 vs spec 64 conflict — 캐노니컬 결정 후 본 이슈 size 토큰 결정도 동시에 따라감)
- 캐노니컬: `shared/packages/mds/core/lib/src/ui/widgets/common/minglit_empty_state.dart` (현재는 fullPage 48 → 캐노니컬 채택 시 spec과도 어긋남 → rolled-own 유지 사유)

## 카테고리

[audit-uiux/차이] — 코드가 spec과 어긋남 (size 8px 차이 + icon 불일치 + 하드코딩 토큰 미사용). #2422 결정과 함께 처리하면 자연스럽게 캐노니컬 회귀 가능.
