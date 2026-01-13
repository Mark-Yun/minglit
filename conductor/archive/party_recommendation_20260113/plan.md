# Implementation Plan: User Action-Based Recommendation System

## Phase 1: Database Infrastructure & Schema Setup [checkpoint: 1f12526]
- [x] Task: DB - Install and Configure `pgvector` and `pgmq` extensions
    - [x] Sub-task: Create migration to enable extensions in Supabase
    - [x] Sub-task: Verify extensions availability in the database
- [x] Task: DB - Create Separate Embedding Tables
    - [x] Sub-task: Create `user_embeddings` table (FK to users, 1:1, ON DELETE CASCADE)
    - [x] Sub-task: Create `party_embeddings` table (FK to parties/events, 1:1, ON DELETE CASCADE)
    - [x] Sub-task: Create HNSW index on `embedding` columns in both new tables
- [x] Task: DB - User Action & PGMQ Setup
    - [x] Sub-task: Create `user_actions` table (user_id, party_id, action_type, created_at)
    - [x] Sub-task: Initialize PGMQ queue named `recommendation_updates`
- [x] Task: Conductor - User Manual Verification 'Phase 1: Database Infrastructure' (Protocol in workflow.md)

## Phase 2: Party Vectorization System
- [~] Task: Edge Function - Create `vectorize-party` function
    - [x] Sub-task: Write unit tests for OpenAI Embedding API integration
    - [x] Sub-task: Implement JSON serialization logic for party metadata (Title, Desc, Tags, etc.)
    - [x] Sub-task: Implement OpenAI API call and error handling
- [x] Task: DB - Party Vectorization Trigger
    - [x] Sub-task: Create a trigger on `parties` (or `events`) table to invoke `vectorize-party` via HTTP/Job
    - [x] Sub-task: Verify that newly created parties get their embedding automatically stored in `party_embeddings`
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Party Vectorization' (Protocol in workflow.md)
- [x] Task: Conductor - User Manual Verification 'Phase 2: Party Vectorization' (Protocol in workflow.md) [checkpoint: 74b326b]

## Phase 3: Action Queuing & Strategy Pattern Implementation
- [x] Task: DB - Action Logging Trigger
    - [x] Sub-task: Create a trigger on `user_actions` to enqueue a message to `recommendation_updates` PGMQ
    - [x] Sub-task: Verify that actions (view, like, etc.) correctly populate the queue
    - [x] Sub-task: Implement PGMQ consumer loop in Edge Function
    - [x] Sub-task: Update logic to read/write from `user_embeddings` table
- [x] Task: Conductor - User Manual Verification 'Phase 3: Action Queuing & Updates' (Protocol in workflow.md) [checkpoint: e5ad11f]

## Phase 4: Personalized Curation API (Postponed)
## Phase 5: App Integration & UI (Postponed)
