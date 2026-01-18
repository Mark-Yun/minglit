# Implementation Plan: Party Matching System

## Phase 1: Database Migration (Supabase)
- [~] **Task: Create Migration File `08_matching.sql`**
    - `match_rules` 테이블 생성: `event_id`, `source_group_id`, `target_group_id`.
    - `match_votes` 테이블 생성: `event_id`, `voter_id`, `candidate_id`.
    - `match_results` 테이블 생성: `event_id`, `user_a_id`, `user_b_id`.
- [ ] **Task: Implement Real-time Matching Trigger**
    - `match_votes`에 데이터가 들어오면 `user_a -> user_b`와 `user_b -> user_a`가 있는지 확인 후 `match_results` 자동 생성.
- [ ] **Task: Secure Phone Number Exposure**
    - 매칭된 유저끼리만 연락처를 볼 수 있는 Secure Function 또는 View 구현.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: DB Migration' (Protocol in workflow.md)

## Phase 2: Domain & Data Layer (`minglit_kit`)
- [ ] **Task: Data Models**
    - `MatchRule`, `MatchVote`, `MatchResult` 모델 구현 (Freezed).
- [ ] **Task: MatchingRepository**
    - `getMatchingCandidates(eventId)`: 규칙에 맞는 후보 리스트 조회.
    - `castVote(eventId, candidateId)`: 투표 수행.
    - `getMatchResults(eventId)`: 성사된 매칭 리스트 조회.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Domain Layer' (Protocol in workflow.md)

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
