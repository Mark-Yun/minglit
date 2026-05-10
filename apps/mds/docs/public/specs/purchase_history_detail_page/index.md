 Spec — PurchaseHistoryDetailPage (app\_user · PurchaseHistoryDetailRoute)  

# Purchase History Detail

## Overview

| Status | 🚧 디자인중 — PurchaseHistoryPage 카드 분리 제안. Flutter 미구현 (TBD). |
|---|---|
| App | app_user |
| Category | my · payment · history |
| Route / Surface | PurchaseHistoryDetailRoute · widget: PurchaseHistoryDetailPage (TBD) |
| Path | /purchase-history/:applicationId |
| Hierarchy | Parent: PurchaseHistoryPage (list 카드 tap 시 push)Children: PartnerDetailPage (파트너 정보 row tap), EventApplicationReviewPage (가칭 · 후속 spec — 심사 상태 row tap. 거절 사유 / 신청 답변 / 검토 시점) |
| Purpose | 결제 1건의 모든 정보를 한 화면에서 보여주고, "이 결제와 관련된 4가지 외부 진입점"(영수증 · 파트너 · 문의 · 심사 상태)을 모은 뒤 환불 정책 카드 안에서 정책 안내와 같은 자리에 예매 취소 버튼을 둬 환불을 진행한다. 이 페이지의 핵심 책임은 결제 정보 + 환불 정책(플랫폼/파트너 두 갈래) 안내. 거절 사유·신청 답변 같은 심층 정보는 한 뎁스 더 들어간 심사 상태 detail로 분리. |
| User journey | Entry points: PurchaseHistory 리스트 카드 tap (단일 진입점).Exit points: 4가지 outbound — ① 영수증 (외부 브라우저 · service.iamport.kr) · ② 문의하기 (시스템 dialer/메일앱) · ③ 파트너 detail push · ④ 심사 상태 detail push. 그 외: "예매 취소" tap → MinglitDialog confirm → cancelOrder EF → 성공 시 list로 복귀 · 뒤로 가기 → list로 복귀. |
| Background | 기존 PurchaseHistoryPage 카드는 1장이 곧 미니 상세 — 카드마다 errorContainer 빨간 버튼이 박혀 list 전체가 위험 신호로 도배되고, 1장이 짊어진 책임 과다(식별 + 다단계 액션)가 누적된 결과로 분리. 이 detail은 정보 과다를 막기 위해 심층 정보(거절 사유 / 신청 답변)를 본문에 펴지 않고 심사 상태 detail로 위임. 본문은 결제·환불·관련 페이지 진입에 집중. 환불 정책은 두 갈래 — 플랫폼 환불 정책(정책 단계표 + 카드 내 예매 취소 버튼으로 진행) + 파트너 직접 환불(자동 환불 외 케이스 안내). 두 갈래 모두 단일 카드에 묶음. 파트너 환불 안내 옆에 별도 CTA는 두지 않고, 바로 아래 ⑤ 파트너 정보 카드의 "문의하기"로 일원화(v1.3) — 동일 페이지 안에서 같은 launcher가 두 번 나오는 중복 제거. 심사 상태는 ② 자리에 배치 — Hero(① 식별)에서 결제 상태(StatusBadge)를 분리해 status는 status 섹션에 모았다. 사용자 인지 흐름: "어떤 이벤트 → 지금 어떤 상태 → 얼마/언제 냈나 → 누구한테 → 환불은 어떻게." |
| Frequency | 리스트에서 1건을 골랐을 때만 — 결제 1건당 0-2회 (영수증 확인 + 환불/문의 결심 시). |

## History

이 spec의 주요 변경 이력. 최신 항목 위.

