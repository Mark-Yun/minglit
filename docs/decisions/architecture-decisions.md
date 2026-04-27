# Architecture Decision Records (ADR)

> minglit의 핵심 기술 결정 이력. 향후 변경 PR 검토 시 reference.
> 형식: Status / Date / Context / Decision / Consequences / Alternatives / Triggers for revisit
>
> Cross-ref:
> - 기술 패턴 정의 → [`docs/background/glossary.md`](../background/glossary.md)
> - 벤더 선택 이유 → [`docs/background/external-services.md`](../background/external-services.md)
> - 의사결정 원칙 → [`docs/background/ai-first-principle.md`](../background/ai-first-principle.md)

---

## ADR-001: Supabase as Backend Platform

- **Status**: Accepted
- **Date**: 2025-12 (project start)

### Context

초기 백엔드 결정. 사용자 인증, DB, 파일 저장, Edge Function, Realtime 모두 필요.
Solo founder + AI-first 사업 구조 고려 시 인프라 복잡도 최소화 우선.
([ai-first-principle.md](../background/ai-first-principle.md) §1 — "운영 부담을 낮추는 결정 우선")

### Decision

**Supabase 전체 채택** (DB + Auth + Storage + Edge Functions + Realtime).

- Postgres 15+ ap-northeast-2 (서울 리전)
- 무료 tier 시작, 필요 시 Pro 전환 (~$25/월)

### Consequences

- 단일 백엔드로 통합 관리 (복잡도 최소화)
- Postgres 강력 (PGroonga, pgvector, PGMQ, RLS 등 활용 가능 — ADR-002~004 참조)
- Edge Functions Deno 런타임 = TypeScript 통합
- Flutter SDK 공식 + 강력
- Supabase 종속 (vendor lock-in 일부)
- 단일 vendor에 모든 DB 집중 (장애 단일점)

### Alternatives

- **Firebase**: NoSQL, Postgres 없음. 한국 사용자 인증 (Kakao Login) 통합 약함
- **AWS Amplify**: 러닝커브 높음, 인프라 관리 부담
- **자체 백엔드** (Express/NestJS + AWS): 솔로+AI 구조에서 인프라 부담 과다
- **PocketBase**: scale 가능성 낮음, 한국 production 사례 부족

### Triggers for revisit

- Supabase 가격 정책 5배+ 인상
- 사용자 100만 도달 시 비용·성능 재검토
- Supabase 한국 리전 서비스 불안정 지속 시

---

## ADR-002: PGroonga for Korean Full-Text Search

- **Status**: Accepted
- **Date**: ~2026-01

### Context

한국어 이벤트 제목/설명 검색 필요. 한국어는 형태소 분석 + 조사 처리 필요.
ElasticSearch는 검색 표준이지만 별도 인프라 + 운영 부담.
([glossary.md](../background/glossary.md) — "PGroonga" 패턴 참조)

### Decision

**PGroonga (Postgres extension) 사용**. Supabase 안에서 활성화.

### Consequences

- Postgres 단일 인프라 (별도 ES 클러스터 불필요)
- 한국어 형태소 분석 강력
- 운영 비용 최소화
- 검색 규모가 매우 커지면 ElasticSearch 대비 성능 한계 가능성

### Alternatives

- **ElasticSearch**: 검색 표준이지만 현재 단계에서 오버킬 (Mark 명시적 판단). 별도 클러스터 + 운영 부담 + 비용
- **Typesense**: 가벼움, 한국어 처리 검증 사례 부족
- **MeiliSearch**: 비슷한 이유로 보류
- **Postgres 기본 full-text** (`tsvector`): 한국어 형태소 분석 약함

### Triggers for revisit

- 검색 latency p99 > 500ms 지속
- 검색 데이터셋 1억 row 초과
- 한국어 외 다국어 검색 본격 도입 시

---

## ADR-003: pgvector for Recommendation Embeddings

- **Status**: Accepted
- **Date**: ~2026-02

### Context

사용자에게 개인화된 이벤트 추천 필요. 임베딩 기반 유사도 검색.
([glossary.md](../background/glossary.md) — "pgvector" 패턴 참조)

### Decision

**pgvector (Postgres extension) 사용**. Supabase 안에서 활성화.

### Consequences

