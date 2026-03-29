# Minglit 디자인 패턴 카탈로그 스펙

## 개요

기본 컴포넌트(Button, Card, Chip 등)를 **조합하여 반복 사용하는 상위 레벨 UI 구조**를 "패턴"으로 정의하고, 앱 내 디자인 카탈로그에 등록한다.

```
기본 컴포넌트 (에픽 #618 — 디자인 카탈로그에 이미 있음)
  Badge, Button, ListRow, Section, ContentCard, BottomCTA...
    ↓ 조합
패턴 (본 스펙 — 컴포넌트를 조합한 상위 레벨 가이드)
  상세 페이지, 리스트+필터, 폼 위저드, 카드 레이아웃, 결제 플로우...
```

### 핵심 원칙

1. **코드에서 추출** — 이미 앱에서 반복 사용 중인 구조를 패턴으로 정형화한다. 새로 발명하지 않는다.
2. **조합 중심** — TDS(토스)의 Compound 패턴 전략을 참고: 하위 컴포넌트를 제공하고 팀이 직접 조합하도록 한다.
3. **상태 포함** — 각 패턴은 데이터 있음/빈 상태/로딩/에러 4가지 상태를 반드시 정의한다.
4. **Do/Don't** — 올바른 사용법과 피해야 할 사용법을 명시한다.

### 참고 디자인 시스템

| 시스템 | 패턴 접근 방식 | 밍릿에 적용할 점 |
|--------|--------------|----------------|
| **TDS (토스)** | Compound 패턴 — 하위 컴포넌트를 제공, 팀이 조합. "언제 어떤 선택이 적절한가"에 집중 | 패턴별 구성 컴포넌트 목록 + 선택 가이드 |
| **Material Design 3** | Canonical Layouts — list-detail, supporting pane, feed 3가지 검증된 레이아웃 | 상세 페이지 = list-detail, 홈 피드 = feed 패턴 |
| **Apple HIG** | Patterns 섹션 — entering data, managing content, searching 등 행위 기반 분류 | 폼/위저드, 검색, 리스트 패턴을 행위 기반으로 문서화 |
| **Shopify Polaris** | 컴포넌트와 별도의 Patterns 문서 — 레이아웃 규칙, 조합 변형, 상태 처리 | 패턴 문서를 컴포넌트 문서와 분리 |

## 유저 시뮬레이션

### 페르소나 1: 신규 Flutter 개발자 (주니어, 입사 2주차)

**상황**: "파트너 앱에 새 상세 페이지를 만들어야 하는데, 기존 페이지 구조를 어떻게 따라야 할지 모르겠다."

- **현재 문제**: EventDetailPage, PartyDetailPage 소스를 직접 읽어야 구조를 파악. 400줄+ 파일에서 핵심 패턴을 추출하기 어려움.
- **패턴 카탈로그가 있다면**: "상세 페이지 패턴" 항목에서 표준 구조(Hero → TabBar → Sections → Bottom CTA) + 구성 컴포넌트 + 코드 스니펫을 즉시 확인.
- **불만/개선점**: 각 패턴에 "이 패턴을 사용하는 실제 화면" 링크가 있으면 코드 참조가 쉬움.

### 페르소나 2: PM/디자이너 (기획 담당)

**상황**: "정산 상세 페이지 와이어프레임을 그려야 하는데, 기존 상세 페이지들과 일관성을 맞추고 싶다."

- **현재 문제**: Figma에 컴포넌트는 있지만, "상세 페이지는 이렇게 구성한다"는 가이드가 없음.
- **패턴 카탈로그가 있다면**: 패턴별 와이어프레임 + 구성 규칙을 보고 일관된 레이아웃 결정.
- **불만/개선점**: 상태 변형(빈/에러/로딩) 와이어프레임도 포함되어야 QA 협의가 빨라짐.

### 페르소나 3: 시니어 개발자 (리팩토링 담당)

**상황**: "이벤트 상세(5탭)와 파티 상세(3탭)가 비슷한 구조인데 구현이 미묘하게 다르다. 통일하고 싶다."

