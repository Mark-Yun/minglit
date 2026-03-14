# 파트너 앱 디자인 시스템 (Design System)

이 문서는 밍릿 파트너 앱(`app_partner`)의 일관된 사용자 경험과 시각적 정체성을 유지하기 위한 디자인 시스템 레퍼런스입니다. 모든 UI 컴포넌트는 `minglit_kit` 패키지에 정의된 디자인 토큰과 테마를 기반으로 구축됩니다.

---

## 1. 개요

밍릿 파트너 앱의 디자인 시스템은 파트너(사장님)가 매장·파티·이벤트를 효율적으로 운영할 수 있도록 신뢰감과 사용성을 강조합니다. Material 3 기반 위에 3-Layer 테마 구조를 적용합니다.

- **참조 문서**:
  - [클라이언트 아키텍처](../../architecture/client.md) — Feature-first 구조, Coordinator 패턴, Repository 패턴
  - [화면 카탈로그](./screen-catalog.md) — 파트너 앱 전체 화면 목록
- **소스 경로**: `shared/packages/minglit_kit/lib/src/theme/`
- **테마 진입점**: `minglit_theme.dart` (part 파일 3개 포함)

### 3-Layer 테마 구조

| Layer | 역할 | 파일 |
| :--- | :--- | :--- |
| Layer 1 | 폰트·텍스트 통일 (NotoSansKR) | `minglit_theme.dart` |
| Layer 2 | Material 컴포넌트 커스터마이징 | `minglit_component_theme.dart` |
| Layer 3 | 브랜드 상수 (색상·간격·곡률 등) | `minglit_design_tokens.dart` |

---

## 2. 디자인 토큰 (Design Tokens)

디자인 토큰은 UI의 가장 작은 단위로, 색상·간격·곡률·아이콘 크기·애니메이션 지속 시간을 상수로 관리합니다.

**소스**: `shared/packages/minglit_kit/lib/src/theme/minglit_design_tokens.dart:L5-L134`

---

### 2.1 MinglitColors (라이트 모드)

브랜드의 핵심 색상과 UI 상태를 나타내는 컬러 팔레트입니다.

**소스**: `minglit_design_tokens.dart:L5-L41`

| 토큰명 | 값 (Hex) | 용도 |
| :--- | :--- | :--- |
| `primary` | `#9900FF` | 브랜드 주색상 (Purple) |
| `secondary` | `#FF9900` | 보조 색상 Auxiliary 1 (Amber) |
| `tertiary` | `#48C9B0` | 강조 색상 Toned-down Mint |
| `background` | `#FFFFFF` | 기본 배경색 |
| `surface` | `#F9FAFB` | 카드·입력 필드 배경색 (부드러운 회색) |
| `textPrimary` | `#111827` | 주요 텍스트 (Near-black) |
| `textSecondary` | `#4B5563` | 보조 텍스트 (Dark gray) |
| `error` | `#EF4444` | 에러 상태 |
| `success` | `#22C55E` | 성공 상태 |
| `warning` | `#F59E0B` | 경고 상태 |
| `transparent` | `#00000000` | 완전 투명 |
| `scrim` | `#80000000` | 오버레이 배경 (50% 불투명 검정) |

---

### 2.2 MinglitColorsDark (다크 모드)

다크 모드 대응을 위한 컬러 팔레트입니다. `secondary`, `tertiary`, `error`는 라이트 모드와 동일 값을 공유합니다.

**소스**: `minglit_design_tokens.dart:L43-L59`

| 토큰명 | 값 (Hex) | 비고 |
| :--- | :--- | :--- |
| `primary` | `#AA33FF` | 라이트보다 밝게 조정 |
| `background` | `#0F0F0F` | |
| `surface` | `#212121` | |
| `textPrimary` | `#FFFFFF` | |
| `textSecondary` | `#AAAAAA` | |
| `divider` | `#3D3D3D` | 다크 모드 전용 구분선 |
| `secondary` | `#FF9900` | `MinglitColors.secondary`와 동일 |
| `tertiary` | `#48C9B0` | `MinglitColors.tertiary`와 동일 |
| `error` | `#EF4444` | `MinglitColors.error`와 동일 |

