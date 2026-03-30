# Global Event Pipeline Architecture

This document describes the two-tier queue architecture used in Minglit to handle system events, notifications, and vector embeddings.

## 1. Overview

The Global Event Pipeline is a robust, asynchronous event processing system. It uses a two-tier approach to decouple event production from consumption. All system events first enter a central hub before being distributed to specialized queues. This design ensures that the system can handle high volumes of events without blocking the main database transactions. It also allows for easy addition of new consumers without modifying existing producers.

## 2. Architecture Diagram

The diagram below illustrates the flow of an event from the database trigger to the final consumer.

```text
+-------------------+       +-----------------------+
|  Database Tables  |       |  produce_event()      |
|  (parties, etc.)  | ----> |  (Trigger Function)   |
+-------------------+       +-----------+-----------+
                                        |
                                        v
                            +-----------+-----------+
                            |   q_global_events     | (Tier 1: Central Hub)
                            +-----------+-----------+
                                        |
                                        v
                            +-----------+-----------+
                            |   fan_out_event()     | (Dispatcher)
                            +-----+-----------+-----+
                                  |           |
               +------------------+           +------------------+
               |                                                 |
               v                                                 v
    +----------+----------+                           +----------+----------+
    |   q_notifications   | (Tier 2)                  |     q_vectors       | (Tier 2)
    +----------+----------+                           +----------+----------+
               |                                                 |
               v                                                 v
    +----------+----------+                           +----------+----------+
    | notification-worker | (Edge Function)           |    vector-worker    | (Edge Function)
    +----------+----------+                           +----------+----------+
               |                                                 |
               v                                                 v
    +----------+----------+                           +----------+----------+
    |     FCM / Push      |                           |     pgvector        |
    +---------------------+                           +---------------------+
```

## 3. Event Types

Minglit tracks ten primary event types. Each type has a specific producer and target queues.

| Event Type | Producer (Trigger/Cron) | Target Queues | Description |
| :--- | :--- | :--- | :--- |
| `party_created` | `parties` INSERT | `q_notifications`, `q_vectors` | Triggered when a new social party is created. |
| `user_interaction` | `user_actions` INSERT | `q_notifications`, `q_vectors` | Tracks user likes, views, or dislikes for personalization. |
| `application_approved` | `event_applications` UPDATE | `q_notifications` | Sent when a user's request to join an event is accepted. |
| `application_rejected` | `event_applications` UPDATE | `q_notifications` | Sent when a user's request to join an event is declined. |
| `event_updated` | `events` UPDATE | `q_notifications` | Triggered by changes in event title, time, or location. |
| `event_cancelled` | `events` UPDATE | `q_notifications` | Fired when an event status changes to 'cancelled'. |
| `new_application` | `event_applications` INSERT | `q_notifications` | Notifies partners about a new applicant for their event. |
| `verification_result` | `verification_submissions` UPDATE | `q_notifications` | Communicates the outcome of a user's ID verification. |
| `event_reminder` | `send_event_reminders()` cron | `q_notifications` | Sent to participants one hour before an event starts. |
| `match_result` | `notify_match_results()` cron | `q_notifications` | Notifies matched users of their match result after the event. |

## 4. Event Routes

The `event_routes` table governs how events move from the global queue to specialized ones. This table allows administrators to toggle routes on or off without changing code.

### Route Matrix

| event_type | q_notifications | q_vectors |
| :--- | :---: | :---: |
| `party_created` | ✅ | ✅ |
| `user_interaction` | ✅ | ✅ |
| `application_approved` | ✅ | — |
| `application_rejected` | ✅ | — |
| `event_updated` | ✅ | — |
| `event_cancelled` | ✅ | — |
| `new_application` | ✅ | — |
| `verification_result` | ✅ | — |
| `event_reminder` | ✅ | — |
| `match_result` | ✅ | — |

Total: 12 active routes (q_notifications: 10, q_vectors: 2)

## 5. Payload Schema

The `produce_event()` function generates a standardized JSONB payload. This ensures consistency across all workers.

