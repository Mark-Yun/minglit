# PRD: 파트너 정산 (Partner Settlement)

## Summary

이벤트가 completed 상태로 전환될 때 정산 레코드를 자동 생성하고, 14일 환불 유예 후 검증을 거쳐 PortOne Payout API를 통해 파트너 계좌로 자동 지급하는 정산 파이프라인. 불변 원장과 7-상태 머신으로 법무/감사 요건을 충족한다.

## Motivation / Problem to Solve

- 이벤트 참가비가 파트너에게 정산되지 않으면 서비스 신뢰도와 파트너 이탈 위험 직결
- 수동 정산 처리는 오류·지연·분쟁 발생 시 추적이 불가능
- 전자상거래법(5년 보존) + 전자금융거래법(PG 처리 기록) 준수 필요
- 파트너가 정산 현황/수수료 내역을 직접 조회할 수 없어 CS 문의 증가
- 레거니 architecture.md/requirements.md 형태 문서로 CUJ 기반 테스트 기준 부재

## Goals

### Target Users

- **파트너(이벤트 주최자)**: 정산 현황 조회 + 이의 제기 + 계좌 관리
- **운영팀(Admin)**: 홀드·취소·수동 조정·재시도·재조정
- **Finance Admin**: 배치 지급 실행 + 3-way 재조정 감사
- **법무/감사**: 불변 원장·체크섬·감사 로그 검증

### Key Goals

- **P0**: 이벤트 완료 시 정산 레코드 자동 생성 (`on_event_completed` DB 트리거 — 멱등성)
- **P0**: 14일 유예 후 PENDING → READY 자동 전환 (nightly cron)
- **P0**: READY 배치 지급 실행 (PortOne Payout API, 지수 백오프 재시도)
- **P0**: 7-상태 머신 (PENDING/HOLD/CANCELED/READY/PROCESSING/COMPLETED/FAILED)
- **P0**: 파트너가 앱에서 정산 현황 조회 (요약·목록·상세)
- **P0**: 정산 시점 수수료율 스냅샷 (사후 율 변경 영향 없음)
- **P0**: 전체 상태 전환 감사 로그 (불변)
- **P1**: 3-way 재조정 (PortOne 리포트 + 내부 원장 + 은행 대사)
- **P1**: 운영팀 HOLD·취소·수동 조정 (admin-dashboard 통해)
- **P1**: 정산 PDF 다운로드 (파트너용)

### Non-Goals

- 외화 정산 (KRW 단일)
- 세금계산서 자동 발행 (별도 PR)
- 파트너 앱 내 배치 지급 실행 UI (Admin 전용)
- 실시간 정산 (배치 주기 단축 가능하나 본 PRD 범위 외)

## Product Principles

1. **불변 원장**: 상태 전환마다 append-only 감사 로그. UPDATE/DELETE 없음.
2. **멱등성**: 동일 이벤트(`source_type='EVENT'`, `source_id=event.id`)에 대해 정산 레코드 1건만 생성 (이중 생성 방지).
3. **율 스냅샷**: 정산 생성 시점 수수료율·VAT율 캡처 — 사후 변경 영향 없음.
4. **체크섬**: PENDING→READY 전환 시 필수 필드 검증 + 금액 무결성 체크.
5. **자기 서비스**: 파트너가 정산 현황·수수료 내역·이의 제기를 앱에서 직접 처리.

## Technical Approach

- **상태 머신** (`transition_settlement_status` DB 함수의 허용 매트릭스 기준):
  - 정상 지급: `PENDING → READY → PROCESSING → COMPLETED`
  - 체크섬 실패 (READY 전환 전): `PENDING → HOLD`
  - 지급 실패 재시도: `PROCESSING → FAILED → READY → PROCESSING` (max 8회 지수 백오프)
  - 비재시도 오류 (PROCESSING 중): `PROCESSING → FAILED → HOLD` (PROCESSING에서 HOLD 직접 전환 불가)
  - 이벤트 취소: `PENDING|READY|FAILED|HOLD → CANCELED` (PROCESSING은 FAILED 경유 후 CANCELED 가능)
- **저장 (활성)**: `settlement_items`, `payouts`, `payout_transfers`, `settlement_histories`, `adjustment_items`
- **저장 (레거시/읽기전용)**: `settlements` — 이전 아키텍처 아카이브. 쓰기 경로 없음. 호환성 유지 목적으로만 보존.
- **EF**: `partner-manage-settlement`, `settlement-query`, `settlement-register-transfers`, `settlement-transfer`
- **배치**: pg_cron nightly (PENDING→READY), 지급 배치 (READY→PROCESSING)
- **UI**: `settlement_page.dart` (대시보드/목록/상세 탭) + `bank_account_page.dart`
- **외부 의존**: PortOne Payout API (지급 실행), PortOne Settlement Report (재조정)

