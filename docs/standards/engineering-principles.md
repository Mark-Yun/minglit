# Software Engineering Principles & Design Patterns Standard (v2.0)

**Description**: 본 문서는 Minglit 시스템의 장기적인 생존과 품질을 보장하기 위한 엔터프라이즈급 아키텍처 설계 및 범용 엔지니어링 정책을 정의합니다. 모든 시니어 엔지니어와 에이전트는 본 정책을 설계 및 리뷰의 절대적 기준으로 삼습니다.

**References**:
*   [Domain-Oriented Observability - Martin Fowler](https://martinfowler.com/articles/domain-oriented-observability.html)
*   [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
*   [Distributed Saga Pattern - Microsoft Azure](https://learn.microsoft.com/en-us/azure/architecture/patterns/saga)
*   [Google SRE: Testing for Reliability](https://sre.google/sre-book/testing-for-reliability/)
*   [Uber Engineering: Reliable Error Handling](https://www.uber.com/blog/reliable-and-scalable-error-handling/)

---

## 🚀 Section 1: 도메인 중심 관측성 정책 (Domain-Oriented Observability)

### [Rule 1.1] Encapsulation of Instrumentation (계측의 캡슐화)
*   **Policy**: 도메인 로직 내에서 로깅(`logger`), 메트릭(`metrics`), 분석 도구를 직접 호출하는 것을 엄격히 금지합니다. 모든 계측 로직은 **'Domain Probe'** 인터페이스 뒤로 추상화되어야 합니다.
*   **Rationale**: 비즈니스 로직의 가독성을 높이고, 기술적 세부 사항(예: 로깅 프레임워크 변경)이 핵심 도메인에 영향을 미치는 것을 차단합니다. 또한 테스트 시 실제 로그를 파싱하지 않고도 비즈니스 이벤트 발생 여부를 검증할 수 있습니다.
*   **Standard**: 기술적 용어(info, warn)가 아닌 도메인 용어(discountApplied, paymentFailed)를 메서드명으로 사용합니다.
*   **Audit Criteria**: 도메인 서비스 클래스에 외부 로깅 라이브러리 임포트가 포함되어 있는가? (발견 시 반려)

---

## 🏗️ Section 2: 분산 일관성 및 트랜잭션 정책 (Distributed Consistency)

### [Rule 2.1] Saga Pattern & Compensating Transactions (보상 트랜잭션)
*   **Policy**: 여러 마이크로서비스나 독립된 데이터베이스(Supabase, 외부 API)에 걸쳐 발생하는 모든 분산 작업은 반드시 **Saga 패턴**을 따라야 합니다. 실패 시 이전 단계의 작업을 취소하는 **'보상 트랜잭션(Compensating Transaction)'** 정의가 필수입니다.
*   **Implementation**: 
    1. **Pivot Step**: 작업의 '되돌릴 수 없는 지점'을 명시합니다. Pivot 이전 작업은 보상이 가능해야 하며, Pivot 이후 작업은 성공할 때까지 재시도(Retry) 가능해야 합니다.
    2. **Idempotency**: 모든 재시도 가능 작업은 반드시 멱등성(Idempotency)이 보장되어야 합니다.
*   **Audit Criteria**: 설계 문서나 코드 내에 각 단계별 실패 시 복구 전략(Rollback 로직)이 명시되어 있는가?

---

## ⚡ Section 3: 에러 핸들링 및 회복 탄력성 정책 (Error & Resiliency)

### [Rule 3.1] Error Classification & Backoff (에러 분류 및 백오프)
*   **Policy**: 모든 시스템 에러는 다음 세 가지로 분류되어야 합니다:
    1. **Fatal (비재시도)**: 4xx 클라이언트 에러, 권한 없음 등 (재시도 금지).
    2. **Transient (재시도 가능)**: 네트워크 타임아웃, 503 서비스 일시 불능 등.
    3. **Advisory (무시/로깅)**: 비즈니스 로직에 영향 없는 부수적 에러.
*   **Standard**: 재시도 시 반드시 **지수 백오프(Exponential Backoff)**와 **지터(Jitter)**를 적용하여 'Thundering Herd' 현상을 방지해야 합니다.
*   **Audit Criteria**: 재시도 로직이 고정된 간격(Constant Interval)으로 설정되어 있는가? 4xx 에러에 대해 재시도를 수행하는가?

---

## 🧪 Section 4: 신뢰성 테스트 정책 (Reliability Testing)

### [Rule 4.1] The Testing Pyramid & Automation (테스트 피라미드 준수)
*   **Policy**: 테스트 슈트는 구글 SRE 표준에 따라 다음 비율을 지향합니다: **Unit Tests (70%) / Integration Tests (20%) / E2E Tests (10%)**.
*   **Standard**:
    1. **Negative Testing**: 성공 케이스뿐만 아니라, 보상 트랜잭션이 작동하는 실패 시나리오를 반드시 테스트합니다.
    2. **Automation Gates**: 핵심 경로(Critical Path)의 코드는 테스트 커버리지가 하락할 경우 병합될 수 없습니다.
*   **Audit Criteria**: 신규 비즈니스 로직에 대한 유닛 테스트가 포함되었는가? 실패 시나리오(Edge cases)에 대한 검증이 있는가?

---

## ⚠️ Section 5: 안티패턴 및 코드 품질 (Anti-patterns)

### [Rule 5.1] YAGNI & Complexity Control
*   **Policy**: 미래의 확장성을 고려한 과도한 추상화보다 현재의 요구사항을 가장 단순하게 해결하는 코드를 우선합니다. 코드 복잡도(Cyclomatic Complexity)가 높은 메서드는 반드시 리팩토링 대상이 됩니다.
*   **Rule 5.2 Primitive Obsession**: 전화번호, 금액, 이메일 등을 단순 `string`이나 `int`로 다루지 마세요. 도메인 의미를 담은 **Value Object**를 사용하여 불변성과 유효성을 보장하십시오.

---

## 🛠️ 시니어 리뷰어 체크리스트 (Summary Checklist)

1.  [ ] **Observability**: 도메인 로직에서 기술적 계측 프레임워크가 격리되었는가?
2.  [ ] **Saga**: 실패 시 데이터를 복구할 보상 트랜잭션이 정의되었는가?
3.  [ ] **Resiliency**: 재시도 로직에 지수 백오프와 지터가 적용되었는가?
4.  [ ] **Identity**: 도메인 엔티티와 값 객체(Value Object)가 명확히 구분되었는가?
5.  [ ] **Testing**: 테스트 피라미드 비율을 준수하며 실패 케이스를 검증하는가?
