 Spec — EventApplicationDetailPage (app\_partner · EventApplicationDetailRoute)  

# Event Application Detail

## Overview

| Status | ✅ 디자인완료 — 6개 state · pending_review/approved/rejected/paid + loading + error |
|---|---|
| App | app_partner |
| Category | application · detail · review |
| Route / Surface | EventApplicationDetailRoute · widget: EventApplicationDetailPage |
| Path | /applications/event/:applicationId |
| Hierarchy | Parent: EventApplicationManagePage (탭 목록에서 행 탭으로 진입)Children: — (거절 사유 다이얼로그는 state 5로 이 spec 안에서 다룸) |
| Purpose | 파트너가 한 이벤트 신청을 깊게 검토하는 단일 화면. 신청자 프로필·결제 정보·상태를 한 페이지에서 확인하고, 심사 중인 건은 같은 화면에서 승인 또는 거절 처리한다. |
| User journey | Entry points: 신청 관리의 "승인됨"/"거절됨" 탭에서 신청 행 탭.Exit points: 승인/거절 처리 성공 → "처리가 완료되었습니다." 안내와 함께 자동으로 목록으로 복귀. 뒤로 가기 → 신청 목록. 처리 실패 시 에러 다이얼로그 (화면은 유지). |
| Background | 이벤트 신청 워크플로우는 심사 대기 → (승인 또는 거절) → 결제 완료 순으로 흐름. 파트너가 한 신청을 깊게 검토(거절 사유 작성, 결제 금액 확인, 신원 정보 검증)할 수 있도록 설계. 승인/거절 액션은 심사 대기 상태일 때만 노출되어 부주의한 재처리를 방지. |
| Frequency | 이벤트 운영 기간 중 신청 도착마다. 인기 이벤트는 시간당 다회 진입. |

## History

이 spec의 주요 변경 이력. 최신 항목 위.

| Date | Version | Author | Changes |
|---|---|---|---|
| 2026-05-01 | 1.0 | mark-yun | v1.4 template으로 초기 작성. 6 states (pending_review baseline · approved · rejected · paid · Loading · Error) → mini-table per state, additive diff. 거절 다이얼로그를 별도 state로 추가 (state 5). 실 Flutter source(event_application_detail_page.dart) 기반 — status enum, 결제금액 row, 거절 사유 row, MinglitAsyncValueWidget(loading/error) 검증. |

