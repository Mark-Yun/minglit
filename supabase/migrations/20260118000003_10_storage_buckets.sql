-- 10. STORAGE: verification-proofs bucket and RLS policies

-- 1. Create Buckets
insert into storage.buckets (id, name, public)
values 
  ('verification-proofs', 'verification-proofs', false),
  ('party-assets', 'party-assets', true),
  ('partner-proofs', 'partner-proofs', false)
on conflict (id) do nothing;

-- 2. RLS Policies for verification-proofs

-- Allow users to upload their own proofs
-- Path structure: {user_id}/applications/{event_id}/{filename}
create policy "Users can upload own verification proofs"
on storage.objects for insert
with check (
  bucket_id = 'verification-proofs' 
  and (storage.foldername(name))[1] = (auth.uid())::text
);

-- Allow users to view their own proofs
create policy "Users can view own verification proofs"
on storage.objects for select
using (
  bucket_id = 'verification-proofs' 
  and (storage.foldername(name))[1] = (auth.uid())::text
);

-- 3. RLS Policies for party-assets (Public)

-- Allow authenticated users (partners) to upload party assets
create policy "Partners can upload party assets"
on storage.objects for insert
with check (
  bucket_id = 'party-assets' 
  and auth.role() = 'authenticated'
);

-- Public access is handled by bucket configuration (public=true), 
-- but we can add explicit policy if needed.
create policy "Public can view party assets"
on storage.objects for select
using ( bucket_id = 'party-assets' );

-- 4. RLS Policies for partner-proofs (Private)

-- Allow partners to upload their own proofs
-- Path: {user_id}/...
create policy "Partners can upload own proofs"
on storage.objects for insert
with check (
  bucket_id = 'partner-proofs' 
  and (storage.foldername(name))[1] = (auth.uid())::text
);

-- Allow partners to view own proofs
create policy "Partners can view own proofs"
on storage.objects for select
using (
  bucket_id = 'partner-proofs' 
  and (storage.foldername(name))[1] = (auth.uid())::text
);

-- Allow admins to view all partner proofs
create policy "Admins can view partner proofs"
on storage.objects for select
using (
  bucket_id = 'partner-proofs'
  and exists (
    select 1 from public.app_roles
    where user_id = auth.uid() and role in ('super_admin', 'moderator')
  )
);

-- Allow admins/partners to view verification proofs (legacy policy, kept for safety)
create policy "Admins and partners can view all proofs"
on storage.objects for select
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
