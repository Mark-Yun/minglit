 Spec — PartnerMemberPermissionPage (app\_partner · MemberPermissionRoute)  

# Partner Member Permission

## Overview

| Status | ✅ 디자인완료 — 7 state · 역할 + 9개 permission flag 편집 |
|---|---|
| App | app_partner |
| Category | member · partner ops · role/permission editor |
| Route / Surface | MemberPermissionRoute · widget: PartnerMemberPermissionPage |
| Path | /more/partners/:partnerId/members/:targetUserId/permission |
| Hierarchy | Parent: PartnerMemberListPage (멤버 카드 탭 → push, sharedAxisScaled transition)Children: — (form internal — _MemberPermissionForm는 별도 spec 없음) |
| Purpose | 선택한 직원의 역할(owner/manager/staff)과 9개 세부 permission(파트너 정보 수정 · 정산 조회/편집 · 멤버 관리 · 파티 관리 · 인증 조회/심사 · 유저 데이터 조회 · 코멘트 관리)을 한 화면에서 편집하고 저장한다. 위임 가능한 권한 위계 전체를 한 곳에서 다룬다. |
| User journey | Entry points: 멤버 목록 화면 → 멤버 카드 탭.Exit points: 저장 성공 → 성공 안내 메시지가 잠깐 보이고 멤버 목록으로 복귀(변경사항 반영) · AppBar back → 변경 무시하고 복귀 · 오류 → 안내 메시지로만 알리고 화면 유지. |
| Background | 역할(role)은 3단계로 분리되어 있고 권한(permissions)은 추가 옵트인이 가능한 9개 항목으로 구성된다 — 같은 manager라도 가게마다 책임 범위가 달라 세부 토글로 보강. 역할 dropdown을 바꾸면 권한이 그 역할의 기본값으로 일제 초기화 — 사용자에게 정렬된 시작점을 주기 위함이고 그래서 dropdown 위 경고 문구('역할을 변경하면 권한 배열이 기본값으로 초기화됩니다.')를 partner primary 색으로 강조. 역할과 권한은 함께 저장되며, 저장이 완료되면 멤버 목록과 상세 화면이 갱신된다. |
| Frequency | 활성 파트너 기준 연 0~수회. 역할 변경 이벤트는 매우 드물고 보통 가게 셋업 직후 1회 집중. |

## History

이 spec의 주요 변경 이력. 최신 항목 위.

