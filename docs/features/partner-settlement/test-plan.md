# Settlement 도메인 — 테스트 보강 계획

## 현재 커버리지 요약

Settlement 도메인은 이미 상당한 테스트 커버리지를 확보하고 있다:

- **Repository 테스트** (23건): `settlement_repository_test.dart` — 모든 API 호출 커버
- **Controller 테스트** (21건): settlement, settlement_list, settlement_dashboard 컨트롤러
- **Coordinator 테스트** (4건): provider 생성, goToSettlement, goToDetail, goToBankAccount
- **Golden 테스트**: settlement_page, settlement_empty_state
- **Integration 테스트 (CUJ)**: cuj_09 (정산 생성), cuj_10 (상태 머신)
- **Backend Integration**: settlement_pipeline_scenario (수수료 계산 검증)
- **pgTAP 테스트** (11파일): 스키마, 상태 머신, 트리거/cron, 지급 조립, 재시도, 영업일 달력, 시스템 설정, kill switch, 달력 통합, 대사, 모니터링
- **Edge Function 테스트**: settlement-query, settlement-register-transfers, settlement-transfer, partner-manage-settlement

## 이 계획의 범위

위 기존 테스트에서 누락된 **8개 갭**을 보강한다: 데이터 모델 파싱, 공유 모델, 위젯 3종, coordinator retryPayout, 상세 페이지, 다운로드 시트.

---

## 계층별 테스트 계획

### Layer 1: Unit 테스트 — 데이터 모델 파싱

#### 1-1. `settlement_models.dart` (app_partner)

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/settlement/settlement_models_test.dart` | `PartnerSettlement.fromJson`: 정상 JSON → 모든 필드 정확히 파싱 | P1 |
| | `PartnerSettlement.fromJson`: status 대문자 정규화 (`PENDING` → `pending`) | P1 |
| | `PartnerSettlement.fromJson`: null/누락 필드 → 기본값 적용 (빈 문자열, 0 등) | P1 |
| | `PartnerSettlement.fromJson`: 타입 강제 변환 (문자열 "1000" → int 1000) | P1 |
| | `SettlementItem.fromJson`: 25+ 필드 전체 정상 파싱 | P1 |
| | `SettlementItem.fromJson`: null coalescing — 모든 nullable 필드 null 입력 시 기본값 | P1 |
| | `PartnerRevenueSummary.fromJson`: 정상 파싱 + 타입 강제 변환 | P2 |
| | `PartnerMonthlyRevenue.fromJson`: 정상 파싱 + 타입 강제 변환 | P2 |
| | `_toInt`: int 입력 → 그대로 반환 | P1 |
| | `_toInt`: num 입력 (3.7) → 반올림 (4) | P1 |
| | `_toInt`: 문자열 입력 ("42") → int 42 | P1 |
| | `_toInt`: null 입력 → 0 | P1 |
| | `_toInt`: 파싱 불가 문자열 ("abc") → 0 | P2 |
| | `_toDouble`: double 입력 → 그대로 반환 | P1 |
| | `_toDouble`: num 입력 → double 변환 | P1 |
| | `_toDouble`: 문자열 입력 ("3.14") → double 3.14 | P1 |
| | `_toDouble`: null 입력 → 0.0 | P1 |
| | `_toDouble`: 파싱 불가 문자열 → 0.0 | P2 |
| | `_toDateTime`: DateTime 입력 → 그대로 반환 | P1 |
| | `_toDateTime`: ISO8601 문자열 → DateTime 파싱 | P1 |
| | `_toDateTime`: null 입력 → DateTime.now() (근사 비교) | P1 |
| | `_toDateTime`: 잘못된 형식 문자열 → DateTime.now() 폴백 | P2 |

#### 1-2. `settlement_item_detail.dart` (minglit_kit 공유 모델)

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `shared/packages/minglit_kit/test/src/data/models/settlement_item_detail_test.dart` | `SettlementItemDetail.fromJson`: 정상 JSON → 모든 필드 파싱 (중첩 포함) | P1 |
| | `SettlementItemDetail.fromJson`: 중첩 `payoutData` 파싱 → `PayoutSummary` 객체 | P1 |
| | `SettlementItemDetail.fromJson`: 중첩 `historiesData` 파싱 → `List<SettlementHistoryEntry>` | P1 |
| | `SettlementItemDetail.fromJson`: 중첩 `adjustmentsData` 파싱 → `List<AdjustmentItemModel>` | P1 |
| | `SettlementItemDetail.fromJson`: `payoutData` null → PayoutSummary 기본값 | P1 |
| | `SettlementItemDetail.fromJson`: `historiesData` null → 빈 리스트 | P2 |
| | `SettlementItemDetail.fromJson`: `adjustmentsData` null → 빈 리스트 | P2 |
| | `PayoutSummary.fromJson`: `scheduledAt` null → 정상 처리 | P1 |
| | `PayoutSummary.fromJson`: `bankAccountSnapshot` null → 정상 처리 | P1 |
| | `SettlementHistoryEntry.fromJson`: 필수 필드 정상 파싱 | P1 |
| | `SettlementHistoryEntry.fromJson`: 필수 필드 누락 시 동작 확인 | P2 |
| | `AdjustmentItemModel.fromJson`: 정상 파싱 | P1 |
| | `AdjustmentItemModel.fromJson`: `reasonCode` null → 정상 처리 | P2 |
| | `SettlementItemDetail.toJson`: round-trip (fromJson → toJson → fromJson 동일성) | P1 |
| | `PayoutSummary.toJson`: round-trip 동일성 | P2 |
| | `SettlementHistoryEntry.toJson`: round-trip 동일성 | P2 |
| | `AdjustmentItemModel.toJson`: round-trip 동일성 | P2 |

---

### Layer 2: Widget 테스트

#### 2-1. `SettlementStatusBadge`

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/settlement/widgets/settlement_status_badge_test.dart` | `SettlementStatus.fromString`: 7개 상태 문자열 → 올바른 enum 매핑 (`pending`, `confirmed`, `processing`, `completed`, `failed`, `canceled`, `suspended`) | P1 |
| | `SettlementStatus.fromString`: 대소문자 무관 (`PENDING`, `Pending`, `pending` 모두 동일) | P1 |
| | `SettlementStatus.fromString`: 알 수 없는 문자열 → `unknown` 폴백 | P1 |
| | `SettlementStatus.label`: 8개 상태 라벨 정확성 검증 (한국어) | P1 |
| | `SettlementStatusBadge`: compact 모드 렌더링 (작은 크기) | P2 |
| | `SettlementStatusBadge`: non-compact 모드 렌더링 (기본 크기) | P2 |
| | `SettlementStatusBadge`: `canceled` 상태 → 텍스트에 strikethrough 장식 적용 | P1 |
| | `SettlementStatusBadge`: `completed` 상태 → 성공 컬러 적용 | P2 |
| | `SettlementStatusBadge`: `failed` 상태 → 에러 컬러 적용 | P2 |

