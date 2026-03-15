# 밍글릿 (Minglit) 결제 및 정산 시스템 소프트웨어 요구사항 명세서 (SRS)

- **버전**: 2.0
- **작성일**: 2026. 03. 13.

### 변경 이력

| 버전 | 일자 | 작성자 | 변경 내용 |
|------|------|--------|-----------|
| 1.0 | 2026.03.11 | — | 초안 작성 (결제/정산 기본 구조, 상태 머신 7단계, DB 컬럼 정의) |
| 1.2 | 2026.03.11 | — | Audit Spec 추가 (settlement_histories, 체크섬, 요율 스냅샷) |
| 2.0 | 2026.03.13 | — | 5인 Virtual Advisory Board 리뷰 반영. 상태 머신 보강(전이 매트릭스/재시도/HOLD 조건), DB 스키마 5개 테이블 DDL 확정, 법적/규제(섹션 6), 회계/세무(섹션 7), 파트너 경험(섹션 8), 운영 요구사항(4.3~4.6) 신규 추가. REQ 항목 ~10개 → 187개 |

---

## 1. 소개 (Introduction)

### 1.1 목적

밍글릿 호스트(파트너) 정산금의 생성, 보류, 확정, 지급 과정을 자동화하고 통제하기 위한 명세서이다. 특히 과거 정산 내역의 소급 적용을 방지하기 위해 정산 시점의 모든 요율(Rate)과 금액(Amount)을 스냅샷으로 저장한다.

### 1.2 범위

- PG사 웹훅 및 클라이언트 투트랙 승인 파이프라인
- 14일 환불 보증 기간 기반의 상태 머신 관리
- 요율 스냅샷을 포함한 정산 원장 관리 및 배치 송금

### 1.3 설계 원칙

핵심은 (1) 상태 전이의 단일 진실원천(Single source of truth), (2) 원장 불변(immutable ledger) + append-only 감사로그, (3) 지급/송금의 멱등성(idempotency)과 운영 대사(reconciliation)를 제약조건/인덱스/알람으로 강제하는 것이다.

---

## 2. 전체 시스템 구조

public, payment, settlement 스키마 분리 및 PGMQ 비동기 처리.

---

## 3. 기능적 요구사항 (Functional Requirements)

### 3.1 결제 승인 및 정산 원장 적재

- **REQ-3.1.1** (이중 승인 처리): PG 웹훅과 앱 직접 승인 중 선착순 1건만 처리 (멱등성 보장).
- **REQ-3.1.2** (정산 요율 스냅샷): 정산 데이터 생성 시점의 파트너 수수료율 및 표준 부가세율을 조회하여 `settlement_items`에 함께 기록한다.

### 3.2 상태 머신 로직

```
PENDING -> HOLD -> CANCELED -> READY -> PROCESSING -> COMPLETED -> FAILED
```

총 7단계.

#### 3.2.1 상태 정의 (State Definitions)

- **REQ-3.2.01**: 정산 항목(settlement item)의 상태(`status`)는 아래 7개 문자열 중 하나여야 한다: `PENDING`, `HOLD`, `CANCELED`, `READY`, `PROCESSING`, `COMPLETED`, `FAILED`.

- **REQ-3.2.02**: `PENDING`은 "정산 대상 원천거래(source)가 수집되었으나, 정산 금액 산식/검증/필수 데이터가 모두 충족되기 전" 상태다. 진입 조건: 신규 생성 시 기본값 또는 `HOLD/FAILED`에서 데이터가 보강되어 재계산 전.

- **REQ-3.2.03**: `READY`는 "정산 금액이 확정되고(산식 계산 완료), 지급 묶음(payout) 편성 및 송금 요청이 가능"한 상태다. 진입 조건: 필수 필드(파트너, 정산기간, 금액, 수수료, 계좌 스냅샷)가 모두 존재하고, `hold`/`fail` 사유가 비어 있으며, 체크섬(checksum) 검증이 통과.

- **REQ-3.2.04**: `PROCESSING`은 "지급/송금 프로세스가 진행 중" 상태다. 진입 조건: `READY`에서 지급 실행이 시작되며, 동일 항목에 대해 동시에 2개 이상의 실행이 발생하지 않도록 단일 실행 잠금(lock)이 확보되어야 한다(REQ-3.2.15 참조).

- **REQ-3.2.05**: `COMPLETED`는 "해당 정산 항목의 지급이 최종 성공으로 확정되었고, 더 이상 상태가 변하지 않는 종결(terminal) 상태"다. 진입 조건: 연결된 송금 시도(`payout_transfers`)가 성공으로 확정되고, 내부원장(ledger) 반영이 완료되며, 대사 대상 식별자(provider transfer id 등)가 저장됨.

- **REQ-3.2.06**: `CANCELED`는 "정산 항목이 정책/관리자 판단으로 지급 대상에서 제외되었고, 더 이상 상태가 변하지 않는 종결(terminal) 상태"다. 진입 조건: `PENDING/READY/HOLD/FAILED`에서만 가능하며, `PROCESSING` 이후에는 취소 전이를 금지한다(대신 `adjustment_items`로 반영, REQ-7.13).

- **REQ-3.2.07**: `FAILED`는 "지급/송금 또는 정산 산식/검증 단계에서 오류가 발생하여 자동 진행이 중단된 상태(비종결, 재시도 가능)"다. 진입 조건: (a) `PROCESSING` 중 외부 연동 실패/타임아웃, (b) `READY` 진입 검증 실패(데이터 불일치/체크섬 오류) 발생 시.

- **REQ-3.2.08**: `HOLD`는 "컴플라이언스/분쟁/계좌정보 문제 등으로 의도적으로 진행이 정지된 상태(비종결)"다. `HOLD`는 반드시 `hold_reason_code`와 `hold_reason_detail`(사유 상세)를 동반해야 한다(REQ-3.2.23).

- **REQ-3.2.09**: 진행 상태(in-progress states)는 `PENDING`, `READY`, `PROCESSING`이며, 대기/정지 상태(paused states)는 `HOLD`, `FAILED`다. 종결 상태(terminal states)는 `COMPLETED`, `CANCELED`다.

- **REQ-3.2.10**: 모든 상태 변경은 "원인 이벤트(event_type), 행위자(actor), 이전/이후 상태(from/to), 변경 시각(event_at)"을 `settlement_histories`에 append-only로 기록해야 한다(REQ-5.2.02).

#### 3.2.2 허용 전이 매트릭스 (Transitions)

아래 표에 없는 전이는 모두 금지한다(deny by default).

| From | To | Trigger (이벤트) | Guard (조건) | Actor |
|---|---|---|---|---|
| PENDING | READY | `calc_succeeded` | 필수 데이터 충족 + 금액/요율 검증 + 체크섬 OK | system/job |
| PENDING | HOLD | `hold_applied` | `hold_reason_code` 존재 | admin/system |
| PENDING | CANCELED | `canceled` | 아직 지급 실행 전 | admin |
| HOLD | READY | `hold_released` | `hold_reason_*` 제거 + 재검증 통과 | admin/system |
| HOLD | CANCELED | `canceled` | 지급 실행 전 | admin |
| READY | PROCESSING | `payout_started` | 단일 실행 잠금 획득 + 연결 payout 생성됨 | system/job |
| READY | HOLD | `hold_applied` | 지급 시작 전 + 사유 저장 | admin/system |
| READY | CANCELED | `canceled` | 지급 시작 전 | admin |
| PROCESSING | COMPLETED | `payout_succeeded` | 송금 성공 확정 + 원장 반영 완료 | system |
| PROCESSING | FAILED | `payout_failed` | 실패 분류(error_class) 저장 + 재시도 가능여부 계산 | system |
| FAILED | READY | `retry_scheduled` | `retry_count < max_retry` + 재시도 간격 도래 | system/job |
| FAILED | HOLD | `hold_applied` | 반복 실패/분쟁 등으로 수동 개입 필요 | admin/system |
| FAILED | CANCELED | `canceled` | 정책상 지급 불가 확정 | admin |

- **REQ-3.2.11**: 상태 전이 API는 반드시 Guard를 서버에서 재검증해야 하며(클라이언트 신뢰 금지), 실패 시 `409 Conflict`(상태 불일치) 또는 `422 Unprocessable Entity`(가드 불충족)로 구분 응답해야 한다.

