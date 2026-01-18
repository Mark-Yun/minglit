# 명세서: 범용 파일 피커 (MinglitFilePicker) 구현 및 통합

## 1. 개요
기존 `MinglitImagePicker`를 대체하고 기능을 확장하여, 이미지뿐만 아니라 PDF 등 문서 파일까지 지원하는 범용 파일 피커를 구현합니다. `image_picker`와 `file_picker` 패키지를 활용하며, 선택된 파일의 미리보기 및 Supabase Storage 자동 업로드 기능을 제공하여 개발 생산성을 높입니다.

## 2. 주요 기능

### 2.1. 파일 선택 (File Selection)
- **지원 포맷:** 이미지(JPG, PNG), 문서(PDF).
- **다중 선택:** 옵션(`allowMultiple: true`)을 통해 여러 파일을 한 번에 선택 가능.
- **소스:** 갤러리/파일 탐색기 및 카메라(이미지의 경우) 지원.

### 2.2. 미리보기 (Preview UI)
- **이미지:** 썸네일 또는 전체 화면 미리보기.
- **PDF:** 첫 페이지 썸네일(가능한 경우) 또는 파일 아이콘과 파일명 표시.
- **리스트 뷰:** 다중 선택 시 가로 스크롤 또는 그리드 형태의 미리보기 리스트 제공.

### 2.3. 자동 업로드 (Auto-Upload Integration)
- **옵션:** `autoUpload: true` 설정 시, 파일 선택 직후 Supabase Storage에 업로드를 시작.
- **상태 표시:** 업로드 중 프로그레스 바(%), 성공/실패 아이콘 표시.
- **결과 반환:** 업로드 완료 시 다운로드 URL(`List<String>`) 반환.

### 2.4. 통합 및 마이그레이션
- 기존 `MinglitImagePicker`를 `MinglitFilePicker`를 사용하는 래퍼(Wrapper)로 변경하거나, 완전히 대체하여 삭제 (`Deprecated` 처리 후 점진적 제거).

## 3. 기술 스택
- **패키지:** `image_picker` (카메라/이미지 최적화), `file_picker` (범용 파일 및 다중 선택).
- **백엔드:** Supabase Storage.

## 4. 수락 기준
- [ ] `MinglitFilePicker` 위젯이 `minglit_kit`에 구현되어야 함.
- [ ] 이미지와 PDF 파일을 모두 선택할 수 있어야 함.
- [ ] 선택된 파일이 지정된 버킷(예: `verification-docs`)에 업로드되고 URL이 반환되어야 함.
- [ ] 기존 `MinglitImagePicker` 사용처(`app_partner` 등)가 깨지지 않도록 호환성을 유지하거나 수정해야 함.
