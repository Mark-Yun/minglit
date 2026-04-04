# [PM] Minglit 제품 요구사항 정의서 (Product Requirement Document)

**문서 상태:** [초안 / 검토 중 / 승인됨]
**담당 PM:** {{author}} | **버전:** 1.0.0
**핵심 전략:** #WorkingBackwards #HypothesisDriven #JTBD #Identity_vs_Qualification

---

## 1. 가상 보도자료 (Press Release - Amazon "Working Backwards")
*Amazon의 제품 개발 철학인 '고객으로부터 시작하여 거꾸로 작업하기'를 적용합니다. 제품이 성공적으로 출시된 미래의 시점에서 고객에게 보낼 메시지를 작성합니다. 기술적 디테일보다 고객이 얻게 될 '감정적 이득'과 '가시적인 성과'에 집중하십시오. 특히 Minglit의 핵심 가치인 '신뢰(Trust)'와 '안전한 연결'이 이 기능을 통해 어떻게 증폭되었는지 명시해야 합니다. 이는 팀 전체가 동일한 북극성(North Star)을 바라보게 만드는 가장 강력한 도구입니다.*

> **[출시일: 202X년 X월 X일]** "오늘 Minglit은 [기능명]을 통해 사용자들이 [해결된 문제]를 더 이상 겪지 않고 [얻게 된 이득]을 누릴 수 있게 되었음을 발표합니다. 이제 우리 고객들은 [경험의 변화]를 통해 이전과는 다른 수준의 [가치 및 신뢰]를 체감하게 될 것입니다..."

---

## 2. 가설 기반 문제 정의 및 신뢰 레이어 설계 (Hypothesis & Trust Layer)
*SVPG의 Marty Cagan이 강조하는 'Product Discovery' 원칙을 적용합니다. 우리는 단순히 기능을 만드는 것이 아니라 가설을 검증합니다. 데이터 기반의 관측값(Observation)을 근거로 제시하여 주관적 판단을 배제하십시오. 추가로 Minglit 아키텍처 가이드(Section 5)에 따라, 이 기능이 어떤 신뢰 레이어(Trust Layer)에 속하는지 명확히 정의해야 합니다.*

- **관측된 문제 (The Pain):** 어떤 정량적/정성적 데이터가 이 문제의 심각성을 증명하는가?
- **핵심 가설 (The Hypothesis):** "우리는 [A]라는 기능이 사용자의 [B] 문제를 해결하여 [C]라는 지표를 변화시킬 것이라고 믿는다."
- **신뢰 레이어 매핑 (Trust Journey):** 
  - **Layer 1 (Identity):** 실존 인물 확인(나이/성별) 단계에서의 개입인가?
  - **Layer 2 (Qualification):** 파트너의 추가 심사(직장/학력 등) 단계에서의 개입인가?

---

## 3. 잡 스토리 및 심층 ICP 분석 (Jobs-to-be-Done & ICP)
*사용자를 인구통계학적으로 나누는 것을 넘어, 그들이 처한 '상황'과 '해결하고자 하는 과업'에 집중합니다. Clay Christensen의 JTBD 이론에 따라 사용자가 이 기능을 '고용(Hire)'하는 이유를 기술하십시오. Airbnb가 강조하는 구체적인 사용자 세그먼트(ICP)를 설정하여 타겟팅의 날카로움을 더합니다.*

- **ICP (대상 사용자 상세):** (예: 처음으로 오프라인 파티를 주최하려는 파트너 앱 사용자)
- **Job Story:** "[상황]에서 나는 [동기]를 위해 [결과]를 얻고 싶다. 왜냐하면 [근본적인 욕구] 때문이다."

---

## 4. 성공 지표, 가드레일 및 도메인 이벤트 (Metrics & Domain Probes)
*Google의 성과 측정 프레임워크를 적용합니다. 성공을 정의하는 '북극성 지표'뿐만 아니라, 이 기능이 다른 핵심 경험을 해치지 않는지 감시하는 '가드레일 지표'를 반드시 설정하십시오. 측정 불가한 목표는 목표가 아닙니다. 엔지니어링 팀이 이 지표를 추적할 수 있도록 'Domain Probe(비즈니스 이벤트 로깅)'의 대상을 명시하십시오.*

- **North Star Metric:** (예: 심사 승인 완료율 15% 상승)
- **Counter-Metrics (Guardrails):** (예: 고객 지원 문의량 증가, 심사 대기 시간 지연 등)
- **정의할 도메인 이벤트 (Domain Probes):** 비즈니스 관점에서 추적해야 할 핵심 액션 (예: `verificationStarted`, `submissionApproved`).

---

## 5. 핵심 요구사항 및 비목표 (Requirements & Non-Goals)
*P0(필수)부터 P2(장기)까지 우선순위를 엄격히 구분합니다. 특히 Google의 'Non-Goals' 관행에 따라, 이번 프로젝트에서 의도적으로 '하지 않을 일'을 명시하십시오. 이는 개발 범위의 확산(Scope Creep)을 막고 팀의 가용 리소스를 가장 임팩트 있는 곳에 집중시키는 핵심 전략입니다.*

---

## 6. 참고 문헌 및 방법론 근거
1. **Ian McAllister (Amazon):** "Working Backwards: The PR/FAQ Process".
2. **Marty Cagan (SVPG):** "Inspired: How to Create Tech Products Customers Love".
3. **Minglit Architecture Guide:** Section 5 (Trust & Verification Architecture).
4. **Minglit Engineering Principles:** Section 1 (Domain-Oriented Observability).
