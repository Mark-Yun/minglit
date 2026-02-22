-- 23. GRANTS: PostgreSQL role-level permissions for PostgREST (anon/authenticated)
-- RLS policies define row-level access, but GRANT defines table-level access.
-- Without GRANT, even rows passing RLS are blocked with 42501 (permission denied).
set search_path to public, extensions;

grant usage on schema public to anon, authenticated;

-- ============================================================
-- 1. ANON READ (pre-login CUJ: event list + event detail)
-- ============================================================

grant select on public.events to anon, authenticated;
grant select on public.parties to anon, authenticated;
grant select on public.partners to anon, authenticated;
grant select on public.locations to anon, authenticated;
grant select on public.entry_groups to anon, authenticated;
grant select on public.tickets to anon, authenticated;

-- ============================================================
-- 1b. AUTHENTICATED-ONLY READ (login required)
-- ============================================================

grant select on public.user_profiles to authenticated;
grant select on public.verifications to authenticated;
grant select on public.entry_group_templates to authenticated;
grant select on public.ticket_templates to authenticated;
grant select on public.social_interactions to authenticated;
grant select on public.match_rules to authenticated;

-- ============================================================
-- 2. AUTHENTICATED USER TABLES (per-user RLS gated)
-- ============================================================

-- user_profiles: users can update own profile
grant update on public.user_profiles to authenticated;

-- partner_member_permissions: users can read own/admin can read team
grant select on public.partner_member_permissions to authenticated;

-- partner_applications: users can read/create own applications
grant select, insert on public.partner_applications to authenticated;

-- event_applications: users can read/create/update own + partner staff can read
grant select, insert, update on public.event_applications to authenticated;

-- event_participants: users can read own participation
grant select on public.event_participants to authenticated;

-- user_verifications: users have full control over own verifications
grant select, insert, update, delete on public.user_verifications to authenticated;

-- verification_submissions: users can read/create own + partner staff can read/update
grant select, insert, update on public.verification_submissions to authenticated;

-- partner_verified_users: users can read own verified status
grant select on public.partner_verified_users to authenticated;

-- social_interactions: users can manage own interactions (like, subscribe, bookmark, block)
grant select, insert, update, delete on public.social_interactions to authenticated;

-- match_votes: users can read own votes + cast new votes
grant select, insert on public.match_votes to authenticated;

-- match_pairs: users can read own matches
grant select on public.match_pairs to authenticated;

-- user_notifications: users can read + mark as read
grant select, update on public.user_notifications to authenticated;

-- fcm_tokens: users can manage own device tokens
grant select, insert, update, delete on public.fcm_tokens to authenticated;

-- user_settings: users can manage own settings
grant select, insert, update on public.user_settings to authenticated;

-- minglit_files: users can read own + granted files
grant select on public.minglit_files to authenticated;

-- file_access_grants: users can read own grants
grant select on public.file_access_grants to authenticated;

-- verification_comments: partner staff can read + create comments
grant select, insert on public.verification_comments to authenticated;

-- ============================================================
-- 3. PARTNER ADMIN TABLES (RLS gated by has_partner_permission)
-- All write operations go through authenticated role, RLS ensures
-- only users with correct partner permissions can modify.
-- ============================================================

grant insert, update, delete on public.partners to authenticated;
grant insert, update, delete on public.locations to authenticated;
grant insert, update, delete on public.verifications to authenticated;
grant insert, update, delete on public.parties to authenticated;
grant insert, update, delete on public.events to authenticated;
grant insert, update, delete on public.ticket_templates to authenticated;
grant insert, update, delete on public.entry_group_templates to authenticated;
grant insert, update, delete on public.entry_groups to authenticated;
grant insert, update, delete on public.tickets to authenticated;

-- settlements: partner can read own (gated by has_partner_permission)
grant select on public.settlements to authenticated;

-- match_rules: partner admin can manage match rules for their events
grant insert, update, delete on public.match_rules to authenticated;

-- ============================================================
-- 4. VIEWS
-- ============================================================

grant select on public.locations_view to anon, authenticated;
grant select on public.partner_revenue_stats to authenticated;
grant select on public.partner_monthly_revenue to authenticated;
grant select on public.my_matches_view to authenticated;

-- ============================================================
-- 5. SEQUENCES (needed for client-side gen_random_uuid() in inserts)
-- ============================================================

grant usage on all sequences in schema public to anon, authenticated;

-- ============================================================
-- 6. RPC FUNCTIONS
-- SECURITY DEFINER functions (apply_event, check_party_balance, etc.)
-- run as owner and bypass grants — no extra grants needed.
-- SECURITY INVOKER functions (search_events_pgroonga, search_parties_pgroonga)
-- use caller's role — they need SELECT on events/parties (already granted above).
-- ============================================================
