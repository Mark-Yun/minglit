 Spec — EventApplicationReviewPage (app\_user · EventApplicationReviewRoute)  

# Event Application Review

## Overview

| Status | 🚧 디자인중 — PurchaseHistoryDetailPage 심사 상태 row tap 시 push할 자식 spec. Flutter 미구현 (TBD). |
|---|---|
| App | app_user |
| Category | my · payment · review |
| Route / Surface | EventApplicationReviewRoute · widget: EventApplicationReviewPage (TBD) |
| Path | /purchase-history/:applicationId/review |
| Hierarchy | Parent: PurchaseHistoryDetailPage (심사 상태 row tap 시 push)Children: — (terminal — review의 CTA "다시 신청하기"는 외부 — EventDetailPage로 push, detail에서 신청 흐름 진행) |
| Purpose | 사용자가 자기 신청 1건이 시간 흐름상 어떻게 진행됐는지를 timeline으로 확인하고, 종결된 결제(거절/취소/결제 실패)에서는 사유 + 다음 액션(다시 신청하기)으로 연결한다. 부모 detail은 "지금 어떤 상태"만 답하고, 이 페이지는 "어떻게 그 상태가 됐나" + "왜 그렇게 됐나"를 답한다. 신청 시 제출한 답변(snapshotData) 스냅샷도 같이 확인 가능. |
| User journey | Entry points: PurchaseHistoryDetail의 ④ 심사 상태 row tap (단일 진입점).Exit points: "다시 신청하기" CTA tap → 같은 이벤트 detail page로 push (모든 case 통일 동작 — detail에서 status 분기 처리). · 뒤로 가기 → PurchaseHistoryDetail로 복귀. |
| Background | PurchaseHistoryDetail이 정보-과다를 막기 위해 심층 정보(거절 사유 / 신청 답변 / 검토 시점 / timeline)를 본문에 펴지 않고 한 뎁스 위임받은 페이지. 핵심 가치는 "시간 흐름 + 사유" — 사용자가 부모 detail에서 못 보는 유일한 정보. 자동 취소(이벤트 시작 도래 등)도 별도 use case로 빼지 않고 timeline 마지막 step의 사유로 통합 표현 (사용자 직접 취소도 같은 step, reason만 다름). 제출한 정보(VerificationSubmission.snapshotData)는 timeline의 "신청" step 안 collapsible로 통합 — default 접힘. 사용자가 토글로 펼쳐 봄 (v1.3 통합 + v1.4 default 접힘). |
| Frequency | 거절/취소/심사 중일 때만 의미 있음. 결제 직후 paid/approved 상태에선 진입 빈도 매우 낮음 (timeline이 단순). 신청 1건당 0-1회. |

## History

이 spec의 주요 변경 이력. 최신 항목 위.