[🧱 Layout](#layout) [🎨 States](#states) [🔄 Global Behavior](#global-behavior) [📖 Reference](#reference)

🧱

## Layout

화면 구조 — 영역, 정렬, 간격 규칙. 색·타이포 무시.

## Blueprint & tree

AppBar("신청 상세") + 스크롤 body. body는 프로필 카드 → 신청 정보 카드 (+ 심사 대기 상태에선 심사 액션 row까지)의 단순 stack. 로딩/에러 분기는 화면이 자동 처리.

![blueprint](blueprint.png)

**Scaffold**(bg: `color-surface`) ├─ **AppBar**('신청 상세') ← ① └─ **body**: 데이터 단계별 분기 ├─ 로딩 → 중앙 스피너 ├─ 에러 → 중앙 에러 아이콘 + "오류가 발생했습니다." └─ 결과 ├─ 신청 없음 → 중앙 평문 "신청 정보를 찾을 수 없습니다." └─ 결과 화면 └─ **스크롤 body**(padding: `spacing-medium (16)`) └─ **Column**(좌측 정렬) ├─ _Profile card_ ← ② │ └─ Card → Padding(`spacing-medium`) → Row │ ├─ **CircleAvatar**(56×56 · primary 옅은 배경) │ ├─ Gap: `spacing-medium (16)` │ ├─ Column(좌측 정렬) │ │ ├─ 이름 (titleMedium · w700) │ │ ├─ "{age}세 · {gender}" (있을 때만) │ │ └─ 생년월일 (있을 때만) │ └─ 상태 배지 │ ├─ Gap: `spacing-medium (16)` ├─ "신청 정보" 섹션 헤더 ← ③ ├─ Gap: `spacing-small (8)` ├─ _Info card_ ← ④ │ └─ Card → Column │ ├─ "신청일" 행 (yyyy.MM.dd) │ ├─ "결제금액" 행 (있을 때만 — 천 단위 콤마 + 원) │ └─ "거절 사유" 행 (있을 때만 — 멀티라인) │ └─ \[심사 대기 상태일 때만\] ← ⑤⑥ ├─ Gap: `spacing-large (24)` ├─ "심사" 섹션 헤더 ← ⑤ ├─ Gap: `spacing-small (8)` └─ _Action row_ ← ⑥ └─ Row ├─ 거절 (외곽선 + 에러 색) ├─ Gap: `spacing-small (8)` └─ 승인 (primary 채움)

## Spacing & alignment rules

| # | Region | Alignment | Spacing |
|---|---|---|---|
| — | Outer body padding | — | 전 방향: spacing-medium (16px) (SingleChildScrollView padding) |
| ① | AppBar | centerTitle (Material default · Partner theme) · h=56 | 표준 AppBar — 뒤로가기 자동 |
| ② | Profile Card | Row(crossAxis: center) · avatar + 가변 info + 우측 badge | card inner: spacing-medium (16) · avatar↔info: spacing-medium (16) |
| ③ | Section title "신청 정보" | flex start · titleSmall | 위 카드와 간격: spacing-medium (16) · 아래 카드와: spacing-small (8) |
| ④ | Info Card | Column(stretch) · ListTile dense rows | row inner: ListTile dense (min-height 48) · row 간 1px hairline |
| ⑤ | Section title "심사" | flex start · titleSmall · pending only | 위 카드와 간격: spacing-large (24) · 아래 row: spacing-small (8) |
| ⑥ | Action Row | Row · 2 Expanded · 풀폭 분할 | 버튼 사이: spacing-small (8) · 버튼 height: 48 |

## Sub-anatomy ① — Profile Card (②)

Avatar + 좌측 사용자 정보 stack + 우측 status badge. badge 높이는 텍스트 자연스러운 크기, badge는 우상단으로 클리핑되지 않는 일반 Row 끝.

![blueprint](blueprint_2.png)

**Card**(`radius-card (16)`) └─ **Padding**(`spacing-medium (16)`) └─ **Row**(crossAxis: center) ├─ **CircleAvatar**(r=28, bg: primary@`highlight (10%)`) ← ㉠ │ └─ Text(name\[0\]) · titleLarge · w700 · color: primary ├─ Gap: `spacing-medium (16)` ├─ **Expanded** → Column(crossAxis: start) ← ㉡ │ ├─ Text(name) · titleMedium · w700 │ ├─ \[age || gender\] Text("{age}세 · {gender}") · bodyMedium · onSurfaceVariant │ └─ \[birthDate\] Text(birthDate) · labelSmall · onSurfaceVariant └─ **\_StatusBadge**(status) ← ㉢

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | CircleAvatar | 크로스 center · 56×56 | bg: primary @ opacity-highlight (.10) |
| ㉡ | Info Column | start · 자동 줄바꿈 | row 간 자동 (Column intrinsic) · meta gap: 1–2px |
| ㉢ | StatusBadge | row 끝 · vertical center | padding: spacing-small (8) h × spacing-xxsmall (2) v · radius: radius-small (8) |

## Sub-anatomy ② — Info Card (④)

정보 행이 세로로 쌓인다. "신청일"은 항상 표시. "결제금액"은 금액이 있을 때만, "거절 사유"는 사유가 있을 때만 추가.

![blueprint](blueprint_3.png)

**Card**(`radius-card (16)`) └─ **Column** ├─ **ListTile**(dense:true) ← ㉠ │ ├─ title: Text("신청일") │ └─ trailing: Text(yyyy.MM.dd) · bodyMedium ├─ \[paymentAmount>0\] **ListTile**(dense:true) ← ㉡ │ ├─ title: Text("결제금액") │ └─ trailing: Text("#,###원") · bodyMedium └─ \[rejectionReason!=null\] **ListTile**(dense:true) ← ㉢ ├─ title: Text("거절 사유") └─ subtitle: Text(rejectionReason)

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | ListTile dense | title left · trailing right | min-height 48 · v-padding 4 · h-padding ListTile default (16) |
| ㉡ | ListTile dense | 동일 · 천 단위 콤마 포맷 | 금액은 RegExp #,###으로 포맷 + "원" 접미 |
| ㉢ | ListTile (subtitle) | title 위 · subtitle 아래(multiline) | subtitle은 자연 wrap, dense 무시되고 Text 자체 line-height 따름 |

## Sub-anatomy ③ — Action Row (⑥) — pending\_review only

심사 대기 상태일 때만 "심사" 섹션과 함께 노출. 한 줄에 두 버튼이 동일 폭으로 분할 — 좌측은 거절 (외곽선 + 에러 색), 우측은 승인 (primary 채움).

![blueprint](blueprint_4.png)

**Row** ├─ **Expanded** ← ㉠ │ └─ **OutlinedButton.icon**(side: error) │ ├─ icon: Icons.close · color-error │ └─ label: Text("거절") · color-error ├─ Gap: `spacing-small (8)` └─ **Expanded** ← ㉡ └─ **FilledButton.icon**(default · primary) ├─ icon: Icons.check └─ label: Text("승인")

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | OutlinedButton "거절" | flex 1 · 풀폭 좌 · 아이콘 좌 | border + text: color-error · radius: radius-button (12) |
| ㉡ | FilledButton "승인" | flex 1 · 풀폭 우 · 아이콘 좌 | bg: color-primary (Partner #6c3ce1) · text: white · radius: radius-button (12) |

🎨

## States

시각 변형 6종. baseline = pending\_review (심사 액션 노출), 나머지는 additive diff.

신청 상태(심사 중 · 승인됨 · 거절됨 · 결제 완료) + 데이터 로딩/에러 + 거절 사유 다이얼로그(모달). 알 수 없는 상태값이 들어오면 그 문자열 그대로 외곽선 색으로 표시되는 fallback.

### State summary

| State | Tag | 조건 (요약) | Key visual differentiator |
|---|---|---|---|
| Pending review 🎯 | baseline | 심사 대기 | 심사 섹션 + 거절/승인 버튼 row · warning(amber) 배지 |
| Approved | read-only | 승인됨 | 심사 섹션 미노출 · success(green) 배지 · 결제금액 행 가능 |
| Rejected | read-only | 거절됨 | 심사 섹션 미노출 · error(red) 배지 · 거절 사유 행 추가 |
| Paid | completed | 결제 완료 | primary(purple) 배지 · 결제금액 항상 표시 · 심사 섹션 없음 |
| Reject reason dialog | modal | "거절" 탭에서 진입 | 어두운 scrim + 다이얼로그 · 사유 입력란 + "취소" / "거절" |
| Loading / Error | async | 데이터 로딩/실패 | body 영역만 스피너 또는 에러 아이콘 + "오류가 발생했습니다." (AppBar 유지) |

![visual](visual_1.png)

🔄

## Global Behavior

cross-cutting — 모든 state에 적용되는 액션, motion, 글로벌 에지케이스. 각 state 한정 액션은 위 mini-table 참고.

## Cross-cutting interactions

| 사용자 액션 | 화면에 보이는 결과 |
|---|---|
| 뒤로 가기 (시스템 back / AppBar back) | 신청 관리 화면으로 복귀. 진행 중인 데이터 조회는 자동 정리. |
| 심사 처리 결과 | 처분이 성공하면 "처리가 완료되었습니다." 안내 + 자동으로 목록 화면으로 복귀. 실패 시 에러 다이얼로그 노출 + 화면은 유지. |
| 다크 모드 토글 | scaffold/카드 배경이 다크 톤으로 자동 전환. 아바타/배지의 옅은 배경은 각 색상의 비율 그대로 유지. partner primary도 다크 변형으로 자동 매핑. |
| 금액 포맷 | 모든 state에서 결제금액은 천 단위 콤마 + "원" 접미사. 0이나 비어있는 값은 행 자체가 숨김. |

## Motion timing

Source: `shared/packages/mds/core/lib/src/theme/minglit_design_tokens.dart` · GoRouter는 `MinglitPageTransitions.sharedAxisScaled` 사용 (route data class에서 명시).

| Transition | Token / Duration | Notes |
|---|---|---|
| 화면 진입 (목록 → 상세) | MinglitAnimation.medium (350ms) | shared-axis Z-scale + fade. |
| Loading → 데이터 표시 | cut (no animation) | 부드러운 페이드 없이 즉각 교체. |
| 거절 다이얼로그 in/out | MinglitAnimation.fast (200ms) | 기본 다이얼로그 scale + fade. |
| 승인/거절 처리 → 안내 + 목록 복귀 | MinglitAnimation.fast (200ms) | 안내 스낵바가 슬라이드 업되고 즉시 목록 화면으로 복귀. 스낵바는 다음 화면에 남아있음. |

## Global edge cases

-   **네트워크 끊김** — 진입 직후라면 로딩에서 에러로 전환 (재시도 버튼 없음). 심사 처리 중이라면 에러 다이얼로그.
-   **다크 모드** — 다크 토글로 확인. partner primary는 다크 변형으로 자동 전환. 배지 배경은 각 색상의 옅은 비율을 그대로 유지.
-   **알 수 없는 상태값** — 새 상태가 추가되어 본 화면에 매핑이 없으면 그 문자열 그대로 외곽선 색으로 표시되는 fallback이 동작.
-   **접근성** — 아바타의 이니셜은 단일 글자 — screen reader는 이름 텍스트를 별도로 읽음. 버튼은 라벨 텍스트가 그대로 시맨틱.
-   **모델-UI drift** — 환불 상태, 결제 시각 등은 데이터에 존재하지만 본 화면은 표시하지 않음. 환불/취소 케이스 가시성은 후속 개선 후보.

📖

## Reference

implementation source + 인접 화면. Components / Tokens는 위 mini-table 참고.

## Implementation source

| Widget | EventApplicationDetailPage + _ApplicationDetailBody + _StatusBadge — apps/app_partner/lib/src/features/application/event_application_detail_page.dart |
|---|---|
| Route | EventApplicationDetailRoute · /applications/event/:applicationId · MinglitPageTransitions.sharedAxisScaled · app_routes.dart |
| Provider | eventApplicationDetailProvider(applicationId) · eventApplicationReviewControllerProvider (review 결과 listenManual) |
| Repository | eventRepositoryProvider.getApplicationById — EventApplication model + status string ('pending_review' / 'approved' / 'rejected' / 'paid') |
| Async wrapper | MinglitAsyncValueWidget — loading: MinglitCircularProgressIndicator, error: _DefaultErrorView (icon + 제목, retry 없음) |
| Snackbar / error | ScaffoldMessenger.of(context).showSnackBar + handleMinglitError (controller.listenManual에서) |
| ⚠️ 알려진 drift | refund_status·paid_at·payment_id 모델 필드는 page에서 미렌더. Refunded/Canceled status 자체가 현 코드엔 없음 (status enum은 4개로 한정). |

## Related screens

| Spec | Relation |
|---|---|
| EventApplicationManagePage | 부모 화면. "승인됨" / "거절됨" 탭의 신청 행 탭으로 이 detail 진입 (Fix #1860). |
| PartnerHomePage | Partner Shell의 홈. ApplicationBranch는 bottom-nav로 진입. |
| EventDetailPage | 이 신청이 향한 이벤트의 파트너 측 상세. 동일 데이터 도메인이지만 별도 surface. |