- **현재 문제**: 각 페이지가 독자적으로 발전하여 NestedScrollView 사용법, TabController 관리, 스켈레톤 로딩이 제각각.
- **패턴 카탈로그가 있다면**: 표준 구조가 정의되어 "이것과 다르면 리팩토링 대상"이라는 기준이 생김.
- **불만/개선점**: Do/Don't에 "settlement_detail_page처럼 수동 setState를 쓰지 마라 → MinglitAsyncValueWidget을 쓰라"같은 실제 사례 포함 필요.

### 페르소나 4: QA 엔지니어

**상황**: "빈 상태 테스트를 작성해야 하는데, 앱 전체에서 빈 상태가 어디서 어떤 형태로 나타나야 하는지 모르겠다."

- **현재 문제**: 빈 상태 위젯이 각 피처에서 개별 구현. 아이콘, 메시지, CTA 유무가 제각각.
- **패턴 카탈로그가 있다면**: "빈/에러/로딩 상태 패턴" 항목에서 표준 구조 확인 → 일탈한 화면을 버그로 리포트 가능.
- **불만/개선점**: 각 패턴의 "테스트 체크리스트" 항목이 있으면 좋음.

## 구성 요소

### 패턴 분류 체계

코드베이스 분석 결과 7가지 반복 패턴을 식별했다. 이를 3개 카테고리로 분류한다.

```
📐 레이아웃 패턴 (화면 전체 구조)
├── P1. 상세 페이지 (Detail Page)
├── P2. 리스트 + 필터 (List & Filter)
└── P3. 폼 위저드 (Form Wizard)

🃏 콘텐츠 패턴 (반복 콘텐츠 단위)
├── P4. 카드 레이아웃 (Card Layouts)
└── P5. 결제/트랜잭션 플로우 (Transaction Flow)

🔄 상태 패턴 (데이터 상태 처리)
├── P6. 빈/에러/로딩 상태 (Data States)
└── P7. 비동기 데이터 래퍼 (Async Wrapper)
```

---

### P1. 상세 페이지 패턴 (Detail Page)

**M3 매핑**: List-Detail canonical layout

#### 표준 구조

```
┌─────────────────────────────┐
│ [← Back]    Title    [⋮]   │  AppBar (simpleAppBar)
├─────────────────────────────┤
│                             │
│  ┌───────────────────────┐  │
│  │   Hero Image (16:9)   │  │  SliverAppBar + FlexibleSpaceBar
│  │   + Gradient Overlay  │  │
│  └───────────────────────┘  │
│                             │
│  Title (titleLarge)         │  Content header
│  Subtitle (bodyMedium)      │
│                             │
│ ┌─────┬─────┬─────┬─────┐  │
│ │Tab 1│Tab 2│Tab 3│Tab N│  │  SliverPersistentHeader(TabBar)
│ └─────┴─────┴─────┴─────┘  │
│                             │
│  Tab Content (scrollable)   │  TabBarView
│  ...                        │
│                             │
├─────────────────────────────┤
│  [Primary CTA Button]      │  Bottom CTA (고정)
└─────────────────────────────┘
```

#### 구성 컴포넌트

| 컴포넌트 | 용도 | 소스 |
|----------|------|------|
| `MinglitAsyncValueWidget` | 데이터 로딩/에러 래퍼 | minglit_kit |
| `NestedScrollView` + `SliverAppBar` | 탭과 스크롤 동기화 | Flutter |
| `DefaultTabController` + `TabBar` | 탭 네비게이션 | Flutter |
| `MinglitSectionDivider.thick()` | 섹션 구분 | minglit_kit |
| `MinglitImage` / `MinglitImageCarousel` | 히어로 이미지 | minglit_kit |

#### 현재 사용 화면

| 화면 | 탭 수 | 특이사항 |
|------|-------|---------|
| `EventDetailPage` (유저) | 5 | 하단 티켓 바 고정 |
| `PartyDetailPage` (파트너) | 3 | NestedScrollView + 핀 고정 |
| `EventDetailPage` (파트너) | 2 | 신청자 관리 탭 포함 |
| `PartnerDetailPage` (유저) | 0 | 탭 없이 단일 스크롤 (변형) |

#### 상태 변형

| 상태 | 처리 |
|------|------|
| 로딩 | `_DetailContentSkeleton` — Hero 영역 + 텍스트 라인 스켈레톤 |
| 에러 | `MinglitAsyncValueWidget` 기본 에러 + 재시도 |
| 데이터 있음 | 표준 레이아웃 |
| 탭 콘텐츠 빈 상태 | 탭별 개별 빈 상태 메시지 |

