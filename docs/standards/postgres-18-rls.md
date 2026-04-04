# PostgreSQL 18 & RLS Performance Standard (v2.0)

**Description**: 본 문서는 PostgreSQL 18의 최신 엔진 튜닝, 다변량 통계를 이용한 쿼리 계획 최적화, 그리고 대규모 데이터 환경에서의 무중단 마이그레이션(Zero-downtime) 정책을 정의합니다. 모든 DB 엔지니어와 에이전트는 본 정책을 시스템 운용의 절대적 기준으로 삼습니다.

**References**:
*   [PostgreSQL 18: Asynchronous I/O Configuration](https://www.postgresql.org/docs/18/runtime-config-resource.html#GUC-IO-METHOD)
*   [PostgreSQL Docs: Multivariate Statistics (CREATE STATISTICS)](https://www.postgresql.org/docs/current/planner-stats.html)
*   [Supabase Blog: Zero-downtime Postgres Migrations](https://supabase.com/blog/zero-downtime-postgres-migrations)
*   [Use The Index Luke: Indexing for High Scale](https://use-the-index-luke.com)
*   [EDB: PostgreSQL Security & Hardening](https://www.enterprisedb.com/postgresql-security-best-practices)

---

## 🚀 Section 1: Postgres 18 엔진 및 AIO 최적화 정책 (Engine Tuning)

### [Rule 1.1] Asynchronous I/O (io_method) 활용
*   **Policy**: Linux 환경(현대적 커널)에서는 반드시 **`io_uring`**을 사용하여 컨텍스트 스위칭 오버헤드를 최소화해야 합니다. 지원되지 않는 환경에서는 `worker` 방식을 차선책으로 선택합니다.
*   **Standard**: 
    1. **`effective_io_concurrency`**: NVMe/SSD 환경에서는 200~500 사이로 설정하여 스토리지의 병렬 처리 능력을 극대화합니다.
    2. **`maintenance_io_concurrency`**: `VACUUM` 및 `CREATE INDEX` 가속을 위해 16 이상으로 설정합니다.
    3. **`backend_flush_after`**: 대량 쓰기 시 OS 페이지 캐시 스파이크를 방지하기 위해 512kB 수준으로 설정하여 트랜잭션 지연 지터(Jitter)를 줄입니다.
*   **Audit Criteria**: 고부하 I/O 작업 시 단일 워커에 병목이 발생하는가? 설정값이 하드웨어 성능과 일치하는가?

---

## 🧠 Section 2: 실행 계획 및 통계 관리 정책 (Query Planning)

### [Rule 2.1] Extended Statistics for RLS (다변량 통계 적용)
*   **Policy**: RLS 정책에서 복합 조건(예: `tenant_id` + `user_role`)을 빈번하게 사용할 경우, 반드시 **`CREATE STATISTICS`**를 통해 컬럼 간 종속성(Dependencies)과 다변량 최빈값(MCV) 정보를 옵티마이저에게 제공해야 합니다.
*   **Rationale**: Postgres의 기본 통계는 컬럼들이 서로 독립적이라고 가정합니다. `tenant_id`와 특정 상태값 간의 상관관계를 통계로 명시하지 않으면, 옵티마이저가 행 수를 과소평가하여 부적절한 실행 계획(Sequential Scan 등)을 세우게 됩니다.
*   **Audit Criteria**: 복합 RLS 필터가 적용된 쿼리에서 `EXPLAIN ANALYZE` 상의 예상 행 수(Rows)와 실제 행 수의 차이가 10배 이상 발생하는가?

---

## 🏗️ Section 3: 무중단 마이그레이션 정책 (Zero-downtime Migration)

### [Rule 3.1] Expand/Contract Pattern (확장/수축 패턴)
*   **Policy**: 1,000만 행 이상의 테이블에 대한 스키마 변경은 반드시 다음 4단계를 거쳐야 합니다.
    1. **Phase 1: Expand**: 신규 컬럼을 **Nullable**로 추가하고, 인덱스는 `CREATE INDEX CONCURRENTLY`를 사용하여 생성합니다. (Access Exclusive Lock 방지)
    2. **Phase 2: Migrate**: 트리거(Trigger)를 설정하여 신규 유입 데이터를 동기화하고, 기존 데이터는 배치(Batch) 단위로 백필(Backfill)합니다.
    3. **Phase 3: Switch**: 애플리케이션 코드를 수정하여 읽기/쓰기 지점을 신규 컬럼으로 전환합니다.
    4. **Phase 4: Contract**: 동기화 트리거를 제거하고 이전 컬럼을 삭제합니다.
*   **Audit Criteria**: 마이그레이션 중 테이블 전체에 `Access Exclusive` 락을 거는 작업이 포함되어 있는가? 대량 데이터 백필 시 WAL 세그먼트 폭주를 고려했는가?

---

## 🛠️ 시니어 리뷰어 체크리스트 (Summary Checklist)

1.  [ ] **AIO**: 스토리지 특성에 최적화된 `io_method`와 컨커런시 설정이 반영되었는가?
2.  [ ] **Statistics**: RLS 복합 필터 컬럼에 대해 `CREATE STATISTICS`가 정의되었는가?
3.  [ ] **Concurrency**: 모든 인덱스 생성이 `CONCURRENTLY` 키워드를 포함하는가?
4.  [ ] **Locking**: 1,000만 행 이상 테이블 변경 시 락 타임아웃(`lock_timeout`) 정책이 수립되었는가?
5.  [ ] **Backfill**: 마이그레이션 백필 작업이 트랜잭션당 1만~5만 행 사이의 배치로 설계되었는가?
6.  [ ] **Stability**: 모든 RLS 커스텀 함수가 `STABLE` 또는 `IMMUTABLE`로 마킹되었는가?
