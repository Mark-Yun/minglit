 Spec — EventDetailPage (app\_partner · EventDetailRoute)  

# Partner Event Detail

## Overview

| Status | ✅ 디자인완료 — 6 state · 파트너 이벤트 운영(티켓 관리 + 참가 신청 심사) 단일 진입점 |
|---|---|
| App | app_partner |
| Category | event · partner ops · 운영 관리 + 신청 심사 |
| Route / Surface | EventDetailRoute · widget: EventDetailPage (+ _EventInfoTab · _HeroDetailRow / _MetaDetailRow internal widgets) |
| Path | /parties/:partyId/events/:eventId |
| Hierarchy | Parent: PartyDetailPage (이벤트 카드 탭 시 push)Children: EventEditRoute (Hero "일정" 영역 탭 — 이벤트 정보 수정) · TicketCreateRoute (Add 카드 탭) · TicketEditRoute (티켓 카드 탭) · EventApplicationReviewDialog (심사 대기 카드 탭 — 다이얼로그) |
| Purpose | 파트너가 자신의 파티에 속한 단일 이벤트를 한 화면에서 운영하도록 한다 — 좌측 탭(운영 관리)에서는 일정 / 정원 / 상태 / 공개 설정 같은 핵심 메타를 한눈에 보고 그 아래에서 입장권을 추가하거나 수정할 수 있고, 우측 탭(참가 신청)에서는 들어온 신청을 심사 대기 / 처리 완료로 묶어 빠르게 승인 · 거절할 수 있다. |
| User journey | Entry points: PartyDetailPage의 이벤트 카드 탭 → 이 화면 진입 (운영 관리 탭이 기본).Exit points: AppBar back → 파티 상세 / Hero "일정" 영역 탭 → EventEditPage (이벤트 정보 수정) / Add 카드 (또는 빈 상태 카드) → TicketCreatePage / 티켓 카드 탭 → TicketEditPage / 신청 카드(심사 대기) 탭 → 심사 다이얼로그 → 승인/거절 후 같은 화면 머무름 / "참가 신청" 탭 전환 → 같은 페이지 안에서 본문 교체. |
| Background | 이 화면은 user app의 EventDetailPage와 같은 이벤트를 보지만 관점이 정반대다 — user는 "이 이벤트에 참여할까?"를 결정하고, partner는 "이 이벤트가 잘 굴러가고 있나, 누구를 받을까?"를 결정한다. 그래서 partner 쪽은 이미지 캐러셀 / 환불 정책 / CTA 바 같은 영업 톤 요소가 모두 빠지고, 대신 운영용 메타 표 + 티켓 CRUD 진입점 + 신청 심사 입구의 3 블록만 남긴다. 파티 단위로 묶인 여러 이벤트 중 하나에 대한 "운영 데스크"라고 보면 된다. |
| Frequency | 운영 중인 이벤트 1건당 활성기 동안 다회 — 신청이 들어올 때마다 알림을 받고 진입해 심사한다. 신청자 많은 이벤트는 일 단위로, 한산한 이벤트는 행사 직전 1~2회로 사용량이 갈린다. |

## History

이 spec의 주요 변경 이력. 최신 항목 위.

