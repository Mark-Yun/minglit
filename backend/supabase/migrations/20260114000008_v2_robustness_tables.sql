-- v2 Robustness Tables: Idempotency and DLQ
create table public.processed_events (
  id uuid primary key, -- The Trace ID/Event ID from the message
  processed_at timestamptz not null default now()
);

create table public.dead_letter_queue (
  id uuid default gen_random_uuid() primary key,
  msg_id bigint not null,
  queue_name text not null,
  payload jsonb not null,
  error_reason text,
  failed_at timestamptz not null default now()
);

-- RLS
alter table public.processed_events enable row level security;
alter table public.dead_letter_queue enable row level security;

-- Index for maintenance
create index processed_events_at_idx on public.processed_events(processed_at);
create index dlq_queue_name_idx on public.dead_letter_queue(queue_name);
