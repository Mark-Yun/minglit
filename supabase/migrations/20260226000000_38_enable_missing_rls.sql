set search_path to public, extensions;

-- ============================================================================
-- P0-3: Enable RLS on 6 missing tables
-- Tables: debug_logs, app_roles, partner_settlements,
--         partner_member_permissions, partner_applications, verification_comments
-- ============================================================================

-- 1. debug_logs: Revoke public grants and lock down to service_role only
revoke all on public.debug_logs from anon;
revoke all on public.debug_logs from authenticated;
alter table public.debug_logs enable row level security;
create policy "service_role_all" on public.debug_logs for all
  using (current_setting('role') = 'service_role')
  with check (current_setting('role') = 'service_role');

-- 2. app_roles: super_admin only
alter table public.app_roles enable row level security;
create policy "super_admin_only" on public.app_roles for all
  using (public.is_super_admin())
  with check (public.is_super_admin());

-- 3. partner_settlements: permission-based access
alter table public.partner_settlements enable row level security;
create policy "settlement_read" on public.partner_settlements for select
  using (public.has_partner_permission(partner_id, 'SETTLEMENT_VIEW'));
create policy "settlement_write" on public.partner_settlements for update
  using (public.has_partner_permission(partner_id, 'SETTLEMENT_EDIT'))
  with check (public.has_partner_permission(partner_id, 'SETTLEMENT_EDIT'));
create policy "settlement_delete" on public.partner_settlements for delete
  using (public.is_super_admin());
-- INSERT handled by service_role (Edge Functions / triggers)

-- 4. partner_member_permissions: Enable RLS (existing SELECT policy activates)
--    Existing: "Users can read own permissions" → auth.uid() = user_id OR is_super_admin() OR has_partner_permission(partner_id, 'MEMBER_MANAGE')
alter table public.partner_member_permissions enable row level security;
create policy "member_manage_insert" on public.partner_member_permissions for insert
  with check (public.has_partner_permission(partner_id, 'MEMBER_MANAGE'));
create policy "member_manage_update" on public.partner_member_permissions for update
  using (public.has_partner_permission(partner_id, 'MEMBER_MANAGE'))
  with check (public.has_partner_permission(partner_id, 'MEMBER_MANAGE'));
create policy "member_manage_delete" on public.partner_member_permissions for delete
  using (public.has_partner_permission(partner_id, 'MEMBER_MANAGE'));

-- 5. partner_applications: Enable RLS (existing SELECT policy activates)
--    Existing: "Users can read own applications" → auth.uid() = user_id OR is_super_admin()
alter table public.partner_applications enable row level security;
create policy "authenticated_can_apply" on public.partner_applications for insert
  to authenticated
  with check (auth.uid() = user_id);
create policy "admin_update_applications" on public.partner_applications for update
  using (public.is_super_admin())
  with check (public.is_super_admin());
create policy "admin_delete_applications" on public.partner_applications for delete
  using (public.is_super_admin());

-- 6. verification_comments: complex access control
alter table public.verification_comments enable row level security;
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
