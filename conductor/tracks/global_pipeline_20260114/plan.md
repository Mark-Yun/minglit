# Implementation Plan: Global Event Pipeline & Hybrid Workers

## Phase 1: Infrastructure Refactoring (Clean Slate) [checkpoint: 20260114-phase1]
- [x] Task: Migration Refactoring (001_schema.sql)
    - [x] Sub-task: Merge existing tables, enums, extensions into `migrations/20260114000001_schema.sql`
    - [x] Sub-task: Define new tables: `event_routes`
    - [x] Sub-task: Remove old migration files
- [x] Task: Pipeline Setup (002_pipeline.sql)
    - [x] Sub-task: Create queues: `q_global_events`, `q_notifications`, `q_vectors`
    - [x] Sub-task: Implement Dispatcher Trigger (`trigger_dispatch_event`)
    - [x] Sub-task: Configure initial `event_routes` in `seed.sql`
- [x] Task: Scheduler Setup (003_cron.sql)
    - [x] Sub-task: Configure `pg_cron` jobs to invoke workers periodically
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Infrastructure Refactoring' (Protocol in workflow.md)

## Phase 2: Notification Worker (Real-time) [checkpoint: 20260114-phase2]
- [x] Task: Edge Function - Create `notification-worker`
    - [x] Sub-task: Implement Long Polling loop (55s limit, 5s interval)
    - [x] Sub-task: Implement PGMQ consumer logic
    - [x] Sub-task: Write unit tests for polling logic
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Notification Worker' (Protocol in workflow.md)

## Phase 3: Vector Worker (Batch Processing) [checkpoint: 20260114-phase3]
- [x] Task: Edge Function - Create `vector-worker`
    - [x] Sub-task: Implement Batch Reader (`pgmq.read_batch` with size 50)
    - [x] Sub-task: Port `OpenAIService` and `serializeParty` logic from previous track
    - [x] Sub-task: Implement `Promise.all` for parallel API calls
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Vector Worker' (Protocol in workflow.md)

## Phase 4: Integration & Testing
- [~] Task: End-to-End Testing
    - [ ] Sub-task: Create a test script to simulate `party_created` event
    - [ ] Sub-task: Verify flow: DB -> Global Queue -> Dispatch -> 2nd Queues -> Workers -> Result
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Integration & Testing' (Protocol in workflow.md)
