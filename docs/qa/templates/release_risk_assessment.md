# [QA] 위험 기반 품질 평가 및 릴리즈 리스크 보고서 (Release Risk Assessment)

**릴리즈 명:** {{release_id}} | **테스트 기간:** {{start_date}} ~ {{end_date}}
**담당 QA:** {{author}}
**품질 철학:** #RiskBasedTesting #TestingPyramid #NegativeTesting

---

## 1. 릴리즈 권고 및 잔존 리스크 요약 (Executive Summary & Residual Risk)
*QA의 역할은 '버그 제로'가 아닌 '리스크 가시화'입니다. ISTQB의 위험 기반 테스트(RBT) 원칙에 따라, 배포 전 남아있는 '잔존 리스크(Residual Risk)'를 투명하게 공개하고 비즈니스 관점의 Go/No-Go 판정을 내립니다. 의사결정권자가 배포 버튼을 누를 때 어떤 위험을 감수하는지 명확히 인지하게 만드십시오.*

- **최종 판정:** [🟢 Go / 🟡 Caution / 🔴 No-Go]
- **핵심 잔존 리스크:** 배포 후 발생 가능한 가장 큰 우려 사항 1~2가지.

---

## 2. 테스트 범위 및 누락 영역 (Scope & Dark Matter)
*우리가 무엇을 검증했는지보다 '무엇을 검증하지 못했는지'가 더 중요할 때가 있습니다. 환경적 제약, 시간 부족 등으로 인해 테스트가 누락된 영역(Dark Matter)을 명시하십시오. 이는 배포 후 모니터링 팀이 어디를 집중해서 봐야 할지 알려주는 이정표가 됩니다.*

- **검증 완료 (In-Scope):**
- **미검증 영역 (Out-of-Scope/Dark Matter):**

---

## 3. 핵심 시나리오 및 실패 케이스 검증 (Negative Testing & Saga Validation)
*Minglit 환경에서는 성공 케이스보다 '실패 시 복구'가 올바르게 작동하는지가 훨씬 중요합니다. 시스템 장애 상황을 의도적으로 발생시켜 복구 능력을 검증합니다.*

- **보상 트랜잭션 검증:** Saga 패턴의 각 단계에서 네트워크 타임아웃/실패를 유도했을 때, 이전 데이터가 안전하게 롤백되는가?
- **에러 재시도 로직:** 일시적(Transient) 에러 시 지수 백오프가 올바르게 작동하여 서버에 과부하를 주지 않는가?

---

## 4. 정량적 리스크 분석 및 품질 게이트 (Risk Matrix & Automation Gates)
*리스크를 객관화합니다. 각 이슈를 **발생 가능성(Likelihood)**과 **비즈니스 영향도(Impact)**의 곱으로 계산하십시오. 또한 Minglit의 테스트 피라미드 목표(Unit 70% / Integration 20% / E2E 10%)가 준수되었는지 확인합니다.*

> **Risk Score = Likelihood (1-5) × Impact (1-5)**

| 리스크 ID | 설명 | 가능성 | 영향도 | 점수 | 등급 | 완화 전략 (Workaround) |
|---|---|:---:|:---:|:---:|:---:|---|
| R-01 | (예: 타임아웃 시 롤백 실패 우려) | 2 | 5 | **10** | High | 타임아웃 로그 모니터링 강화 및 수동 복구 스크립트 대기 |

- **테스트 피라미드 달성률:** Unit (X%) / Integration (Y%) / E2E (Z%)
- **품질 게이트 상태:** Critical/Major 버그 해결 완료 여부.

---

## 5. 참고 문헌 및 방법론 근거
1. **ISTQB:** "Risk-Based Testing (RBT) Framework".
2. **Google SRE Book:** "Testing for Reliability".
3. **Minglit Engineering Principles:** Section 4 (Reliability Testing Policy).