- **REQ-3.2.12**: `PROCESSING` 진입 시각(`processing_started_at`)과 `PROCESSING` 종료 시각(`processing_ended_at`)을 저장해야 하며, 종료 시각은 `COMPLETED/FAILED` 진입 시 필수로 채워야 한다.

- **REQ-3.2.13**: `PROCESSING` 중 시스템 장애로 "무한 처리"가 발생하지 않도록, `PROCESSING` 상태가 `processing_started_at + 2 hours`를 초과하면 자동으로 `FAILED`로 전이시키고 `error_class=TIMEOUT_STUCK_PROCESSING`을 저장해야 한다.

- **REQ-3.2.14**: `READY -> PROCESSING` 전이는 멱등해야 하며, 동일 항목에 대해 중복 호출이 오더라도 "최대 1회만 실제 송금 요청"이 발생해야 한다(송금 멱등성은 REQ-5.3.12의 `payout_transfers.idempotency_key`로 보장).

- **REQ-3.2.15**: 동시성 제어는 DB 원자 업데이트(Compare-And-Set, CAS)로 강제해야 한다. 예: `UPDATE ... SET status='PROCESSING' WHERE id=? AND status='READY'`가 1행 갱신될 때만 실제 처리 수행.

- **REQ-3.2.16**: 종결 상태(`COMPLETED`, `CANCELED`)에서는 어떤 전이도 허용하지 않으며, 전이 시도는 감사로그에 "거부 이벤트(rejected_transition)"로 기록해야 한다.

- **REQ-3.2.17**: `FAILED`는 재시도 가능한 실패(`retryable=true`)와 재시도 불가능(`retryable=false`)을 구분해야 하며, 재시도 불가능 실패는 자동으로 `HOLD`로 전이하거나(정책) 또는 `CANCELED`로 전이하는 운영 규칙을 코드로 고정해야 한다(아래 3.2.3).

#### 3.2.3 FAILED 재시도/수동 개입 규칙

- **REQ-3.2.18**: `FAILED` 진입 시 필수 저장 필드: `failure_reason_code`(열거값), `failure_message`(최대 512자), `error_class`(예: `BANK_API_TIMEOUT`), `retryable`(boolean), `retry_count`(int), `next_retry_at`(timestamptz).

- **REQ-3.2.19**: 자동 재시도는 지수 백오프(exponential backoff) 규칙을 따른다: `next_retry_at = now + min( 2^retry_count * 60s , 6h ) + jitter(+-20%)`. 최대 재시도 횟수는 `max_retry=8`로 고정한다.

- **REQ-3.2.20**: 아래 실패 코드는 자동 재시도를 금지(`retryable=false`)하고 즉시 `HOLD`로 전이해야 한다: `INVALID_BANK_ACCOUNT`, `ACCOUNT_CLOSED`, `NAME_MISMATCH`, `COMPLIANCE_REVIEW_REQUIRED`.

- **REQ-3.2.21**: 아래 실패 코드는 자동 재시도를 허용(`retryable=true`)한다: `BANK_API_TIMEOUT`, `BANK_API_5XX`, `NETWORK_ERROR`, `PROVIDER_RATE_LIMIT`, `TEMPORARY_INSUFFICIENT_BALANCE`(운영 정책 허용 시).

- **REQ-3.2.22**: 수동 개입(admin action)은 반드시 `settlement_histories.actor_type='ADMIN'`, `actor_id`, `admin_note`를 기록해야 하며, `FAILED -> READY` 수동 전이는 "사유/근거 링크(evidence_url)"가 없으면 금지한다.

#### 3.2.4 HOLD 진입/해제 조건

- **REQ-3.2.23**: `HOLD` 진입 시 `hold_reason_code`는 아래 중 하나여야 한다(추가 시 SRS 업데이트 필수): `COMPLIANCE`, `DISPUTE`, `BANK_INFO_MISSING`, `BANK_INFO_INVALID`, `MANUAL_REVIEW`, `FRAUD_SUSPECTED`.

- **REQ-3.2.24**: `HOLD` 해제(`hold_released`)는 반드시 "해제 전 재검증(re-validate)"을 수행해야 하며, 재검증 항목은 (a) 계좌 스냅샷 존재, (b) 금액/요율 범위, (c) 체크섬 재생성 일치, (d) 지급 가능 캘린더(REQ-4.6.03) 충족이다.

- **REQ-3.2.25**: `HOLD` 상태에서는 지급 관련 외부 호출(송금/PG 정산 요청)을 절대 수행하지 않아야 하며, 스케줄러(job)는 `status IN ('READY','FAILED')`만 조회 대상으로 삼아야 한다.

### 3.3 배치 및 크론잡

- **REQ-3.3.1** (확정 배치): `event_completed_at` + 14일 경과 시 READY 전환.
- **REQ-3.3.2** (지급 배치): 합산 후 송금 시 은행 API에 `Idempotency-Key` 전달 의무화.

### 3.4 백오피스 제어 기능

- 지급 보류(Hold)
- 사후 차감(Adjustment)
- 수동 정산 트리거
- 회계 엑셀 다운로드

---

## 4. 비기능적 요구사항 (Non-Functional Requirements)

### 4.1 데이터 무결성 및 정밀도

- **REQ-4.1.1** (금액 데이터 타입): 원단위 오차 방지를 위해 모든 금액(`_amount`) 컬럼은 `BIGINT` 사용.
- **REQ-4.1.2** (요율 데이터 타입): 수수료율 및 부가세율(`_rate`) 컬럼은 `DECIMAL(5, 2)` 형식을 사용하여 정밀도를 확보한다.
- **REQ-4.1.3** (절사 정책): 소수점 발생 시 코드 레벨에서 '원단위 내림(Floor)' 정책을 일관되게 적용한 후 정수형으로 DB에 저장한다.

### 4.2 성능 및 장애 방어

- **Chunk Processing**: 트랜잭션당 500건 분할 업데이트.
- **4중 방어막**: 앱 투트랙 승인, PG 재시도, PGMQ 큐잉, 일일 대사(Reconciliation).

### 4.3 모니터링/관측성 (Observability)

- **REQ-4.3.01**: 모든 비동기 처리(job/worker)는 `request_id`(또는 `correlation_id`)를 생성해 로그/메트릭/트레이스에 공통으로 포함해야 한다.

- **REQ-4.3.02**: 핵심 메트릭을 최소 아래 12개 수집해야 한다(이름은 그대로 사용):
  - `settlement_items_created_total`
  - `settlement_items_status_total{to_status=...}`
  - `settlement_calc_failed_total{reason=...}`
  - `payouts_created_total`
  - `payouts_completed_total`
  - `payouts_failed_total{reason=...}`
  - `payout_transfers_requested_total{provider=...}`
  - `payout_transfers_succeeded_total{provider=...}`
  - `payout_transfers_failed_total{provider=...,error_class=...}`
  - `payout_transfer_latency_ms{provider=...}` (p50/p95/p99)
  - `dlq_depth{queue=...}`
  - `reconciliation_mismatch_total{type=...}`

- **REQ-4.3.03**: 알람 임계치는 아래를 기본값으로 고정해야 한다:
  - 5분 이동창에서 `payout_transfers_failed_total / requested_total > 0.01` 이면 경고, `> 0.05`이면 치명(Critical)
  - `dlq_depth > 100` 10분 지속 시 경고, `> 1000` 즉시 치명
  - `PROCESSING` 상태 항목이 2시간 초과 1건 이상이면 치명(REQ-3.2.13)
  - 지급 목표시간(REQ-4.6.01) 대비 30분 초과 지연 payout이 1건 이상이면 경고

- **REQ-4.3.04**: 애플리케이션 로그는 JSON(one-line) 구조로 고정하며 최소 필드를 포함해야 한다: `timestamp, level, message, service, env, request_id, partner_id, payout_id, settlement_item_id, idempotency_key, event_type, error_class`.

- **REQ-4.3.05**: 개인정보/계좌정보는 로그에 평문으로 남기면 안 되며, 마스킹(`account_last4`)만 허용한다.

- **REQ-4.3.06**: 외부 연동(provider) 호출은 요청/응답을 요약해 로그로 남기되, 응답 전문은 `payout_transfers.response_payload`에 마스킹 저장한다.

