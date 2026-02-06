-- 13. File Management System

-- 1. Create minglit_files table
create table public.minglit_files (
  id uuid primary key default gen_random_uuid(),
  storage_object_id uuid not null references storage.objects(id) on delete cascade,
  bucket_id text not null,
  file_path text not null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

-- Index for performance
create index idx_minglit_files_owner on public.minglit_files(owner_id);
create index idx_minglit_files_path on public.minglit_files(bucket_id, file_path);

-- 2. Create file_access_grants table
create table public.file_access_grants (
  id uuid primary key default gen_random_uuid(),
  file_id uuid not null references public.minglit_files(id) on delete cascade,
  viewer_id uuid not null references auth.users(id) on delete cascade,
  expires_at timestamptz,
  created_at timestamptz default now()
);

create index idx_file_grants_file_viewer on public.file_access_grants(file_id, viewer_id);

-- 3. Trigger Function to sync storage.objects -> minglit_files
create or replace function public.handle_storage_object_created()
returns trigger as $$
begin
  insert into public.minglit_files (storage_object_id, bucket_id, file_path, owner_id)
  values (new.id, new.bucket_id, new.name, new.owner);
  return new;
end;
$$ language plpgsql security definer;

-- Trigger
create trigger on_storage_object_created
after insert on storage.objects
for each row execute function public.handle_storage_object_created();

-- 4. Enable RLS
alter table public.minglit_files enable row level security;
alter table public.file_access_grants enable row level security;

-- Policies for minglit_files
create policy "Users can view own files"
on public.minglit_files for select
using (auth.uid() = owner_id);

create policy "Users can view granted files"
on public.minglit_files for select
using (
  exists (
    select 1 from public.file_access_grants
    where file_id = minglit_files.id
    and viewer_id = auth.uid()
    and (expires_at is null or expires_at > now())
  )
);

-- Policies for file_access_grants
create policy "Viewers can see their grants"
on public.file_access_grants for select
using (viewer_id = auth.uid());

-- 5. Update Storage RLS (verification-proofs)
create policy "Granted users can view verification proofs"
on storage.objects for select
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

-- 6. Grant triggers (Logic)

-- 6.1. Grant access on Application Created
create or replace function public.handle_new_application_files()
returns trigger as $$
declare
  v_partner_owner_id uuid;
  v_event_end_time timestamptz;
  v_file_record record;
begin
  -- 1. Get Event Info (End Time & Partner Owner)
  select e.end_time, perm.user_id
  into v_event_end_time, v_partner_owner_id
  from public.events e
  join public.parties party on e.party_id = party.id
  join public.partner_member_permissions perm on party.partner_id = perm.partner_id
  where e.id = new.event_id 
  and perm.role = 'owner';

  if v_partner_owner_id is null then
    return new; -- Should not happen
  end if;

  -- 2. Find related files in minglit_files
  -- Path pattern: {user_id}/applications/{event_id}/%
  for v_file_record in
    select id from public.minglit_files
    where file_path like (new.user_id || '/applications/' || new.event_id || '/%')
  loop
    -- 3. Insert Grant
    insert into public.file_access_grants (file_id, viewer_id, expires_at)
    values (
      v_file_record.id, 
      v_partner_owner_id, 
      v_event_end_time + interval '30 days'
    );
    -- Note: No unique constraint on (file_id, viewer_id) yet, maybe needed?
    -- Assuming one grant per viewer per file is sufficient.
  end loop;

  return new;
end;
$$ language plpgsql security definer;

create trigger on_application_created
after insert on public.event_applications
for each row execute function public.handle_new_application_files();


-- 6.2. Update expiration on Event Reschedule
create or replace function public.handle_event_reschedule()
returns trigger as $$
begin
  -- Only run if end_time changed
  if old.end_time = new.end_time then
    return new;
  end if;

  -- Update all grants related to applications for this event
  -- Logic: Find grants for files that belong to applications of this event.
  -- This is tricky without direct link. 
  -- But we know the path pattern: %/applications/{event_id}/%
  
  update public.file_access_grants g
  set expires_at = new.end_time + interval '30 days'
  from public.minglit_files f
  where g.file_id = f.id
  and f.file_path like ('%/applications/' || new.id || '/%');

  return new;
end;
$$ language plpgsql security definer;

create trigger on_event_reschedule
after update of end_time on public.events
for each row execute function public.handle_event_reschedule();