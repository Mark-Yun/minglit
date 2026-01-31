# 계획: 파트너 앱 메인 대시보드 및 네비게이션 구현

## Phase 1: App Shell 및 하단 네비게이션 구축
- [ ] Task: GoRouter `StatefulShellRoute` 기반 네비게이션 구현
    - [ ] `app_partner` 라우팅 설정 파일 수정 (`app_routes.dart`).
    - [ ] 4개 탭 + 1개 액션 버튼 구조의 `PartnerScaffold` 작성.
- [ ] Task: 중앙 QR 버튼 스타일링
    - [ ] `FloatingActionButton` 또는 `BottomNavigationBarItem` 커스텀 렌더링.
    - [ ] 클릭 시 `QRScannerScreen` (Placeholder) 호출.
- [ ] Task: 4개 탭의 플레이스홀더 화면 연결
    - [ ] `PartnerHomeScreen`, `PartyListPage` (기존), `SettlementPage` (신규), `MorePage` (신규).
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 탭 및 QR 버튼 동작 확인' (Protocol in workflow.md)

## Phase 2: 홈 대시보드 데이터 로직 구현
- [ ] Task: 대시보드용 데이터 프로바이더 작성 (`PartnerDashboardController`)
    - [ ] `EventApplicationRepository`를 통해 '승인 대기(pending_review)' 카운트 조회.
    - [ ] `EventRepository`를 통해 '오늘의 파티' 조회.
- [ ] Task: 매출 데이터 권한 체크 로직
    - [ ] `PartnerMemberPermission`을 확인하여 정산 데이터 조회 권한 검증.
- [ ] Task: 단위 테스트 작성
    - [ ] 대시보드 데이터 로딩 및 권한 로직 테스트.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 데이터 로딩 확인' (Protocol in workflow.md)

## Phase 3: 홈 대시보드 UI 구현
- [ ] Task: 핵심 지표 위젯 구현
    - [ ] `ApprovalWaitingCard`: 대기 인원 수 표시 및 심사 페이지 이동.
    - [ ] `TodayPartyCard`: 오늘의 파티 정보 및 체크인 버튼.
    - [ ] `RevenueSummaryCard`: (권한 있을 시) 월 매출 표시.
- [ ] Task: 대시보드 레이아웃 조립
    - [ ] `CustomScrollView` 또는 `ListView`를 사용하여 위젯 배치.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 대시보드 UI 확인' (Protocol in workflow.md)

## Phase 4: QR 스캐너 연동 (기초)
- [ ] Task: `mobile_scanner` 패키지 설정
    - [ ] iOS/Android 카메라 권한 설정 (Info.plist, AndroidManifest.xml).
- [ ] Task: 스캐너 화면 구현
    - [ ] 전체 화면 스캐너 및 닫기 버튼.
- [ ] Task: 최종 품질 검증
    - [ ] 린트 체크 및 빌드 테스트.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: 전체 기능 통합 확인' (Protocol in workflow.md)
