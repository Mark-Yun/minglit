# Specification: User Action-Based Recommendation System

## 1. 개요 (Overview)
유저의 행동(View, Like, Dislike, Purchase)을 분석하여 개인화된 파티 추천을 제공하는 시스템을 구축합니다. 파티 정보를 벡터화하여 저장하고, 유저의 실시간 액션에 따라 유저 프로필 임베딩을 비동기적으로 업데이트하여 최적의 큐레이션을 제공합니다.

## 2. 기능적 요구사항 (Functional Requirements)

### 2.1 파티 데이터 벡터화 (Party Embedding)
- **대상:** 생성된 모든 파티 및 이벤트.
- **데이터 구성:** 제목, 상세 설명, 태그, 카테고리, 시간 정보를 포함한 JSON 객체.
- **저장소:** `party_embeddings` 테이블 (1:1 관계).
- **처리:** 파티 생성/수정 시 OpenAI Embedding API(`text-embedding-3-small` 등)를 통해 벡터를 생성하고 `pgvector` 컬럼에 저장.

### 2.2 유저 액션 기록 및 큐잉 (Action Logging & Queuing)
- **로그 기록:** `user_actions` 테이블에 유저의 액션(view, like, dislike, purchase) 기록.
- **비동기 큐:** DB 트리거를 통해 PGMQ(Postgres Message Queue)에 '임베딩 업데이트 작업'을 삽입.
- **가중치 정책:**
    - View: +1
    - Like: +3
    - Purchase: +5
    - Dislike: -3 (벡터 감산 처리)

### 2.3 유저 프로필 업데이트 (Profile Vector Update)
- **컴퓨트:** Supabase Edge Function에서 PGMQ의 메시지를 컨슈밍.
- **저장소:** `user_embeddings` 테이블 (1:1 관계).
- **알고리즘:** Strategy 패턴을 적용한 `HybridCalculator` 구현.
    - 이동 평균(Moving Average)과 누적 가중치 방식을 혼합하여 최신 트렌드와 장기 취향을 동시에 반영.
    - 새로운 액션 벡터를 가중치에 따라 기존 유저 프로필 벡터(`user_embeddings.embedding`)에 가산/감산 후 정규화(Normalization).

### 2.4 개인화 큐레이션 (Personalized Curation)
- **로직:** 유저의 프로필 벡터와 파티 벡터 간의 코사인 유사도(Cosine Similarity)를 계산.
- **노출:** 유사도가 높은 이벤트를 우선적으로 노출하는 API/함수 제공.

## 3. 비기능적 요구사항 (Non-Functional Requirements)
- **안정성:** PGMQ를 통한 재시도 메커니즘으로 외부 API 장애 시 데이터 유실 방지.
- **유연성:** Strategy 패턴을 통해 향후 추천 알고리즘(예: 감쇠율 조정) 교체가 용이하도록 설계.
- **성능:** `pgvector` 인덱스(HNSW 등)를 활용하여 대규모 데이터에서도 빠른 유사도 검색 보장.

## 4. 수락 기준 (Acceptance Criteria)
- [ ] 파티 생성 시 임베딩이 정상적으로 생성되어 `party_embeddings` 테이블에 저장되는가?
- [ ] 유저 액션 발생 시 PGMQ에 메시지가 생성되고 Edge Function이 이를 처리하는가?
- [ ] 액션 가중치에 따라 `user_embeddings` 테이블의 임베딩 값이 수학적으로 올바르게 업데이트되는가?
- [ ] 추천 쿼리 실행 시 유저의 최근 관심사가 반영된 결과가 상단에 노출되는가?

## 5. 범위 제외 (Out of Scope)
- 유저 간의 협업 필터링(Collaborative Filtering) - 본 스택은 콘텐츠 기반 필터링에 집중함.
- 실시간 실황 기반 추천 (예: 현재 인원수 기반 실시간 순위).
