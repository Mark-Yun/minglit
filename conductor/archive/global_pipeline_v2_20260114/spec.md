# Specification: Global Event Pipeline v2 (Robustness & Observability)

## 1. 개요 (Overview)
기존 이벤트 파이프라인(v1)에 안정성과 관측 가능성을 더하여 프로덕션 레벨로 고도화합니다. 메시지 포맷을 표준화하고, 중복 처리 방지(Idempotency), 에러 격리(DLQ), 그리고 처리 지연 추적(Time Tracking) 기능을 구현합니다.

## 2. 기능적 요구사항 (Functional Requirements)

### 2.1 표준 메시지 포맷 (Standardized Payload)
모든 이벤트 메시지는 다음 포맷을 따릅니다:
```json
{
  "id": "uuid-trace-id",           // Trace ID (End-to-End 추적용)
  "type": "PARTY_CREATED",         // Event Type
  "meta": {
    "occurred_at": 1705234000,     // 발생 시각 (Unix Timestamp)
    "source": "parties_table",     // 출처 테이블
    "attempt": 1                   // 처리 시도 횟수
  },
  "actor": {                       // 행위자 정보
    "id": "user_uuid",
    "role": "host"
  },
  "payload": { ... }               // 실제 데이터 (Full Snapshot)
}
```

### 2.2 멱등성 보장 (Idempotency)
- **`processed_events` 테이블**: 처리 완료된 이벤트 ID를 기록합니다.
- **Worker 로직**: 메시지 처리 전 `processed_events`를 조회하여 이미 처리된 ID라면 무시(Skip)하고 큐에서 삭제합니다.

### 2.3 죽은 편지 보관함 (Dead Letter Queue - DLQ)
- **`dead_letter_queue` 테이블**: 처리에 실패한 악성 메시지를 보관합니다.
- **Retry 정책**: PGMQ의 `read_ct`(읽은 횟수)가 5회를 초과하면 DLQ 테이블로 이동시키고 큐에서 영구 삭제합니다.

### 2.4 시간 여행 기록 (Time Tracking)
- **Lag 모니터링**: `processed_at` (처리 시각) - `occurred_at` (발생 시각)을 계산하여 처리 지연 시간을 로그로 남깁니다.
- **Trace ID**: DB 트리거에서 생성된 ID가 Dispatcher를 거쳐 Worker 로그까지 유지되어야 합니다.

## 3. 기술적 요구사항 (Technical Requirements)
- **DB Migration**: `processed_events`, `dead_letter_queue` 테이블 생성 및 기존 트리거 함수 업데이트.
- **Edge Function**: `notification-worker`, `vector-worker` 로직에 멱등성 및 DLQ 체크 미들웨어/함수 적용.

## 4. 수락 기준 (Acceptance Criteria)
- [ ] DB 트리거가 표준화된 JSON 포맷으로 메시지를 생성하는가?
- [ ] 동일한 메시지가 두 번 들어왔을 때, Worker가 두 번째 메시지를 무시하는가?
- [ ] 5번 이상 실패한 메시지가 `dead_letter_queue` 테이블로 이동하는가?
- [ ] Worker 로그에 `Lag` (지연 시간) 정보가 출력되는가?
