---
source_url: https://github.com/Mark-Yun/minglit/issues/2415
captured_at: 2026-05-10
issue_number: 2415
state: open
labels: []
author: Mark-Yun
title: "[audit-uiux/차이] settlement_page Dashboard error — 인라인 Column + Text(error.toString()) vs List tab의 MinglitEmptyState"
---

# [audit-uiux/차이] settlement_page Dashboard error — 인라인 Column + Text(error.toString()) vs List tab의 MinglitEmptyState

> Issue #2415 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2415

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

- code (Dashboard error · drift): `apps/app_partner/lib/src/features/settlement/_settlement_dashboard_tab.dart:34-58`
- code (List error · canonical): `apps/app_partner/lib/src/features/settlement/_settlement_list_tab.dart:81-89`
- spec: `apps/mds/docs/public/specs/settlement_page/index.md`
  - Global edge cases line 210 (`대시보드 오류 — '다시 시도' 버튼은 일반 FilledButton ... 후속 통일 후보`)
  - Reference · ⚠️ Drift / 후속 후보 line 229 (`Dashboard error column은 MinglitEmptyState 미사용 (인라인 Text + FilledButton) — list와 시각적 결 통일 후보`)

## 현재 / 권장

### 현재 (drift)

같은 화면(SettlementPage)의 두 탭 — Dashboard / List — 이 **에러 상태에서 다른 컴포넌트 패턴**을 사용. 스펙 자체가 line 210/229 에서 이 불일치를 "후속 통일 후보"로 인지하지만 추적 이슈는 부재.

**Dashboard tab error** (`_settlement_dashboard_tab.dart:34-58`):
```dart
error: (error, _) => [
  Center(
    child: Column(
      children: [
        Text('오류가 발생했습니다',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(error.toString(),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: MinglitSpacing.medium),
        FilledButton(
          onPressed: () => ref
              .read(settlementDashboardControllerProvider.notifier)
              .loadDashboard(),
          child: const Text('다시 시도'),
        ),
      ],
    ),
  ),
],
```

문제 3가지:
1. **MinglitEmptyState 미사용** — 디자인 시스템 위젯이 있는데도 인라인 `Center+Column+Text+FilledButton` 으로 재작성. typography / 간격 / 아이콘 톤이 list 탭 에러와 어긋남.
2. **아이콘 부재** — list 탭 에러는 `Icons.error_outline` 아이콘이 있는데 dashboard 에러는 텍스트만 노출.
3. **`error.toString()` raw 노출** — 사용자에게 raw 예외 메시지(스택/서버 응답 fragment)가 그대로 노출될 수 있음. spec은 "안내 텍스트 + '다시 시도' 버튼" 으로만 기술 — raw 메시지 노출은 spec 에도 없음.

**List tab error** (`_settlement_list_tab.dart:81-89`) — canonical 패턴:
```dart
MinglitEmptyState(
  icon: Icons.error_outline,
  title: '목록을 불러오지 못했습니다',
  subtitle: '잠시 후 다시 시도해 주세요.',
  actionLabel: '다시 시도',
  onAction: () => ref
      .read(settlementListControllerProvider.notifier)
      .refresh(),
)
```

### 권장

`_settlement_dashboard_tab.dart` error 분기를 List tab 과 동일한 `MinglitEmptyState` 로 교체:

```dart
error: (error, _) => [
  MinglitEmptyState(
    icon: Icons.error_outline,
    title: '대시보드를 불러오지 못했습니다',
    subtitle: '잠시 후 다시 시도해 주세요.',
    actionLabel: '다시 시도',
    onAction: () => ref
        .read(settlementDashboardControllerProvider.notifier)
        .loadDashboard(),
  ),
],
```

라벨만 화면 컨텍스트에 맞게 ('목록' → '대시보드') 조정. 시각적 결과 토큰은 list tab 과 100% 동일해짐.

`error.toString()` 은 모니터링 시스템(Sentry 등)으로만 보내고 사용자에게는 노출하지 않는다 — 다른 partner 화면(EventApplicationManagePage 신청관리) State 6 노트와 일치: `📝 사용자에겐 일반 안내 카피만. 디버깅 정보는 별도 모니터링 시스템에서 확인.`

## 영향

- **시각적 일관성**: 같은 화면 내 두 탭의 에러 결이 어긋남 — 사용자가 "같은 앱 같은 화면" 으로 인지하기 어렵게 만듦.
- **UX 위험**: raw 에러 메시지가 노출되면 신뢰감 하락 + (드물게) 민감한 백엔드 정보 노출 위험.
- **maintainability**: 새로운 에러 화면 패턴 결정 시 두 곳을 동시에 갱신해야 하는 부담.

## reference

- spec drift 명시: `apps/mds/docs/public/specs/settlement_page/index.md:210, 229`
- canonical (settlement list tab): `apps/app_partner/lib/src/features/settlement/_settlement_list_tab.dart:81-89`
- canonical (Fix #127): list 탭 에러 상태 — 빈 상태 대신 명시적 에러 화면 + MinglitEmptyState 사용
- 디자인 시스템 위젯: `shared/packages/mds/core/lib/src/ui/widgets/common/minglit_empty_state.dart` (fullPage variant)
- 인접 패턴 — search_page Error: 이미 `MinglitEmptyState` 토픽으로 audit 됨 (issue #2408)
- 인접 패턴 — notification_list_screen Error: 인라인 override 사용 (issue #2413) — 동일 패턴의 다른 차이

## 노트

- 단일 PR 로 처리 가능한 작은 drift. SWE 에게 라우팅 시 "_settlement_dashboard_tab.dart 의 error 분기 8줄을 MinglitEmptyState 로 치환" 으로 충분.
- spec 변경 불필요 — spec 은 이미 "후속 통일" 을 명시하고 있고, 갱신 후에는 ⚠️ Drift 표 line 229 의 첫 번째 항목과 line 210 의 마지막 bullet 만 제거하면 됨.
