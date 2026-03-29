# 04. Navigation — 네비게이션 가이드

밍릿 앱의 네비게이션 구조와 규칙입니다.

---

## 1. BottomNav (하단 네비게이션)

### 유저 앱

유저 앱은 BottomNav Shell을 사용하지 않음. 모든 라우트가 독립 top-level.

**소스**: `apps/app_user/lib/src/routing/app_routes.dart`

| 주요 경로 | 페이지 |
| :--- | :--- |
| `/` | HomePage |
| `/search` | SearchPage |
| `/my` | MyPage |

### 파트너 앱

**소스**: `apps/app_partner/lib/src/ui/shell/partner_scaffold.dart:53-79`

| # | 아이콘 | 라벨 | 경로 |
| :--- | :--- | :--- | :--- |
| 1 | `home` / `home_outlined` | 홈 | `/` |
| 2 | `assignment` / `assignment_outlined` | 신청관리 | `/applications` |
| 3 | `qr_code_scanner` / `qr_code_scanner_outlined` | 체크인 | `/checkin` |
| 4 | `account_balance` / `account_balance_outlined` | 정산 | `/settlement` |
| 5 | `more_horiz` / `more_horiz_outlined` | 더보기 | `/more` |

### 스타일 규칙

- 선택 상태 색상: `MinglitColors.primary` (`#9900FF`) — `minglit_design_tokens.dart:10`
- 미선택 상태 색상: `MinglitColors.textSecondary` (`#4B5563`) — `minglit_design_tokens.dart:28`
- 아이콘 크기: `MinglitIconSize.medium` (24px) — `minglit_design_tokens.dart:115`

---

## 2. AppBar

### 표준 AppBar

**소스**: `minglit_component_theme.dart:5-17`

| 속성 | 값 | 라인 |
| :--- | :--- | :--- |
| backgroundColor | `#FFFFFF` | :6 |
| elevation | 0 (플랫) | :7 |
| centerTitle | true | :8 |
| titleTextStyle | 18px / w600 / NotoSansKR | :10-16 |

### AppBar 유틸리티

**소스**: `minglit_theme.dart:12-58`

| 메서드 | 설명 | 라인 |
| :--- | :--- | :--- |
| `MinglitTheme.appBarLogo({height})` | 앱바 로고 위젯 (기본 높이 32) | :13-19 |
| `MinglitTheme.sliverAppBar({title, actions})` | Scroll-to-hide SliverAppBar (floating + snap) | :22-43 |
| `MinglitTheme.simpleAppBar({title, actions})` | 기본 AppBar (뒤로가기 자동 표시) | :46-58 |

### 규칙

- **목록 화면**: `sliverAppBar` 사용 (스크롤 시 숨김)
- **상세/편집 화면**: `simpleAppBar` 사용 (고정)
- **뒤로가기**: `automaticallyImplyLeading: true` (기본값)
- **액션 버튼**: 최대 2개 권장, 아이콘 크기 `MinglitIconSize.medium` (24px)

---

## 3. BottomSheet Navigation

바텀 시트 내부 네비게이션 패턴입니다.

### 표준 구조

```text
[DragHandle]                    — 상단 드래그 핸들
[SafeArea]
  [Padding: MinglitSpacing.medium (16px)]
    [Column(mainAxisSize: min)]
      [Title]                   — titleMedium
      [Content / Options]       — ListTile 기반 옵션 목록
      [Action Buttons]          — 하단 확인/취소
```

### 스타일 규칙

- 곡률: `MinglitRadius.card` (16px) — 상단 모서리
- 패딩: `MinglitSpacing.medium` (16px)
- 옵션 선택: `MinglitColors.primary` 강조 + `Icons.check_circle`
- 오버레이: `MinglitColors.scrim` (`#80000000`) — `minglit_design_tokens.dart:40`

### 사용 사례

- `PartyStatusEditSheet` (`apps/app_partner/lib/src/features/party/widgets/party_status_edit_sheet.dart`)

---

## 4. Deep Link

<!-- TODO: 딥링크 스킴 및 라우팅 규칙 코드 확인 후 업데이트 필요 -->

### 라우터 소스

| 앱 | 라우터 파일 |
| :--- | :--- |
| 유저 앱 | `apps/app_user/lib/src/routing/app_router.dart` |
| 파트너 앱 | `apps/app_partner/lib/src/routing/app_router.dart` |

### 규칙

- GoRouter 기반 선언적 라우팅
- 딥링크 수신 시 인증 상태에 따라 리다이렉트 처리
- 미인증 사용자: 로그인 화면 → 인증 후 원래 경로로 이동

---

## 5. Page Transition

화면 전환 애니메이션 규칙입니다.

### 기본 전환

| 전환 유형 | 애니메이션 | Duration |
| :--- | :--- | :--- |
| Push (forward) | Material 기본 (slide from right) | `MinglitAnimation.medium` (350ms) |
| Pop (back) | Material 기본 (slide to right) | `MinglitAnimation.medium` (350ms) |
| BottomSheet 등장 | Slide up | `MinglitAnimation.medium` (350ms) |
| Dialog 등장 | Fade + Scale | `MinglitAnimation.fast` (200ms) |

**Duration 소스**: `minglit_design_tokens.dart:125-134`

<!-- TODO: 커스텀 page transition builder 정의 필요. 현재는 Material 기본 전환 사용. -->

---

## 관련 문서

- [02-components.md](02-components.md) -- AppBar, BottomSheet 컴포넌트
- [05-motion.md](05-motion.md) -- 모션/전환 상세
- [기존 파트너 앱 디자인 시스템](../partner-app/design-system.md)

---

*소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
