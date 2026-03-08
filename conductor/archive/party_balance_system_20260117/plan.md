# 계획: 파티 입장 성비 및 그룹 밸런스 자동 관리

## Phase 1: 백엔드 로직 및 DB 설계
- [ ] Task: DB 스키마 업데이트 (`parties` 테이블)
    - [ ] `balance_config` JSONB 컬럼 추가 및 마이그레이션 작성.
- [ ] Task: 밸런스 체크 PL/pgSQL 함수 구현
    - [ ] `check_party_balance(event_id, ticket_id)`: 현재 예매 수량을 조회하여 구매 가능 여부(Boolean) 및 사유 반환.
- [ ] Task: `apply_event` 트랜잭션 연동
    - [ ] 신청/결제 시점에 `check_party_balance`를 호출하여 밸런스가 깨지면 에러 발생(Rollback).
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 1: DB 및 로직 검증' (Protocol in workflow.md)

## Phase 2: 파트너 앱 (사장님 설정) 구현 (`app_partner`)
- [ ] Task: 파티 생성/수정 위저드 UI 수정
    - [ ] '모집 설정' 단계에 **"성비 균형 자동 관리"** 스위치 추가.
    - [ ] 스위치 상태를 `balance_config` 데이터로 변환하여 저장.
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 2: 설정 저장 확인' (Protocol in workflow.md)

## Phase 3: 유저 앱 (티켓 구매 UX) 구현 (`app_user`)
- [ ] Task: 티켓 목록 UI 개선
    - [ ] `EventRepository`에서 티켓 조회 시 밸런스 상태(Locked 여부)를 함께 가져오도록 수정.
    - [ ] Locked 된 티켓은 비활성화하고 "성비 조절 중" 문구 표시.
- [ ] Task: (옵션) 대기 알림 UI
    - [ ] Locked 티켓 클릭 시 "풀리면 알림 받기" 팝업 표시 (기능 구현은 Mock 또는 간단하게).
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 3: 구매 제한 테스트' (Protocol in workflow.md)
