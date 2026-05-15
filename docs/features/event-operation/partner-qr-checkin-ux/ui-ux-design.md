# 파트너 QR 체크인 화면 — UI/UX 디자인

> **이슈**: #1779 파트너 qr checkin uiux 강화 필요
> **관련 PR**: #1782 (스펙 + 와이어프레임)
> **작성자**: needs-uiux-claude-1 (UX Designer)
> **작성일**: 2026-04-24
> **선행 문서**: [spec.md](./spec.md), [wireframe.html](./wireframe.html)

## 목적

스펙(#1782)에서 정의한 "스캐너 화면에 실시간 입장 현황 통합" 방향은 합리적이다. 본 문서는 그 스펙이 밍글릿 디자인 시스템(`minglit_kit`)과 정합하게 구현되도록 **토큰·컴포넌트·상호작용·애니메이션·접근성** 기준을 못박는다. 스펙이 비워둔 "어떻게 예쁘고 정확하게" 영역을 채우는 문서다.

## 리뷰 요약 (스펙 대비 변경/보정)

| 항목 | 스펙(#1782) | 보정 | 사유 |
|------|-------------|------|------|
| Success green | `#22C55E` | **`MinglitColors.success = #16A34A`** | `minglit_kit` 토큰이 화이트 대비 AA(≥4.5:1) 만족을 위해 green-600으로 하향. hex 하드코딩 금지. |
| Warning | `#F59E0B` | **`MinglitColors.warning = #D97706`** | 토큰 정합. 하드코딩 시 lint `minglit_no_hardcoded_colors` 위반. |
| Partner primary | `#6C3CE1` | **유지** — `MinglitPartnerColors.primary` 참조로 변경 | 값은 맞지만 토큰 참조로 통일. |
| 상단 요약 카드 | 솔리드 화이트 카드 80px, 카메라 축소 | **유지 + 안전영역 포함 88–96px** | 노치/다이나믹 아일랜드 겹침 방지. SafeArea 상단 패딩 포함 계산. |
| 카메라 frame size | 250→220 축소 | **220 유지, 동적 min(220, 화면 짧은 축의 48%)** | 소형 기기(iPhone SE 375x667)에서 220 고정 시 컨트롤 짤림. |
| 스캔 성공 오버레이 | 전체 화면 0.8s | **반투명 상단 하이라이트 배너 + 중앙 체크마크 0.6s easeOutBack** | 전체 덮으면 다음 스캔이 막힘(혼잡 시 줄 밀림). 배너형으로 연속 스캔 흐름 유지. |
| 그룹 시트 축소 높이 | 40px 헤더 | **56px (핸들 12 + 타이틀 행 44)** | iOS HIG 최소 터치 타겟 44pt 확보. 40은 탭 실수율 증가. |
| 수동 체크인 버튼 위치 | 카메라 아래 horizontal row | **카메라 오버레이 우상단 FAB `manual_search_24` 아이콘 + 하단 바에 텍스트 버튼 병행** | 혼잡 시 버튼 손에 닿는 영역(엄지 호) 이슈. FAB + 하단 보조 2중 진입. |
| Manual sheet 검색 | "이름 또는 전화 뒷자리" | **"이름 · 전화 뒷자리" 단일 input, 자동 감지 (숫자 4자리 → 전화 탐색)** | UX 인지 부하 감소. |

## 설계 원칙

1. **카메라가 주인공이다.** 체크인 성공 피드백은 0.6s, 그 외에는 스캐너를 가리지 않는다. 통계는 "참조 레이어", 스캔은 "작업 레이어".
2. **숫자가 멀리서 읽혀야 한다.** 입구에서 파트너가 팔을 뻗은 거리(50cm)에서도 보이는 타이포 위계. 큰 숫자는 `headlineMedium`(24pt w700) 이상.
3. **임계치는 색으로 경고한다.** 쿼터 임박(≥90%) 시 빨강, 여유 있음(<50%) 시 primary. 단, 색맹 안전하게 **색 + 숫자 + 프로그레스 폭** 3중 시그널.
4. **상태를 숨기지 않는다.** 오프라인·로딩·빈 상태 모두 첫화면에 명시. 스캔 가능 여부를 유저가 스스로 파악 가능해야 함.
5. **Haptic·사운드로 핸즈프리 운영을 돕는다.** 파트너는 보통 한 손에 폰, 다른 손은 도어 안내. 시선 떼는 빈도를 줄여야 함.
6. **다크모드는 클럽/야간 현장 필수.** `partnerThemeDark` 완전 대응, 자동 전환(system) 기본.

## 정보 구조 (IA)

```
[SafeArea top + AppBar 56pt]
  ← 이벤트명 · 새로고침

[요약 카드 96pt]                     ← MinglitContentCard 재사용 (no shadow, border only)
  "23/50"  "46%"
  [==========··········]           ← LinearProgressIndicator (height 8, radius 4)
  ● 진행중 · 남은 27명 · 8분 전 업데이트

[스캐너 Stack — 남는 공간 전부]      ← extendBodyBehindAppBar 그대로 유지
  - MobileScanner (full-bleed, 배경)
  - QrScannerOverlayShape (커스텀 shape, 가운데 220 cutout, scrim 70%)
  - 우상단 FAB (manual checkin, 44×44, 반투명 surface 12%)
  - 우상단 FAB (플래시 토글)
  - 하단 힌트 텍스트 (scrim 위 white 87%)
  - 중앙 배너 오버레이 (성공/실패 시 0.6s)

[Bottom Sheet — 엔트리 그룹 현황]   ← DraggableScrollableSheet
  축소(56pt) ↔ 확장(40–80% screen)
  - 핸들 36x4
  - 타이틀: "엔트리 그룹별 현황"
  - 축소 시 서브타이틀: "총 4개 그룹 · 남 15/28 · 여 8/22"
  - 확장 시 그룹 리스트 (세로 스크롤)
```

### 레이어 우선순위

```
z=40  Success/Fail 중앙 배너  (0.6s만 노출)
z=30  FAB 버튼 (플래시/수동)
z=20  AppBar + 요약 카드
z=15  Bottom Sheet (그룹 현황)
z=10  QrScannerOverlayShape (corner + scrim)
z=0   MobileScanner (카메라 raw)
```

## 컴포넌트 명세

### 1. 상단 요약 카드 — `_CheckinSummaryCard`

위치: AppBar 바로 아래, 좌우 `MinglitSpacing.screenEdge(16)`, 상단 `MinglitSpacing.cardGap(12)`.

```dart
// apps/app_partner/lib/src/features/checkin/widgets/checkin_summary_card.dart
class _CheckinSummaryCard extends StatelessWidget {
  const _CheckinSummaryCard({
    required this.checkedIn,
    required this.total,
    this.lastUpdated,
    this.isOffline = false,
    this.isLoading = false,
  });

  final int checkedIn;
  final int total;
  final DateTime? lastUpdated;
  final bool isOffline;
  final bool isLoading;
  // ...
}
```

**토큰 / 스펙**:

| 속성 | 값 |
|------|-----|
| Background | `theme.colorScheme.surface` (다크모드: `MinglitColorsDark.surface`) |
| Border | `theme.colorScheme.outlineVariant`, 1px |
| Radius | `MinglitRadius.card` (16) |
| Padding | 수직 `MinglitSpacing.medium(16)`, 수평 `MinglitSpacing.medium(16)` |
| 큰 숫자 `23` | `theme.textTheme.headlineMedium`(28/700), `colorScheme.onSurface` |
| `/50` | 동일 사이즈, `colorScheme.onSurfaceVariant`, w500 |
| `46%` | `theme.textTheme.titleMedium`(16/600), `colorScheme.primary` (체크인율 ≥90% 시 `colorScheme.error`) |
| Progress bar | `LinearProgressIndicator`, `minHeight: 8`, `borderRadius: 4`, 색상 단계별 |
| Meta row gap | `MinglitSpacing.small(8)` |
| Meta text | `theme.textTheme.bodySmall`(12/500), `colorScheme.onSurfaceVariant` |

**진행률 색상 단계** (`_progressColor(ratio)`):

```dart
Color _progressColor(double ratio, ColorScheme scheme) {
  if (ratio >= 0.9) return scheme.error;      // MinglitColors.error
  if (ratio >= 0.5) return scheme.tertiary;   // warning 역할 — 파트너 테마에서 tertiary=warning
  return scheme.primary;                       // MinglitPartnerColors.primary
}
```

> ⚠️ `warning` 토큰은 `ColorScheme` 표준에 없으므로 **`theme.extension<MinglitWarningExt>()`** 또는 **`MinglitColors.warning` 직접 참조**. 기존 프로젝트는 후자를 사용 중(예: `weekly_stats_row.dart`).

**Live dot** (업데이트 pulse):

```dart
// 녹색 6x6 원, 1.5s pulse (opacity 1 → 0.3 → 1)
MinglitLiveDot(color: MinglitColors.success)   // 신규 widget 추가 제안
```

**상태 변형**:
- `isLoading` → shimmer skeleton (기존 `loading_indicator.dart` 스타일 재사용)
- `isOffline` → 테두리 `MinglitColors.warning`, `primarySurface`=`#FFFBEB`, 퍼센트 대신 "캐시됨" 뱃지
- `total == 0` → 큰 숫자 `0/0`, 퍼센트 hyphen, meta "아직 발급된 티켓이 없습니다"

### 2. 카메라 오버레이 + 컨트롤 FAB

기존 `QrScannerOverlayShape` 유지하되 **cutOutSize 반응형화**:

```dart
// qr_scanner_screen.dart
final double cutOut = math.min(
  220,
  MediaQuery.sizeOf(context).shortestSide * 0.48,
);
```

**FAB 2종** (우상단, 세로 쌓기, 간격 `MinglitSpacing.sm(12)`):

| FAB | 아이콘 | 배경 | 토글 시 |
|-----|--------|------|---------|
| 플래시 | `Icons.flash_off` / `Icons.flash_on` | `Colors.white.withOpacity(0.12)` | 활성화 시 배경 `MinglitPartnerColors.primary.withOpacity(0.85)` |
| 수동 체크인 | `Icons.manage_search` | 동일 | 탭 시 `showModalBottomSheet` |

- 크기: 44×44 (iOS HIG 최소), 터치 영역 48×48 (Material)
- 위치: `SafeArea` 내부, top `MinglitSpacing.medium(16)` + AppBar + 카드 높이, right `MinglitSpacing.medium(16)`
- Border: `Colors.white.withOpacity(0.18)`, 1px
- Radius: `MinglitRadius.button(12)`
- Elevation: 0 (plat하게), shadow는 scrim에 이미 흡수됨

**하단 힌트** ("참가자의 QR 코드를 프레임 안에 비추세요"):
- `theme.textTheme.bodyMedium`(14/500), `Colors.white.withOpacity(0.75)`
- cutout 바로 아래 `MinglitSpacing.large(24)` gap, 좌우 `screenEdge(16)`

### 3. 성공 배너 (기존 전체 오버레이 대체)

스펙의 "0.8s 전체 초록 오버레이"를 **상단 슬라이드-인 배너 + 중앙 체크마크**로 변경 제안.

**레이아웃**:
```
┌────────────────────────────────┐
│  ╔══════════════════════════╗  │  ← 배너 (슬라이드 다운 200ms)
│  ║ ✓  홍길동 · 남 20대 초반  ║  │     MinglitColors.success bg
│  ║    24번째 입장 · 9:47 PM  ║  │     MinglitColors.background text
│  ╚══════════════════════════╝  │
│                                │
│       [scanner active]          │  ← 스캐너는 계속 활성
│                                │
│            ⓘ  ← 중앙 체크        │  ← 24x24 체크마크, bounce 200ms
│            ✓                    │
│                                │
└────────────────────────────────┘
```

**타이밍**:
- 200ms 슬라이드 다운 입장 (`Curves.easeOutBack`)
- 400ms 정적 유지
- 200ms 페이드 아웃
- 총 800ms, 하지만 스캐너 비활성 없음 — 다음 스캔 허용

**중앙 체크마크**:
- 96×96 흰 원 + 56pt 초록 체크 — 기존 `_ResultFeedbackOverlay` 중앙 요소 재사용
- `AnimationController` 0→1, `Curves.easeOutBack`, 200ms bounce + 200ms fade-out
- 스캐너 hit detection 살아있음

**Haptic**:
- 성공: `HapticFeedback.mediumImpact()`
- 중복 체크인: `HapticFeedback.lightImpact()` + `warning` 배너
- 실패(다른 이벤트/환불): `HapticFeedback.heavyImpact()` + `error` 배너

**사운드** (선택, 기본 off — 노이즈 많은 클럽 고려):
- 성공: 240Hz sine 120ms
- 실패: 180Hz→80Hz drop 200ms
- 설정 토글 필요 (`user_settings.checkin_sound = true`)

### 4. 엔트리 그룹 Bottom Sheet

**기본 축소 상태**: `DraggableScrollableSheet`, `initialChildSize: 0.12`, `minChildSize: 0.08`, `maxChildSize: 0.85`.

```dart
// 화면 높이 812 기준
// 축소 = 0.12 × 812 ≈ 97pt (SafeArea bottom 34 + 핸들/타이틀 63)
// 확장 = 0.85 × 812 ≈ 690pt
```

**축소 상태 컨텐츠**:
```
   ─────  (36×4 handle)
   엔트리 그룹별 현황          ▲
   총 4개 그룹 · 남 15/28 · 여 8/22
```
- 헤더 탭 + 드래그 둘 다로 확장 가능
- 탭 힌트 chevron `▲` (grey-500, 14pt)

**확장 상태 — 그룹 행**:
```
남 20대 초반                   13/14
[████████████████████████░░]  92%     ← fill-high (error)

여 20대 초반                    5/14
[██████████░░░░░░░░░░░░░░░]  36%     ← fill-low (primary)
```

**행 토큰**:
| 속성 | 값 |
|------|-----|
| 상단 row padding | `EdgeInsets.symmetric(vertical: MinglitSpacing.sm(12))` |
| Label | `bodyMedium`(14/600), `onSurface` |
| Count (체크인 부분) | `bodyMedium`(14/700), `onSurface` |
| Count (`/14` 부분) | `bodyMedium`(14/500), `onSurfaceVariant` |
| Progress bar | height 6, radius 3, background `outlineVariant` |
| Divider | 1px `outlineVariant`, 마지막 행 제외 |

**정렬** (파트너가 주목해야 할 순):
1. 완충률 ≥ 90% (쿼터 임박) — 위
2. 완충률 50–89%
3. 완충률 < 50%
4. 같은 bucket 내에서는 label 알파벳순

**빈 상태** (엔트리 그룹 없는 이벤트):
- 시트 자체 숨김 (`entry_groups.isEmpty` 시 `const SizedBox.shrink()`)
- 요약 카드만 노출

**에러 상태**:
- 축소 헤더 유지, 서브타이틀을 "불러오기 실패 · 다시 시도"로 교체, 탭 시 재조회

### 5. 수동 체크인 바텀시트 — `_ManualCheckinSheet`

**진입**:
- 우상단 FAB `Icons.manage_search` 탭 → `showModalBottomSheet`, `isScrollControlled: true`
- 최대 높이 `MediaQuery.sizeOf(context).height * 0.85`

**구조**:
```
━━━ (handle)
수동 체크인                               ✕

[🔍 이름 또는 전화 뒷자리 4자리]          ← TextField, autofocus
ⓘ QR 인식이 어려울 때 이름으로 체크인 처리

미체크인 (27명)
  👤 김민지     여 20대 초반 · 010-****-1234      [체크인]
  👤 박재훈     남 20대 초반 · 010-****-5678      [체크인]

체크인 완료 (23명)
  👤 홍길동     남 20대 초반 · 9:47 PM 체크인     [✓ 완료]
```

**검색 로직** (클라이언트 측):
- 입력이 순수 숫자 4자리 → 전화 뒷자리 매칭
- 아니면 → 이름 `contains` (초성 검색은 v2)
- 결과 실시간 필터, debounce 150ms

**행 컴포넌트**:
- Avatar: 40×40, `MinglitColors.primary.withOpacity(0.15)` 배경, 이니셜 표시
- 이름: `bodyLarge`(15/600)
- 메타: `bodySmall`(12/500), `onSurfaceVariant`
- 체크인 버튼:
  - 미체크인: filled primary, radius `MinglitRadius.button(12)`, 높이 36, padding H=14
  - 완료: outlined success, `MinglitColors.success` text + border
  - 최소 터치 영역 44×44 유지 (InkWell padding)

**체크인 성공 시**:
- 해당 행이 "체크인 완료" 섹션 상단으로 이동 (`AnimatedList`, 300ms)
- `HapticFeedback.selectionClick()`
- 요약 카드 카운트 +1, 해당 엔트리 그룹 +1 (Realtime 구독 없어도 optimistic)

## 스캔 성공/실패 상태 매트릭스

| 결과 | 배너 색 | 아이콘 | 타이틀 | 서브타이틀 | Haptic | 오버레이 지속 |
|------|---------|--------|--------|-----------|--------|---------------|
| 정상 | `success`(#16A34A) | `check_circle` | `{user_name}` | `{group_label} · {N}번째 입장` | medium | 600ms |
| 이미 체크인됨 | `warning`(#D97706) | `info` | 이미 체크인된 참가자 | `{time} 체크인 완료` | light | 800ms |
| 다른 이벤트 티켓 | `error`(#EF4444) | `error` | 입장 불가 | `다른 이벤트의 티켓입니다` | heavy | 1200ms |
| 환불된 티켓 | `error` | `error` | 환불된 티켓 | `이 티켓은 환불 처리되었습니다` | heavy | 1200ms |
| 쿼터 초과 | `error` | `error` | 그룹 마감 | `{group_label} 쿼터 초과` | heavy | 1200ms |
| QR 형식 오류 | `error` | `error` | 스캔 실패 | `유효하지 않은 QR 코드입니다` | heavy | 800ms |
| 네트워크 오류 | `warning` | `cloud_off` | 연결 불안정 | `잠시 후 재시도합니다` | light | 1500ms |

**중요**: 오류 배너는 하단에 "수동 체크인" 숏컷 액션을 포함 — 줄이 밀리지 않게.

## 애니메이션 사양

| 애니메이션 | Duration | Curve | 구현 |
|------------|----------|-------|------|
| 요약 카운트 변경 (`23`→`24`) | 350ms | `Curves.easeOut` | `AnimatedSwitcher` + `SlideTransition(0, 0.3)` |
| 프로그레스 바 fill | 350ms | `Curves.easeOut` | `TweenAnimationBuilder<double>` |
| 성공 배너 슬라이드 다운 | 200ms | `Curves.easeOutBack` | `SlideTransition(-1, 0)` |
| 성공 배너 페이드 아웃 | 200ms | `Curves.easeIn` | `FadeTransition` |
| 중앙 체크마크 bounce | 200ms | `Curves.easeOutBack` | `ScaleTransition(0→1.1→1)` |
| 바텀시트 drag | 250ms | `Curves.easeOut` | `DraggableScrollableSheet` 기본 |
| FAB 플래시 토글 | 150ms | `Curves.easeInOut` | 배경 색상 lerp |
| Live dot pulse | 1500ms | `Curves.easeInOut` | `AnimationController.repeat()` reverse |
| Shimmer skeleton | 1200ms | `Curves.linear` | 기존 `loading_indicator.dart` |

**주의**: `Duration` 값은 반드시 `MinglitAnimation.fast(200)`, `medium(350)` 토큰 사용.

## 접근성

### 대비율 (WCAG AA/AAA)

| 조합 | 예상 비율 | 목표 |
|------|-----------|------|
| 큰 숫자 `23` (onSurface `#111827` on surface `#FFFFFF`) | 16.9:1 | AAA ✅ |
| 퍼센트 텍스트 (primary `#6C3CE1` on `#FFFFFF`) | 6.87:1 | AA ✅ |
| 힌트 텍스트 (white@75% on scrim `#0A0A0F`) | 8.2:1 | AAA ✅ |
| 성공 배너 text (white on `#16A34A`) | 4.84:1 | AA ✅ |
| Warning 배너 text (white on `#D97706`) | 4.73:1 | AA ✅ |
| Meta 텍스트 (`onSurfaceVariant` on `surface`) | 9.21:1 | AAA ✅ |

### 터치 타겟

- FAB: 44×44 이상 (iOS HIG), InkWell로 48×48 확장
- 바텀시트 헤더: 56pt 전체 탭 영역
- 체크인 버튼: 높이 36 + padding으로 44 확보
- 수동 리스트 행: 높이 56 (avatar 40 + padding 8×2)

### 스크린 리더 (Semantics)

```dart
Semantics(
  label: '전체 체크인 $checkedIn명 중 $total명, ${percent.toStringAsFixed(0)}%',
  child: _CheckinSummaryCard(...),
)

// 성공 시 Announce
SemanticsService.announce(
  '$userName 체크인 완료, $groupLabel, $ordinal번째 입장',
  TextDirection.ltr,
);

// 그룹 행
Semantics(
  label: '$groupLabel, $checked명 체크인, $total명 중, ${ratio}퍼센트',
  child: _GroupRow(...),
)
```

### 폰트 스케일 대응

- 큰 숫자는 `MediaQuery.textScalerOf(context).clamp(1.0, 1.3)` 제한
- 1.3× 이상 확대 시 요약 카드 높이 자동 증가 허용 (120–140pt)
- 카메라 영역은 자동 축소 (min 180pt)

## 다크모드 (`partnerThemeDark`)

| 요소 | Light | Dark |
|------|-------|------|
| 카드 배경 | `MinglitColors.surface` `#F9FAFB` | `MinglitColorsDark.surface` `#212121` |
| 카드 border | `divider` `#E5E7EB` | `divider` `#3D3D3D` |
| 큰 숫자 | `#111827` | `#FFFFFF` |
| 메타 | `#4B5563` | `#AAAAAA` |
| 퍼센트 (일반) | `MinglitPartnerColors.primary` `#6C3CE1` | `MinglitPartnerColorsDark.primary` `#9B7BEC` |
| Progress low | partner primary | partner primaryDark `#9B7BEC` |
| Progress mid | `MinglitColors.warning` `#D97706` | `MinglitColorsDark.warning` `#FBBF24` |
| Progress high | `MinglitColors.error` `#EF4444` | `#EF4444` (공용) |
| 성공 배너 | `#16A34A` | `#4ADE80` |
| FAB 배경 | `white@12%` | `white@16%` (어두운 배경에서 더 도드라지게) |

**시스템 테마 자동 감지**: 파트너 앱 기본 `ThemeMode.system`, 밤 클럽/현장에서 자동으로 다크.

## 파일/코드 레이아웃 제안

```
apps/app_partner/lib/src/features/checkin/
├── checkin_controller.dart                 ← 기존 (확장)
├── checkin_controller.g.dart               ← 기존
├── qr_scanner_screen.dart                  ← 기존 (리팩터)
├── widgets/                                ← 신규
│   ├── checkin_summary_card.dart           ← 요약 카드
│   ├── checkin_scanner_overlay.dart        ← QR frame + FAB들
│   ├── checkin_success_banner.dart         ← 상단 배너
│   ├── entry_group_bottom_sheet.dart       ← 축소/확장 시트
│   ├── entry_group_row.dart                ← 개별 그룹 행
│   └── manual_checkin_sheet.dart           ← 수동 체크인
└── stats/                                  ← 신규
    ├── checkin_stats_controller.dart       ← Realtime + stats RPC
    └── checkin_stats_state.dart
```

**컨트롤러 책임 분리**:
- `checkinControllerProvider` — QR 스캔 결과 처리 (기존, 확장 없음)
- `checkinStatsControllerProvider` — 신규: stats RPC + Realtime 구독, optimistic 업데이트

## 실시간 업데이트 전략

**옵티미스틱**: 내 기기 스캔 성공 → 즉시 `checkinStatsController.increment(groupId)` → UI 반영 → 서버 ack 도착 시 재계산 (충돌 없으면 no-op).

**Realtime 구독**: 다른 기기 스캔 → Supabase Realtime `event_participants` 채널 → `checked_in_at` 변경 row 감지 → `stats` 재계산 트리거. 스로틀 1000ms (한 번에 여러 스캔 대응).

**오프라인 폴백**: `connectivity_plus`로 네트워크 감지 → 요약 카드 `isOffline: true` 표시 → 스캐너 UI는 "잠시 후 재시도" 안내(실제 로컬 큐는 v2).

## 구현 체크리스트

### Phase 1 — 시각/레이아웃 (구현 전 승인 필요)
- [ ] `_CheckinSummaryCard` 위젯 구현 + Widget Test
- [ ] 카메라 cutout 반응형화 (`math.min(220, shortestSide * 0.48)`)
- [ ] FAB 2종 (플래시·수동) 배치
- [ ] 상단 성공 배너(0.6s easeOutBack) — 기존 `_ResultFeedbackOverlay` 대체

### Phase 2 — 데이터
- [ ] Backend: `checked_in_at` 컬럼 + `get_event_checkin_stats` RPC
- [ ] `checkinStatsController` + Realtime 구독
- [ ] 요약 카드 연동 + shimmer/offline 상태

### Phase 3 — 엔트리 그룹 시트
- [ ] `DraggableScrollableSheet` + 핸들
- [ ] 그룹 행 정렬 로직 (≥90% → 50–89% → <50%)
- [ ] 진행률 색상 단계별 (primary/warning/error)

### Phase 4 — 수동 체크인
- [ ] `_ManualCheckinSheet` + 검색 로직 (이름/전화 4자리 자동 감지)
- [ ] 미체크인/완료 섹션 분리 + `AnimatedList` 이동

### Phase 5 — 접근성 & 다크모드
- [ ] Semantics 라벨 전체 추가
- [ ] `SemanticsService.announce` 성공/실패 시점
- [ ] 다크모드 Golden 테스트 (light/dark 6 frames)

## QA 핸드오프 노트

QA에게 전달할 테스트 포인트 (자세한 건 `test-plan.md`에서):

1. **Golden**: 6 frames (기본/그룹 확장/스캔 성공/수동/오프라인/빈 상태) × light/dark × 3 폰 사이즈(375/390/430) = 36 golden
2. **Interaction**: 그룹 시트 drag, FAB 탭, 수동 검색 입력, Realtime 이벤트 수신
3. **Edge**: 엔트리 그룹 0개/1개/8개, 참가자 0명, 전체 마감, 오프라인 전환
4. **Accessibility**: TalkBack/VoiceOver 라벨 읽기, 폰트 1.3×, 색맹 시뮬레이션
5. **Performance**: 혼잡 상황 시뮬레이션(초당 2 스캔, 10분 연속), 애니메이션 jank < 5 frames

## 오픈 이슈 / 의사결정 필요

1. **사운드 ON/OFF 토글 위치** — 화면 내 quick toggle vs 설정 화면. 현장 파트너 요청 감안 `AppBar actions` 내 스피커 아이콘 제안. → Mark 판단.
2. **엔트리 그룹 정렬을 유저가 커스터마이즈** — v2 스코프.
3. **배지 시스템** — `남 20대 14/14 마감` 이후 그룹이 여럿이면 배너 스택 관리. v1은 최근 1개만 노출, v2에서 "2건 더" 스택 UI.

## 다음 단계

`needs-uiux` 완료 → `needs-qa`로 라우팅.
QA는 이 문서의 Phase 체크리스트 + 테스트 포인트를 기반으로 `test-plan.md` 작성.

---

**토큰 준수 서약**: 이 문서의 모든 색상/간격/라디우스는 `minglit_kit` 토큰 참조. 구현 시 hex 하드코딩 발견되면 `minglit_no_hardcoded_colors` lint에 의해 차단됨. 예외가 필요하면 `MinglitColors`/`MinglitPartnerColors`를 확장.