#### Do / Don't

| Do | Don't |
|----|-------|
| `NestedScrollView` + `SliverPersistentHeader`로 탭+스크롤 동기화 | 탭 없이 단순 Column에 모든 섹션 나열 (스크롤 성능 저하) |
| `MinglitAsyncValueWidget`로 데이터 상태 래핑 | 수동 `setState` + `_isLoading` 플래그 사용 |
| 히어로 이미지에 그라디언트 오버레이 + 텍스트 | 이미지 위에 그라디언트 없이 텍스트 직접 배치 (가독성) |
| 하단 CTA는 `Scaffold.bottomNavigationBar` 또는 `Positioned`로 고정 | CTA를 스크롤 내부에 배치 (발견성 저하) |

---

### P2. 리스트 + 필터 패턴 (List & Filter)

**M3 매핑**: Feed canonical layout

#### 표준 구조

```
┌─────────────────────────────┐
│ [Logo]    Title    [🔔][🔍] │  SliverAppBar (floating + snap)
├─────────────────────────────┤
│ [필터A] [필터B] [필터C] ▸   │  Horizontal Chip bar (선택사항)
├─────────────────────────────┤
│ ┌───────────────────────┐   │
│ │  Card Item 1          │   │  ListView.separated
│ └───────────────────────┘   │  또는 CustomScrollView + SliverList
│       cardGap (12px)        │
│ ┌───────────────────────┐   │
│ │  Card Item 2          │   │
│ └───────────────────────┘   │
│       ...                   │
├─────────────────────────────┤
│ [Pull to Refresh indicator] │  RefreshIndicator (선택사항)
└─────────────────────────────┘
```

#### 구성 컴포넌트

| 컴포넌트 | 용도 | 소스 |
|----------|------|------|
| `MinglitTheme.sliverAppBar()` | 스크롤 시 숨김 AppBar | minglit_kit |
| `MinglitFilterChip` | 필터 칩 | minglit_kit |
| `MinglitAsyncValueWidget` | 데이터 상태 래퍼 | minglit_kit |
| `ListView.separated` | 아이템 리스트 | Flutter |
| `RefreshIndicator` | 당겨서 새로고침 | Flutter |

#### 현재 사용 화면

| 화면 | 필터 | 아이템 타입 |
|------|------|-----------|
| `HomePage` (유저) | 칩 필터 (지역, 카테고리) | EventCard |
| `PartyListPage` (파트너) | 없음 | PartyListItem |
| `SettlementPage` (파트너) | TabBar (대시보드/리스트) | SettlementCard |
| `SearchPage` (유저) | 검색 TextField | EventCard |
| `PurchaseHistoryPage` (유저) | 없음 | PurchaseHistoryCard |

#### 상태 변형

| 상태 | 처리 |
|------|------|
| 로딩 | 스켈레톤 카드 3~5개 (shimmer) |
| 에러 | 중앙 에러 아이콘 + 메시지 + 재시도 버튼 |
| 빈 상태 | 중앙 아이콘 + 안내 텍스트 + CTA 버튼(선택) |
| 데이터 있음 | 카드 리스트 |

#### Do / Don't

| Do | Don't |
|----|-------|
| `ListView.separated`로 `cardGap` (12px) 간격 유지 | `Column` + `SizedBox`로 수동 간격 (스크롤 성능) |
| 빈 상태에 다음 행동 유도 CTA 포함 | "데이터가 없습니다" 한 줄만 표시 |
| 필터 변경 시 리스트 fade 전환 | 필터 변경 시 전체 화면 로딩 인디케이터 |

---

### P3. 폼 위저드 패턴 (Form Wizard)

**HIG 매핑**: Entering Data pattern

#### 표준 구조

```
┌─────────────────────────────┐
│ [← Back]  Step 2/6   [닫기] │  AppBar + 스텝 인디케이터
├─────────────────────────────┤
│ ═══════════◯───────────     │  LinearProgressIndicator
├─────────────────────────────┤
│                             │
│  Step Title (titleLarge)    │
│  Description (bodyMedium)   │
│                             │
│  [Form Fields]              │  PageView 내부 스텝 콘텐츠
│  ...                        │
│                             │
│                             │
├─────────────────────────────┤
│ [이전]          [다음하기]   │  Bottom nav buttons
└─────────────────────────────┘
```