- **REQ-4.3.07**: 운영 대시보드는 최소 3개 뷰를 제공해야 한다: (1) 지급 성공률/지연, (2) 실패코드 Top N, (3) 대사 불일치 건수/추이.

- **REQ-4.3.08**: 배치 처리량(throughput)과 지연(latency)은 분리 지표로 관찰해야 하며, 처리량 감소 + 지연 증가 동시 발생 시 자동으로 치명 알람을 발생시킨다.

- **REQ-4.3.09**: 모든 상태 전이는 `settlement_histories` 기반으로 재구성 가능해야 하며, 운영에서 상태가 의심될 때 "히스토리 재생성"으로 진실을 검증할 수 있어야 한다.

- **REQ-4.3.10**: 장애 대응을 위해 "마지막 성공 대사 시각/마지막 성공 송금 시각"을 노출해야 한다.

### 4.4 대사 (Reconciliation): 3-way

- **REQ-4.4.01**: 대사는 3-way로 수행해야 한다: (1) PG 정산 리포트(PG report), (2) 내부원장(`settlement_items`/`payouts`), (3) 은행 입출금 내역(bank statement).

- **REQ-4.4.02**: 대사 주기는 최소 일 1회(Daily)이며, 지급일에는 지급 완료 후 1시간 내 "당일 지급분"을 추가 대사해야 한다.

- **REQ-4.4.03**: 허용 오차(tolerance)는 원화 기준 "금액 오차 0원"을 원칙으로 하며, 예외적으로 PG 수수료 반올림 차이 등 사전에 정의된 케이스에 한해 "거래당 +-1원"을 허용한다(예외 목록은 코드 상수로 고정).

- **REQ-4.4.04**: 대사 불일치 유형은 최소 아래로 분류하고 각각 카운트/알람을 분리해야 한다: `MISSING_IN_PG`, `MISSING_IN_LEDGER`, `MISSING_IN_BANK`, `AMOUNT_MISMATCH`, `DUPLICATE`, `DATE_SHIFT`.

- **REQ-4.4.05**: 대사 플로우는 단계적으로 고정한다: 수집(import) -> 정규화(normalize) -> 매칭(match by key) -> 불일치 분류(classify) -> 티켓 생성/알림(notify) -> 수동 해결/재대사.

- **REQ-4.4.06**: 매칭 키는 최소 2종을 지원해야 한다: (a) provider transfer id 기반, (b) `(partner_id, amount, date, idempotency_key)` 기반 보조 매칭.

- **REQ-4.4.07**: 대사 결과는 "재현 가능"해야 하므로, 사용한 원본 파일의 해시(SHA-256)와 처리 시각, 처리 버전을 저장해야 한다.

- **REQ-4.4.08**: 대사 불일치가 `Critical`인 경우(은행에는 출금됐는데 내부원장 실패/미반영), 즉시 지급 중단(새로운 `READY->PROCESSING` 전이 중지) 스위치를 지원해야 한다.

- **REQ-4.4.09**: 대사로 인해 수정이 필요할 때는 원장 수정이 아니라 `adjustment_items` 추가로만 해결해야 한다(원장 불변).

- **REQ-4.4.10**: 대사 미해결 건은 24시간 내 1차 조치(원인 분류/담당자 할당)가 이루어져야 한다.

### 4.5 재시도/DLQ

- **REQ-4.5.01**: 모든 외부 연동(송금/PG/웹훅)은 at-least-once 호출을 전제로 설계하고, 멱등키로 중복 부작용을 차단해야 한다(REQ-5.3.12, REQ-6.19).

- **REQ-4.5.02**: 재시도는 지수 백오프 + 지터를 사용해야 하며, 기본 파라미터는 REQ-3.2.19와 동일하게 적용한다.

- **REQ-4.5.03**: 최대 재시도 횟수 초과 또는 `retryable=false` 실패는 DLQ로 이동시키고, DLQ 레코드에는 원본 payload 해시와 마지막 오류 정보를 저장해야 한다.

- **REQ-4.5.04**: DLQ 처리는 2가지 모드만 허용한다: (1) 재처리(replay), (2) 영구 실패 확정(mark failed + hold). 임의 수정 후 재처리는 금지한다.

- **REQ-4.5.05**: DLQ replay는 관리자 권한으로만 가능하며, replay 요청도 멱등키를 가져야 한다(같은 DLQ 메시지에 대해 중복 replay 금지).

- **REQ-4.5.06**: replay 시에도 `payout_transfers` 유니크 멱등 제약에 의해 중복 송금이 발생하지 않아야 한다.

- **REQ-4.5.07**: 재시도/리플레이로 발생한 모든 부작용(상태 전이/송금 시도)은 `settlement_histories`에 구분 이벤트로 기록되어야 한다(`retry_scheduled`, `dlq_replayed` 등).

- **REQ-4.5.08**: 재시도 가능한 오류 분류표(error_class -> retryable)는 코드 상수로 유지하고, 런타임 변경을 허용하지 않는다(운영 안정성).

- **REQ-4.5.09**: 외부 연동 타임아웃은 5초로 고정하고, 타임아웃은 `retryable=true`로 분류한다(단, provider 정책에 따라 조정 가능).

- **REQ-4.5.10**: rate limit(429) 응답은 `next_retry_at`을 provider가 제공하는 `Retry-After`(초) 헤더가 있으면 우선 적용한다.

### 4.6 SLA/운영 캘린더

- **REQ-4.6.01**: 지급 목표 시간은 "정산 확정(READY) 기준 D+2 영업일 15:00 KST"를 기본으로 한다(정책 상수).

- **REQ-4.6.02**: 컷오프(cut-off) 시간은 영업일 14:00 KST로 고정하며, 컷오프 이후 확정된 건은 다음 영업일 기준으로 스케줄링한다.

- **REQ-4.6.03**: 공휴일/주말은 영업일에서 제외하며, 운영 캘린더는 연도별 테이블로 관리하고(예: `business_calendar(date, is_business_day, reason)`), 스케줄 계산은 해당 테이블만 참조해야 한다.

- **REQ-4.6.04**: 은행 점검 시간(예: 23:30-00:30 KST)에는 송금 요청을 금지해야 하며, 해당 시간대에 걸리면 다음 허용 윈도우로 `scheduled_at`을 자동 이월해야 한다.

- **REQ-4.6.05**: SLA 지연 정의: `now > scheduled_at + 30 minutes`이고 `payouts.status not in ('COMPLETED','CANCELED')`인 경우 지연으로 간주한다.

- **REQ-4.6.06**: 지연 발생 시 파트너에게 지연 알림을 발송해야 하며, 알림에는 "지연 사유코드 + 예상 처리 시각(ETA)"가 포함되어야 한다.

- **REQ-4.6.07**: ETA는 단순 문구가 아니라 계산값이어야 하며, 최소 규칙: "다음 영업일 11:00 KST" 또는 "점검 종료 후 1시간 내" 중 빠른 값.

- **REQ-4.6.08**: SLA 준수율을 월간으로 산출해야 하며, 정의는 `completed_at <= scheduled_at` 비율로 고정한다(예외 제외 시 예외 목록을 명시).

- **REQ-4.6.09**: 운영자가 지급을 수동 트리거할 수 있어야 하나, 수동 트리거 역시 멱등키를 필요로 하며(`payout_request_idempotency_key`), 감사로그에 남겨야 한다.

- **REQ-4.6.10**: 시스템은 "지급 중단 스위치(kill switch)"를 제공해야 하며, 활성화 시 `READY->PROCESSING` 신규 전이를 금지하고 기존 `PROCESSING`은 안전 종료(FAILED 전이)한다.

---

## 5. 데이터베이스 상세 설계 요구사항

전제: PostgreSQL(Supabase). 모든 금액은 `BIGINT`(KRW 원 단위), 모든 요율(%)은 `DECIMAL(5,2)`이며, 요율 범위 체크를 DB 제약으로 강제한다.

### 5.1 `settlement_items` (정산 원장)

정산의 최소 단위 원장(ledger-like) 레코드이며, 상태/금액/수수료/세금/체크섬/원천거래 연결을 포함한다.

- **REQ-5.1.01**: `settlement_items`는 정산의 최소 단위 원장(ledger-like) 레코드이며, 상태/금액/수수료/세금/체크섬/원천거래 연결을 포함해야 한다.

