# 티켓 QR 화면 — Boarding Pass 리디자인 테스트 계획

## 개요

현재 `TicketQRScreen`을 항공 보딩패스 메타포로 리디자인한다. 기존 흰 배경 + QR 전용 레이아웃에서 브랜드 헤더 + 이벤트 정보 + 절취선 + QR stub 4영역 카드 구조로 변경. 백엔드 변경 없음 (기존 `TicketTokenService` + `TicketToken` 활용) → DB/EF 테스트 불필요.

**참고**: `docs/qa/automation-test-guide.md`

### 피처 파이프라인

| 단계 | 담당 | 이슈 | PR | 산출물 | 상태 |
|------|------|------|-----|--------|------|
| 기획 | pm | #1526 | #1530 | spec.md, wireframe.html | 완료 |
| UX 리뷰 | ux-designer | #1526 | - | 리뷰 코멘트 | 완료 |
| 테스트 계획 | qa-lead | #1526 | 현재 PR | test-plan.md | 진행 중 |
| 구현 | swe | - | - | 코드 | 대기 |

---

## 계층별 테스트 계획

### Layer 1: Edge Function / DB 테스트

해당 없음 — 신규 백엔드 변경 없음. 기존 `TicketTokenService.getToken()` 재사용.

### Layer 2: Controller/Provider 테스트 (순수 로직)

| 대상 | 파일 | 테스트 케이스 | 우선순위 |
|------|------|-------------|---------|
| `BoardingPassStatus` 결정 로직 | `apps/app_user/test/src/features/ticket/logic/boarding_pass_status_test.dart` | 아래 상세 | P1 |
| `TicketQRScreen` 이벤트 메타 전달 | `apps/app_user/test/src/features/ticket/logic/ticket_qr_meta_test.dart` | 아래 상세 | P1 |

#### `BoardingPassStatus` — 상태 결정 로직

티켓 상태를 `event.startTime`과 현재 시간 비교로 결정:

```
✅ 오늘 이벤트 (startTime이 오늘) → BOARDING 상태 반환
✅ 미래 이벤트 (startTime이 내일 이후) → CONFIRMED 상태 반환
✅ 지난 이벤트 (startTime이 어제 이전) → USED 상태 반환
✅ 오늘 자정 경계 — 23:59 시작 이벤트가 BOARDING으로 분류
✅ 날짜 비교가 UTC가 아닌 로컬 타임존 기준
```

#### 이벤트 메타데이터 전달 검증

```
✅ TicketQRScreen에 eventTitle, eventDateTime, eventVenue, ticketName이 전달됨
✅ 이벤트 메타가 null일 때 fallback 텍스트 표시 (defensive)
✅ 긴 이벤트명 (50자+) — 2줄 말줄임 적용 (overflow: TextOverflow.ellipsis, maxLines: 2)
✅ 긴 장소명 — 1줄 말줄임
```

### Layer 3: Widget 테스트 (Flutter)

| 위젯 | 파일 | 테스트 케이스 | 우선순위 |
|------|------|-------------|---------|
| `BoardingPassCard` | `apps/app_user/test/src/features/ticket/ui/boarding_pass_card_test.dart` | 아래 상세 | P1 |
| `PerforationClipper` | `apps/app_user/test/src/features/ticket/ui/perforation_clipper_test.dart` | 아래 상세 | P2 |
| `TicketQRScreen` 리팩터링 | `apps/app_user/test/src/features/ticket/ui/ticket_qr_screen_test.dart` | 아래 상세 | P1 |

#### `BoardingPassCard` — 보딩패스 카드 위젯

```
✅ 헤더 스트립 렌더링: Minglit 로고 + "BOARDING PASS" + "입장권" 텍스트 존재
✅ 이벤트 정보 섹션: DATE/VENUE 라벨 + 날짜/시간/장소 값 표시
✅ 이벤트 타이틀 표시: 이벤트명 + 티켓 종류 텍스트
✅ 절취선 영역: 좌우 노치 + dashed line 렌더링 (CustomPainter 존재 확인)
✅ QR stub 섹션: QR 코드 렌더링 (200x200) + 티켓 번호 + 상태 배지
✅ BOARDING 상태: 녹색 dot + "BOARDING" 텍스트 (오늘 이벤트)
✅ CONFIRMED 상태: primary 색상 + "CONFIRMED" 텍스트 (미래 이벤트)
✅ USED 상태: gray 색상 + "USED" 텍스트 + 카드 전체 opacity 0.55
✅ USED 상태에서 스캐닝 애니메이션 비활성 확인
✅ 안내 문구 "입장 시 파트너에게 이 화면을 보여주세요" 카드 외부에 표시
```

