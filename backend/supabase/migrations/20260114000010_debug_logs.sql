-- Migration to add debug logs table
create table public.debug_logs (
  id uuid default gen_random_uuid() primary key,
  message text,
  payload jsonb,
  created_at timestamptz default now()
);

-- Give permissions
grant all on public.debug_logs to service_role;
grant all on public.debug_logs to postgres;
grant all on public.debug_logs to anon;
grant all on public.debug_logs to authenticated;
