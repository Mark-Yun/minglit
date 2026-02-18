# 명세서: pg_tap 도입 및 DB 통합 테스트 마이그레이션 (pg_tap Integration & DB Test Migration)

## 1. 개요
기존 Dart 기반의 백엔드 통합 테스트(`backend_integration`) 중 데이터베이스 내부 로직(스키마, 트리거, 함수, RLS) 검증 부분을 `pg_tap` 프레임워크로 교체합니다. 이를 통해 DB 로직을 SQL 환경 내에서 더 빠르고 정확하게 검증하며, CI/CD 파이프라인의 조기 검증 단계를 강화합니다.

## 2. 주요 기능

### 2.1. 인프라 구축
- **환경 설정:** 로컬 Supabase 환경에서 `pgtap` 확장을 활성화합니다.
- **구조 설계:** `supabase/tests` 디렉토리에 도메인별 SQL 테스트 파일(`.sql`)을 구성합니다.

### 2.2. 테스트 마이그레이션 (역할 분담)
기존 Dart 테스트의 기능을 다음과 같이 재배치합니다:
- **pg_tap (SQL):**
    - 테이블 스키마 및 인덱스 존재 여부 검증.
    - 트리거 실행 결과 (예: 신청 시 알림 생성, 상태 동기화).
    - RLS(Row Level Security) 정책 작동 여부.
    - PL/pgSQL 함수 및 RPC 로직.
- **Dart Test (Integration):**
    - Edge Function 호출 및 외부 서비스(FCM, Iamport) 연동 결과 검증.
    - 스토리지 파일 업로드 및 ACL 연동.

### 2.3. CI/CD 통합
- `supabase db reset` 직후 `supabase db test`를 실행하도록 워크플로우를 수정합니다.
- 테스트 실패 시 후속 단계를 중단하고 리포트를 제공합니다.

## 3. 기술 스택
- **Database:** PostgreSQL (`pg_tap` extension)
- **Tooling:** Supabase CLI (`supabase db test`)
- **CI/CD:** GitHub Actions

## 4. 수락 기준
- [ ] `supabase db test` 명령어로 모든 SQL 테스트가 통과한다.
- [ ] 기존 Dart 테스트 중 DB 전용 로직이 성공적으로 SQL 테스트로 옮겨졌다.
- [ ] CI 파이프라인에서 마이그레이션 후 테스트 자동 실행이 확인된다.