| Date | Version | Author | Changes |
|---|---|---|---|
| 2026-05-03 | 1.8 | mark-yun | State 4 (결제 실패) 결제 정보 카드 라벨 정정 — "결제 금액" → "결제 시도 금액". 결제 자체가 일어나지 않은 케이스에서 "결제 금액"이라는 표현이 misleading. 이미 적용된 "결제일 → 결제 시도일" 패턴과 동일한 결로 일관 처리. |
| 2026-05-03 | 1.7 | mark-yun | 예매 취소 버튼 위치 미세 조정 — 환불 정책 카드 안에서 버튼 위치를 "카드 마지막"에서 "플랫폼 정책 ↔ 파트너 직접 환불 사이 (divider 위)"로 이동. 흐름이 "정책 안내 → 액션(버튼) → divider → 자동 환불 외 대안 안내"로 정렬되어 카드 안에서 정보→액션→대안 사이클이 자연스럽게 마무리됨. 파트너 직접 환불 섹션은 항상 노출 — 처음에 disabled일 때만 노출하는 옵션도 검토했으나, active 사용자가 "다른 환불 경로"의 존재를 모를 수 있다는 discoverability 우려로 두 상태 모두 노출 유지. |
| 2026-05-03 | 1.6 | mark-yun | 예매 취소 버튼을 환불 정책 카드 안으로 이전 — sticky BottomCTA 제거. 카드 마지막 element로 위치(margin-top spacing-medium · height 48 · radius-button). "정책을 본 직후 같은 카드에서 액션" 흐름. canCancel false면 미렌더가 아니라 disabled로 노출 — Material default disabled tokens (onSurface 5%/38%) 사용해 암묵적 합의 UI 그대로 활용. disabled 버튼이 마지막 단계 highlight 바로 아래 위치해 "왜 안 되는지" self-explain. errorContainer를 유지하면서 opacity만 낮추는 방식은 채택 X (모호한 시그널 회피). State별 처리 — 1: active / 2: disabled / 3: 카드 swap으로 미렌더 / 4: 카드 미노출로 미렌더 / 5: "신청 취소 안내" 카드 안 동일 패턴(카피만 "신청 취소"). body의 80px bottom padding 제거, sticky CTA 영역 제거 — 화면 밀도 ↑. |
| 2026-05-03 | 1.5 | mark-yun | 심사 상태 row trail에 RefundBadge 추가 — refundStatus != 'none'일 때 StatusBadge 옆에 두 번째 badge 노출 ("환불 완료" neutral / "환불 처리 중" warning / "환불 실패" error). cancelled / rejected는 backend가 자동으로 'refunded' 동기화 → 두 badge 항상 함께. State 4를 payment_failed 단독으로 좁힘 — 도메인 가정에 따라 cancelled / rejected는 항상 refundStatus 'refunded'를 동반하므로 State 3(환불 완료)에 통합. State 4는 결제 자체가 실패한 케이스(paymentId 없음, 환불 개념 자체 없음)만 담음. mockup도 결제 실패 예시로 변경. Sub-anatomy ② status 표 보강 — "함의되는 refundStatus" 컬럼 추가 + RefundBadge 별도 표 + status × refundStatus 조합 가이드 문단 추가. |
| 2026-05-03 | 1.4 | mark-yun | 심사 상태 row 2-line ListTile로 확장 — 라벨 아래에 subtitle "마지막 업데이트: {relative time}" 추가 (VerificationSubmission.reviewedAt 또는 application.updatedAt 기준 · 방금/N분 전/N시간 전/N일 전/N주 전/yyyy.MM.dd 단계 포맷). 사용자가 detail로 진입하지 않고도 "최근 변동" 시점을 인지. 심사 상태 명세 보강 — Sub-anatomy ②에 8 status 분기마다 "사용자 관점 의미 + 다음 단계" 컬럼 추가. cancelled / rejected는 보통 자동 환불을 동반함을 명시. 환불 완료 카드 → 환불 정보 카드로 통합 — refundStatus 'refunded' 상태에서 결제 정보 카드를 미노출하고, 환불 정책 카드를 "환불 정보" 카드로 swap. 카드 내용을 결제 정보 + 환불 결과 통합(티켓 · 결제 금액 · 환불일 · 환불 비율 · 환불 금액 · 수수료) — 한 카드에서 "원래 얼마 → 얼마 돌려받음" 비교 가능. 영수증 버튼도 그쪽으로 이전. |
| 2026-05-03 | 1.3 | mark-yun | 환불 정책 카드 정리 — 카피 변경: "환불 정보" → "환불 정책", "플랫폼 자동 환불" → "플랫폼 환불 정책". 현재 단계 highlight를 primary color tint + h-padding(12px) 강조 → label/value 모두 bold로 변경 (색·padding 변경 없음 — row 정렬 어긋남 방지). 파트너 환불 CTA 제거 — "파트너 문의하기 →" 버튼 삭제. 파트너 환불 안내는 안내 문구만 남기고, 문의 진입은 ⑤ 파트너 정보 카드의 "문의하기"로 일원화 (동일 launcher 중복 제거). 카드 순서 재배치 — 환불 정책 ↔ 파트너 정보 swap. 새 순서: Hero → 심사 상태 → 결제 정보 → 환불 정책 → 파트너 정보. "이 결제는 환불 어떻게 되는데? 안 되면 → 바로 아래 파트너에게 직접 연락" 자연 흐름. |
| 2026-05-03 | 1.2 | mark-yun | IA 미세 조정 — StatusBadge를 Hero에서 심사 상태 row로 이관. status는 status 섹션에 모음. 심사 상태 row를 ② 자리로 이동(기존 ④). row 내부 패턴: [심사 상태 · StatusBadge · ›] · "자세히" 텍스트 제거(chevron이 affordance 충분). 보조 액션 톤 다운 — 영수증 / 문의하기 TextButton 색을 color-primary(브랜드) → color-text-primary(검정/짙은 회색)으로. plain TextButton 위계. 여백 정리 — 결제 정보 / 파트너 정보 카드의 보조 액션 row에서 margin-top: spacing-medium 제거. divider가 마지막 row 바로 아래 붙고, 버튼 padding-top만 유지. |
| 2026-05-03 | 1.1 | mark-yun | IA 재정렬 — 5섹션 + BottomCTA로 재구성. 파트너 정보 카드 신규(프로필+이름+소개+chevron+문의하기), 심사 상태 row 신규(상태 무관 일관 카피 + chevron · 심사 상태 detail로 push), 환불 정책 카드를 플랫폼 환불 정책 + 파트너 직접 환불 두 섹션으로 통합. canCancel 조건 확장 — 기존 paid/approved만 → paid/approved + pending/pending_review 추가 (파트너 미수락 단계에서도 유저 측 자유 환불 가능). Flutter PurchaseHistoryController.isActiveTicket 변경 필요 (후속 PR). refundStatus 'refunded' state 신규 — 환불 정책 카드 → 환불 완료 카드(환불일/비율/금액/수수료)로 swap. 거절 사유 안내 박스 제거 (심사 상태 detail로 위임). |
| 2026-05-02 | 1.0 | mark-yun | v1.4 template으로 신규 작성. PurchaseHistoryPage 카드의 책임 과다(식별 + 결제 상세 + 다단계 액션 + 위험 액션)를 분리하기 위한 detail 화면 초안. Hero / 결제 정보 / 환불 정책 / BottomCTA(예매 취소) 4섹션. 7 state 정의. |