#### 2-2. `SettlementCard`

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/settlement/widgets/settlement_card_test.dart` | 정상 데이터 → 상태 배지, 정산 금액, 생성 일시 모두 표시 | P1 |
| | `_formatAmount`: 양수 (1000) → "1,000" 콤마 포맷 | P1 |
| | `_formatAmount`: 음수 (-500) → "-500" 표시 | P1 |
| | `_formatAmount`: 0 → "0" 표시 | P2 |
| | `_formatAmount`: 큰 금액 (1000000) → "1,000,000" 포맷 | P2 |
| | `onTap` 콜백 → 카드 탭 시 호출 확인 | P1 |
| | status 누락 → 기본값 `PENDING` 적용 | P1 |
| | netAmount 누락 → 기본값 0 적용 | P2 |
| | createdAt 빈 문자열 → '-' 표시 | P2 |

#### 2-3. `StatusFilterChips`

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/settlement/widgets/status_filter_chips_test.dart` | 8개 칩 렌더링: "전체" + 7개 상태 필터 | P1 |
| | 선택된 칩 하이라이트 스타일 적용 | P1 |
| | "전체" 칩 탭 → `onStatusChanged(null)` 콜백 호출 | P1 |
| | 특정 상태 칩 탭 → `onStatusChanged('해당상태')` 콜백 호출 | P1 |
| | 초기 선택 상태 반영 (selectedStatus 파라미터) | P2 |
| | 다른 칩 탭 시 이전 선택 해제 + 새 칩 하이라이트 | P2 |

