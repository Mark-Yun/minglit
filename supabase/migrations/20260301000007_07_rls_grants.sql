-- 07. All RLS Policies + GRANT Statements
-- Squashed from: 02_users.sql, 03_partners.sql, 04_events.sql, 05_commerce.sql, 07_social.sql,
--   08_matching.sql, 10_storage_buckets.sql, 11_notifications.sql, 13_file_management.sql,
--   15_settlements.sql, 23_grants.sql, 24_rls_hardening.sql, 38_enable_missing_rls.sql
set search_path to public, extensions;

-- ============================================================
-- PART A: RLS Policies
-- ============================================================

-- ---------------- user_profiles ----------------
-- (24_rls_hardening: self-only, no public read)
create policy "Users can read own profile" on public.user_profiles
  for select using (auth.uid() = id);
create policy "Users can update own profile" on public.user_profiles for update using (auth.uid() = id);

-- ---------------- app_roles ----------------
-- (38_enable_missing_rls)
create policy "super_admin_only" on public.app_roles for all
  using (public.is_super_admin())
  with check (public.is_super_admin());

-- ---------------- partners ----------------
create policy "Public read access" on public.partners for select using (true);
create policy "Admin/Owner partners all access" on public.partners for all 
  using (public.is_super_admin() or public.has_partner_permission(id, 'PARTNER_EDIT'));

-- ---------------- partner_settlements ----------------
-- (38_enable_missing_rls)
create policy "settlement_read" on public.partner_settlements for select
  using (public.has_partner_permission(partner_id, 'SETTLEMENT_VIEW'));
create policy "settlement_write" on public.partner_settlements for update
  using (public.has_partner_permission(partner_id, 'SETTLEMENT_EDIT'))
  with check (public.has_partner_permission(partner_id, 'SETTLEMENT_EDIT'));
create policy "settlement_delete" on public.partner_settlements for delete
  using (public.is_super_admin());

-- ---------------- partner_member_permissions ----------------
-- (from 03_partners.sql + 38_enable_missing_rls)
create policy "Users can read own permissions" on public.partner_member_permissions for select 
  using (auth.uid() = user_id or public.is_super_admin() or public.has_partner_permission(partner_id, 'MEMBER_MANAGE'));
create policy "member_manage_insert" on public.partner_member_permissions for insert
  with check (public.has_partner_permission(partner_id, 'MEMBER_MANAGE'));
create policy "member_manage_update" on public.partner_member_permissions for update
  using (public.has_partner_permission(partner_id, 'MEMBER_MANAGE'))
  with check (public.has_partner_permission(partner_id, 'MEMBER_MANAGE'));
create policy "member_manage_delete" on public.partner_member_permissions for delete
  using (public.has_partner_permission(partner_id, 'MEMBER_MANAGE'));

-- ---------------- partner_applications ----------------
-- (from 03_partners.sql + 38_enable_missing_rls)
create policy "Users can read own applications" on public.partner_applications for select 
  using (auth.uid() = user_id or public.is_super_admin());
create policy "authenticated_can_apply" on public.partner_applications for insert
  to authenticated
  with check (auth.uid() = user_id);
create policy "admin_update_applications" on public.partner_applications for update
  using (public.is_super_admin())
  with check (public.is_super_admin());
create policy "admin_delete_applications" on public.partner_applications for delete
  using (public.is_super_admin());

-- ---------------- locations ----------------
create policy "Public read access" on public.locations for select using (true);
create policy "Admin/Owner locations all access" on public.locations for all 
  using (public.is_super_admin() or public.has_partner_permission(partner_id, 'PARTY_MANAGE'));

-- ---------------- verifications ----------------
create policy "Public read access" on public.verifications for select using (true);
create policy "Admin/Owner verifications all access" on public.verifications for all 
  using (
    public.is_super_admin() or 
    (partner_id is not null and public.has_partner_permission(partner_id, 'PARTNER_EDIT'))
  );

-- ---------------- parties ----------------
create policy "Public read access" on public.parties for select using (true);
create policy "Admin/Owner parties all access" on public.parties for all 
  using (public.is_super_admin() or public.has_partner_permission(partner_id, 'PARTY_MANAGE'));

