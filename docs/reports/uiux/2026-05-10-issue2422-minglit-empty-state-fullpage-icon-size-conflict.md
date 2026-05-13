---
source_url: https://github.com/Mark-Yun/minglit/issues/2422
captured_at: 2026-05-11
issue_number: 2422
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/개선] MinglitEmptyState fullPage variant 아이콘 size 48 vs 3개 spec 64 충돌 — 캐노니컬 합리화 결정 필요"
---

# [audit-uiux/개선] MinglitEmptyState fullPage variant 아이콘 size 48 vs 3개 spec 64 충돌 — 캐노니컬 합리화 결정 필요

> Issue #2422 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2422

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

`shared/packages/mds/core/lib/src/ui/widgets/common/minglit_empty_state.dart:103-105` — `MinglitEmptyState.fullPage` variant icon size = `MinglitIconSize.display` (48px).

이 토큰 선택과 3개 화면 spec(`party_list_page` / `checkin_placeholder_page` / `event_application_manage_page`)이 명시한 **64×64** 사이에 충돌이 있어, 해당 화면들이 캐노니컬 위젯을 우회하고 raw `Column`으로 rolled-own empty state를 구현하고 있다.

## 현재 / 권장

### 현재 — 캐노니컬과 spec 불일치

| Spec | Empty 아이콘 크기 | 캐노니컬 매칭? |
|---|---|---|
| `party_list_page` line 902 | smile_outline · **64×64** · `--color-divider` | ❌ |
| `checkin_placeholder_page` line 332 | qr_code_scanner · **xlarge\*2 ≈ 64** | ❌ |
| `event_application_manage_page` line 217 | 서류 outline · **width 64 height 64** opacity 0.5 | ❌ |
| `event_matching_screen` line 239 | (people/lock outline) · **48×48** | ✅ matches `MinglitIconSize.display` |

다수(3 of 4) full-page empty state spec이 **64px**를 명시 — 캐노니컬 fullPage variant(48px)와 불일치.

### 캐스케이드 — 코드가 캐노니컬을 우회

3개 화면이 `MinglitEmptyState`를 사용하지 않고 raw `Column`으로 직접 구현 (size 64 충족 위해):

| 파일 | 라인 | 우회 사유 |
|---|---|---|
| `apps/app_partner/lib/src/features/checkin/checkin_placeholder_page.dart` | 122-138 | icon size `MinglitIconSize.xlarge * 2` (64) — 캐노니컬은 48 |
| `apps/app_partner/lib/src/features/application/event_application_manage_tab.dart` | 46-65 | 동일 — `MinglitIconSize.xlarge * 2` |
| `apps/app_partner/lib/src/features/party/list/party_list_page.dart` | 107-110 | 하드코딩 `size: 56` — 캐노니컬도 spec(64)도 둘 다 위반 |

캐노니컬 위젯이 spec과 일치하지 않으니 SWE가 raw Column을 쓰는 게 자연스러운 분기 → 캐노니컬 합리화 / 일관성 확보 필요.

### 권장 — 결정 옵션

**옵션 A (권장)** — 캐노니컬을 64로 변경:
```dart
// minglit_empty_state.dart
size: variant == MinglitEmptyStateVariant.card
    ? MinglitIconSize.xlarge          // 32 (그대로)
    : MinglitIconSize.xlarge * 2,     // 48 → 64
```
- 장점: 다수 spec(3/4)에 캐노니컬 정렬 / rolled-own 3개 화면 캐노니컬 회귀 가능 / 풀-페이지 hero 시그널 강화
- 단점: `event_matching_screen` spec 1건은 48 → 64로 spec 업데이트 필요

**옵션 B** — 캐노니컬 48 유지, 3개 spec 48로 업데이트:
- 장점: 변경 표면 작음 (캐노니컬 위젯 무변)
- 단점: 풀-페이지 hero icon이 시각적으로 약함 / 3개 spec 동시 변경 / event_application_manage spec line 903 "큰 아이콘 (서류 outline 형 · 64 · 보조 색)" 처럼 64라는 점이 시그널로 강조된 사례 → 의도 손상

**옵션 C** — 새 variant `heroFullPage` (64) 신설, 기존 `fullPage` (48) 유지:
- 장점: 두 톤 모두 보존 / 화면별 선택 가능
- 단점: variant 종류 4개로 증가 / 어떤 화면이 어떤 variant 써야 하는지 가이드라인 추가 필요

## reference

- canonical: `shared/packages/mds/core/lib/src/ui/widgets/common/minglit_empty_state.dart:103-105`
- token: `shared/packages/mds/core/lib/src/theme/minglit_design_tokens.dart:238-246` (`xlarge`=32 / `display`=48 — 64에 해당하는 토큰 없음 → `xlarge*2` 곱셈 패턴)
- specs:
  - `apps/mds/docs/public/specs/party_list_page/index.html:902` — empty state 64×64
  - `apps/mds/docs/public/specs/checkin_placeholder_page/index.html:332` — `xlarge*2 ≈ 64`
  - `apps/mds/docs/public/specs/event_application_manage_page/index.html:217` — width/height 64
  - `apps/mds/docs/public/specs/event_matching_screen/index.html:239` — 48×48 (옵션 A 채택 시 spec 업데이트 대상)
- M3/iOS HIG 비교: full-page empty state hero icon은 일반적으로 56–64dp (Material 3 Empty State guidance / iOS HIG NoContent placeholder). 48dp는 inline / list-empty 컨텍스트가 적합. 다수 spec이 64를 채택한 것이 frontier 톤에 더 가까움.

## 카테고리

[audit-uiux/개선] — 디자인 시스템 내부 충돌 (캐노니컬 위젯 ↔ 다수 spec). spec 직접 수정 / 위젯 직접 수정 모두 진행하지 않고 Mark 결정 대기.