---

### 2.3 MinglitSpacing (간격)

일관된 레이아웃을 위한 스페이싱 스케일입니다. `double` 타입 상수.

**소스**: `minglit_design_tokens.dart:L62-L89`

| 토큰명 | 값 (px) | 용도 |
| :--- | :--- | :--- |
| `zero` | 0 | 간격 없음 |
| `xxsmall` | 2 | 미세 간격 |
| `xsmall` | 4 | 요소 내 좁은 간격 |
| `xsmall2` | 6 | 중간 좁은 간격 |
| `small` | 8 | 일반적인 좁은 간격 |
| `sm` | 12 | 요소 간 중간 간격 |
| `medium` | 16 | 기본 여백 (Standard padding) |
| `large` | 24 | 섹션 간 간격 |
| `xlarge` | 32 | 큰 섹션 간 간격 |

---

### 2.4 MinglitRadius (곡률)

컴포넌트의 모서리 둥글기 값입니다. `double` 타입 상수.

**소스**: `minglit_design_tokens.dart:L92-L104`

| 토큰명 | 값 (px) | 용도 |
| :--- | :--- | :--- |
| `small` | 8 | 작은 요소 (상태 뱃지, 체크박스 등) |
| `input` | 12 | 입력 필드 (TextField) |
| `button` | 16 | 버튼 (ElevatedButton, OutlinedButton) |
| `card` | 24 | 카드·바텀 시트·이미지 클리핑 |

---

### 2.5 MinglitIconSize (아이콘 크기)

아이콘의 표준 크기 가이드입니다. `double` 타입 상수.

**소스**: `minglit_design_tokens.dart:L107-L122`

| 토큰명 | 값 (px) | 용도 |
| :--- | :--- | :--- |
| `xsmall` | 16 | 인라인 텍스트 옆 아이콘 |
| `small` | 20 | 리스트 아이템 보조 아이콘 |
| `medium` | 24 | 기본 아이콘 (Material 기본값) |
| `large` | 28 | 강조 아이콘 |
| `xlarge` | 32 | 대형 아이콘 (빈 상태 화면 등) |

---

### 2.6 MinglitAnimation (애니메이션)

사용자 인터랙션 피드백을 위한 표준 지속 시간입니다. `Duration` 타입 상수.

**소스**: `minglit_design_tokens.dart:L125-L134`

| 토큰명 | 값 (ms) | 용도 |
| :--- | :--- | :--- |
| `fast` | 200 | 간단한 상태 변화 (선택, 토글) |
| `medium` | 350 | 화면 전환·모달 등장 |
| `slow` | 500 | 복잡한 레이아웃 변화 |

---

## 3. 유틸리티 클래스 (Design Utils)

토큰을 조합한 재사용 가능한 스타일 프리셋입니다.

**소스**: `shared/packages/minglit_kit/lib/src/theme/minglit_design_utils.dart`

| 클래스 | 주요 메서드 | 설명 |
| :--- | :--- | :--- |
| `MinglitShadows` | `cardSelected(Color accentColor)` | 선택된 카드 그림자 — accentColor 10% 불투명, blurRadius 8, offset (0,4) |
| `MinglitBorders` | `card(ColorScheme, {isSelected})` | 카드 테두리 — 선택 시 `secondary`, 미선택 시 `outlineVariant` |
| `MinglitDecorations` | `selectableCard(context, {isSelected})` | 선택 가능한 카드 전체 BoxDecoration (색상+곡률+테두리+그림자 통합) |
| `MinglitTextStyles` | `selectableCardTitle`, `selectableCardSubtitle`, `selectableCardDescription`, `infoText` | 카드 내 텍스트 스타일 프리셋 |