-- ---------------- events ----------------
create policy "Public read access" on public.events for select using (true);
create policy "Admin/Owner events all access" on public.events for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.parties p
      where p.id = party_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

-- ---------------- entry_group_templates ----------------
create policy "Public read access" on public.entry_group_templates for select using (true);
create policy "Admin/Owner entry_group_templates all access" on public.entry_group_templates for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.parties p
      where p.id = party_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

-- ---------------- entry_groups ----------------
create policy "Public read access" on public.entry_groups for select using (true);
create policy "Admin/Owner entry_groups all access" on public.entry_groups for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.events e
      join public.parties p on p.id = e.party_id
      where e.id = event_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

-- ---------------- ticket_templates ----------------
create policy "Public read access" on public.ticket_templates for select using (true);
create policy "Admin/Owner ticket_templates all access" on public.ticket_templates for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.parties p
      where p.id = party_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

-- ---------------- tickets ----------------
create policy "Public read access" on public.tickets for select using (true);
create policy "Admin/Owner tickets all access" on public.tickets for all 
  using (
    public.is_super_admin() or 
    exists (
      select 1 from public.events e
      join public.parties p on p.id = e.party_id
      where e.id = event_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

-- ---------------- event_applications ----------------
create policy "Users can read own applications" on public.event_applications for select 
  using (auth.uid() = user_id);
create policy "Users can create own applications" on public.event_applications for insert 
  with check (auth.uid() = user_id);
create policy "Users can update own applications" on public.event_applications for update 
  using (auth.uid() = user_id);
create policy "Partner staff can view applications" on public.event_applications for select
  using (
    exists (
      select 1 from public.events e
      join public.parties p on p.id = e.party_id
      where e.id = event_id
      and public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

-- ---------------- event_participants ----------------
-- (24_rls_hardening: open to all authenticated)
create policy "Authenticated users can read all participants" on public.event_participants
  for select using (auth.role() = 'authenticated');

-- ---------------- verification_submissions ----------------
create policy "Users can read own submissions" on public.verification_submissions for select 
  using (auth.uid() = user_id);
create policy "Users can create own submissions" on public.verification_submissions for insert 
  with check (auth.uid() = user_id);
create policy "Partner staff can view submissions" on public.verification_submissions for select
  using (public.has_partner_permission(partner_id, 'VERIFY_LIST_VIEW'));
create policy "Partner staff can update submissions" on public.verification_submissions for update
  using (public.has_partner_permission(partner_id, 'VERIFY_REVIEW'));

-- ---------------- user_verifications ----------------
create policy "Users can read/write own verifications" on public.user_verifications for all
  using (auth.uid() = user_id);

-- ---------------- partner_verified_users ----------------
create policy "Users can read own verified status" on public.partner_verified_users for select 
  using (auth.uid() = user_id);

-- ---------------- verification_comments ----------------
-- (38_enable_missing_rls)
create policy "comments_read" on public.verification_comments for select
  using (
    public.is_super_admin() or
    author_id = auth.uid() or
    exists (
      select 1 from public.verification_submissions vs
      where vs.id = submission_id and vs.user_id = auth.uid()
    ) or
    exists (
      select 1 from public.verification_submissions vs
      where vs.id = submission_id
      and public.has_partner_permission(vs.partner_id, 'VERIFY_REVIEW')
    )
  );
create policy "comments_insert" on public.verification_comments for insert
  with check (
    public.is_super_admin() or
    exists (
      select 1 from public.verification_submissions vs
      where vs.id = submission_id
      and public.has_partner_permission(vs.partner_id, 'VERIFY_REVIEW')
    )
  );
create policy "comments_update" on public.verification_comments for update
  using (public.is_super_admin() or author_id = auth.uid())
  with check (public.is_super_admin() or author_id = auth.uid());
create policy "comments_delete" on public.verification_comments for delete
  using (public.is_super_admin());

-- ---------------- social_interactions ----------------
-- (24_rls_hardening: self-only SELECT + ALL for write)
create policy "Users can view own interactions" on public.social_interactions
  for select using (auth.uid() = user_id);
create policy "Users can manage own interactions" on public.social_interactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------- match_rules ----------------
create policy "Anyone can read match rules" on public.match_rules for select using (true);

-- ---------------- match_votes ----------------
create policy "Users can read own votes" on public.match_votes for select
  using (auth.uid() = voter_id);
create policy "Users can cast votes" on public.match_votes for insert
  with check (auth.uid() = voter_id);

-- ---------------- match_pairs ----------------
create policy "Users can see own matches" on public.match_pairs for select
  using (auth.uid() = user_lower_id or auth.uid() = user_higher_id);

-- ---------------- user_notifications ----------------
create policy "Users can view their own notifications" on public.user_notifications
  for select using (auth.uid() = user_id);
create policy "Users can update their own notifications" on public.user_notifications
  for update using (auth.uid() = user_id);
create policy "Service role can insert notifications" on public.user_notifications
  for insert with check (true);

-- ---------------- fcm_tokens ----------------
create policy "Users can view their own FCM tokens" on public.fcm_tokens
  for select using (auth.uid() = user_id);
create policy "Users can insert/update their own FCM tokens" on public.fcm_tokens
  for insert with check (auth.uid() = user_id);
create policy "Users can delete their own FCM tokens" on public.fcm_tokens
  for delete using (auth.uid() = user_id);

-- ---------------- user_settings ----------------
create policy "Users can view their own settings" on public.user_settings
  for select using (auth.uid() = user_id);
create policy "Users can update their own settings" on public.user_settings
  for update using (auth.uid() = user_id);
create policy "Users can insert their own settings" on public.user_settings
  for insert with check (auth.uid() = user_id);

-- ---------------- minglit_files ----------------
create policy "Users can view own files" on public.minglit_files for select
  using (auth.uid() = owner_id);
create policy "Users can view granted files" on public.minglit_files for select
  using (
    exists (
      select 1 from public.file_access_grants
      where file_id = minglit_files.id
      and viewer_id = auth.uid()
      and (expires_at is null or expires_at > now())
    )
  );

-- ---------------- file_access_grants ----------------
create policy "Viewers can see their grants" on public.file_access_grants for select
  using (viewer_id = auth.uid());

-- ---------------- settlements ----------------
create policy "Partner can read own settlements" on public.settlements for select
  using (
    public.is_super_admin() or public.has_partner_permission(partner_id, 'SETTLEMENT_VIEW')
  );

-- ---------------- debug_logs ----------------
-- (38_enable_missing_rls)
create policy "service_role_all" on public.debug_logs for all
  using (current_setting('role') = 'service_role')
  with check (current_setting('role') = 'service_role');

-- ---------------- storage.objects ----------------
-- verification-proofs
create policy "Users can upload own verification proofs" on storage.objects for insert
  with check (
    bucket_id = 'verification-proofs' 
    and (storage.foldername(name))[1] = (auth.uid())::text
  );
create policy "Users can view own verification proofs" on storage.objects for select
  using (
    bucket_id = 'verification-proofs' 
    and (storage.foldername(name))[1] = (auth.uid())::text
  );
create policy "Granted users can view verification proofs" on storage.objects for select
  using (
    bucket_id = 'verification-proofs'
    and exists (
      select 1 from public.minglit_files f
      join public.file_access_grants g on f.id = g.file_id
      where f.storage_object_id = storage.objects.id
      and g.viewer_id = auth.uid()
      and (g.expires_at is null or g.expires_at > now())
    )
  );
create policy "Admins and partners can view all proofs" on storage.objects for select
  using (
    bucket_id = 'verification-proofs'
    and (
      exists (
        select 1 from public.app_roles
        where user_id = auth.uid() and role in ('super_admin', 'moderator')
      )
      or
      exists (
        select 1 from public.partner_member_permissions
        where user_id = auth.uid()
      )
    )
  );

-- party-assets
create policy "Partners can upload party assets" on storage.objects for insert
  with check (
    bucket_id = 'party-assets' 
    and auth.role() = 'authenticated'
  );
create policy "Public can view party assets" on storage.objects for select
  using ( bucket_id = 'party-assets' );

-- partner-proofs
create policy "Partners can upload own proofs" on storage.objects for insert
  with check (
    bucket_id = 'partner-proofs' 
    and (storage.foldername(name))[1] = (auth.uid())::text
  );
create policy "Partners can view own proofs" on storage.objects for select
  using (
    bucket_id = 'partner-proofs' 
    and (storage.foldername(name))[1] = (auth.uid())::text
  );
create policy "Admins can view partner proofs" on storage.objects for select
  using (
    bucket_id = 'partner-proofs'
    and exists (
      select 1 from public.app_roles
      where user_id = auth.uid() and role in ('super_admin', 'moderator')
    )
  );

-- ============================================================
-- PART B: GRANT Statements (from 23_grants.sql + 24_rls_hardening.sql + 06_system.sql)
-- ============================================================

grant usage on schema public to anon, authenticated;

-- 1. ANON + AUTHENTICATED READ
grant select on public.events to anon, authenticated;
grant select on public.parties to anon, authenticated;
grant select on public.partners to anon, authenticated;
grant select on public.locations to anon, authenticated;
grant select on public.entry_groups to anon, authenticated;
grant select on public.tickets to anon, authenticated;
grant select on public.verifications to anon, authenticated;

-- 1b. AUTHENTICATED-ONLY READ
grant select on public.user_profiles to authenticated;
grant select on public.entry_group_templates to authenticated;
grant select on public.ticket_templates to authenticated;
grant select on public.social_interactions to authenticated;
grant select on public.match_rules to authenticated;

-- 2. AUTHENTICATED USER TABLES
grant update on public.user_profiles to authenticated;
grant select on public.partner_member_permissions to authenticated;
grant select, insert on public.partner_applications to authenticated;
grant select, insert, update on public.event_applications to authenticated;
grant select on public.event_participants to authenticated;
grant select, insert, update, delete on public.user_verifications to authenticated;
grant select, insert, update on public.verification_submissions to authenticated;
grant select on public.partner_verified_users to authenticated;
grant select, insert, update, delete on public.social_interactions to authenticated;
grant select, insert on public.match_votes to authenticated;
grant select on public.match_pairs to authenticated;
grant select, update on public.user_notifications to authenticated;
grant select, insert, update, delete on public.fcm_tokens to authenticated;
grant select, insert, update on public.user_settings to authenticated;
grant select on public.minglit_files to authenticated;
grant select on public.file_access_grants to authenticated;
grant select, insert on public.verification_comments to authenticated;

-- 3. PARTNER ADMIN TABLES
grant insert, update, delete on public.partners to authenticated;
grant insert, update, delete on public.locations to authenticated;
grant insert, update, delete on public.verifications to authenticated;
grant insert, update, delete on public.parties to authenticated;
grant insert, update, delete on public.events to authenticated;
grant insert, update, delete on public.ticket_templates to authenticated;
grant insert, update, delete on public.entry_group_templates to authenticated;
grant insert, update, delete on public.entry_groups to authenticated;
grant insert, update, delete on public.tickets to authenticated;
grant select on public.settlements to authenticated;
grant insert, update, delete on public.match_rules to authenticated;

-- 4. VIEWS
grant select on public.locations_view to anon, authenticated;
grant select on public.partner_revenue_stats to authenticated;
grant select on public.partner_monthly_revenue to authenticated;
grant select on public.my_matches_view to authenticated;

-- 5. SEQUENCES
grant usage on all sequences in schema public to anon, authenticated;

-- 6. debug_logs (service_role + postgres only — revoke from anon/authenticated)
revoke all on public.debug_logs from anon;
revoke all on public.debug_logs from authenticated;
grant all on public.debug_logs to service_role;
grant all on public.debug_logs to postgres;

-- 7. RPC GRANT EXECUTE (24_rls_hardening.sql)
GRANT EXECUTE ON FUNCTION public.get_matched_user_info(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_event_applications_with_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_partner_members_with_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_verification_requests_with_user(uuid) TO authenticated;
