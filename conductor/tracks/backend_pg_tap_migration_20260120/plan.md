# 구현 계획: pg_tap 도입 및 DB 통합 테스트 마이그레이션

## Phase 1: 인프라 및 환경 설정
- [ ] Task: `pgtap` 확장 활성화
    - [ ] `backend/supabase/migrations`에 `pgtap` extension 생성 스크립트 추가 (dev only?).
    - [ ] `backend/supabase/config.toml` 확인 (test db config).
- [ ] Task: 테스트 디렉토리 구성
    - [ ] `backend/supabase/tests` 폴더 및 `database.spec.sql` (메인 엔트리) 생성.
    - [ ] `tests/test_helpers.sql` (공통 유틸리티) 생성.
- [ ] Task: CI/CD 파이프라인 수정 (`.github/workflows/ci.yml`)
    - [ ] `check-supabase` Job에 `supabase db start` (or `link`) 및 `supabase db test` 추가.
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: 도메인별 테스트 마이그레이션 (Part 1 - Core & Auth)
- [ ] Task: 유저/권한 테스트 (`02_users.sql`)
    - [ ] `tests/01_auth_test.sql` 작성 (RLS, Profile 트리거).
- [ ] Task: 파트너/장소 테스트 (`03_partners.sql`)
    - [ ] `tests/02_partner_test.sql` 작성.
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: 도메인별 테스트 마이그레이션 (Part 2 - Business Logic)
- [ ] Task: 이벤트/티켓 테스트 (`04_events.sql`)
    - [ ] `tests/03_event_test.sql` 작성 (재고 관리 트리거 등).
- [ ] Task: 결제/신청 테스트 (`05_commerce.sql`, `09_refund.sql`)
    - [ ] `tests/04_commerce_test.sql` 작성 (상태 동기화, 환불 트리거).
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: 클린업 및 마무리
- [ ] Task: 기존 Dart 테스트 코드 정리
    - [ ] `tests/backend_integration`에서 중복되는 DB 로직 테스트 제거.
- [ ] Task: 최종 통합 검증
    - [ ] CI 파이프라인 전체 성공 확인.
- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