```json
{
  "event_id": "7981f211-5f50-4828-9f37-1234567890ab",
  "event_type": "application_approved",
  "occurred_at": 1708000000,
  "schema_version": 1,
  "data": {
    "id": "...",
    "user_id": "...",
    "event_id": "...",
    "status": "approved",
    "created_at": "..."
  },
  "metadata": {
    "source_table": "event_applications",
    "source_id": "uuid"
  }
}
```

## 6. Queue Details

*   **`q_global_events`**: The central hub. It accepts raw event data from database triggers. Its primary role is to serve as the source for the fan-out process.
*   **`q_notifications`**: Dedicated to user-facing alerts. Messages here are consumed by the `notification-worker` to send push notifications and update in-app notification history.
*   **`q_vectors`**: Used for background analytical tasks. The `vector-worker` consumes these to update user and party embeddings in `pgvector` for the recommendation engine.

## 7. Notification Template System

While some legacy triggers still hold text, the system is moving toward a template-based approach in the `notification-worker`. Below are the current Korean text mappings for various event types.

| Event Type | Title Example | Body Example |
| :--- | :--- | :--- |
| `application_approved` | `[이벤트 참가 확정] {title}` | `이벤트 참가가 확정되었습니다.` |
| `application_rejected` | `[신청 거절] {title}` | `신청이 거절되었습니다.` |
| `event_cancelled` | `[이벤트 취소] {title}` | `진행 예정이었던 이벤트가 취소되었습니다.` |
| `event_updated` | `[이벤트 업데이트] {title}` | `주최자가 이벤트 정보를 변경했습니다.` |
| `new_application` | `[신규 신청] {title}` | `새로운 이벤트 참가 신청이 도착했습니다.` |
| `verification_result` | `[인증 승인] {display_name}` | `인증이 승인되었습니다.` |
| `event_reminder` | `[리마인더] {title}` | `이벤트가 1시간 후 시작됩니다.` |
| `match_result` | `[매칭 결과]` | `{event_title}에서 매칭이 성사되었습니다! 결과를 확인해 보세요.` |

## 8. Error Handling

The pipeline includes several layers of resilience:

*   **Idempotency**: The `processed_events` table tracks handled `trace_id` values to prevent duplicate processing.
*   **Retry Policy**: PGMQ's visibility timeout allows workers to retry failed tasks. If a task fails 5 times, it is moved to the `dead_letter_queue`.
*   **Dead Letter Queue (DLQ)**: The `dead_letter_queue` table stores failed messages along with the error reason for manual inspection and recovery.

## 9. Adding New Event Types

Follow this checklist to integrate a new event into the pipeline:

1.  **Enum Update**: Add the new event type name to the `event_type_name` enum in a migration.
2.  **Define Route**: Insert the routing logic into the `event_routes` table.
3.  **Create Trigger**: Add a trigger to the source table that calls `produce_event('your_event_type')`.
4.  **Worker Logic**: Update the relevant worker (e.g., `notification-worker`) to handle the new payload and apply templates.
5.  **Tests**: Add a pgTAP test case to verify the event flows through both queue tiers.

## 10. Known Limitations

*   **Cron Latency**: Some events depend on `pg_cron` (like `event_reminder`), which has a minimum resolution of one minute.
*   **External Hooks**: The `portone-webhook` currently bypasses the global pipeline and interacts with the database directly for immediate processing requirements.
*   **Batching**: The `vector-worker` processes events in batches of up to 50, which might introduce slight delays in recommendation updates.

## 11. Decision Log

### Why a Two-Tier Architecture?
We chose a two-tier design to solve the "one-to-many" problem. A single database action (like creating a party) often needs to trigger multiple downstream effects (sending notifications, updating search vectors, and logging analytics). A single queue would require the producer to know about every consumer. With two tiers, the producer only needs to send data once to the global hub.

### Why DB Trigger Fan-out?
Using database triggers ensures that events are captured even if the application layer changes. It provides a single source of truth at the data layer. By moving the fan-out logic to a dispatcher, we keep the individual triggers simple and maintainable.

---

## Related Documents

- [Backend Architecture](./backend.md) — 전체 백엔드 인프라
- [Search & Recommendation](./search-and-recommendation.md) — q_vectors 큐 consumer (vector-worker)
- [Trust & Verification](./trust-and-verification.md) — verification_result 이벤트 처리
- [Payment Pipeline](./payment-pipeline.md) — 결제/정산 파이프라인
