# 구현 계획: 유저 앱 구매 내역 구현 (User Purchase History)

## Phase 1: 데이터 모델 및 리포지토리 레이어
- [x] Task: `EventApplication` 모델 확장
    - [x] `Event`, `Ticket`, `Party` 정보를 포함하도록 모델 필드 및 JSON 직렬화 업데이트.
- [x] Task: `EventRepository`에 구매 내역 조회 메서드 추가
    - [x] `getMyPurchaseHistory()` 메서드 구현 (정렬 및 조인 쿼리 포함).
- [x] Task: 단위 테스트 작성 (Repository)
    - [x] `tests/backend_integration`에 구매 내역 조회 로직 검증 테스트 추가.
- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: 비즈니스 로직 (Riverpod)
- [x] Task: `PurchaseHistoryController` 구현
    - [x] 무한 스크롤 또는 단순 목록 조회를 위한 `AsyncNotifier` 생성.
- [x] Task: 단위 테스트 작성 (Logic)
    - [x] 컨트롤러의 상태 변화 및 에러 핸들링 검증.
- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: UI 구현 (app_user)
- [x] Task: `PurchaseHistoryScreen` UI 개발
    - [x] 디자인 토큰(`MinglitSpacing`, `MinglitRadius`)을 적용한 리스트 및 카드 구현.
    - [x] 상태별 배지(Badge) 및 액션 버튼(환불, 영수증 등) 배치.
- [x] Task: 마이페이지(My Page) 진입점 추가
    - [x] 마이페이지 메뉴에 '구매 내역' 항목 추가 및 라우팅 연동.
- [x] Task: UI 통합 테스트 작성
    - [x] `app_user` 내 위젯 테스트를 통해 화면 렌더링 및 네비게이션 검증.
- [x] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: 폴리싱 및 마무리
- [x] Task: Zero-Warning 린트 및 빌드 검증
    - [x] `flutter analyze` 및 각 플랫폼별 빌드 테스트 수행.
- [x] Task: 최종 수동 검증
    - [x] 실제 구매 프로세스 진행 후 내역 화면에서 데이터 일치 여부 확인.
- [x] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