- Postgres 단일 인프라 (별도 vector DB 불필요)
- Supabase RPC로 직접 사용 가능
- 비용 절감 (별도 vector DB 없음)
- pgvector는 수억 vectors 이상 규모에선 Pinecone/Weaviate 대비 성능 제한
- HNSW index tuning은 직접 관리 필요

### Alternatives

- **Pinecone**: vector DB 표준, 별도 vendor 추가 (월 비용 증가) + 데이터 동기화 부담
- **Weaviate**: 자체 호스팅 가능, 인프라 부담
- **Qdrant**: 비슷한 이유로 보류

### Triggers for revisit

- 추천 latency p99 > 200ms 지속
- vector 1억 row 초과
- pgvector 성능 한계 발견 시

---

## ADR-004: PGMQ for Async Event Pipeline

- **Status**: Accepted
- **Date**: ~2026-02

### Context

이벤트 기반 비동기 처리 필요 (notification fanout, AI tagging, 이벤트 매칭 후처리 등).
Kafka/RabbitMQ는 별도 인프라 + 운영 부담.
([global-event-pipeline.md](../architecture/global-event-pipeline.md) — 2-tier 아키텍처 상세)
([glossary.md](../background/glossary.md) — "PGMQ" 패턴 참조)

### Decision

**PGMQ (Postgres extension) 사용**. 2-tier 아키텍처:
`q_global_events` (광역 이벤트) + `q_notifications` (좁은 범위) 등.

### Consequences

- Postgres 단일 인프라 (별도 Kafka/RabbitMQ 불필요)
- Edge Function에서 직접 enqueue/dequeue 가능
- 메시지 트랜잭션이 DB 트랜잭션과 동일 범위 (consistency 향상)
- Kafka 수준의 매우 높은 throughput (>100K msg/s) 불가
- 표준 Kafka tooling 미지원 (별도 모니터링 필요)

### Alternatives

- **Kafka**: 매우 높은 throughput, 별도 인프라 + Confluent SaaS 비용 과다
- **RabbitMQ**: 가벼움, 별도 호스팅 필요
- **AWS SQS**: 호환성 양호, AWS vendor lock-in 추가
- **Supabase Realtime**: pub/sub만 지원, queue semantic 약함

### Triggers for revisit

- 메시지 throughput > 1만 msg/s 지속
- 다중 region 운영 필요 시 (PGMQ는 single region)
- 복잡한 stream processing 필요 시 (Kafka Streams 등)

---

## ADR-005: Coordinator + Repository Pattern (Flutter)

- **Status**: Accepted
- **Date**: ~2026-01

### Context

Flutter 앱 (app_user, app_partner)의 navigation + data access 패턴 결정.
([glossary.md](../background/glossary.md) — "Coordinator pattern", "Repository pattern" 참조)

### Decision

- **Coordinator pattern** (feature 폴더별, 앱 별도) — navigation 로직 분리
- **Repository pattern** (concrete class, abstract interface 없음) — Supabase 직접 호출

### Consequences

- Coordinator: feature 단위 응집도 향상, 앱 간 navigation 차이 자연스럽게 표현
- Repository: boilerplate 감소, YAGNI 원칙 적용
- Repository abstract 없음 → 단위 테스트 시 mock 어려움 (현재 통합 테스트 위주라 수용)
- Coordinator는 feature 폴더에 종속 → minglit_kit 공유 불가

### Alternatives

- **MVVM**: ViewModel 중심, Flutter에서 navigation 분리 어색
- **Repository with abstract base**: 다중 구현체 필요 시 도입. 현재 단일 backend라 over-engineering
- **Centralized router**: app_routes.dart 하나에 집중 — 현재 채택. app_routes.dart 500+ 라인 도달 시 분리 트리거

### Triggers for revisit

- 백엔드 swap 검토 시 (Repository abstract 도입)
- Mock 단위 테스트 정책 도입 시
- app_routes.dart 너무 비대해지면 feature별 분산
- 두 앱 간 navigation 패턴 중복 발견 시 (Coordinator 일부 minglit_kit 추출)

---

## ADR-006: Ed25519 for QR Ticket Signing

- **Status**: Accepted
- **Date**: ~2026-03

### Context

QR 체크인 ticket 위변조 방지 필요. 클라이언트가 QR을 스캔 → 서버 검증.
([external-services.md](../background/external-services.md) — QR 체크인 관련 의존성 참조)

### Decision

