-- 06. All Functions & Triggers (Pipeline, RPCs, Search)
-- Squashed from: 06_system.sql (functions), 14_party_balance.sql (RPCs), 19_pgroonga_search.sql (RPCs),
--   20_ai_recommendation.sql, 21_geo_distance.sql, 22_bulk_eligibility.sql,
--   24_rls_hardening.sql (RPCs), 26_fix_payment_status.sql (pgmq_send),
--   31_refactor_produce_event.sql, 32_fanout_trigger.sql,
--   33_trigger_event_applications.sql, 34_trigger_events.sql, 35_trigger_verification.sql,
--   36_refactor_reminder_cron.sql
set search_path to public, extensions;

-- ============================================================
-- 1. PGMQ Wrappers
-- ============================================================

create or replace function public.pgmq_read(queue_name text, vt int, "limit" int)
returns setof jsonb 
set search_path = public, extensions, pgmq, temp
as $$
begin
  return query select to_jsonb(msg) from pgmq.read(queue_name, vt, "limit") as msg;
end;
$$ language plpgsql security definer;

create or replace function public.pgmq_delete_batch(queue_name text, msg_ids bigint[])
returns setof bigint 
set search_path = public, extensions, pgmq, temp
as $$
begin
  return query select * from pgmq.delete_batch(queue_name, msg_ids::int8[]);
end;
$$ language plpgsql security definer;

create or replace function public.pgmq_delete(queue_name text, msg_id bigint)
returns boolean 
set search_path = public, extensions, pgmq, temp
as $$
begin
  return pgmq.delete(queue_name, msg_id::int8);
end;
$$ language plpgsql security definer;

create or replace function public.pgmq_pop(queue_name text)
returns setof jsonb 
set search_path = public, extensions, pgmq, temp
as $$
begin
  return query select to_jsonb(msg) from pgmq.pop(queue_name) as msg;
end;
$$ language plpgsql security definer;

create or replace function public.pgmq_send(queue_name text, message jsonb)
returns bigint
language plpgsql
security definer
set search_path = public, extensions, pgmq, temp
as $$
begin
  return pgmq.send(queue_name, message);
end;
$$;

-- ============================================================
-- 2. Event Dispatcher (fan_out_event)
-- ============================================================

create or replace function public.fan_out_event(p_event_type text, p_payload jsonb)
returns void 
set search_path = public, extensions, pgmq, temp
as $$
declare
  route record;
begin
  for route in 
    select target_queue 
    from public.event_routes 
    where event_type::text = p_event_type 
    and is_active = true
  loop
    perform pgmq.send(route.target_queue::text, p_payload);
  end loop;
end;
$$ language plpgsql security definer;

-- ============================================================
-- 3. Event Producer (trigger version — for parties, user_actions)
-- ============================================================

create or replace function public.produce_event()
returns trigger 
set search_path = public, extensions, pgmq, temp
as $$
declare
  event_type text;
  trace_id uuid := gen_random_uuid();
  actor_id uuid := auth.uid();
