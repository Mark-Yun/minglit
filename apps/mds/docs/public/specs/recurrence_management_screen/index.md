 Spec — RecurrenceManagementScreen (app\_partner · RecurrenceManagementRoute)  

# Recurrence Management

## Overview

| Status | ✅ 디자인완료 — 8 state · 파티 반복 규칙(active/paused/cancelled) 관리 |
|---|---|
| App | app_partner |
| Category | party · recurrence · rule lifecycle |
| Route / Surface | RecurrenceManagementRoute · widget: RecurrenceManagementScreen |
| Path | /more/parties/:partyId/recurrence |
| Hierarchy | Parent: PartyDetailPage (파티 상세 → '반복 규칙' 메뉴 push)Children: — (overlay만 — MinglitAlert.showConfirm) |
| Purpose | 한 파티에 등록된 반복 규칙(매주/2주/매월)의 현재 상태(활성/일시정지/취소)를 보여주고, 파트너가 일시정지·재개·취소 액션을 취하게 한다. 반복 일정 자동 생성 ON/OFF 스위치 + 종료 트리거 단일 진입점. |
| User journey | Entry points: PartyDetailPage → "반복 규칙 관리" 메뉴 탭.Exit points: AppBar back → PartyDetail로 pop · 일시 정지/재개 → 같은 화면 stay (status 변경 후 success snackbar) · 취소 → confirm dialog → 같은 화면 stay (cancelled로 status 변경, 액션바 사라짐, 안내문 표시). |
| Background | 반복 규칙은 PGMQ + cron 기반으로 매일 새 이벤트를 생성한다 — 일시 정지(paused)는 cron 스케줄러가 row를 스킵하도록 플래그를 세우고, 취소(cancelled)는 row를 종결 처리해 더 이상 활성화 불가능하게 한다. 취소가 비가역적인 이유는 종료된 규칙을 살리면 과거 시점의 일정이 갑자기 생성되는 race를 야기하기 때문 — 그래서 confirm dialog가 destructive variant로 강한 마찰을 둠. 일시 정지는 가역적이라 일반 OutlinedButton. |
| Frequency | 활성 파트너 기준 월 0~수회. 시즌제(주말 한정 등) 운영 파트너만 active 사용. 대부분의 파트너는 1회 셋업 후 진입 안 함. |

## History

이 spec의 주요 변경 이력. 최신 항목 위.