| Date | Version | Author | Changes |
|---|---|---|---|
| 2026-05-01 | 1.0 | mark-yun | v1.4 template으로 신규 작성. 파트너 brand color (#6c3ce1) viewport-scoped override. 3 state(Default · Loading · Error) → mini-table per state, additive diff. Tab 구조 폐기 후 참가 신청은 별도 라우트(EventApplicationListRoute)로 분리. 4 sub-anatomy (AppBar · Title block · Detail info card · Tickets section) + 1 visual zoom-in (Detail info card 상태별 톤). 참가 신청 도메인은 별도 라우트(EventApplicationListRoute)로 분리. |

[🧱 Layout](#layout) [🎨 States](#states) [🔄 Global Behavior](#global-behavior) [📖 Reference](#reference)

🧱

## Layout

화면 구조 — 영역, 정렬, 간격 규칙. 색·타이포 무시.

## Blueprint & tree

Scaffold = AppBar(title '이벤트 상세') + body(이벤트 데이터 비동기 로드 → 단일 스크롤 페이지). 본문은 세 섹션으로 명확히 분리된다: (1) **Hero 카드** — 일정(D-day trail) + 상태 · 탭 → [EventEditRoute](/specs/event_edit_page/index.html). (2) **참가 현황 섹션** — 이벤트 전체 분수(큰 22+px count) + 누적 CapacityBar([MinglitCapacityBar](/components#MinglitCapacityBar)) + breakdown + _심사 대기 ≥1일 때_ "심사 대기 N건 처리하기 →" 링크(탭 → [EventApplicationListRoute](/specs/event_application_list_page/index.html) · 그룹 필터 없음). (3) **입장 그룹별 현황 섹션** — 입장 그룹 카드 × N(각 그룹: 이름 + 분수 + 누적 CapacityBar + breakdown + 그룹 티켓 row × N(_각 row에 발행률 mini CapacityBar_) + "이 그룹에 티켓 추가" 버튼 · 카드 자체 탭 → EventApplicationListRoute(groupId)). 그 아래 공개 설정 footer 마이크로 텍스트. TabBar / 하단 네비게이션 / CTA 바 없음 — leaf route. 참가 신청 도메인은 별도 라우트로 분리되며, 전체 진입(참가 현황 카드)과 그룹별 진입(그룹 카드) 모두 같은 EventApplicationListRoute로 라우팅 — 그룹별 진입 시만 groupId 파라미터로 필터.

![blueprint](blueprint.png)

**Scaffold** ├─ **appBar**: AppBar ← ① │ ├─ leading: BackButton (auto) │ └─ title: Text('이벤트 상세') · centerTitle: false (TabBar 없음 — 단일 스크롤) └─ **body**: `MinglitAsyncValueWidget<Event>` ├─ loading: `MinglitCircularProgressIndicator` ├─ error: Centered text ('이벤트 로드 실패') └─ data: **SingleChildScrollView** ← ②③④⑤⑥ └─ `MinglitContentLayout`(sections: \[ ├─ **\_TitleRow**(Row · padding small top + h-screen-edge) ← ②a title row │ └─ Text(event.title) _· 20px w600 · color-text-primary_ │ ├─ **\_MetaChipLine**(Row · spacing-xsmall · padding small top + h-screen-edge · title 아래) ← ②b chips │ · **InkWell**(onTap: showToast(visibilityDescription)) │ └─ **MinglitChip**(label: '공개'/'비공개', tone: 공개→success / 비공개→outline, │ leadingIcon: 공개→globe / 비공개→lock, │ interactive: true) /\* 탭 시 설명 토스트 \*/ │ · **MinglitChip**(label: status, tone: scheduled→accent · cancelled→error · completed→outline) │ · **MinglitChip**(label: 'D-N', tone: warning) /\* 시간 임박 — 주황 \*/ │ ├─ **\_EditRow**(Row justify-end · padding small top + h-screen-edge) ← ②c edit row │ └─ **InkWell**(onTap: push [EventEditRoute](/specs/event_edit_page/index.html)) │ └─ Row('정보 수정 ›' · 13px w600 primary) /\* Hero 카드 바로 위, 우측 \*/ │ ├─ Padding(_screenEdge h_) → Container(radius-card · borderless) ← ③ │ └─ **\_InfoBlocks**(Column · spacing-medium) \[ /\* stacked blocks \*/ │ ├─ **\_InfoBlock**('일정') │ │ ├─ caption 12px w500 secondary ('일정') │ │ ├─ primary 16px w600 primary ('YYYY.MM.DD (E)') │ │ └─ secondary 13px secondary ('오후 H:MM ~ H:MM') │ └─ **\_InfoBlock**('장소') │ ├─ caption 12px w500 secondary ('장소') │ ├─ primary 16px w600 primary (event.location.name) │ ├─ secondary 13px secondary (event.location.address) │ ├─ **\_KakaoMapThumb**(height 100 · radius-input) /\* SDK 임베드 \*/ │ │ · static 또는 light interactive map · 핀 = event.location.geoPoint │ │ · onTap → 외부 맵 앱 deep-link (kakaomap://place?id= or maps:?q=) │ │ · spec mock에서는 grid + 보라 핀으로 placeholder 표현 │ └─ **\_Directions**('오시는길') /\* 자유 텍스트 \*/ │ ├─ label 11px w600 secondary ('오시는길') │ └─ text 13px primary · multiline (도보·입구·주차·랜드마크) │ \] ├─ `MinglitSection`(title: '참가 현황') ← ④ │ └─ Padding(_screenEdge h_) → **EventApplicationStatsCard**(event) ← ⑤ │ ├─ Row(spacing-large gap) \[ /\* 메트릭 한 줄 통합 \*/ │ │ Metric(count event.confirmedCount '24px w700' + label '/ N 확정' '13px w500 secondary'), │ │ Metric(count event.pendingCount + label '심사대기' · count에 pulse 강조 ≥1), │ │ Metric(count event.refundedCount + label '환불완료' · 정적 — 액션 X) │ │ \] /\* refundedCount = refund\_status IN ('completed') \*/ │ ├─ **MinglitCapacityBar**( │ │ total: event.totalCapacity, │ │ filled: event.confirmedCount, │ │ pending: event.pendingCount) │ └─ **\_Actions**(Column · spacing-small · margin-top small) \[ │ if event.pendingCount > 0: │ **InkWell**(onTap: push EventApplicationListRoute(anchor: pending)) │ └─ **\_ReviewCtaButton**('심사하기' · primary fill · h44 · radius-button) │ /\* 항상 노출 — 환불 요청 등 유저별 비정형 액션 진입 \*/ │ **InkWell**(onTap: push EventApplicationListRoute /\* no filter \*/) │ └─ **\_ApplicantsCtaButton**('참가자 보기' · outline primary · h44 · radius-button) │ \] │ ├─ `MinglitSection`(title: '기대 매출') ← ⑥ │ └─ Padding(_screenEdge h_) → **\_RevenueSummaryCard**(event) │ ├─ _전체 매출_ │ │ ├─ Row(event.currentRevenue 22px w700 + '/ 최대 event.maxRevenue' 13px secondary) │ │ ├─ **MinglitCapacityBar**(continuous, │ │ │ total: maxRevenue, filled: currentRevenue, pending: pendingRevenue) │ │ └─ Row(현재 KKK원 · 심사 승인 시 +KKK원) │ └─ _그룹별 매출_ (Divider · top-border · padding-top medium) │ for each entryGroup in event.entryGroups: │ Column(spacing-xsmall) \[ │ Row(group.name 13px secondary, group.currentRevenue 14px w600 primary, '/ 최대 group.maxRevenue' 12px secondary) │ **MinglitCapacityBar**(continuous · height 6, │ total: group.maxRevenue, filled: group.currentRevenue, pending: group.pendingRevenue) │ \] │ └─ `MinglitSection`(title: '입장 그룹별 현황') ← ⑦ └─ Padding(_screenEdge h_) → **EntryGroupListContainer**(border + radius) for each entryGroup in event.entryGroups: ← ⑧ if not first: Divider(full-width · color-divider) **InkWell**(onTap: push EventApplicationListRoute(groupId: g.id)) └─ Padding(spacing-large v · spacing-medium h) → **EntryGroupSection**(group) ├─ Row(group.name + Row(count + '/ N 확정') + chevron) ├─ **MinglitCapacityBar**( │ total: group.capacity, │ filled: group.confirmedCount, │ pending: group.pendingCount) ├─ Row(확정 N · 대기 M · 환불 R) /\* 0인 항목은 노이즈, 표시 X \*/ │ _(group-level alert 폐기 — 참가 현황 섹션이 대체)_ ├─ **\_NestContainer**(passthrough — 보더 각 티켓이 보유) │ └─ Column(spacing-small) \[ │ for each ticket in group.tickets: │ **InkWell**(onTap: push [TicketEditRoute](/specs/ticket_edit_page/index.html)(ticketId)) │ └─ Container( │ border-left: 3px neutral-gray @ 15%, /\* 티켓별 bar — primary 톤과 의미 분리 \*/ │ padding: small v · medium left, /\* 16px indent \*/ │ child: Column(spacing-small) \[ │ Row( │ Column\[ticket.name _(14px w600)_ │ + '판매 N · 대기 M / 발행 K장' _(12px secondary)_\], │ ticket.price _(14px w600)_, │ chevron\_right _(14 secondary)_ /\* 탭 affordance \*/ │ ) │ **MinglitCapacityBar**( /\* mini · height 4 — 판매+대기/발행 \*/ │ total: ticket.issuedQuantity, │ filled: ticket.soldQuantity, │ pending: ticket.pendingQuantity) │ \]) │ _탭 시 가격 / 발행수 수정 가능. 티켓별 분리된 좌측 bar로 single ticket도 명확한 티켓 단위 느낌_ │ \] └─ **\_GroupAddTicketButton**(group) _nest 밖 — full-width_ · dashed primary border · h44 · radius-button · '+ 이 그룹에 티켓 추가' · indent 없음 (그룹 본체와 같은 폭 — 그룹 자체에 속한 액션이라 들여쓰기 안 함) · onTap → push [TicketCreateRoute](/specs/ticket_create_page/index.html)(groupId: g.id) \] \]) ※ 공개 설정 chip은 이벤트 title 우측에 inline (상단 즉시 확인) — footer 폐기. _티켓 정원 정책_: 티켓 발행 총수 ≥ 입장 그룹 정원. UI는 발행수가 정원 미만이면 안내(보강 권고). "남은 정원만큼 더 발행" 같은 cap 메시지 사용 X — 추가 발행은 항상 가능.

## Spacing & alignment rules

| # | Region | Alignment | Spacing |
|---|---|---|---|
| ① | AppBar | height 56 · row crossAxis center · 좌측 정렬 타이틀 | back left: spacing-xsmall (4) · title↔back gap: 0 (BackButton width 흡수) |
| ② | Event title | 좌측 정렬 · multi-line | h-padding: spacing-screen-edge (16) · 위 spacing-medium (16) |
| ④ | Detail info card | 풀폭 with screen-edge h-margin · column | h-margin: spacing-screen-edge (16) · padding: spacing-medium (16) all · radius: radius-card (16) · row 사이 divider top/bottom spacing-small (8) |
| ⑤ | Tickets section | 풀폭 · column stretch | section header padding: spacing-medium top · 카드 사이 spacing-small (8) · 카드 h-margin: spacing-screen-edge |

## Event title block anatomy (②)

운영 관리 탭의 첫 줄 — 이벤트 제목이 단독 블록으로 떠 있다. 화면 좌우 가장자리에서 16px 떨어져 있고, 한 줄에 안 들어가면 자연스럽게 줄바꿈되며 글자 크기가 줄지 않는다. 파트너 보라색 + 굵은 헤드라인 톤으로 화면에서 가장 시각적 무게가 큰 요소 — 사용자가 "지금 운영 중인 이벤트가 무엇인지" 즉시 인지하게 하는 앵커. 이벤트에 제목이 비어있으면 이 블록 자체가 사라지고 그 아래 카드가 위로 붙는다.

![blueprint](blueprint_2.png)

**Padding**(_screenEdge h_ · top: 0) └─ **Text**(event.title) ← ㉠ · style: _headlineSmall_ · weight: _FontWeight.bold_ · color: _colorScheme.primary (partner #6c3ce1)_ · 줄바꿈 가능 (maxLines 미지정) _표시 조건:_ · event.title이 비어있지 않으면 노출 · 비어있으면 블록 통째로 사라지고 그 아래 카드가 위로 붙음 (Padding 자체가 sections 배열에 포함되지 않음) _※ user app 쪽 EventDetailPage의 hero 이미지 위에 떠 있는 타이틀과 달리, partner는 운영 페이지라 시각 무게를 본문 첫 줄에 둔다 — 이미지 캐러셀 없음._

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | Event title | 좌측 정렬 · multi-line | typography headlineSmall bold · color color-primary (partner) · h-pad spacing-screen-edge (16) · 하단 spacing-medium (다음 카드 사이) |
| — | 제목 없는 케이스 | — | 블록 미노출 — 카드가 위로 collapse |

## Hero 영역 anatomy (②③)

페이지 최상단의 Hero 영역은 **4단 구조**로 분리: **(1) Title row** — 이벤트 title(20px w600 · 일반 톤) 단독. AppBar 바로 아래 페이지 정체성을 명확히. **(2) Meta chip line** — title 바로 아래에 _stable→dynamic 순서_로 **공개 설정 chip**(공개 → 🌐 globe icon + success 초록 / 비공개 → 🔒 lock icon + outline 회색 · set-once · _탭 시 설명 토스트_) → 상태 chip(모집 → success 초록 / 취소 → error 빨강 / 완료 → success 초록) → D-day chip(warning 주황 — 시간 임박 시그널). 도메인별 색 + 아이콘 차이로 메타 종류가 한눈에 구분. 공개 설정 chip은 인터랙티브 — 탭하면 토스트로 의미 안내(공개 → "외부에 공개되어 누구나 볼 수 있는 이벤트입니다." / 비공개 → "초대받은 사람만 볼 수 있는 비공개 이벤트입니다."). 다른 chip(상태·D-day)은 정적 노출만. 운영자가 화면 들어와 0.3초 안에 "공개됐어 / 어떤 상태야 / 며칠 남았어"를 확인. **(3) 정보 수정 row** — Hero 카드 바로 위, 우측 정렬 "정보 수정 ›" 링크(13px w600 primary). 카드 밖 별도 row에 두어 편집 동작이 카드 콘텐츠와 시각적으로 분리 — 운영자가 정보를 읽다가 "수정해야지" 의도가 생겼을 때 손이 닿기 쉬운 위치. 탭 시 [`EventEditPage`](/specs/event_edit_page/index.html)로 push. **(4) Hero 카드 — stacked info blocks**: '일정' / '장소' 각각 caption(12px w500 secondary · 카테고리) → primary(16px w600 primary · 값) → secondary(13px secondary · 보조). value 폰트는 title(20px)보다 작아 페이지 위계 유지 — Hero 카드의 무게는 stacked 구조와 caption-primary-secondary 위계에서 나옴. **장소 block**은 추가로 _Kakao Map thumb_(100px · 핀 placement, 탭 시 외부 맵 앱 deep-link로 길 안내)과 _오시는길 sub-section_(label '오시는길' + 자유 텍스트 — 도보 안내 / 입구 / 주차 / 랜드마크 등 운영자가 작성)을 포함. 운영자뿐 아니라 외부 공유 시 참가자에게도 가치 있는 정보. 카드 자체는 borderless(`MinglitContentCard`의 `bordered: false` variant). 이전 Hero(아이콘 + 단일 일정 텍스트 + 상태 row + divider) → 현재 구조 전환 이유: (a) 정렬 — 아이콘과 multi-line 텍스트의 baseline 충돌 해소, (b) 정보 — 장소 추가 + 메타는 chip line으로 페이지 최상단 강조, (c) 액션 affordance — 카드 전체 탭보다 명시적 텍스트 링크가 의도 명료. 호스트 정보는 운영자 본인이 호스트인 경우가 대부분이라 본 영역에서는 생략(필요 시 EventEditPage에서 확인).

![blueprint](blueprint_3.png)

**Padding**(_screenEdge h_) └─ **Container**( ← ㉠ │ color: _color-surface_, │ borderRadius: _radius-card (16)_, │ border: 1px _color-divider (outlineVariant)_, │ padding: _spacing-medium (16)_ all) └─ **Column** ├─ **InkWell**(onTap: push [EventEditRoute](/specs/event_edit_page/index.html)) │ └─ **\_HeroDetailRow**(calendar\_today, '일정', ← Hero row (탭 가능) │ primary: 'yyyy년 MM월 dd일 (E)', │ secondary: 'a h:mm ~ a h:mm') ├─ Divider(spacing-small v-padding 양쪽) ├─ **\_MetaDetailRow**(people\_outline, '참가 현황', ← Supporting row │ value: '확정 N명 / 신청 M명 (대기 P)') ├─ Divider ├─ **\_MetaDetailRow**(info\_outline, '상태', ← Supporting row │ value: status label, │ valueColor: _scheduled→primary · cancelled→error · completed→outline_) ├─ Divider └─ **\_MetaDetailRow**(visibility, '공개 설정', ← Supporting row value: '공개' / '비공개' / '파티 설정 따라가기') _Hero row (\_HeroDetailRow) 내부 구조:_ └─ Row(crossAxis: start, gap: spacing-small) ├─ **Icon**(medium ≈22 · color-primary) ← ㉡ left └─ Expanded Column(gap: 2px) ├─ **Text**(caption '일정') ← ㉡ caption │ · 11px · w500 · color-text-secondary · letterSpacing 0.02em ├─ **Text**(primary value) ← ㉣ primary │ · 18px · w700 · color-text-primary · maxLines 2 · ellipsis └─ **Text**(secondary value) ← ㉤ secondary · 14px · color-text-secondary · maxLines 2 · ellipsis _Supporting row (\_MetaDetailRow) 내부 구조:_ └─ Row(crossAxis: start, gap: spacing-small, padding: 2px v) ├─ **Icon**(small ≈18 · color-text-secondary) ← ㉡ left └─ Expanded Column(gap: 1px) ├─ **Text**(label) ← ㉦㉧㉨ label │ · 12px · w500 · color-text-secondary · maxLines 2 · ellipsis └─ **Text**(value) ← ㉦㉧㉨ value · 14px · w600 · color-text-primary (기본) · 상태 행만 valueColor 적용 (primary/error/outline) + w700 · maxLines 2 · ellipsis

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | Card 외곽 | 풀폭 with screen-edge h-margin | radius radius-card (16) · padding spacing-medium (16) all · border 1px color-divider · bg color-surface |
| ㉡ | Icon 영역 (모든 행) | row leading · 좌측 정렬 · 행 시작 | Hero 행: iconSize-medium (≈22) · color color-primary · margin-top 2 / Supporting 행: iconSize-small (≈18) · color color-text-secondary · margin-top 0 · gap spacing-small (8) |
| ㉣ | Hero primary (날짜) | 좌측 정렬 · icon 우측 | typography 18px w700 · color color-text-primary · line-height 1.3 · maxLines 2 · ellipsis |
| ㉤ | Hero secondary (시간) | 좌측 정렬 · primary 아래 | typography 14px · color color-text-secondary · line-height 1.35 · maxLines 2 · ellipsis · 위 gap 2px |
| — | Hero caption ('일정') | 좌측 정렬 · primary 위 | typography 11px w500 · color color-text-secondary · letterSpacing 0.02em · 아래 gap 2px |
| ㉦㉧㉨ | Supporting label | 좌측 정렬 · 행 위쪽 | typography 12px w500 · color color-text-secondary · 아래 gap 1px · maxLines 2 · ellipsis |
| ㉦㉧㉨ | Supporting value | 좌측 정렬 · label 아래 | typography 14px w600 · 기본 color-text-primary · 상태 행만 primary / error / outline 중 하나 + w700 · maxLines 2 · ellipsis |
| — | Divider (행 사이) | 풀폭 · hero ↔ supporting / supporting ↔ supporting | height 1px color-divider · 위/아래 margin spacing-small (8) |

## Entry group cards anatomy (⑤)

섹션 헤더("참가 현황 / 입장권") 아래에 이어 붙는 **입장 그룹별 카드 stack**. 한 이벤트가 여러 입장 그룹(예: 일반 그룹 / VIP 그룹)을 가질 수 있으며, 각 그룹마다 카드 1개가 만들어져 그룹의 참가 현황 + 티켓 + 추가 버튼이 한 묶음으로 묶인다. 카드 안 구조는 위에서 아래로: 그룹 이름 + 분수(확정/정원) + chevron / **누적 진행 바**(확정 = 강한 primary, 대기 = 옅은 primary @ 30%) / breakdown(확정 N · 대기 M · 거절 P) / 심사 대기 alert (있을 때만) / divider / 그룹 티켓 row × N(이름 + 발행수 + 가격) / "+ 이 그룹에 티켓 추가" 버튼(dashed primary border). **카드 자체 탭 → [`EventApplicationListRoute`](/specs/event_application_list_page/index.html)(groupId)** — 해당 그룹으로 필터된 신청 리스트로 이동. 티켓 row 탭 → [`TicketEditRoute`](/specs/ticket_edit_page/index.html)(ticketId), 추가 버튼 탭 → [`TicketCreateRoute`](/specs/ticket_create_page/index.html)(groupId 사전 선택). **티켓 정원 정책**: 티켓 발행 총수 ≥ 그룹 정원이어야 함 (티켓이 정원보다 적으면 안내). "남은 정원만큼" 같은 cap 메시지 사용 X — 추가 발행은 항상 가능하며 운영자가 자유로 늘릴 수 있다. 입장 그룹이 0개면 본문 자리에 빈 상태 카드("입장 그룹을 먼저 만들어주세요" + 파티 상세 CTA), 그룹은 있는데 티켓이 0개면 카드 안 티켓 리스트 자리에 작은 안내 + 추가 버튼만.

![blueprint](blueprint_4.png)

`MinglitSection`(title: '입장권 관리', padding: EdgeInsets.zero, child: ...) ├─ _Section header row_ ← ㉠ │ └─ Title: '입장권 관리' _· bodyMedium · w700_ (trailing 없음 — Add 카드가 단일 진입점) │ └─ `MinglitAsyncValueWidget`(ticketsAsync) ├─ loading: small spinner ├─ error: 작은 텍스트 ('티켓 로드 실패') └─ data → **TicketListView** ├─ _case A — 빈 상태_ │ └─ `AddActionCard` (large) ← 빈 상태 단독 │ · 보라 dashed background · '새 티켓 만들기' │ · onTap → TicketCreateRoute │ └─ _case B — 티켓 있음_ ├─ **TicketStatusHeader** ← ㉢ │ · ℹ️ '발행 N / 정원 M' (labelMedium · text-secondary) │ · h-padding xxsmall │ └─ ListView.separated ├─ **TicketListItem**(ticket) × N ← ㉣㉤ │ · Card · radius-card · border outlineVariant │ · 좌측: 티켓 이름 + 발행/정원 라벨 │ · 우측: 가격 │ · onTap → push [TicketEditRoute](/specs/ticket_edit_page/index.html)(ticketId) │ └─ `AddActionCard` (small + 아이콘) ← ㉥ · trailing 자리에 늘 한 칸 더 붙음 — 새 티켓 추가의 단일 진입점 · onTap → TicketCreateRoute

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | Section title | 좌측 정렬 · 풀폭 (trailing 없음) | typography bodyMedium w700 · color color-text-primary · h-pad spacing-screen-edge |
| ㉢ | TicketStatusHeader | row · icon + label + count(우측) | typography labelMedium(label) / bodySmall(count) · color color-text-secondary · v-pad spacing-small |
| ㉣㉤ | TicketListItem | 풀폭 카드 · row 안 | radius radius-card · border outlineVariant · padding spacing-medium · 카드 사이 spacing-small (8) |
| ㉥ | AddActionCard (trailing) | 풀폭 · 항상 리스트 끝에 | radius radius-input · 보라 dashed border · padding spacing-medium · top margin spacing-xxsmall |
| — | 빈 상태 (case A) | 풀폭 단일 카드 | 같은 AddActionCard 컴포넌트, 라벨이 '새 티켓 만들기'로 큰 톤 |

🎨

## States

3 state (Default · Loading · Error). Default = baseline (데이터 로드 완료 · 티켓 ≥ 1개 · 신청 진행 중). 각 state는 mini-table 6-row (조건/사용자액션/에지케이스/컴포넌트/토큰/노트). 나머지 state는 additive diff (`+` · `−` · `↔ X → Y` · `동일` · `—`).

## State summary

한눈에 6 state 비교. 자세한 사양은 아래 각 mini-table.

| State | Tag | 조건 (요약) | Key visual differentiator |
|---|---|---|---|
| Default · 모집 🎯 | primary | 이벤트 데이터 로드 · 상태 'scheduled' · 입장 그룹 ≥ 1 · 티켓 ≥ 1 · 신청 ≥ 1 | 제목 + chip(공개·모집·D-N) + Hero 일정/장소 + 참가 현황(심사하기·참가자 보기) + 기대 매출(전체+그룹별) + 입장 그룹별 카드 N개 |
| 이벤트 취소됨 | cancelled | 상태 'cancelled' (운영자 또는 시스템) | chip 모집 → 취소(error 빨강) + 정보 수정 / 심사하기 / 티켓 추가 / 티켓 row 탭 모두 숨김·비활성 · Hero ⚠️ 안내 · 매출 카드 라벨 '환불 완료' · 심사대기 metric은 운영자 모니터링용 유지 |
| 이벤트 완료됨 | completed | 상태 'completed' (cron auto-complete: end_time 도달) | chip 'outline 회색' + D+N · 정보 수정 / 심사하기 / 티켓 추가 / 티켓 row 탭 모두 숨김·비활성 · 매출 카드 라벨 '달성 매출' · 심사대기 metric 숨김 · '확정' → '참석' 라벨 전환 |
| 신청 0건 | empty-applications | 입장 그룹 ≥ 1 · 신청 데이터 0건 | 참가 현황 분수 0/N · capbar 빈 · 심사대기 metric 숨김 · 환불완료 metric 숨김 · 심사하기 CTA 숨김 · 참가자 보기 outline만 |
| Loading | async | 이벤트 데이터 로드 중 | 풀-스크린 spinner (AppBar는 살아있음) |
| Error | network/server | 이벤트 데이터 로드 실패 | 가운데 에러 안내 텍스트 + retry (본문 미렌더) |

## States gallery

각 state mini-table — mockup(rowspan=6) + 6 aspect rows. **Default · 모집이 baseline**; 나머지 5 states는 additive diff prefix(↔ Default + ...) 사용.

![visual](visual_1.png)

## Meta chip — visual (도메인별 톤)

페이지 최상단 chip line은 운영 단계 메타를 색으로 구분해 운영자가 0.3초 안에 인지하도록 한다. 도메인별 색 매핑이 단일 진실: **공개 설정**(success / outline) · **이벤트 상태**(success / error / success) · **D-day**(warning · 시간 임박 시그널). 모든 chip은 동일 토큰(`radius-small` · 12px w600 · 3px 10px padding)을 공유하며 색만 variant로 분기.

![visual](visual_2.png)

| Chip 라벨 | Variant / 색 | 의미 / 노출 조건 |
|---|---|---|
| 공개 | success · 초록 #15803d | 이벤트가 외부에 노출됨. set-once — 운영자가 거의 안 바꿈. |
| 비공개 | outline · 회색 | 외부 노출 X. 초대 / draft 단계. |
| 모집 | success · 초록 #15803d | 이벤트 시작 전 — 신청 받는 활발한 단계. (공개 chip과 동일 톤이지만 도메인 다름 — visibility vs lifecycle) |
| 취소 | error · 빨강 | 이벤트 취소됨 — 주의 (환불 / 사후 안내 필요). |
| 완료 | outline · 회색 | 이벤트 종료 — 정산 / 리뷰 단계로 이동. |
| D-N (N>0) | warning · 주황 #b85a00 | 이벤트 시작까지 N일. 항상 동일 톤 (D-30 ~ D-1). |
| D-day | warning · 주황 | 이벤트 당일. label만 'D-day'로 변경 (숫자 없음). |
| D+N (지남) | outline · 회색 | 이벤트 시작 시간 지남. 보통 '완료' 상태와 함께 노출. |

※ Chip 순서는 stable→dynamic — 공개 chip(set-once)이 가장 좌측, 상태 chip(occasional change), D-day chip(매일 변함)이 우측. 운영자 시선이 변하지 않는 메타 → 변하는 메타 순으로 흘러가도록 설계.

🔄

## Global Behavior

Cross-cutting / global only — 모든/다수 state에 동일하게 적용되는 동작. state-specific 인터랙션은 위 States section의 각 state mini-table 참조.

## Cross-cutting interactions

| 사용자 액션 | 화면에 보이는 결과 |
|---|---|
| 뒤로 가기 (OS back / AppBar 뒤로 버튼) | 파티 상세로 복귀 — 모든 state에서 동일. |
| (deprecated) 탭 전환 | (deprecated) Tab 구조 폐기 후 단일 스크롤로 전환. 참가 신청은 별도 라우트(EventApplicationListRoute)로 분리되어 push 네비게이션으로 이동. |
| 다른 화면에서 돌아옴 (TicketCreate / TicketEdit / 심사 다이얼로그) | 이 화면은 자동으로 최신 데이터를 다시 받아옴 — 새로 만든 티켓이 리스트에 추가되거나, 심사 처리된 신청이 처리 완료 그룹으로 이동한다. |
| 심사 처리 성공 (참가 신청 탭에서) | 다이얼로그 닫힘 → SnackBar('심사 처리가 완료되었습니다.') 잠깐 표시 → 신청 리스트가 자동 갱신되며 해당 카드가 처리 완료 그룹으로 이동. |
| 심사 처리 실패 | SnackBar 대신 공통 에러 안내가 노출되고, 카드는 심사 대기 그룹에 그대로 유지된다. |

※ state-specific 액션 (티켓 카드 탭 / 심사 대기 카드 탭 등)은 위 States section의 mini-table에 분산.

## Motion & timing

**임시값 사용 금지** — duration은 `MinglitAnimation` 토큰에서 선택.

| Token | Value | Use case |
|---|---|---|
| MinglitAnimation.micro | 100ms | 탭 active indicator 슬라이드 (탭 → 다음 탭) |
| MinglitAnimation.fast | 200ms | 심사 다이얼로그 scale fade-in/out |
| MinglitAnimation.medium | 350ms | loading → data 크로스페이드 · push 화면 전환 |
| (OS default) SnackBar | ~250ms 진입 / 4s 표시 / 200ms 퇴장 | Material SnackBar 기본 |

| Transition | Duration (token) | Curve / notes |
|---|---|---|
| 탭 전환 (본문 슬라이드) | medium (350ms) | (deprecated — Tab 구조 폐기됨) push/pop은 Material 기본 슬라이드 |
| 활성 indicator 이동 | micro 근사 (~100ms) | (deprecated — TabBar 폐기됨) |
| 이벤트 데이터 로드 (Loading → Default) | medium (350ms) | spinner fade-out + 본문 fade-in 크로스페이드 |
| 심사 다이얼로그 진입/퇴장 | fast (200ms) | Material Dialog scale fade |
| 심사 처리 후 리스트 갱신 | ~ms (즉시) | 리스트가 새 데이터로 다시 그려짐 — 카드 위치 변경은 별도 애니메이션 없이 즉시 반영 |
| SnackBar 등장 | OS default | 화면 하단에서 슬라이드 업 → 약 4초 머무름 → 자동 사라짐 |

## Global edge cases

화면 전반에 영향을 주는 edge case. state-specific edge case는 위 States section의 각 mini-table 에지케이스 행에.

-   **이벤트 제목이 비어있음** — 본문 상단의 제목 블록 통째로 사라짐. Hero 카드가 곧바로 시작 위치로 올라간다.
-   **참가 현황 / 신청 카운트가 0** — 메타 카드의 "참가 현황" 행은 "확정 0명 / 신청 0명 (대기 0)"으로 노출 (행 자체는 사라지지 않음).
-   **티켓이 0개** — 입장권 섹션 본문이 큰 보라 빈 상태 카드("새 티켓 만들기") 한 장으로 대체. 섹션 헤더는 타이틀만 노출(trailing 버튼 없음).
-   **정원(maxParticipants)이 정해지지 않음** — 입장권 섹션의 status header(발행/정원 라인)가 사라지고 곧바로 카드부터 시작.
-   **입장 그룹이 정의되지 않은 단순 이벤트** — 티켓 카드 sub-라벨에서 "그룹" 정보가 빠지고 발행/정원 텍스트만 남는다.
-   **다크 모드** — 활성 탭 / 이벤트 제목 / Add 카드의 partner primary 톤이 다크 브랜드 톤(#9b7bec)으로 자동 전환. 메타 카드 / 티켓 카드 / 신청 카드 / divider / status badge 모두 mds 다크 토큰 자동 반영. 상태값 색(모집/취소/완료)도 동일 매핑이 다크 컬러 셋으로 적용.
-   **접근성** — Hero 카드 / 참가 현황 카드는 InkWell이라 Material 기본 a11y(스크린 리더 "버튼" 인식). 메타 카드의 라벨/값은 row 단위로 grouped. status badge 텍스트는 색 의존이 아니라 라벨 자체를 읽으면 의미가 전달되도록 작성. 심사 흐름은 별도 라우트(EventApplicationListRoute → EventApplicationDetailRoute)로 분리되어 키보드 nav 자연스럽게 가능.
-   **네트워크 끊김 (재진입 전)** — Loading이 길어지다 결국 Error state로 전환. AppBar는 살아있어 사용자가 뒤로갈 수 있음.

※ **티켓 / 심사 다이얼로그 자체의 edge** (가격 미정 / 심사 거절 사유 미입력 등)는 각 child spec / 다이얼로그 내부 사양 참고.

📖

## Reference

Implementation source + 인접 화면 link만. **Components / Tokens는 States section의 각 mini-table**에 분산됨.

## Implementation source

| 항목 | Path / Reference |
|---|---|
| Widget class | EventDetailPage (+ _EventInfoTab · _HeroDetailRow / _MetaDetailRow internal widgets) |
| File path | apps/app_partner/lib/src/features/party/event/detail/event_detail_page.dart |
| Ticket list widget | ticket_list_item.dart (TicketListView · TicketListItem · TicketStatusHeader) |
| Controller / Provider | eventDetailProvider(eventId) · eventTicketsProvider(eventId) · eventApplicationsProvider(eventId) · eventApplicationReviewControllerProvider · partyDetailProvider(partyId) |
| Review dialog | EventApplicationReviewDialog — 심사 대기 카드 탭 시 노출되는 승인/거절 다이얼로그 |
| Route | EventDetailRoute · path: /parties/:partyId/events/:eventId · app_partner/lib/src/routing/app_routes.dart |

## Related screens

| Spec | Relation |
|---|---|
| PartyDetailPage | Parent — 이 화면으로 진입하는 주 경로 (이벤트 카드 탭). |
| EventEditPage | Hero "일정" 영역 탭 → 이벤트 정보 수정 화면. 확정 참가자 ≥1명이면 일정·장소 변경 시 사유 입력 + 자동 알림 정책 발동. |
| TicketCreatePage | 빈 상태 카드(티켓 0개) / 리스트 끝 Add 카드 → 모두 여기로 이동 (단일 진입점). |
| TicketEditPage | 입장권 카드 탭 → 해당 티켓을 선택한 상태로 이 화면으로 이동. |
| EventApplicationManagePage | 여러 이벤트의 신청을 한꺼번에 관리하는 화면 — 본 화면의 참가 현황 카드 → EventApplicationListRoute가 단일 이벤트 버전이고, 이 화면은 cross-event 버전. |
| EventApplicationDetailPage | 개별 신청 상세 — 본 화면에서는 다이얼로그로 처리하지만, 더 깊은 정보가 필요할 때 이쪽으로 향한다. |
| EventCreatePage | 이 화면이 보여주는 이벤트를 처음 만든 화면 — 같은 event 데이터의 생성 단계. |
| EventDetailPage (user) | 같은 이벤트의 user 측 화면 — 영업 톤(이미지 캐러셀 + CTA 바). 같은 데이터, 정반대 관점. |

## ✅ Authoring checklist

-   ✅ **Header** — Title (h1)만
-   ✅ **Overview** — Status (✅ 디자인완료) · App · Category · Route · Path · Hierarchy · Purpose · User journey · Background · Frequency 10행 모두 채움
-   ✅ **History** — v1.0 (2026-05-01) 초기 작성
-   ✅ **Layout — top blueprint** — AppBar + Title + Detail card + Stats card + Tickets section + Visibility footer 6블록 + tree
-   ✅ **Layout — Sub-anatomy 3종** — Title block · Detail info card · Tickets section (참가 신청은 EventApplicationListRoute 별도 spec)
-   ✅ **States — 6종** — Default · 이벤트 취소됨 · 이벤트 완료됨 · 신청 0건 · Loading · Error
-   ✅ **States — mini-table 6 rows** — 6 state 모두 (조건/액션/에지/컴포넌트/토큰/노트)
-   ✅ **States — Default baseline 풀 리스트** — 컴포넌트 + 토큰 풀 명시
-   ✅ **States — additive diff** — 나머지 3 state는 ↔ / + / − prefix 사용
-   ✅ **State summary matrix** — 6 state 한눈 비교
-   ✅ **Visual zoom-in 1종** — Meta chip 도메인별 톤 (공개·상태·D-day 4 그룹 + 통합 예시)
-   ✅ **Global Behavior — cross-cutting only** — 뒤로가기 · 탭 전환 · 화면 복귀 시 새로고침 · 심사 처리 성공/실패
-   ✅ **Global Behavior — Motion** — MinglitAnimation token 매핑 표 + transitions 표
-   ✅ **Global edge cases** — 제목 빈/카운트 0/티켓 0/정원 미정/그룹 없음/다크모드/접근성/네트워크
-   ✅ **Reference — Implementation source** — widget · file · tab2 widget · ticket widget · controllers · review dialog · route
-   ✅ **Reference — Related screens** — PartyDetail · TicketCreate · TicketEdit · ApplicationManage · ApplicationDetail · EventCreate · user EventDetail
-   ✅ **Partner brand color** — viewport-scoped `--color-primary` 오버라이드 (#6c3ce1 / dark #9b7bec)
-   ✅ **톤 룰** — 사용자 관찰 가능 묘사. provider/method/AsyncValue/Riverpod 용어 사용 안 함 (widget 트리 내 컴포넌트 contract만 widget 이름 사용)