---

## 4. 컴포넌트 테마 (Component Themes)

Material 3 기반 컴포넌트들을 밍릿 스타일로 커스터마이징한 설정값입니다.

**소스**: `shared/packages/minglit_kit/lib/src/theme/minglit_component_theme.dart`

| 컴포넌트 | 주요 설정값 |
| :--- | :--- |
| **AppBar** | `elevation: 0`, `centerTitle: true`, `bg: #FFFFFF`, `titleTextStyle: 18px/w600/NotoSansKR` |
| **ElevatedButton** | `minSize: ∞×56`, `radius: 16`, `bg: primary(#9900FF)`, `fg: white`, `text: 16px/bold`, `elevation: 0` |
| **OutlinedButton** | `minSize: ∞×56`, `radius: 16`, `border: primary`, `fg: primary`, `text: 16px/bold` |
| **TextButton** | `fg: primary`, `text: 14px/bold` |
| **Card** | `elevation: 0`, `radius: 24`, `color: surface(#F9FAFB)`, `margin: zero` |
| **InputDecoration** | `filled: true`, `fillColor: surface`, `radius: 12`, `border: none`, `focusedBorder: primary 2px`, `contentPadding: 16` |
| **Chip** | `radius: 100(pill)`, `side: none`, `bg: surface`, `selectedColor: primary`, `labelStyle: 13px` |
| **Checkbox** | `selectedFill: primary`, `shape: radius 4`, `side: grey 1.5px` |
| **TabBar** | `labelColor: primary`, `unselectedColor: textSecondary`, `indicatorColor: primary`, `indicatorSize: tab`, `dividerColor: transparent` |
| **Divider** | `color: #E5E7EB`, `thickness: 1`, `space: 16` |

---

## 5. 위젯 패턴 카탈로그 (Widget Patterns)

파트너 앱에서 반복적으로 사용되는 주요 UI 패턴과 대표 예시입니다.

### 5.1 Card (정보 카드)

데이터 요약이나 목록 항목을 표시할 때 사용합니다. `MinglitRadius.card(24)` + `elevation: 0` 조합이 기본입니다.

- **대표 예시**: `apps/app_partner/lib/src/features/home/widgets/revenue_summary_card.dart`
  - `Card` + `InkWell` 조합으로 탭 가능한 카드 구현
  - `colorScheme.surfaceContainerHighest` 배경, `MinglitSpacing.large(24)` 패딩
- **사용 화면**: 홈 대시보드, 파티 목록, 수익 관리 → [화면 카탈로그](./screen-catalog.md) 참조

### 5.2 Summary (요약 정보)

상세 화면 상단에서 핵심 정보를 브리핑할 때 사용합니다. 이미지 캐러셀 + 상태 뱃지 + 제목 + 설명 구조가 표준입니다.

- **대표 예시**: `apps/app_partner/lib/src/features/party/widgets/party_basic_info_summary.dart`
  - 상태 뱃지: `active(primary)` / `draft(outline)` / `closed(error)` 색상 분기
  - 설명 영역: `flutter_quill` 리치 텍스트 뷰어, `collapsible` 옵션 지원
  - 이미지: `MinglitImageCarousel` + `MinglitRadius.card` 클리핑
- **사용 화면**: 파티 상세, 이벤트 상세, 위자드 검토 단계

### 5.3 Input (입력 폼)

위자드나 편집 화면에서 정보를 입력받을 때 사용합니다. `InputDecorationTheme`이 전역 적용되므로 별도 스타일 불필요합니다.

- **대표 예시**: `apps/app_partner/lib/src/features/party/widgets/party_location_detail_input.dart`
- **사용 화면**: 파트너 신청(온보딩), 파티 생성/수정 위자드, 티켓 설정

### 5.4 BottomSheet (하단 시트)

부분 수정이나 옵션 선택 시 사용합니다. `SafeArea` + `Padding(MinglitSpacing.medium)` + `Column(mainAxisSize.min)` 구조가 표준입니다.

