---
source_url: https://github.com/Mark-Yun/minglit/issues/2418
captured_at: 2026-05-10
issue_number: 2418
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] settlement_page — AppBar info_outline icon 누락 (PR #2380 spec sync 후 코드 미반영)"
---

# [audit-uiux/차이] settlement_page — AppBar info_outline icon 누락 (PR #2380 spec sync 후 코드 미반영)

> Issue #2418 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2418

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

- code: `apps/app_partner/lib/src/features/settlement/settlement_page.dart:51-72` (AppBar `actions` 배열)
- spec: `apps/mds/docs/public/specs/settlement_page/index.html`
  - Layout tree: line 500 — `IconButton(info_outline) → showMinglitHelpSheet(...)` (info → wallet 순서)
  - AppBar sub-anatomy: line 567 — `② Info action (1st trailing) · info_outline 22×22 · 탭 시 도움말 bottom sheet 진입 (State 7). 파트너 앱 모든 화면에 동일 패턴 적용.`
- canonical 구현 reference: `apps/app_partner/lib/src/features/party/list/party_list_page.dart:8-55` (Fix #2200, PR #2243)

## 현재 / 권장

### 현재 (drift)

PR #2380 (commit `e1cc82a55`)이 spec 에 "info → wallet" actions 순서를 동기화했지만, **settlement_page 코드에는 info_outline icon 자체가 없음**. wallet icon (계좌 관리) 만 존재 (그것도 SETTLEMENT_EDIT permission gated — Fix #1568).

```dart
// settlement_page.dart:52-64 — 현재
appBar: AppBar(
  title: const Text('정산'),
  actions: [
    if (canEditSettlement)
      IconButton(
        icon: const Icon(Icons.account_balance_wallet_outlined),
        tooltip: '계좌 관리',
        ...
      ),
    // info_outline 누락
  ],
  bottom: TabBar(...),
),
```

PR #2380 본문은 *"코드는 PR #2243에서 결정·배포됨. Mark 지시로 spec 단순 sync."*라고 명시했지만, PR #2243은 `party_list_page` 1개 화면만 구현했고 settlement_page 등 나머지 3개 화면은 미구현 상태였다 → spec ↔ code drift.

### 권장 (Mark 결정 시 swe 라우팅)

canonical 패턴(party_list_page) 그대로 첫 trailing action 으로 info_outline 추가 (permission 게이트 무관 — 도움말은 모든 멤버에게 노출):

```dart
const _kSettlementHelpSections = [
  HelpSection(
    title: '...',
    body: '...',
  ),
  // PR #2380 본문: "도움말 콘텐츠(Q&A sections)는 화면별 정의 미완 — placeholder로 표시. 추후 별도 이슈로 확정."
  // → 콘텐츠는 Mark 가 별도 정의 후 채움
];

appBar: AppBar(
  title: const Text('정산'),
  actions: [
    IconButton(
      icon: const Icon(Icons.info_outline),
      iconSize: 22,
      tooltip: '도움말',
      onPressed: () => showMinglitHelpSheet(
        context: context,
        title: '정산 가이드',
        sections: _kSettlementHelpSections,
      ),
    ),
    if (canEditSettlement)
      IconButton(
        key: const Key('bankAccountButton'),
        icon: const Icon(Icons.account_balance_wallet_outlined),
        tooltip: '계좌 관리',
        ...
      ),
  ],
  bottom: TabBar(...),
),
```

## 영향

- spec State 7 "도움말 bottom sheet" 가 spec 에만 존재 + 코드에서는 진입점 부재 → 파트너가 정산 정책(수수료/지급주기/세금 처리 등) 컨텍스트 도움말에 접근 불가. **정산 도메인 특성상 도움말 부재가 가장 큰 친화도 손실 영역 중 하나** (정산 관련 CS 부담 직결).
- spec 은 "파트너 앱 모든 화면에 동일 패턴 적용" 을 명시하지만 실제로는 party_list_page 1개 화면만 적용. 패턴 일관성 위반.
- audit / spec walk 가 이 화면을 "spec 동기화됨" 으로 잘못 판정할 위험.

## reference

- canonical 구현: `apps/app_partner/lib/src/features/party/list/party_list_page.dart:8-55` (Fix #2200 — `_kPartyHelpSections` const list + IconButton(info_outline) + showMinglitHelpSheet)
- helper 위치: `shared/packages/mds/core/lib/src/ui/widgets/common/minglit_help_sheet.dart:42-63` (`showMinglitHelpSheet` + `HelpSection` 구조체 — minglit_kit re-export)
- spec sync PR: #2380 (commit e1cc82a55, closes #2261/#2265, also-closes #2268-2271)
- 자매 issue: settlement_page 외 같은 root cause 로 partner_home_page (#2417) / event_application_manage_page 도 별도 파일링 예정.

## 카테고리

`[audit-uiux/차이]` — 코드 ↔ 단일 진실(spec) drift. spec 만 sync 되고 코드 미반영. tpm 이 트리아지로 `needs-swe` 부여.

— needs-uiux-claude-1
