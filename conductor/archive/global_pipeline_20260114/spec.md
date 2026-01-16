# Specification: Global Event Pipeline & Hybrid Workers (v1.0)

## 1. 개요 (Overview)
Minglit의 모든 비즈니스 로직을 이벤트 중심으로 처리하기 위한 전역 이벤트 파이프라인을 구축합니다. DB 트리거를 활용한 효율적인 디스패칭과, 긴급도에 따른 하이브리드 워커(Long Polling/Batch) 시스템을 통해 시스템의 확장성과 안정성을 확보합니다.

## 2. 기능적 요구사항 (Functional Requirements)

### 2.1 멀티 큐 인프라 (Multi-Queue Setup)
- **q_global_events**: 모든 로우 데이터가 최초로 적재되는 1차 큐.
- **q_notifications**: 실시간 처리가 필요한 알림 및 인증 전용 2차 큐.
- **q_vectors**: 임베딩 및 통계 분석을 위한 배치 처리 전용 2차 큐.

### 2.2 DB 디스패처 (SQL Dispatcher)
- **로직**: `q_global_events`에 데이터 삽입 시 트리거 발동.
- **라우팅**: `event_routes` 테이블의 규칙에 따라 데이터를 분류하여 각 2차 큐로 복제(Fan-out).
- **데이터**: 변경된 데이터의 전체 스냅샷을 JSONB 형태로 포함.

### 2.3 하이브리드 워커 (Hybrid Workers)
- **Notification Worker (실시간)**: 
    - 5초 간격 고정 폴링, 최대 55초 실행(Wall Clock) 루프.
    - `q_notifications`의 메시지를 즉시 처리.
- **Vector Worker (효율)**: 
    - 1분 주기 배치 처리.
    - 최대 50개의 이벤트를 묶어서 OpenAI Embedding API 호출 및 처리.

### 2.4 추천 및 검색 (Personalization)
- **하이브리드 검색**: 10km 이내 거리 필터링 + 취향 벡터 코사인 유사도 정렬.
- **동적 가중치**: Click(0.1), Join(1.0), Negative Review(-1.0) 가중치를 반영한 벡터 연산.

## 3. 기술적 요구사항 (Technical Requirements)
- **Extensions**: `vector`, `postgis`, `pgmq`, `pg_cron`, `pg_net`.
- **Infrastructure as Code**: 모든 설정은 `supabase/migrations` 내 001, 002, 003 순번의 SQL 파일로 관리.
- **Edge Functions**: Deno 환경에서 Strategy 패턴을 적용한 워커 구현.

## 4. 수락 기준 (Acceptance Criteria)
- [ ] 파티 생성 시 `q_global_events`를 거쳐 `q_notifications`와 `q_vectors`로 데이터가 정상 분배되는가?
- [ ] `notification-worker`가 55초 루프 내에서 실시간으로 메시지를 처리하는가?
- [ ] `vector-worker`가 50개 단위로 배치를 묶어서 효율적으로 임베딩을 생성하는가?
- [ ] 모든 인프라 설정이 `supabase start` 명령어로 재현 가능한가?
