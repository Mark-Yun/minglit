# 계획: UI/UX 피드백 시스템 표준화 (Minglit Feedback System)

## Phase 1: 컴포넌트 및 확장 메서드 구현 (`minglit_kit`) [checkpoint: 0960650]
- [x] Task: `MinglitSnackBar` 및 `MinglitToast` 위젯 구현 (0960650)
    - [x] `minglit_kit`에 디자인 토큰을 적용한 스낵바/토스트 UI 작성.
- [x] Task: `MinglitDialog` (Alert/Confirm) 및 `MinglitBanner` 구현 (0960650)
    - [x] 확인/취소 버튼이 포함된 표준 다이얼로그 및 지속형 배너 UI 작성.
- [x] Task: `BuildContext` Extension 구현 (0960650)
    - [x] `showMinglitSuccess`, `showMinglitInfo`, `showMinglitWarning`, `showMinglitConfirm` 메서드 작성 및 위젯 연동.
- [x] Task: `handleMinglitError` 리팩토링 (0960650)
    - [x] 기존 에러 핸들러가 새로운 `MinglitDialog` 또는 `MinglitSnackBar`를 사용하도록 수정.
- [x] Task: Conductor - 사용자 수동 검증 'Phase 1: 컴포넌트 동작 확인' (Protocol in workflow.md) (0960650)

## Phase 2: 일괄 마이그레이션 (`app_partner`) [checkpoint: 0960650]
- [x] Task: `app_partner` 내 `ScaffoldMessenger` 호출부 전수 조사 및 교체 (0960650)
- [x] Task: `app_partner` 내 `showDialog` 호출부 전수 조사 및 교체 (0960650)
- [x] Task: Conductor - 사용자 수동 검증 'Phase 2: 파트너 앱 UI 확인' (Protocol in workflow.md) (0960650)

## Phase 3: 일괄 마이그레이션 (`app_user`) [checkpoint: 0960650]
- [x] Task: `app_user` 내 `ScaffoldMessenger` 호출부 전수 조사 및 교체 (0960650)
- [x] Task: `app_user` 내 `showDialog` 호출부 전수 조사 및 교체 (0960650)
- [x] Task: Conductor - 사용자 수동 검증 'Phase 3: 유저 앱 UI 확인' (Protocol in workflow.md) (0960650)