- **REQ-5.1.02**: `settlement_items`의 모든 금액 컬럼(`*_amount`) 타입은 `BIGINT NOT NULL`이어야 하며, 음수 금액을 금지한다(`CHECK (amount >= 0)`) — 사후 차감/조정은 `adjustment_items`로만 표현한다(REQ-5.3.21).

- **REQ-5.1.03**: `settlement_items`에는 산식 검증용 체크섬을 저장해야 한다: `calc_checksum CHAR(64) NOT NULL` (SHA-256 hex).

- **REQ-5.1.04**: `settlement_items`는 원천거래 중복 적재를 방지하기 위해 `(partner_id, source_type, source_id)`에 유니크 제약을 둔다.

- **REQ-5.1.05**: 조회 성능을 위해 최소 인덱스 4종을 둔다: `(partner_id, settlement_period_start, settlement_period_end)`, `(status)`, `(payout_id)`, `(source_type, source_id)`.

#### 5.1.1 필수 컬럼 정의

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| `id` | `UUID` | PK |
| `partner_id` | `UUID NOT NULL` | 파트너 식별자 |
| `settlement_period_start` | `DATE NOT NULL` | 정산 기간 시작 |
| `settlement_period_end` | `DATE NOT NULL` | 정산 기간 종료 |
| `currency` | `CHAR(3) NOT NULL DEFAULT 'KRW'` | 통화 |
| `source_type` | `TEXT NOT NULL` | 원천거래 유형 (ORDER, REFUND, CHARGEBACK) |
| `source_id` | `TEXT NOT NULL` | 원천 시스템 식별자 |
| `status` | `TEXT NOT NULL` | 7개 상태 중 하나 (CHECK 제약) |
| `gross_amount` | `BIGINT NOT NULL` | 유저 실제 결제 금액 |
| `platform_fee_rate` | `DECIMAL(5,2) NOT NULL` | 정산 생성 시점의 수수료율 (예: 10.00) |
| `platform_fee_amount` | `BIGINT NOT NULL` | 결제금액 * 수수료율 (절사 적용) |
| `pg_fee_rate` | `DECIMAL(5,2) NOT NULL` | PG 수수료율 |
| `pg_fee_amount` | `BIGINT NOT NULL` | PG 수수료액 (절사 적용) |
| `vat_rate` | `DECIMAL(5,2) NOT NULL` | 적용된 부가세율 (예: 10.00) |
| `vat_amount` | `BIGINT NOT NULL` | 수수료액 * 부가세율 (절사 적용) |
| `net_amount` | `BIGINT NOT NULL` | 호스트 최종 지급액 |
| `hold_reason_code` | `TEXT` | HOLD 사유 코드 |
| `hold_reason_detail` | `TEXT` | HOLD 사유 상세 |
| `failure_reason_code` | `TEXT` | FAILED 사유 코드 |
| `failure_message` | `TEXT` | 실패 메시지 (최대 512자) |
| `retryable` | `BOOLEAN NOT NULL DEFAULT FALSE` | 재시도 가능 여부 |
| `retry_count` | `INT NOT NULL DEFAULT 0` | 재시도 횟수 |
| `next_retry_at` | `TIMESTAMPTZ` | 다음 재시도 시각 |
| `processing_started_at` | `TIMESTAMPTZ` | 처리 시작 시각 |
| `processing_ended_at` | `TIMESTAMPTZ` | 처리 종료 시각 |
| `payout_id` | `UUID` | 지급 묶음 ID (Optional, FK) |
| `calc_checksum` | `CHAR(64) NOT NULL` | SHA-256 체크섬 |
| `version` | `INT NOT NULL DEFAULT 1` | 낙관적 잠금용 버전 |
| `event_completed_at` | `TIMESTAMPTZ` | 14일 계산의 기준이 되는 이벤트 종료일 |
| `created_at` | `TIMESTAMPTZ NOT NULL DEFAULT now()` | 생성 시각 |
| `updated_at` | `TIMESTAMPTZ NOT NULL DEFAULT now()` | 갱신 시각 |

#### 5.1.2 DDL 참조

```sql
create table if not exists settlement_items (
  id uuid primary key default gen_random_uuid(),

  partner_id uuid not null,
  settlement_period_start date not null,
  settlement_period_end   date not null,

  currency char(3) not null default 'KRW',

  source_type text not null,
  source_id   text not null,

  status text not null check (status in
    ('PENDING','HOLD','CANCELED','READY','PROCESSING','COMPLETED','FAILED')
  ),

  gross_amount        bigint not null check (gross_amount >= 0),
  platform_fee_rate   decimal(5,2) not null check (platform_fee_rate >= 0 and platform_fee_rate <= 100),
  platform_fee_amount bigint not null check (platform_fee_amount >= 0),

  pg_fee_rate         decimal(5,2) not null check (pg_fee_rate >= 0 and pg_fee_rate <= 100),
  pg_fee_amount       bigint not null check (pg_fee_amount >= 0),

  vat_rate            decimal(5,2) not null check (vat_rate >= 0 and vat_rate <= 100),
  vat_amount          bigint not null check (vat_amount >= 0),

  net_amount          bigint not null check (net_amount >= 0),

  hold_reason_code    text,
  hold_reason_detail  text,
  failure_reason_code text,
  failure_message     text,

  retryable boolean not null default false,
  retry_count int not null default 0 check (retry_count >= 0),
  next_retry_at timestamptz,

  processing_started_at timestamptz,
  processing_ended_at   timestamptz,

  payout_id uuid,

  calc_checksum char(64) not null,
  version int not null default 1 check (version >= 1),

  event_completed_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint uq_settlement_items_source unique (partner_id, source_type, source_id),
  constraint ck_settlement_items_period check (settlement_period_start <= settlement_period_end),
  constraint ck_settlement_items_hold_reason check (
    (status <> 'HOLD') or (hold_reason_code is not null)
  )
);

create index if not exists idx_settlement_items_partner_period
  on settlement_items(partner_id, settlement_period_start, settlement_period_end);

create index if not exists idx_settlement_items_status
  on settlement_items(status);

create index if not exists idx_settlement_items_payout
  on settlement_items(payout_id);

create index if not exists idx_settlement_items_source
  on settlement_items(source_type, source_id);
```

- **REQ-5.1.06**: `payout_id`는 `payouts.id`를 참조하는 FK여야 하며, 지급 편성 이전에는 `NULL`이어야 한다.
- **REQ-5.1.07**: `updated_at`은 애플리케이션에서 갱신하거나, DB 트리거로 "row update 시 now()"로 강제해야 한다.
- **REQ-5.1.08**: `status='COMPLETED'`일 때는 `processing_started_at`과 `processing_ended_at`이 `NOT NULL`이어야 한다.
- **REQ-5.1.09**: `status='FAILED'`일 때는 `failure_reason_code`가 `NOT NULL`이어야 한다.
- **REQ-5.1.10**: `version`은 낙관적 잠금(optimistic locking) 용도로 사용하며, 상태 전이 시 `version=version+1` 갱신을 필수로 한다.

### 5.2 `settlement_histories` (감사 로그, append-only)

- **REQ-5.2.01**: `settlement_histories`는 append-only이며 `UPDATE/DELETE`를 애플리케이션 정책으로 금지하고, DB 권한으로도 write role에 `UPDATE/DELETE` 권한을 부여하지 않아야 한다.

- **REQ-5.2.02**: 모든 상태 전이(성공/실패/거부 포함)는 `settlement_histories`에 1건 이상 기록되어야 하며, `settlement_histories` 없이 `settlement_items.status`만 변경하는 코드는 금지한다.

- **REQ-5.2.03**: 감사로그는 "누가/언제/무엇을"을 식별할 수 있어야 하므로 `actor_type`, `actor_id`, `event_type`, `from_status`, `to_status`를 `NOT NULL`로 둔다.

- **REQ-5.2.04**: `details`는 JSONB로 저장하며, 최소 키 셋을 강제한다: `{"request_id": "...", "idempotency_key": "...", "reason": "...", "diff": {...}}` (해당 없는 키는 생략 가능).

#### 5.2.1 DDL 참조

