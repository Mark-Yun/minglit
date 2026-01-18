# Implementation Plan: Party Matching System

## Phase 1: Database Migration (Supabase) [checkpoint: 576ad7c]
- [x] **Task: Create Migration File `08_matching.sql`** [df9b36e]
- [x] **Task: Implement Real-time Matching Trigger** [df9b36e]
- [x] **Task: Secure Phone Number Exposure** [df9b36e]
- [x] Task: Conductor - User Manual Verification 'Phase 1: DB Migration' (Protocol in workflow.md)

## Phase 2: Domain & Data Layer (`minglit_kit`) [checkpoint: 3b36e4b]
- [x] **Task: Data Models** [df9b36e]
    - `MatchRule`, `MatchVote`, `MatchPair` 모델 구현 (Freezed).
- [x] **Task: MatchingRepository** [df9b36e]
    - `getMatchingCandidates(eventId)`: 규칙에 맞는 후보 리스트 조회.
    - `castVote(eventId, candidateId)`: 투표 수행.
    - `getMatchResults(eventId)`: 성사된 매칭 리스트 조회.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Domain Layer' (Protocol in workflow.md)

## Phase 3: Partner Interface (Setting & Control)
- [ ] **Task: Matching Setup UI**
    - 이벤트 생성/수정 화면에 매칭 규칙 설정 UI 추가.
- [ ] **Task: Matching Controller**
    - 매칭 세션 수동 활성화 버튼 및 상태 관리.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Partner UI' (Protocol in workflow.md)

## Phase 4: User Experience (Voting & Matching)
- [ ] **Task: Voting Screen**
    - 파티 종료 후 접근 가능한 매칭 투표 화면 구현.
- [ ] **Task: Result UI**
    - 매칭 성공 시 화려한 애니메이션과 함께 연락처 노출.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: User UI' (Protocol in workflow.md)
