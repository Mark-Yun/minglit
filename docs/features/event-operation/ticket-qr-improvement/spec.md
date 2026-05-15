# 티켓 QR 화면 — Boarding Pass 리디자인 스펙

## 개요

현재 티켓 QR 화면은 흰 배경에 QR 코드만 표시되어 시각적 밀도가 낮고, 이벤트 입장이라는 핵심 순간의 감성이 부족하다. **실제 항공 보딩패스 디자인**을 오마주하여 "입장 승인"의 물리적 감각을 디지털로 구현한다.

### 디자인 레퍼런스

| 레퍼런스 | 차용 요소 |
|----------|-----------|
| **대한항공 보딩패스** | 스카이블루 헤더 바 + 로고 배치, 탑승구/좌석 정보의 격자형 레이아웃, 절취선 위아래 영역 분리 |
| **아시아나 보딩패스** | 좌-우 출발지/도착지 양쪽 배치, 중앙 정보 밀도, 바코드 stub 분리 |
| **Apple Wallet 패스** | 세로형 카드, 상단 로고 스트립, 하단 바코드 영역, 모서리 라운딩 |

### 핵심 원칙

1. **진짜 티켓 느낌** — 스크린 안의 UI가 아니라 손에 든 물리적 입장권처럼 느껴야 한다
2. **입장 승인 감성** — "BOARDING" 상태 표시로 실제 탑승 게이트 통과 경험을 오마주
3. **맥락 정보** — QR만이 아닌, 이벤트명/일시/장소를 함께 표시하여 입장 직전 불안감 제거
4. **브랜드 아이덴티티** — 밍글릿 primary gradient + 로고로 서비스 정체성 강화

### 참고 앱 분석

| 앱 | 강점 | 밍글릿 적용 |
|----|------|-------------|
| **Eventbrite** | Wallet 연동, QR 직접 표시 | QR 중심 stub 영역 분리 |
| **Dice** | 이벤트 아트워크 통합, 프리미엄 느낌 | 이벤트 썸네일 활용 가능성 (v2) |
| **Airbnb Experiences** | 예약 확인서 카드 스타일 | 정보 배치 참고 |

## 현재 상태 (AS-IS)

```
┌──────────────────────────┐
│        AppBar: 내 티켓     │
├──────────────────────────┤
│                          │
│                          │
│      ┌──────────┐        │
│      │          │        │
│      │  QR Code │        │
│      │  240x240 │        │
│      │          │        │
│      └──────────┘        │
│                          │
│  입장 시 파트너에게        │
│  이 화면을 보여주세요      │
│                          │
└──────────────────────────┘
```

**문제점**:
- 흰 배경에 QR만 있어 시각적 밀도가 낮음
- 어떤 이벤트 티켓인지 맥락 정보 없음
- 입장 승인이라는 특별한 순간의 감성 부재
- 브랜드 요소 없음

## 구성 요소 (TO-BE)

### 전체 레이아웃

```
┌─────────────────────────────────────┐
│  Scaffold: surface (#F9FAFB)        │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ▓▓▓▓ HEADER (gradient) ▓▓▓▓│    │  ← 1. 브랜드 헤더
│  │  Minglit Logo               │    │
│  │  BOARDING PASS · 입장권     │    │
│  ├─────────────────────────────┤    │
│  │                             │    │
│  │  EVENT INFO SECTION         │    │  ← 2. 이벤트 정보
│  │  날짜·시간  →  장소          │    │
│  │       이벤트 제목            │    │
│  │                             │    │
│  ├─ ─ ─ ─ ─ ─ ○ ─ ─ ─ ─ ─ ─ ─┤    │  ← 3. 절취선 (perforation)
│  │                             │    │
│  │  ┌───────────────┐          │    │  ← 4. QR Stub
│  │  │               │          │    │
│  │  │   QR CODE     │          │    │
│  │  │               │          │    │
│  │  └───────────────┘          │    │
│  │                             │    │
│  │  TICKET NO. · STATUS        │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  안내 문구                           │
└─────────────────────────────────────┘
```

### 1. 브랜드 헤더 (Header Strip)

항공 보딩패스 상단 항공사 로고 바를 오마주.

- **배경**: primary gradient (`#9900FF` → `#7B2FBE`, 좌→우)
- **높이**: 64px
- **내용**:
  - 좌측: Minglit 로고 (SVG, white, height 24px)
  - 우측: "BOARDING PASS" 텍스트 (영문, `labelMedium`, white, letter-spacing 2px)
  - 우측 아래: "입장권" (한글, `labelSmall`, white, opacity 0.7)
- **모서리**: 상단만 라운딩 (16px = `MinglitRadius.card`)

### 2. 이벤트 정보 섹션 (Flight Info Zone)

대한항공 보딩패스의 출발지-도착지 양쪽 배치를 이벤트 맥락으로 재해석.