#### 구성 컴포넌트

| 컴포넌트 | 용도 | 소스 |
|----------|------|------|
| `PageController` + `PageView` | 스텝 간 수평 전환 | Flutter |
| `LinearProgressIndicator` | 진행 상태 표시 | Flutter |
| `Form` + `GlobalKey<FormState>` | 스텝별 유효성 검증 | Flutter |
| `MinglitGlobalLoadingOverlay` | 제출 시 전체 로딩 | minglit_kit |
| `InputDecorationTheme` | 입력 필드 스타일 | minglit_kit (전역) |

#### 현재 사용 화면

| 화면 | 스텝 수 | 특이사항 |
|------|--------|---------|
| `PartyCreateWizardPage` (파트너) | 6 | 생성/편집 모드 공유 |
| `EventApplicationWizardPage` (유저) | 3+ | 티켓→인증→결제 동적 스텝 |
| `PartnerApplyPage` (파트너) | 5 | 온보딩 신청 위저드 |

#### 상태 변형

| 상태 | 처리 |
|------|------|
| 유효성 실패 | 인라인 에러 (필드 아래 빨간 텍스트) |
| 제출 중 | `MinglitGlobalLoadingOverlay` + 로딩 메시지 |
| 제출 성공 | 성공 다이얼로그/화면 → 이전 화면으로 pop |
| 제출 실패 | 에러 다이얼로그 + 재시도/수정 안내 |
| 초안 저장 | 스텝 이동 시 자동 상태 보존 (PageController) |

#### Do / Don't

| Do | Don't |
|----|-------|
| `PageController.animateToPage()`으로 스텝 전환 | `Navigator.push`로 각 스텝을 별도 화면으로 (상태 유실) |
| 스텝별 `Form` 유효성 검증 후 다음 허용 | 모든 유효성을 마지막 제출에서 한번에 검증 |
| 진행 상태를 `LinearProgressIndicator`로 표시 | 스텝 번호만 텍스트로 표시 (시각적 피드백 부족) |
| 편집 모드에서 기존 데이터 pre-fill | 편집 시 빈 폼으로 시작 |

---

### P4. 카드 레이아웃 패턴 (Card Layouts)

코드베이스에서 5가지 카드 변형을 식별했다.

#### 변형 A — 이미지 카드 (Image Card)

이벤트 피드, 파티 목록에서 사용. 시각적 임팩트 최대화.

```
┌─────────────────────────────┐
│ ┌───────────────────────┐   │
│ │  Image (16:9)         │   │  AspectRatio + MinglitImage
│ │  + Gradient overlay   │   │
│ │  ┌──────┐    ┌─────┐  │   │  Stack: 상태 뱃지 + 가격
│ │  │D-3   │    │30,000│  │   │
│ │  └──────┘    │  원  │  │   │
│ │              └─────┘  │   │
│ └───────────────────────┘   │
│  이벤트 제목 (titleMedium)   │  Info section
│  3월 31일 (화) 19:00        │
│  강남 라운지바 · 12/20명     │
└─────────────────────────────┘
```

**사용**: `MinglitEventCard`, `PartyListItem`

#### 변형 B — 트랜잭션 카드 (Transaction Card)

구매 내역에서 사용. 정보 밀도 높음.

```
┌─────────────────────────────┐
│  3월 25일          [승인됨]  │  날짜 + 상태 뱃지
│ ─────────────────────────── │  Divider
│  [80x80]  이벤트 제목        │  썸네일 + 텍스트 정보
│           3/31 (화) 19:00   │
│           강남 라운지바       │
│ ─────────────────────────── │  Divider
│  일반 입장권      30,000원   │  티켓 + 가격
│ ─────────────────────────── │  Divider
│  [영수증] [문의] [취소]      │  액션 버튼 row
└─────────────────────────────┘
```

**사용**: `PurchaseHistoryCard`

#### 변형 C — 정보 카드 (Info Card)

정산 목록 등 단순 데이터 표시.

