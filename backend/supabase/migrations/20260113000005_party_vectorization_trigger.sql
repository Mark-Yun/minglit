-- Ensure pg_net is enabled
create extension if not exists pg_net with schema extensions;

create or replace function public.trigger_vectorize_party()
returns trigger as $$
declare
  -- Note: In production, this URL should be your project's Edge Function URL.
  -- In local development with Supabase CLI, 'http://kong:8000' routes to Edge Functions.
  edge_function_url text := 'http://kong:8000/functions/v1/vectorize-party'; 
begin
  -- Fire and forget
  perform net.http_post(
    url := edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('request.jwt.claim.sub', true) -- Optional: forward user auth
    ),
    body := jsonb_build_object('record', row_to_json(NEW))
  );
  return NEW;
end;
$$ language plpgsql security definer;

-- Trigger on Parties
create trigger on_party_vectorize
  after insert or update of title, description on public.parties
  for each row execute procedure public.trigger_vectorize_party();