begin
  if (TG_NARGS > 0) then
    event_type := TG_ARGV[0];
  else
    event_type := 'unknown_' || TG_TABLE_NAME || '_' || lower(TG_OP);
  end if;

  perform public.fan_out_event(
    event_type,
    jsonb_build_object(
      'id', trace_id,
      'type', event_type,
      'meta', jsonb_build_object(
        'occurred_at', extract(epoch from now())::bigint,
        'source', TG_TABLE_NAME,
        'attempt', 1
      ),
      'actor', jsonb_build_object(
        'id', actor_id,
        'role', case 
          when actor_id is null then 'system'
          else 'user'
        end
      ),
      'payload', row_to_json(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

-- Triggers for produce_event (trigger version)
create trigger on_party_created_event
  after insert on public.parties
  for each row execute procedure public.produce_event('party_created');

create trigger on_user_action_event
  after insert on public.user_actions
  for each row execute procedure public.produce_event('user_interaction');

-- ============================================================
-- 4. Event Producer (overloaded void version — for pipeline triggers)
-- ============================================================

CREATE OR REPLACE FUNCTION public.produce_event(
  p_event_type public.event_type_name,
  p_source_table text,
  p_source_id uuid,
  p_row_data jsonb
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
DECLARE
  v_event_id uuid := gen_random_uuid();
BEGIN
  PERFORM pgmq.send(
    'q_global_events',
    jsonb_build_object(
      'event_id', v_event_id,
      'event_type', p_event_type::text,
      'occurred_at', extract(epoch from now())::bigint,
      'schema_version', 1,
      'data', p_row_data,
      'metadata', jsonb_build_object(
        'source_table', p_source_table,
        'source_id', p_source_id
      )
    )
  );

  INSERT INTO public.processed_events (id, processed_at)
  VALUES (v_event_id, now())
  ON CONFLICT (id) DO NOTHING;
END;
$$;

-- ============================================================
-- 5. Fan-out Trigger on q_global_events
-- ============================================================

CREATE OR REPLACE FUNCTION public.fanout_global_event()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
DECLARE
  v_event_type text;
BEGIN
  v_event_type := NEW.message->>'event_type';
  IF v_event_type IS NOT NULL THEN
    PERFORM public.fan_out_event(v_event_type, NEW.message);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_global_event_fanout ON pgmq.q_q_global_events;

CREATE TRIGGER on_global_event_fanout
  AFTER INSERT ON pgmq.q_q_global_events
  FOR EACH ROW EXECUTE FUNCTION public.fanout_global_event();

-- ============================================================
-- 6. Pipeline Triggers (event_applications, events, verification_submissions)
-- ============================================================

-- 6a. Event Applications trigger
CREATE OR REPLACE FUNCTION public.trigger_produce_event_application()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.produce_event(
      'new_application'::public.event_type_name,
      'event_applications',
      NEW.id,
      row_to_json(NEW)::jsonb
    );
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.status = 'approved' AND (OLD.status IS DISTINCT FROM 'approved') THEN
      PERFORM public.produce_event(
        'application_approved'::public.event_type_name,
        'event_applications',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    ELSIF NEW.status = 'rejected' AND (OLD.status IS DISTINCT FROM 'rejected') THEN
      PERFORM public.produce_event(
        'application_rejected'::public.event_type_name,
        'event_applications',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_produce_event_application ON public.event_applications;

CREATE TRIGGER on_produce_event_application
  AFTER INSERT OR UPDATE ON public.event_applications
  FOR EACH ROW EXECUTE FUNCTION public.trigger_produce_event_application();

-- 6b. Events trigger
CREATE OR REPLACE FUNCTION public.trigger_produce_event_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF NEW.status = 'cancelled' AND (OLD.status IS DISTINCT FROM 'cancelled') THEN
      PERFORM public.produce_event(
        'event_cancelled'::public.event_type_name,
        'events',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    ELSIF (
      NEW.title IS DISTINCT FROM OLD.title OR
      NEW.start_time IS DISTINCT FROM OLD.start_time OR
      NEW.location_id IS DISTINCT FROM OLD.location_id
    ) THEN
      PERFORM public.produce_event(
        'event_updated'::public.event_type_name,
        'events',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_produce_event_events ON public.events;

CREATE TRIGGER on_produce_event_events
  AFTER UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.trigger_produce_event_events();

-- 6c. Verification Submissions trigger
CREATE OR REPLACE FUNCTION public.trigger_produce_event_verification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND (OLD.status IS DISTINCT FROM NEW.status) THEN
    IF NEW.status IN ('approved', 'rejected', 'needs_correction') THEN
      PERFORM public.produce_event(
        'verification_result'::public.event_type_name,
        'verification_submissions',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_produce_event_verification ON public.verification_submissions;

CREATE TRIGGER on_produce_event_verification
  AFTER UPDATE ON public.verification_submissions
  FOR EACH ROW EXECUTE FUNCTION public.trigger_produce_event_verification();

-- ============================================================
-- 7. Event Reminder Function (refactored to use produce_event)
-- ============================================================

create or replace function public.send_event_reminders()
returns void
language plpgsql
security definer
set search_path = public, extensions, pgmq, temp
as $$
declare
  participant record;
begin
  for participant in
    select
      ep.id as participant_id,
      ep.user_id,
      e.id as event_id,
      coalesce(e.title, '이벤트') as event_title
    from public.event_participants ep
    join public.events e on e.id = ep.event_id
    where e.start_time between now() + interval '55 minutes' and now() + interval '65 minutes'
      and e.status = 'scheduled'
      and ep.status = 'ticket_issued'
      and ep.reminder_sent_at is null
  loop
    perform public.produce_event(
      'event_reminder'::public.event_type_name,
      'event_participants',
      participant.participant_id,
      jsonb_build_object(
        'user_id', participant.user_id,
        'event_id', participant.event_id,
        'event_title', participant.event_title
      )
    );

    update public.event_participants
    set reminder_sent_at = now()
    where id = participant.participant_id;
  end loop;
end;
$$;

-- ============================================================
-- 8. PGroonga Search RPCs (only if pgroonga extension is available)
-- ============================================================

DO $pgroonga_check$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgroonga') THEN
    EXECUTE $exec$
      CREATE OR REPLACE FUNCTION public.search_events_pgroonga(query text)
      RETURNS SETOF public.events
      LANGUAGE sql STABLE SECURITY INVOKER AS $fn$
        SELECT e.* FROM public.events e
        WHERE query <> '' AND e.title &@~ query LIMIT 20;
      $fn$;
    $exec$;

    EXECUTE $exec$
      CREATE OR REPLACE FUNCTION public.search_parties_pgroonga(query text)
      RETURNS SETOF public.parties
      LANGUAGE sql STABLE SECURITY INVOKER AS $fn$
        SELECT p.* FROM public.parties p
        WHERE query <> '' AND p.title &@~ query LIMIT 20;
      $fn$;
    $exec$;
  ELSE
    RAISE NOTICE 'pgroonga not available, skipping search RPCs';
  END IF;
END $pgroonga_check$;

-- ============================================================
-- 9. Party Balance RPCs
-- ============================================================

create or replace function public.check_party_balance(
  p_event_id uuid,
  p_ticket_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_party_id uuid;
  v_balance_config jsonb;
  v_target_gender public.gender;
  v_ticket_gender public.gender;
  v_tolerance int;
  v_group_counts jsonb := '{}'::jsonb;
  v_target_groups jsonb;
  v_male_count int := 0;
  v_female_count int := 0;
  v_diff int;
begin
  select p.id, p.balance_config
  into v_party_id, v_balance_config
  from public.events e
  join public.parties p on p.id = e.party_id
  where e.id = p_event_id;

  if v_balance_config is null or (v_balance_config->>'enabled')::boolean is not true then
    return jsonb_build_object('allowed', true, 'reason', null);
  end if;

  v_tolerance := coalesce((v_balance_config->>'tolerance')::int, 2);

  select eg.gender
  into v_ticket_gender
  from public.tickets t
  join public.entry_groups eg on eg.id = any(t.target_entry_group_ids)
  where t.id = p_ticket_id
  limit 1;

  if v_ticket_gender is null then
    return jsonb_build_object('allowed', true, 'reason', null);
  end if;

  select 
    coalesce(sum(case when eg.gender = 'male' then 1 else 0 end), 0),
    coalesce(sum(case when eg.gender = 'female' then 1 else 0 end), 0)
  into v_male_count, v_female_count
  from public.event_participants ep
  join public.tickets t on t.id = ep.ticket_id
  join public.entry_groups eg on eg.id = any(t.target_entry_group_ids)
  where ep.event_id = p_event_id;

  if v_ticket_gender = 'male' then
    v_diff := (v_male_count + 1) - v_female_count;
  else
    v_diff := (v_female_count + 1) - v_male_count;
  end if;

  if v_diff > v_tolerance then
    return jsonb_build_object(
      'allowed', false, 
      'reason', '성비 조절 중',
      'gender', v_ticket_gender::text,
      'male_count', v_male_count,
      'female_count', v_female_count,
      'tolerance', v_tolerance
    );
  end if;

  return jsonb_build_object(
    'allowed', true, 
    'reason', null,
    'male_count', v_male_count,
    'female_count', v_female_count
  );
end;
$$;

create or replace function public.get_event_ticket_balance_status(
  p_event_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb := '[]'::jsonb;
  v_ticket record;
  v_check_result jsonb;
begin
  for v_ticket in
    select id, name from public.tickets where event_id = p_event_id
  loop
    v_check_result := public.check_party_balance(p_event_id, v_ticket.id);
    v_result := v_result || jsonb_build_array(
      jsonb_build_object(
        'ticket_id', v_ticket.id,
        'ticket_name', v_ticket.name,
        'allowed', v_check_result->>'allowed',
        'reason', v_check_result->>'reason'
      )
    );
  end loop;

  return v_result;
end;
$$;

-- apply_event (FINAL version with balance check from 14_party_balance.sql)
create or replace function public.apply_event(
  p_event_id uuid,
  p_ticket_id uuid,
  p_user_id uuid,
  p_payment_id text,
  p_payment_amount int,
  p_verification_data jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_app_id uuid;
  v_status text := 'pending_review';
  v_balance_result jsonb;
begin
  v_balance_result := public.check_party_balance(p_event_id, p_ticket_id);
  if (v_balance_result->>'allowed')::boolean is not true then
    raise exception '성비 균형 제한: %', v_balance_result->>'reason'
      using errcode = 'P0001';
  end if;

  if (p_verification_data is null) then
    v_status := 'paid';
  end if;

  insert into public.event_applications (
    event_id, ticket_id, user_id, 
    payment_id, payment_amount, status
  )
  values (
    p_event_id, p_ticket_id, p_user_id,
    p_payment_id, p_payment_amount, v_status
  )
  returning id into v_app_id;

  if (p_verification_data is not null) then
    insert into public.user_verifications (user_id, verification_id, data)
    values (
      p_user_id, 
      (p_verification_data->>'verification_id')::uuid, 
      p_verification_data->'data'
    )
    on conflict (user_id, verification_id) 
    do update set data = excluded.data, updated_at = now();

    insert into public.verification_submissions (
      partner_id, user_id, verification_id, application_id,
      status, snapshot_data
    )
    values (
      (p_verification_data->>'partner_id')::uuid,
      p_user_id,
      (p_verification_data->>'verification_id')::uuid,
      v_app_id,
      'pending',
      p_verification_data->'data'
    );
  end if;

  return v_app_id;
end;
$$;

-- ============================================================
-- 10. AI Recommendation RPC
-- ============================================================

create or replace function public.get_personalized_recommendations(
  p_user_id uuid,
  p_limit int default 10
)
returns table (
  event_id uuid,
  event_title text,
  event_description jsonb,
  event_image_urls text[],
  event_start_time timestamptz,
  event_end_time timestamptz,
  event_status text,
  event_max_participants int,
  event_current_participants int,
  party_id uuid,
  party_title text,
  party_image_urls text[],
  location_id uuid,
  location_name text,
  location_address text,
  location_lat double precision,
  location_lng double precision,
  similarity_score double precision
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user_embedding extensions.vector(1536);
begin
  select ue.embedding into v_user_embedding
  from public.user_embeddings ue
  where ue.user_id = p_user_id;

  if v_user_embedding is null then
    return;
  end if;

  return query
  select
    e.id as event_id,
    e.title as event_title,
    e.description as event_description,
    coalesce(e.image_urls, p.image_urls) as event_image_urls,
    e.start_time as event_start_time,
    e.end_time as event_end_time,
    e.status as event_status,
    e.max_participants as event_max_participants,
    e.current_participants as event_current_participants,
    p.id as party_id,
    p.title as party_title,
    p.image_urls as party_image_urls,
    l.id as location_id,
    l.name as location_name,
    l.address as location_address,
    st_y(l.geo_point::geometry) as location_lat,
    st_x(l.geo_point::geometry) as location_lng,
    1 - (pe.embedding <=> v_user_embedding) as similarity_score
  from public.party_embeddings pe
  join public.parties p on p.id = pe.party_id
  join public.events e on e.party_id = p.id
  left join public.locations l on l.id = coalesce(e.location_id, p.location_id)
  where e.status = 'scheduled'
    and e.start_time >= now()
    and pe.embedding is not null
  order by pe.embedding <=> v_user_embedding asc
  limit p_limit;
end;
$$;

comment on function public.get_personalized_recommendations is
  'Returns personalized event recommendations based on pgvector cosine similarity between user and party embeddings';

-- ============================================================
-- 11. Geo Distance RPC
-- ============================================================

create or replace function public.get_events_within_radius(
  p_lat double precision,
  p_lng double precision,
  p_radius_meters int default 5000,
  p_limit int default 20
)
returns table (
  event_id uuid,
  event_title text,
  event_description jsonb,
  event_image_urls text[],
  event_start_time timestamptz,
  event_end_time timestamptz,
  event_status text,
  event_max_participants int,
  event_current_participants int,
  party_id uuid,
  party_title text,
  party_image_urls text[],
  location_id uuid,
  location_name text,
  location_address text,
  location_lat double precision,
  location_lng double precision,
  distance_meters double precision
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_point geography;
begin
  v_point := st_makepoint(p_lng, p_lat)::geography;

  return query
  select
    e.id as event_id,
    e.title as event_title,
    e.description as event_description,
    coalesce(e.image_urls, p.image_urls) as event_image_urls,
    e.start_time as event_start_time,
    e.end_time as event_end_time,
    e.status as event_status,
    e.max_participants as event_max_participants,
    e.current_participants as event_current_participants,
    p.id as party_id,
    p.title as party_title,
    p.image_urls as party_image_urls,
    l.id as location_id,
    l.name as location_name,
    l.address as location_address,
    st_y(l.geo_point::geometry) as location_lat,
    st_x(l.geo_point::geometry) as location_lng,
    st_distance(l.geo_point, v_point) as distance_meters
  from public.events e
  join public.parties p on p.id = e.party_id
  join public.locations l on l.id = coalesce(e.location_id, p.location_id)
  where e.status = 'scheduled'
    and e.start_time >= now()
    and l.geo_point is not null
    and st_dwithin(l.geo_point, v_point, p_radius_meters)
  order by st_distance(l.geo_point, v_point) asc
  limit p_limit;
end;
$$;

-- ============================================================
-- 12. Bulk Eligibility RPC
-- ============================================================

create or replace function public.get_bulk_eligibility_data(
  p_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile jsonb;
  v_verifications jsonb;
begin
  select jsonb_build_object(
    'gender', up.gender,
    'birth_year', extract(year from up.birth_date)::int,
    'is_verified', up.is_verified
  ) into v_profile
  from public.user_profiles up
  where up.id = p_user_id;

  if v_profile is null then
    return jsonb_build_object(
      'user_profile', null,
      'approved_verifications', '[]'::jsonb
    );
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'partner_id', pvu.partner_id,
      'verification_id', pvu.verification_id,
      'verified_at', pvu.verified_at,
      'valid_until', pvu.valid_until
    )
  ), '[]'::jsonb) into v_verifications
  from public.partner_verified_users pvu
  where pvu.user_id = p_user_id
    and (pvu.valid_until is null or pvu.valid_until > now());

  return jsonb_build_object(
    'user_profile', v_profile,
    'approved_verifications', v_verifications
  );
end;
$$;

-- ============================================================
-- 13. Security Definer RPCs (from 24_rls_hardening.sql)
-- ============================================================

-- RPC 1: get_matched_user_info
CREATE OR REPLACE FUNCTION public.get_matched_user_info(
  p_target_user_id uuid,
  p_target_event_id uuid
)
RETURNS TABLE(user_name text, profile_image_url text, phone_number text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.match_pairs
    WHERE event_id = p_target_event_id
      AND (
        (user_lower_id = auth.uid() AND user_higher_id = p_target_user_id) OR
        (user_lower_id = p_target_user_id AND user_higher_id = auth.uid())
      )
  ) THEN
    RETURN QUERY
      SELECT up.name, up.profile_image_url, up.phone_number
      FROM public.user_profiles up
      WHERE up.id = p_target_user_id;
  END IF;
END;
$$;

-- RPC 2: get_event_applications_with_user
CREATE OR REPLACE FUNCTION public.get_event_applications_with_user(p_event_id uuid)
RETURNS TABLE(
  application_id uuid, event_id uuid, ticket_id uuid, user_id uuid,
  payment_id text, payment_amount int, status text,
  created_at timestamptz, updated_at timestamptz,
  user_name text, user_phone text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.events e
    JOIN public.parties p ON p.id = e.party_id
    WHERE e.id = p_event_id
      AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
  ) THEN
    RETURN QUERY
      SELECT ea.id, ea.event_id, ea.ticket_id, ea.user_id,
             ea.payment_id, ea.payment_amount, ea.status,
             ea.created_at, ea.updated_at,
             up.name, up.phone_number
      FROM public.event_applications ea
      LEFT JOIN public.user_profiles up ON up.id = ea.user_id
      WHERE ea.event_id = p_event_id
      ORDER BY ea.created_at DESC;
  END IF;
END;
$$;

-- RPC 3: get_partner_members_with_user
CREATE OR REPLACE FUNCTION public.get_partner_members_with_user(p_partner_id uuid)
RETURNS TABLE(
  user_id uuid, partner_id uuid, role text, permissions text[],
  joined_at timestamptz, user_name text, user_profile_image text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.has_partner_permission(p_partner_id, 'MEMBER_MANAGE')
     OR EXISTS (
       SELECT 1 FROM public.partner_member_permissions
       WHERE partner_id = p_partner_id AND user_id = auth.uid()
     )
  THEN
    RETURN QUERY
      SELECT pmp.user_id, pmp.partner_id, pmp.role, pmp.permissions,
             pmp.joined_at, up.name, up.profile_image_url
      FROM public.partner_member_permissions pmp
      LEFT JOIN public.user_profiles up ON up.id = pmp.user_id
      WHERE pmp.partner_id = p_partner_id
      ORDER BY pmp.joined_at;
  END IF;
END;
$$;

-- RPC 4: get_pending_verification_requests_with_user
CREATE OR REPLACE FUNCTION public.get_pending_verification_requests_with_user(p_partner_id uuid)
RETURNS TABLE(
  submission_id uuid, partner_id uuid, user_id uuid,
  verification_id uuid, application_id uuid, status text,
  snapshot_data jsonb, created_at timestamptz, user_name text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.has_partner_permission(p_partner_id, 'VERIFY_LIST_VIEW') THEN
    RETURN QUERY
      SELECT vs.id, vs.partner_id, vs.user_id,
             vs.verification_id, vs.application_id, vs.status,
             vs.snapshot_data, vs.created_at, up.name
      FROM public.verification_submissions vs
      LEFT JOIN public.user_profiles up ON up.id = vs.user_id
      WHERE vs.partner_id = p_partner_id
        AND vs.status = 'pending'
      ORDER BY vs.created_at;
  END IF;
END;
$$;