```sql
create table if not exists settlement_histories (
  id uuid primary key default gen_random_uuid(),
  settlement_item_id uuid not null,

  event_at timestamptz not null default now(),
  event_type text not null,
  actor_type text not null check (actor_type in ('SYSTEM','JOB','ADMIN','PARTNER')),
  actor_id text not null,

  from_status text not null,
  to_status   text not null,

  idempotency_key text,
  details jsonb not null default '{}'::jsonb,

  constraint fk_settlement_histories_item
    foreign key (settlement_item_id) references settlement_items(id)
);

create index if not exists idx_settlement_histories_item_eventat
  on settlement_histories(settlement_item_id, event_at);

create index if not exists idx_settlement_histories_event_type
  on settlement_histories(event_type);
```

- **REQ-5.2.05**: `settlement_histories`에는 상태 전이 외에도 "정산 산식 재계산(recalc), 계좌 스냅샷 변경(bank_snapshot_updated), 보류 사유 변경(hold_reason_updated)" 이벤트를 기록해야 한다.
- **REQ-5.2.06**: 감사로그의 `idempotency_key`가 존재하는 경우, 동일 `settlement_item_id + event_type + idempotency_key` 조합 중복을 방지하는 유니크 인덱스를 추가해야 한다.
- **REQ-5.2.07**: 운영/감사 목적 조회를 위해 `actor_type+actor_id` 인덱스를 추가해야 한다.
- **REQ-5.2.08**: 개인정보(계좌번호 원문 등)는 `details`에 평문으로 저장하면 안 되며, 마스킹된 값(예: `account_last4`)만 저장해야 한다.
- **REQ-5.2.09**: 감사로그는 최소 5년 보관해야 한다(REQ-6.11 데이터 보존 기간과 일치).
- **REQ-5.2.10**: 모든 시간 필드는 KST 표시용이 아니라 `timestamptz`로 저장하고, 표시 레이어에서 KST 변환한다.

### 5.3 `payouts` (지급 묶음)

- **REQ-5.3.01**: `payouts`는 파트너별 지급 실행의 단위이며, 다수 `settlement_items`를 묶고 총액/상태/목표 지급 시각(scheduled_at)을 저장해야 한다.

- **REQ-5.3.02**: `payouts` 상태는 최소 `CREATED`, `READY`, `PROCESSING`, `COMPLETED`, `FAILED`, `CANCELED`를 지원해야 하며, `settlement_items` 상태 머신과 독립적으로 운영되되 참조 무결성을 유지해야 한다.

- **REQ-5.3.03**: `payouts`에는 은행 계좌 스냅샷을 JSONB로 저장해야 하며, 지급 실행 중 파트너가 계좌를 변경해도 "해당 payout의 송금 대상 계좌"는 변하지 않아야 한다(불변 스냅샷).

#### 5.3.1 DDL 참조

```sql
create table if not exists payouts (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null,

  payout_period_start date not null,
  payout_period_end   date not null,
  currency char(3) not null default 'KRW',

  status text not null check (status in ('CREATED','READY','PROCESSING','COMPLETED','FAILED','CANCELED')),

  scheduled_at timestamptz not null,
  processing_started_at timestamptz,
  processing_ended_at   timestamptz,

  item_count int not null default 0 check (item_count >= 0),

  total_gross_amount        bigint not null check (total_gross_amount >= 0),
  total_platform_fee_amount bigint not null check (total_platform_fee_amount >= 0),
  total_pg_fee_amount       bigint not null check (total_pg_fee_amount >= 0),
  total_vat_amount          bigint not null check (total_vat_amount >= 0),
  total_net_amount          bigint not null check (total_net_amount >= 0),

  bank_account_snapshot jsonb not null default '{}'::jsonb,

  payout_request_idempotency_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint ck_payouts_period check (payout_period_start <= payout_period_end)
);

create unique index if not exists uq_payouts_partner_period
  on payouts(partner_id, payout_period_start, payout_period_end);

create index if not exists idx_payouts_status_scheduled
  on payouts(status, scheduled_at);
```

- **REQ-5.3.04**: `settlement_items.payout_id`는 `payouts.id`를 FK로 참조해야 하며, payout 생성 후 배치로 연결할 때 "동일 파트너/동일 기간" 외 연결을 금지한다.
- **REQ-5.3.05**: `payout_request_idempotency_key`가 존재하는 경우, 동일 파트너에서의 중복 요청을 방지하기 위해 `(partner_id, payout_request_idempotency_key)` 유니크 인덱스를 추가해야 한다.
- **REQ-5.3.06**: `total_*_amount`는 연결된 `settlement_items`의 합과 일치해야 하며, 지급 실행 직전에 DB에서 재집계한 값과 다르면 `FAILED`로 전이하고 대사 알람을 발생시켜야 한다(REQ-4.4.04).
- **REQ-5.3.07**: 지급 실행은 "payout 단위"로 시작하되, 개별 송금 시도는 `payout_transfers`에서 관리해야 한다.
- **REQ-5.3.08**: `payouts`는 `COMPLETED` 이후 수정 불가(원장 불변)이며, 환불/차지백은 `adjustment_items`로만 반영한다.
- **REQ-5.3.09**: `bank_account_snapshot`에는 계좌번호 전체를 저장하지 않으며, 필요한 경우 암호화된 ciphertext만 저장하고(last4는 별도), 키 관리는 REQ-6.08을 따른다.
- **REQ-5.3.10**: `scheduled_at` 산정은 운영 캘린더(공휴일/점검시간)를 반영해야 하며(REQ-4.6.03), 산정 규칙을 코드로 고정한다.

### 5.4 `payout_transfers` (송금 시도 + 멱등성 키)

- **REQ-5.3.11**: `payout_transfers`는 송금 시도의 단위이며, 외부 은행/이체 제공자(provider) 호출 1회당 1행을 생성해야 한다.
- **REQ-5.3.12**: `payout_transfers.idempotency_key`는 provider에 전송되는 멱등성 키이며, `(provider, idempotency_key)` 유니크 제약으로 "중복 송금"을 DB 수준에서 차단해야 한다.
- **REQ-5.3.13**: 송금 요청/응답 payload는 JSONB로 저장하되, 개인정보/비밀키는 반드시 제거(redaction)된 형태로만 저장해야 한다.

#### 5.4.1 DDL 참조

```sql
create table if not exists payout_transfers (
  id uuid primary key default gen_random_uuid(),
  payout_id uuid not null,

  provider text not null,
  idempotency_key text not null,

  attempt_no int not null check (attempt_no >= 1),
  status text not null check (status in ('CREATED','REQUESTED','SUCCEEDED','FAILED')),

  amount bigint not null check (amount >= 0),
  currency char(3) not null default 'KRW',

  provider_transfer_id text,
  requested_at timestamptz,
  responded_at timestamptz,

  response_code text,
  response_message text,

  error_class text,
  retryable boolean not null default false,
  next_retry_at timestamptz,

  request_payload jsonb not null default '{}'::jsonb,
  response_payload jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),

  constraint fk_payout_transfers_payout
    foreign key (payout_id) references payouts(id),
  constraint uq_payout_transfers_idem unique (provider, idempotency_key)
);

create index if not exists idx_payout_transfers_payout
  on payout_transfers(payout_id);

create index if not exists idx_payout_transfers_status_retry
  on payout_transfers(status, next_retry_at);
```

- **REQ-5.3.14**: `attempt_no`는 payout+provider 내에서 1부터 증가해야 하며, 재시도 시 기존 행을 업데이트하지 말고 "새 행 추가(append)"로 남겨야 한다(감사/대사 용이성).
- **REQ-5.3.15**: 동일 payout에 대해 동시에 2개의 `REQUESTED` 전송이 발생하지 않도록, 송금 실행 job은 "(payout_id, provider) 기준 단일 실행"을 보장해야 한다(락 또는 큐 단일 처리).
- **REQ-5.3.16**: `SUCCEEDED`가 1건이라도 존재하면 payout의 실제 지급은 성공으로 간주하며, 추가 재시도 행 생성은 금지한다.
- **REQ-5.3.17**: provider로부터 "이미 처리됨(duplicate)" 응답을 받은 경우에도 `idempotency_key` 기준으로 `SUCCEEDED` 상태를 확정할 수 있어야 하며, 확정 로직은 "provider_transfer_id 또는 응답 바디의 상태"를 근거로 한다.
- **REQ-5.3.18**: 송금 성공 확정 시, `payouts.status` 및 연결된 `settlement_items.status`를 동일 트랜잭션에서 `COMPLETED`로 전이하고 `settlement_histories`에 기록해야 한다.
- **REQ-5.3.19**: 송금 실패 시, 실패코드/재시도 가능여부를 `payout_transfers`에 저장하고, payout/item 상태는 `FAILED`로 전이하되 재시도 정책은 REQ-3.2.19와 REQ-4.5.02를 따른다.
- **REQ-5.3.20**: 멱등성 키의 TTL은 "재전송/중복요청 방지" 목적이므로 최소 180일간 재사용을 금지하며, DB에는 해당 기간 동안 레코드를 보관해야 한다.

