# 명세서: SQL 스키마 리팩토링 및 도메인 기반 분리

## 1. 개요
현재 `20260114000001_schema.sql`에 모든 로직이 집중되어 있어 유지보수 및 AI 에이전트의 컨텍스트 파악이 어렵습니다. 이를 도메인(관심사)별로 분리하여 코드 가독성을 높이고 관리 효율성을 극대화합니다.

## 2. 목표 및 전략
- **관심사 분리 (Separation of Concerns):** 테이블, RLS 정책, 트리거를 기능적 도메인 단위로 그룹화하여 하나의 파일만 보고 해당 기능을 완벽히 이해할 수 있도록 함.
- **순차적 실행 보장:** 타임스탬프를 이용해 의존성 순서(Core -> Users -> Partners -> Events -> Commerce -> Pipeline)에 따른 마이그레이션 실행 보장.
- **베이스라인 초기화:** 기존의 모든 마이그레이션 파일을 제거하고 리팩토링된 파일들로 베이스라인을 재정립함.

## 3. 리팩토링 대상 및 파일 구조 (예시)
1.  **`01_core.sql`**: Extension, Enum 타입, 공용 헬퍼 함수.
2.  **`02_users.sql`**: `user_profiles`, `app_roles`, `user_embeddings`, `user_actions`.
3.  **`03_partners.sql`**: `partners`, `partner_settlements`, `locations`, `verifications`.
4.  **`04_events.sql`**: `parties`, `events`, `entry_groups`, `tickets`, `party_embeddings`.
5.  **`05_commerce.sql`**: `event_applications`, `verification_submissions`, `apply_event` RPC.
6.  **`06_system.sql`**: `processed_events`, `debug_logs`, `PGMQ` 관련 설정, `pg_cron` 작업.

## 4. 작업 기준 (Acceptance Criteria)
- [ ] 기존 모든 마이그레이션 파일 삭제.
- [ ] 새로운 도메인별 마이그레이션 파일 생성 (순차적 타임스탬프 적용).
- [ ] 각 파일 내에 관련 테이블, RLS, 트리거가 응집되어 있어야 함.
- [ ] `npx supabase db reset` 실행 시 에러 없이 최신 스키마가 완벽히 구성되어야 함.
- [ ] `minglit_db_test` (통합 테스트) 실행 시 모든 케이스가 통과해야 함 (회귀 테스트).

## 5. 주의 사항
- 파일 분리 시 테이블 간 FK 제약 조건 순서를 엄격히 준수해야 함 (부모 테이블이 먼저 생성되어야 함).
- `handle_updated_at` 같은 공용 함수는 `01_core.sql`에 정의하여 모든 도메인에서 참조할 수 있게 함.