## User Journey

### Scenario 1: 이벤트 완료 → 정산 레코드 자동 생성 (CUJ 1-x)

이벤트가 `completed` 상태로 전환 → DB `on_event_completed` 트리거가 `create_settlement_on_event_completion()` 실행 → 정산 레코드 PENDING 생성 (수수료율·VAT 스냅샷 포함). 파트너는 앱에서 해당 이벤트의 정산이 PENDING 상태로 진입한 것을 확인한다. 결제 승인은 이 시나리오의 선행 조건(event_participants 생성)이며 정산 직접 트리거가 아님.

### Scenario 2: 14일 후 READY 전환 + 배치 지급 (CUJ 2-x)

nightly cron이 14일 경과한 PENDING 레코드를 READY로 전환 → 배치 지급 실행 → PortOne Payout → COMPLETED. 파트너는 앱에서 정산 완료 + 입금 내역을 확인한다.

### Scenario 3: 파트너가 정산 현황 조회 (CUJ 3-x)

파트너가 앱 정산 페이지에서 요약 KPI (총 정산 금액·수수료·입금 예정) 확인 → 이벤트별 목록 → 상세(수수료 내역·상태 타임라인) 조회.

### Scenario 4: 정산 실패 재시도 (CUJ 4-x)

지급 실행 중 PortOne 오류 → FAILED 전환 → 지수 백오프 재시도 (최대 8회). 비재시도 오류는 FAILED → HOLD 전환 + 운영팀 알림 (PROCESSING에서 HOLD 직접 전환 불가).

### Scenario 5: 파트너가 계좌 정보 등록/변경 (CUJ 5-x)

파트너가 정산 계좌를 최초 등록하거나 변경한다. 변경 후에는 다음 배치부터 새 계좌로 지급.

### Scenario 6: 이벤트 취소 → 정산 CANCELED (CUJ 6-x)

이벤트가 운영 정책 또는 파트너 요청으로 취소되어 지급 대상에서 제외됨. 개별 참가자의 결제 취소는 이 경로와 무관: 이벤트 완료 전 취소 → `event_applications` 환불 처리 후 정산 집계에서 자동 제외, 완료·지급 이후 차지백 → `adjustment_items`로 사후 반영. CANCELED는 terminal 상태이며 이후 지급 불가.

## Data Flow

### Scenario 1

이벤트 `completed` 전환 → DB `on_event_completed` 트리거 → `create_settlement_on_event_completion()` → `settlement_items` PENDING 생성 + 수수료율·VAT 스냅샷

### Scenario 2

pg_cron (03:00 KST) → 14일 경과 PENDING 조회 → 체크섬 검증 → READY 전환 → 배치 지급 → PortOne API → COMPLETED 또는 FAILED (재시도 가능) 또는 FAILED→HOLD (비재시도)

### Scenario 3

파트너 앱 → `settlement-query` EF → 요약/목록/상세 데이터 반환 → UI 렌더
계좌 관리: 파트너 앱 → `partner-manage-settlement` EF → 계좌 upsert (bank_account_page)

## KPIs / Success Metrics

- **정산 완료율**: COMPLETED / (COMPLETED + CANCELED) ≥ 99.5% — FAILED는 재시도 가능(non-terminal) 상태이므로 분모에서 제외. 종결 상태는 COMPLETED·CANCELED만 해당.
- **지급 지연**: READY 전환 후 배치 지급 ≤ 24h (p95)
- **파트너 정산 문의 감소**: CS 채널 정산 문의 ≥ 50% 감소 (런칭 후 4주)
- **재조정 미스매치**: 0건 (daily 3-way 대사 pass)

## Launch Strategy

- Phase 1: 정산 조회 + 자동 파이프라인 (이미 구현됨)
- Phase 2: PDF 다운로드 + 이의 제기 self-service
- Phase 3: Admin 대시보드 통합 (admin-dashboard PR)

## Legal Basis

| 근거 | 내용 |
|------|------|
| 전자상거래법 시행령 제6조 | 대금결제·공급 기록 5년 보존 |
| 전자상거래법 시행령 제6조 | 소비자 불만·분쟁 처리 기록 3년 보존 |
| 부가가치세법 | 세금계산서 등 세무 기록 5년 보존 |
| 전자금융거래법 | PG 처리 기록 보존 |

## References

- **기존 문서**: `docs/features/settlement/partner-settlement/requirements.md`, `architecture.md`
- **코드**: `apps/app_partner/lib/src/features/settlement/`
- **EF**: `supabase/functions/partner-manage-settlement/`, `settlement-transfer/`
- **PortOne Payout API**: PortOne 공식 문서 (정산 이체)
