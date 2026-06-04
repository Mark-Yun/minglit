# Edge Function Architecture

Edge Functions use one wrapper, thin HTTP handlers, typed inputs, service
orchestration, pure domain policy, and Postgres RPC for atomic writes.

## Standard Layers

```text
<ef-name>/
  BLUEDOC.md        # only when the EF has local structure worth mapping
  index.ts          # HTTP/auth/input/response only
  input.ts          # request body validation and typed DTOs
  service.ts        # use-case orchestration, DB/RPC/external IO
  service_test.ts   # fakeSupabase/service-level behavior
  index_test.ts     # auth, invalid input, response mapping
  deno.json

_shared/domains/<domain>/
  BLUEDOC.md
  *.ts              # pure business rules only
  *_test.ts         # dense policy tests, no mocks
```

Action-router EFs may use `_handlers/` and `_lib/` when one public EF exposes
multiple actions. Small EFs may stay as `index.ts` only.

## Responsibilities

`index.ts` owns HTTP concerns: `minglitEdgeFunction`, caller type checks,
`parseJsonBody`, input validation, service invocation, and response mapping.

`input.ts` owns request shape. It should reject invalid field types before DB
queries. Missing-field error strings remain stable for clients and tests.

`service.ts` owns orchestration: Supabase queries, RPC calls, external clients,
logging, Statsig, Sentry breadcrumbs, and use-case result mapping. It should be
small enough that each business branch is visible without reading HTTP code.

`_shared/domains/*` owns pure policy. No DB, HTTP, env, logger, timers, random
IDs, or `Date.now()`. Pass `now`, raw policy, or loaded records as arguments.

Postgres RPC owns atomic writes for inventory, application/order creation,
payment verification, approval, refund, settlement, and other state transitions
that must not partially succeed.

## Route Naming

Function route names are stable public API. New user- or partner-specific
routes should prefer an actor prefix (`user-*`, `partner-*`) when the actor is
part of the contract. System workers may use domain nouns such as
`notification-worker`, and external callbacks may use domain suffixes such as
`payment-webhook`.

Existing unprefixed domain routes remain canonical unless a versioned alias and
manifest deprecation plan are added in the same rollout. This includes
`payment-verify`, `payment-cancel`, `event-checkin`, `apply-event`,
`commit-match-likes`, and `recurrence-rules`. Every manifest entry must have a
matching `supabase/config.toml` section before deploy.

## Extraction Signals

- Two or more request fields with validation rules: add `input.ts`.
- Two or more DB/RPC steps: add `service.ts`.
- A business rule needs many cases or is reused: add `_shared/domains/<domain>`.
- Three or more actions in one EF: use `_handlers/`.
- A write path updates more than one consistency boundary: move it into RPC.

## Test Strategy

Domain policy tests are the primary business-rule guard. They should be fast,
mock-free, and exhaustive over boundary cases.

Service tests verify orchestration with fake Supabase: query/RPC branches,
fail-open/fail-closed policy, update errors, and event emission behavior.

Handler tests stay thin: auth errors, invalid JSON, invalid input, and response
mapping. Integration/CUJ tests prove schema/RLS/RPC wiring and key happy paths,
not every business-rule combination.

---

_Reviewed: 2026-05-24 00:00_
