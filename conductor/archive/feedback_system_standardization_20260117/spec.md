# 명세서: UI/UX 피드백 시스템 표준화 (Minglit Feedback System)

## 1. 개요
Minglit 앱 전반의 성공, 정보, 경고, 에러 메시지 및 사용자 컨펌 절차를 표준화합니다. 하드코딩된 `ScaffoldMessenger`와 `showDialog` 호출을 제거하고, `minglit_kit`의 디자인 토큰이 적용된 통합 피드백 시스템을 구축하여 UI 일관성과 개발 생산성을 높입니다.

## 2. 주요 기능

### 2.1. 통합 피드백 컴포넌트 (`minglit_kit`)
- **MinglitSnackBar:** 하단에 잠시 나타나는 성공/정보 메시지용. (MinglitTheme 적용)
- **MinglitToast:** 화면 중앙/상단에 나타나는 짧은 알림용.
- **MinglitBanner:** 상단 고정형, 상태 해결 시까지 지속되는 알림용.
- **MinglitDialog:** 
    - **Alert:** 단순 정보 확인 및 에러 메시지 표시.
    - **Confirm:** "생성하시겠습니까?", "삭제하시겠습니까?" 등 사용자의 명시적 선택이 필요한 경우.

### 2.2. BuildContext Extension 메서드
- 의미 기반의 간결한 호출 방식 지원:
    - `context.showMinglitSuccess(message)`
    - `context.showMinglitInfo(message)`
    - `context.showMinglitWarning(message)`
    - `bool? confirmed = await context.showMinglitConfirm(title, message)`

### 2.3. 기존 시스템 통합
- `handleMinglitError` 리팩토링: 에러 발생 시 `MinglitDialog` 또는 `MinglitSnackBar`를 내부적으로 사용하도록 수정하여 UI 룩앤필 통일.

## 3. 마이그레이션 계획 (일괄 적용)
- `apps/app_user` 및 `apps/app_partner` 전체 소스 코드를 검색.
- 모든 `ScaffoldMessenger.of(context).showSnackBar(...)` 호출부를 새로운 확장 메서드로 교체.
- 기존 `showDialog`, `showCupertinoDialog` 등을 `context.showMinglitConfirm/Alert`로 교체.

## 4. 기술 요구사항
- **위치:** `shared/packages/minglit_kit/lib/src/ui/feedback/`
- **디자인 토큰:** `MinglitTheme`의 색상(Primary, Secondary, Surface), 간격(Spacing), 둥근 모서리(Radius)를 엄격히 준수.
- **비동기 처리:** 컨펌 다이얼로그의 경우 `Future<bool>` 반환을 보장하여 흐름 제어 지원.

## 5. 수락 기준 (Acceptance Criteria)
- [ ] `minglit_kit`에 표준 피드백 컴포넌트 4종(SnackBar, Toast, Banner, Dialog) 구현 완료.
- [ ] `BuildContext` 확장 메서드를 통한 호출이 정상 동작함.
- [ ] `handleMinglitError` 호출 시 새로운 디자인의 UI가 나타남.
- [ ] `app_user`, `app_partner` 내 기존 피드백 코드 100% 교체 완료 및 정상 동작 확인.
