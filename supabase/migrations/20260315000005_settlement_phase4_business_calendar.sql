-- Settlement Phase 4: Business Calendar
-- REQ-4.6.01: D+2 영업일 15:00 KST, REQ-4.6.02: Cutoff 14:00 KST
-- REQ-4.6.03: business_calendar(date, is_business_day, reason)
-- REQ-4.6.04: 은행 점검 23:30-00:30 KST 회피

create table if not exists public.business_calendar (
  date            date    primary key,
  is_business_day boolean not null default true,
  reason          text
);

-- Seed ALL 365 days of 2026 as business days first
insert into public.business_calendar (date, is_business_day, reason)
select gs::date, true, null
from generate_series('2026-01-01'::date, '2026-12-31'::date, '1 day'::interval) gs
on conflict (date) do nothing;

-- Then mark weekends as non-business
update public.business_calendar
set is_business_day = false,
    reason = coalesce(reason, '주말')
where date between '2026-01-01' and '2026-12-31'
  and extract(dow from date) in (0, 6);

-- Then mark KR public holidays (incl. 대체공휴일)
insert into public.business_calendar (date, is_business_day, reason) values
  ('2026-01-01', false, '신정'),
  ('2026-01-28', false, '설날 연휴'),
  ('2026-01-29', false, '설날'),
  ('2026-01-30', false, '설날 연휴'),
  ('2026-03-01', false, '삼일절'),
  ('2026-03-02', false, '삼일절 대체공휴일'),
  ('2026-05-05', false, '어린이날'),
  ('2026-05-24', false, '부처님오신날'),
  ('2026-05-25', false, '부처님오신날 대체공휴일'),
  ('2026-06-06', false, '현충일'),
  ('2026-08-15', false, '광복절'),
  ('2026-08-17', false, '광복절 대체공휴일'),
  ('2026-10-03', false, '개천절'),
  ('2026-10-05', false, '추석'),
  ('2026-10-06', false, '추석 연휴'),
  ('2026-10-07', false, '추석 연휴'),
  ('2026-10-09', false, '한글날'),
  ('2026-12-25', false, '성탄절')
on conflict (date) do update
  set is_business_day = excluded.is_business_day,
      reason          = excluded.reason;

-- calculate_scheduled_at: D+2 business day at 15:00 KST
-- REQ-4.6.01/02/03/04
create or replace function public.calculate_scheduled_at(
  p_base_date   date,
  p_cutoff_time time default '14:00'
)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now_kst_time   time;
  v_effective_date date;
  v_target_date    date;
  v_result         timestamptz;
  v_result_time    time;
  v_calendar_count int;
begin
  v_now_kst_time := (now() at time zone 'Asia/Seoul')::time;

  if v_now_kst_time > p_cutoff_time then
    v_effective_date := p_base_date + 1;
  else
    v_effective_date := p_base_date;
  end if;

  -- Fallback check: if no non-business day entries in next 30 days → calendar data absent
  -- (business_calendar stores all days; is_business_day=false marks non-business days)
  select count(*) into v_calendar_count
  from public.business_calendar
  where date > v_effective_date
    and date <= v_effective_date + 30
    and is_business_day = false;

  if v_calendar_count = 0 then
    raise warning
      'business_calendar has no data after %. Falling back to D+2 calendar days.',
      v_effective_date;
    return (v_effective_date + interval '2 days' + time '15:00')
           at time zone 'Asia/Seoul';
  end if;

  -- D+2 business day: generate_series and skip dates marked as non-business in calendar.
  -- A date is a business day if it does NOT appear in business_calendar with is_business_day=false.
  select date into v_target_date
  from (
    select d::date as date,
           row_number() over (order by d) as rn
    from generate_series(
      v_effective_date + interval '1 day',
      v_effective_date + interval '30 days',
      interval '1 day'
    ) as d
    where not exists (
      select 1 from public.business_calendar bc
      where bc.date = d::date
        and bc.is_business_day = false
    )
  ) biz_days
  where rn = 2;

  if v_target_date is null then
    raise warning
      'Not enough business days found after %. Falling back to D+2 calendar days.',
      v_effective_date;
    return (v_effective_date + interval '2 days' + time '15:00')
           at time zone 'Asia/Seoul';
  end if;

  v_result := (v_target_date::text || ' 15:00:00')::timestamp
              at time zone 'Asia/Seoul';

  v_result_time := (v_result at time zone 'Asia/Seoul')::time;
  if v_result_time >= '23:30'::time or v_result_time < '00:30'::time then
    v_result := ((v_target_date + 1)::text || ' 06:00:00')::timestamp
                at time zone 'Asia/Seoul';
  end if;

  return v_result;
end;
$$;

alter table public.business_calendar enable row level security;
create policy "business_calendar_select_all"
  on public.business_calendar for select
  using (true);
create policy "business_calendar_write_service_role"
  on public.business_calendar for all
  using (auth.role() = 'service_role');
