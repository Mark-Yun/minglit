-- Fix #998: Event State Machine Extension
-- Extends events.status from 3 states (scheduled, cancelled, completed)
-- to 5 states (scheduled, active, ongoing, cancelled, completed).
--
-- State transitions:
--   scheduled → active   (cron: activate-upcoming-events, every minute, start_time - 30min reached)
--   scheduled → cancelled (manual, partner action)
--   active    → ongoing  (cron: start-active-events, every minute, start_time reached)
--   active    → cancelled (manual, partner action)
--   ongoing   → completed (cron: auto-complete-past-events, every 15min, end_time reached)

set search_path to public, extensions;

-- ============================================================
-- Section 1: ALTER check constraint on events.status
-- Fix #998: Drop old 3-state constraint and add new 5-state constraint.
-- ============================================================

ALTER TABLE public.events
  DROP CONSTRAINT IF EXISTS events_status_check;

ALTER TABLE public.events
  ADD CONSTRAINT events_status_check
  CHECK (status IN ('scheduled', 'active', 'ongoing', 'cancelled', 'completed'));

-- ============================================================
-- Section 2: Data migration — backfill existing scheduled events
-- Fix #998: Backfill in priority order:
--   1. ongoing: start_time <= now AND end_time > now (event has started, still running)
--   2. active: start_time - 30min <= now AND start_time > now (within check-in window)
--   3. completed: end_time <= now (event has ended, never transitioned)
-- ============================================================

-- Fix #998: Events that have actually started (start_time <= now) and are
-- still running → 'ongoing'. Run this first so that events within the 30-min
-- window but already past start_time are correctly set to 'ongoing'.
UPDATE public.events
SET status = 'ongoing', updated_at = now()
WHERE status = 'scheduled'
  AND start_time <= now()
  AND end_time > now();

-- Fix #998: Events approaching start (within 30 min window, not yet started)
-- → 'active'. Run after ongoing backfill to avoid promoting already-started
-- events to 'active'.
UPDATE public.events
SET status = 'active', updated_at = now()
WHERE status = 'scheduled'
  AND start_time - interval '30 minutes' <= now()
  AND start_time > now();

-- Fix #998: Events that were 'scheduled' but have already ended
-- must be moved to 'completed' to avoid being permanently stuck.
UPDATE public.events
SET status = 'completed', updated_at = now()
WHERE status = 'scheduled'
  AND end_time <= now();

-- ============================================================
-- Section 3: Modify cron 'auto-complete-past-events'
-- Fix #998: Cron previously completed events at 'scheduled'; now
-- events only reach end_time after passing through 'ongoing'.
-- Change WHERE clause from status = 'scheduled' to status = 'ongoing'.
-- ============================================================

SELECT cron.unschedule('auto-complete-past-events');

SELECT cron.schedule(
  'auto-complete-past-events',
  '*/15 * * * *',
  $$
    UPDATE public.events
    SET status = 'completed', updated_at = now()
    WHERE status = 'ongoing'
      AND end_time < now();
  $$
);

-- ============================================================
-- Section 4: New cron 'activate-upcoming-events'
-- Fix #998: Transition scheduled → active 30 minutes before start_time
-- (check-in window opens). Runs every minute.
-- ============================================================

SELECT cron.unschedule('activate-upcoming-events');

SELECT cron.schedule(
  'activate-upcoming-events',
  '* * * * *',
  $$
    UPDATE public.events
    SET status = 'active', updated_at = now()
    WHERE status = 'scheduled'
      AND start_time - interval '30 minutes' <= now();
  $$
);

-- ============================================================
-- Section 5: New cron 'start-active-events'
-- Fix #998: Transition active → ongoing when start_time is reached
-- (event actually starts). Runs every minute.
-- ============================================================

SELECT cron.unschedule('start-active-events');

SELECT cron.schedule(
  'start-active-events',
  '* * * * *',
  $$
    UPDATE public.events
    SET status = 'ongoing', updated_at = now()
    WHERE status = 'active'
      AND start_time <= now();
  $$
);

