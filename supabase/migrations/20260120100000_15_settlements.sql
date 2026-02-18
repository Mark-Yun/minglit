-- 15. SETTLEMENTS: Settlement Records, Revenue Views, Cron

-- 1. Tables
create table public.settlements (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid not null references public.partners(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  event_title text not null,
  event_date timestamptz not null,
  total_sales integer not null default 0,
  total_refunds integer not null default 0,
  pg_fee integer not null default 0,
  platform_fee integer not null default 0,
  vat integer not null default 0,
  net_amount integer not null default 0,
  status text not null default 'pending'
    check (status in ('pending', 'ready', 'requested', 'completed')),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (event_id)
);

create index settlements_partner_id_idx on public.settlements(partner_id);
create index settlements_status_idx on public.settlements(status);
create index settlements_event_date_idx on public.settlements(event_date);

-- 2. Revenue Views
create or replace view public.partner_revenue_stats as
select
  partner_id,
  coalesce(sum(total_sales), 0) as total_sales,
  coalesce(sum(total_refunds), 0) as total_refunds,
  coalesce(sum(net_amount), 0) as net_amount
from public.settlements
group by partner_id;

create or replace view public.partner_monthly_revenue as
select
  partner_id,
  date_trunc('month', event_date)::date as month,
  coalesce(sum(total_sales), 0) as total_sales,
  coalesce(sum(total_refunds), 0) as total_refunds,
  coalesce(sum(net_amount), 0) as net_amount
from public.settlements
group by partner_id, date_trunc('month', event_date)
order by month;

-- 3. Settlement Creation Trigger
create or replace function public.create_settlement_on_event_completion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_partner_id uuid;
  v_event_title text;
  v_event_date timestamptz;
  v_total_sales integer := 0;
  v_total_refunds integer := 0;
  v_pg_fee integer := 0;
  v_platform_fee integer := 0;
  v_vat integer := 0;
  v_net_amount integer := 0;
begin
  if (new.status = 'completed' and old.status is distinct from 'completed') then
    select p.partner_id,
      coalesce(new.title, p.title),
      new.end_time
    into v_partner_id, v_event_title, v_event_date
    from public.parties p
    where p.id = new.party_id;

    select
      coalesce(
        sum(case when ea.status in ('paid', 'approved') then ea.payment_amount else 0 end),
        0
      ),
      coalesce(
        sum(case when ea.refund_status = 'completed' then ea.payment_amount else 0 end),
        0
      )
    into v_total_sales, v_total_refunds
    from public.event_applications ea
    where ea.event_id = new.id;

    v_pg_fee := round(v_total_sales * 0.035)::int;
    v_platform_fee := round(v_total_sales * 0.05)::int;
    v_vat := round((v_pg_fee + v_platform_fee) * 0.1)::int;
    v_net_amount := v_total_sales - v_total_refunds - v_pg_fee - v_platform_fee - v_vat;

    insert into public.settlements (
      partner_id,
      event_id,
      event_title,
      event_date,
      total_sales,
      total_refunds,
      pg_fee,
      platform_fee,
      vat,
      net_amount,
      status
    )
    values (
      v_partner_id,
      new.id,
      v_event_title,
      v_event_date,
      v_total_sales,
      v_total_refunds,
      v_pg_fee,
      v_platform_fee,
      v_vat,
      v_net_amount,
      'pending'
    )
    on conflict (event_id) do update
    set
      event_title = excluded.event_title,
      event_date = excluded.event_date,
      total_sales = excluded.total_sales,
      total_refunds = excluded.total_refunds,
      pg_fee = excluded.pg_fee,
      platform_fee = excluded.platform_fee,
      vat = excluded.vat,
      net_amount = excluded.net_amount,
      updated_at = now();
  end if;
  return new;
end;
$$;

create trigger on_event_completed
  after update of status on public.events
  for each row execute procedure public.create_settlement_on_event_completion();

create trigger handle_updated_at before update on public.settlements
  for each row execute procedure moddatetime(updated_at);

-- 4. Cron Job: Transition Pending -> Ready after 7 days
create or replace function public.update_settlement_ready_status()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.settlements
  set status = 'ready', updated_at = now()
  where status = 'pending'
  and event_date <= now() - interval '7 days';
end;
$$;

select cron.schedule(
  'settlement-status-transition',
  '0 3 * * *',
  $$
    select public.update_settlement_ready_status();
  $$
);

-- 5. RLS Policies
alter table public.settlements enable row level security;

create policy "Partner can read own settlements" on public.settlements for select
  using (
    public.is_super_admin() or public.has_partner_permission(partner_id, 'SETTLEMENT_VIEW')
  );