- **대표 예시**: `apps/app_partner/lib/src/features/party/widgets/party_status_edit_sheet.dart`
  - 상태 옵션: `active` / `draft` / `closed` — `ListTile` + 원형 아이콘 컨테이너
  - 선택 상태: `MinglitColors.primary` 강조 + `Icons.check_circle`
  - 공개 범위: `SwitchListTile` 추가 섹션
- **사용 화면**: 파티 상태 변경, 필터 선택

### 5.5 Dialog (다이얼로그)

중요한 확인이나 검색 등 독립적인 작업 시 사용합니다. `minglit_kit`의 `MinglitDialog`를 기반으로 합니다.

- **대표 예시**: `apps/app_partner/lib/src/features/onboarding/widgets/address_search_dialog.dart`
- **사용 화면**: 주소 검색, 삭제 확인, 권한 설정, 이벤트 신청 심사

### 5.6 List/Scroll (리스트 및 스크롤)

대량의 데이터를 나열할 때 사용합니다. `SliverList` 또는 `ListView.builder` 기반입니다.

- **대표 예시**: `apps/app_partner/lib/src/features/party/event/widgets/event_application_list_view.dart`
- **사용 화면**: 신청자 명단, 알림 센터, 정산 내역, 파티 목록

### 5.7 Badge/Banner (뱃지 및 배너)

상태 알림이나 가이드를 제공할 때 사용합니다.

- **대표 예시**: `apps/app_partner/lib/src/features/home/widgets/location_guide_banner.dart`
- **사용 화면**: 홈 대시보드 (미처리 항목 알림, 위치 설정 가이드)

---

## 6. 공유 컴포넌트 목록 (minglit_kit)

`minglit_kit` 패키지에서 `minglit_ui.dart`를 통해 export되는 공용 UI 컴포넌트입니다.

**소스**: `shared/packages/minglit_kit/lib/minglit_ui.dart`

| 컴포넌트명 | 용도 | 파일 경로 |
| :--- | :--- | :--- |
| `MinglitLoginScreen` | 공용 로그인 화면 | `src/features/auth/ui/minglit_login_screen.dart` |
| `StaffGateScreen` | 스태프 게이트 화면 | `src/features/auth/ui/staff_gate_screen.dart` |
| `StaffGuardWrapper` | 스태프 권한 가드 래퍼 | `src/features/auth/ui/staff_guard_wrapper.dart` |
| `MinglitGlobalLoadingOverlay` | 전역 로딩 오버레이 | `src/features/loading/minglit_global_loading_overlay.dart` |
| `NotificationListScreen` | 알림 목록 화면 | `src/features/notification/notification_list_screen.dart` |
| `NotificationSettingsScreen` | 알림 설정 화면 | `src/features/notification/notification_settings_screen.dart` |
| `LocationSearchScreen` | 위치 검색 화면 | `src/features/search/ui/location_search_screen.dart` |
| `MinglitSocialButton` | 소셜 로그인 버튼 | `src/features/social/ui/minglit_social_button.dart` |
| `IdentityVerificationScreen` | 본인인증 화면 | `src/features/verification/ui/identity_verification_screen.dart` |
| `MinglitAlert` | 표준 알림 팝업 | `src/ui/widgets/common/minglit_alert.dart` |
| `MinglitDialog` | 표준 다이얼로그 프레임 | `src/ui/widgets/common/minglit_dialog.dart` |
| `MinglitChip` | 정보 표시용 칩 | `src/ui/widgets/common/minglit_chip.dart` |
| `MinglitFilterChip` | 선택/필터용 칩 | `src/ui/widgets/common/minglit_filter_chip.dart` |
| `MinglitImage` | 네트워크 이미지 (캐싱) | `src/ui/widgets/common/minglit_image.dart` |
| `MinglitImageCarousel` | 이미지 캐러셀 | `src/ui/widgets/common/minglit_image_carousel.dart` |
| `MinglitParticipantGauge` | 참가자 게이지 바 | `src/ui/widgets/common/minglit_participant_gauge.dart` |
| `MinglitSkeleton` | 스켈레톤 로딩 | `src/ui/widgets/common/minglit_skeleton.dart` |
| `MinglitFilePicker` | 파일 선택기 | `src/ui/widgets/common/minglit_file_picker.dart` |
| `MinglitAsyncValueWidget` | AsyncValue 상태 처리 래퍼 | `src/ui/widgets/common/minglit_async_value_widget.dart` |
| `LoadingIndicator` | 공용 로딩 애니메이션 | `src/ui/widgets/common/loading_indicator.dart` |
| `NumberStepperInput` | 숫자 증감 입력 | `src/ui/widgets/common/number_stepper_input.dart` |
| `AddActionCard` | 항목 추가 액션 카드 | `src/ui/widgets/common/add_action_card.dart` |
| `VerificationCard` | 인증 정보 카드 | `src/ui/widgets/common/verification_card.dart` |
| `VerificationSelectCard` | 인증 선택 카드 | `src/ui/widgets/common/verification_select_card.dart` |
| `EntryGroupDetail` | 입장 그룹 상세 | `src/ui/widgets/common/entry_group_detail.dart` |
| `EventCard` | 이벤트 요약 카드 | `src/ui/widgets/party/event_card.dart` |
| `LocationMapView` | 위치 지도 뷰 | `src/ui/widgets/party/location_map_view.dart` |
| `PartnerDetailView` | 파트너 상세 뷰 | `src/ui/widgets/partner/partner_detail_view.dart` |
| `BugReporterWrapper` | 버그 리포트 래퍼 | `src/ui/widgets/bug_reporter_wrapper.dart` |

