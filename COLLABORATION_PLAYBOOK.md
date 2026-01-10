# 🤝 Minglit AI Collaboration Playbook

이 문서는 Minglit 프로젝트에서 인간 엔지니어와 AI 에이전트가 최상의 시너지를 내기 위해 준수해야 할 **협업 문화, 기술적 가치관, 그리고 엔지니어링 표준**을 정의합니다.

---

## 💎 핵심 가치 (Core Values)

### 1. 조합과 재사용 (Aggregation over Creation)
*   새로운 기능 구현 시 `minglit_kit`과 프로젝트 내 기존 위젯을 우선 탐색합니다.
*   구조가 같다면 코드를 복사하지 않고, 기존 위젯을 감싸는 **Wrapper 방식(Aggregation)**을 택하여 일관성을 유지합니다.

### 2. 역할의 분리 (Smart Controller, Dumb Widget)
*   **Widget**: 데이터가 있으면 그리고, 없으면 안 그리는 '순수한 표시' 역할에 집중합니다. 내부에 복잡한 Fallback 로직을 두지 않습니다.
*   **Controller**: 초기값 주입, 데이터 가공, 상태 관리를 전담합니다. 위젯이 필요로 하는 모든 데이터를 미리 준비해서 밀어넣어 줍니다.

### 3. 완벽한 코드 품질 (Zero-Warning Policy)
*   `dart analyze` 결과에 어떠한 에러, 경고, 정보(info)도 남기지 않습니다. 모든 린트 경고는 기술 부채로 간주합니다.
*   80자 줄 길이 제한, 캐스케이드 연산자(`..`) 사용 등 Dart의 idiomatic한 문법을 엄격히 준수합니다.

### 4. 직관적인 UX (Summary-to-Edit Flow)
*   상세 정보 화면의 섹션은 그 자체로 클릭 가능한 '버튼' 역할을 수행합니다.
*   섹션 클릭 시 별도의 수정 화면이나 바텀시트로 연결되어 즉시 편집할 수 있는 직관적인 흐름을 유지합니다.

---

## 🛠️ 작업 프로세스 (Work Process)

1.  **맥락 파악 (Context)**: 수정 요청 시 관련 위젯, 모델, 리포지토리를 모두 읽어 전체 데이터 흐름을 먼저 파악합니다. **Fact & Schema First** 원칙에 따라 실제 코드를 기반으로 판단합니다.
2.  **구조적 계획 (Planning)**: **`sequentialthinking` 도구**를 필수로 사용하여 문제를 단계별로 분석하고 논리적인 해결책을 설계합니다. 사용자에게는 Aggregation 전략이 포함된 계획을 제안하고 확인받습니다.
3.  **정교한 구현 (Implementation)**: 
    *   디자인 토큰(`MinglitSpacing`, `MinglitRadius` 등)을 철저히 사용합니다.
    *   아이콘 하나, 색상 하나도 전체 앱의 무드와 일치시키기 위해 고민합니다.
    *   **Linting First**: `analyze_files` 실행 전 반드시 `dart fix`와 `dart format`을 수행합니다.
4.  **검증 및 정사 (Verification)**: 구현 후 반드시 직접 실행 및 로그 분석을 통해 100% 완벽한지 검증합니다.
5.  **승인 후 커밋 (Approval & Commit)**: 모든 작업의 끝에는 사용자에게 최종 결과물을 보여주고, **명시적인 승인이 있을 때만** 커밋을 진행합니다.
6.  **기억 및 회고 (Memory)**: 작업이 완료되면 반드시 **`save_memory` 도구**를 사용하여 수행한 작업의 핵심 맥락, 결정된 아키텍처, 향후 참고할 사항을 장기 기억에 저장합니다.

---

## 🛡️ 기술 표준 (Technical Standards)

### 1. 에러 핸들링 (Error Handling)
*   사용자 과실(`MinglitUserException`)과 시스템 오류(`MinglitSystemException`)를 구분합니다.
*   UI 계층에서는 `handleMinglitError(context, e)`를 사용하여 일관된 사용자 피드백을 제공합니다.

### 2. 로깅 및 추적 (Logging)
*   리포지토리 레이어의 모든 I/O는 `Log.d`로 기록하며, 에러 발생 시 스택 트레이스를 포함하여 `Log.e`로 기록합니다.

### 3. 다국어 준수 (i18n)
*   모든 UI 문자열은 하드코딩하지 않고 `context.l10n`을 통해 `.arb` 파일을 참조합니다.

---

## 🎨 디자인 가이드라인 (UI/UX Mood)

*   **Full-Width Layout**: 섹션들은 좌우 여백 없이 화면에 꽉 차는 현대적인 리스트 스타일을 지향합니다.
*   **Subtle & Clean**: 강한 보더보다는 은은한 배경색(`surfaceContainerLowest`)과 그림자(`BoxShadow`)를 사용하여 영역을 구분합니다.
*   **Iconography**: 상세 정보에는 `primary` 색상의 작은 아이콘을 수직 정렬하여 가독성을 높입니다.

---

**"우리는 단순한 코딩 파트너를 넘어, 함께 제품의 가치를 빚어가는 팀입니다."**