```
┌─────────────────────────────┐
│  정산 완료         [완료]    │  상태 + 뱃지
│  3월 25일                   │  날짜
│  150,000원                  │  금액 (headlineSmall)
└─────────────────────────────┘
```

**사용**: `SettlementCard`

#### 변형 D — 통계 카드 (Stats Card)

대시보드 요약 정보.

```
┌─────────────────────────────┐
│  이번 달 수익          [▸]   │  라벨 + 상세 링크
│  1,250,000원                │  금액 (headlineSmall, bold)
│  +15% vs 지난달             │  변동률 (bodySmall)
└─────────────────────────────┘
```

**사용**: `RevenueSummaryCard`

#### 변형 E — 선택 카드 (Selectable Card)

티켓 선택, 옵션 선택에서 사용.

```
┌─────────────────────────────┐  ← 미선택: outlineVariant 테두리
│  ● 일반 입장권               │    선택: secondary 테두리 + 배경 틴트
│  30,000원                   │         + shadow
│  성인 남녀 누구나 참여       │
└─────────────────────────────┘
```

**사용**: `MinglitDecorations.selectableCard()` (03-patterns.md에 정의됨)

#### 공통 규칙

| 속성 | 토큰 | 값 |
|------|------|-----|
| 카드 간 간격 | `cardGap` | 12px |
| 카드 내부 패딩 (세로) | `cardContentV` | 16px |
| 카드 내부 패딩 (가로) | `screenEdge` | 20px |
| 카드 곡률 | `MinglitRadius.card` | 16px |
| 카드 elevation | — | 0 (flat) |
| 카드 배경 | `MinglitColors.surface` | #F9FAFB |

---

### P5. 결제/트랜잭션 플로우 패턴 (Transaction Flow)

#### 표준 흐름

```
사용자 행동 (신청하기/결제하기)
  │
  ├── 확인 다이얼로그 (금액, 약관 동의)
  │     └── [결제하기] / [돌아가기]
  │
  ├── 결제 처리 중 → MinglitGlobalLoadingOverlay
  │     └── "결제를 확인하고 있어요"
  │
  ├── 성공 → 성공 화면/다이얼로그
  │     └── "30,000원 결제가 완료됐어요"
  │     └── [티켓 확인하기] CTA
  │
  └── 실패 → 에러 다이얼로그
        └── "결제에 실패했어요. 카드 정보를 확인해주세요."
        └── [다시 시도하기] / [돌아가기]
```

#### 환불 서브플로우

```
취소 요청 → 환불 계산 다이얼로그
  │    수수료: X원
  │    환불액: Y원
  │    [취소하기 (error)] / [돌아가기]
  │
  ├── 처리 중 → 로딩 오버레이
  └── 완료 → "환불이 완료됐어요. 영업일 기준 3일 내에 입금돼요"
```

---

### P6. 빈/에러/로딩 상태 패턴 (Data States)

#### 로딩 상태 — 3단계

| 레벨 | 위젯 | 용도 |
|------|------|------|
| 인라인 | `SizedBox` + `CircularProgressIndicator` | 카드 내 부분 로딩 |
| 콘텐츠 | `MinglitSkeleton` (shimmer) | 카드/리스트 스켈레톤 |
| 전체 화면 | `MinglitGlobalLoadingOverlay` | 결제, 제출 등 블로킹 작업 |

#### 빈 상태 — 표준 구조

```
      Center
        │
   [Icon] (64px, onSurfaceVariant)
        │
   SizedBox(16px)
        │
   [Title] (titleMedium)
   "아직 ○○이 없어요"
        │
   SizedBox(8px)
        │
   [Description] (bodyMedium, textSecondary)
   "○○하면 여기에 나타나요"
        │
   SizedBox(24px)
        │
   [CTA Button] (OutlinedButton, 선택사항)
   "○○ 둘러보기"
```

#### 에러 상태 — 표준 구조

```
      Center
        │
   [Icon] (error_outline, 64px, error color)
        │
   SizedBox(16px)
        │
   [Title] (titleMedium)
   "문제가 발생했어요"
        │
   SizedBox(8px)
        │
   [Description] (bodyMedium, textSecondary)
   "잠시 후 다시 시도해주세요"
        │
   SizedBox(24px)
        │
   [Retry Button] (ElevatedButton)
   "다시 시도하기"
```