-- ============================================================
-- Section 6: Redefine trigger_produce_event_events()
-- Fix #998: Add active → cancelled case alongside scheduled → cancelled.
-- Partners can cancel an event that is still active (not yet ongoing).
-- ============================================================

CREATE OR REPLACE FUNCTION public.trigger_produce_event_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF NEW.status = 'cancelled' AND (OLD.status IS DISTINCT FROM 'cancelled') THEN
      -- Fix #998: fire event_cancelled for both scheduled → cancelled and active → cancelled
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

-- ============================================================
-- Section 7a: Redefine search_events_pgroonga()
-- Fix #998: Include 'active' events in search results alongside 'scheduled'.
-- Active events are still open for applications and visible in feed/search.
-- Source: 20260316000001_restore_block_filter_search.sql (latest version).
-- ============================================================

CREATE OR REPLACE FUNCTION public.search_events_pgroonga(query text)
RETURNS SETOF public.events
LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT e.* FROM public.events e
  JOIN public.parties p ON e.party_id = p.id
  WHERE query <> ''
    AND p.title &@~ query
    AND e.status IN ('scheduled', 'active')
    AND e.start_time >= now()
    AND COALESCE(e.visibility, p.visibility) = 'public'
    AND NOT EXISTS (SELECT 1 FROM public.social_interactions si WHERE si.user_id = auth.uid() AND si.target_id = p.partner_id AND si.interaction_type = 'block')
  ORDER BY e.start_time ASC
  LIMIT 20;
$$;

