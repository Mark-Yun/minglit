# Supabase Platform & Infrastructure Standard (v2.0)

**Description**: 본 문서는 Supabase 통합 인프라를 활용한 엔터프라이즈급 백엔드 설계, 시스템 신뢰성 보장, 그리고 다중 테넌트(Multi-tenancy) 환경에서의 데이터 격리 정책을 정의합니다. 모든 백엔드 엔지니어와 에이전트는 본 정책을 설계의 절대적 기준으로 삼습니다.

**References**:
*   [Supabase Database Webhooks: Event-Driven Guide](https://supabase.com/docs/guides/database/webhooks)
*   [Supabase Edge Functions: Resource & Performance Limits](https://supabase.com/docs/guides/functions/limits)
*   [Supabase Auth: Multi-tenancy Architecture Patterns](https://supabase.com/docs/guides/auth/multi-tenancy)
*   [Stripe Engineering: Asynchronous Event Reliability](https://stripe.com/docs/webhooks/best-practices)
*   [AWS S3: Scalable Storage Isolation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)

---

## 🚀 Section 1: 데이터 일관성 및 이벤트 신뢰성 정책 (Event Reliability)

### [Rule 1.1] Transactional Outbox Pattern (트랜잭션 아웃박스)
*   **Policy**: 데이터베이스 변경과 외부 시스템(에지 함수, 타 API) 알림은 반드시 단일 트랜잭션 내에서 원자성(Atomicity)을 보장해야 합니다.
*   **Implementation**: 
    1. 비즈니스 로직 수행 시 별도의 `outbox_events` 테이블에 이벤트 데이터를 함께 기록합니다.
    2. 데이터베이스 트리거 또는 CDC(Change Data Capture)를 통해 해당 테이블의 변경분을 감지하고 에지 함수를 호출합니다.
*   **Rationale**: 직접적인 API 호출 방식은 네트워크 장애 시 데이터는 변경되었으나 알림이 유실되는 '분산 데이터 불일치' 문제를 야기합니다. 아웃박스 패턴은 시스템 장애 시에도 최소 1회 전달(At-least-once delivery)을 보장합니다.
*   **Audit Criteria**: 핵심 도메인 변경 시 에지 함수를 직접 호출(Invoke)하는 로직이 있는가? (발견 시 트리거 기반 아웃박스 패턴으로 변경 권고)

---

## ⚡ Section 2: 에지 함수 자원 및 성능 정책 (Edge Function Optimization)

### [Rule 2.1] Memory-Aware Execution (메모리 인식 실행)
*   **Policy**: 모든 에지 함수는 **최대 256MB**의 메모리 제한 내에서 동작하도록 설계되어야 합니다. 대용량 데이터 처리 시 메모리 피크를 유발하는 전체 로드(Bulk load)를 엄격히 금지합니다.
*   **Standard**: 
    1. 외부 리소스(DB, API) 호출 시 반드시 페이지네이션(Pagination)을 적용합니다.
    2. 대용량 응답은 `ReadableStream`을 사용하여 청크 단위로 처리함으로써 메모리 점유율을 일정하게 유지합니다.
*   **Audit Criteria**: 함수 내에서 대량의 배열을 한 번에 메모리에 올리는 로직이 있는가? `await Promise.all()`의 병렬 개수가 제한(Throttle)되어 있는가?

### [Rule 2.2] Cold Start Mitigation (콜드 스타트 완화)
*   **Policy**: 함수의 부팅 속도를 높이기 위해 종속성을 최소화하고, 전역 스코프에서 무거운 연산을 수행하지 않습니다.
*   **Standard**: DB 연결 설정과 같은 무거운 초기화 로직은 핸들러 외부의 전역 싱글톤으로 관리하여 Warm Start 성능을 극대화합니다.

---

## 🔐 Section 3: 다중 테넌트 및 데이터 격리 정책 (Multi-tenant Isolation)

### [Rule 3.1] ID-based Row-Level Isolation
*   **Policy**: Minglit은 **ID 기반 격리(Row-Level Isolation)** 방식을 표준으로 채택합니다. 모든 테이블은 반드시 `tenant_id` (또는 `org_id`) 컬럼을 포함해야 하며, 이를 기반으로 하는 RLS 정책이 수반되어야 합니다.
*   **Standard**:
    1. **Strict Filter**: 모든 정책은 `USING (tenant_id = (SELECT auth.tenant_id()))`와 같이 명시적인 격리 조건을 포함해야 합니다.
    2. **Cross-tenant Prevention**: 테넌트 간 데이터 이동은 반드시 명시적인 승인 워크플로우를 거쳐야 하며, 단순 쿼리로 가능해서는 안 됩니다.
*   **Audit Criteria**: 새 테이블 생성 시 `tenant_id` 컬럼과 연동된 RLS 정책이 누락되었는가? (발견 시 Critical Issue로 분류)

---

## 🛠️ 시니어 리뷰어 체크리스트 (Summary Checklist)

1.  [ ] **Consistency**: 데이터 변경과 연동된 이벤트 발송이 아웃박스 패턴으로 보호되는가?
2.  [ ] **Memory**: 에지 함수가 스트리밍이나 페이지네이션을 통해 256MB 메모리 한계 내에서 작동하는가?
3.  [ ] **Isolation**: 모든 신규 테이블에 테넌트 격리를 위한 `tenant_id`와 RLS 정책이 적용되었는가?
4.  [ ] **Retention**: 업로드된 파일의 수명 주기와 스토리지 RLS 정책이 정의되었는가?
5.  [ ] **Verification**: 외부 유입 이벤트(웹훅)에 대한 서명 검증 로직이 포함되었는가?
