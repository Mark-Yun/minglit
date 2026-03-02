# 계획: 파일 관리 및 보안 접근 시스템

## Phase 1: 데이터베이스 스키마 및 트리거
- [ ] Task: `minglit_files`, `file_access_grants` 테이블 생성 마이그레이션 작성.
- [ ] Task: `storage.objects` -> `minglit_files` 동기화 Trigger Function 작성.
- [ ] Task: RLS 정책 작성 (파일 소유자 및 권한 보유자 접근 허용).

## Phase 2: 권한 부여 로직 구현
- [ ] Task: `EventRepository` 수정 - 파티 신청 시 관련 파일에 대해 파트너에게 권한 부여(`file_access_grants` insert).
- [ ] Task: `PartnerRepository` 수정 - 파일 조회(`getSignedUrl`) 시 권한 체크 로직 검증.

## Phase 3: 테스트 및 검증
- [ ] Task: 파일 업로드 후 `minglit_files` 자동 생성 확인.
- [ ] Task: 권한 없는 계정으로 파일 조회 시도 (실패 확인).
- [ ] Task: 권한 만료 테스트.