| Date | Version | Author | Changes |
|---|---|---|---|
| 2026-05-03 | 1.10 | mark-yun | "다시 신청하기" 동작 명확화 — 이전: 모호한 "wizard 또는 list" 분기. 변경: 모든 status에서 EventDetailRoute push 통일. 이유: (a) 단일 destination으로 코드/spec 단순, (b) detail이 이벤트 현재 상태(모집 중/종료/만석/가격 변동)를 보여줘 사용자 인지 ↑, (c) detail의 신청 흐름을 review가 재사용 (코드 중복 X), (d) rejected 케이스에서 자격 조건 다시 확인 자연스러움. Backend 재신청 / 결제 재시도 모델 = Model 1 (history 누적) — 같은 applicationId 안에서 status 전환 (rejected/cancelled → pending_review · payment_failed → paid) + snapshot_data array에 새 entry append. 새 application 생성하지 않음. 이유: timeline의 핵심 가치(시간 흐름)가 history 분리 시 약해짐. 후속 작업 표에 backend 정책 확인 필요 항목 명시 (status 전환 허용 / DB unique constraint 검토). |
| 2026-05-03 | 1.9 | mark-yun | MinglitTimeline 컴포넌트 generic화 — v1.8에서 promote한 컴포넌트가 review-specific이라 더 generic하게 재설계. (a) status: completed/active/failed/cancelled enum (신청 lifecycle 어휘) → tone: success/progress/error/neutral/muted (semantic-neutral) — 어떤 도메인 lifecycle도 매핑 가능. (b) pulsing을 tone과 orthogonal한 별도 prop으로 분리 — review의 active 강조용 시각 효과지만, 어떤 tone과도 결합 가능. (c) time string prop → trailing Widget slot으로 일반화 — 시점/금액/badge/icon 무엇이든. (d) muted tone 신규 — outline only로 미래/대기 step 표현 (review는 미사용, order tracking 등에서 활용). Review의 lifecycle → tone 매핑 표를 Sub-anatomy ②에 명시 (completed→success / active→progress+pulsing / failed→error / cancelled→neutral). 다른 use case(정산/배송 등)는 자체 매핑. |
| 2026-05-03 | 1.8 | mark-yun | Timeline 패턴을 MinglitTimeline 컴포넌트로 promote — Sub-anatomy ②의 inline timeline 패턴(dot/line/heading + status enum)을 mds 공용 컴포넌트로 분리. MinglitTimeline + MinglitTimelineStep 작성 (/components#MinglitTimeline). 다른 use case(정산 진행 / 환불 진행 / 배송 추적 등)에서 재사용 가능. Page-specific은 children slot으로 주입 — ReasonBox / "제출한 정보" collapsible / 검토자 메모 / "다시 신청하기" CTA는 모두 review-specific이므로 컴포넌트 안에 들어가지 않음. step의 children slot으로 작성 측에서 자유 컨텐츠 주입. 컴포넌트는 dot/line/heading만 책임. Implementation source 갱신 — 기존 file-private _Timeline / _TimelineStep 표현 → MinglitTimeline + MinglitTimelineStep reference로 변경. mds_core에 widget 신규 추가 필요 (후속 PR). |
| 2026-05-03 | 1.7 | mark-yun | Spec internal cleanup pass — v1.0~v1.6 evolution 과정에서 누락된 stale references 일괄 정리: (a) state summary table의 모든 row를 v1.4(default 접힘) + v1.6(Hero tap) 반영하게 갱신, (b) state 2/3/4/5 mini-table의 사용자 액션·에지케이스·컴포넌트·노트 셀에서 "신청 답변 카드 자동 펼침/접힘" → "제출한 정보 default 접힘 / 토글 펼침" 표현으로 통일, (c) 변형 표(Step 4 결과)의 paid 행을 "신청 완료" terminal → "결제 완료" terminal (step 2개 압축) 으로 정정 — v1.5에서 첫 step "신청"으로 바뀌면서 "신청 완료" terminal과 충돌 해결, (d) approved 행을 "검토자 라인" → "ReasonBox 라벨=검토자 이름 / 본문=환영 메시지" (v1.3 통일 패턴) 으로 정정, (e) Background paragraph / Motion timing / Global edge cases / 접근성 조항에서 "신청 답변 카드" 표현 → "신청 step의 제출한 정보 collapsible"로 일괄 갱신. Spec ↔ mockup 동기화 확인 완료 — 모든 mockup HTML이 최신 결정사항 반영, spec text와 충돌 없음. |
| 2026-05-03 | 1.6 | mark-yun | Hero card tappable — 카드 전체가 InkWell · onTap → push EventDetailRoute. 이벤트명 옆에 chevron right 한 개로 시각 시그널. 모든 state에서 동일 동작 (Hero는 status에 무관). Body top padding 제거 — AppBar 바로 아래 불필요한 여백 제거. 첫 카드(Hero)가 AppBar에 더 붙어 시작감 ↑. 좌우 / 하단 padding은 그대로 유지 (spacing-medium). |
| 2026-05-03 | 1.5 | mark-yun | State 5 (결제 실패) 첫 step 카피 정정 — "신청 시도" → "신청". 다른 state와 동일 카피로 일관. snapshotData가 backend에 생성됐다면 신청 행위는 완료된 거고, 실패한 건 결제 단계뿐. "시도" prefix는 불필요한 mental gymnastics. |
| 2026-05-03 | 1.4 | mark-yun | 제출한 정보 collapsible default 접힘 통일 — 기존 status별 분기(pending_review/rejected 자동 펼침 / 그 외 접힘) 폐기. 모든 status / 모든 entry에서 default 접힘. 사용자가 명시적으로 토글 탭해야 펼침. 일관 동작 + 화면 진입 시 노이즈 ↓. 워딩 변경 — "답변 보기/닫기" → "제출한 정보 보기/닫기". "답변"이 Q&A처럼 모호했고, snapshotData가 텍스트 + 이미지 mix이므로 "정보"가 더 포괄적. 시점("제출한")으로 신청 wizard에서 입력한 것임을 명확히. 검토자 메모(같은 카드 내 다른 row)와 의미상 분리. |
| 2026-05-03 | 1.3 | mark-yun | 신청 답변 카드 폐기 → "신청" step 안 collapsible 통합 — snapshot_data가 submission attempt history array(entry당 신청 시도 1번)이라는 본질에 맞춰, 모든 entry를 timeline의 별도 "신청" step으로 노출. 각 step 안 collapsible content에 그 entry의 data + comments 포함. 별도 신청 답변 카드 삭제 (Sub-anatomy ③ 폐기) → 본문 카드 3 → 2. step 라벨은 단순 "신청" (1차/2차 분기 X — 시간순 노출로 자연 구분). 재제출은 entry 추가로 timeline이 자동 확장됨 — entries 사이 result='rejected'가 있으면 synthetic 거절됨 step 삽입. 검토자 코멘트 노출 — entry.comments가 있으면 답변 row 아래 1px divider + "검토자 메모" 라벨로 자연 구분. step heading inline 변경 — 기존 title 아래 줄 time 별도 → title + time이 한 줄에 inline (flex baseline · gap spacing-small). 메타데이터 가독성 ↑. 심사 진행 중 step의 time 제거 — "진행 중"이라 specific 시점 모호. 카피만 노출. 승인됨 step에도 ReasonBox 적용 — 기존 "검토: ..." 별도 라인을 ReasonBox 라벨/본문 형태로 통일 (검토자 메시지 톤). 별도 .ear-step__reviewer 클래스 폐기. |
| 2026-05-03 | 1.2 | mark-yun | ReasonBox 톤 다운 + 말풍선화 — (a) 좌측 3px error border 제거 · (b) bg 빨간색 6% tint → onSurface 4% subtle neutral 단일 스타일 (rejected/cancelled 색 분기 폐기) · (c) radius radius-small(8) → radius-medium(12) softer corners · (d) 라벨 자리에 일반 "사유" 대신 sender 이름(검토자 / 시스템 / 본인) — 별도 검토자 라인 폐기 후 흡수. CTA "다시 신청하기" 위치 변경 — 종결 step 내부 → timeline card 마지막 element(step 바깥, 카드 자체의 액션처럼). full-width filled 스타일은 그대로. step 내부 full width가 step의 일부로 안 보였던 이슈 해결. cancelled 사유 라벨 "시스템" / "본인" 분기 — 자동 취소 = "시스템", 사용자 직접 취소 = "본인". rejected = 검토자 이름. payment_failed = "시스템". |
| 2026-05-03 | 1.1 | mark-yun | Hero 디자인 부모 detail과 통일 — compact(이벤트명+일시)에서 풀 hero(thumb 16:9 + 제목 + 일시 + 장소)로 변경. 시각 일관성 우선. Timeline dot/line 정렬 보정 + dot 크기 축소 + step 간격 증가 — dot 14×14 → 12×12 (border-box), dot ↔ line center 일치 (둘 다 -22 center), step 간 gap spacing-large(24) → spacing-xlarge(32). Active step copy 변경 — "예상 결과 발표일" 대신 "이벤트 시작 시점까지 심사가 완료되지 않으면 자동 취소되며, 결제 금액은 자동 환불됩니다" — 사용자에게 더 의미 있는 안내. "다시 신청하기" CTA 스타일 변경 — OutlinedButton(primary border + transparent bg) → FilledButton(primary bg + white fg · full width 48px). 부모 detail의 예매 취소 버튼과 같은 시각 무게감. Cancelled state CTA 제거 — 사용자가 직접 취소했거나 시스템이 자동 취소한 케이스에서 즉각 재신청 prompt가 부자연스럽고, 자동 취소(이벤트 시작 도래)는 같은 이벤트 재신청 자체가 의미 없음. CTA는 rejected / payment_failed에서만 노출. snapshotData 실제 backend 스키마 확인 결과 반영 — Q&A list가 아니라 submission attempt history array (각 entry: submitted_at / data / comments / result). spec 안 ⚠ 박스로 명시. 재제출 history를 어떻게 표현할지(최근만 vs 전체 vs 재제출 시만)는 다음 iteration 결정 사항. |
| 2026-05-03 | 1.0 | mark-yun | v1.4 template으로 신규 작성. PurchaseHistoryDetailPage의 심사 상태 row가 push할 자식 spec. IA: Hero(compact) → Timeline card(메인 vertical stepper) → 신청 답변 card(collapsible). Timeline 단계: 신청 → 결제 → [심사 — 자격 심사 있는 이벤트만] → 결과/취소. 종결 step 안에 사유 + 검토자 + CTA "다시 신청하기" inline. 7 state 정의: 심사 진행 중 / 승인 완료 / 거절됨 / 취소됨(user/auto 통합) / 결제 실패 / Loading / Error. 자동 취소(이벤트 시작 도래 등)는 별도 state가 아니라 cancelled state의 reason 변형으로 흡수. |

[🧱 Layout](#layout) [🎨 States](#states) [🔄 Global Behavior](#global-behavior) [📖 Reference](#reference)

🧱

## Layout

AppBar + 스크롤 body(**2 카드 — Hero + Timeline**). Hero 카드는 부모 detail과 동일 디자인. 메인 Timeline 카드는 [`MinglitTimeline`](/components#MinglitTimeline) 컴포넌트(v1.8 promoted) · "신청" step 안 collapsible로 답변+검토자 메모 통합 (v1.3).

## Blueprint & tree

Scaffold + Material default AppBar (title "심사 상태") + MinglitAsyncValueWidget. data branch: 단일 EventApplication(+ joined VerificationSubmission)을 받아 Hero → Timeline 카드 2개 stack. Sticky CTA 없음 — "다시 신청하기"는 timeline 카드 마지막 element로 inline. v1.3에서 신청 답변 카드 폐기, "신청" step의 collapsible로 통합.

![blueprint](blueprint.png)

**Scaffold** └─ **AppBar**(_title: "심사 상태"_) ← ① └─ **MinglitAsyncValueWidget<EventApplication>** ├─ loading → **MinglitCircularProgressIndicator** ├─ error → **\_DefaultErrorView** └─ data → **SingleChildScrollView**(padding: _0 / spacing-medium / spacing-medium / spacing-medium_ · top 0 — v1.6) └─ **Column**(gap: _spacing-medium_) ├─ _Hero card_ ← ② └─ _Timeline card_ ← ③ _(신청 step 안 답변 collapsible · 종결 step 안 사유 · 카드 마지막 CTA "다시 신청하기")_

| # | Region | Alignment | Spacing |
|---|---|---|---|
| — | Body padding | — | SingleChildScrollView padding: top 0 (v1.6 — AppBar 바로 아래 첫 카드 시작) · 좌/우 spacing-medium (16px) · bottom spacing-medium (16px) |
| ① | AppBar | title left + auto back arrow | height: 56 · scaffold gray bg · border-bottom 없음 |
| ②③ | 본문 카드 (Hero + Timeline · v1.3에서 신청 답변 카드 폐기 후 2개) | full width · vertical stack | radius: radius-card (16px) · padding all: spacing-medium (16px) · shadow blur 8 offset (0,2) opacity shadowXs (0.06) · 카드 사이 gap spacing-medium (16px) |

## Sub-anatomy ① — Hero card (tappable · v1.6)

**v1.1: 부모 detail의 Hero 디자인 재사용** — thumb 16:9 + 이벤트명 + 일시 + 장소. 부모 detail과 동일 patterns/tokens. **v1.6: 카드 전체가 InkWell tappable → push EventDetailRoute** — 사용자가 "이 신청이 어떤 이벤트였는지" 더 깊이 보고 싶을 때 한 탭으로 이벤트 상세 진입. 시각 시그널은 이벤트명 옆 chevron right 한 개 (오른쪽 끝 정렬). InkWell ripple은 카드 전체에 적용. StatusBadge는 노출하지 않음 (부모 detail의 ② 심사 상태 row가 status indicator 담당, review 페이지는 timeline이 status 표현).

![blueprint](blueprint_2.png)

**InkWell**(onTap → push EventDetailRoute · v1.6) └─ **Container**(card chrome) └─ **Padding**(`spacing-medium`) └─ **Column**(crossAxis: start) ├─ _thumb_ ← ㉠ ├─ Gap: `spacing-medium` ├─ **Row**(crossAxis: start · gap small) │ ├─ _이벤트명_(flex 1) ← ㉡ │ └─ _chevron right_ (Icons.chevron\_right · 20 · onSurfaceVariant) ← ㉤ ├─ Gap: `spacing-xsmall` ├─ _일시_ ← ㉢ └─ _장소_ ← ㉣

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | thumb | full width · 16:9 | radius-medium (12px) · 누락 시 placeholder bg color-surface |
| ㉡ | 이벤트명 | start · flex 1 · maxLines 2 | typography titleLarge w700 |
| ㉤ | chevron right | flex-shrink 0 · 우측 끝 · 제목 baseline 살짝 위(margin-top 2px) | 20×20 · color color-text-secondary · gap from 제목 spacing-small (8px) |
| ㉢ | 일시 | start | typography bodyMedium |
| ㉣ | 장소 | start | typography bodyMedium · color color-text-secondary |

## Sub-anatomy ② — Timeline card (메인)

Vertical stepper. 단계 = 신청 → 결제 → \[심사 — 자격 심사 있는 이벤트만 노출\] → 결과(승인 / 거절 / 취소). 각 step은 dot + 연결 line + 라벨 + 시점 + (있으면) 추가 detail. **종결 step**에는 사유 박스 + 검토자 + CTA "다시 신청하기"가 inline. **미래 step은 노출하지 않음** — 현재 진행 중인 step까지만 (회색 미래 dot은 wizard 톤이라 review에 부적합). 진행 중 step은 active(primary color + pulsing dot)으로 강조.

![blueprint](blueprint_3.png)

**Container**(card chrome) └─ **Padding**(`spacing-medium`) └─ **Column**(crossAxis: stretch) ├─ _"진행 단계"_ ← ㉠ ├─ Gap: `spacing-medium` ├─ **MinglitTimeline** (v1.8 mds 컴포넌트 — vertical stepper · dot/line/heading은 컴포넌트 책임 · step 내부 children은 page-specific) │ ├─ **Step 신청** × _snapshot\_data.length_ ← ㉡ (각 entry당 1개) │ │ ├─ **Dot**(completed · success · 12×12 border-box) │ │ ├─ **Line**(아래 step과 연결 · 2px · color-divider) │ │ ├─ **Heading row** (inline · v1.3) │ │ │ ├─ **Text**(title "신청" · `bodyMedium` w600) │ │ │ └─ **Text**(time = entry.submitted\_at · `bodySmall` onSurfaceVariant) │ │ └─ **StepAnswers** (collapsible — v1.3 통합) │ │ ├─ **ToggleButton** "제출한 정보 보기/닫기" + chevron 14 (default 접힘 — v1.4) │ │ └─ _if expanded_ │ │ └─ **Container**(bg onSurface 4% · radius 12 · padding sm/medium) │ │ ├─ **AnswerRow** × N (data 항목별 — text / 이미지) │ │ │ ├─ **Text**(label · `labelSmall` w700 onSurfaceVariant uppercase) │ │ │ └─ **Text** 또는 **MinglitImage**(64×64 radius-small) │ │ └─ _if entry.comments.length > 0_ │ │ └─ **CommentRow** (위 1px divider) │ │ ├─ **Text**("검토자 메모" · labelSmall w700 onSurfaceVariant uppercase) │ │ └─ **Text**(comments join · bodySmall onSurface) │ ├─ **Step 결제** ← ㉢ │ │ ├─ **Dot** + **Line** │ │ └─ **Heading row** (inline title + time + amount) │ ├─ _entries 사이에 result='rejected'면_ │ │ └─ **Step 거절됨** (synthetic — 다음 신청 step과 분기) │ ├─ _if 자격 심사 있는 이벤트 + 마지막 entry result null_ │ │ └─ **Step 심사 진행 중** ← ㉣ │ │ ├─ **Dot**(active · primary · pulsing) + **Line** │ │ ├─ **Heading**("심사 진행 중" · primary · _time 미노출 · v1.3_) │ │ └─ **Text**(detail · "이벤트 시작까지 자동 환불 안내") │ └─ _if 종결 (승인 / 거절 / 취소 / 결제 실패)_ ← ㉤ │ └─ **Step 결과** (terminal · last · line 없음) │ ├─ **Dot**(success / error / neutral 분기) │ ├─ **Heading**(title + time) │ └─ _if 거절 / 취소 / 결제 실패 / 승인_ │ └─ **ReasonBox** (말풍선 톤 · v1.2) │ ├─ **Text**(label = sender — 검토자명 / "시스템" / "본인") │ └─ **Text**(본문 = 사유 또는 검토자 메시지) └─ _if rejected / payment\_failed (cancelled X · v1.2)_ └─ **FilledButton**("다시 신청하기" · primary · full width 48 · margin-top spacing-large)

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | 섹션 제목 | start | typography labelLarge w700 |
| ㉡㉢㉣㉤ | Timeline step | start · 좌측 32px(dot 영역) padding | step 사이 gap spacing-xlarge (32px) (v1.1 — was 24) · dot 12×12 border-box (v1.1 — was 14×14) radius 50% · dot ↔ line 정렬 보정 (dot left -28 · line left -23 · 둘 다 center -22) · line 2px width · line 색 color-divider |
| — | Step title | start | typography bodyMedium w600 · color: completed = onSurface · active = color-primary · failed = color-error · cancelled = onSurface |
| — | Step time | start | typography bodySmall · color color-text-secondary · 2px gap from title |
| — | ReasonBox (말풍선 톤 v1.2) | full width | padding spacing-sm v + spacing-medium h · radius radius-medium (12px) (softer corners) · 좌측 border 제거 (v1.2) · bg 단일 neutral subtle tint (onSurface 4% — rejected/cancelled 색 분기 폐기) · 라벨 자리 = sender (검토자 이름 / "시스템" / "본인" 등) · 본문 = 사유 텍스트 · 라벨 bodySmall (12px) w700 onSurfaceVariant · 본문 bodySmall (13px) onSurface line-height 1.5 · margin-top spacing-small |
| — | "다시 신청하기" CTA | full width · 가운데 정렬 | v1.2: timeline card 마지막 element로 이동 (step 내부 X) — step과 분리되어 카드 액션처럼 인지. FilledButton · height 48 · width 100% · bg color-primary · fg white · border 없음 · radius radius-button (12px) · typography labelLarge w600 · margin-top spacing-large (24px) from timeline. 부모 detail의 예매 취소 버튼과 같은 시각 무게감(forward-looking이라 destructive errorContainer 대신 primary). |

신청 lifecycle → MinglitTimelineStep tone 매핑 (review use case)

| 신청 상황 | tone | pulsing | 의미 / 사용 시점 |
|---|---|---|---|
| 이미 통과한 step (신청·결제 완료·승인됨) | success | — | color-success (초록) — 달성/통과된 단계 |
| 현재 진행 중 (심사 진행 중 / 결제 처리 중) | progress | true | color-primary + 1.4s pulse — "지금 여기" 강조 |
| 실패 종결 (결제 실패 / 거절됨) | error | — | color-error (빨강) — 종결되었으나 실패 |
| 취소 종결 (사용자 취소 / 자동 취소) | neutral | — | color-text-secondary — 종결됐으나 강조 안 함 |
| (미래 step) | muted | — | review에서는 미사용 — 현재까지만 노출. order tracking 등 다른 use case에서 활용 |

**note** — `tone`은 semantic-neutral. review 도메인의 lifecycle을 위 표대로 매핑해서 사용. 다른 use case (정산/배송/알림 등)는 자체 매핑.

Step 4 결과 — status별 변형

| application.status | dot 색 | title | 본문 (사유 박스 / CTA) |
|---|---|---|---|
| paid (자격 심사 X) | completed | 마지막 step "결제 완료" | 심사 step skip — 결제 완료가 terminal step. detail "이벤트 당일 체크인하세요" · CTA 없음 · 사실상 step 2개로 압축 (신청 → 결제 완료) |
| approved | completed | "승인됨" | ReasonBox 라벨 = 검토자 이름 (예: "강남 라운지 운영팀") · 본문 = 환영 메시지 (예: "신청 감사합니다. 이벤트 당일 뵙겠습니다.") · CTA 없음 · v1.3 — 별도 검토자 라인 폐기, ReasonBox로 통일 |
| pending_review | active (pulsing) | "심사 진행 중" | "이벤트 시작 시점까지 심사가 완료되지 않으면 자동 취소되며, 결제 금액은 자동 환불됩니다." · 마지막 step (terminal · 미완) · CTA 없음 · line 없음 (v1.1 — 예상 발표일 대신 자동 환불 안내로 변경) |
| pending · payment_pending | active | "결제 처리 중" | 결제 step에서 active 상태로 멈춤 · 그 위 신청 step은 completed · CTA 없음 |
| cancelled (사용자 직접) | cancelled | "취소됨" | ReasonBox 라벨 "본인" · 본문 "직접 취소했습니다" 또는 사용자 입력 사유 · CTA 없음 |
| cancelled (자동 — 이벤트 시작 도래) | cancelled | "취소됨" | ReasonBox 라벨 "시스템" · 본문 "이벤트 시작 시점에 도달하여 자동 취소되었습니다. 결제 금액은 자동 환불 처리됐어요." · CTA 없음 |
| cancelled (자동 — 심사 지연) | cancelled | "취소됨" | ReasonBox 라벨 "시스템" · 본문 "심사가 완료되지 못해 자동 취소되었습니다" · CTA 없음 |
| rejected | failed | "거절됨" | ReasonBox 라벨 = 검토자 이름 (예: "서울 숲 파티 운영팀") · 본문 = 파트너 거절 사유 (rejectionReason) · CTA "다시 신청하기" (timeline card 마지막 element) |
| payment_failed | failed | "결제 실패" | 결제 step에서 실패 · 그 위 신청 step만 completed · ReasonBox 라벨 "시스템" · 본문 "카드 인증 실패" 등 PG 응답 메시지 · CTA "다시 신청하기" |

**note** — 자동 취소(이벤트 시작 도래 / 심사 지연 등)는 별도 state로 빼지 않고 cancelled state의 reason 변형으로 통합. 사용자 직접 취소도 같은 step, reason만 다름. 카피는 backend가 setting하는 cancellation\_reason 필드(또는 동등) 그대로 노출 — 시스템 사유는 문장 그대로, 사용자 입력 사유는 따옴표로 감쌈.

## 신청 답변 — Sub-anatomy ② 안 통합 (v1.3)

**v1.3 변경: 별도 신청 답변 카드 폐기 → "신청" step 안 collapsible로 통합.** 이유: snapshotData가 submission entry 단위(각 entry = 1번의 신청 시도)이고, 사용자가 "내가 어떻게 여기까지 왔는지"를 timeline의 시간축 위에서 보는 게 자연. 별도 카드로 따로 두면 두 timeline(메인 진행 단계 + 답변 history)을 머리속에서 join해야 하는 부담.

실제 backend 스키마 (v1.1 확인 결과 · v1.3에서 history mode 채택)

snapshot\_data: \[
  {
    submitted\_at: "2026-03-15",         // ISO timestamp
    data: { university: "서울대", ... }, // verification 정의별 자유 key-value
    comments: \[\],                       // 검토자가 단 코멘트 array (v1.3: 사용자에게 노출)
    result: "rejected" | null,          // 그 시도의 결과
  },
  // 재제출 시 새 entry append
\]

**v1.3 채택 결정 사항**:

-   **모든 entry 노출** — array의 각 entry는 timeline의 별도 "신청" step으로. 1번 제출한 사용자는 step 1개, 재제출 사용자는 step 여러 개.
-   **각 entry의 data + comments**를 그 step의 collapsible 안에 함께 노출. 검토자 메모가 있으면 답변 row 아래에 1px divider + "검토자 메모" 라벨로 구분.
-   **step 라벨은 단순히 "신청"** — "1차/2차" 등 분기 안 함 (시간순으로 나열되면 자연스럽게 구분됨).
-   **entry 사이의 거절** — 첫 entry result='rejected' + 다음 entry 존재 시, 두 신청 step 사이에 "거절됨" 종결 step 형태로 자동 삽입 (단, 최근 result가 null이면 마지막 step은 active "심사 진행 중").
-   **default 접힘 (v1.4)** — 모든 status / 모든 entry에서 default 접힘. 사용자가 명시적으로 "제출한 정보 보기" 토글을 탭해야 펼쳐짐. status별 분기 폐기 — 일관 동작.

**verification field 메타 (key → user-facing label 매핑)**는 `Verification` 모델에 정의되어 있을 것 — 이벤트별로 항목이 다름. UI는 verification에서 받은 메타 + snapshot\_data.data를 join해서 친화적 라벨 노출. backend 스키마 확정 시 동기화 필요 (TBD).

data 안 항목 종류별 표시 형태

| data 안 항목 | 표시 |
|---|---|
| 텍스트 값 (자기소개 / 자유 답변 / 직업 등) | label + 본문 텍스트 (line-height 1.5) |
| 이미지 URL (인증 사진) | label + 64×64 thumbnail (radius-small) · 탭 시 풀스크린 모달 (Phase 2) |
| 선택지 (단일 / 다중) | label + 선택된 옵션 텍스트 (다중이면 쉼표 구분) |
| 날짜 / timestamp | label + "yyyy.MM.dd" 포맷 |
| comments (검토자 메모) | data row 아래 divider 1px + "검토자 메모" 라벨(uppercase) + 본문 (배열이 여러 개면 줄바꿈으로 join) |
| submitted_at | step의 inline time으로 노출 (heading 옆) |
| result | 다음 step(거절됨 등)의 존재로 표현. 별도 visual 없음. |

🎨

## States

7 state. Timeline 종결 step의 dot 색 / 사유 박스 / CTA 노출 / 신청 step 답변 펼침 default로 갈라짐. v1.3에서 신청 답변 카드를 timeline 안 통합. 자동 취소(시스템 사유)는 cancelled state에 reason 변형으로 흡수. 재제출 history는 entry당 step 추가로 자연스럽게 표현.

### State summary — 7 states

| State | Tag | 조건 | Key visual differentiator |
|---|---|---|---|
| Default · 심사 진행 중 | baseline | pending_review (또는 pending · payment_pending) | 마지막 step active (pulsing primary dot) · 종결 step 없음 · 제출한 정보 default 접힘 |
| Default · 완료 (paid / approved) | variant | paid (자격 심사 X · step 2개) 또는 approved (자격 심사 통과 · step 4개) | 모든 step completed · paid 마지막 "결제 완료" + detail("이벤트 당일 체크인") · approved 마지막 "승인됨" + ReasonBox 환영 메시지 · CTA 없음 · 제출한 정보 default 접힘 |
| Default · 거절됨 | variant | rejected | 마지막 step failed (error red dot) · ReasonBox 말풍선 톤 — 라벨 검토자 / 본문 거절 사유 · CTA "다시 신청하기" · 제출한 정보 default 접힘 (검토자 메모도 같이) |
| Default · 취소됨 | variant | cancelled (user / auto 통합) | 마지막 step cancelled (neutral) · ReasonBox 라벨 "시스템" 또는 "본인" · CTA 없음 (v1.1) · 제출한 정보 default 접힘 |
| Default · 결제 실패 | variant | payment_failed | 결제 step에서 failed · timeline 2 steps (신청 → 결제 실패) · ReasonBox 라벨 "시스템" · CTA "다시 신청하기" · 제출한 정보 토글 미렌더 가능 (snapshot 없으면) |
| Loading | async | fetch 중 | 화면 중앙 spinner |
| Error | network/server | 로드 실패 | error_outline icon + "오류가 발생했습니다." |

![visual](visual_1.png)

🔄

## Global Behavior

cross-cutting — 모든 state에 적용되는 액션, motion, 글로벌 에지케이스.

## Cross-cutting interactions

| 사용자 액션 | 화면에 보이는 결과 |
|---|---|
| 뒤로 가기 | 부모 PurchaseHistoryDetailPage로 복귀. |
| 다크 모드 토글 | scaffold / 카드 / dot / ReasonBox 모두 dark 토큰으로 swap. dot success/error/primary는 light/dark colorset 자동 대응. |
| 버튼 / row tap haptic | InkWell ripple + Material default haptic light. 카드 본체 자체는 tap 액션 없음 — 신청 답변 헤더, 종결 step CTA만 액션. |
| 풀-다운 새로고침 | 구현 안 함 — review는 본질적으로 historical view. 갱신은 부모 detail로 돌아갔다 다시 진입. |
| 부모 detail → 진입 | extra: application + submission 함께 push 권장. id만으로 deep-link도 허용 — 이때 Loading. |
| "다시 신청하기" tap (v1.10) | 이벤트 detail page로 push (모든 status에서 통일 동작 — rejected / payment_failed). detail이 이벤트 현재 상태(모집 중/종료/만석)를 보여주고 사용자가 detail의 신청 버튼 → wizard 또는 결제 재시도. backend 측은 Model 1 — 같은 applicationId 안 status 전환 + snapshot_data array append (history 누적). 새 application 생성 X. |
| Hero card tap (v1.6) | EventDetailRoute로 push — 이벤트 상세 페이지로 이동. 모든 state에서 동일 동작 (Hero card 자체는 status에 무관). 이벤트가 삭제됐으면 EventDetailPage가 ErrorView 표시 (별도 fallback 없음). |

## Motion timing

Source: `shared/packages/mds/core/lib/src/theme/minglit_design_tokens.dart` → `MinglitAnimation`.

| Transition | Token / Duration | Notes |
|---|---|---|
| 부모 detail → review push | MinglitAnimation.fast (200ms) | GoRouter Material default 좌→우 slide. |
| "제출한 정보" collapsible expand/collapse (신청 step 안) | MinglitAnimation.fast (200ms) | AnimatedSize 자동 ease + toggle chevron rotate 180°. |
| Active step dot pulse | (unscoped) 1.4s loop | opacity 1 → 0.5 → 1 + scale 1 → 0.85 → 1. 토큰 미정의 — ms 직접 명시. 현재 단계가 진행 중임을 시각 시그널. |
| "다시 신청하기" tap → 이벤트 detail push | MinglitAnimation.fast (200ms) | GoRouter default. detail에서 추가 신청 흐름은 EventDetailPage spec 참조. |
| InkWell ripple | MinglitAnimation.micro (100ms) | Material default ripple. |
| Step dot 색 변경 (status 변동 시) | cut | 화면 진입 시 한 번만 결정 — 진입 중 status 변경되면 재진입까지 갱신 안 됨. |

## Global edge cases

-   **application + submission 둘 다 fetch 필요** — application은 부모 detail에서 받아온 것 재사용 권장(extra push). submission은 별도 fetch 또는 application과 함께 join. submission 없으면 신청 step의 "제출한 정보 보기" 토글이 미렌더 (timeline은 그대로).
-   **자격 심사 없는 이벤트 (submission == null)** — 신청 step의 제출한 정보 토글 미렌더 + timeline의 "심사" step skip → step 2개로 압축 (신청 → 결제 완료, 결제가 terminal).
-   **cancellation\_reason / rejectionReason 시스템 vs 사용자 입력 구분** — backend가 시스템 사유는 plain text, 사용자 입력 사유는 quoted 또는 별도 flag로 구분. UI는 카피 어휘로 자연스럽게 ("자동 취소되었습니다" vs "직접 취소했습니다") — backend 스키마 확정 시 동기화 필요 (TBD).
-   **다크 모드** — 카드 bg → `color-dark-surface`, scaffold → `color-dark-background`, ReasonBox bg/border는 dark colorset 알파로 swap.
-   **접근성** — Active dot pulse는 시각 단서. screen reader에는 step title이 명확("심사 진행 중", "거절됨", "결제 실패") + reason 본문이 그대로 읽힘. 신청 step의 "제출한 정보 보기" 토글은 `aria-expanded` 적용 권장. Hero card는 `InkWell`이라 screen reader가 "버튼 — 이벤트 상세로 이동"으로 읽음.
-   **저성능 디바이스** — pulse animation이 부담될 수 있음 — `MediaQuery.of(context).disableAnimations` 시 pulse 제거하고 정적 dot으로 fallback.

📖

## Reference

implementation source + 인접 화면. 🚧 디자인중 — 미존재 항목은 TBD.

## Implementation source

| Widget class | EventApplicationReviewPage · TBD |
|---|---|
| File path | apps/app_user/lib/src/features/event/admission/event_application_review_page.dart · TBD |
| Controller | 부모 detail의 PurchaseHistoryController 재사용 (단일 application 조회) 또는 별도 EventApplicationReviewController 신규 — submission(VerificationSubmission) join 포함 · TBD |
| Route | EventApplicationReviewRoute · path: /purchase-history/:applicationId/review · TBD |
| Repository | eventRepositoryProvider.getApplicationById(id) + verificationRepositoryProvider.getSubmissionByApplicationId(id) · TBD |
| Async wrapper | MinglitAsyncValueWidget |
| Timeline 컴포넌트 | MinglitTimeline + MinglitTimelineStep (v1.8 promoted) — mds_core에 widget 신규 추가 필요 (TBD). step 내부 컨텐츠는 children slot으로 주입. |
| 신청 답변 위젯 | file-private _AnswersCard + _AnswerRow — collapsible (AnimatedSize · ExpansionTile 변형 또는 직접 구현) |
| "다시 신청하기" 라우팅 | EventDetailRoute(eventId)로 단일 push (v1.10 통일 동작). detail에서 status 분기 처리. |
| Icons (Material) | arrow_back · error_outline · expand_more (chevron — 답변 카드 toggle) · chevron_right (CTA 화살표) |

## 후속 작업 (이 review가 활성되려면 필요한 변경)

| 변경 항목 | 설명 |
|---|---|
| Flutter — 위젯 / 라우트 신규 | EventApplicationReviewPage + EventApplicationReviewRoute 추가 (app_user). 부모 detail의 심사 상태 row tap이 이 라우트로 push. |
| Backend — cancellation_reason 필드 표준화 | EventApplication에 cancellation_reason 컬럼 (또는 동등) 추가 + 시스템 사유 / 사용자 입력 사유 구분 (별도 enum 또는 flag). 현재 모델은 rejectionReason만 있음 — cancelled 케이스의 사유 표현 필드 부재. |
| Backend — review_started_at / reviewedAt 노출 | timeline의 "심사 진행" step time을 표시하려면 검토 시작 시점이 backend 응답에 있어야 함. 현재 VerificationSubmission.reviewedAt은 종료 시점만 — reviewStartedAt(또는 동등) 추가 필요. 또는 application의 updatedAt + 상태 전이 history로 유추. |
| Backend — snapshotData 스키마 확정 | 현재 List<dynamic> 자유형 — UI가 라벨/본문/이미지 매핑하려면 typed item structure 필요 (예: {type: 'text'\|'image'\|'choice', label: string, value: any}). |
| "다시 신청하기" 라우팅 로직 | v1.10에서 EventDetailRoute(eventId) 단일 push로 통일 — detail이 이벤트 현재 상태 + 신청 흐름을 처리. controller는 분기 없이 단순 push. |
| Backend — 재신청 / 결제 재시도 모델 (Model 1) | 같은 applicationId 안에서 status 전환 + snapshot_data array에 새 entry append (history 누적). 검토: (a) rejected / cancelled → pending_review 전환 허용, (b) payment_failed → paid 전환 허용, (c) DB 측 user_id × event_id unique constraint 여부 (있으면 Model 1 강제, 없으면 정책 결정 필요). 새 application 생성 모델(Model 2)은 history 분리되어 timeline의 의미 약해짐 — 채택 X. |
| Spec — 부모 detail의 후속 작업 표 업데이트 | PurchaseHistoryDetailPage의 후속 작업 표에서 "심사 상태 detail spec 신규" 항목 → 머지됨으로 표시 (이번 spec 머지 후). |

## Related screens

| Spec | Relation |
|---|---|
| PurchaseHistoryDetailPage | 부모 — 심사 상태 row tap 시 이 review page로 push. |
| PurchaseHistoryPage | 조부 — 리스트 → detail → review 흐름. |
| EventDetailPage | "다시 신청하기" CTA의 단일 push 대상 (v1.10). detail이 이벤트 현재 상태 + 신청 흐름을 통합 처리. |
| EventApplicationWizardPage | EventDetail의 신청 버튼 → 이 wizard로 push (간접). review에서 직접 진입하지 않음. |
| EventApplicationDetailPage (app_partner) | 대칭 화면 — 파트너가 보는 신청 detail. 같은 application을 다른 시점(파트너→신청자)에서 봄. 거절 사유 작성도 그쪽에서. |