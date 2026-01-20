-- 10. STORAGE: verification-proofs bucket and RLS policies

-- 1. Create Bucket
insert into storage.buckets (id, name, public)
values ('verification-proofs', 'verification-proofs', false)
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

-- Allow admins/partners to view proofs
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