#### `PerforationClipper` — 절취선 커스텀 페인터

```
✅ CustomClipper/CustomPainter 생성 시 에러 없음
✅ 좌우 반원 노치가 카드 가장자리에 위치 (clipPath 검증)
```

#### `TicketQRScreen` — 리팩터링 후 통합

```
✅ 토큰 로딩 성공 → BoardingPassCard 렌더링
✅ 토큰 null → 기존 에러 UI 표시 (BoardingPassCard 미표시)
✅ 로딩 상태 → skeleton shimmer 표시
✅ 에러 상태 → 기존 에러 UI 유지
✅ 밝기 자동 최대화 동작 유지 (기존 TicketQRViewer 기능)
✅ dispose 시 밝기 복원 동작 유지
✅ Semantics label '이벤트 입장 QR 코드' 유지 (접근성)
```

### Layer 4: Golden 테스트 (시각적 회귀)

| 화면 | 변형 | 파일 | 우선순위 |
|------|------|------|---------|
| BoardingPassCard | BOARDING (오늘) | `apps/app_user/test/alchemist/boarding_pass_card_golden_test.dart` | P1 |
| BoardingPassCard | CONFIRMED (미래) | 동일 | P1 |
| BoardingPassCard | USED (종료) | 동일 | P2 |
| BoardingPassCard | 로딩 skeleton | 동일 | P2 |
| BoardingPassCard | 긴 이벤트명 말줄임 | 동일 | P3 |

```dart
// Golden 테스트 예시
@Tags(['golden'])
library;

goldenTest(
  'BoardingPassCard states',
  fileName: 'boarding_pass_card_states',
  builder: () => GoldenTestGroup(
    children: [
      GoldenTestScenario(name: 'boarding', child: /* BOARDING 상태 */),
      GoldenTestScenario(name: 'confirmed', child: /* CONFIRMED 상태 */),
      GoldenTestScenario(name: 'used', child: /* USED 상태 (opacity 0.55) */),
      GoldenTestScenario(name: 'skeleton', child: /* 로딩 skeleton */),
    ],
  ),
);
```

### Layer 5: 라우트 / 통합 테스트

| 대상 | 파일 | 테스트 케이스 | 우선순위 |
|------|------|-------------|---------|
| 라우트 파라미터 | `apps/app_user/test/src/features/ticket/ui/ticket_qr_screen_test.dart` | 아래 상세 | P2 |

```
✅ 기존 TicketQRScreen(ticketId) 라우트가 정상 동작 (호환성)
✅ 이벤트 메타 파라미터 확장 시 기존 호출 코드 호환 (Optional 파라미터)
✅ MyTicketsPage → TicketQRScreen 네비게이션 정상 동작
```

---

## 기존 테스트 회귀 방지

`TicketQRScreen` 리팩터링 시 기존 테스트가 깨지지 않도록:

1. **`test/integration/cuj_ticket_qr_test.dart`**: QR 토큰 로딩 + 렌더링 CUJ — `BoardingPassCard` 도입 후에도 QR 데이터 인코딩 계약 유지 확인
2. **`test/alchemist/ticket_qr_screen_golden_test.dart`**: 기존 golden 파일 업데이트 필요 (UI가 완전히 변경되므로 새 golden으로 교체)
3. **`test/src/features/ticket/data/ticket_wallet_repository_test.dart`**: 변경 없음 — 데이터 레이어 미변경
4. **`test/src/features/ticket/data/ticket_token_service_test.dart`**: 변경 없음
5. **`test/scenarios/ticket_qr_scenarios.dart`**: mock override 업데이트 필요 (이벤트 메타 파라미터 추가 시)

---

## 엣지 케이스 테스트

