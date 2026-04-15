# Settings/MyPage Design System Redesign

> Issue: #1475
> Status: Design Spec
> Last Updated: 2026-04-15

## 1. Problem Statement

현재 설정 화면(User App MyPage, Partner App MorePage)의 문제점:

| 문제 | 현재 상태 | 목표 |
|------|-----------|------|
| 레이아웃 | raw `ListTile`, 카드 그룹 없음 | 카드 기반 섹션 그룹 |
| 밀도 | ~56px 높이, 넓은 간격 | 48px compact 타일 |
| 정보 | 현재 값 subtitle 없음 | 테마, 알림 등 현재 값 표시 |
| 일관성 | trailing 위젯 불일치 | chevron/switch/value 패턴 통일 |
| 구분 | plain `Divider()` | 시맨틱 카드 그룹 + 섹션 헤더 |

벤치마크: Claude 앱 수준의 compact, information-dense 설정 화면.

---

## 2. Design Tokens (기존 토큰만 사용)

### 사용하는 토큰

| 용도 | 토큰 | 값 |
|------|------|----|
| 타일 제목 | `bodyMedium` | 16px normal |
| 타일 부제 (현재 값) | `bodySmall` | 13px |
| 섹션 헤더 | `labelMedium` | 12px w500 |
| 프로필 이름 | `titleMedium` | 16px bold |
| 프로필 부제 | `bodySmall` | 13px |
| 아이콘 사이즈 | `MinglitIconSize.small` | 20px |
| 카드 라운딩 | `MinglitRadius.card` | 16px |
| 화면 가장자리 | `MinglitSpacing.medium` | 16px |
| 그룹 간 간격 | `MinglitSpacing.large` | 24px |
| 타일 수평 패딩 | `MinglitSpacing.medium` | 16px |
| 타일 수직 패딩 | `MinglitSpacing.xsmall` | 4px |
| 섹션 헤더 하단 마진 | `MinglitSpacing.small` | 8px |

### 신규 토큰 제안 없음

모든 스펙은 기존 `MinglitSpacing`, `MinglitRadius`, `MinglitIconSize` 토큰으로 충족된다.

---

## 3. Component Specs

### 3.1 MinglitSettingsTile

설정 화면 전용 compact 타일 위젯.

```
┌─────────────────────────────────────────────────────┐
│ [icon 20px]  Title (bodyMedium 16px)    [trailing]  │  48px height
│              Subtitle (bodySmall 13px)              │
└─────────────────────────────────────────────────────┘
     ↕4px        ←16px→                    ←16px→
```

#### Properties

| Property | Type | 설명 |
|----------|------|------|
| `leading` | `IconData` | 좌측 아이콘 (20px, `onSurfaceVariant`) |
| `title` | `String` | 제목 (`bodyMedium`, 16px) |
| `subtitle` | `String?` | 현재 값 표시 (`bodySmall`, 13px, `onSurfaceVariant`) |
| `trailing` | `SettingsTileTrailing` | chevron / switch / value / none |
| `onTap` | `VoidCallback?` | 탭 액션 |
| `destructive` | `bool` | true이면 title/icon을 `error` 색상으로 표시 |

#### Trailing Types

| 타입 | 위젯 | 용도 |
|------|------|------|
| `navigation` | `Icon(Icons.chevron_right, size: 20, color: onSurfaceVariant)` | 페이지 이동 |
| `toggle` | `Switch.adaptive()` | on/off 토글 |
| `value` | `Text(value, style: bodySmall, color: onSurfaceVariant)` | 읽기 전용 값 표시 |
| `none` | 없음 | trailing 불필요 시 |

#### Layout Rules

- **Height**: 48dp (compact). subtitle이 있어도 48dp 유지 (2줄 텍스트가 아이콘 높이 안에 들어감).
- **Horizontal padding**: `MinglitSpacing.medium` (16px) 양쪽.
- **Vertical padding**: `MinglitSpacing.xsmall` (4px) 상하.
- **Icon-to-title gap**: `MinglitSpacing.medium` (16px).
- **Touch target**: 48dp minimum (Material accessibility guideline 충족).
- **Ink ripple**: bounded within tile area.
- **Icon color**: `colorScheme.onSurfaceVariant` (destructive일 때 `colorScheme.error`).
- **Title color**: `colorScheme.onSurface` (destructive일 때 `colorScheme.error`).
- **Subtitle color**: `colorScheme.onSurfaceVariant`.

### 3.2 MinglitSettingsGroup

카드 형태로 관련 설정 항목을 묶는 컨테이너.

```
            SECTION HEADER (labelMedium, uppercase)
          ┌─────────────────────────────────────────┐
          │  Setting Item 1                         │
          │─────────────────────────────────────────│  ← divider (left inset 56px)
          │  Setting Item 2                         │
          │─────────────────────────────────────────│
          │  Setting Item 3                         │
          └─────────────────────────────────────────┘
   ←16px→                                     ←16px→
                        ↕24px (group gap)
```

#### Properties

