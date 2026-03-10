ALTER TYPE public.social_interaction_type ADD VALUE IF NOT EXISTS 'report';

-- ============================================================
-- report_details table
-- ============================================================

CREATE TABLE public.report_details (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_id uuid NOT NULL,
  target_type public.social_target_type NOT NULL,
  reason text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.report_details ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own reports" ON public.report_details FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own reports" ON public.report_details FOR SELECT TO authenticated USING (auth.uid() = user_id);
GRANT SELECT, INSERT ON public.report_details TO authenticated;

-- ============================================================
-- search_events_pgroonga: add block filter
-- ============================================================

CREATE OR REPLACE FUNCTION public.search_events_pgroonga(query text)
RETURNS SETOF public.events
LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT e.* FROM public.events e
  JOIN public.parties p ON e.party_id = p.id
  WHERE query <> ''
    AND p.title &@~ query
    AND e.status = 'scheduled'
    AND e.start_time >= now()
    AND NOT EXISTS (SELECT 1 FROM public.social_interactions si WHERE si.user_id = auth.uid() AND si.target_id = p.partner_id AND si.interaction_type = 'block')
  ORDER BY e.start_time ASC
  LIMIT 20;
$$;

-- ============================================================
-- search_parties_pgroonga: add block filter
-- ============================================================

CREATE OR REPLACE FUNCTION public.search_parties_pgroonga(query text)
RETURNS SETOF public.parties
LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT p.* FROM public.parties p
  WHERE query <> ''
    AND p.title &@~ query
    AND NOT EXISTS (SELECT 1 FROM public.social_interactions si WHERE si.user_id = auth.uid() AND si.target_id = p.partner_id AND si.interaction_type = 'block')
  LIMIT 20;
$$;

-- ============================================================
-- get_personalized_recommendations: add block filter
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
    and not exists (select 1 from public.social_interactions si where si.user_id = p_user_id and si.target_id = p.partner_id and si.interaction_type = 'block')
  order by pe.embedding <=> v_user_embedding asc
  limit p_limit;
end;
$$;

comment on function public.get_personalized_recommendations is
  'Returns personalized event recommendations based on pgvector cosine similarity between user and party embeddings';

-- ============================================================
-- get_events_within_radius: add p_user_id + block filter
-- ============================================================

create or replace function public.get_events_within_radius(
  p_lat double precision,
  p_lng double precision,
  p_radius_meters int default 5000,
  p_limit int default 20,
  p_user_id uuid default null
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
    and (p_user_id is null or not exists (select 1 from public.social_interactions si where si.user_id = p_user_id and si.target_id = p.partner_id and si.interaction_type = 'block'))
  order by st_distance(l.geo_point, v_point) asc
  limit p_limit;
end;
$$;