-- ============================================================
-- Section 7b: Redefine get_personalized_recommendations()
-- Fix #998: Include 'active' events in recommendations alongside 'scheduled'.
-- Source: 20260311000001_add_visibility.sql (latest version with visibility filter).
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_personalized_recommendations(
  p_user_id uuid,
  p_limit int default 10
)
RETURNS TABLE (
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
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_embedding extensions.vector(1536);
BEGIN
  SELECT ue.embedding INTO v_user_embedding
  FROM public.user_embeddings ue
  WHERE ue.user_id = p_user_id;

  IF v_user_embedding IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    e.id AS event_id,
    e.title AS event_title,
    e.description AS event_description,
    coalesce(e.image_urls, p.image_urls) AS event_image_urls,
    e.start_time AS event_start_time,
    e.end_time AS event_end_time,
    e.status AS event_status,
    e.max_participants AS event_max_participants,
    e.current_participants AS event_current_participants,
    p.id AS party_id,
    p.title AS party_title,
    p.image_urls AS party_image_urls,
    l.id AS location_id,
    l.name AS location_name,
    l.address AS location_address,
    st_y(l.geo_point::geometry) AS location_lat,
    st_x(l.geo_point::geometry) AS location_lng,
    1 - (pe.embedding <=> v_user_embedding) AS similarity_score
  FROM public.party_embeddings pe
  JOIN public.parties p ON p.id = pe.party_id
  JOIN public.events e ON e.party_id = p.id
  LEFT JOIN public.locations l ON l.id = coalesce(e.location_id, p.location_id)
  WHERE e.status IN ('scheduled', 'active')
    AND e.start_time >= now()
    AND pe.embedding IS NOT NULL
    AND p.visibility = 'public'
  ORDER BY pe.embedding <=> v_user_embedding ASC
  LIMIT p_limit;
END;
$$;

-- ============================================================
-- Section 7c: Redefine get_user_event_feed() (user_event_feed RPC)
-- Fix #998: Include 'active' events in feed alongside 'scheduled'.
-- Source: 20260330000003_user_event_feed.sql (latest version).
-- ============================================================

CREATE OR REPLACE FUNCTION public.user_event_feed(
  p_user_id uuid DEFAULT NULL,
  p_sort_by text DEFAULT 'recommended',
  p_eligible_only boolean DEFAULT false,
  p_has_remaining_slots boolean DEFAULT false,
  p_lat double precision DEFAULT NULL,
  p_lng double precision DEFAULT NULL,
  p_radius_km double precision DEFAULT NULL,
  p_limit int DEFAULT 20,
  p_cursor_sort_key text DEFAULT NULL,
  p_cursor_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_result jsonb;
  v_point geography;
BEGIN
  -- Validate sort_by
  IF p_sort_by NOT IN ('recommended', 'closing_soon', 'nearest_date') THEN
    RAISE EXCEPTION 'Invalid sort_by: %. Must be one of: recommended, closing_soon, nearest_date', p_sort_by;
  END IF;

  -- Clamp limit
  IF p_limit < 1 THEN p_limit := 1; END IF;
  IF p_limit > 50 THEN p_limit := 50; END IF;

  -- Build geography point for nearby filter
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_point := st_makepoint(p_lng, p_lat)::geography;
  END IF;

  WITH filtered_events AS (
    SELECT
      e.id,
      e.party_id,
      e.title AS event_title,
      e.description AS event_description,
      e.image_urls AS event_image_urls,
      e.contact_options AS event_contact_options,
      e.start_time,
      e.end_time,
      e.min_confirmed_count,
      e.max_participants,
      e.current_participants,
      e.remaining_slots,
      e.status,
      e.visibility AS event_visibility,
      e.created_at,
      e.updated_at,
      -- Party data
      jsonb_build_object(
        'id', p.id,
        'partner_id', p.partner_id,
        'title', p.title,
        'description', p.description,
        'image_urls', p.image_urls,
        'status', p.status,
        'visibility', p.visibility,
        'created_at', p.created_at,
        'updated_at', p.updated_at,
        'contact_options', p.contact_options,
        'required_verification_ids', p.required_verification_ids,
        'min_confirmed_count', p.min_confirmed_count,
        'max_participants', p.max_participants,
        'location', CASE WHEN l.id IS NOT NULL THEN jsonb_build_object(
          'id', l.id,
          'partner_id', l.partner_id,
          'name', l.name,
          'address', l.address,
          'address_detail', l.address_detail,
          'region_1', l.region_1,
          'region_2', l.region_2,
          'region_3', l.region_3,
          'directions_guide', l.directions_guide,
          'postal_code', l.postal_code,
          'created_at', l.created_at,
          'updated_at', l.updated_at
        ) ELSE NULL END,
        'partner', CASE WHEN pr.id IS NOT NULL THEN jsonb_build_object(
          'id', pr.id,
          'name', pr.name,
          'status', pr.status,
          'created_at', pr.created_at,
          'updated_at', pr.updated_at
        ) ELSE NULL END
      ) AS party,
      -- Entry groups as JSON array
      (
        SELECT COALESCE(jsonb_agg(jsonb_build_object(
          'id', eg.id,
          'event_id', eg.event_id,
          'label', eg.label,
          'gender', eg.gender,
          'birth_year_min', eg.birth_year_min,
          'birth_year_max', eg.birth_year_max,
          'required_verification_ids', eg.required_verification_ids,
          'created_at', eg.created_at,
          'updated_at', eg.updated_at
        )), '[]'::jsonb)
        FROM entry_groups eg WHERE eg.event_id = e.id
      ) AS entry_groups,
      -- Tickets as JSON array
      (
        SELECT COALESCE(jsonb_agg(jsonb_build_object(
          'id', t.id,
          'event_id', t.event_id,
          'name', t.name,
          'description', t.description,
          'price', t.price,
          'quantity', t.quantity,
          'sold_count', t.sold_count,
          'target_entry_group_ids', t.target_entry_group_ids,
          'required_verification_ids', t.required_verification_ids,
          'status', t.status,
          'created_at', t.created_at,
          'updated_at', t.updated_at
        )), '[]'::jsonb)
        FROM tickets t WHERE t.event_id = e.id
      ) AS tickets,
      -- Distance in meters (NULL when no location or no user coords)
      CASE
        WHEN v_point IS NOT NULL AND l.geo_point IS NOT NULL
        THEN st_distance(l.geo_point, v_point)
        ELSE NULL
      END AS distance_meters,
      -- Sort keys for cursor pagination
      CASE p_sort_by
        WHEN 'recommended' THEN e.created_at::text
        WHEN 'closing_soon' THEN e.remaining_slots::text || '|' || e.start_time::text
        WHEN 'nearest_date' THEN e.start_time::text
      END AS sort_key
    FROM events e
    JOIN parties p ON p.id = e.party_id
    LEFT JOIN locations l ON l.id = COALESCE(e.location_id, p.location_id)
    LEFT JOIN partners pr ON pr.id = p.partner_id
    WHERE
      -- Fix #998: Include 'active' events alongside 'scheduled' in the feed
      e.status IN ('scheduled', 'active')
      AND e.start_time >= now()
      AND COALESCE(e.visibility, p.visibility) = 'public'
      AND p.status = 'active'
      -- Block filter: exclude blocked partners for authenticated users
      AND (
        p_user_id IS NULL
        OR NOT EXISTS (
          SELECT 1 FROM social_interactions si
          WHERE si.user_id = p_user_id
            AND si.target_id = p.partner_id
            AND si.interaction_type = 'block'
        )
      )
      -- Remaining slots filter
      AND (NOT p_has_remaining_slots OR e.remaining_slots > 0)
      -- Nearby filter (radius in km → meters)
      AND (
        v_point IS NULL
        OR p_radius_km IS NULL
        OR (l.geo_point IS NOT NULL AND st_dwithin(l.geo_point, v_point, p_radius_km * 1000))
      )
      -- Cursor-based pagination
      AND (
        p_cursor_sort_key IS NULL OR p_cursor_id IS NULL
        OR (
          CASE p_sort_by
            -- recommended: ORDER BY created_at DESC, id ASC
            WHEN 'recommended' THEN
              (e.created_at < p_cursor_sort_key::timestamptz)
              OR (e.created_at = p_cursor_sort_key::timestamptz AND e.id > p_cursor_id)
            -- closing_soon: ORDER BY remaining_slots ASC, start_time ASC, id ASC
            WHEN 'closing_soon' THEN
              (e.remaining_slots > split_part(p_cursor_sort_key, '|', 1)::int)
              OR (e.remaining_slots = split_part(p_cursor_sort_key, '|', 1)::int
                  AND e.start_time > split_part(p_cursor_sort_key, '|', 2)::timestamptz)
              OR (e.remaining_slots = split_part(p_cursor_sort_key, '|', 1)::int
                  AND e.start_time = split_part(p_cursor_sort_key, '|', 2)::timestamptz
                  AND e.id > p_cursor_id)
            -- nearest_date: ORDER BY start_time ASC, id ASC
            WHEN 'nearest_date' THEN
              (e.start_time > p_cursor_sort_key::timestamptz)
              OR (e.start_time = p_cursor_sort_key::timestamptz AND e.id > p_cursor_id)
            ELSE true
          END
        )
      )
    ORDER BY
      CASE p_sort_by
        WHEN 'recommended' THEN NULL -- handled below
        WHEN 'closing_soon' THEN NULL
        WHEN 'nearest_date' THEN NULL
      END,
      -- recommended: newest first
      CASE WHEN p_sort_by = 'recommended' THEN e.created_at END DESC NULLS LAST,
      -- closing_soon: fewest remaining slots first, then earliest start
      CASE WHEN p_sort_by = 'closing_soon' THEN e.remaining_slots END ASC NULLS LAST,
      CASE WHEN p_sort_by = 'closing_soon' THEN e.start_time END ASC NULLS LAST,
      -- nearest_date: earliest start first
      CASE WHEN p_sort_by = 'nearest_date' THEN e.start_time END ASC NULLS LAST,
      e.id ASC
    LIMIT p_limit + 1  -- fetch one extra to detect next page
  )
  SELECT jsonb_build_object(
    'events', COALESCE(
      (SELECT jsonb_agg(
        jsonb_build_object(
          'id', fe.id,
          'party_id', fe.party_id,
          'title', fe.event_title,
          'description', fe.event_description,
          'image_urls', fe.event_image_urls,
          'contact_options', fe.event_contact_options,
          'start_time', fe.start_time,
          'end_time', fe.end_time,
          'min_confirmed_count', fe.min_confirmed_count,
          'max_participants', fe.max_participants,
          'current_participants', fe.current_participants,
          'remaining_slots', fe.remaining_slots,
          'status', fe.status,
          'visibility', fe.event_visibility,
          'created_at', fe.created_at,
          'updated_at', fe.updated_at,
          'party', fe.party,
          'entryGroups', fe.entry_groups,
          'tickets', fe.tickets,
          'distance_meters', fe.distance_meters
        )
      ) FROM (SELECT * FROM filtered_events LIMIT p_limit) fe),
      '[]'::jsonb
    ),
    'has_more', (SELECT count(*) > p_limit FROM filtered_events),
    'next_cursor', (
      SELECT jsonb_build_object(
        'sort_key', last_row.sort_key,
        'id', last_row.id
      )
      FROM (SELECT * FROM filtered_events LIMIT p_limit) last_row
      ORDER BY
        CASE WHEN p_sort_by = 'recommended' THEN last_row.created_at END DESC NULLS LAST,
        CASE WHEN p_sort_by = 'closing_soon' THEN last_row.remaining_slots END ASC NULLS LAST,
        CASE WHEN p_sort_by = 'closing_soon' THEN last_row.start_time END ASC NULLS LAST,
        CASE WHEN p_sort_by = 'nearest_date' THEN last_row.start_time END ASC NULLS LAST,
        last_row.id ASC
      LIMIT 1 OFFSET p_limit - 1
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- ============================================================
-- Section 7d: Redefine send_event_reminders()
-- Fix #998: Remind participants for both 'scheduled' and 'active' events.
-- Once activate-upcoming-events cron fires, events near start_time will
-- be 'active', so the reminder must include both statuses.
-- Source: 20260301000006_06_functions_triggers.sql (latest version).
-- ============================================================

CREATE OR REPLACE FUNCTION public.send_event_reminders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
DECLARE
  participant record;
BEGIN
  FOR participant IN
    SELECT
      ep.id AS participant_id,
      ep.user_id,
      e.id AS event_id,
      coalesce(e.title, '이벤트') AS event_title
    FROM public.event_participants ep
    JOIN public.events e ON e.id = ep.event_id
    WHERE e.start_time BETWEEN now() + interval '55 minutes' AND now() + interval '65 minutes'
      AND e.status IN ('scheduled', 'active')
      AND ep.status = 'ticket_issued'
      AND ep.reminder_sent_at IS NULL
  LOOP
    PERFORM public.produce_event(
      'event_reminder'::public.event_type_name,
      'event_participants',
      participant.participant_id,
      jsonb_build_object(
        'user_id', participant.user_id,
        'event_id', participant.event_id,
        'event_title', participant.event_title
      )
    );

    UPDATE public.event_participants
    SET reminder_sent_at = now()
    WHERE id = participant.participant_id;
  END LOOP;
END;
$$;

-- ============================================================
-- Section 7e: Redefine get_events_within_radius()
-- Fix #998: Include 'active' events in radius search alongside 'scheduled'.
-- Active events are still open for applications and visible in nearby search.
-- Source: 20260311000001_add_visibility.sql (latest version with visibility filter).
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_events_within_radius(
  p_lat double precision,
  p_lng double precision,
  p_radius_meters int default 5000,
  p_limit int default 20
)
RETURNS TABLE (
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
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_point geography;
BEGIN
  v_point := st_makepoint(p_lng, p_lat)::geography;

  RETURN QUERY
  SELECT
    e.id AS event_id,
    e.title AS event_title,
    e.description AS event_description,
    COALESCE(e.image_urls, p.image_urls) AS event_image_urls,
    e.start_time AS event_start_time,
    e.end_time AS event_end_time,
    e.status AS event_status,
    e.max_participants AS event_max_participants,
    e.current_participants AS event_current_participants,
    p.id AS party_id,
    p.title AS party_title,
    p.image_urls AS party_image_urls,
    l.id AS location_id,
    l.name AS location_name,
    l.address AS location_address,
    st_y(l.geo_point::geometry) AS location_lat,
    st_x(l.geo_point::geometry) AS location_lng,
    st_distance(l.geo_point, v_point) AS distance_meters
  FROM public.events e
  JOIN public.parties p ON p.id = e.party_id
  JOIN public.locations l ON l.id = COALESCE(e.location_id, p.location_id)
  WHERE e.status IN ('scheduled', 'active')
    AND e.start_time >= now()
    AND l.geo_point IS NOT NULL
    AND st_dwithin(l.geo_point, v_point, p_radius_meters)
    AND p.visibility = 'public'
    AND COALESCE(e.visibility, p.visibility) = 'public'
  ORDER BY st_distance(l.geo_point, v_point) ASC
  LIMIT p_limit;
END;
$$;

-- ============================================================
-- Section 8: Modify apply_event() — add status validation
-- Fix #998: Reject new applications for events that are ongoing,
-- completed, or cancelled. Only 'scheduled' and 'active' allow
-- new ticket purchases.
-- Source: 20260301000006_06_functions_triggers.sql (latest version with balance check).
-- ============================================================

CREATE OR REPLACE FUNCTION public.apply_event(
  p_event_id uuid,
  p_ticket_id uuid,
  p_user_id uuid,
  p_payment_id text,
  p_payment_amount int,
  p_verification_data jsonb DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_app_id uuid;
  v_status text := 'pending_review';
  v_balance_result jsonb;
  v_event_status text;
BEGIN
  -- Fix #998: Validate event status — only 'scheduled' and 'active' allow applications
  SELECT status INTO v_event_status
  FROM public.events
  WHERE id = p_event_id;

  IF v_event_status IS NULL THEN
    RAISE EXCEPTION '존재하지 않는 이벤트입니다.'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_event_status NOT IN ('scheduled', 'active') THEN
    RAISE EXCEPTION '신청 불가 상태의 이벤트입니다: %', v_event_status
      USING ERRCODE = 'P0001';
  END IF;

  v_balance_result := public.check_party_balance(p_event_id, p_ticket_id);
  IF (v_balance_result->>'allowed')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION '성비 균형 제한: %', v_balance_result->>'reason'
      USING ERRCODE = 'P0001';
  END IF;

  IF (p_verification_data IS NULL) THEN
    v_status := 'paid';
  END IF;

  INSERT INTO public.event_applications (
    event_id, ticket_id, user_id,
    payment_id, payment_amount, status
  )
  VALUES (
    p_event_id, p_ticket_id, p_user_id,
    p_payment_id, p_payment_amount, v_status
  )
  RETURNING id INTO v_app_id;

  IF (p_verification_data IS NOT NULL) THEN
    INSERT INTO public.user_verifications (user_id, verification_id, data)
    VALUES (
      p_user_id,
      (p_verification_data->>'verification_id')::uuid,
      p_verification_data->'data'
    )
    ON CONFLICT (user_id, verification_id)
    DO UPDATE SET data = EXCLUDED.data, updated_at = now();

    INSERT INTO public.verification_submissions (
      partner_id, user_id, verification_id, application_id,
      status, snapshot_data
    )
    VALUES (
      (p_verification_data->>'partner_id')::uuid,
      p_user_id,
      (p_verification_data->>'verification_id')::uuid,
      v_app_id,
      'pending',
      p_verification_data->'data'
    );
  END IF;

  RETURN v_app_id;
END;
$$;
