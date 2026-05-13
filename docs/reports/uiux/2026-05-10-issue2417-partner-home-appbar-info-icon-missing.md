---
source_url: https://github.com/Mark-Yun/minglit/issues/2417
captured_at: 2026-05-10
issue_number: 2417
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] partner_home_page — AppBar info_outline icon 누락 (PR #2380 spec sync 후 코드 미반영)"
---

# [audit-uiux/차이] partner_home_page — AppBar info_outline icon 누락 (PR #2380 spec sync 후 코드 미반영)

> Issue #2417 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2417

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

- code: `apps/app_partner/lib/src/features/home/partner_home_page.dart:38-82` (AppBar `actions` 배열)
- spec: `apps/mds/docs/public/specs/partner_home_page/index.html`
  - Layout tree: line 1057 — `IconButton(info_outline) → showMinglitHelpSheet(...)`
  - AppBar sub-anatomy: line 1122 — `② Info action (1st trailing) · info_outline 22×22 · 탭 시 도움말 bottom sheet 진입 (State 8). 파트너 앱 모든 화면에 동일 패턴 적용.`
- canonical 구현 reference: `apps/app_partner/lib/src/features/party/list/party_list_page.dart:8-55` (Fix #2200, PR #2243)

## 현재 / 권장

### 현재 (drift)

PR #2380 (commit `e1cc82a55`)이 3개 spec 에 `AppBar info_outline → showMinglitHelpSheet` 패턴을 동기화했지만, **partner_home_page 코드에는 info_outline icon 자체가 없음**. spec 은 "info → bug → 알림" 순서(line 1057)를 명시하지만 코드는 "bug → 알림"만 존재.

```dart
// partner_home_page.dart:44-81 — 현재
actions: [
  const BugReportAction(),                     // ① spec 기준 ③번 위치
  Stack(...IconButton(notifications_outlined)) // ② spec 기준 ④번 위치
  // info_outline 누락
],
```

PR #2380 본문은 *"코드는 PR #2243에서 결정·배포됨. Mark 지시로 spec 단순 sync."*라고 명시했지만, PR #2243은 `party_list_page` 1개 화면만 구현했고 partner_home_page 등 나머지 3개 화면은 미구현 상태였다 → spec ↔ code drift.

### 권장 (Mark 결정 시 swe 라우팅)

canonical 패턴(party_list_page) 그대로 첫 trailing action 으로 info_outline 추가:

```dart
const _kPartnerHomeHelpSections = [
  HelpSection(
    title: '...',
    body: '...',
  ),
  // PR #2380 본문: "도움말 콘텐츠(Q&A sections)는 화면별 정의 미완 — placeholder로 표시. 추후 별도 이슈로 확정."
  // → 콘텐츠는 Mark 가 별도 정의 후 채움
];

actions: [
  IconButton(
    icon: const Icon(Icons.info_outline),
    iconSize: 22,
    tooltip: '도움말',
    onPressed: () => showMinglitHelpSheet(
      context: context,
      title: '파트너 홈 가이드',
      sections: _kPartnerHomeHelpSections,
    ),
  ),
  const BugReportAction(),
  Stack(...notifications_outlined...),
],
```

## 영향

- spec State 8 "도움말 bottom sheet" 가 spec 에만 존재 + 코드에서는 진입점 부재 → 파트너가 앱에서 컨텍스트 도움말에 접근 불가.
- spec 은 "파트너 앱 모든 화면에 동일 패턴 적용" 을 명시하지만 실제로는 party_list_page 1개 화면만 적용. 패턴 일관성 위반.
- audit / spec walk 가 이 화면을 "spec 동기화됨" 으로 잘못 판정할 위험.

## reference

- canonical 구현: `apps/app_partner/lib/src/features/party/list/party_list_page.dart:8-55` (Fix #2200 — `_kPartyHelpSections` const list + IconButton(info_outline) + showMinglitHelpSheet)
- helper 위치: `shared/packages/mds/core/lib/src/ui/widgets/common/minglit_help_sheet.dart:42-63` (`showMinglitHelpSheet` + `HelpSection` 구조체 — minglit_kit re-export)
- spec sync PR: #2380 (commit e1cc82a55, closes #2261/#2265, also-closes #2268-2271)
- 자매 issue: partner_home_page 외 같은 root cause 로 settlement_page / event_application_manage_page 도 별도 파일링 예정.

## 카테고리

`[audit-uiux/차이]` — 코드 ↔ 단일 진실(spec) drift. spec 만 sync 되고 코드 미반영. tpm 이 트리아지로 `needs-swe` 부여 (코드 픽스 영역 — Help sheet sections 콘텐츠 결정은 Mark, IconButton 추가 + showMinglitHelpSheet 호출 wiring 은 swe).

— needs-uiux-claude-1
