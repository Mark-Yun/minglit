 Spec — EventDetailPage (app\_user · EventDetailRoute)  

# Event Detail

## Overview

| Status | 🚧 디자인중 — scroll-spy + §1 sub-anatomy 정리 + BottomTicketBar 별도 spec 분리. 라벨 변경(BottomTicketBar) 이터레이션 중. |
|---|---|
| App | app_user |
| Category | event · detail |
| Route / Surface | EventDetailRoute · widget: EventDetailPage (+ _EventDetailContent · _BottomTicketBar via part of) |
| Path | /events/:eventId |
| Hierarchy | Parent: — (top-level screen)Children: EventBottomTicketBar (⑥ 영역, 별도 spec) |
| Purpose | 이벤트 참여 결정의 핵심 화면 — 모든 정보(기본 정보 · 상세 소개 · 참가 현황 · 필요 인증 · 환불 정책)를 단일 scrollable 페이지에 5개 섹션으로 배치하고 하단 CTA로 참여/상태별 액션을 수행한다. 상단의 5탭은 화면 전환이 아닌 scroll-spy — 탭 탭 시 섹션으로 animate-scroll, 스크롤 시 활성 탭 자동 갱신. |
| User journey | Entry points: 홈 피드 카드 탭 / 태그 이벤트 목록 탭 / 공유 링크(딥링크) 직접 진입.Exit points: 뒤로 가기 → 이전 화면 / 파트너 이름 탭 → PartnerDetailPage / "구매하기" CTA → 티켓 선택 바텀시트 → EventApplicationWizard / "참여 취소" → 취소 확인 다이얼로그 / 공유하기 → OS share sheet. |
| Background | 5탭 scroll-spy 구조로 정보 밀도 ↑ + 단일 스크롤 흐름 보존. 히어로 이미지 collapse 시 AppBar에 이벤트 타이틀 fade-in (CollapseMode.pin). 파트너 차단·신고는 ⋮ 메뉴로 접근 (인증된 사용자에게만). BottomTicketBar는 별도 spec으로 분리 — EventBottomTicketBar 참고. |
| Frequency | 관심 이벤트마다 1회 이상 — 참여 전 반복 열람. |

## History

| Date | Version | Author | Changes |
|---|---|---|---|
| 2026-05-01 | 2.0 | mark-yun | 새 템플릿으로 마이그레이션. Header → Title만, 메타는 Overview 테이블 9행으로 흡수. Visual → States 리네임, 6 states 모두 mini-table 6-row 패턴 (Default baseline + additive diff). Behavior → Global Behavior. Reference에서 Components used + Tokens consumed 표 제거 (mini-tables로 분산), Implementation source 추가. Status: 🚧 디자인중. |
| 2026-05-01 | 1.3 | mark-yun | BottomTicketBar 영역 분리 — 자체 spec(event_bottom_ticket_bar.html)으로 추출. 이 페이지에서는 ⑥ 영역으로 stub 처리, 자세한 12-state 매트릭스는 그쪽에 위임. |
| 2026-04-29 | 1.2 | mark-yun | scroll-spy 패턴 명시. Visual states 재구성 — Default를 "스크롤 top", State 4를 "Mid-scroll · §3 active"로 reframe. 탭이 화면 전환이 아닌 scroll-spy임을 Layout intro + State summary에 명확히 표기. 사용자가 보고하던 혼선("탭으로만 나뉘어져있음") 해소. §1 기본 정보 sub-anatomy 섹션 추가 (Sub-anatomy parallel structure 도입). |
| 2026-04-XX | 1.0 | mark-yun | Initial spec — 4-perspective 구조 (Layout / Visual / Behavior / Reference). 6 states (Default · Loading · Error · Scrolled · Already Joined · Full). BottomTicketBar 인라인 작성. |

