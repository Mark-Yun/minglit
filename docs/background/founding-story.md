# Founding Story

> minglit이 무엇을 위해 존재하고, 왜 시작했고, 어떻게 운영되는지의 단일 진실.
> 다른 모든 docs (product-thesis, personas, partner-workflow, 등) 의 북극성.

## Mission

**인연을 찾아가는 통과 입구.**

minglit은 사람들이 자기에게 맞는 인연을 찾아 떠나는 여정의 시작점.
관문이자 통로, 목적지 아님 — 우리는 만남의 기회를 만들고, 매칭이 성공한 뒤에는 사용자가 우리 플랫폼을 떠나도 OK.

## 5-Year Vision

**5년 안에**:
- 한국 데이팅·소개팅 시장 **beat** (점유율 1위)
- **결정사 대체** — 결정사 사용자들이 minglit 플랫폼 위로 이동
- **200만 회원**

## 시작 배경 (Why minglit?)

### 개인 여정

설립자 Mark은 본인이 모든 만남 모델을 직접 사용해본 사용자:
- 소개팅 앱
- 데이팅 앱
- 결정사
- 로테이션 소개팅 (최근 핫해진)

### 시장 관찰

- **사회는 점점 개인화** — AI 발전 + 1인 가구 증가 + 자연스러운 만남 채널 약화
- **기존 만남 모델은 비효율적**:
  - 결정사: too much (비용 + 인증 + 결혼 압박)
  - 데이팅앱: too little (검증 X + 노이즈 ↑ + 가벼움)
  - 카페/인스타 모임: 신뢰 X
- **한국은 고신용 사회** — 신원·자격 검증을 신뢰하는 사회 풍토. 검증 없는 만남에 대한 거부감 ↑.

### Insight

**한국에 걸맞은 mid-market 만남 모델 필요**:
- 결정사 대비: **비용 + 인증 간소화**
- 데이팅앱 대비: **인증 + 비용 강화**

### Trigger

**로테이션 소개팅 / 미팅** 트렌드 (2024-2025) 가 시장 진입 모델로 적합. 규모(4:4-12:12) + 검증 메커닉 + 효율성이 minglit이 만들고 싶은 디지털 인프라와 자연스럽게 매핑됨. 이 이벤트 모델을 첫 GTM hook으로.

## AI-First 운영 원칙 (핵심 MOAT)

> minglit은 **인간 중심 사업 구조 X. AI agent 중심 사업 구조.**
> 이건 단순 "도구 활용"이 아닌 **사업 구조 자체의 차별화**.

### 무엇이 다른가

| 전통 스타트업 | minglit (AI-first) |
|---|---|
| 엔지니어 N명 채용 → 코드 작성 | AI 워커들이 코드 작성 (`minglit-worker-runtime`) |
| PM/UX/QA/Legal 팀 | 각 역할별 AI 페르소나 (audit-uiux, audit-legal, runtime-qa-tester 등) |
| Slack/회의로 의사결정 | AI 에이전트가 GitHub 이슈/PR 생성·리뷰·머지 |
| 신입 onboarding 1-2개월 | AI가 docs/background/ + graphify 그래프 읽고 즉시 활동 |

### 운영 메커니즘

1. **인프라 레이어** (Mark이 만들고 유지):
   - minglit-worker-runtime (워커 spawn / 스케줄 / 권한)
   - graphify 지식 그래프 (AI 메모리)
   - docs/background/ (AI 컨텍스트)
   - prompt files (AI 행동 정의)
2. **실행 레이어** (AI agent가 수행):
   - 코드 작성 + PR
   - Code review (CodeRabbit + 자체 워커)
   - 정기 audit (security, legal, uiux, architecture, qa)
   - PM/TPM 리포트
   - 운영 이슈 triage

### Mark의 역할

- **Vision + Product 방향 결정**
- **AI 오케스트레이션** (워커 정의, 프롬프트 튜닝, 인프라 발전)
- **외부 자문 결정** (변호사, 세무사 등 AI가 못 하는 영역)
- **사용자 인터뷰 / 시장 인사이트 수집**

### 왜 이게 가능한가

- **AI 코딩 능력 임계점 돌파** (2024-2025 Claude/GPT-4급 도구로 production code 가능)
- **Solo founder + AI = 작은 팀의 효율** (코디네이션 비용 ↓, 결정 속도 ↑)
- **knowledge graph + structured docs**로 AI 워커 production-ready

### 이게 가져다주는 경쟁우위 (MOAT)

1. **빠른 iteration** — 인간 팀 대비 50배 속도로 기능 개발/검증
2. **낮은 burn rate** — 팀 인건비 ↓ → runway 길어짐
3. **24/7 운영** — 워커가 자동 audit/QA/모니터링
4. **scaling 무제한** — 사용자 ↑ 시 워커 추가만 — 팀 hiring 없음

### Risk

- **AI 도구 의존 + cost 변동** → 어댑터 패턴 + multi-vendor 전략 ([external-services.md](./external-services.md) 참조)
- **AI 에이전트 결정 신뢰 ↓** → audit 워커 5종 + 사람(Mark) 최종 승인 게이트
- **법적 책임은 결국 사람** → 변호사 자문, 통신판매업 신고 등 외부 행정 항목

## 팀 + 단계

| 항목 | 상태 |
|---|---|
| **팀 규모** | Solo founder (Mark) + AI 워커 ~30종 |
| **시작 시점** | 2025년 12월 (개발 본격 시작) |
| **현재 단계** | MVP 개발 중 |
| **런칭 목표** | 2026년 7월 |
| **외부 도움** | (필요 시) 변호사 / 세무사 자문 |

## 이름의 의미: minglit

**mingle + it + (lit)**:
- **mingle** — 사람들이 자연스럽게 어울리다
- **it** — 그것 (만남, 인연)
- **(lit)** — 불붙은, 활기찬 (slang). 약속을 zest 있게 만든다는 의미

## 다른 docs와의 관계

이 문서는 다음의 북극성:
- [`product-thesis.md`](./product-thesis.md) — mid-market 포지셔닝 + 로테이션 소개팅 모델
- [`personas.md`](./personas.md) — Partner P-1/P-2, User U-1/U-2 페르소나
- [`partner-workflow.md`](./partner-workflow.md) — 12-step Partner 운영 흐름
- [`ai-first-principle.md`](./ai-first-principle.md) — AI-first 원칙 상세 (이 문서의 §AI-First 부분 확장)
- [`external-services.md`](./external-services.md) — vendor 선택 + 어댑터 패턴 (AI-first risk 대응)
- [`legal-context.md`](./legal-context.md) — 법적 의무 + 인간 게이트가 필요한 영역
