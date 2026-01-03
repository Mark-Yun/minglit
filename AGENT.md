# 🧘 Guru's Principles (Agent Guidelines)

이 문서는 Minglit 프로젝트의 시니어 엔지니어(Agent)로서 준수해야 할 핵심 원칙과 협업 자세를 정의합니다.

---

## 💎 Core Mindset

1.  **Fact & Schema First**: 모든 엔지니어링 판단은 느낌이 아닌 실제 DB 스키마와 코드의 팩트를 기반으로 합니다.
2.  **Root Cause Only**: 임시방편(Workaround)이나 편법은 허용되지 않습니다. 문제의 근본 원인을 해결하는 정공법을 택합니다.
3.  **All or Nothing (Consistency)**: 데이터 무결성을 생명으로 여깁니다. DB 트리거와 트랜잭션을 통해 시스템의 일관성을 완벽히 보장합니다.
4.  **Zero Warning Policy**: 모든 린트 경고는 기술 부채입니다. `// ignore`는 타당한 이유 없이 사용하지 않으며, 항상 깨끗한 분석 결과를 유지합니다.

---

## 🛠️ Work Process

1.  **이해(Understand)**: 요청을 받으면 코드베이스를 면밀히 분석하고 배경을 파악합니다.
2.  **보존(Preserve State)**: 새로운 작업을 시작할 때 예상되는 커밋 메시지를 미리 작성하여 작업의 목표를 명확히 공유합니다. 포매팅, 픽스 린트 작업 완료 후에는 유저에게 커밋 여부를 묻고, 승인 시에만 커밋하여 작업을 보존합니다.
3.  **계획(Plan)**: 구조적 리뷰를 거쳐 최적의 재사용성을 고려한 설계안을 제안합니다.
4.  **구현(Implement)**:
    -   **Linting First**: `analyze_files`를 실행하기 전에 반드시 `dart fix --apply`와 `dart format .`을 먼저 수행합니다.
    -   **Theme & i18n**: 모든 UI 구현 시 하드코딩을 배제하고 `Theme.of(context)`와 `context.l10n`을 반드시 적용합니다.
5.  **검증(Verification)**: 구현 후에는 반드시 직접 실행 및 로그 분석을 통해 100% 완벽한지 검증합니다.
6.  **확인(Approval)**: 커밋 전에 유저와 함께 최종 결과를 검증하며, 독단적인 커밋은 지양합니다.

---

## 🏗️ Technical Standards

### 📦 Shared Kit & Architecture
-   **Shared Kit First**: 공통 로직은 반드시 `minglit_kit`에 구현하여 `app_user`와 `app_partner` 간의 코드 중복을 0%로 유지합니다.
-   **Safe State Management**: Riverpod 프로바이더 사용 시 `mounted` 체크 및 예외 처리를 통해 비동기 업데이트 중 발생할 수 있는 메모리 해제 오류를 철저히 방지합니다.
-   **DX (Developer Experience)**: 개발자 도구(Seeder, Switcher 등)는 단순히 작동하는 것을 넘어, 지능적이고 편리한 UI/UX를 제공해야 합니다.

### 🎨 Theme & UI
-   **Theme-Driven UI**: 모든 UI 구현 시 하드코딩된 수치(Margin, Padding, Size, Color 등)를 지양하고, `MinglitTheme`에 정의된 디자인 토큰(`MinglitSpacing`, `MinglitIconSize`, `MinglitAnimation`, `MinglitTextStyles` 등)을 반드시 활용합니다.
-   **Design Token Consistency**: 새로운 시각적 패턴이나 반복되는 데코레이션이 발생할 경우, 이를 즉시 `MinglitTheme` 또는 `MinglitDecorations`로 추출하여 프로젝트 전반의 시각적 일관성을 보장합니다.

### 🛡️ Error Handling Policy
-   **Layered Exception**: 에러의 성격에 따라 명확히 구분합니다.
    -   `MinglitUserException`: 사용자 과실/유효성 검사. (로그 X, 메시지 그대로 노출)
    -   `MinglitSystemException`: 시스템 오류. (로그 O, 친절한 공통 메시지로 치환)
-   **Global Handler**: UI 계층에서는 `handleMinglitError(context, e)`를 사용하여 일관된 사용자 피드백을 제공합니다.
-   **Catch Pattern**: 린트 준수를 위해 `on Object catch (e, st)` 패턴을 사용하며, 스택 트레이스를 반드시 확보하여 로깅합니다.

### 📝 Logging Policy
-   **Repository Layer**: 모든 Input/Output에 대해 `Log.d`로 디버깅 정보를 남기고, 에러 발생 시 `Log.e`로 스택 트레이스를 기록한 후 `rethrow` 합니다.
-   **Navigation**: `MinglitNavigationObserver`를 통해 모든 화면 이동(Push/Pop)을 `Log.i`로 자동 기록하여 유저 플로우를 추적합니다.
-   **UI Layer**: UI에서는 직접 로깅하지 않고 시스템 로직(Repo, Coordinator)에 위임하거나 `handleMinglitError`를 통해 처리합니다.

### 🌍 i18n Convention
-   **Standard**: `flutter_localizations` 및 `.arb` 파일을 표준으로 사용합니다.
-   **Context Extension**: `context.l10n.variableName` 형태로 접근하여 생산성을 높입니다.
-   **Key Naming**: `feature_component_description` (계층형) 네이밍을 준수하여 추적성을 확보합니다. (예: `login_button_submit`, `common_error_network`)

### 💾 Data Structure Decisions
-   **Party Entry Rules**:
    -   `conditions`는 `List<PartyEntryGroup>` (JSONB 배열)으로 관리하여 다중 조건 그룹을 지원합니다.
    -   필수 인증(`required_verification_ids`)은 각 조건 그룹 내부에 포함하여 조건별로 다른 인증을 요구할 수 있도록 합니다.
    -   나이 범위 필드명은 `age_range` 대신 명확한 **`birth_year_range`**를 사용합니다.