---

## 7. 앱 전용 위젯 목록 (app_partner)

파트너 앱의 비즈니스 로직에 특화된 전용 위젯들입니다. 피처별로 그룹핑합니다.

**소스 루트**: `apps/app_partner/lib/src/features/`

### Home

| 위젯명 | 용도 | 파일 경로 |
| :--- | :--- | :--- |
| `TodayPartyCard` | 오늘의 파티 요약 카드 | `home/widgets/today_party_card.dart` |
| `RevenueSummaryCard` | 수익 요약 카드 (대시보드) | `home/widgets/revenue_summary_card.dart` |
| `UpcomingEventsCard` | 다가오는 이벤트 카드 | `home/widgets/upcoming_events_card.dart` |
| `ClosingSoonEventsCard` | 마감 임박 이벤트 카드 | `home/widgets/closing_soon_events_card.dart` |
| `PendingApplicantsBadgeCard` | 미처리 신청자 뱃지 카드 | `home/widgets/pending_applicants_badge_card.dart` |
| `ApprovalWaitingCard` | 승인 대기 카드 | `home/widgets/approval_waiting_card.dart` |
| `ActivePartySummaryScroll` | 운영 중 파티 가로 스크롤 | `home/widgets/active_party_summary_scroll.dart` |
| `LocationGuideBanner` | 위치 설정 가이드 배너 | `home/widgets/location_guide_banner.dart` |

### Party

