# 계획: 파티 상세 이미지 다중 업로드 및 뷰어 구현

## Phase 1: 데이터베이스 스키마 및 모델 업데이트
- [ ] Task: SQL 마이그레이션 작성 및 적용
    - [ ] `public.parties` 테이블에 `image_urls` (text[]) 컬럼 추가.
    - [ ] 기존 `image_url` 데이터를 `image_urls` 배열로 이관하는 마이그레이션 스크립트 작성.
- [ ] Task: `Party` 데이터 모델 업데이트 (`minglit_kit`)
    - [ ] `Party` 클래스에 `imageUrls` 필드 추가 및 `fromJson` 매핑 수정.
    - [ ] 기존 `imageUrl` 필드를 Getter로 유지 (배열의 첫 번째 요소 반환)하여 하위 호환성 확보.
    - [ ] `build_runner` 실행하여 코드 생성.
- [ ] Task: 모델 매핑 단위 테스트 작성
    - [ ] `test/src/data/models/party_test.dart` 생성 또는 수정.
    - [ ] 단일/다중 이미지 JSON 데이터가 올바르게 매핑되는지 검증.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 데이터 구조 변경 확인' (Protocol in workflow.md)

## Phase 2: 다중 이미지 업로드 및 편집 UI (`app_partner`)
- [x] Task: `PartyRepository` 이미지 업로드 로직 수정
    - [x] 다중 파일을 순차적으로 업로드하고 URL 리스트를 반환하는 `uploadPartyImages` 구현.
- [ ] Task: `PartyImageEditor` 웹 미리보기 버그 수정
    - [ ] `XFile.path`가 웹에서 동작하지 않는 문제 해결 (Blob URL 또는 Bytes 사용).
- [ ] Task: 다중 이미지 리스트 관리 UI 개선
    - [ ] 이미지 추가 시 기존 리스트 뒤에 추가.
    - [ ] 개별 삭제 기능 유지.
    - [ ] **첫 번째 이미지가 대표(Badge)**임을 명확히 UI로 표시.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 파트너 앱 다중 업로드 테스트' (Protocol in workflow.md)

## Phase 3: 이미지 캐러셀 및 라이트박스 구현 (`minglit_kit`, `apps`)
- [ ] Task: 공용 `MinglitImageCarousel` 위젯 구현 (`minglit_kit`)
    - [ ] `PageView` 기반의 슬라이더 및 페이지 인디케이터(Dot style) 구현.
- [ ] Task: 이미지 상세 보기(Lightbox) 구현
    - [ ] 이미지 클릭 시 전체 화면으로 확대하여 볼 수 있는 뷰어 연동 (`photo_view` 등 활용).
- [ ] Task: 각 앱 상세 페이지 통합
    - [ ] 유저 앱 `EventDetailScreen` 상단 이미지를 캐러셀로 교체.
    - [ ] 파트너 앱 파티 상세 요약부 이미지 교체.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 최종 캐러셀 동작 확인' (Protocol in workflow.md)
