# Implementation Plan: Global Event Pipeline v2

## Phase 1: Standardize Message Payload
- [ ] Task: DB - Update Producer Triggers (Migration)
    - [ ] Sub-task: Modify `produce_event` trigger function to generate `id`, `type`, `meta`, `actor`, `payload` structure.
    - [ ] Sub-task: Verify payload structure with test insert.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Standardize Message Payload' (Protocol in workflow.md)

## Phase 2: Robustness Infrastructure (DB)
- [ ] Task: DB - Create Robustness Tables (Migration)
    - [ ] Sub-task: Create `processed_events` table (id, processed_at).
    - [ ] Sub-task: Create `dead_letter_queue` table (msg_id, payload, error_reason).
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Robustness Infrastructure' (Protocol in workflow.md)

## Phase 3: Worker Upgrade (Idempotency & DLQ)
- [ ] Task: Edge Function - Implement Worker Middleware
    - [ ] Sub-task: Create `WorkerUtils` class (checkIdempotency, moveToDLQ, logTimeLag).
    - [ ] Sub-task: Update `notification-worker` to use `WorkerUtils`.
    - [ ] Sub-task: Update `vector-worker` to use `WorkerUtils`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Worker Upgrade' (Protocol in workflow.md)

## Phase 4: Verification
- [ ] Task: Integration Test v2
    - [ ] Sub-task: Test Idempotency (Send same message twice).
    - [ ] Sub-task: Test DLQ (Force error 5 times).
    - [ ] Sub-task: Check Logs for Time Lag.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Verification' (Protocol in workflow.md)