#### 2-4. `SettlementDetailPage`

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/settlement/settlement_detail_page_test.dart` | 로딩 상태 → `CircularProgressIndicator` 표시 | P1 |
| | 에러 상태 → 에러 메시지 + 재시도 버튼 표시 | P1 |
| | 재시도 버튼 탭 → 데이터 재조회 | P2 |
| | detail null → "정산 항목을 찾을 수 없습니다." 메시지 표시 | P1 |
| | 정상 데이터 → `StatusMessageCard` 렌더링 | P1 |
| | 정상 데이터 → `AmountBreakdown` 렌더링 | P1 |
| | 정상 데이터 → `StatusTimeline` 렌더링 | P1 |
| | 정상 데이터 → `ActionButtons` 렌더링 | P1 |
| | `StatusMessageCard`: 7개 상태별 메시지 정확성 검증 | P1 |
| | `StatusMessageCard`: `unknown` 상태 → 폴백 메시지 | P2 |
| | `AmountBreakdown`: 금액 ₩ 접두사 표시 | P1 |
| | `AmountBreakdown`: 수수료 차감 항목 `-` 접두사 표시 | P1 |
| | `ActionButtons`: status=`FAILED` + retryable=true → 재시도 버튼 표시 | P1 |
| | `ActionButtons`: status=`FAILED` + retryable=false → 재시도 버튼 미표시 | P1 |
| | `ActionButtons`: status!=`FAILED` → 재시도 버튼 미표시 | P2 |
| | `ActionButtons`: CSV 다운로드 버튼 항상 표시 | P1 |

#### 2-5. `DownloadBottomSheet`

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/settlement/widgets/download_bottom_sheet_test.dart` | CSV 생성: 올바른 헤더 행 출력 | P1 |
| | CSV 생성: 데이터 행 정확성 | P1 |
| | CSV 생성: BOM 접두사 (UTF-8 with BOM) 포함 | P1 |
| | `_escapeCsv`: 콤마 포함 문자열 → 쌍따옴표 감싸기 | P1 |
| | `_escapeCsv`: 쌍따옴표 포함 → 이중 쌍따옴표 이스케이프 | P1 |
| | `_escapeCsv`: 줄바꿈 포함 → 쌍따옴표 감싸기 | P1 |
| | `_escapeCsv`: 특수문자 없는 문자열 → 그대로 반환 | P2 |
| | CSV 생성 중 로딩 상태 표시 | P2 |
| | Share 통합 테스트 (플랫폼 의존 — mock 또는 스킵) | P3 |

---

### Layer 3: Widget 테스트 — Coordinator retryPayout

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/settlement/settlement_coordinator_retry_test.dart` | 성공 플로우: 로딩 표시 → repository.retryPayout 호출 → 성공 스낵바 표시 → 로딩 숨김 | P1 |
| | 실패 플로우: 로딩 표시 → repository.retryPayout 실패 → 에러 스낵바 표시 → 로딩 숨김 | P1 |
| | context.mounted guard: 언마운트된 context → 스낵바 미표시 (크래시 방지) | P1 |
| | repository.retryPayout 호출 시 올바른 settlementId 전달 확인 | P2 |

---

## 실행 순서

**P1 (필수): 52건**
- 데이터 모델 파싱 (`settlement_models.dart`): 14건
- 공유 모델 파싱 (`settlement_item_detail.dart`): 10건
- `SettlementStatusBadge` 위젯: 4건
- `SettlementCard` 위젯: 4건
- `StatusFilterChips` 위젯: 4건
- `SettlementDetailPage` 위젯: 11건
- `DownloadBottomSheet` 위젯: 6건
- Coordinator `retryPayout`: 3건

**P2 (권장): 29건**
- 데이터 모델 추가 엣지 케이스: 5건
- 공유 모델 null/round-trip: 7건
- `SettlementStatusBadge` 스타일: 5건
- `SettlementCard` 엣지 케이스: 4건
- `StatusFilterChips` 세부: 2건
- `SettlementDetailPage` 세부: 4건
- `DownloadBottomSheet` 세부: 2건
- Coordinator `retryPayout` 세부: 1건

**P3 (선택): 1건**
- `DownloadBottomSheet` Share 통합: 1건

**총 82건**
