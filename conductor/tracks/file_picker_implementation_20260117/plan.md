# 계획: 범용 파일 피커 (MinglitFilePicker) 구현 및 통합

## Phase 1: 기반 로직 및 위젯 구현 (`minglit_kit`) [checkpoint: 1ecea72]
- [x] Task: `file_picker` 패키지 추가 (1ecea72)
    - [x] `minglit_kit` 및 `app_user`, `app_partner`에 의존성 추가.
- [x] Task: `MinglitFilePicker` 코어 위젯 구현 (1ecea72)
    - [x] 파일 선택 로직 (`image_picker` + `file_picker` 하이브리드).
    - [x] 단일/다중 선택 및 이미지/PDF 필터링 기능.
- [x] Task: 미리보기(Preview) 섹션 구현 (1ecea72)
    - [x] 이미지 썸네일 렌더링.
    - [x] PDF 파일 아이콘 및 파일명 렌더링.
- [x] Task: Conductor - User Manual Verification 'Phase 1: 파일 선택 및 UI 확인' (Protocol in workflow.md) (1ecea72)

## Phase 2: Supabase Storage 연동 및 자동 업로드 [checkpoint: c8c9a00]
- [x] Task: `StorageRepository` 확장 [c8c9a00]
    - [x] 범용 파일 업로드 메서드 구현 (버킷 지정, 유니크 파일명 생성).
- [x] Task: 자동 업로드 상태 관리 (Riverpod) [c8c9a00]
    - [x] 선택된 파일의 업로드 상태(`pending`, `uploading`, `success`, `error`) 추적.
    - [x] 업로드 진행률(%) 표시 UI 연동.
- [x] Task: Conductor - User Manual Verification 'Phase 2: 스토리지 업로드 확인' (Protocol in workflow.md)

## Phase 3: 기존 위젯 통합 및 마이그레이션
- [ ] Task: `MinglitImagePicker` 리팩토링
    - [ ] `MinglitFilePicker`를 내부적으로 사용하도록 수정하여 코드 중복 제거.
- [ ] Task: 프로젝트 전체 마이그레이션
    - [ ] `app_partner` (파티 생성) 및 `app_user` (인증 신청) 화면에 적용.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 전체 통합 확인' (Protocol in workflow.md)
