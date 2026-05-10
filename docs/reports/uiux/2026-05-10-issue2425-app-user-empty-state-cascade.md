---
source_url: https://github.com/Mark-Yun/minglit/issues/2425
captured_at: 2026-05-11
issue_number: 2425
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] app_user 4개 화면 rolled-own empty state — #2422 cascade 확장 (search 2개 / my_page / auth_guard, 모두 size: 64 하드코딩)"
---

# [audit-uiux/차이] app_user 4개 화면 rolled-own empty state — #2422 cascade 확장 (search 2개 / my_page / auth_guard, 모두 size: 64 하드코딩)

> Issue #2425 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2425

Scheduler: needs-uiux-claude-1

## 발견 위치

`#2422` (`MinglitEmptyState.fullPage` icon size = 48 vs 다수 spec 64) cascade 가 **app_partner 외에 app_user 4개 화면에서도 동일하게 발생** 중. 기존 audit 는 app_partner 만 확인 (3개) → 캐스케이드 총 **7+ 화면** 으로 확장.

## 현재 / 권장

### app_user rolled-own 인스턴스 (4건)

| 파일 | 라인 | 아이콘 | 코드 크기 | spec 크기 | 일치? |
|---|---|---|---|---|---|
| `apps/app_user/lib/src/features/search/search_page.dart` | 90-94 | `Icons.search` | `size: 64` | search_page/index.html:107,391 — 64 | spec ✅ / 캐노니컬 ❌ |
| `apps/app_user/lib/src/features/search/search_page.dart` | 150-154 | `Icons.search_off_outlined` | `size: 64` | search_page/index.html:402 — 64 | spec ✅ / 캐노니컬 ❌ |
| `apps/app_user/lib/src/features/home/my_page.dart` | 28-32 | `Icons.person_outline` | `size: 64` | my_page/index.html:551,574 — 64 | spec ✅ / 캐노니컬 ❌ |
| `apps/app_user/lib/src/features/auth/ui/auth_guard.dart` | 31-35 | `Icons.lock_outline` | `size: 64` | (공용 guard widget — 개별 spec 없음, 동일 톤 패턴) | 캐노니컬 ❌ |

전부 raw `Column` + `Icon(... size: 64 ...)` + `Text(titleMedium)` + `Text(bodyMedium)` + 옵셔널 CTA 의 **동일 구조** — `MinglitEmptyState.fullPage` 캐노니컬 위젯의 거의 완전한 복제. 캐노니컬을 호출하지 않은 사유는 단 하나 — 캐노니컬이 size 48 을 강제하므로 spec 64 를 만족할 수 없음 (#2422).

### 추가 드리프트 (참고)

| 파일 | 라인 | 코드 크기 | spec 크기 | 비고 |
|---|---|---|---|---|
| `apps/app_user/lib/src/features/tickets/my_tickets_page.dart` | 31 | `MinglitIconSize.display` (=48) | my_tickets_page/index.html:380 — 64 | 캐노니컬 토큰 사용했으나 spec 미달 — #2422 캐노니컬 정렬되면 자동 해소 |

(`apps/app_user/lib/src/features/my_tickets/ui/my_tickets_page.dart` 는 `MinglitEmptyState` 사용 — canonical compliant 이나 동일 size 48 vs spec 64 격차 보유)

### 권장

**본 발견은 #2422 의 결정에 종속.**

- **#2422 옵션 A 채택 시** (캐노니컬 → 64) — 본 4개 + #2422 의 3개 + 캐노니컬 사용 my_tickets = **8개 화면이 자동 정렬**. 추가 대규모 변경 불필요.
- **#2422 옵션 B 채택 시** (캐노니컬 48 유지, spec → 48) — 본 4개 화면도 코드 size 64 → 48 변경 + 캐노니컬 회귀 작업 추가. 변경 표면 가장 큼.
- **#2422 옵션 C 채택 시** (`heroFullPage` 신설) — 본 4개 화면 모두 신 variant 적용 가이드라인 필요.

**옵션 A 가 가장 효율적** — cascade 가 4 → 7 → 8개 화면으로 확장되며 다수 spec(이제 7+개 spec)이 64 를 명시하는 만큼, 캐노니컬을 64 로 정렬하면 자연스러운 회귀 경로 확보.

## reference

- root cause issue: #2422
- 형제 cascade: #2423 (party_list_page, app_partner)
- canonical: `shared/packages/mds/core/lib/src/ui/widgets/common/minglit_empty_state.dart:103-105`
- specs (모두 64 명시):
  - `apps/mds/docs/public/specs/search_page/index.html:107,391,402`
  - `apps/mds/docs/public/specs/my_page/index.html:551,574`
  - `apps/mds/docs/public/specs/my_tickets_page/index.html:380`
- M3/iOS HIG: 풀-페이지 hero icon 56-64dp 권장 — frontier 톤 정렬

## 카테고리

[audit-uiux/차이] — 코드 ↔ 캐노니컬 위젯 우회 패턴 (4개 추가). #2422 결정과 묶어 처리하면 본 이슈 자동 해소.