[🧱 Layout](#layout) [🎨 States](#states) [🔄 Global Behavior](#global-behavior) [📖 Reference](#reference)

🧱

## Layout

AppBar + 스크롤 body(5 카드). 본문 카드 사이 vertical medium(16) gap. 카드는 흰 배경 + radius-card(16) + 약한 drop shadow. 예매 취소 액션은 sticky BottomCTA가 아니라 **환불 정책 카드 안 마지막 element**로 통합 (v1.6 — canCancel false면 disabled).

## Blueprint & tree

Scaffold + Material default AppBar (title "구매 상세") + MinglitAsyncValueWidget. data branch: 단일 EventApplication을 받아 Hero → 심사 상태 → 결제 정보 → 환불 정책 → 파트너 정보 5개 카드를 vertical stack으로 출력. **예매 취소는 환불 정책 카드 안 마지막 element**로 위치 — sticky BottomCTA 없음. **v1.3: 정보 흐름 재정렬** — "이건 어떤 이벤트인가 → 지금 어떤 상태인가 → 얼마/언제 냈나 → 환불은 어떻게 가능한가 → (자동 환불 외) 누구에게 직접 연락하나" 순. 환불 정책이 파트너 정보보다 위에 있어야 "자동 환불 안 되면 → 파트너에 직접 연락" 흐름이 자연스럽게 시선에 걸림. **v1.6: 예매 취소 카드 내 통합** — 환불 정책을 본 직후 같은 카드 안에서 액션 가능. canCancel false일 때 sticky 버튼이 사라지는 게 아니라 **같은 자리에 disabled로 노출** — "왜 안 되는지" 정책 마지막 단계 highlight와 직관적으로 연결됨.

![blueprint](blueprint.png)

**Scaffold** └─ **AppBar**(_title: "구매 상세"_) ← ① └─ **MinglitAsyncValueWidget<EventApplication>** ├─ loading → **MinglitCircularProgressIndicator** ├─ error → **\_DefaultErrorView** └─ data → **SingleChildScrollView**(padding all _spacing-medium_) └─ **Column**(gap: _spacing-medium_) ├─ _Hero card_ ← ② ├─ _심사 상태 row card_ ← ③ ├─ _결제 정보 card_ ← ④ ├─ _환불 정책 card_ (예매 취소 버튼 포함) ← ⑤ └─ _파트너 정보 card_ ← ⑥

| # | Region | Alignment | Spacing |
|---|---|---|---|
| — | Body padding | — | SingleChildScrollView padding all: spacing-medium (16px) — sticky CTA 없으므로 bottom 추가 padding 불필요 (v1.6) |
| ① | AppBar | title left + auto back arrow | height: 56 · scaffold gray bg · border-bottom 없음 |
| ②③④⑤⑥ | 본문 5 카드 | full width · vertical stack | radius: radius-card (16px) · padding all: spacing-medium (16px) · shadow blur 8 offset (0,2) opacity shadowXs (0.06) · 카드 사이 gap spacing-medium (16px) |
| ⑤ 내부 | 예매 취소 버튼 | full width · 카드 마지막 element | height 48 · margin-top spacing-medium · radius radius-button (12px) · active: bg color-error 12% tint + fg color-error · disabled: bg onSurface 5% + fg onSurface 38% + cursor not-allowed (Material default) |

## Sub-anatomy ① — Hero card

이벤트 식별 영역. 큰 thumbnail + 제목/일시/장소를 세로로 쌓음. **StatusBadge는 Hero에 두지 않음** — status 시각 indicator는 ③ 심사 상태 row에 모음. 이로써 Hero는 "이건 어떤 이벤트인가?" 한 가지 질문에만 답함.

![blueprint](blueprint_2.png)

**Container**(card chrome) └─ **Padding**(`spacing-medium`) └─ **Column**(crossAxis: start) ├─ _thumb_ ← ㉠ ├─ Gap: `spacing-medium` ├─ _이벤트명_ ← ㉡ ├─ Gap: `spacing-xsmall` ├─ _일시_ ← ㉢ └─ _장소_ ← ㉣

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | thumb | full width · 16:9 | radius-medium (12px) · 누락 시 placeholder bg color-surface |
| ㉡ | 이벤트명 | start · maxLines 2 | typography titleLarge w700 |
| ㉢ | 일시 | start | typography bodyMedium |
| ㉣ | 장소 | start | typography bodyMedium · color color-text-secondary |

## Sub-anatomy ② — 심사 상태 row card

현재 결제 상태(StatusBadge)와 심사 detail 진입을 단일 row에 묶음. **2-line ListTile** — 위에 라벨 "심사 상태", 아래에 마지막 업데이트 상대 시간(`application.updatedAt` 또는 `VerificationSubmission.reviewedAt` 기준 · "방금" / "{N}시간 전" / "{N}일 전" / "{yyyy.MM.dd}"). 라벨은 **status에 따라 분기하지 않음** — 항상 "심사 상태". status별 시각 indicator는 inline StatusBadge로, 심층 정보(거절 사유 / 신청 답변 / 검토 시점)는 한 뎁스 더 들어간 [`EventApplicationReviewPage`](/specs/event_application_review_page/index.html)(가칭)에서. "자세히" 텍스트는 의도적으로 제거 — chevron이 tappable affordance 충분히 전달. **v1.4 추가**: subtitle "마지막 업데이트: ..." — 사용자가 carrier로 진입하지 않고도 신청·심사·환불 처리의 최근 활동 시점을 인지.

![blueprint](blueprint_3.png)

**Container**(card chrome · padding all `spacing-medium`) └─ **InkWell**(onTap → push EventApplicationReviewRoute) └─ **Row**(spaceBetween · center crossAxis · gap `spacing-medium`) ├─ **Column**(crossAxis: start · gap 2px) │ ├─ **Text**("심사 상태" · `bodyLarge` w500) ← ㉠ │ └─ **Text**("마지막 업데이트: {relative}" · `bodySmall`) ← ㉡ └─ **Row**(`spacing-small` gap · center) ← ㉢ ├─ **StatusBadge**(application.status · 8 분기) ├─ _if refundStatus != 'none'_ → **RefundBadge**(refundStatus) │ _("환불 완료" · neutral / "환불 처리 중" · warning / "환불 실패" · error)_ └─ **Icon**(Icons.chevron\_right · onSurfaceVariant)

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | "심사 상태" 라벨 | start | typography bodyLarge w500 · color color-text-primary |
| ㉡ | 마지막 업데이트 시간 | start | typography bodySmall · color color-text-secondary · gap 2px (㉠과 사이) |
| ㉢ | trail (StatusBadge + chevron) | center · 사이 gap spacing-small (8px) | StatusBadge 토큰: radius-small (8px) v-padding spacing-xsmall h-padding spacing-sm · chevron 18 onSurfaceVariant · 전체 InkWell ripple |

마지막 업데이트 — 데이터 소스 + 상대 시간 포맷

| 조건 | 표시 |
|---|---|
| 심사 처리된 적 있음 (VerificationSubmission.reviewedAt 존재) | reviewedAt 기준 상대 시간 |
| 심사 처리 전 | application.updatedAt 기준 상대 시간 (결제·신청·자동 동기화 등 가장 최근 변경) |
| 1분 미만 | "방금" |
| 1시간 미만 | "{N}분 전" |
| 24시간 미만 | "{N}시간 전" |
| 7일 미만 | "{N}일 전" |
| 4주 미만 | "{N}주 전" |
| 그 이상 | "{yyyy.MM.dd}" (절대 날짜) |

StatusBadge — application.status 8 분기 · 함의되는 환불 상태

| application.status | status badge 라벨 / 색 | 함의되는 refundStatus | 사용자 관점 의미 | 다음 단계 |
|---|---|---|---|---|
| paid | "결제완료" / success | 'none' (정상) — 환불 badge 없음 | 결제 완료, 입장권 확보됨. 자격 심사 없는 이벤트. | 이벤트 당일 체크인. 환불은 환불 정책 카드 내 "예매 취소" 버튼. |
| approved | "승인됨" / success | 'none' (정상) — 환불 badge 없음 | 파트너가 신청 승인. 결제도 완료. | 이벤트 당일 체크인. |
| pending_review | "심사 중" / warning | 'none' (정상) — 환불 badge 없음 | 파트너 검토 중. 결제는 끝났고 승인 대기. | 알림 대기. 본인 의사로 취소도 가능. |
| pending · payment_pending | "결제 대기" / info | 'none' (정상) — 환불 badge 없음 | 결제 처리 중 (PG 응답 대기). | 잠시 후 자동 갱신. |
| cancelled | "취소됨" / neutral | 'refunded' (정상) — "환불 완료" badge 함께 노출 | 사용자가 직접 취소 → 자동 환불 처리됨. | 없음 — 환불 정보 카드 확인 또는 새 이벤트. |
| rejected | "거절됨" / error | 'refunded' (정상) — "환불 완료" badge 함께 노출 | 파트너가 신청 거절 → 자동 환불 처리됨. | 심사 detail에서 거절 사유 확인. 결제는 환불됨. |
| payment_failed | "결제 실패" / error | 'none' (환불 개념 자체 없음) — 환불 badge 없음 | 결제 자체 실패 (카드/잔액/네트워크). 결제 행위 없음. | 다른 결제 수단으로 새 신청 (별도 흐름). |
| 그 외 (예외) | "알수없음" / neutral | — | backend가 알 수 없는 status 반환. 이론상 발생 X. | 새로고침 또는 고객센터. |

RefundBadge — refundStatus별 별도 badge (status badge 옆에 함께 노출)

| refundStatus | badge 라벨 / 색 | 표시 조건 |
|---|---|---|
| 'none' (default) | — | badge 미노출 (환불 행위가 없거나 진행 중 아님) |
| 'refunded' | "환불 완료" / neutral | cancelled / rejected와 함께 — 자동 환불 처리 완료 |
| 'refund_pending' (가칭 · backend TBD) | "환불 처리 중" / warning | 환불 EF 호출 후 PG 응답 대기 — 잠깐 보일 수 있음 |
| 'refund_failed' (가칭 · backend TBD) | "환불 실패" / error | 환불 시도 실패 — 사용자가 고객센터로 우회 필요 |

**note — application.status × refundStatus 조합 가이드**  
· `cancelled`·`rejected` 는 backend가 자동으로 `refundStatus = 'refunded'`로 동기화 → 두 badge가 항상 함께 (status badge + "환불 완료"). 이 케이스는 화면이 **State 3(환불 완료)**로 분류되어 결제 정보 카드 미노출 + 환불 정보 카드 노출.  
· `payment_failed` 는 결제 자체가 안 됐으므로 환불 개념 없음 (refundStatus 'none' 유지) → 환불 badge 미노출. 화면은 **State 4(결제 실패)**로 분류되어 결제 정보 카드만 노출, 영수증 버튼은 paymentId 없어 자동 미노출.  
· cancelled / rejected에서 refundStatus가 'none'인 경우는 비정상 — backend 일관성 문제. spec 기본 가정 외, 후속에서 처리.

## Sub-anatomy ③ — 결제 정보 card

결제 1건의 raw fact + 영수증 진입. KeyValueRow 패턴 — label은 onSurfaceVariant, value는 onSurface. 결제 금액은 강조(w700). 카드 하단 1px divider 바로 아래 "영수증" plain TextButton — 외부 브라우저로 iamport 영수증 페이지 열기. **v1.2: divider와 마지막 KV row 사이 여백 제거** · **버튼 색 검정 톤(plain)**.

![blueprint](blueprint_4.png)

**Container**(card chrome) └─ **Padding**(`spacing-medium`) └─ **Column**(crossAxis: stretch) ├─ _"결제 정보"_ ← ㉠ ├─ Gap: `spacing-medium` ├─ _KeyValueRow list_ ← ㉡ │ ├─ **MinglitKeyValueRow**("결제일", "yyyy.MM.dd HH:mm") │ ├─ **MinglitKeyValueRow**("티켓", ticket.name ?? "티켓 정보 없음") │ └─ **MinglitKeyValueRow**("결제 금액", "{amount}원" · value strong) ├─ **Divider**(1px · margin-top 0 · 마지막 KV row의 padding-bottom 그대로 유지) └─ _if paymentId 있음_ ← ㉢ └─ **TextButton**("영수증" full width · color `color-text-primary` · padding-top `spacing-medium`)

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | 섹션 제목 | start | typography labelLarge w700 |
| ㉡ | KeyValueRow list | spaceBetween (label ↔ value) | row v-padding spacing-sm · 사이 1px color-divider · label bodyMedium onSurfaceVariant · value bodyMedium w500 · 결제 금액 value bodyLarge w700 |
| ㉢ | 영수증 버튼 | full width · 가운데 정렬 | height 40 · color color-text-primary (v1.2 · 검정/짙은 회색 plain) · typography labelLarge w500 · padding-top spacing-medium · top border 1px color-divider · margin-top 0 |

## Sub-anatomy ④ — 환불 정책 card

두 갈래 환불 정책을 단일 카드로 안내. 상단 "플랫폼 환불 정책"은 RefundCalculator 정책(grace\_period\_hours / cutoff\_days · 기본 2/7)을 4단계 row로 풀어 보여주고 현재 시점 단계를 **label/value 모두 bold**로 강조 (v1.3 — 색·padding 강조 제거 · 정렬 어긋남 방지). 중간 "파트너 직접 환불"은 자동 환불 외 케이스에서 파트너에게 직접 연락하는 안내만 (CTA 버튼은 ⑤ 파트너 정보 카드의 "문의하기"로 일원화 — v1.3에서 중복 CTA 제거). **v1.6: "예매 취소" 버튼을 카드 안으로 통합** — 정책을 본 직후 같은 카드 안에서 액션. canCancel 충족 시 active(errorContainer), 미충족 시 disabled(Material default 회색). disabled 상태가 단계 row 바로 아래 위치해 "왜 안 되는지" 시각적으로 self-explain. **v1.7: 버튼 위치 — 플랫폼 정책과 파트너 직접 환불 사이**로 이동. 버튼 아래에 divider + 파트너 직접 환불 안내가 옴. 흐름: "정책 → 액션 → (자동 환불 외) 대안 안내". 파트너 직접 환불 안내는 active / disabled 두 상태 모두 노출 — 사용자가 카드 진입 전부터 "다른 환불 경로" 존재를 인지하도록 (discoverability). **v1.4: refundStatus가 'refunded'면 이 카드와 결제 정보 카드 둘 다 사라지고, 두 정보가 합쳐진 "환불 정보" 카드 1개로 swap** — 결제 정보(티켓·결제 금액)와 환불 결과(환불일·환불 비율·환불 금액·수수료)를 한 카드에서 비교 가능. 영수증 버튼도 그쪽으로 이전 (paymentId 있을 때). 환불 완료 카드에는 예매 취소 버튼 자체가 없음.

![blueprint](blueprint_5.png)

**Container**(card chrome) └─ **Padding**(`spacing-medium`) └─ **Column**(crossAxis: stretch) ├─ _"환불 정책"_ ← ㉠ ├─ Gap: `spacing-medium` ├─ _플랫폼 환불 정책 섹션_ │ ├─ **Text**("플랫폼 환불 정책" · `labelSmall` w700 onSurfaceVariant · uppercase) ← ㉡ │ ├─ Gap: `spacing-small` │ └─ _단계별 row × 4_ ← ㉢ │ _(현재 단계 row만 label/value 모두 w700 — 색·bg·padding 변경 없음)_ ├─ _예매 취소 버튼_ ← ㉣ │ └─ **FilledButton**("예매 취소" · width 100% · height 48 · margin-top `spacing-medium`) │ ├─ _if canCancel_ → enabled · errorContainer bg / onErrorContainer fg │ └─ _else_ → disabled · onSurface 5% bg / onSurface 38% fg · cursor not-allowed ├─ **Divider**(1px) + `spacing-medium` v-margin _(버튼과 파트너 환불 안내 사이 명확한 구분)_ └─ _파트너 직접 환불 섹션_ ├─ **Text**("파트너 직접 환불" · `labelSmall` w700 onSurfaceVariant · uppercase) ← ㉤ └─ **Text**("자동 환불 기간 외에도 파트너에게 환불 요청 가능" · `bodySmall`) ← ㉥ _(CTA 버튼 없음 — 바로 아래 ⑤ 파트너 정보 카드의 "문의하기" 사용 · 항상 노출 — discoverability 확보)_

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | 섹션 제목 | start | typography labelLarge w700 |
| ㉡㉤ | 서브 헤딩 | start | typography labelSmall w700 · color color-text-secondary · uppercase · letter-spacing 0.04em |
| ㉢ | 플랫폼 단계별 row × 4 | spaceBetween | row v-padding spacing-xsmall · h-padding 0 (모든 row 동일 — v1.3) · label bodyMedium onSurface · value bodyMedium w500 onSurfaceVariant · 현재 단계 row: label w700 + value w700 (색은 동일 유지 — 차분한 강조) |
| ㉣ | 예매 취소 버튼 | full width · 가운데 정렬 | height 48 · radius radius-button (12px) · margin-top spacing-medium · typography labelLarge w600 · active: bg color-error 12% tint + fg color-error · disabled: bg onSurface 5% tint + fg onSurface 38% tint + cursor not-allowed (Material default) · v1.7: 위치가 플랫폼 정책 ↔ 파트너 직접 환불 사이로 이동 — divider가 버튼 아래에 위치하여 "정책 → 액션 → (자동 환불 외) 대안" 흐름 자연스러움 |
| ㉥ | 파트너 환불 안내 | start | 안내 bodySmall · color color-text-primary · CTA 없음 · active/disabled 모두 노출 (v1.7 — discoverability 확보 위해 항상) |

예매 취소 버튼 — canCancel 분기 · 노출 방식

| 상태 조건 | 버튼 표시 | 적용 state |
|---|---|---|
| canCancel == true | active — errorContainer · 탭 시 환불 확인 다이얼로그 (state 8) | State 1 (활성 + 환불 가능) |
| canCancel == false (자동 환불 기간 종료 / 시작 후) | disabled — Material 회색 · 탭 무반응 · cursor not-allowed | State 2 (환불 기간 종료) |
| refundStatus == 'refunded' | 버튼 미렌더 — 카드 자체가 "환불 정보" 카드로 swap | State 3 (환불 완료) |
| status == payment_failed | 버튼 미렌더 — 환불 정책 카드 자체 미노출 | State 4 (결제 실패) |
| 무료 티켓 (paymentAmount 0 + paymentId 없음) | "신청 취소 안내" 카드 안에 동일 패턴 — 카피만 "신청 취소"로 미세 조정. 시작 전 active, 시작 후 disabled | State 5 (무료 티켓) |

**note — disabled 시각**: Material default disabled tokens 사용 (별도 disabled colorset 신규 정의 X). 이로써 "비활성화된 버튼"이라는 암묵적 합의 UI를 그대로 활용 — 사용자가 학습 비용 없이 인지. errorContainer 색을 유지한 채 opacity만 낮추는 방식은 채택하지 않음 ("빨간 액션이지만 잠겨있다"는 모호한 시그널을 피하기 위해).

플랫폼 환불 정책 단계 row 라벨 — 정책값에 따라 동적

| 단계 | label 패턴 | value |
|---|---|---|
| 1. Grace 기간 내 | "결제 후 {graceHours}시간 이내" | "100% 환불" |
| 2. Cutoff 이전 | "이벤트 시작 {cutoffDays}일 이전" | "100% 환불" |
| 3. Cutoff 이내 ~ 시작 직전 | "이벤트 시작 {cutoffDays}일 이내" | "부분 환불 (RefundCalculator 비율)" |
| 4. 시작 후 | "이벤트 시작 후" | "자동 환불 불가" |

**note** — 정확한 단계 비율(50/80/100 등)은 `RefundCalculator` 로직과 일치해야 함. 정책 조회 실패 시 default(grace 2h / cutoff 7d) fallback (Fix #133).

## Sub-anatomy ⑤ — 파트너 정보 card

파트너 식별 + 두 갈래 진입(파트너 detail · 문의하기). 상단 row 전체가 tap target — 작은 원형 프로필 + 파트너명 + 한 줄 소개 + 우측 chevron으로 "이 파트너에 대해 더 알아보기" 시그널. 하단 1px divider 바로 아래 "문의하기" plain TextButton — 시스템 dialer/메일앱 연결. **v1.3: 환불 정책 카드 바로 아래 위치** — "자동 환불 안 되면 → 파트너에 직접 연락" 흐름이 시선에 자연스럽게 걸리도록.

![blueprint](blueprint_6.png)

**Container**(card chrome) └─ **Padding**(`spacing-medium`) └─ **Column**(crossAxis: stretch) ├─ _"파트너"_ ← ㉠ ├─ Gap: `spacing-medium` ├─ _파트너 row_ (InkWell · onTap → PartnerDetail) ← ㉡ │ ├─ **CircleAvatar**(48 · partner.profileImageUrl ?? placeholder) │ ├─ Gap: `spacing-medium` │ ├─ **Expanded**(Column) │ │ ├─ **Text**(partner.name · titleSmall w700 · maxLines 1 ellipsis) │ │ └─ **Text**(partner.introduction ?? "" · bodySmall onSurfaceVariant · maxLines 1 ellipsis) │ └─ **Icon**(Icons.chevron\_right · onSurfaceVariant) ├─ **Divider**(1px · margin 0) └─ **TextButton**("문의하기" full width · color `color-text-primary` · padding-top `spacing-medium`) ← ㉢

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | 섹션 제목 | start | typography labelLarge w700 |
| ㉡ | 파트너 row | center · gap medium | avatar 48×48 radius 50% · 누락 시 placeholder bg color-surface + 아이콘 onSurfaceVariant · name titleSmall w700 · intro bodySmall onSurfaceVariant · chevron 18 onSurfaceVariant · 전체 InkWell |
| ㉢ | 문의하기 버튼 | full width · 가운데 정렬 | height 40 · color color-text-primary · typography labelLarge w500 · padding-top spacing-medium · top border 1px color-divider · margin-top 0 |

파트너 row · 데이터 누락 시 변형

| 조건 | 표시 |
|---|---|
| profileImageUrl 없음 | placeholder 아이콘 (Icons.storefront 또는 Icons.person · onSurfaceVariant) |
| introduction 없음 | 두 번째 line 자체 미렌더 — name 1행만 노출 |
| partner 자체 누락 | 카드 전체 미렌더. 이 경우 "문의하기" 진입점이 사라짐 — 사용자는 환불 정책 카드의 안내 문구만 보고 다른 경로(고객센터 등)로 우회 |

## canCancel 판정 — Flutter 후속 변경 필요

"예매 취소" 버튼은 Sub-anatomy ④ 환불 정책 카드 안에 통합되었음 (v1.6). canCancel 판정 로직은 그대로 — true면 active, false면 disabled로 노출. **v1.1 확장**: 활성 status 화이트리스트에 `pending`, `pending_review` 추가 — 파트너 미수락 단계에서도 유저는 자유롭게 환불(=신청 취소) 가능. 현재 Flutter `isActiveTicket`은 paid/approved만 — 후속 PR에서 확장 필요.

| 조건 | 결과 |
|---|---|
| status ∈ {paid, approved, pending, pending_review} | 활성 티켓으로 간주 — 기존 paid/approved에 pending/pending_review 추가 |
| refundStatus == 'none' | 중복 환불 방지 |
| eventStartTime > now | 이벤트 시작 전만 |
| 유료(paymentAmount > 0 \|\| paymentId 있음): paymentId/paymentAmount/eventStartTime 모두 not-null | iamport 환불 호출 가능 |
| 무료(paymentAmount == 0 && paymentId 없음): eventStartTime not-null | user-cancel-order EF가 무료 케이스 분기 처리 (Fix #1652) |

🎨

## States

8 state. baseline = Default · 활성 + 환불 가능. 변형은 환불 정책 카드 내 예매 취소 버튼 active/disabled / 환불 정책 카드 노출 여부 / 환불 완료 swap / 심사 상태 row의 StatusBadge 색으로 갈라짐.

**State 종류 식별 기준**: `MinglitAsyncValueWidget`의 3-way + data 안에서 결제 상태(`application.status`) + 환불 상태(`application.refundStatus`) + 환불 가능 여부(`canCancel`) + 무료/유료(`paymentId` 유무)로 분기.

### State summary — 8 states

| State | Tag | 조건 (요약) | Key visual differentiator |
|---|---|---|---|
| Default · 활성 + 환불 가능 | baseline | 활성 (paid/approved/pending/pending_review) + 시작 전 + 자동 환불 기간 내 | 환불 정책 카드 현재 단계 highlight + 카드 내 예매 취소 버튼 active (errorContainer) + 심사 상태 badge success |
| Default · 환불 기간 종료 | variant | 활성이지만 시작 후 또는 자동 환불 기간 만료 | 환불 정책 카드 마지막 단계 highlight + 카드 내 예매 취소 버튼 disabled (Material 회색) + 파트너 환불 안내 강조 |
| Default · 환불 완료 | variant | refundStatus == 'refunded' (보통 cancelled / rejected와 함께) | 결제 정보 카드 미노출 · 환불 정책 → 환불 정보 카드로 통합 swap (티켓·결제 금액·환불 결과 모두 포함) · 예매 취소 버튼 미렌더 · 심사 상태 badge neutral/error + RefundBadge "환불 완료" |
| Default · 결제 실패 | variant | payment_failed (환불 개념 없음) | 환불 정책 / 환불 정보 카드 둘 다 미노출 + 영수증 미노출(paymentId 없음) + 예매 취소 버튼 미렌더 + 심사 상태 badge error |
| Default · 무료 티켓 | variant | paymentAmount 0 + paymentId 없음 + 활성 + 시작 전 | 영수증 버튼 미노출 · 결제 금액 0원 · 환불 정책 → "신청 취소 안내" 카드 단순화 + 카드 내 "신청 취소" 버튼 active |
| Loading | async | fetch 중 | 화면 중앙 spinner |
| Error | network/server | 로드 실패 | error_outline icon + "오류가 발생했습니다." |
| Refund Confirm Dialog | overlay | "예매 취소" tap → 정책 조회 → refundPercentage > 0 | 본문 위 scrim + MinglitDialog |

![visual](visual_1.png)

🔄

## Global Behavior

cross-cutting — 모든 state에 적용되는 액션, motion, 글로벌 에지케이스.

## Cross-cutting interactions

| 사용자 액션 | 화면에 보이는 결과 |
|---|---|
| 뒤로 가기 | 구매 내역 리스트로 복귀. |
| 다크 모드 토글 | scaffold / 카드 / dialog 모두 dark 토큰으로 swap. StatusBadge는 light/dark colorset 분리. 예매 취소 버튼 disabled 색도 dark onSurface 알파로 자동 swap. |
| 버튼 / row tap haptic | InkWell ripple + Material default haptic light. 카드 본체 자체는 tap 액션 없음 — 심사 상태 row / 파트너 row / 영수증 / 문의 / 예매 취소 버튼만 액션. |
| 풀-다운 새로고침 | 구현 안 함 — 단일 결제 detail이라 갱신은 (a) 환불 성공 후 list로 복귀 (b) 화면 재진입. |
| 리스트 → detail push (entry) | list 카드 tap → extra: application으로 함께 push 권장. applicationId만으로 deep-link도 허용 — 이때 Loading. |
| 외부 url_launcher 실패 | browser·dialer·메일앱 부재 시 launchUrl false → showMinglitWarning 토스트. |

## Motion timing

Source: `shared/packages/mds/core/lib/src/theme/minglit_design_tokens.dart` → `MinglitAnimation`.

| Transition | Token / Duration | Notes |
|---|---|---|
| list → detail push | MinglitAnimation.fast (200ms) | GoRouter Material default 좌→우 slide. |
| 심사 상태 row tap → 심사 detail push | MinglitAnimation.fast (200ms) | 동일 GoRouter 패턴. |
| 파트너 row tap → PartnerDetail push | MinglitAnimation.fast (200ms) | 동일 GoRouter 패턴. |
| "예매 취소" tap → MinglitDialog show | MinglitAnimation.medium (350ms) | fade + scale-in. |
| EF cancelOrder 진행 중 | — | 화면 전체 dim + spinner (글로벌 로딩 오버레이). |
| 환불 성공 → list로 복귀 + invalidate | cut | Navigator.maybePop + ref.invalidate. detail 화면 unmount. |
| InkWell ripple | MinglitAnimation.micro (100ms) | Material default ripple. |
| 예매 취소 버튼 active/disabled (canCancel 변동) | cut | 화면 진입 시 한 번만 결정 — 시간 경과로 false 전환 시 재진입까지 갱신 안 됨. disabled 전환 시 fade 등 transition 없음 (re-render). |

## Global edge cases

-   **paidAt 누락** — webhook 처리 전이면 null. `paidAt ?? createdAt` fallback (Fix #579 패턴). 무료 티켓에서는 결제 정보 카드 첫 행 라벨이 "신청일"로 미세 조정.
-   **환불 정책 조회 실패** — 기본 정책(grace 2h / cutoff 7d) fallback (Fix #133 패턴).
-   **이벤트 시작 후 cancel 시도** — canCancel false면 환불 정책 카드 안 예매 취소 버튼이 disabled로 노출 (cursor not-allowed). 시간 경과 자동 재계산 안 됨 — 재진입 시 갱신.
-   **중복 invalidate 방지** — onSuccess(maybePop) 후 invalidate (Fix #1951 패턴).
-   **contactOptions 누락** — phone/email 모두 없으면 "연락처 정보가 없습니다" 토스트만. ④ 파트너 카드 + ⑥ 환불 정책 카드의 "문의하기"가 동일 fallback 경로.
-   **파트너 정보 누락** — ⑤ 파트너 정보 카드 자체 미렌더 → 화면에서 "문의하기" 진입점이 사라짐. 환불 정책 카드의 안내 문구는 그대로 노출되지만 사용자는 다른 경로(고객센터 등)로 우회. _v1.3에서 환불 정책 카드의 CTA를 제거했기 때문에, 파트너 카드가 미렌더되면 in-app 문의 경로 자체가 끊김 — 후속 PR에서 fallback CTA(고객센터 등) 추가 검토 필요._
-   **iamport 영수증 URL 의존성** — Phase 2에서 backend가 보낸 receipt URL 사용 검토.
-   **다크 모드** — 카드 bg → `color-dark-surface`, scaffold → `color-dark-background`.
-   **접근성** — 예매 취소 버튼 라벨 명확("예매 취소" / 무료는 "신청 취소"). disabled 상태도 screen reader가 "비활성화됨"을 읽을 수 있게 `aria-disabled` 또는 native `disabled` 속성 사용. 환불 정책 현재 단계 highlight는 색에만 의존하지 않고 row 위치/bold로도 식별 가능. 심사 상태 row의 StatusBadge 색은 8 status 분기가 명확한 라벨과 함께 노출됨.

📖

## Reference

implementation source + 인접 화면. 🚧 디자인중 — 미존재 항목은 TBD.

## Implementation source

이 spec과 매칭되는 실제 Flutter source 위치. Status 🚧 디자인중이므로 대부분 TBD.

| Widget class | PurchaseHistoryDetailPage · TBD |
|---|---|
| File path | apps/app_user/lib/src/features/payment/ui/purchase_history_detail_page.dart · TBD |
| Refund row atom | _RefundRow — list spec의 purchase_history_refund_row.dart를 detail part로 이관 권장 |
| Controller | PurchaseHistoryDetailController · 또는 list와 동일 PurchaseHistoryController 재사용 · TBD |
| Route | PurchaseHistoryDetailRoute · path: /purchase-history/:applicationId · TBD |
| List entry | app_routes.dart의 PurchaseHistoryRoute 하위로 추가 |
| Repository | list와 동일 — eventRepositoryProvider.getMyPurchaseHistory(userId)로 받은 list에서 단일 application을 push (extra) · 또는 getApplicationById(id) 별도 정의 · TBD |
| Cancel EF | eventRepositoryProvider.cancelOrder(eventId, reason) — list spec과 동일 EF 재사용 |
| Policy repository | policyRepositoryProvider.getRefundPolicy() — Fix #133 fallback |
| Refund calculator | RefundCalculator.calculate(...) |
| Async wrapper | MinglitAsyncValueWidget |
| StatusBadge | StatusBadge = MinglitBadge · 8 status 분기 (심사 상태 row 내부에 inline) |
| 예매 취소 버튼 | 환불 정책 카드 내 FilledButton(또는 ElevatedButton) — Material default disabled style 적용 · 별도 MinglitBottomCta 미사용 (v1.6) |
| KeyValueRow | MinglitKeyValueRow — 결제 정보 / 환불 완료 카드 |
| MinglitDialog | MinglitDialog.show<T> — 환불 confirm |
| External launcher | url_launcher.launchUrl — 영수증·tel:·mailto: |

## 후속 작업 (이 detail이 활성되려면 필요한 변경)

이 spec은 **이번 PR에서 spec만 머지** · 아래 변경은 별도 후속 PR.

| 변경 항목 | 설명 |
|---|---|
| Flutter — canCancel 조건 확장 | PurchaseHistoryController.isActiveTicket의 status 화이트리스트에 pending, pending_review 추가. 파트너 미수락 단계에서도 유저가 자유롭게 환불(=신청 취소) 가능하게. |
| Flutter — detail 위젯/라우트 신규 | PurchaseHistoryDetailPage + PurchaseHistoryDetailRoute 추가. list 카드 위젯의 _onCancelPressed / _showRefundConfirmDialog / _showRefundErrorDialog + part 'purchase_history_refund_row.dart'를 detail로 이관. |
| Spec — list spec 슬림화 | PurchaseHistoryPage 카드 sub-anatomy 축소: header(date · StatusBadge) + info(thumb · 제목 · 일시 · 장소) + 우측 chevron만. divider/pay-row/actions row 제거. 카드 자체가 tap target. State 5(Refund Confirm Dialog) 제거 — detail spec 단일 정의. |
| Spec — 심사 상태 detail 신규 (가칭) | event_application_review_page.html 신규 spec — 거절 사유(rejectionReason) / 신청 답변 스냅샷(VerificationSubmission.snapshotData) / 검토 시점(reviewedAt) / 검토자(reviewedBy) / 단계별 진행 표시. 라우트 path: /purchase-history/:applicationId/review 등. |
| Spec — 파트너 detail 확인 | PartnerDetailPage 존재 여부 확인 · 미존재 시 별도 spec 작업 필요. |
| Backend — refundedAt 컬럼 | State 3(환불 완료)의 환불 완료 카드 첫 행 "환불일"이 표시 가능하려면 EF 응답 또는 EventApplication에 환불 처리 시점 필요. 현재 refundStatus만 있고 시점 컬럼 없음 — DB 마이그레이션 또는 응답 enrichment 필요. |

## Related screens

| Spec | Relation |
|---|---|
| PurchaseHistoryPage | 부모 — list 카드 tap 시 detail push. |
| PartnerDetailPage | 자식 — 파트너 row tap 시 push. |
| EventApplicationReviewPage (가칭) | 자식 — 심사 상태 row tap 시 push. 거절 사유 / 신청 답변 / 검토 시점 등. |
| MyTicketsPage | 형제 — active 티켓만. Phase 2에서 동일 detail로 deep-link 가능. |
| EventDetailPage | EventApplicationWizard 결제 완료 후 detail로 직접 push redirect 가능 (Phase 2). |
| LoginPage | 비로그인 deep-link 시 RLS 차단 → Error state. |