---

### P7. 비동기 데이터 래퍼 패턴 (Async Wrapper)

#### 표준 사용법

```dart
MinglitAsyncValueWidget<T>(
  value: ref.watch(provider),
  data: (data) => _ContentWidget(data: data),
  // loading, error는 기본값 사용 (선택적 오버라이드)
)
```

#### Do / Don't

| Do | Don't |
|----|-------|
| `MinglitAsyncValueWidget`로 래핑 | 수동 `setState` + `_isLoading` 플래그 |
| `ref.watch(provider)`로 반응형 데이터 | `initState()`에서 수동 fetch + 상태 관리 |
| 커스텀 스켈레톤은 `loading:` 파라미터로 전달 | 별도 `if (_isLoading)` 분기 |

---

## 디자인 카탈로그 앱 내 구현

### 카탈로그 탭 구성 (에픽 #618 확장)

기존 카탈로그 탭에 "패턴" 탭을 추가한다.

```
디자인 카탈로그
├── 토큰 (기존)
│   ├── 색상
│   ├── 타이포그래피
│   ├── 간격
│   └── ...
├── 위젯 (에픽 #618)
│   ├── MinglitButton
│   ├── MinglitBadge
│   └── ...
└── 패턴 (본 스펙 — 신규)
    ├── 📐 레이아웃
    │   ├── 상세 페이지
    │   ├── 리스트 + 필터
    │   └── 폼 위저드
    ├── 🃏 콘텐츠
    │   ├── 카드 레이아웃 (5 변형)
    │   └── 결제 플로우
    └── 🔄 상태
        ├── 빈/에러/로딩
        └── Async 래퍼
```

### 패턴 상세 화면 구성

각 패턴 상세 화면은 다음 섹션으로 구성:

1. **설명** — 패턴 용도, M3/TDS 매핑
2. **라이브 프리뷰** — 실제 위젯으로 렌더링된 패턴 데모
3. **구성 컴포넌트** — 사용 컴포넌트 목록 (탭으로 각 컴포넌트 카탈로그 링크)
4. **상태 변형** — 토글로 데이터/빈/로딩/에러 상태 전환
5. **사용 화면** — 이 패턴을 사용하는 실제 앱 화면 목록
6. **Do/Don't** — 올바른/잘못된 사용 예시

## 데이터 소스

앱 내 카탈로그이므로 외부 API 없음. 패턴 데모 데이터는 하드코딩된 mock 데이터 사용.

## 라우트 변경

기존 디자인 카탈로그 라우트(`/dev`) 내부에 패턴 탭 추가. 신규 라우트 불필요.

## 에러/로딩 상태

디자인 카탈로그 자체는 로컬 데이터만 사용하므로 에러/로딩 상태 불필요. 패턴 데모 내에서 의도적으로 각 상태를 시뮬레이션한다.

## 구현 이슈 분할 (예상)

| # | 제목 | 의존성 | 설명 |
|---|------|--------|------|
| 1 | 디자인 카탈로그에 "패턴" 탭 추가 | 에픽 #618 (#621) | 탭 구조 확장, 패턴 목록 화면 |
| 2 | P1 상세 페이지 패턴 데모 | #1 | 라이브 프리뷰 + 상태 변형 토글 |
| 3 | P2 리스트+필터 패턴 데모 | #1 | 라이브 프리뷰 + 필터 인터랙션 |
| 4 | P3 폼 위저드 패턴 데모 | #1 | 라이브 프리뷰 + 스텝 전환 |
| 5 | P4 카드 레이아웃 패턴 데모 (5 변형) | #1 | 각 카드 변형 프리뷰 |
| 6 | P5 결제 플로우 패턴 데모 | #1 | 플로우 다이어그램 + 상태 시뮬레이션 |
| 7 | P6 빈/에러/로딩 상태 패턴 데모 | #1 | 3단계 로딩 + 빈/에러 표준 구조 |
| 8 | P7 Async 래퍼 패턴 데모 + Do/Don't | #1 | MinglitAsyncValueWidget 사용법 |
| 9 | `docs/ux/design-system/03-patterns.md` 업데이트 | #2~#8 | 기존 문서에 상위 패턴 반영 |