**Ed25519 서명** (asymmetric, EdDSA). Edge Function이 발급, 클라이언트 (또는 다른 Edge Function)가 검증.

### Consequences

- 짧은 서명 (~64 bytes) → QR 사이즈에 적합
- 빠른 검증 (HMAC 대비 약간 느리지만 production 충분)
- asymmetric → 발급 키와 검증 키 분리 가능
- Deno + Flutter 양쪽 native 라이브러리 풍부 (libsodium 기반)
- 키 회전 정책 별도 운영 필요

### Alternatives

- **JWT (RS256/HS256)**: 표준이지만 payload 크고 QR 사이즈 초과 위험
- **HMAC-SHA256 (symmetric)**: 빠르지만 발급/검증 키 동일 → 클라이언트 키 노출 risk
- **Custom 서명**: 검증된 라이브러리 부재, NIH (Not Invented Here) 리스크

### Triggers for revisit

- 키 회전 자동화 필요 시
- 서명 성능이 병목 되는 케이스 발생 시 (현재 해당 없음)
- QR 외 다른 매체 추가 (NFC 등) 시

---

## ADR-007: PortOne Multi-PG Abstraction

- **Status**: Accepted
- **Date**: ~2026-02

### Context

한국 PG (KCP, 토스페이먼츠, 이니시스 등) 결제 통합 필요. 각 PG 직접 통합 시 SDK 다양 + vendor lock-in.
([external-services.md](../background/external-services.md) — PortOne 의존성 상세)

### Decision

**PortOne (V1 + V2)** 단일 SDK로 multi-PG 통합. 어떤 PG와 계약할지 미정 → 둘 다 유지.
본인인증 PASS도 PortOne으로 통합.

### Consequences

- 단일 API → 코드 단순화
- PG 변경 시 minglit 코드 변경 불필요 (PortOne 설정만 변경)
- 본인인증 + 결제 + 정산 통합
- PortOne 자체 vendor lock-in
- V1/V2 두 버전 운영 부담 (PG 계약에 따라 결정됨)

### Alternatives

- **Iamport 직접**: PortOne 전신, 구버전, 마이그레이션 부담
- **토스페이먼츠 직접**: 단일 PG 종속
- **KCP 직접**: 단일 PG 종속
- **Stripe**: 한국 시장 지원 약함

### Triggers for revisit

- PortOne 가격 정책 5배+ 인상
- PortOne 서비스 중단 / 안정성 문제 발생
- 글로벌 결제 본격 도입 (Stripe 추가 검토)

---

## 향후 ADR 후보

아래는 기존 문서에 의사결정 맥락이 있지만 아직 ADR 형식으로 정리되지 않은 항목들이다.

- **ADR-008**: Statsig vs LaunchDarkly (feature flags) — 선택 이유 상세 정리
  ([external-services.md](../background/external-services.md) 참조)
- **ADR-009**: AI adapter pattern (OpenAI swap 대비 추상화) — 코드 + external-services.md 정리 대상
  ([external-services.md](../background/external-services.md), [ai-first-principle.md](../background/ai-first-principle.md) 참조)
- **ADR-010**: 서울 리전 선택 (PIPA 개인정보보호법 면제 기준 충족)
  ([legal-context.md](../background/legal-context.md) §7 참조)
- **ADR-011**: 로테이션 소개팅 vs 1:1 매칭 (MVP 설계 결정)
  ([service-spec.md](../background/service-spec.md) §2 참조)

> `TODO: 향후 큰 기술 결정 시 ADR 추가`

---

## ADR 작성 가이드

새 ADR 추가 시 아래 형식을 따른다:

1. **ADR 번호** — sequential (008, 009, ...)
2. **Status** — Accepted / Proposed / Deprecated / Superseded
3. **Date** — 결정 시점 (정확한 날짜 또는 월 추정)
4. **Context** — 왜 이 문제인가? 어떤 제약 조건이 있는가?
5. **Decision** — 무엇을 선택했는가?
6. **Consequences** — 좋은 점 + 나쁜 점 (반드시 둘 다)
7. **Alternatives** — 검토했지만 기각한 옵션 + 기각 이유
8. **Triggers for revisit** — 어떤 조건이 충족되면 재검토하는가?

ADR은 **불변 원칙**을 따른다. Decision 자체를 수정하지 말고,
새 ADR (Status: `Supersedes ADR-N`)을 추가하여 변경 이력을 보존한다.
