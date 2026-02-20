-- 21. Geographic Distance Filter RPC Function
set search_path to public, extensions;

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
