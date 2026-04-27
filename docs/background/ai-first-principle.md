# AI-First 운영 원칙

> minglit의 운영 구조는 인간 중심이 아닌 AI agent 중심. 이 문서는 그 원칙의 상세 + 적용 가이드.
> 모든 새 기능/프로세스/도구 결정 시 이 원칙에 부합하는지 점검.
> 상위 맥락: [`founding-story.md`](./founding-story.md) §AI-First 운영 원칙

## 핵심 원칙

### 1. 모든 운영을 AI 에이전트가 주도

- 코드 작성, 리뷰, 머지: AI 워커
- 정기 audit: AI 워커 (security, legal, uiux, architecture, qa)
- PM/TPM 리포트: AI 워커
- 의사결정 후속 (이슈 생성, PR, 알림): AI 워커
- **인간 (Mark)**: vision, 외부 자문, 결정 최종 승인 (특정 게이트)

### 2. AI가 production-ready 하려면 컨텍스트 필요

- **structured docs** (`docs/background/`): 도메인/페르소나/워크플로우/법령
- **knowledge graph** (`graphify-out/`): 코드 + docs 의 의미 그래프
- **prompt files** (`config/prompts/`): 워커별 역할/페르소나/work
- **history mirror** (`docs/reports/`): 과거 audit/exec 리포트로 패턴 학습

### 3. 인간 게이트는 명확히 정의

다음만 인간 (Mark) 승인 필요:
- 외부 자문 결정 (변호사, 세무사)
- 큰 비용 발생 결정 (vendor 계약, 인프라 변경)
- 법적 책임 결정 (약관 변경, 신고 절차)
- 새 워커 / 새 prompt 정의 (오케스트레이션)
- 그 외 — AI 워커가 자율적으로 처리

### 4. 도구 선택은 AI 친화적으로

- **CLI 강력 지원** (Axiom 선택 이유 중 하나)
- **API 우선** (vendor lock-in 회피, swap 가능)
- **무료 한도 ↑** (AI 워커 실험·반복 비용 ↓)
- **표준 protocol** (GitHub API, OAuth, REST)

### 5. AI 에이전트 결정 신뢰성 보장

- **5종 audit 워커**가 서로 cross-check (security/legal/uiux/qa/architecture)
- **이슈 → PR → CodeRabbit + 자체 리뷰 → admin merge** 다단계 게이트
- **runtime-qa 워커**가 사용자 시나리오 직접 실행 (단말 + ADB)
- **knowledge graph**로 변경 영향 트레이스 자동화

## 무엇이 가능한가

### 단기 (지금)

- 신규 기능 PR 생성 + 머지: AI 자율 (Mark 코드 안 봄)
- 정기 감사 보고: AI 자동 (#1744 같은 보안 감사가 자동 생성)
- 코드 리뷰: CodeRabbit + 자체 리뷰 워커
- 이슈 트리아지 + 분배: needs-* 라벨 라우팅 워커

### 중기 (2026 후반)

- 사용자 인터뷰 분석 자동화 (인터뷰 transcript → 페르소나/페인 업데이트)
- 마케팅 카피 생성 + A/B 테스트 (Statsig)
- 가격 정책 실험 자동화

### 장기 (2027+)

- AI 에이전트가 직접 신규 기능 기획·검증·배포 cycle 자율 운영
- Mark은 외부 (사용자, 법, 펀딩) 인터페이스만 담당

## 무엇을 안 하는가 (Anti-patterns)

- **인간이 코드 직접 작성** (Mark이 hands-on coding 하는 것은 anti-pattern — 그건 한 사람의 시간이 병목)
- **AI 결정을 인간이 매번 검토** (게이트는 명확히 정의, 그 외엔 AI 자율)
- **vendor lock-in** (단일 vendor에 의존하는 의사결정 — 어댑터 패턴 우선)
- **이메일/Slack에 흩어진 의사결정** (모든 결정은 GitHub + structured docs로)

## 이 원칙과 minglit 코드/구조의 매핑

| 원칙 | 코드/구조 |
|---|---|
| AI 워커 주도 | `minglit-worker-runtime/` 별도 repo |
| 컨텍스트 제공 | `docs/background/`, `docs/research/`, `graphify-out/` |
| 워커 역할 정의 | `config/prompts/{persona,role,policy,work}/` |
| 다단계 게이트 | GitHub PR + CodeRabbit + audit 워커 5종 |
| 어댑터 패턴 (lock-in 회피) | `supabase/functions/_shared/ai-adapter/`, PortOne 다중 PG |
| 사용자 시나리오 검증 | `runtime-qa-*` 워커 (ADB + Pixel/S24) |

자세한 vendor 선택 근거: [`external-services.md`](./external-services.md)
법적 게이트 적용 범위: [`legal-context.md`](./legal-context.md)

## 변경 시 영향

이 원칙을 바꾸면 minglit의 사업 구조 자체가 바뀜. 변경 트리거:
- AI 도구 비용 급등 (현재 어댑터로 대응)
- 법적 의무로 인간 승인 의무화 (예: AI 기본법 강제 영향)
- 사용자가 인간 운영자를 강하게 선호 시그널 (현재 가설 X)
