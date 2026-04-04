# [Arch] 전략적 기술 설계 및 아키텍처 결정 기록서 (Tech Spec & ADR)

**문서 번호:** ADR {{id}} | **제목:** {{title}}
**상태:** [Proposed / Accepted / Superseded]
**담당 설계자:** {{author}}
**핵심 원칙:** #TradeOffAnalysis #ADR #SagaPattern #DomainProbes

---

## 1. 배경 및 제약 사항 (Context & Constraints)
*기술 설계의 시작은 '왜'와 '제약'을 이해하는 것입니다. ThoughtWorks의 ADR 철학에 따라, 현재 우리가 직면한 한계와 비즈니스 요구사항을 명확히 정의하십시오. Minglit은 Supabase, Deno Edge, Postgres 18 환경에서 동작하며 Riverpod 3.0과 GoRouter를 사용합니다. 이러한 제약 조건이 설계의 방향을 결정합니다.*

- **문제 배경 (The Problem):**
- **기술적/사업적 제약 (Constraints):** 기존 레거시 호환성, 플랫폼 제약 등.

---

## 2. 아키텍처 결정 및 트레이드오프 (The Decision & Trade-offs)
*가장 중요한 섹션입니다. 마틴 파울러는 "아키텍처는 트레이드오프의 예술"이라고 말했습니다. 선택한 기술이나 패턴이 주는 '이득'뿐만 아니라 '대가(Cost)'를 명확히 기술하십시오. 대안들과 비교하여 왜 이 선택이 최선이었는지 논리적으로 증명하십시오. "이게 더 좋아서"가 아니라 "이러한 단점에도 불구하고 이 장점이 현재 우리에게 더 필요하기 때문"이라는 서술이 필요합니다.*

- **최종 결정:**
- **포기한 대안 (Alternatives):** 
- **트레이드오프 분석:** 확장성을 위해 일관성을 타협했는가? 운영 복잡도를 감수하고 성능을 선택했는가?

---

## 3. 분산 트랜잭션 및 상세 설계 (Saga & Detailed Design)
*C4 모델링 기법을 활용하여 시스템의 추상화 수준을 나누어 설명합니다. 특히 Minglit 엔지니어링 원칙(Section 2)에 따라, 여러 데이터 소스에 걸친 작업은 반드시 Saga 패턴을 적용해야 합니다.*

- **Saga 단계 및 Pivot 정의:** 작업의 '되돌릴 수 없는 지점(Pivot)' 명시.
- **보상 트랜잭션 (Compensating Transaction):** 실패 시 각 단계를 어떻게 되돌릴(Rollback) 것인가? 재시도는 멱등성을 보장하는가?
- **Repository Split:** 레포지토리가 거대해질 경우 `mixin`과 `part` 패턴을 사용하여 쿼리/커맨드를 분리했는가? (가이드 6.3)

---

## 4. 운영 우수성 및 안정성 (Operational Excellence - AWS Framework)
*AWS Well-Architected Framework를 적용합니다. 배포 후 시스템이 어떻게 모니터링되고 장애에 대응할지 설계 단계에서 고려(Design for Failure)하십시오.*

- **에러 분류 및 백오프:** Transient 에러 발생 시 지수 백오프(Exponential Backoff)와 지터(Jitter) 적용 전략 (원칙 3.1).
- **관측 가능성 (Domain Probes):** 도메인 로직 내에 로깅 프레임워크를 직접 노출하지 않고 `Domain Probe` 인터페이스로 캡슐화했는가? (원칙 1.1)

---

## 5. 참고 문헌 및 방법론 근거
1. **Michael Nygard:** "Documenting Architecture Decisions (ADR)".
2. **AWS:** "Well-Architected Framework - Operational Excellence".
3. **Minglit Engineering Principles:** Section 1 (Domain Probes), Section 2 (Saga), Section 3 (Resiliency).