### 5.5 `adjustment_items` (사후 차감/조정)

- **REQ-5.3.21**: 환불/차지백/분쟁 조정 등 확정 이후 변동은 원장 불변 원칙에 따라 `settlement_items`를 수정하지 않고 `adjustment_items`로만 반영해야 한다.
- **REQ-5.3.22**: `adjustment_items.amount_signed`는 `BIGINT`이며 음수(차감)와 양수(가산)를 모두 허용하되, 0은 금지한다.
- **REQ-5.3.23**: `adjustment_items`는 "어떤 대상에 대한 조정인지"를 식별해야 하며, 최소 1개 이상의 참조 키를 요구한다: `related_settlement_item_id` 또는 `related_payout_id` 또는 `(source_type, source_id)`.

#### 5.5.1 DDL 참조

```sql
create table if not exists adjustment_items (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null,

  adjustment_type text not null check (adjustment_type in
    ('REFUND','CHARGEBACK','MANUAL_DEDUCT','MANUAL_ADD','FEE_CORRECTION','TAX_CORRECTION')
  ),

  amount_signed bigint not null check (amount_signed <> 0),
  currency char(3) not null default 'KRW',

  reason_code text not null,
  reason_detail text,

  related_settlement_item_id uuid,
  related_payout_id uuid,
  source_type text,
  source_id text,

  evidence_url text,
  status text not null check (status in ('CREATED','APPLIED','CANCELED')),

  created_by_actor_type text not null check (created_by_actor_type in ('SYSTEM','ADMIN')),
  created_by_actor_id text not null,

  created_at timestamptz not null default now(),

  constraint fk_adjustment_related_item
    foreign key (related_settlement_item_id) references settlement_items(id),
  constraint fk_adjustment_related_payout
    foreign key (related_payout_id) references payouts(id)
);

create index if not exists idx_adjustment_partner_created
  on adjustment_items(partner_id, created_at);

create index if not exists idx_adjustment_related
  on adjustment_items(related_settlement_item_id, related_payout_id);
```

- **REQ-5.3.24**: `adjustment_items.status='APPLIED'`가 되면 어떤 payout에 반영되었는지를 식별할 수 있어야 하며, 연결 키(예: `applied_payout_id`) 또는 `settlement_histories.details`에 반드시 기록해야 한다.
- **REQ-5.3.25**: 동일 원천에 대해 중복 조정이 생성되지 않도록 `(partner_id, adjustment_type, source_type, source_id)` 유니크 인덱스를 추가해야 한다(해당 source가 존재할 때).

### 5.6 멱등성 키 전략 (Idempotency)

- **REQ-5.3.26**: 멱등성 키 적용 범위(scope)는 최소 3개다: (1) payout 생성/요청(`payouts.payout_request_idempotency_key`), (2) provider 송금(`payout_transfers.idempotency_key`), (3) 상태 전이 이벤트(`settlement_histories.idempotency_key`, 선택).

- **REQ-5.3.27**: 키 생성 규칙은 문자열로 고정 포맷을 사용해야 한다:
  `{env}:{scope}:{partner_id}:{yyyyMMdd}-{seq}:{sha256(payload)[:12]}`
  예: `prod:transfer:8f...:20260313-0001:1a2b3c4d5e6f`

- **REQ-5.3.28**: DB 제약으로 멱등성을 강제해야 한다:
  - payout 요청: `unique(partner_id, payout_request_idempotency_key)`
  - 송금: `unique(provider, idempotency_key)`
  - 원천거래 적재: `unique(partner_id, source_type, source_id)`

- **REQ-5.3.29**: TTL은 "키 재사용 금지 기간"으로 정의하며, `payout_transfers` 및 관련 로그는 최소 180일 동안 유지되어야 한다. TTL 만료 전 동일 키 재사용은 무조건 거부해야 한다(`409 Conflict`).

- **REQ-5.3.30**: 멱등 요청 재수신 시, 서버는 "기존 결과를 그대로 반환"해야 하며(상태/transfer id 포함), 새 처리(송금 호출/상태 전이)를 수행하면 안 된다.

---

## 6. 법적/규제 요구사항

### 6.1 거래 구조/역할 정의

- **REQ-6.01**: 본 시스템의 거래 구조는 "통신판매중개자(Online marketplace intermediary)로서 플랫폼이 결제/정산 흐름을 중개"하는 모델로 정의하며, 파트너(판매자/주최자)가 최종 공급자(merchant of record)가 되는 것을 원칙으로 한다.

- **REQ-6.02**: SRS 및 정산서/약관에 플랫폼과 파트너의 책임 구분을 명시해야 한다: (a) 플랫폼: 정산 계산/지급 집행/내부원장/대사, (b) 파트너: 상품/서비스 제공 및 환불/분쟁 1차 책임(단, 플랫폼이 수탁한 업무 범위는 예외).

- **REQ-6.03**: 결제/환불/차지백 이벤트는 "원장 불변 + 조정 항목"으로만 반영되어야 하며, 사후 수정이 불가능하도록 감사로그를 유지해야 한다(REQ-5.2.01, REQ-7.13).

### 6.2 환불 정책 법적 근거 (이벤트/공연 특성 반영)

- **REQ-6.04**: 환불 정책은 "서비스 제공 시점(공연/이벤트 시작 시각) 기준"으로 환불 가능/불가 및 수수료 부과 기준을 규칙 테이블로 고정해야 한다(예: `refund_policy_rules`: `cutoff_hours`, `refund_fee_rate`).

- **REQ-6.05**: "공연 시작 이후" 환불 요청은 원칙적으로 환불 불가로 처리하되, 예외(주최자 취소/천재지변/법령상 청약철회 예외 등)는 `adjustment_items`로만 처리하고 사유코드/근거문구를 저장해야 한다.

- **REQ-6.06**: 환불 처리 시 "원천 결제건/티켓 사용 여부/입장 처리 여부"를 검증해야 하며, 검증 결과(불가 사유 포함)를 `settlement_histories.details`에 저장해야 한다.

### 6.3 개인정보(PII) 처리: 계좌정보 수집/암호화/보관/파기

- **REQ-6.07**: 파트너 계좌정보는 최소수집 원칙으로 `bank_code`, `account_holder_name`, `account_no_ciphertext`, `account_last4`만 저장해야 하며, 계좌번호 평문 저장은 금지한다.

- **REQ-6.08**: `account_no_ciphertext`는 애플리케이션 계층에서 envelope encryption(예: KMS data key)으로 암호화된 바이트열로 저장해야 하며, DB에는 복호화 키를 저장하면 안 된다.

- **REQ-6.09**: 계좌정보 접근은 역할 기반(RBAC)으로 제한해야 하며, "조회 행위" 자체를 감사로그로 남겨야 한다(누가/언제/어떤 파트너 계좌를 조회했는지).

- **REQ-6.10**: 파트너가 계좌를 변경하면, 기존 계좌 레코드는 즉시 파기하지 않고 "사용 종료 시각"을 표시한 뒤 보존 기간(REQ-6.11) 이후 파기해야 한다. 지급 스냅샷(`payouts.bank_account_snapshot`)은 지급 감사 목적상 별도 보존한다.

### 6.4 데이터 보존 기간 (Retention)

- **REQ-6.11**: 데이터 보존 기간은 아래 표를 최소 기준으로 적용해야 하며, 만료 시 파기(삭제 또는 암호화키 파기)를 수행해야 한다.

