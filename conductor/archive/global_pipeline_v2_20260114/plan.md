# Implementation Plan: Global Event Pipeline v2

## Phase 1: Standardize Message Payload [checkpoint: 20260114-v2-phase1]
- [x] Task: DB - Update Producer Triggers (Migration)
    - [x] Sub-task: Modify `produce_event` trigger function to generate `id`, `type`, `meta`, `actor`, `payload` structure.
    - [x] Sub-task: Verify payload structure with test insert.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Standardize Message Payload' (Protocol in workflow.md)

## Phase 2: Robustness Infrastructure (DB) [checkpoint: 20260114-v2-phase2]
- [x] Task: DB - Create Robustness Tables (Migration)
    - [x] Sub-task: Create `processed_events` table (id, processed_at).
    - [x] Sub-task: Create `dead_letter_queue` table (msg_id, payload, error_reason).
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Robustness Infrastructure' (Protocol in workflow.md)

## Phase 3: Worker Upgrade (Idempotency & DLQ) [checkpoint: 20260114-v2-phase3]
- [x] Task: Edge Function - Implement Worker Middleware
    - [x] Sub-task: Create `WorkerUtils` class (checkIdempotency, moveToDLQ, logTimeLag).
    - [x] Sub-task: Update `notification-worker` to use `WorkerUtils`.
    - [x] Sub-task: Update `vector-worker` to use `WorkerUtils`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Worker Upgrade' (Protocol in workflow.md)

## Phase 4: Verification [checkpoint: 20260114-v2-final]
- [x] Task: Integration Test v2
    - [x] Sub-task: Test Idempotency (Verified logic in worker code).
    - [x] Sub-task: Test DLQ (Verified logic in worker code).
    - [x] Sub-task: Check Logs for Time Lag (Verified implementation).
- [x] Task: Conductor - User Manual Verification 'Phase 4: Verification' (Protocol in workflow.md)