| Property | Type | 설명 |
|----------|------|------|
| `header` | `String?` | 섹션 헤더 텍스트 (optional) |
| `children` | `List<Widget>` | `MinglitSettingsTile` 목록 |

#### Layout Rules

- **Background**: `surfaceContainerLowest` (light) / `surfaceContainerHigh` (dark)
  - M3 `ColorScheme.fromSeed()`가 자동 생성하는 surface container 계열 사용.
  - 페이지 배경(`scaffoldBackgroundColor`)과 미세한 대비 제공.
- **Border radius**: `MinglitRadius.card` (16px).
- **Internal padding**: 0 (타일이 자체 패딩 처리).
- **Margin**: horizontal `MinglitSpacing.medium` (16px).
- **Gap between groups**: `MinglitSpacing.large` (24px).
- **Elevation**: 0 (플랫 디자인, 배경색 대비로만 구분).
- **Clip behavior**: `Clip.antiAlias` (첫/마지막 타일의 ripple이 radius를 넘지 않도록).

#### Section Header Rules

- **Typography**: `labelMedium` (12px, w500).
- **Transform**: uppercase (한글은 그대로, 영문만 해당).
- **Color**: `colorScheme.onSurfaceVariant`.
- **Alignment**: left, `MinglitSpacing.medium` (16px) padding.
- **Bottom margin**: `MinglitSpacing.small` (8px).

#### Internal Divider

- **Thickness**: 0.5px.
- **Color**: `colorScheme.outlineVariant`.
- **Left inset**: 56px (16px padding + 20px icon + 16px gap + 4px extra = 아이콘 이후 정렬).
- **Right inset**: 0.

### 3.3 Profile Area

프로필 섹션은 독립된 `MinglitSettingsGroup` 카드 안에 위치.

```
          ┌─────────────────────────────────────────┐
          │  ┌──────┐                               │
          │  │Avatar│  Name (titleMedium 16px bold)  [>]│
          │  │ 48px │  email@ex.com (bodySmall 13px)│
          │  └──────┘                               │
          └─────────────────────────────────────────┘
```

#### Layout Rules

- **Avatar**: `CircleAvatar(radius: 24)` → 48px diameter (기존 32px에서 증가).
- **Name**: `titleMedium` (16px bold), `colorScheme.onSurface`.
- **Email/info**: `bodySmall` (13px), `colorScheme.onSurfaceVariant`.
- **Trailing**: chevron (프로필 편집 진입).
- **Internal padding**: `MinglitSpacing.medium` (16px) all sides.
- **Avatar-to-text gap**: `MinglitSpacing.medium` (16px).
- **Top margin from AppBar**: `MinglitSpacing.medium` (16px).

---

## 4. Page Structure

### 4.1 Overall Layout

```
┌──────────────────────────────────┐
│  AppBar (no elevation, simple)   │
├──────────────────────────────────┤
│                                  │
│  [ScrollView]                    │
│    ↕16px (top padding)           │
│    ┌──── Profile Group ────┐     │
│    └───────────────────────┘     │
│    ↕24px                         │
│    SECTION HEADER                │
│    ┌──── Settings Group ───┐     │
│    └───────────────────────┘     │
│    ↕24px                         │
│    SECTION HEADER                │
│    ┌──── Settings Group ───┐     │
│    └───────────────────────┘     │
│    ...                           │
│    ↕ bottom safe area            │
│                                  │
└──────────────────────────────────┘
```

- **Page background**: `scaffoldBackgroundColor` (light: `#FFFFFF`, dark: `#0F0F0F`).
- **AppBar**: `title` only, `elevation: 0`, `scrolledUnderElevation: 0`.
- **ScrollView**: `ListView` with `padding: EdgeInsets.only(top: medium, bottom: safeArea)`.

### 4.2 User App (MyPage) 시맨틱 그룹

| # | 그룹 | 헤더 | 항목 | trailing |
|---|------|------|------|----------|
| 1 | 프로필 | (없음) | Avatar + 이름 + 이메일 | chevron |
| 2 | 활동 | 활동 | 구매 내역 | chevron |
|   |      |      | 내 티켓 | chevron |
| 3 | 설정 | 설정 | 알림 설정 | chevron |
|   |      |      | 테마 (subtitle: 현재 모드) | chevron |
| 4 | 개인정보 및 보안 | 개인정보 및 보안 | 개인정보 | chevron |
|   |                |                | 권한 설정 | chevron |
|   |                |                | 차단 목록 | chevron |
| 5 | 약관 및 정보 | 약관 및 정보 | 개인정보처리방침 | chevron |
|   |            |            | 이용약관 | chevron |
|   |            |            | 앱 버전 (subtitle: 버전 값) | value |
| 6 | 계정 | 계정 | 로그아웃 (destructive) | none |
| 7 | Dev | DEV | Design Catalog | chevron |

**Group 7 (Dev)**: `kDebugMode` 또는 환경 변수로 dev 환경에서만 표시.

### 4.3 Partner App (MorePage) 시맨틱 그룹

