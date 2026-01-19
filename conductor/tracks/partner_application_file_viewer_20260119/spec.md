# 명세서: 파트너 신청 서류 뷰어 구현 (Partner Application File Viewer)

## 1. 개요
파트너 가입 신청 시 제출된 증빙 서류(사업자등록증, 신분증, 통장사본 등)를 관리자 앱(`app_partner`)에서 조회할 수 있는 기능을 구현합니다. 제출된 파일은 이미지(JPG, PNG) 또는 PDF 형식이므로, 각 형식에 맞는 적절한 뷰어를 제공해야 합니다.

## 2. 주요 기능

### 2.1. 파일 다운로드 및 조회 버튼
- `PartnerApplicationDetailScreen`의 파일 리스트 아이템에 [보기] 또는 아이콘 버튼 제공.
- TODO 주석(`// TODO(mark): Implement file download logic.`) 해결.

### 2.2. 이미지 뷰어
- **동작**: 이미지 파일 클릭 시 전체 화면 다이얼로그로 표시.
- **기능**: 핀치 줌(확대/축소) 및 드래그 이동 (`InteractiveViewer` 사용).
- **닫기**: 배경 클릭 또는 닫기 버튼으로 종료.

### 2.3. PDF 및 문서 뷰어
- **동작**: PDF 등 비이미지 파일 클릭 시 시스템 기본 뷰어 또는 브라우저로 열기.
- **구현**: `url_launcher` 패키지의 `launchUrl` 사용.
- **웹 호환성**: 웹 환경에서는 브라우저 새 탭으로 열기 지원.

## 3. 기술 스택
- **Image**: `InteractiveViewer`, `showDialog`.
- **PDF/Doc**: `url_launcher`.
- **Storage**: Supabase Storage Signed URL 생성 로직.

## 4. 수락 기준
- [ ] 파트너 신청 상세 화면에서 제출된 파일을 클릭하면 뷰어가 떠야 함.
- [ ] 이미지는 앱 내 팝업으로 확대/축소 가능해야 함.
- [ ] PDF는 외부 브라우저나 시스템 뷰어로 정상적으로 열려야 함.