| Date | Version | Author | Changes |
|---|---|---|---|
| 2026-05-01 | 1.0 | mark-yun | v1.4 template으로 작성. 8 state(Default active · Paused · Cancelled · No rule · Confirm cancel dialog · Action loading · Success snackbar · Loading/Error fetch) → mini-table per state, baseline = Default active(매주 · 정상 운영중). 파트너 brand color(#6c3ce1) viewport-scoped. |

[🧱 Layout](#layout) [🎨 States](#states) [🔄 Global Behavior](#global-behavior) [📖 Reference](#reference)

🧱

## Layout

화면 구조 — 영역, 정렬, 간격 규칙. 색·타이포 무시.

## Blueprint & tree

Scaffold = simpleAppBar('반복 규칙 관리') + body(AsyncValueWidget). data 분기 시 Column\[Expanded(SingleChildScrollView body)\] + bottom action bar (status가 cancelled가 아닐 때만). body 안에는 MinglitTag(status) + Card('규칙 정보' + 5~6 row) + cancelled 시 안내문. action bar는 status별 버튼 조합이 다름.

![blueprint](blueprint.png)

**Scaffold** ├─ **appBar**: simpleAppBar(title:'반복 규칙 관리') └─ **body**: `MinglitAsyncValueWidget<RecurrenceRule?>` ├─ loading: MinglitCircularProgressIndicator ├─ data null: Center(Text '설정된 반복 규칙이 없습니다.') └─ data RecurrenceRule: **\_RecurrenceRuleContent** └─ Column(crossAxis.stretch) ├─ **Expanded**(**SingleChildScrollView**(pad `spacing-large`)) ← ② │ └─ Column(crossAxis.start) │ ├─ MinglitTag(status: '활성' | '일시 정지' | '취소됨') │ ├─ SizedBox(`spacing-large = 24`) │ ├─ **Card**(pad `spacing-medium = 16`) │ │ └─ Column(crossAxis.start) │ │ ├─ Text('규칙 정보' · titleSmall bold) │ │ ├─ SizedBox(`spacing-small = 8`) │ │ └─ infoRow × 4~6 (반복 패턴 / 시작 / 종료 / 종료 날짜? / 마지막 생성일?) │ └─ if cancelled → Text('취소된 규칙은 재활성화할 수 없습니다.') │ └─ if status != cancelled → **SafeArea + Padding(`spacing-medium`)** ← ③ └─ Row\[Expanded(button), gap `spacing-small`, Expanded(button)\] status별: · active → \[OutlinedButton '일시 정지', FilledButton(error) '규칙 취소'\] · paused → \[OutlinedButton '규칙 취소', FilledButton '재개'\]

## Spacing & alignment rules

| # | Region | Alignment | Spacing |
|---|---|---|---|
| ① | AppBar | height 56 · centerTitle:false · scaffold-gray bg | title typography app-bar-title (18 / 700) |
| ② | body — Expanded scroll | SingleChildScrollView pad-all spacing-large (24) · Column.start | tag → card spacing-large (24) · card → hint spacing-large (24) |
| — | Card 내부 | Padding all spacing-medium (16) · Column.start | title → first row spacing-small (8) · row 사이 vertical spacing-xsmall (4) (Padding symmetric) |
| — | InfoRow | Row.spaceBetween · label 좌측 / value 우측 | vertical padding spacing-xsmall (4) · 라벨 색은 onSurfaceVariant · value는 onSurface |
| ③ | Action bar | SafeArea + Padding all spacing-medium (16) · Row.flex equal · 2 Expanded | 버튼 사이 spacing-small (8) · 버튼 height ~44 · radius radius-button (12) |

## Sub-anatomy ① — Info Card (규칙 정보)

Card 내부에 5~6 InfoRow. 각 row는 label(좌) + value(우) spaceBetween. 종료 날짜 / 마지막 생성일은 nullable이라 있을 때만 렌더 — 4행 또는 6행으로 변동.

![blueprint](blueprint_2.png)

**Card**(default elevation/radius) └─ **Padding**(all `spacing-medium (16)`) └─ Column(crossAxis.start) ├─ Text('규칙 정보' · titleSmall · bold) ← ㉠ ├─ SizedBox(`spacing-small (8)`) ├─ infoRow('반복 패턴', patternLabel) ← ㉡ 매주/2주마다/매월 ├─ infoRow('시작 시간', rule.startTime) ← ㉢ ├─ infoRow('종료 시간', rule.endTime) ← ㉣ ├─ if endDate != null → infoRow('종료 날짜', endDate) ← ㉤ └─ if lastGeneratedDate != null → infoRow('마지막 생성일', lastGeneratedDate) ← ㉥

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | '규칙 정보' title | top · bold | typography titleSmall · fontWeight bold · color onSurface |
| ㉡~㉥ | InfoRow | Row.spaceBetween · vertical pad spacing-xsmall (4) | label bodyMedium · color onSurfaceVariant · value bodyMedium · color onSurface |

## Sub-anatomy ② — Action bar (status별 분기)

status별로 버튼 조합이 다름. cancelled 상태에서는 action bar 자체가 hide된다 (Column 자식 if 분기로).

![blueprint](blueprint_3.png)

if active: Row \[ Expanded → **OutlinedButton**('일시 정지') ← ㉠ SizedBox(`spacing-small (8)`) Expanded → **FilledButton**(bg: error, '규칙 취소') ← ㉡ \] if paused: Row \[ Expanded → **OutlinedButton**('규칙 취소') ← ㉠ SizedBox(`spacing-small (8)`) Expanded → **FilledButton**(bg: primary, '재개') ← ㉡ \] if cancelled: (action bar 자체 hidden — Column 자식 if 분기로)

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | Outlined button | flex 1 · 좌측 | border color-primary (or color-error when paused-cancel) · text 동일 색 · transparent bg |
| ㉡ | Filled button | flex 1 · 우측 | active: color-error bg + #fff text · paused-resume: color-primary bg + #fff text |

🎨

## States

시각 변형 8종. baseline = Default active(매주 · 운영중), 나머지는 additive diff.

**State 식별 기준**: `partyRecurrenceRuleProvider` AsyncValue · `RecurrenceRule.status`(active/paused/cancelled) · `recurrenceManagementControllerProvider.isLoading` (액션 진행 중) · MinglitAlert.showConfirm 오버레이 · 결과 snackbar.

### State summary — 8 states

| State | Tag | 조건 (요약) | Key visual differentiator |
|---|---|---|---|
| Default · Active | baseline | rule.status == active | 보라 '활성' 칩 · Card · 액션바 [Outlined 일시정지 + Filled error 취소] |
| Paused | state | rule.status == paused | tertiary '일시 정지' 칩 · 액션바 [Outlined 취소 + Filled primary 재개] |
| Cancelled | terminal | rule.status == cancelled | error '취소됨' 칩 · 안내문 '재활성화할 수 없습니다' · 액션바 hidden |
| No rule | edge | rule == null | 중앙 '설정된 반복 규칙이 없습니다.' (Card · 액션바 모두 없음) |
| Confirm cancel dialog | overlay | '규칙 취소' 탭 직후 | scrim + AlertDialog(isDestructive:true) — 빨간 '취소하기' 버튼 + '아니오' |
| Action loading | async | controller.isLoading | 액션 버튼 disabled (onPressed=null) · 스피너 별도 노출 없음 (글로벌 loading은 사용 안 함) |
| Success snackbar | overlay | 액션 성공 직후 | 녹색 success snackbar('일시 정지/재개/취소되었습니다') + provider invalidate |
| Loading / Error (fetch) | async | provider lifecycle | Loading=중앙 spinner · Error=AsyncValueWidget default |

![visual](visual_1.png)

🔄

## Global Behavior

cross-cutting · motion · global edges.

## Cross-cutting interactions

| 사용자 액션 | 화면에 보이는 결과 |
|---|---|
| OS back / AppBar back | 모든 state에서 가능 — PartyDetailPage로 pop. 액션 RPC 진행 중에도 가능 (mounted 가드). |
| 앱 background → foreground | provider 자동 refetch 없음. 다른 디바이스에서 status가 바뀌었어도 이 화면은 stale로 남음. |
| Confirm dialog 외부 scrim 탭 | dialog dismiss · 액션 무시 (cancelText 탭과 동일) |

## Motion & timing

| Token | Value | Use case |
|---|---|---|
| MinglitAnimation.micro | 100ms | 버튼 ripple · MinglitTag tap (현재 tap 없지만 ink 효과 default) |
| MinglitAnimation.fast | 200ms | AsyncValueWidget loading → data fade · 액션바 button disabled toggle |
| MinglitAnimation.medium | 350ms | route push from PartyDetail · MinglitAlert dialog slide-up · snackbar slide-up |

| Transition | Duration (token) | Curve / notes |
|---|---|---|
| partyDetail → recurrence (push) | medium (350ms) | Material default route transition |
| action 진행 중 button disable → enable | fast (200ms) | AnimatedSwitcher 없이 즉시 setState |
| Confirm dialog enter/exit | medium (350ms) | Material AlertDialog default fade + scale |
| Snackbar slide-up/dismiss | medium (350ms) | auto-dismiss ~3s |
| status 변경(active ↔ paused ↔ cancelled) | fast (200ms) | AsyncValueWidget data → data 재 build · MinglitTag 색 즉시 swap |

## Global edge cases

-   **네트워크 끊김** — fetch: Error state · 액션: handleMinglitError snackbar(\_handleResult가 처리)
-   **auth 만료** — RPC 401 → controller hasError → handleMinglitError
-   **다크 모드** — 모든 토큰 자동 변환. status tag 3색은 색상 시스템(primary/tertiary/error) 그대로 → dark 변형 자동 적용
-   **접근성** — MinglitTag label은 sr 읽음 · Card title 'titleSmall'로 sr heading 인식 · 버튼 disabled 상태 전달
-   **다국어** — 현재 hard-coded ko 문자열만 — l10n 정리 후속 후보

📖

## Reference

Implementation source + 인접 화면 link.

## Implementation source

| 항목 | Path / Reference |
|---|---|
| Widget class | RecurrenceManagementScreen · 내부: _RecurrenceRuleContent |
| File path | apps/app_partner/lib/src/features/party/recurrence/recurrence_management_screen.dart |
| Provider | partyRecurrenceRuleProvider(partyId) (data fetch) · recurrenceManagementControllerProvider (pause/resume/cancel) |
| Controller | recurrence_management_controller.dart |
| Route | RecurrenceManagementRoute · path: /more/parties/:partyId/recurrence · 부모: PartyDetailRoute |

## Related screens

| Spec | Relation |
|---|---|
| PartyDetailPage | Parent — 진입점 |
| PartyCreateWizardPage | Sibling — 새 파티 + 반복 규칙 동시 생성 흐름 |