[🧱 Layout](#layout) [🎨 States](#states) [🔄 Global Behavior](#global-behavior) [📖 Reference](#reference)

🧱

## Layout

화면 구조 — 영역, 정렬, 간격 규칙. 색·타이포 무시.

## Blueprint & tree

Column(Expanded + BottomTicketBar). Expanded 내부는 AnimatedSwitcher — loading/error/data 전환. data 상태: **단일 CustomScrollView** — SliverAppBar(expandedHeight=16:9 이미지) + SliverPersistentHeader(탭바) + 5개 SliverToBoxAdapter 섹션이 **한 줄로 길게 스크롤**됨. AppBar는 pinned — collapse 시 타이틀 fade-in. **TabBar는 화면 전환이 아닌 scroll-spy** — 탭 탭하면 해당 섹션으로 animateTo(300ms easeInOut), 사용자가 스크롤하면 GlobalKey 기반 viewport 검사로 현재 보이는 섹션을 감지해 active tab 자동 업데이트(`_isTabTapScroll` guard로 탭 탭 직후 충돌 방지).

![blueprint](blueprint.png)

**Scaffold** └─ **Column** ├─ **Expanded** │ └─ **AnimatedSwitcher**(duration: MinglitAnimation.medium) │ ├─ \[loading\] **\_EventDetailContentSkeleton** │ ├─ \[error\] **MinglitErrorState**(fullPage) │ └─ \[data\] **\_EventDetailContent** │ └─ **Stack** │ ├─ **RefreshIndicator** │ │ └─ **CustomScrollView** │ │ ├─ **SliverAppBar**(expanded=16:9, pinned) ← ① │ │ │ ├─ **FlexibleSpaceBar** │ │ │ │ ├─ **MinglitImageCarousel**(imageUrls) │ │ │ │ └─ gradient overlay (top black→transparent) │ │ │ ├─ leading: **BackButton**(color: iconColor) │ │ │ └─ actions: **PopupMenuButton**(block/report) _(partner≠null & user≠null)_ │ │ │ │ │ ├─ **SliverPersistentHeader**(pinned) ← ② │ │ │ └─ **TabBar**(scrollable, tabAlignment:start) │ │ │ └─ tabs: 기본 정보 / 상세 소개 / 참가 현황 / 필요 인증 / 환불 정책 │ │ │ │ │ ├─ **SliverToBoxAdapter**: §1 기본 정보 ← ③ │ │ │ ├─ partner row (CircleAvatar + name + chevron) │ │ │ ├─ title Text(headlineSmall bold) │ │ │ ├─ **\_InfoTile** — 날짜·시간·진행 시간 │ │ │ ├─ **\_InfoTile** — 장소 이름·주소 │ │ │ └─ Wrap: **MinglitSocialActionChip**(like) + **MinglitChip**(공유하기) │ │ │ │ │ ├─ **SliverToBoxAdapter**: §2 상세 소개 ← ④ │ │ │ └─ **\_QuillViewer**(delta JSON) │ │ │ │ │ ├─ **SliverToBoxAdapter**: §3 참가 현황 │ │ │ └─ **MinglitSection**(title: '참여 현황') │ │ │ └─ **EntryGroupDetail** × N + **MinglitParticipantGauge** │ │ │ │ │ ├─ **SliverToBoxAdapter**: §4 필요 인증 ← ⑤ │ │ │ └─ **MinglitSection** → **VerificationCard** × N │ │ │ │ │ ├─ **SliverToBoxAdapter**: §5 환불 정책 │ │ │ └─ **MinglitSection** → **\_RefundPolicySection** │ │ │ │ │ └─ **SliverToBoxAdapter**(bottom padding: screenHeight/2) │ │ │ └─ **OpenInAppBanner** (Positioned bottom) _(if !\_bannerDismissed)_ │ └─ _BottomTicketBar_ ← ⑥ ├─ \[data\] **\_BottomTicketBar** │ ├─ price Column(최저가 label + 금액 titleLarge secondary-color) │ └─ **MinglitButton** / **MinglitButton.destructive** (admission state) ├─ \[loading\] **\_BottomTicketBarSkeleton** └─ \[error\] SizedBox.shrink()

## Spacing & alignment rules

| # | Region | Alignment | Spacing |
|---|---|---|---|
| ① | Hero SliverAppBar | expandedHeight = screenWidth × 9/16 (px) | back/more 버튼: top spacing-small+8. 아이콘 색상: 히어로 visible=white, collapsed=onSurface. |
| ② | Pinned TabBar | scrollable · tabAlignment: start (no 52dp indent) | height: kTextTabBarHeight+1 ≈ 49px. 하단 Divider 1px. |
| ③ | §1 기본 정보 | column start · screen-edge h-padding | h-pad: spacing-screen-edge (16px) · v-pad: spacing-medium (16px) · 섹션 내 gap: spacing-small (8px) |
| ④ | §2 상세 소개 | column start | top: spacing-sectionGap (40px) · h-pad: spacing-screen-edge |
| ⑤ | §3§4§5 각 섹션 | column start (MinglitSection 내부 표준) | top: spacing-sectionGap (40px) 각 섹션 첫 padding |
| ⑥ | BottomTicketBar | Row · price col (crossAxis start) + 버튼 flex:1 | outer pad: spacing-medium (16px) all · price↔button: spacing-large (24px) |

## §1 기본 정보 — sub-anatomy

§1 (③)의 내부 구조 — Column(crossAxis start) · h-pad `spacing-screen-edge` · v-pad `spacing-medium`. partner row(있을 때만) → 이벤트명 → InfoTile × 2 (날짜·장소) → action chips (Wrap). 파트너 없는 일부 이벤트는 partner row 영역이 통째로 사라지고 그 밑이 위로 collapse.

![blueprint](blueprint_2.png)

**SliverToBoxAdapter** (§1) └─ **Padding**(_screenEdge h · medium v_) └─ **Column**(crossAxis: start) ├─ _Partner row_ (if partner != null) ← ㉠ │ └─ **GestureDetector**(opaque · onTap: pushPartnerDetail) │ └─ Row │ ├─ **CircleAvatar**(radius: _radius-input = 12_) — 24×24 │ ├─ Gap: _spacing-small (8)_ │ ├─ Flexible Text(_titleSmall · onSurfaceVariant_) │ ├─ Gap: _spacing-xsmall (4)_ │ └─ Icon(_chevron\_right · 16 · onSurfaceVariant_) ├─ Gap: _spacing-small (8)_ _(if partner)_ │ ├─ _Title_ ← ㉡ │ └─ Text(_headlineSmall_ · **bold**) │ · 폴백: party.title → event.title → '제목 없음' ├─ Gap: _spacing-medium (16)_ │ ├─ _InfoTile #1 — 날짜·시간_ ← ㉢ │ └─ **\_InfoTile**(icon: calendar\_today\_outlined, │ title: 'M월 d일 (E) HH:mm', │ subtitle: '`{durationHours}`시간') ├─ Gap: _spacing-small (8)_ │ ├─ _InfoTile #2 — 장소_ ← ㉣ │ └─ **\_InfoTile**(icon: location\_on\_outlined, │ title: location?.name ?? '장소 미정', │ subtitle: location?.address ?? '주소 정보 없음') ├─ Gap: _spacing-medium (16)_ │ └─ _Action chips_ Wrap(spacing/runSpacing: small) ← ㉤ ├─ **MinglitSocialActionChip**(targetType: party · interactionType: like) │ · activeIcon: _thumb\_up_ · inactiveIcon: _thumb\_up\_outlined_ │ · activeColor: _color-primary_ │ · onUnauthenticatedTap: _pushLogin()_ (게스트일 때만) │ · radius: _radius-small (8)_ · padding: 12h · 6v · 1px outline border │ └─ **MinglitChip**(size: large · label: '공유하기' · icon: share\_outlined) · onTap: `ShareUtils.shareEvent(eventTitle, eventId, baseUrl)` · radius: _radius-small (8)_ · padding: 12h · 6v · 내부: _icon (16) | 1px outlineVariant divider | label (labelLarge)_ _※ Chip은 mds `MinglitChip` / `MinglitSocialActionChip` 컴포넌트 그대로 사용._ _pill(radius-chip)이 아니라 radius-small(8) 직사각형 — 기능 버튼 톤._ _FilterChipBar의 chip(radius-chip pill)과 시각적으로 명확히 구분됨 — 역할이 다름._

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | Partner row | row crossAxis center · 좌측 정렬 · 전체 width | avatar 24×24 (radius-input = 12) · avatar↔name spacing-small (8) · name↔chevron spacing-xsmall (4) · 행 하단 spacing-small (8) |
| ㉡ | Event title | 좌측 정렬 · multi-line | typography headlineSmall bold · 하단 spacing-medium (16) |
| ㉢ | InfoTile — 날짜 | row · icon-leading + 2-line text | icon-text gap: spacing-sm (12) · 행 하단 spacing-small (8) |
| ㉣ | InfoTile — 장소 | row · icon-leading + 2-line text | icon-text gap: spacing-sm · 행 하단 spacing-medium (16) |
| ㉤ | Action chips Wrap | spacing/runSpacing: spacing-small (8) | chip radius: radius-small (8) · padding 12h · 6v · 내부 icon \| 1px divider \| label · text labelLarge |

## Hero image carousel anatomy (①)

① 영역의 내부 구조 — 화면 너비 × 9/16 비율의 16:9 이미지 영역. 가로 스와이프 캐러셀(점 인디케이터 포함) 위에 어두운 그라데이션이 얇게 깔리고, 그 위에 흰색 뒤로가기 / ⋮ 메뉴 아이콘이 떠 있다. 이미지가 여러 장이면 하단 중앙에 점 인디케이터가 표시되고, 한 장이면 인디케이터 자체가 사라진다.

![blueprint](blueprint_3.png)

**SliverAppBar**(pinned, expandedHeight: _screenWidth × 9/16_) └─ **FlexibleSpaceBar**(collapseMode: pin) └─ **Stack**(fit: expand) ├─ _Carousel_ ← ㉣ │ └─ **MinglitImageCarousel**(imageUrls) │ · 가로 스와이프로 다음/이전 이미지로 전환 │ · 좌우 끝에서는 더 이상 넘어가지 않음 (반복 안 함) │ ├─ _Top gradient_ ← ㉠ │ · 위 80px 영역 흑색 0.5 → 투명 그라데이션 │ · 흰색 아이콘 가독성 확보용 — 이미지 톤 무관하게 선명 │ ├─ leading: _BackButton_ ← ㉡ │ · 40×40 hit zone · 좌측 가장자리 4px │ · 색상: 펼쳐진 상태에서는 흰색, 접힌 상태로 가면 onSurface로 자동 전환 │ ├─ actions: _PopupMenuButton(⋮)_ ← ㉢ │ · 우측 가장자리 4px · 40×40 │ · 차단 / 신고 메뉴 항목 노출 (로그인 + 파트너 존재 시에만 표시) │ └─ _Page indicator_ ← ㉤ · 하단 중앙에 작은 점들이 가로로 배치 · 활성 점은 가로로 길쭉한 알약 모양으로 강조 · 이미지가 1장이면 영역 자체가 사라짐

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| — | Hero 외부 | full-width · aspect 16:9 | height = screenWidth × 9/16 · bottom edge가 TabBar 시작점 |
| ㉠ | Top gradient overlay | top 정렬 · 풀폭 · 높이 80px | 색: 검정 0.5 → 투명 (선형) · 아이콘 가독성용 |
| ㉡ | 뒤로 버튼 | 좌상 정렬 | top: spacing-small (8) · left: 4px · 40×40 hit zone · icon 22 |
| ㉢ | ⋮ 메뉴 버튼 | 우상 정렬 | top: spacing-small (8) · right: 4px · 40×40 hit zone · icon 22 · 로그인 + 파트너 존재 시에만 노출 |
| ㉣ | 이미지 캐러셀 | fit: cover · 가로 스와이프 | 각 이미지가 풀폭 채움 · 페이지 단위 슬라이드 |
| ㉤ | 점 인디케이터 | 하단 중앙 정렬 | bottom: spacing-small (8) · 점 사이 gap: 4px · 점 크기 6 · 활성: 가로 16 알약 · 1장이면 숨김 |

## Pinned TabBar anatomy (②)

② 영역의 내부 구조 — 히어로 바로 아래에 붙는 49px 가로 스크롤 탭 바. 5개 탭(기본 정보 · 상세 소개 · 참가 현황 · 필요 인증 · 환불 정책)이 좌측부터 차례로 늘어서 있고, 활성 탭은 색상 + 아래 2px 보라 언더라인으로 표시된다. 탭은 화면을 갈아끼우지 않고 **같은 페이지 안의 해당 섹션으로 부드럽게 스크롤**한다.

![blueprint](blueprint_4.png)

**SliverPersistentHeader**(pinned, height ≈ 49) └─ **Container**(bg: _color-background_, border-bottom: 1px _color-divider_) └─ **TabBar**(scrollable, tabAlignment: start) ├─ _Tab #1 — 기본 정보_ ← ㉠ ├─ _Tab #2 — 상세 소개_ ← ㉡ ├─ _Tab #3 — 참가 현황_ ← ㉢ ├─ _Tab #4 — 필요 인증_ ← ㉣ └─ _Tab #5 — 환불 정책_ _각 탭 내부:_ · 좌우 padding 14px · 상하 padding 10px · 비활성 라벨: _color-text-secondary_ · w500 · 활성 라벨: _color-primary_ · w600 + 하단 2px _color-primary_ 언더라인 · 탭 사이 간격: 0 (각 탭의 padding으로 분리됨) _스크롤 동기화:_ · 사용자가 페이지를 스크롤하면 현재 보이는 섹션의 탭이 자동으로 활성화됨 · 탭을 직접 탭하면 그 섹션으로 약 300ms 부드럽게 스크롤 · 탭 직후 잠깐은 자동 갱신이 멈춰 충돌하지 않음

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| — | TabBar 외부 | full-width · 가로 스크롤 | height ≈ 49px (kTextTabBarHeight + 1) · 하단 1px color-divider |
| ㉠–㉣ | 각 탭 | tabAlignment: start (좌측부터) · row crossAxis center | padding: 10v · 14h · gap: 0 · 라벨 bodyMedium w500 (활성 w600) |
| — | 활성 indicator | 탭 라벨 하단에 정렬 | 높이 2px · 색 color-primary · 너비 = 라벨 너비 |
| — | 비활성 라벨 | — | 색 color-text-secondary · w500 |
| — | 활성 라벨 | — | 색 color-primary · w600 |

## §3 참가 현황 — sub-anatomy

§3 영역의 내부 구조 — "참여 현황" 섹션 헤더 + 입장권(또는 입장 그룹)별 카드 리스트. 각 카드에는 좌측에 그룹명 + 현재 참여 인원, 우측에 정원 대비 현재 참여 비율을 보여주는 가로 게이지 바와 "현재/정원" 텍스트가 함께 붙는다. 입장 그룹이 정의되지 않은 단순 이벤트는 카드 없이 "N명 / M명" 텍스트 한 줄만 노출된다.

![blueprint](blueprint_5.png)

**SliverToBoxAdapter** (§3) └─ **MinglitSection**(title: '참여 현황') ├─ _Section header_ ← ㉠ │ · "참여 현황" · _bodyMedium · bold_ │ · padding: _medium · screenEdge · sm_ │ └─ **Column** ├─ _Entry group card #1_ ← ㉡ │ └─ **Container**(border 1px · radius-small · h-margin screenEdge) │ └─ Stack │ ├─ Column(crossAxis: start) │ │ ├─ _그룹 이름_ (bodyMedium · w600) │ │ └─ _"N명 참여"_ (bodySmall · text-secondary) │ └─ _Gauge cluster_ (Positioned top-right) │ ├─ **MinglitParticipantGauge** — 80×6 알약 바 │ │ · 채워진 부분: _color-primary_ │ │ · 빈 부분: _color-divider_ │ └─ _"현재/정원"_ 라벨 (10 · w600 · text-secondary) │ └─ _Entry group card #2 …_ ← ㉢ · 동일 구조, 정원 / 현재 인원만 다름 · 입장 그룹이 0개면 카드 없이 "N명 / M명" 한 줄로 대체

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | Section header | 좌측 정렬 · 섹션 첫 줄 | padding: medium · screenEdge · sm · text bodyMedium w700 color-text-primary |
| ㉡㉢ | Entry group card | 풀폭 (좌우 16 margin) · 내부 Stack | border 1px color-divider · radius radius-small (8) · padding spacing-small (8) · 카드 사이 spacing-medium (16) |
| — | 그룹 이름 / 인원수 | 카드 좌측 column | 이름 bodyMedium w600 · 인원수 bodySmall color-text-secondary · 줄 간격 spacing-xxsmall (2) |
| — | Gauge bar | 카드 우측 상단 정렬 | 너비 80 · 높이 6 · radius 3 · 채움 color-primary · 배경 color-divider |
| — | "현재/정원" 라벨 | gauge 바로 아래 우측 정렬 | 10px · w600 · color-text-secondary |

## §4 필요 인증 — sub-anatomy

§4 영역의 내부 구조 — "필요 인증" 섹션 헤더 + "참여하려면 아래 인증이 필요합니다" 안내 문구 + 인증 카드 리스트. 각 카드는 좌측 동그란 상태 아이콘(완료=초록 ✓ / 미완료=노랑 !), 가운데 인증 이름 + 상태 텍스트, 우측 chevron(미완료에만)으로 구성된다. 탭하면 해당 인증 화면으로 이동하고, 모두 완료된 상태에서는 모두 ✓ + "완료" 표기로 보인다.

![blueprint](blueprint_6.png)

**SliverToBoxAdapter** (§4) └─ **MinglitSection**(title: '필요 인증') ├─ _Section header_ ← ㉠ │ · "필요 인증" · _bodyMedium · bold_ │ ├─ _Helper text_ ← ㉡ │ · "참여하려면 아래 인증이 필요합니다." │ · _bodySmall · text-secondary_ │ · 인증이 0개면 "별도의 인증이 필요하지 않습니다." 한 줄로 대체 │ └─ **Column** ├─ _Verification card (완료)_ ← ㉢ │ └─ Row │ ├─ _Status circle_ 36×36 │ │ · 배경: _color-success_ 14% tint │ │ · 아이콘: ✓ (_color-success_) │ ├─ Column(flex 1) │ │ ├─ _인증 이름_ (bodyMedium · w600 · text-primary) │ │ └─ _"완료됨"_ (bodySmall · color-success) │ └─ _(no chevron)_ │ └─ _Verification card (미완료)_ ← ㉣ └─ Row ├─ _Status circle_ 36×36 │ · 배경: _color-warning_ 14% tint │ · 아이콘: ! (_color-warning_) ├─ Column(flex 1) │ ├─ _인증 이름_ (bodyMedium · w600) │ └─ _"인증 필요 — 탭하여 시작"_ (bodySmall · color-warning) └─ _chevron\_right_ (16 · text-secondary) · 카드 전체가 탭 영역 — 탭 시 해당 인증 화면으로 이동

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | Section header | 좌측 정렬 · 섹션 첫 줄 | padding: medium · screenEdge · sm · text bodyMedium w700 |
| ㉡ | Helper text | 좌측 정렬 | h-padding spacing-screen-edge · 하단 spacing-sm (12) · text bodySmall color-text-secondary |
| ㉢ | 완료 카드 | row crossAxis center · 좌우 16 margin | border 1px color-divider · radius radius-card (12) · padding 12 · 카드 간 spacing-small (8) |
| — | Status circle (완료) | row leading | 36×36 원형 · bg color-success 14% · 아이콘 색 color-success |
| ㉣ | 미완료 카드 | row crossAxis center · 동일 외형 | 좌측 status circle bg color-warning 14% · 우측 chevron 16 color-text-secondary |
| — | 이름 / 상태 텍스트 | 중앙 column | 이름 bodyMedium w600 · 상태 bodySmall (완료=success / 미완료=warning) |

## §5 환불 정책 — sub-anatomy

§5 영역의 내부 구조 — "환불 정책" 섹션 헤더 + 환불 비율 카드(취소 시점별 % 표) + 보조 문구("파트너 사정 시 100% 자동 환불 …" / "자세히 보기" 인라인 링크). 카드 안의 각 행은 좌측 시점 라벨 + 우측 환불 비율로 구성되고, 100% 환불은 success 강조, 환불 불가는 error 강조 색으로 표시된다.

![blueprint](blueprint_7.png)

**SliverToBoxAdapter** (§5) └─ **MinglitSection**(title: '환불 정책') ├─ _Section header_ ← ㉠ │ · "환불 정책" · _bodyMedium · bold_ │ ├─ _Refund table card_ ← ㉡ │ └─ **Container**(bg surface · border 1px · radius-card) │ ├─ _"취소 시점별 환불 비율"_ 라벨 (bodySmall · w600) │ └─ **Column** │ ├─ _Row #1 — "7일 전까지" / "100% 환불"_ │ │ · 우측 값: _color-success_ · w600 │ │ · 행 하단 1px _color-divider_ │ ├─ _Row #2 — "3일 전까지" / "50% 환불"_ │ │ · 우측 값: _text-primary_ · w600 │ │ · 행 하단 1px divider │ └─ _Row #3 — "당일" / "환불 불가"_ │ · 우측 값: _color-error_ · w600 (강조) │ · 마지막 행은 하단 divider 없음 │ └─ _Helper text_ ← ㉢ · "※ 파트너 사정으로 인한 취소 시 100% 자동 환불됩니다." · 끝에 "자세히 보기" 인라인 링크 (_color-primary_) · 탭 시 환불 정책 본문 다이얼로그 / 외부 링크

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | Section header | 좌측 정렬 · 섹션 첫 줄 | padding: medium · screenEdge · sm · text bodyMedium w700 |
| ㉡ | Refund table card | 풀폭 (좌우 16 margin) · column | bg color-surface · border 1px color-divider · radius radius-card (12) · padding 14v · 16h |
| — | 표 행 (3개) | row · justify space-between | 각 행 padding 6v 0h · 행 하단 1px color-divider (마지막 행은 없음) |
| — | 좌측 시점 라벨 | 좌측 정렬 | text bodyMedium · color-text-secondary |
| — | 우측 환불 비율 | 우측 정렬 | w600 · 100% → color-success · 부분 환불 → color-text-primary · 환불 불가 → color-error |
| ㉢ | Helper + 인라인 링크 | 좌측 정렬 | h-padding spacing-screen-edge · text bodySmall color-text-secondary · "자세히 보기"는 color-primary 인라인 |

## Bottom CTA bar anatomy (⑥ — 요약)

⑥ 영역의 외형만 짧게 요약 — 자세한 12-state 매트릭스(참여 가능 / 마감 / 신청됨 / 거절 등)와 가격 라벨 분기는 [`EventBottomTicketBar`](/specs/event_bottom_ticket_bar/index.html) child spec에 있다. 여기서는 "스크롤 영역 아래에 항상 떠 있는 80px 고정 바" 라는 외부 골격만 다룬다.

![blueprint](blueprint_8.png)

**Container**(bg _color-background_, top shadow) └─ **Padding**(_spacing-medium = 16_ all) └─ **Row**(crossAxis: center) ├─ _가격 영역_ ← ㉠ │ └─ **Column**(crossAxis: start) │ ├─ _"최저가"_ (labelSmall · text-secondary · w600) │ └─ _가격 금액_ (titleLarge · w700 · _color-secondary_) │ · 가격이 미정인 상태에서는 라벨이 다른 안내 문구로 대체될 수 있음 (child spec) │ ├─ Gap: _spacing-large (24)_ │ └─ _CTA 버튼_ ← ㉡ └─ **MinglitButton** / **MinglitButton.destructive** (flex: 1, height 48) · 라벨: 입장 상태에 따라 "구매하기" / "입장권 보기" / "참여 취소" / "신청 마감" 등으로 변함 (child spec 12-state) · 비활성 상태에서는 회색 + 클릭 불가 · 파괴적 액션(참여 취소 등)에서는 빨강 톤 _※ 자세한 라벨 / 색상 / 비활성 분기는 EventBottomTicketBar spec._

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| — | Bar 외부 | 풀폭 · 화면 하단 고정 · row crossAxis center | height ≈ 80 (padding 포함) · padding spacing-medium (16) all · bg color-background · 상단 soft shadow |
| ㉠ | 가격 영역 | row leading · column crossAxis start | 라벨 labelSmall w600 color-text-secondary · 금액 titleLarge w700 color-secondary |
| — | 가격 ↔ 버튼 gap | — | spacing-large (24) |
| ㉡ | CTA 버튼 | flex: 1 · 우측 풀폭 흡수 | height 48 · radius radius-card (12) · text labelLarge w600 · bg color-primary (활성) / color-divider (비활성) / color-error (파괴적) |
| — | SafeArea | bottom (iOS home indicator) | top: false — 하단 시스템 영역만 인셋 |

🎨

## States

6 states (Default · Loading · Error + 3 tab-focused: §3 참가 현황 / §4 필요 인증 / §5 환불 정책). 모든 상태는 동일한 **단일 CustomScrollView** + scroll-spy TabBar — 탭은 화면 전환이 아닌 scroll shortcut + 활성 indicator. 각 state는 mini-table 6-row (조건/사용자액션/에지케이스/컴포넌트/토큰/노트). Default가 baseline.

## State summary

한눈에 6 states 비교. 자세한 사양은 아래 각 mini-table 참조. Admission 분기 (참여 가능 / 마감 / 신청됨 / 거절 등)는 [EventBottomTicketBar](/specs/event_bottom_ticket_bar/index.html) child spec에서 다룸 — 이 spec은 페이지 본문 (탭 / 섹션)에 집중.

| State | Tag | 조건 (요약) | Key visual differentiator |
|---|---|---|---|
| Default 🎯 | primary | 데이터 로드 + 스크롤 top | Hero 풀 + TabBar(§1 기본정보 active) + §1 visible + §2 peek |
| Loading | async | 이벤트 데이터를 불러오는 중 | 전체 skeleton (hero + tabs + 섹션) |
| Error | network/server | 이벤트 데이터를 받지 못한 상태 | 전체 화면 안내 + "다시 시도" CTA |
| §3 참가 현황 active | scrolled | 참가 현황 섹션이 화면 상단에 도달 | Collapsed AppBar + TabBar §3 auto-active + 참여 게이지 카드 리스트 |
| §4 필요 인증 active | scrolled | 필요 인증 섹션이 화면 상단에 도달 | Collapsed AppBar + TabBar §4 auto-active + 인증 카드 리스트 (✓ / ! status) |
| §5 환불 정책 active | scrolled | 환불 정책 섹션이 화면 상단에 도달 | Collapsed AppBar + TabBar §5 auto-active + 환불 비율 table (시점별 %) |

## States gallery

각 state mini-table — mockup(rowspan=6) + 6 aspect rows. **Default가 baseline**; 나머지 5 states는 additive diff (`+` · `−` · `↔ X → Y` · `동일` · `—`). 모든 mockup은 동일 **단일 CustomScrollView** 구조 (5개 섹션이 한 페이지에 연속 배치) — 탭은 scroll-spy. TabBar는 scroll-spy: 현재 보이는 섹션이 자동 강조되며, 탭 탭은 그 섹션으로 animate-scroll. State 1은 스크롤 top(§1 기본 정보 + §2 상세 소개 시작), State 4는 scrolled mid-page(§3 참가 현황 active)를 보여줌. 각 state mockup의 viewport 안에 살짝 보이는 다음 섹션이 "이건 스크롤 페이지다"를 시사.

![visual](visual_1.png)

## AppBar — visual

AppBar는 스크롤에 따라 두 모습으로 나타난다 — 펼친 상태(① 위에 떠 있는 흰색 아이콘 모드)와 접힌 상태(56px 고정 바 + 이벤트 타이틀이 가운데 노출). 어두운 그라데이션과 흰색 아이콘이 결합되어 어떤 이미지 위에서도 가독성이 유지되고, 접힌 뒤에는 onSurface 톤으로 자연스럽게 자리잡는다.

![visual](visual_2.png)

| 상태 | 아이콘 색 | 배경 / 강조 |
|---|---|---|
| 펼친 상태 | 흰색 (back · ⋮) | 이미지 위에 검정 0.5 → 투명 그라데이션 80px · 점 인디케이터 흰색 |
| 접힌 상태 | onSurface (텍스트 톤) | 배경 color-background · 하단 1px color-divider · 이벤트 타이틀 titleMedium w600 1줄 ellipsis |
| 다크 모드 (펼친) | 흰색 유지 (브랜드 톤) | 그라데이션은 그대로 — 어떤 이미지 위에서도 가독성 보장 |
| 다크 모드 (접힌) | onSurface (다크 토큰) | 배경 다크 background · divider 다크 톤으로 자동 전환 |

※ 펼친 상태에서 ⋮ 메뉴는 **로그인 + 파트너 존재** 시에만 노출. 접힌 상태에서도 동일 — 메뉴 항목(차단 / 신고)도 같음.

## Bottom CTA bar — visual

⑥ Bottom CTA bar는 입장 가능 여부와 사용자 상태에 따라 라벨 / 색이 바뀐다 — 같은 80px 골격 안에서 가격 영역 + CTA 버튼 두 슬롯의 톤만 달라진다. 여기서는 자주 마주치는 4개 변형을 한눈에 비교할 수 있도록 모았고, 자세한 12-state 매트릭스는 child spec 참고.

![visual](visual_3.png)

| 변형 | CTA 색 | 가격 영역 톤 |
|---|---|---|
| 참여 가능 (기본) | bg color-primary · 흰 글자 | "최저가" + 금액 color-secondary 강조 |
| 신청됨 (입장권 보기) | bg color-primary · 흰 글자 · leading 티켓 아이콘 | "결제 완료" + 금액 color-text-primary |
| 마감 (비활성) | bg color-divider · 글자 color-text-secondary · 클릭 불가 | 금액도 color-text-secondary로 흐리게 |
| 참여 취소 (파괴적) | bg color-error · 흰 글자 | "결제 완료" + 금액 color-text-primary |

※ 자세한 12-state 매트릭스(심사 안내 banner / 자격 요건 미충족 / 거절 / 환불 진행 등)는 [`EventBottomTicketBar`](/specs/event_bottom_ticket_bar/index.html) child spec 참고.

🔄

## Global Behavior

Cross-cutting / global only — 모든/다수 state에 동일하게 적용되는 동작. state-specific 인터랙션은 위 States section의 각 state mini-table 참조.

## Cross-cutting interactions

| 사용자 액션 | 화면에 보이는 결과 |
|---|---|
| 뒤로 가기 (OS back / AppBar 뒤로 버튼) | 이전 화면으로 이동 — 모든 state에서 동일. |
| 풀-다운 새로고침 | 이벤트 데이터를 다시 받아옴. Loading 상태로 돌아가지 않고 기존 콘텐츠는 유지하면서 최신 참여 현황 / 가격 등을 갱신. |
| OpenInAppBanner "앱에서 열기" 탭 | OS 기본 앱 연결 시트 또는 앱스토어로 이동 — 딥링크로 진입한 경우에만 노출. |
| OpenInAppBanner 닫기 | 배너가 사라지고 아래 콘텐츠가 더 넓게 표시. 세션 내에서 다시 표시되지 않음. |
| VerificationCard 탭 | 인증 상세 화면으로 이동 예정 — 현재는 "구현 준비 중입니다" 안내 (모든 state에서 동일). |

※ state-specific 액션 (히어로 carousel · 탭 탭 · 좋아요 · 공유 · ⋮ 메뉴 등 Default state에서만 / BottomTicketBar 12-state별 분기 등)은 위 States section의 mini-table에 분산.

## Motion & timing

**임시값 사용 금지** — duration은 `MinglitAnimation` 토큰에서 선택.

| Token | Value | Use case |
|---|---|---|
| MinglitAnimation.micro | 100ms | 좋아요 칩 토글 · ripple |
| MinglitAnimation.fast | 200ms | 다이얼로그 scale fade-in |
| MinglitAnimation.medium | 350ms | AnimatedSwitcher (loading → data crossfade) · 티켓 sheet slide-up · 탭→섹션 scroll |
| (OS default) hero carousel · AppBar title fade | ~150–250ms | PageView · SliverAppBar collapse mode default |

| Transition | Duration (token) | Curve / notes |
|---|---|---|
| 화면 진입 (loading → data) | medium (350ms) | AnimatedSwitcher crossfade — 스켈레톤에서 실제 콘텐츠로 부드럽게 전환 |
| Hero 이미지 carousel 스와이프 | ~250ms (PageView default) | PageView 기본 slide · dot indicator 동기 |
| 스크롤 시 AppBar 타이틀 fade-in/out | ~150ms (SliverAppBar default) | SliverAppBar CollapseMode.pin |
| 탭 탭 → 섹션 scroll | medium 근사 (300ms) | easeInOut. 탭 탭 직후 잠깐은 자동 갱신이 멈춰 충돌하지 않음. |
| 좋아요 칩 토글 | micro (100ms) | 배경색 fade · 즉각 피드백 |
| 티켓 선택 sheet 출현 | medium 근사 (300ms hardcode) | Material showModalBottomSheet slide-up |
| 확인 다이얼로그 진입 | fast (200ms) | Material Dialog scale fade-in |

## Global edge cases

화면 전반에 영향을 주는 edge case. state-specific edge case는 위 States section의 각 mini-table 에지케이스 행에.

-   **이미지 없음** — `MinglitImageCarousel`은 빈 imageUrls 처리. 이미지 영역에 placeholder 배경 표시.
-   **파트너가 null (party 없음)** — 파트너 행 숨김 + ⋮ 메뉴 숨김. 이벤트 제목은 `event.title`로 폴백.
-   **entryGroups 없음 (단순 이벤트)** — 참가 현황에 "N명 / M명" 텍스트만 표시 (게이지 없음).
-   **필요 인증 없음** — "별도의 인증이 필요하지 않습니다." 문구 표시.
-   **OpenInAppBanner** — 딥링크로 진입한 경우만 하단 배너 표시. 스크롤 콘텐츠와 겹침 — 배너 닫으면 스크롤 영역 확보.
-   **네트워크 끊김** — Error state 진입. RefreshIndicator로 재시도 가능.
-   **다크 모드** — 히어로 아이콘(expanded): 흰색 유지 (브랜드 감성, primary container). collapsed 상태: onSurface 색상으로 자동 전환. 카드 배경 / 섹션 divider / 탭 언더라인 모두 mds 다크 토큰 자동 반영. 가격 색상: `color-secondary` 유지.
-   **접근성** — TabBar는 Material 기본 a11y. 히어로 carousel은 dot 위치를 screen reader가 읽음. ⋮ 메뉴는 popup으로 키보드 nav 가능.

※ **BottomTicketBar 관련 edge** (가격 미정 · admissionState loading/error 등)는 [EventBottomTicketBar](/specs/event_bottom_ticket_bar/index.html) spec에 있음.

📖

## Reference

Implementation source + 인접 화면 link만. **Components / Tokens는 States section의 각 mini-table**에 분산됨.

## Implementation source

| 항목 | Path / Reference |
|---|---|
| Widget class | EventDetailPage + _EventDetailContent + _BottomTicketBar (모두 같은 파일에 part of) |
| File path | apps/app_user/lib/src/features/event/detail/event_detail_page.dart |
| Part files | event_detail_content.dart · event_bottom_ticket_bar.dart · event_entry_conditions_section.dart · event_verification_section.dart · event_refund_policy_section.dart · event_quill_viewer.dart · event_info_tile.dart · event_detail_content_skeleton.dart |
| Controller / Provider | eventDetailControllerProvider(eventId) · event_detail_controller.dart |
| Coordinator | eventCoordinatorProvider · event_coordinator.dart — pushPartnerDetail · pushLogin · 등 |
| Admission state | eventAdmissionControllerProvider(event) — see EventBottomTicketBar spec |
| Route | EventDetailRoute · path: /events/:eventId · app_routes.dart |

## Related screens

| Spec | Relation |
|---|---|
| HomePage | 피드 카드 탭 → 이 화면으로 진입 (주 경로). 태그 chip 탭 → TagEventListPage → 이 화면. |
| EventBottomTicketBar | ⑥ 영역 — 별도 spec으로 분리. 12 admission state · 입장권/구매하기 라벨 redesign · 심사 안내 banner. |
| PartnerDetailPage (TBD spec) | 파트너 row 탭 시 진입 — event_coordinator.pushPartnerDetail() |
| EventApplicationWizard (TBD spec) | "구매하기" → 티켓 선택 sheet → wizard로 진입 |
| LoginPage | 비로그인 + "좋아요" 탭 시 진입 (auth-required interaction) |
| PartyCreateWizardPage | 파트너가 이 이벤트를 만든 화면. 같은 event 데이터의 생산자 측. |
| SettlementDetailPage | 이 이벤트의 매출에서 발생한 정산을 파트너가 확인하는 화면. |

## ✅ Authoring checklist

-   ✅ **Header** — Title (h1)만
-   ✅ **Overview** — Status (🚧 디자인중) · App · Category · Route · Path · Purpose · Entry/Exit · Background · Frequency 모두 채움
-   ✅ **History** — 1.0 (initial) · 1.2 (scroll-spy + §1 sub-anatomy) · 1.3 (BottomTicketBar 분리) · 2.0 (새 템플릿 마이그레이션) 4 row
-   ✅ **Layout — top blueprint** — Hero + TabBar + 5 sections + BottomTicketBar (⑥은 별도 spec link)
-   ✅ **Layout — Sub-anatomy** — §1 기본 정보 작성됨. 다른 section sub-anatomy는 추후 확장 (현재는 ⑥ → 별도 spec)
-   🚧 **Layout — Sub-anatomy 확장 TODO** — §2 상세 소개(QuillViewer) · §3 참가 현황(EntryGroupDetail+Gauge) · §4 필요 인증(VerificationCard) · §5 환불 정책 — 향후 추가
-   ✅ **States — 종류** — Default · Loading · Error · Mid-scroll · Already Joined · Full (총 6)
-   ✅ **States — mini-table 6 rows** — 6 state 모두 (조건/액션/에지/컴포넌트/토큰/노트)
-   ✅ **States — Default baseline 풀 리스트** — 컴포넌트 + 토큰 풀 명시
-   ✅ **States — additive diff** — Loading은 ↔ Skeleton, Error는 ↔ ErrorState 등 5종 prefix 사용
-   ✅ **State summary matrix** — 6 state 한눈 비교 표 추가됨 (5+ states 권장 충족)
-   ✅ **Global Behavior — cross-cutting only** — 뒤로가기 · pull-to-refresh · OpenInAppBanner · VerificationCard 등. state-specific은 mini-table로 이동.
-   ✅ **Global Behavior — Motion** — MinglitAnimation token 매핑 표 + transitions 표 (token 이름 + ms)
-   ✅ **Global edge cases** — 이미지 없음 · 파트너 null · entryGroups 없음 · 인증 없음 · OpenInAppBanner · 네트워크 · 다크모드 · 접근성
-   ✅ **Reference — Implementation source** — 모든 항목 채움 (widget · path · parts · controller · coordinator · admission · route)
-   ✅ **Reference — Related screens** — Home · BottomTicketBar(분리됨) · PartnerDetail · ApplicationWizard · Login · PartyCreate · Settlement
-   ✅ **Token 표기 통일** — 모든 토큰 `name (px)` 형태 또는 typography `name (size/weight)`
-   🚧 **코드 검증** — ad-hoc trigger 기반 (status가 디자인중). BottomTicketBar 라벨 변경 + 후속 redesign이 코드에 반영되면 multi-pass verify 후 History row 추가