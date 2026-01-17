# 커스텀 린트 규칙 구현 명세서 (Spec)

## 목표
UI 일관성과 디자인 토큰 사용을 강제하기 위한 커스텀 린트 패키지(`minglit_lints`)를 구현합니다.
이번 트랙에서는 다음 두 가지 규칙을 구현합니다:
1.  **하드코딩 패딩 금지 규칙**: Padding 위젯에 숫자를 직접 입력하는 것을 방지합니다.
2.  **공용 인디케이터 강제 규칙**: 기본 Progress Indicator 대신 공용 위젯 사용을 유도합니다.

## 배경 (Context)
- **Architecture as Code**: 자동화된 코드 분석을 통해 UI/UX 일관성을 유지합니다.
- **Tools**: `custom_lint`와 `analyzer` 패키지를 사용합니다.
- **Location**: `shared/packages/minglit_lints`에 패키지를 생성합니다.

## 상세 규칙 (Detailed Rules)

### 1. No Hardcoded Padding (`no_hardcoded_padding`)
- **설명**: 패딩 값은 숫자 리터럴 대신 디자인 토큰(예: `MinglitSpacing`)을 사용해야 합니다.
- **대상**: `Padding` 위젯 (및 `EdgeInsets` 생성자).
- **검사 로직**: `double` 리터럴(예: `16.0`)이나 `int` 리터럴이 패딩 속성에 직접 사용되었는지 감지합니다.
- **심각도**: **Warning**
- **메시지**: "Please use design tokens (e.g., MinglitSpacing) instead of hardcoded numeric values."

### 2. Use Common Progress Indicator (`use_minglit_progress_indicator`)
- **설명**: 로딩 인디케이터의 일관성을 위해 공용 위젯 사용을 강제합니다.
- **대상**: `CircularProgressIndicator`, `LinearProgressIndicator`.
- **심각도**: **Warning**
- **메시지**: "Please use the shared widget (e.g., MinglitCircularProgressIndicator) instead of the default ProgressIndicator."

## 구현 단계 (Implementation Steps)

### 1. 패키지 구조 설정
```text
minglit_workspace/
└── shared/packages/
    └── minglit_lints/
        ├── lib/
        │   ├── minglit_lints.dart
        │   └── src/
        │       ├── no_hardcoded_padding_rule.dart
        │       └── use_minglit_progress_indicator_rule.dart
        ├── pubspec.yaml
        └── tools/analyzer_plugin/bin/plugin.dart
```

### 2. 로직 구현 (Logic Implementation)
- **`NoHardcodedPaddingRule`**: `Padding` 또는 `EdgeInsets`의 `InstanceCreationExpression`을 방문하여 인자가 리터럴인지 확인합니다.
- **`UseMinglitProgressIndicatorRule`**: `InstanceCreationExpression`을 방문하여 금지된 타입(`CircularProgressIndicator`, `LinearProgressIndicator`)인지 확인합니다.

### 3. 통합 (Integration)
- `apps/app_user`와 `apps/app_partner`의 `dev_dependency`에 `minglit_lints`를 추가합니다.
- `analysis_options.yaml`에서 플러그인을 활성화합니다.

## 범위 제외 (Out of Scope)
- 자동 수정(Quick Fixes) 기능은 이번 트랙에서 제외합니다.
- 기타 아키텍처 규칙(Repository 명명 등)은 추후 트랙으로 미룹니다.
