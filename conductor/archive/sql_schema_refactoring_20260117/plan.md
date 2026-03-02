# 계획: SQL 스키마 리팩토링 및 도메인 기반 분리

## Phase 1: 기존 마이그레이션 분석 및 해체 [checkpoint: pending]
- [x] Task: 기존 SQL 파일 내용 분석 및 백업
    - [x] `schema.sql`, `cron.sql`, `pipeline_v2.sql`, `rpc_apply_event.sql` 등의 내용을 도메인별로 분류하여 메모.
- [x] Task: 마이그레이션 파일 재생성 (리팩토링)
    - [x] `migrations/` 폴더 내 기존 파일 삭제.
    - [x] `20260117160000_core.sql` 작성 (Extensions, Enums, Utils).
    - [x] `20260117160001_users.sql` 작성 (Profiles, Roles, Embeddings).
    - [x] `20260117160002_partners.sql` 작성 (Partners, Locations, Verifications).
    - [x] `20260117160003_events.sql` 작성 (Parties, Events, Tickets).
    - [x] `20260117160004_commerce.sql` 작성 (Applications, Submissions, RPC).
    - [x] `20260117160005_system.sql` 작성 (Pipeline, Queues, Cron).
- [x] Task: Conductor - 사용자 수동 검증 'Phase 1: 기존 마이그레이션 분석 및 해체' (Protocol in workflow.md)

## Phase 2: 검증 및 안정화
- [ ] Task: 로컬 DB 리셋 및 스키마 적용
    - [ ] `npx supabase db reset` 실행하여 리팩토링된 마이그레이션 적용.
    - [ ] 에러 발생 시 파일 순서 및 의존성 수정.
- [ ] Task: 테스트 데이터 시딩
    - [ ] `tests/test_data_seeder` 실행하여 데이터 주입.
- [ ] Task: 회귀 테스트 실행 (Regression Test)
    - [ ] `tests/backend_integration`의 `apply_event_flow_test.dart` 실행.
    - [ ] **목표:** 모든 테스트가 `Green`이어야 함.
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 2: 검증 및 안정화' (Protocol in workflow.md)
