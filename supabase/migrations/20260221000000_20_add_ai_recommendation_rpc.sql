-- 20. AI Recommendation RPC Function
-- Returns personalized event recommendations using pgvector cosine similarity
set search_path to public, extensions;

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
  -- 1. Get user's embedding vector
  select ue.embedding into v_user_embedding
  from public.user_embeddings ue
  where ue.user_id = p_user_id;

  -- If user has no embedding, return empty
  if v_user_embedding is null then
    return;
  end if;

  -- 2. Find events whose party embeddings are most similar to user embedding
  -- Uses pgvector cosine distance operator (<=>)
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
