# Plan: Implement Event Detail Screen

## Phase 1: Data & State Management
- [x] Task: Create EventDetailController & State (23d319f)
  - [ ] Subtask: Write tests for EventDetailController (mock repository)
  - [ ] Subtask: Implement EventDetailController in `app_user`
- [ ] Task: Integrate EventRepository
  - [ ] Subtask: Write integration test for fetching single event
  - [ ] Subtask: Ensure `getEvent` method exists and works in `EventRepository`
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Data & State Management' (Protocol in workflow.md)

## Phase 2: Admission Logic Integration
- [ ] Task: Implement EventAdmissionController Integration
  - [ ] Subtask: Write tests for admission state logic (Guest -> Eligible transitions)
  - [ ] Subtask: Connect `EventAdmissionController` to `EventDetailScreen` logic
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Admission Logic Integration' (Protocol in workflow.md)

## Phase 3: UI Implementation
- [ ] Task: Build Screen Skeleton & Header
  - [ ] Subtask: Write widget test for Header display
  - [ ] Subtask: Implement Hero Image and Title section
- [ ] Task: Build Info & Conditions Section
  - [ ] Subtask: Write widget test for EntryGroupDetail integration
  - [ ] Subtask: Implement Info cards and Entry Conditions list
- [ ] Task: Build Dynamic CTA Button
  - [ ] Subtask: Write widget test for button states (Login vs Verify vs Select)
  - [ ] Subtask: Implement sticky bottom CTA with state-based logic
- [ ] Task: Conductor - User Manual Verification 'Phase 3: UI Implementation' (Protocol in workflow.md)

## Phase 4: Navigation & Polish
- [ ] Task: Register Route & Coordinator
  - [ ] Subtask: Write test for GoRouter navigation to detail screen
  - [ ] Subtask: Add `EventDetailRoute` and update `EventCoordinator`
- [ ] Task: Error Handling & Refresh
  - [ ] Subtask: Write test for error state and pull-to-refresh
  - [ ] Subtask: Implement `handleMinglitError` and `RefreshIndicator`
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Navigation & Polish' (Protocol in workflow.md)

