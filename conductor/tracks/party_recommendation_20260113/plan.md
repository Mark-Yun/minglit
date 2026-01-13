# Implementation Plan: User Action-Based Recommendation System

## Phase 1: Database Infrastructure & Schema Setup
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
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Database Infrastructure' (Protocol in workflow.md)

## Phase 2: Party Vectorization System
- [ ] Task: Edge Function - Create `vectorize-party` function
    - [ ] Sub-task: Write unit tests for OpenAI Embedding API integration
    - [ ] Sub-task: Implement JSON serialization logic for party metadata (Title, Desc, Tags, etc.)
    - [ ] Sub-task: Implement OpenAI API call and error handling
- [ ] Task: DB - Party Vectorization Trigger
    - [ ] Sub-task: Create a trigger on `parties` (or `events`) table to invoke `vectorize-party` via HTTP/Job
    - [ ] Sub-task: Verify that newly created parties get their embedding automatically stored in `party_embeddings`
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Party Vectorization' (Protocol in workflow.md)

## Phase 3: Action Queuing & Strategy Pattern Implementation
- [ ] Task: DB - Action Logging Trigger
    - [ ] Sub-task: Create a trigger on `user_actions` to enqueue a message to `recommendation_updates` PGMQ
    - [ ] Sub-task: Verify that actions (view, like, etc.) correctly populate the queue
- [ ] Task: Edge Function - Implement `update-user-profile` logic
    - [ ] Sub-task: Write tests for `HybridCalculator` (Strategy pattern) with weighted vector math
    - [ ] Sub-task: Implement `HybridCalculator` using Moving Average + Cumulative logic
    - [ ] Sub-task: Implement PGMQ consumer loop in Edge Function
    - [ ] Sub-task: Update logic to read/write from `user_embeddings` table
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Action Queuing & Updates' (Protocol in workflow.md)

## Phase 4: Personalized Curation API
- [ ] Task: DB - Create Personalized Curation RPC function
    - [ ] Sub-task: Write SQL function `get_personalized_events(user_id)` joining `party_embeddings` and `user_embeddings`
    - [ ] Sub-task: Implement filtering and ranking logic (similarity threshold, limit) using Cosine Similarity (`<=>`)
    - [ ] Sub-task: Verify search performance with HNSW index
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Curation API' (Protocol in workflow.md)

## Phase 5: App Integration & UI
- [ ] Task: App - Integrate User Action Tracking
    - [ ] Sub-task: Update Repository to log `view`, `like`, `purchase` actions to `user_actions` table
- [ ] Task: App - Recommendation UI Implementation
    - [ ] Sub-task: Create `PersonalizedEventList` widget in `app_user`
    - [ ] Sub-task: Connect to `get_personalized_events` RPC and display results
- [ ] Task: Conductor - User Manual Verification 'Phase 5: App Integration' (Protocol in workflow.md)
