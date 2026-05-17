# Spec: 티켓 QR Boarding Pass 리디자인

> **참조**
> - PRD: [prd.md](./prd.md)
> - MDS specs:
>   - [`ticket_qr_screen`](../../../../apps/mds/docs/public/specs/ticket_qr_screen/) — 보딩패스 카드 (헤더/정보/절취선/QR stub, state PNG 포함)
>   - [`my_tickets_page`](../../../../apps/mds/docs/public/specs/my_tickets_page/) — 진입점 (입장 QR 버튼)
> - Wireframe: [wireframe.html](./wireframe.html)

## CUJs

| ID  | Priority | CUJ Name | Details | FR | NFR |
|-----|----------|----------|---------|----|----|
| 1-1 | P0 | 오늘 이벤트 QR 진입 → BOARDING 표시 | • 내 티켓에서 오늘 이벤트 "입장 QR" 탭<br>• 보딩패스 카드 렌더링<br>• STATUS = `● BOARDING` (success green) | FR-1, FR-2, FR-3, FR-6 | NFR-1, NFR-2 |
| 1-2 | P0 | 이벤트 정보(일시/장소/제목) 노출 | • 카드 상단 헤더 + 이벤트 정보 섹션<br>• DATE/VENUE 라벨 + 값<br>• 이벤트명 중앙 + 티켓 종류 | FR-1, FR-2 | NFR-1 |
| 1-3 | P0 | 위조 방지 안내 표시 | • 카드 하단 안내 + "스크린샷은 입장에 사용할 수 없습니다" 보조 안내<br>• `bodySmall` + 흐린 색 | FR-7 | NFR-3 |
| 1-4 | P1 | 절취선/노치 렌더링 | • 카드 좌우 반원 노치(radius 12px)<br>• 점선(2px dash, 4px gap)<br>• scaffold 배경색과 동일한 노치 채움 | FR-4 | NFR-1 |
| 1-5 | P1 | 헤더 brand gradient + 로고 | • primary gradient(#9900FF → #7B2FBE)<br>• 좌 로고 + 우 "BOARDING PASS" / "입장권" | FR-3 | NFR-1 |
| 1-6 | P2 | QR 스캐닝 라인 애니메이션 | • 기존 primary 수평선 2초 주기<br>• 오늘/미래만 활성, 과거 비활성 | FR-6 | NFR-1 |
| 2-1 | P0 | 미래 이벤트 CONFIRMED 표시 | • 며칠 전 진입<br>• STATUS = `CONFIRMED` (primary color)<br>• 스캔 라인 활성 | FR-6 | NFR-1 |
| 2-2 | P1 | 티켓 번호 노출 | • QR 아래 "TICKET NO." + 축약 ID(`#TK-{날짜}-{순번}`)<br>• 표시 형식 일관성 | FR-5 | NFR-1 |
| 2-3 | P1 | 이벤트 시간 강조 | • 시간은 `headlineSmall` bold + primary color<br>• 날짜보다 시각적 우위 | FR-2 | NFR-1 |
| 3-1 | P1 | 지난 이벤트 USED 표시 | • 과거 이벤트 진입 시 카드 전체 opacity 0.55<br>• STATUS = `USED` (gray)<br>• 스캔 라인 비활성 | FR-6, FR-8 | NFR-1 |
| 3-2 | P2 | 사용됨 워터마크 | • QR 위에 "사용됨" 텍스트 워터마크(선택, V2) | FR-8 | NFR-1 |
| 3-3 | P2 | 로딩 / 에러 상태 | • 로딩: 카드 skeleton + 헤더 gradient 유지<br>• 에러: 기존 에러 UI(아이콘 + 메시지), 카드 미표시 | FR-9 | NFR-2 |

## Functional Requirements

- **FR-1**: 티켓 QR 화면 진입 시 보딩패스 카드 한 장(헤더 + 이벤트 정보 + 절취선 + QR stub) 으로 렌더링.
- **FR-2**: 이벤트 정보 섹션은 DATE/VENUE 라벨 행 + 값 행(날짜 좌, 화살표 중앙, 장소 우) + 이벤트명(중앙) + 티켓 종류 표시.
- **FR-3**: 헤더는 brand primary gradient + 로고(좌) + "BOARDING PASS / 입장권"(우). 상단 모서리만 라운딩.
- **FR-4**: 카드 좌우에 반원 노치 + 점선으로 절취선 표현. 노치는 scaffold 배경색과 동일한 색으로 카드에 구멍이 뚫린 효과.
- **FR-5**: QR 아래 TICKET NO. 라벨 + 축약 ID 표시 (`#TK-{YYYYMMDD}-{순번}` 형식).
- **FR-6**: 이벤트 시작 시간을 기준으로 상태 배지 분기 — 오늘: `● BOARDING`(success), 미래: `CONFIRMED`(primary), 과거: `USED`(gray). 스캔 라인은 오늘/미래만 활성.
- **FR-7**: 카드 아래 메인 안내("입장 시 파트너에게 이 화면을 보여주세요") + 보조 안내("스크린샷은 입장에 사용할 수 없습니다").
- **FR-8**: 과거 이벤트 진입 시 카드 전체 opacity 0.55 적용. 스캔 라인 비활성.
- **FR-9**: 로딩 중에는 헤더 gradient 만 유지하고 본문은 skeleton. 에러 시 기존 에러 UI 유지, 카드 미표시.

## Non-Functional Requirements

- **NFR-1**: 카드 first paint(QR 포함) 500ms 이내 (에뮬레이터 baseline, p50 기준). 절취선 커스텀 페인터는 60fps 유지.
- **NFR-2**: QR 코드는 기존 `qr_flutter` + 토큰 서비스를 그대로 사용 — 토큰 생성/검증 로직 변경 없음.
- **NFR-3**: 위조 방지 안내 텍스트는 WCAG AA 가독성 (`textSecondary` + opacity 0.5 사용 시에도 contrast ratio 4.5:1 이상). 헤더의 흰색 텍스트는 gradient 위에서 7:1 이상 권장.
- **NFR-4**: 접근성 — QR 코드 `Semantics(label: '이벤트 입장 QR 코드')` 유지. 상태 배지에 `Semantics(label: '입장 가능 상태: 오늘')` 등 명시.
- **NFR-5**: 화면 밝기 자동 최대화(기존 로직) — 스캔 가시성 보장.

## Edge Cases

| CUJ ID | 케이스 | 기대 동작 |
|--------|--------|----------|
| 1-1 | 이벤트 메타(제목/장소) 누락 | placeholder 텍스트("이벤트 정보를 불러올 수 없어요") + QR 은 정상 표시 |
| 1-1 | 시각이 자정 직후 (오늘 → 어제 전환) | `event.startTime` 비교로 USED 로 전환. 페이지 재진입 시 갱신 |
| 1-3 | 사용자가 스크린샷 시도 | 카드는 그대로 캡처. 위조 방지 안내가 카드에 함께 노출 |
| 1-4 | 절취선 노치가 다른 배경에서 보임 | 모든 진입 경로에서 scaffold 배경색(#F9FAFB)을 가정. 다른 배경이면 노치 색을 prop 으로 주입 |
| 1-5 | 다크 모드 | 현재 다크 모드 미지원 → 라이트 모드 유지 (Open Q) |
| 1-6 | 저사양 디바이스에서 애니메이션 frame drop | 애니메이션 비활성 옵션 (시스템 reduce-motion 존중) |
| 2-1 | 미래 이벤트의 시작 시간이 임박(1시간 이내) | CONFIRMED 유지. BOARDING 전환은 당일 자정 기준 (Open Q — 1시간 전 BOARDING?) |
| 2-2 | 티켓 ID 가 표준 형식이 아님 | 원본 ID 일부를 안전하게 노출 + 형식 통일은 후속 |
| 3-1 | 지난 이벤트인데 환불/취소 상태 | USED 대신 별도 라벨(REFUNDED/CANCELLED) — 정책 미정 (Open Q) |
| 3-2 | "사용됨" 워터마크가 QR 가독성 저해 | V2 도입 시 opacity 0.2 이하 + 가독성 검증 필요 |
| 3-3 | 네트워크 단절 시 토큰 미발급 | 기존 캐시 토큰 사용. 캐시 없으면 에러 UI |

## Open Questions

- [ ] **이벤트 메타 전달 방식** — Option A(파라미터 확장) vs Option B(토큰에 포함, 크기 증가) vs Option C(별도 쿼리)? 권장: A
- [ ] **BOARDING 전환 시점** — 자정 기준 vs 이벤트 시작 N시간 전?
- [ ] **다크 모드 지원** — V1 미지원이지만 추후 brand gradient 가독성 검토
- [ ] **환불/취소된 티켓의 상태 표시** — USED vs REFUNDED vs CANCELLED 별도?
- [ ] **헤더 shimmer / 중앙 로고 오버레이** — V1 포함 vs V2 분리?
- [ ] **이벤트 아트워크 통합 (Dice 패턴)** — V2 검토 항목

---

## 화면 구성 (참고)

### 화면 1: 보딩패스 카드 (TicketQRScreen)

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
│  │  DATE              VENUE    │    │  ← 2. 이벤트 정보 (라벨)
│  │  4월 25일 (금)     강남     │    │  ← (값)
│  │     19:00     →  라운지바    │    │
│  │                             │    │
│  │  ─────────────────────────  │    │
│  │  금요일 밤 와인 테이스팅      │    │  ← 이벤트 타이틀
│  │  TICKET · 일반 입장권        │    │
│  │                             │    │
│  ├─ ─ ─ ○ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤    │  ← 3. 절취선
│  │                             │    │
│  │  ┌───────────────┐          │    │  ← 4. QR Stub
│  │  │   QR CODE     │          │    │
│  │  │   200x200     │          │    │
│  │  └───────────────┘          │    │
│  │                             │    │
│  │  TICKET NO.        STATUS   │    │
│  │  #TK-2024-0425  ● BOARDING  │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  입장 시 파트너에게 이 화면을 보여주세요│
│  스크린샷은 입장에 사용할 수 없습니다  │
└─────────────────────────────────────┘
```

### 디자인 토큰 (참고)

| 요소 | 값 |
|------|-----|
| 헤더 gradient | `#9900FF` → `#7B2FBE` (좌→우) |
| 헤더 높이 | 64px |
| 카드 모서리 | 16px (`MinglitRadius.card`) |
| 절취선 노치 반경 | 12px |
| 점선 패턴 | 2px dash, 4px gap, `#E5E7EB` |
| QR 크기 | 200×200px (기존 240 → 축소로 정보 밀도 확보) |
| 이벤트 정보 패딩 | 24px (`MinglitSpacing.large`) |
| 안내 텍스트 마진 | 상 24px |
| 위조 방지 안내 마진 | 상 8px |
| 위조 방지 안내 opacity | 0.5 |

### 상태별 변형

| 상태 | 배지 | 카드 opacity | 스캔 라인 | 헤더 |
|------|------|-------------|----------|------|
| 오늘 (D-Day) | `● BOARDING` (success green) | 1.0 | 활성 | gradient + shimmer(선택 V2) |
| 미래 | `CONFIRMED` (primary purple) | 1.0 | 활성 | gradient static |
| 과거 | `USED` (gray) | 0.55 | 비활성 | gradient static |
| 에러 | — | 카드 미표시 | — | 기존 에러 UI |
| 로딩 | — | skeleton | — | gradient 유지 |

### 데이터 정의 (참고)

| 항목 | key | 설명 |
|------|-----|------|
| QR 토큰 | `TicketTokenService.getToken(ticketId)` | 기존 토큰 서비스 |
| 이벤트명 | `eventTitle` | 카드 타이틀 |
| 시작 시각 | `startTime` | DATE/시간/상태 분기 |
| 장소 | `venue` | VENUE 영역 |
| 티켓 종류 | `ticketType` | 타이틀 아래 보조 |
| 티켓 ID 축약 | `#TK-{YYYYMMDD}-{순번}` | TICKET NO. 표시 |

### 페르소나 (참고)

- **지은 (27세, 첫 참가)**: 입구 긴장 → 보딩패스 + BOARDING 으로 안심
- **민수 (32세, 단골)**: 여러 티켓 중 오늘 것을 BOARDING 녹색으로 즉시 식별
- **수진 (29세, SNS 활발)**: 카드 자체가 공유 가치 보유 + 위조 방지 안내로 QR 보호
- **파트너 직원**: 스캔 전 이벤트명/상태로 시각 1차 확인
