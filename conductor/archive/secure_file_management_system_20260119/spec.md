# 명세서: 파일 관리 및 보안 접근 시스템 (Secure File Management System)

## 1. 개요
Supabase Storage에 업로드되는 모든 파일(특히 유저 개인정보)을 `minglit_files` 테이블을 통해 중앙에서 관리하고, `file_access_grants` 테이블을 통해 세밀한 접근 제어(Expiration 포함)를 수행합니다. 파일 업로드 시 Database Trigger를 사용하여 메타데이터를 자동 생성함으로써 데이터 정합성을 보장합니다.

## 2. 주요 기능

### 2.1. 파일 메타데이터 관리 (`minglit_files`)
- **자동 동기화:** `storage.objects` 테이블에 INSERT가 발생하면 Trigger가 동작하여 `minglit_files`에 메타데이터(경로, 소유자, 타입, 크기 등)를 자동 생성.
- **삭제 동기화:** Storage에서 파일이 삭제되면 `minglit_files`에서도 상태 변경(`deleted`) 또는 삭제.

### 2.2. 접근 권한 관리 (`file_access_grants`)
- **권한 부여:** 유저가 파티 신청 시 파트너에게 특정 파일(증빙서류)에 대한 **기간 한정 조회 권한** 부여.
- **RLS 연동:** Storage RLS 정책에서 `file_access_grants` 테이블을 참조하여 권한이 있는 사용자만 파일 조회 허용.

### 2.3. 고아 파일 정리 (Batch Job)
- `minglit_files`에 기록되지 않은 Storage 파일이나, 만료된 권한 관련 파일들을 주기적으로 정리하는 기반 마련.

## 3. 데이터 모델

### `minglit_files`
- `id`: UUID (PK)
- `storage_object_id`: UUID (FK -> storage.objects)
- `bucket_id`: text
- `file_path`: text
- `owner_id`: UUID (FK -> users)
- `created_at`: timestamptz

### `file_access_grants`
- `id`: UUID (PK)
- `file_id`: UUID (FK -> minglit_files)
- `viewer_id`: UUID (FK -> users/partners)
- `expires_at`: timestamptz
- `access_type`: text ('read')

## 4. 수락 기준
- [ ] 파일 업로드 시 `minglit_files`에 데이터가 자동 생성되어야 함.
- [ ] `file_access_grants`가 없는 제3자는 파일에 접근(Signed URL 생성 포함)할 수 없어야 함.
- [ ] 권한 만료 시간이 지나면 접근이 차단되어야 함.