| 케이스 | 테스트 위치 | 우선순위 |
|--------|-----------|---------|
| 이벤트 메타 null (이전 버전 호출) | TicketQRScreen widget test | P1 |
| 자정 경계 — 23:59 시작 이벤트 BOARDING 판정 | BoardingPassStatus logic test | P1 |
| 날짜 변경 (자정 넘김) 시 상태 전이 | BoardingPassStatus logic test | P2 |
| 긴 이벤트명 (50자+) 말줄임 | widget test + golden | P2 |
| 긴 장소명 말줄임 | widget test + golden | P3 |
| 스크린샷 위조 방지 문구 표시 | widget test | P3 |
| 밝기 설정 실패 (ScreenBrightness 예외) | TicketQRViewer test (기존) | P2 |
| 오프라인 → 캐시 토큰 사용 | CUJ integration test (기존) | P2 |

---

## Runtime QA 시나리오 업데이트

`docs/qa/test-cases/app-user-smoke.md` 및 `docs/qa/test-cases/cuj-user.md`에 다음 시나리오 추가/업데이트 필요:

### Smoke (app-user-smoke.md)

기존 티켓 QR 진입 시나리오를 업데이트:

```
- 내 티켓 → 입장 QR 탭 → 보딩패스 카드 UI 확인 (헤더/이벤트정보/절취선/QR 4영역)
- BOARDING/CONFIRMED/USED 상태별 배지 색상 확인
```

### CUJ (cuj-user.md)

```
- 이벤트 결제 완료 → 내 티켓 → QR 화면 → 보딩패스에 이벤트명/일시/장소 표시 확인
- 이벤트 당일 → QR 화면 → "● BOARDING" 녹색 상태 + 스캔 애니메이션 활성
- 지난 이벤트 QR → "USED" 상태 + 카드 흐릿하게 표시 + 스캔 애니메이션 비활성
```

---

## 실행 순서

### P1 (필수) — 24 test cases

| # | 테스트 그룹 | 파일 | 케이스 수 |
|---|-----------|------|----------|
| 1 | `BoardingPassStatus` 상태 결정 | `ticket/logic/boarding_pass_status_test.dart` | 5 |
| 2 | 이벤트 메타 전달 검증 | `ticket/logic/ticket_qr_meta_test.dart` | 4 |
| 3 | `BoardingPassCard` 위젯 | `ticket/ui/boarding_pass_card_test.dart` | 10 |
| 4 | `TicketQRScreen` 리팩터링 | `ticket/ui/ticket_qr_screen_test.dart` | 7 |
| 5 | Golden: BOARDING + CONFIRMED | `goldens/boarding_pass_card_golden_test.dart` | 2 |
| 6 | 엣지: 메타 null + 자정 경계 | (1, 4번에 포함) | 이미 카운트됨 |

> 엣지 케이스(6번)는 별도 파일이 아니라 해당 Provider/Widget 테스트 파일 내 group으로 작성.

### P2 (권장) — 12 test cases

| # | 테스트 그룹 | 파일 | 케이스 수 |
|---|-----------|------|----------|
| 1 | `PerforationClipper` 커스텀 페인터 | `ticket/ui/perforation_clipper_test.dart` | 2 |
| 2 | 라우트 호환성 | `ticket/ui/ticket_qr_screen_test.dart` | 3 |
| 3 | Golden: USED + skeleton | `goldens/boarding_pass_card_golden_test.dart` | 2 |
| 4 | 엣지: 날짜 변경 + 긴 이벤트명 + 밝기 실패 + 오프라인 캐시 | 각 해당 파일 | 5 |

### P3 (선택) — 3 test cases

| # | 테스트 그룹 | 파일 | 케이스 수 |
|---|-----------|------|----------|
| 1 | Golden: 긴 이벤트명 말줄임 | `goldens/boarding_pass_card_golden_test.dart` | 1 |
| 2 | 긴 장소명 말줄임 | widget test | 1 |
| 3 | 위조 방지 문구 표시 | widget test | 1 |

---

**총 39 test cases** (P1: 24건, P2: 12건, P3: 3건)

> 모든 파일 경로는 `apps/app_user/test/src/features/` 기준 상대 경로.
> Golden 테스트는 `apps/app_user/test/alchemist/` 기준.