| 데이터 범주 | 예시 테이블/필드 | 보존기간 | 파기 방식 |
|---|---|---:|---|
| 정산/지급 원장 | `settlement_items`, `payouts` | 5년 | 논리삭제 금지, 기간 만료 후 삭제 |
| 감사로그 | `settlement_histories` | 5년 | 기간 만료 후 삭제 |
| 송금 시도/응답 로그 | `payout_transfers` | 5년 | payload는 마스킹/기간 만료 후 삭제 |
| 분쟁/이의제기 기록 | (파트너 CS 테이블) | 3년(종결 후) | 기간 만료 후 삭제 |
| 접근 로그 | (audit/access log) | 1년 | 기간 만료 후 삭제 |
| 계좌 암호문 | `account_no_ciphertext` | 계약 종료 후 5년 | 키 파기 또는 삭제 |

- **REQ-6.12**: 보존기간 만료 배치는 매일 1회 실행되어야 하며, 파기 결과(삭제 건수/테이블/기간)를 운영 로그로 남겨야 한다.
- **REQ-6.13**: 파기 대상에 포함되는 개인정보는 "암호문 삭제" 또는 "암호화키 폐기(crypto-shredding)" 중 하나를 선택해 일관되게 적용해야 한다.

### 6.5 보류/차감 통지 의무 및 이의제기 절차

- **REQ-6.14**: `HOLD` 진입 시 파트너에게 24시간 이내 통지해야 하며, 통지 내용에는 최소 필드가 포함되어야 한다: `hold_reason_code`, `hold_reason_detail`, 영향 범위(금액/기간), 요청 조치(필요 서류), 예상 처리기한(SLA).

- **REQ-6.15**: `adjustment_items`가 생성되면(차감/가산) 파트너에게 즉시 통지해야 하며, 통지에는 `adjustment_type`, `amount_signed`, `reason_code`, `evidence_url`, 이의제기 링크가 포함되어야 한다.

- **REQ-6.16**: 이의제기(dispute) 접수 시각부터 1영업일 이내 1차 응답(접수 확인)을 보내야 하며, 최종 결론은 5영업일 이내 제공해야 한다(세부 워크플로는 REQ-8.11).

### 6.6 웹훅(Webhook) 보안

- **REQ-6.17**: 모든 인바운드 웹훅은 TLS 1.2+로만 수신해야 하며, HMAC-SHA256 서명 검증을 필수로 한다. 헤더 규격: `X-Signature`, `X-Timestamp`, `X-Event-Id`.

- **REQ-6.18**: 서명 생성 문자열은 아래로 고정한다:
  `signing_payload = X-Timestamp + "." + raw_body`
  `X-Signature = hex(hmac_sha256(webhook_secret, signing_payload))`

- **REQ-6.19**: 재전송 방지(replay protection)를 위해 `X-Timestamp`는 수신 시각 기준 +-5분 윈도우를 초과하면 거부(401)해야 하며, `X-Event-Id`는 DB에 저장하고 중복 수신 시 200을 반환하되 처리는 1회만 수행해야 한다(멱등).

- **REQ-6.20**: 웹훅 IP allowlist를 지원해야 하며, 활성화 시 allowlist 외 요청은 403으로 거부해야 한다(환경별 설정).

- **REQ-6.21**: 웹훅 비밀키(`webhook_secret`)는 최소 90일마다 rotation을 지원해야 하며, rotation 기간에는 "구 키 + 신 키" 동시 검증(dual validation)을 허용해야 한다.

---

## 7. 회계/세무 요구사항

### 7.1 정산 금액 산식 (수식 + 체크섬)

- **REQ-7.01**: 정산 항목별 산식은 아래 순서로 고정한다(모든 `floor`는 원 단위 절사):
  - `platform_fee_amount = floor(gross_amount * platform_fee_rate / 100)`
  - `pg_fee_amount = floor(gross_amount * pg_fee_rate / 100)`
  - `vat_amount = floor((platform_fee_amount + pg_fee_amount) * vat_rate / 100)`
  - `net_amount = gross_amount - platform_fee_amount - pg_fee_amount - vat_amount`

- **REQ-7.02**: payout 총액 산식은 연결된 항목의 합으로만 계산한다:
  - `total_net_amount = sum(settlement_items.net_amount) + sum(applied_adjustments.amount_signed)`
  (조정은 payout 단위로 적용되며, 적용 내역은 추적 가능해야 함)

- **REQ-7.03**: 체크섬은 아래 canonical string의 SHA-256 hex로 계산해 `settlement_items.calc_checksum`에 저장해야 한다:
  `"{partner_id}|{period_start}|{period_end}|{currency}|{gross}|{platform_fee_rate}|{pg_fee_rate}|{vat_rate}|{platform_fee_amount}|{pg_fee_amount}|{vat_amount}|{net_amount}|v1"`
  서버는 `READY` 진입 전/후 체크섬을 재계산해 불일치 시 `FAILED`로 전이해야 한다.

- **REQ-7.04**: 모든 산식 입력(요율)은 `DECIMAL(5,2)`로 저장/계산되어야 하며, 표시/다운로드 시 소수점 2자리로 고정한다.

- **REQ-7.05**: 요율 유효 범위는 0.00~100.00(%)이며, 범위 밖이면 저장 자체를 DB 제약으로 차단해야 한다.

### 7.2 PG 수수료 부담 주체

- **REQ-7.06**: PG 수수료(`pg_fee_amount`)의 부담 주체는 정책 상수로 명시해야 하며, 본 SRS 기본값은 "파트너 부담"으로 고정한다(즉, `net_amount`에서 차감).

- **REQ-7.07**: 만약 특정 파트너/상품에서 플랫폼 부담으로 예외 적용이 필요하면, 예외는 `adjustment_items`로만 처리하며, `reason_code='PG_FEE_BORNE_BY_PLATFORM'`를 사용한다.

### 7.3 파트너 유형별 세무 처리

- **REQ-7.08**: 파트너 유형(`partner_tax_type`)은 최소 아래를 지원해야 한다: `TAXABLE`(과세), `ZERO_RATED`(영세), `EXEMPT`(면세), `SIMPLIFIED`(간이), `CORPORATE`(법인) — 실제 저장은 enum 또는 코드 테이블로 고정한다.

- **REQ-7.09**: `vat_rate` 적용 여부는 파트너 유형과 거래 유형에 따라 결정되며, 결정 규칙은 룰 테이블로 관리되어야 한다(예: `tax_rules(partner_tax_type, transaction_type, vat_rate)`).

- **REQ-7.10**: 파트너의 사업자 정보(사업자등록번호 등)는 별도 테이블로 분리 저장하고, 정산서/세금계산서 발행 시점의 스냅샷을 보관해야 한다(변경 이력 추적).

### 7.4 세금계산서 발행 규칙

- **REQ-7.11**: 세금계산서 발행 대상/주체/발행일은 정책으로 고정해야 하며, 최소 필드가 SRS에 명시되어야 한다: 공급가액, 세액, 공급자/공급받는자 정보, 작성일자, 품목, 비고(정산기간).

- **REQ-7.12**: 세금계산서 발행 기준 금액은 `platform_fee_amount`(플랫폼 수수료)와 그에 대한 VAT를 기준으로 하며, PG 수수료는 플랫폼이 공급하는 용역이 아닌 경우 분리 표기(또는 미포함) 규칙을 명시해야 한다(본 SRS 기본: 플랫폼 수수료만 과세 대상).

### 7.5 확정 이후 환불/차지백 회계처리 (원장 불변)

- **REQ-7.13**: `COMPLETED` 이후 발생한 환불/차지백은 기존 `settlement_items`를 수정하지 않고 `adjustment_items`로만 차감 처리해야 한다.

- **REQ-7.14**: 조정 항목은 반드시 원천 증빙 식별자(`source_type/source_id`)를 포함해야 하며, 차지백은 `CHARGEBACK` 타입으로 고정한다.

- **REQ-7.15**: 조정이 적용된 payout에는 "조정 적용 내역(유형/금액/사유)"이 정산서에 필수로 포함되어야 한다.

### 7.6 절사 정책 (Floor) 확정

- **REQ-7.16**: 절사(floor) 적용 단위는 "항목별(item-level)"로 고정한다. 즉, 수수료/세금은 항목별로 절사 후 합산하며, 총액에서 한 번 더 절사하는 방식은 금지한다.

