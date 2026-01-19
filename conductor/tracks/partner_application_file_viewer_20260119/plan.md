# 계획: 파트너 신청 서류 뷰어 구현

## Phase 1: 파일 조회 로직 구현
- [ ] Task: `SupabaseStorage`에서 Signed URL 생성 로직 구현
    - [ ] `PartnerRepository` 또는 공통 유틸리티에 `getSignedUrl(path)` 추가.
- [ ] Task: 파일 타입 판별 로직 (MIME type 또는 확장자 기반).

## Phase 2: UI 구현
- [ ] Task: 이미지 뷰어 다이얼로그 구현
    - [ ] `InteractiveViewer`를 포함한 `Dialog` 위젯 작성.
- [ ] Task: `PartnerApplicationDetailScreen` 연동
    - [ ] 파일 리스트 아이템 클릭 이벤트 핸들러 구현.
    - [ ] 이미지면 다이얼로그, 그 외면 `url_launcher` 호출.

## Phase 3: 테스트
- [ ] Task: 실제 이미지 및 PDF 파일 업로드 후 조회 테스트.