| # | 그룹 | 헤더 | 항목 | trailing |
|---|------|------|------|----------|
| 1 | 프로필 | (없음) | Avatar + 파트너 이름 + 이메일 | chevron |
| 2 | 비즈니스 관리 | 비즈니스 관리 | 멤버 관리 | chevron |
|   |              |              | 본인인증 관리 | chevron |
| 3 | 설정 | 설정 | 알림 설정 | chevron |
|   |      |      | 테마 (subtitle: 현재 모드) | chevron |
| 4 | 약관 및 정보 | 약관 및 정보 | 권한 | chevron |
|   |            |            | 개인정보처리방침 | chevron |
|   |            |            | 이용약관 | chevron |
|   |            |            | 앱 버전 (subtitle: 버전 값) | value |
| 5 | 계정 | 계정 | 로그아웃 (destructive) | none |
| 6 | Dev | DEV | Design Catalog | chevron |

---

## 5. Light / Dark Mode

### 5.1 Color Mapping

| 요소 | Light | Dark |
|------|-------|------|
| Page background | `#FFFFFF` (scaffoldBg) | `#0F0F0F` (scaffoldBg) |
| Card background | `surfaceContainerLowest` (M3 auto) | `surfaceContainerHigh` (M3 auto) |
| Title text | `onSurface` | `onSurface` |
| Subtitle text | `onSurfaceVariant` (`#4B5563`) | `onSurfaceVariant` (`#AAAAAA`) |
| Icon color | `onSurfaceVariant` | `onSurfaceVariant` |
| Divider | `outlineVariant` | `outlineVariant` |
| Destructive | `error` (`#EF4444`) | `error` (`#EF4444`) |
| Section header | `onSurfaceVariant` | `onSurfaceVariant` |

### 5.2 Surface Container 전략

M3의 `ColorScheme.fromSeed()`는 자동으로 `surfaceContainerLowest`~`surfaceContainerHighest` 계열을 생성한다.
이 자동 생성 색상을 활용하여 페이지 배경과 카드 배경 사이의 미세한 대비를 구현한다.

- Light: 페이지 `#FFFFFF` → 카드 `surfaceContainerLowest` (약간 따뜻한 회색)
- Dark: 페이지 `#0F0F0F` → 카드 `surfaceContainerHigh` (약간 밝은 회색)

---

## 6. Interaction

### 6.1 Tap Feedback

- **Navigation tiles**: InkWell ripple → 페이지 이동.
- **Toggle tiles**: Switch toggle, 타일 자체 탭도 토글 동작.
- **Destructive tiles**: ripple → 확인 다이얼로그 → 액션.
- **Value tiles** (앱 버전 등): 탭 불가, ripple 없음.

### 6.2 Animation

- Switch 토글: Material default animation (`MinglitAnimation.fast`, 200ms).
- 페이지 전환: 기존 라우터 전환 유지.

---

## 7. Accessibility

| 요소 | 처리 |
|------|------|
| Touch target | 48dp minimum height (WCAG) |
| Semantics | `Semantics(label: ...)` for icon-only items |
| Contrast | `onSurfaceVariant` vs card bg — WCAG AA 충족 (M3 보장) |
| Screen reader | tile 전체가 하나의 `Semantics` 노드 |

---

## 8. Implementation Notes

### 8.1 Widget Hierarchy

```dart
Scaffold(
  appBar: AppBar(title: Text('마이페이지')),
  body: ListView(
    padding: EdgeInsets.only(
      top: MinglitSpacing.medium,
      bottom: MediaQuery.of(context).padding.bottom + MinglitSpacing.large,
    ),
    children: [
      MinglitSettingsGroup(       // 프로필
        children: [ProfileTile(...)],
      ),
      SizedBox(height: MinglitSpacing.large),
      MinglitSettingsGroup(       // 활동
        header: '활동',
        children: [...],
      ),
      SizedBox(height: MinglitSpacing.large),
      // ...more groups
    ],
  ),
)
```

### 8.2 파일 구조 (제안)

```
shared/packages/minglit_kit/lib/src/ui/widgets/settings/
  ├── minglit_settings_tile.dart      # MinglitSettingsTile
  ├── minglit_settings_group.dart     # MinglitSettingsGroup
  └── minglit_settings_profile.dart   # Profile area widget

apps/app_user/lib/src/features/home/
  └── my_page.dart                    # 기존 파일 리팩터링

apps/app_partner/lib/src/features/more/
  └── more_page.dart                  # 기존 파일 리팩터링
```

### 8.3 Breaking Changes

- `ThemeSettingsTile`: `MinglitSettingsTile` 기반으로 리팩터링 필요.
- `my_page.dart`, `more_page.dart`: 전면 리팩터링 (기존 raw ListTile 교체).
- 기존 `MinglitListTile`은 변경 없음 (설정 외 화면에서 계속 사용).

---

## 9. Wireframe Reference

인터랙티브 와이어프레임: [`docs/features/settings-redesign/wireframe.html`](./wireframe.html)

- Current vs Redesigned 비교
- User App / Partner App 탭
- Light / Dark 모드 토글
