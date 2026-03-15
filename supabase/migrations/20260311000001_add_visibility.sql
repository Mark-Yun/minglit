-- Section 1: Add visibility columns
ALTER TABLE public.parties
  ADD COLUMN IF NOT EXISTS visibility text NOT NULL DEFAULT 'public'
  CHECK (visibility IN ('public', 'private'));

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS visibility text DEFAULT NULL
  CHECK (visibility IS NULL OR visibility IN ('public', 'private'));

-- Section 2: Replace search_parties_pgroonga
CREATE OR REPLACE FUNCTION public.search_parties_pgroonga(query text)
RETURNS SETOF public.parties
LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT p.* FROM public.parties p
  WHERE query <> ''
    AND p.title &@~ query
    AND p.visibility = 'public'
  LIMIT 20;
$$;

-- Section 3: Replace search_events_pgroonga
CREATE OR REPLACE FUNCTION public.search_events_pgroonga(query text)
RETURNS SETOF public.events
LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT e.* FROM public.events e
  JOIN public.parties p ON e.party_id = p.id
  WHERE query <> ''
    AND p.title &@~ query
    AND e.status = 'scheduled'
    AND e.start_time >= now()
    AND COALESCE(e.visibility, p.visibility) = 'public'
  ORDER BY e.start_time ASC
  LIMIT 20;
$$;

-- Section 4: Replace get_personalized_recommendations
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
    and p.visibility = 'public'
  order by pe.embedding <=> v_user_embedding asc
  limit p_limit;
end;
$$;

-- Section 5: Replace get_events_within_radius
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
    and p.visibility = 'public'
    and COALESCE(e.visibility, p.visibility) = 'public'
  order by st_distance(l.geo_point, v_point) asc
  limit p_limit;
end;
$$;
