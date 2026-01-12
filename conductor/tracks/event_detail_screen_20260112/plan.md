# Plan: Implement Event Detail Screen

## Phase 1: Data & State Management [checkpoint: 8aeb735]
- [x] Task: Create EventDetailController & State (23d319f)
  - [x] Subtask: Implement EventDetailController in `app_user`
- [x] Task: Integrate EventRepository (dfacabc)
  - [x] Subtask: Ensure `getEvent` method exists and works in `EventRepository`
- [x] Task: Conductor - User Manual Verification 'Phase 1: Data & State Management' (Protocol in workflow.md)

## Phase 2: Admission Logic Integration
- [ ] Task: Implement EventAdmissionController Integration
  - [ ] Subtask: Connect `EventAdmissionController` to `EventDetailScreen` logic
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Admission Logic Integration' (Protocol in workflow.md)

## Phase 3: UI Implementation
- [ ] Task: Build Screen Skeleton & Header
  - [ ] Subtask: Implement Hero Image and Title section
- [ ] Task: Build Info & Conditions Section
  - [ ] Subtask: Implement Info cards and Entry Conditions list
- [ ] Task: Build Dynamic CTA Button
  - [ ] Subtask: Implement sticky bottom CTA with state-based logic
- [ ] Task: Conductor - User Manual Verification 'Phase 3: UI Implementation' (Protocol in workflow.md)

## Phase 4: Navigation & Polish
- [ ] Task: Register Route & Coordinator
  - [ ] Subtask: Add `EventDetailRoute` and update `EventCoordinator`
- [ ] Task: Error Handling & Refresh
  - [ ] Subtask: Implement `handleMinglitError` and `RefreshIndicator`
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Navigation & Polish' (Protocol in workflow.md)

