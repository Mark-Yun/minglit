# 계획: 원샷 이벤트 신청 플로우 구현

## Phase 1: 데이터베이스 스키마 및 백엔드 로직 [checkpoint: 229a04e]
- [x] Task: 마이그레이션 파일 작성 (Schema Update)
    - [x] `event_applications` 테이블에 결제 관련 컬럼 추가 (`payment_id`, `payment_amount`, `refund_status`)
    - [x] `verification_submissions` 테이블에 `application_id` (FK) 컬럼 추가
- [x] Task: 자동화 트리거 로직 구현
    - [x] 심사 승인(`verification_submissions` -> `approved`) 시 연결된 `event_applications` 상태를 `approved`로 변경하는 트리거
    - [x] 신청 확정(`event_applications` -> `approved`) 시 `event_participants` 테이블에 티켓 발권 레코드를 자동 생성하는 트리거
- [x] Task: Conductor - 사용자 수동 검증 'Phase 1: 데이터베이스 스키마 및 백엔드 로직' (Protocol in workflow.md)

## Phase 2: 데이터 레이어 및 비즈니스 로직 (minglit_kit) [checkpoint: pending]
- [x] Task: 모델 업데이트
    - [x] `EventApplication`, `VerificationSubmission` 모델에 새로운 필드 반영 및 `freezed` 코드 생성
- [x] Task: 리포지토리 기능 구현
    - [x] `EventRepository.applyEvent` 메서드 구현 (원샷 트랜잭션 로직 포함)
- [x] Task: 코드 품질 강화 (Zero-Warning 루프)
    - [x] `dart fix`, `dart format`, `flutter analyze` 실행 및 모든 이슈 해결
- [x] Task: Conductor - 사용자 수동 검증 'Phase 2: 데이터 레이어 및 비즈니스 로직' (Protocol in workflow.md)

## Phase 3: 신청 위저드 UI 및 컨트롤러 (app_user) [checkpoint: fd67eff]
- [x] Task: EventApplicationController 구현
    - [x] 위저드 상태 관리 및 원샷 신청 로직 연동
- [x] Task: 신청 위저드 UI 구현 (전체 화면)
    - [x] 1단계: 인증 정보 확인/수정 섹션 (기존 정보 프리필)
    - [x] 2단계: 티켓 요약 및 Mock 결제 버튼
- [x] Task: 코드 품질 강화 (Zero-Warning 루프)
    - [x] `dart fix`, `dart format`, `flutter analyze` 실행 및 모든 이슈 해결
- [x] Task: Conductor - 사용자 수동 검증 'Phase 3: 신청 위저드 UI 및 컨트롤러' (Protocol in workflow.md)

## Phase 4: 통합 테스트 및 최종 검증
- [ ] Task: 엔드-투-엔드 흐름 테스트
    - [ ] 미인증 유저의 신규 신청 및 심사 대기 흐름 확인
    - [ ] 기인증 유저의 인증 단계 스킵 및 즉시 신청 흐름 확인
- [ ] Task: 최종 사용자 리뷰 및 승인
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 4: 통합 테스트 및 최종 검증' (Protocol in workflow.md)
