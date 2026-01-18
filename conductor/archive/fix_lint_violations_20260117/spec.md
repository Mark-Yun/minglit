# 린트 위반 사항 수정 및 디자인 시스템 적용 명세서 (Spec)

## 목표
새로 추가된 커스텀 린트 규칙(`no_hardcoded_padding`, `no_hardcoded_colors`, `no_hardcoded_text_style`, `use_minglit_progress_indicator`)을 준수하도록 전체 codebase를 수정합니다. 이를 통해 프로젝트의 UI 일관성을 확보하고 디자인 시스템(Design Tokens) 사용을 강제합니다.

## 수정 가이드라인

### 1. 패딩 및 간격 (Spacing)
- `16.0` -> `MinglitSpacing.medium`
- `8.0` -> `MinglitSpacing.small`
- `4.0` -> `MinglitSpacing.tiny`
- `24.0` -> `MinglitSpacing.large`
- `32.0` -> `MinglitSpacing.xlarge`
- `EdgeInsets.all(16)` -> `EdgeInsets.all(MinglitSpacing.medium)`

### 2. 색상 (Colors)
- `Colors.white` -> `theme.colorScheme.surface` 또는 `Colors.white` (필수적인 경우 디자인 토큰 사용)
- `Colors.grey` -> `theme.colorScheme.outline`
- `Color(0xFF...)` -> `MinglitColors` 또는 `theme.colorScheme`에서 적절한 색상 선택

### 3. 텍스트 스타일 (TextStyle)
- `TextStyle(fontSize: 14, ...)` -> `theme.textTheme.bodyMedium?.copyWith(...)`
- `TextStyle(fontWeight: FontWeight.bold)` -> `theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)`

### 4. 로딩 인디케이터 (Progress Indicator)
- `CircularProgressIndicator()` -> `MinglitCircularProgressIndicator()`
- `LinearProgressIndicator()` -> `MinglitLinearProgressIndicator()`

## 대상 파일 우선순위
1. `apps/app_user/lib/src/features/` (유저 대면 UI)
2. `apps/app_partner/lib/src/features/` (파트너 대면 UI)
3. `shared/packages/minglit_kit/` (공용 위젯 - 여기는 디자인 토큰 정의부이므로 주의해서 수정)
