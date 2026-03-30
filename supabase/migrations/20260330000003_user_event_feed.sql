-- Add remaining_slots generated column and user_event_feed RPC function
-- for server-side feed sorting/filtering (#614)

-- 1. remaining_slots generated column
ALTER TABLE public.events ADD COLUMN remaining_slots int
  GENERATED ALWAYS AS (max_participants - current_participants) STORED;

CREATE INDEX idx_events_remaining_slots ON public.events(remaining_slots, start_time, id);

-- 2. user_event_feed RPC function
-- Supports keyset cursor pagination, multiple sort modes, and optional filters.
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
      -- Base filters
      e.status = 'scheduled'
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

-- Grant execute to authenticated and anon roles
GRANT EXECUTE ON FUNCTION public.user_event_feed TO authenticated, anon;