- **배경**: `#FFFFFF` (`MinglitColors.background`)
- **패딩**: `MinglitSpacing.large` (24px)

#### 2-1. 상단 라벨 행 (Label Row)

항공 보딩패스의 FROM/TO 라벨 스타일.

```
DATE                    VENUE
```
- 스타일: `labelSmall`, `textSecondary` (#4B5563), letter-spacing 1px, uppercase

#### 2-2. 값 행 (Value Row)

```
4월 25일 (금)          강남 라운지바
   19:00          →
```

- **날짜/시간** (좌측):
  - 날짜: `titleMedium` bold (#111827)
  - 시간: `headlineSmall` bold (#9900FF primary) — 시간을 크게 강조
- **화살표** (중앙): `→` 아이콘 (20px, `textSecondary`)
- **장소** (우측):
  - 장소명: `titleMedium` bold (#111827), 우측 정렬
  - 1줄 말줄임

#### 2-3. 이벤트 타이틀 (Event Title)

```
─────────────────
금요일 밤 와인 테이스팅
TICKET · 일반 입장권
```

- 상단 `Divider` (1px, `surface` #F9FAFB)
- 이벤트명: `titleLarge` bold (#111827), 2줄 말줄임, 중앙 정렬
- 티켓 종류: `labelMedium`, `textSecondary`, 중앙 정렬
- **마진**: 상하 `MinglitSpacing.medium` (16px)

### 3. 절취선 (Perforation Line)

항공 보딩패스의 절취선 디테일. 이 디테일이 "진짜 티켓" 느낌의 핵심.

- **구현**: 카드 좌우에 반원 노치 (semicircle cutout, radius 12px) + dashed 라인
- **노치 색상**: scaffold `surface` (#F9FAFB) — 카드에 구멍이 뚫린 것처럼 보임
- **점선**: 2px dash, 4px gap, `#E5E7EB` (gray-200)
- **노치 위치**: 카드 좌우 가장자리, 수직 중심

### 4. QR Stub 섹션

보딩패스 하단 stub (짐표 분리 부분)을 오마주. 바코드/QR이 위치하는 영역.

- **배경**: `#FFFFFF`
- **패딩**: `MinglitSpacing.large` (24px)
- **모서리**: 하단만 라운딩 (16px)

#### 4-1. QR 코드

- **크기**: 200x200px (현재 240에서 축소 — 정보 밀도 확보)
- **스타일**: 기존 `qr_flutter` 유지
- **스캐닝 애니메이션**: 기존 유지 (primary color 수평선, 2초 주기)
- **QR 중앙**: Minglit 아이콘 (32x32px, primary color) 오버레이 (선택)
- **중앙 정렬**

#### 4-2. 티켓 메타 (Ticket Meta Row)

QR 아래 정보 행. 항공 보딩패스의 GATE / SEAT / CLASS 행을 오마주.

```
  TICKET NO.          STATUS
  #TK-2024-0425      ● BOARDING
```

- **티켓 번호** (좌측):
  - 라벨: "TICKET NO.", `labelSmall`, `textSecondary`, letter-spacing 1px
  - 값: 티켓 ID 축약 (`#TK-{날짜}-{순번}`), `labelMedium`, `textPrimary`
- **상태** (우측):
  - 라벨: "STATUS", `labelSmall`, `textSecondary`, letter-spacing 1px
  - 값: 상태 배지
    - 오늘 이벤트: `● BOARDING` (green dot + `success` #22C55E)
    - 미래 이벤트: `CONFIRMED` (primary #9900FF)
    - 지난 이벤트: `USED` (gray, `textSecondary`)

### 5. 안내 문구

카드 아래 scaffold 위.

- 텍스트: "입장 시 파트너에게 이 화면을 보여주세요"
- 스타일: `bodySmall`, `textSecondary`, 중앙 정렬
- 마진 상: `MinglitSpacing.large` (24px)

### 6. 위조 방지 안내 (Optional)

- 텍스트: "스크린샷은 입장에 사용할 수 없습니다"
- 스타일: `labelSmall`, `textSecondary`, opacity 0.5
- 마진 상: `MinglitSpacing.small` (8px)

## 상태별 변형

### 오늘 이벤트 (D-Day)

- 헤더 gradient에 미세한 shimmer 애니메이션 (선택, v2)
- STATUS: `● BOARDING` (green pulse 애니메이션)
- 스캐닝 라인 활성

### 미래 이벤트

- STATUS: `CONFIRMED` (primary color)
- 스캐닝 라인 활성
- 헤더 static

### 지난 이벤트

- 카드 전체 opacity 0.55 (`MinglitOpacity.overlay`)
- STATUS: `USED`
- 스캐닝 라인 비활성
- QR 위에 "사용됨" 워터마크 (선택)

### 에러 상태

- 기존 에러 UI 유지 (error 아이콘 + 메시지)
- 보딩패스 카드는 표시하지 않음

### 로딩 상태

- 보딩패스 카드 skeleton (shimmer)
- 헤더는 gradient 유지, 본문 영역만 skeleton

## 데이터 소스

### 기존 사용

| 소스 | 용도 |
|------|------|
| `TicketTokenService.getToken(ticketId)` | QR 토큰 데이터 |
| `TicketToken.toJson()` | QR 인코딩 데이터 |

### 추가 필요

| 소스 | 용도 | 방법 |
|------|------|------|
| 이벤트명 | 타이틀 표시 | `TicketQRScreen`에 `eventTitle` 파라미터 추가 또는 `TicketToken`에서 추출 |
| 이벤트 날짜/시간 | DATE 섹션 | 동일 |
| 이벤트 장소 | VENUE 섹션 | 동일 |
| 티켓 종류 | TICKET 라벨 | 동일 |
| 이벤트 상태 (오늘/미래/종료) | STATUS 배지 | `event.startTime` 비교 |

**설계 옵션**:
- **Option A (권장)**: `TicketQRScreen`의 파라미터를 확장하여 이벤트 메타데이터를 전달
- **Option B**: `TicketToken`에 이벤트 메타를 포함 (토큰 사이즈 증가 우려)
- **Option C**: ticketId로 별도 쿼리 (네트워크 추가 호출)

## 라우트 변경

- **변경 없음**: 기존 `TicketQRScreen(ticketId)` 라우트 유지
- 파라미터만 확장: `TicketQRScreen(ticketId, eventMeta?)` 또는 provider로 주입

## 접근성

- QR 코드: `Semantics(label: '이벤트 입장 QR 코드')` 유지
- 밝기 자동 조절: 기존 로직 유지 (스캔 가시성)
- 색상 대비: 흰 배경 위 `textPrimary` (#111827) = WCAG AA 충족
- 헤더 흰색 텍스트 on gradient: 대비 비율 확인 필요 (7:1 이상 권장)

## 유저 시뮬레이션

### 페르소나 1: 지은 (27세, 첫 이벤트 참가자)

> 금요일 퇴근 후 와인 테이스팅 이벤트에 처음 참가. 입구에서 QR을 보여줘야 하는데 긴장됨.

- **현재 문제**: QR만 보이니 "이게 맞나?" 확신이 안 듬. 이벤트명이 없어서 다른 이벤트 QR은 아닌지 불안.
- **개선 효과**: 보딩패스에 이벤트명/일시/장소가 있어 한눈에 확인 가능. "BOARDING" 배지로 입장 가능 상태 확인. 자신감 있게 QR 제시.

### 페르소나 2: 민수 (32세, 이벤트 단골)

> 이번 달에만 3개 이벤트 참가. 여러 티켓 중 오늘 것을 빠르게 찾아야 함.

- **현재 문제**: QR 화면에 이벤트 구분 정보 없음. 여러 티켓이 있을 때 혼동 가능.
- **개선 효과**: 이벤트명과 날짜가 카드에 표시되어 즉시 확인. 오늘 이벤트는 "BOARDING" 녹색 표시로 시각적 구분.

### 페르소나 3: 수진 (29세, SNS 활발 유저)

> 이벤트 참가 경험을 인스타에 공유하고 싶음. 스크린샷을 찍을 만한 순간을 찾음.

- **현재 문제**: 흰 바탕에 QR만 있는 화면은 공유 가치가 없음.
- **개선 효과**: 보딩패스 디자인은 시각적으로 매력적. 항공 티켓 감성은 "특별한 경험" 느낌을 강화. 자발적 공유 유도 (위조방지 문구로 QR 자체는 보호).

### 페르소나 4: 파트너 직원 (이벤트 주최측)

> 입구에서 참가자 QR을 스캔하는 역할. 빠르게 유효한 티켓인지 확인해야 함.

- **현재 문제**: QR만 보이므로 시각적으로 유효성 판단 불가. 스캔 전까지 아무 정보 없음.
- **개선 효과**: "BOARDING" 상태 + 이벤트명으로 빠른 시각 확인. QR 스캔 전에도 올바른 이벤트 티켓인지 1차 확인 가능.

## 구현 이슈 분할 (예상)

| 순서 | 이슈 제목 | 의존성 | 우선순위 |
|------|-----------|--------|----------|
| 1 | `BoardingPassCard` 위젯 생성 (헤더 + 정보 + 절취선 + QR stub) | 없음 | P1 |
| 2 | `TicketQRScreen` 리팩토링 — `BoardingPassCard` 통합 + 이벤트 메타 전달 | #1 | P1 |
| 3 | 절취선 커스텀 페인터 (`PerforationClipper`) | #1 | P1 |
| 4 | 상태별 변형 (오늘/미래/종료) | #2 | P2 |
| 5 | (선택) 헤더 shimmer 애니메이션 | #1 | P3 |
| 6 | (선택) QR 중앙 Minglit 아이콘 오버레이 | #1 | P3 |
