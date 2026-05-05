-- Fix #2118: Partners cannot read applicant user profiles due to self-only RLS.
-- Adds a SELECT policy that allows partner staff with PARTY_MANAGE permission
-- to read user_profiles of users who applied to their events.
--
-- Pattern mirrors "Partner staff can view applications" on event_applications.

set search_path to public, extensions;

create policy "Partners can read applicant profiles" on public.user_profiles
  for select using (
    exists (
      select 1 from public.event_applications ea
      join public.events e on e.id = ea.event_id
      join public.parties p on p.id = e.party_id
      where ea.user_id = user_profiles.id
        and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