| 위젯명 | 용도 | 파일 경로 |
| :--- | :--- | :--- |
| `PartyListItem` | 파티 목록 아이템 | `party/list/widgets/party_list_item.dart` |
| `PartyBasicInfoSummary` | 파티 기본 정보 요약 (이미지+제목+설명) | `party/widgets/party_basic_info_summary.dart` |
| `PartyBasicInfoEditScreen` | 파티 기본 정보 편집 화면 | `party/widgets/party_basic_info_edit_screen.dart` |
| `PartyStatusEditSheet` | 파티 운영 상태 변경 바텀 시트 | `party/widgets/party_status_edit_sheet.dart` |
| `PartyDescriptionInput` | 파티 설명 입력 (Quill 에디터) | `party/widgets/party_description_input.dart` |
| `PartyImageEditor` | 파티 이미지 편집 | `party/widgets/party_image_editor.dart` |
| `PartyLocationInput` | 파티 위치 입력 | `party/widgets/party_location_input.dart` |
| `PartyLocationDetailInput` | 파티 위치 상세 입력 | `party/widgets/party_location_detail_input.dart` |
| `PartyLocationSummary` | 파티 위치 요약 | `party/widgets/party_location_summary.dart` |
| `PartyLocationEditScreen` | 파티 위치 편집 화면 | `party/widgets/party_location_edit_screen.dart` |
| `PartyCapacityInput` | 파티 정원 입력 | `party/widgets/party_capacity_input.dart` |
| `PartyCapacitySummary` | 파티 정원 요약 | `party/widgets/party_capacity_summary.dart` |
| `PartyCapacityContactEditScreen` | 파티 정원·연락처 편집 화면 | `party/widgets/party_capacity_contact_edit_screen.dart` |
| `PartyContactInput` | 파티 연락처 입력 | `party/widgets/party_contact_input.dart` |
| `PartyContactSummary` | 파티 연락처 요약 | `party/widgets/party_contact_summary.dart` |
| `PartyVerificationInput` | 파티 인증 설정 입력 | `party/widgets/party_verification_input.dart` |
| `PartyEntranceConditionSummary` | 파티 입장 조건 요약 | `party/widgets/party_entrance_condition_summary.dart` |
| `PartyEventListSummary` | 파티 이벤트 목록 요약 | `party/widgets/party_event_list_summary.dart` |

### Party — Ticket

| 위젯명 | 용도 | 파일 경로 |
| :--- | :--- | :--- |
| `PartyTicketTemplateInput` | 파티 티켓 템플릿 입력 | `party/ticket/widgets/party_ticket_template_input.dart` |
| `PartyTicketsSummary` | 파티 티켓 목록 요약 | `party/ticket/widgets/party_tickets_summary.dart` |

### Party — Event

| 위젯명 | 용도 | 파일 경로 |
| :--- | :--- | :--- |
| `EventCard` (파트너 전용) | 파트너 이벤트 카드 | `party/event/widgets/event_card.dart` |
| `TicketListItem` | 티켓 목록 아이템 | `party/event/widgets/ticket_list_item.dart` |
| `EventApplicationListView` | 이벤트 신청자 리스트 | `party/event/widgets/event_application_list_view.dart` |
| `EventApplicationReviewDialog` | 신청자 심사 다이얼로그 | `party/event/widgets/event_application_review_dialog.dart` |
| `EventBasicInfoSummary` | 이벤트 기본 정보 요약 | `party/event/widgets/event_basic_info_summary.dart` |
| `EventCapacitySummary` | 이벤트 정원 요약 | `party/event/widgets/event_capacity_summary.dart` |
| `EventContactSummary` | 이벤트 연락처 요약 | `party/event/widgets/event_contact_summary.dart` |
| `EventLocationSummary` | 이벤트 위치 요약 | `party/event/widgets/event_location_summary.dart` |
| `EventEntranceConditionSummary` | 이벤트 입장 조건 요약 | `party/event/widgets/event_entrance_condition_summary.dart` |
| `EventDateTimeInput` | 이벤트 날짜·시간 입력 | `party/event/widgets/event_date_time_input.dart` |

### Ticket

| 위젯명 | 용도 | 파일 경로 |
| :--- | :--- | :--- |
| `TicketForm` | 티켓 생성/편집 폼 | `ticket/widgets/ticket_form.dart` |

### Onboarding

| 위젯명 | 용도 | 파일 경로 |
| :--- | :--- | :--- |
| `AddressSearchDialog` | 주소 검색 다이얼로그 | `onboarding/widgets/address_search_dialog.dart` |

---

*소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