| Date | Version | Author | Changes |
|---|---|---|---|
| 2026-05-01 | 1.0 | mark-yun | v1.4 template으로 작성. 7 state(Default · Role-changed reset · Saving · Save success · Save error · Member not found · Loading · Error) → mini-table per state, baseline = Default(manager 역할 + manager default permissions). 파트너 brand color(#6c3ce1) viewport-scoped. role 변경 시 permissions 자동 재기록 동작 별도 state. |

[🧱 Layout](#layout) [🎨 States](#states) [🔄 Global Behavior](#global-behavior) [📖 Reference](#reference)

🧱

## Layout

화면 구조 — 영역, 정렬, 간격 규칙. 색·타이포 무시.

## Blueprint & tree

Scaffold = simpleAppBar('권한 상세 설정') + body(MinglitAsyncValueWidget). data 분기 시 \_MemberPermissionForm을 SingleChildScrollView로 띄우고 위에서 아래로 멤버 헤더 → 역할 섹션(Dropdown) → 권한 섹션(경고문 + 9 CheckboxListTile) → 풀폭 ElevatedButton('변경 사항 저장') 순. 저장 중일 때는 폼 전체가 사라지고 MinglitCircularProgressIndicator 단독 노출.

![blueprint](blueprint.png)

**Scaffold** ├─ **appBar**: simpleAppBar(title:'권한 상세 설정') └─ **body**: `MinglitAsyncValueWidget<Map?>` ├─ loading: `MinglitCircularProgressIndicator` ├─ data null: Center(Text '멤버를 찾을 수 없습니다.') └─ data Map: **\_MemberPermissionForm** ├─ if \_isSaving → MinglitCircularProgressIndicator (전체 교체) └─ else → **SingleChildScrollView**(pad `spacing-large = 24`) └─ Column(crossAxis.start) ├─ _Member header_ ← ② │ ├─ Text(user.name · titleLarge bold) │ └─ Text(user.email · bodyMedium outline) ├─ SizedBox(`spacing-xlarge = 32`) │ ├─ _Role section_ ← ③ │ ├─ Text('역할(Role) 선택' · bodyLarge bold) │ ├─ SizedBox(`spacing-small = 8`) │ └─ Container(border outlineVariant · radius-small) │ └─ DropdownButton<String> · 3 items (owner/manager/staff) ├─ SizedBox(`spacing-xlarge = 32`) │ ├─ _Permission section_ ← ④ │ ├─ Text('상세 기능 권한(Permissions)' · bodyLarge bold) │ ├─ SizedBox(`spacing-xsmall = 4`) │ ├─ Text('역할을 변경하면 권한 배열이 기본값으로 초기화됩니다.' · labelSmall · color primary) │ ├─ SizedBox(`spacing-medium = 16`) │ └─ ...\_permissionLabels.entries.map(\_buildPermissionTile) │ └─ **CheckboxListTile**(leading checkbox · label bodyMedium · contentPadding zero) ├─ SizedBox(`spacing-xlarge × 1.5 = 48`) │ └─ _Save_ ← ⑤ └─ **ElevatedButton**('변경 사항 저장' · 풀폭)

## Spacing & alignment rules

| # | Region | Alignment | Spacing |
|---|---|---|---|
| — | Outer page padding | SingleChildScrollView all spacing-large (24) | 좌우 24 · 상하 24 |
| ① | AppBar | height 56 · centerTitle:false · scaffold-gray bg | title typography app-bar-title (18 / 700) |
| ② | Member header | Column.start · name 큰 글씨 · email 작은 글씨 | name → email spacing-xxsmall (2) (Text 자체 line-height) · header → role spacing-xlarge (32) |
| ③ | Role section | Column.start · Dropdown은 가로 isExpanded | title → dropdown spacing-small (8) · dropdown 내부 padding-horizontal spacing-small (8) · role → permission spacing-xlarge (32) |
| ④ | Permission section | Column.start · 9개 tile vertical 나열 | title → warn spacing-xsmall (4) · warn → tiles spacing-medium (16) · tile 사이 간격 = CheckboxListTile 자체 height (48) |
| ⑤ | Save button | 풀폭 (Column.crossAxis.stretch는 아니지만 Column 자체가 stretch 안 시 ElevatedButton이 child의 폭만큼 확장 — 실제로는 제한 없음 → MinglitTheme의 ElevatedButton min-width 영향) | permission tiles → save spacing-xlarge × 1.5 = 48 · button height 48 |

## Sub-anatomy ① — Permission CheckboxListTile

9개 permission flag 각각 별도 CheckboxListTile. controlAffinity:leading(좌측 체크박스) · contentPadding:zero(외부 24 padding만) · onChanged → setState로 \_currentPermissions 배열 add/remove.

![blueprint](blueprint_2.png)

**CheckboxListTile**(controlAffinity:leading · contentPadding:zero) ├─ value: isChecked ← (\_currentPermissions.contains(key)) ├─ leading: **Checkbox**(activeColor: `color-primary`) ← ㉠ ├─ title: **Text**(label · bodyMedium) ← ㉡ └─ onChanged: setState(\_currentPermissions.add/remove)

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | Checkbox | leading · 18×18 box | activeColor color-primary · uncheck border color-divider |
| ㉡ | Label Text | flex · left · single-line (긴 라벨도 wrap 가능) | typography bodyMedium · color onSurface |

**9개 permission key 순서**: PARTNER\_EDIT · SETTLEMENT\_VIEW · SETTLEMENT\_EDIT · MEMBER\_MANAGE · PARTY\_MANAGE · VERIFY\_LIST\_VIEW · USER\_DATA\_VIEW · VERIFY\_REVIEW · COMMENT\_MANAGE (Map 선언 순서 그대로 — Dart Map insertion order 보장).

🎨

## States

시각 변형 7종. baseline = Default(manager + 6개 default permissions), 나머지는 additive diff.

**State 식별 기준**: 멤버 데이터 도착 여부 · 멤버 존재 여부 · 선택된 역할 / 권한 토글 상태 · 저장 진행 여부 · 저장 결과(성공/오류).

### State summary — 7 states

| State | Tag | 조건 (요약) | Key visual differentiator |
|---|---|---|---|
| Default | baseline | 멤버 데이터가 도착했고 manager 역할로 진입 | Dropdown='Manager (운영 및 심사)' · 6개 박스 체크 · 보라 경고문 · 풀폭 보라 Save 버튼 |
| Role changed → reset | local mut. | Dropdown 변경 직후 | 체크 패턴이 새 역할 기본값으로 일제히 갱신됨 (애니메이션 없이 즉시) |
| Saving | async | 저장 진행 중 | 폼 전체가 사라지고 화면 가운데 스피너 |
| Save success | overlay | 저장 성공 직후 | 녹색 성공 안내 메시지('저장되었습니다.') + 멤버 목록으로 복귀 후 화면 자체가 사라짐 |
| Save error | overlay | 저장 실패 | 오류 안내 메시지가 잠깐 노출되고 폼은 그대로 유지 |
| Member not found | edge | 멤버를 찾을 수 없음 | 중앙 텍스트 '멤버를 찾을 수 없습니다.'만 (form 없음) |
| Loading / Error (fetch) | async | 멤버 데이터 조회 중/실패 | Loading=중앙 스피너 · Error=기본 오류 화면 |

![visual](visual_1.png)

🔄

## Global Behavior

cross-cutting · motion · global edges.

## Cross-cutting interactions

| 사용자 액션 | 화면에 보이는 결과 |
|---|---|
| OS back / AppBar back | 모든 state에서 가능 — 멤버 목록으로 복귀. 변경사항이 있어도 별도 확인 없이 무시(향후 dirty guard 도입 후보) |
| 키보드 dismiss | 입력 필드 없음 — Dropdown은 키보드를 호출하지 않음. |
| 앱 background → foreground | 자동 새로고침 없음. 단, 저장 중이었다면 백그라운드에서 계속 진행되어 결과가 반영됨. |
| 화면 회전 | 가로 화면에서도 모든 항목이 세로 스크롤로 노출되어 폼 자체 잘림 없음 |

## Motion & timing

| Token | Value | Use case |
|---|---|---|
| MinglitAnimation.micro | 100ms | Checkbox toggle ripple · Dropdown item ripple · Save button press feedback |
| MinglitAnimation.fast | 200ms | AsyncValueWidget loading → data fade · Save button → spinner교체 (form swap) |
| MinglitAnimation.medium | 350ms | route push from list (sharedAxisScaled · MemberPermissionRoute가 정의) · snackbar slide-up |

| Transition | Duration (token) | Curve / notes |
|---|---|---|
| list → permission (push) | medium (350ms) | sharedAxisScaled — 표준 push 전환 |
| Dropdown 열기/닫기 | fast (200ms) | Material default · 위로 펼침 |
| form → spinner (Saving) | fast (200ms) | 거의 즉시 교체 (별도 페이드 없음) |
| Save success → pop | medium (350ms) | 표준 reverse 전환 + 안내 메시지 슬라이드 업 동시 |

## Global edge cases

-   **네트워크 끊김** — 진입 시: 오류 화면으로 진입 · 저장 시: 오류 안내 메시지 + 폼 유지(재시도 가능)
-   **인증 만료** — 인증 만료가 감지되면 로그인 화면으로 자동 이동될 수 있음
-   **다크 모드** — 모든 색상이 다크 톤으로 자동 전환. 보라 경고문 / 저장 버튼도 다크 보라로 dim.
-   **접근성** — 체크박스는 'checked/unchecked' 음성 안내 · Dropdown은 음성 라벨이 누락될 수 있어 향후 보강 후보 · 큰 글씨 모드 시 9개 항목이 세로로 길어져 스크롤 발생
-   **다국어** — 권한 라벨은 현재 한글 기준. 다국어 추가 시 라벨 사전만 확장하면 됨

📖

## Reference

Implementation source + 인접 화면 link.

## Implementation source

| 항목 | Path / Reference |
|---|---|
| Widget class | PartnerMemberPermissionPage · 내부 form: _MemberPermissionForm |
| File path | apps/app_partner/lib/src/features/member/partner_member_permission_page.dart |
| Provider | partnerMemberProvider({partnerId, targetUserId}) — list provider 위에서 firstWhereOrNull 필터 |
| Repository | partnerRepositoryProvider · updateMemberRole · updateMemberPermissions |
| Route | MemberPermissionRoute · path: /more/partners/:partnerId/members/:targetUserId/permission · transition: MinglitPageTransitions.sharedAxisScaled |

## Related screens

| Spec | Relation |
|---|---|
| PartnerMemberListPage | Parent — 진입점, 저장 후 invalidate되어 갱신 |
| MorePage | Grandparent — 더보기 탭 root |