- **REQ-7.17**: 절사 대상은 `platform_fee_amount`, `pg_fee_amount`, `vat_amount`이며, `net_amount`는 차감 결과로 자연스럽게 정수화된다.

- **REQ-7.18**: 절사 정책 변경은 과거 데이터에 소급 적용하지 않으며, 버전 문자열(`calc_version`, 예: `v1`)로 구분해 체크섬에 포함해야 한다.

### 7.7 정산서(Statement) 필수 필드

- **REQ-7.19**: 정산서에는 최소 아래 필드가 포함되어야 한다:
  `partner_id, partner_name, settlement_period_start, settlement_period_end, currency, item_count, total_gross_amount, total_platform_fee_amount, total_pg_fee_amount, total_vat_amount, total_net_amount, payout_id, payout_status, scheduled_at, completed_at, bank_account_last4, calc_version`.

- **REQ-7.20**: 정산서에는 조정 항목 요약이 필수다: `adjustment_count, adjustment_total_signed, adjustments_by_type`.

- **REQ-7.21**: 정산서의 모든 금액은 `BIGINT` 정수로 제공하고(원 단위), 표시 레이어에서만 천단위 구분을 적용한다.

---

## 8. 파트너 경험 요구사항

### 8.1 정산 조회 화면 필수 표시 필드

- **REQ-8.01**: 파트너 정산 목록 화면은 최소 컬럼을 표시해야 한다: `정산기간(period)`, `상태(status)`, `총매출(total_gross_amount)`, `플랫폼수수료(total_platform_fee_amount)`, `PG수수료(total_pg_fee_amount)`, `부가세(total_vat_amount)`, `정산금(total_net_amount)`, `지급예정(scheduled_at)`, `지급완료(completed_at)`.

- **REQ-8.02**: 정산 상세 화면은 항목 레벨로 drill-down 가능해야 하며, 항목별 필드 최소 셋: `source_type`, `source_id`, `gross_amount`, `platform_fee_rate/amount`, `pg_fee_rate/amount`, `vat_rate/amount`, `net_amount`, `status`, `hold_reason_code`, `failure_reason_code`.

- **REQ-8.03**: `calc_checksum`은 UI에 기본 노출하지 않되, 분쟁/지원 목적의 "고급 정보(Advanced)" 영역에서 조회 가능해야 한다.

- **REQ-8.04**: 파트너가 다운로드한 정산서와 화면 표시값은 동일한 집계 기준(REQ-7.16 item-level floor)을 사용해야 한다.

### 8.2 상태별 안내 메시지 (고정 문구 + 변수)

- **REQ-8.05**: 상태 메시지는 아래 템플릿으로 고정하고, `{}` 변수만 치환한다:
  - `PENDING`: "정산 데이터를 확인 중입니다. 완료 예정: {eta}"
  - `HOLD`: "정산이 보류되었습니다. 사유: {hold_reason_code}. 조치 필요: {action_required}"
  - `READY`: "정산이 확정되었습니다. 지급 예정: {scheduled_at}"
  - `PROCESSING`: "지급 처리 중입니다. 처리 시작: {processing_started_at}"
  - `COMPLETED`: "지급이 완료되었습니다. 지급일시: {completed_at} / 금액: {total_net_amount}원"
  - `FAILED`: "지급 처리에 실패했습니다. 사유: {failure_reason_code}. 다음 재시도: {next_retry_at}"
  - `CANCELED`: "정산이 취소되었습니다. 사유: {cancel_reason}"

- **REQ-8.06**: `HOLD`와 `FAILED`는 반드시 "지원센터 문의 링크"와 "이의제기 접수 버튼"을 포함해야 한다.

- **REQ-8.07**: `FAILED`에서 `retryable=false`인 경우 메시지 템플릿은 다음으로 바꿔야 한다: "자동 재시도가 중단되었습니다. 사유: {failure_reason_code}. 조치가 필요합니다: {action_required}"

### 8.3 알림 트리거 (Notification Triggers)

- **REQ-8.08**: 알림은 최소 채널 2개(Email + In-app)를 지원해야 하며, 트리거는 아래 이벤트에서 발생해야 한다:
  `READY 확정`, `payout_started`, `COMPLETED 지급완료`, `FAILED 실패`, `HOLD 보류`, `adjustment_items 생성(차감/가산)`.

- **REQ-8.09**: 각 알림 payload는 최소 필드를 포함해야 한다: `partner_id, payout_id, settlement_period, status, total_net_amount, scheduled_at/next_retry_at, reason_code, deep_link_url`.

- **REQ-8.10**: 알림은 이벤트당 1회만 발송되어야 하며, 중복 발송 방지를 위해 알림에도 멱등키를 적용해야 한다(예: `notif:{event_type}:{entity_id}:{version}`).

### 8.4 이의제기 워크플로 (단계 + SLA)

- **REQ-8.11**: 이의제기(dispute) 상태는 최소 아래 6단계를 지원해야 한다: `SUBMITTED`, `ACKED`, `UNDER_REVIEW`, `NEED_INFO`, `RESOLVED_ACCEPTED`, `RESOLVED_REJECTED`.

- **REQ-8.12**: 단계별 SLA를 고정한다:
  - `SUBMITTED -> ACKED`: 1영업일 이내
  - `UNDER_REVIEW` 최종 결론: 5영업일 이내
  - `NEED_INFO`에서 파트너 응답 유예: 7일(캘린더일) — 미응답 시 자동 종결(`RESOLVED_REJECTED`) 가능

- **REQ-8.13**: 이의제기 결론이 "인용(accepted)"이면 재정산은 원장 수정이 아니라 `adjustment_items` 생성으로만 수행해야 한다(REQ-5.3.21).

- **REQ-8.14**: 이의제기에는 반드시 대상이 연결되어야 한다: `payout_id` 또는 `settlement_item_id` 중 하나는 필수.

### 8.5 정산서 다운로드 (필수 컬럼, 포맷)

- **REQ-8.15**: 정산서 다운로드는 최소 CSV를 지원해야 하며, 인코딩은 `UTF-8`로 제공한다. 컬럼은 REQ-7.19의 필수 필드를 모두 포함해야 한다.

- **REQ-8.16**: 항목 상세 다운로드(라인아이템)는 별도 파일로 제공해야 하며, 최소 컬럼:
  `settlement_item_id, source_type, source_id, status, gross_amount, platform_fee_rate, platform_fee_amount, pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount, hold_reason_code, failure_reason_code`.

- **REQ-8.17**: 다운로드 파일에는 "산식 버전(calc_version)"과 "생성 시각(generated_at)"을 헤더 메타로 포함해야 한다(첫 줄 주석 또는 별도 요약 시트).

### 8.6 지급 실패 대응 플로우 (계좌 오류/재지급)

- **REQ-8.18**: 지급 실패가 `INVALID_BANK_ACCOUNT`인 경우, 화면에서 계좌 수정 UI로 바로 이동시키고, 계좌 수정 완료 후 "재지급 요청" 버튼을 노출해야 한다.

- **REQ-8.19**: 재지급 요청은 멱등이어야 하며, 요청 시 `payout_request_idempotency_key`를 생성/저장하고 중복 클릭 시 기존 요청 결과를 반환해야 한다.

- **REQ-8.20**: 재지급은 기존 payout를 수정하지 않고 "동일 payout에 대해 `payout_transfers` 새 attempt를 append"로 고정한다(REQ-5.3.14).

- **REQ-8.21**: 파트너가 계좌를 수정한 경우에도 이미 생성된 `payouts.bank_account_snapshot`은 바뀌지 않으므로, 재지급 시에는 "새 스냅샷을 사용하는 transfer attempt"를 생성해야 하며, 어떤 스냅샷으로 보냈는지 파트너 화면에 표시해야 한다(`account_last4`, `bank_code`).

---

## 부록: 향후 고려사항

- 정산/지급/조정 전반을 단일 "원장 엔트리(ledger_entries)"로 일반화하려면(대규모 확장), 현 스키마 위에 별도 엔트리 테이블을 추가하는 설계로 재검토 필요.
- 법적 문구(약관/환불정책/통지 템플릿)는 운영 정책 변경 가능성이 높아 "템플릿 버전 관리"가 필요해지면 별도 템플릿 테이블로 분리 권장.
