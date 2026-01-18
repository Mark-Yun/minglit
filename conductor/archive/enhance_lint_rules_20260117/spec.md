# 린트 규칙 강화 명세서 (Spec)

## 목표
디자인 시스템(Design Tokens)의 철저한 준수를 위해 `minglit_lints` 패키지에 색상과 텍스트 스타일 관련 규칙을 추가합니다.

## 상세 규칙 (Detailed Rules)

### 1. No Hardcoded Colors (`no_hardcoded_colors`)
- **설명**: 색상 리터럴(`Color(...)`)이나 머티리얼 기본 색상(`Colors.red` 등)의 직접 사용을 금지합니다.
- **대상**:
  - `Color` 생성자 호출.
  - `Colors` 클래스의 정적 멤버 접근 (예: `Colors.red`, `Colors.blue`).
- **예외**: `MinglitColors` 등 디자인 토큰 클래스 내부에서의 사용은 허용해야 할 수도 있으나, 일단 앱 코드 전반에 적용합니다. (필요시 ignore 주석 사용 유도)
- **메시지**: "Avoid hardcoded colors. Use `MinglitTheme` or design tokens instead."
- **심각도**: **Warning**

### 2. No Hardcoded TextStyle (`no_hardcoded_text_style`)
- **설명**: `TextStyle` 생성자를 직접 호출하여 스타일을 정의하는 것을 금지합니다.
- **대상**: `TextStyle` 생성자 호출.
- **권장**: `Theme.of(context).textTheme` 또는 `MinglitTextTheme` 사용.
- **메시지**: "Avoid hardcoded TextStyle. Use `Theme.of(context).textTheme` or design tokens."
- **심각도**: **Warning**

## 구현 위치
- `shared/packages/minglit_lints/lib/src/`

## 통합
- 기존 `minglit_lints` 플러그인 엔트리포인트에 새 규칙 등록.
