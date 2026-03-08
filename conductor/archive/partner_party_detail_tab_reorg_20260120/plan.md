# 계획: 파트너 앱 파티 상세 탭 구조 재구성

## Phase 1: 탭 구조 및 위젯 분리 준비
- [ ] Task: `PartyDetailPage`의 탭 컨트롤러 확장 (2 -> 3개)
- [ ] Task: 기존 탭 위젯에서 도메인별 컴포넌트 추출
    - [ ] `PartyDetailOperationTab`에서 이벤트 리스트와 티켓 리스트 분리.
    - [ ] `PartyDetailInfoTab`에서 입장 조건 그룹 섹션 추출.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 기본 탭 UI 구조 확인' (Protocol in workflow.md)

## Phase 2: 신규 탭 위젯 구현 (`app_partner`)
- [ ] Task: **탭 1: `PartyEventManagementTab`** 구현
    - [ ] 이벤트 목록 및 회차 생성 버튼 배치.
- [ ] Task: **탭 2: `PartyInfoTab`** 리팩터링
    - [ ] 기본 정보, 운영 상태, 장소, 연락처 섹션 유지.
    - [ ] 입장 조건 요약 섹션 삭제.
- [ ] Task: **탭 3: `PartyRuleManagementTab`** 구현
    - [ ] 상단: 입장 조건 그룹(`EntryGroupTemplate`) 리스트.
    - [ ] 하단: 티켓 템플릿(`TicketTemplate`) 리스트 및 수정 연동.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 각 탭별 내용 배치 확인' (Protocol in workflow.md)

## Phase 3: 품질 검증 및 마무리
- [ ] Task: 탭 전환 시 데이터 동기화 확인 (Riverpod Provider 갱신 로직)
- [ ] Task: 코드 품질 강화 루프 실행
    - [ ] `dart fix --apply`, `dart format`, `flutter analyze` (Zero Warning 달성).
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 전체 운영 흐름 및 개연성 확인' (Protocol in workflow.md)
