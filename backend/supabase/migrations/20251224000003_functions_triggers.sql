-- Security Functions
create or replace function public.is_super_admin()
returns boolean as $$
  select exists (
    select 1 from public.app_roles 
    where user_id = auth.uid() and role = 'super_admin'
  );
$$ language sql security definer;

create or replace function public.has_partner_permission(p_id uuid, p_key text)
returns boolean as $$
begin
  if public.is_super_admin() then return true; end if;

  return exists (
    select 1 from public.partner_member_permissions
    where partner_id = p_id 
    and user_id = auth.uid()
    and p_key = any(permissions)
  );
end;
$$ language plpgsql security definer;

-- Triggers & Helpers
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger handle_updated_at before update on public.user_profiles for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.partners for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.locations for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.parties for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.events for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.entry_group_templates for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.entry_groups for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.ticket_templates for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.tickets for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.event_applications for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.event_participants for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.partner_applications for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.verification_submissions for each row execute procedure moddatetime (updated_at);
-- New Tables Triggers
create trigger handle_updated_at before update on public.user_embeddings for each row execute procedure moddatetime (updated_at);
create trigger handle_updated_at before update on public.party_embeddings for each row execute procedure moddatetime (updated_at);

-- Update participation stats
create or replace function public.update_event_participation_stats()
returns trigger as $$
begin
  if (TG_OP = 'INSERT') then
    update public.events set current_participants = current_participants + 1 where id = NEW.event_id;
    update public.tickets set sold_count = sold_count + 1 where id = NEW.ticket_id;
  elsif (TG_OP = 'DELETE') then
    update public.events set current_participants = current_participants - 1 where id = OLD.event_id;
    update public.tickets set sold_count = sold_count - 1 where id = OLD.ticket_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

create trigger on_participant_change
after insert or delete on public.event_participants
for each row execute function public.update_event_participation_stats();

-- Sync permissions
create or replace function public.sync_partner_member_permissions()
returns trigger as $$
begin
  if (new.role = 'owner') then
    new.permissions := array['PARTNER_EDIT', 'SETTLEMENT_VIEW', 'SETTLEMENT_EDIT', 'MEMBER_MANAGE', 'PARTY_MANAGE', 'VERIFY_LIST_VIEW', 'USER_DATA_VIEW', 'VERIFY_REVIEW', 'COMMENT_MANAGE'];
  elsif (new.role = 'manager') then
    new.permissions := array['PARTNER_EDIT', 'PARTY_MANAGE', 'VERIFY_LIST_VIEW', 'USER_DATA_VIEW', 'VERIFY_REVIEW', 'COMMENT_MANAGE'];
  elsif (new.role = 'staff') then
    new.permissions := array['VERIFY_LIST_VIEW', 'COMMENT_MANAGE', 'PARTY_MANAGE'];
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_sync_permissions before insert or update of role on public.partner_member_permissions for each row execute procedure public.sync_partner_member_permissions();

-- Auth.users -> user_profiles auto sync
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id, username, name, phone_number)
  values (new.id, new.raw_user_meta_data->>'username', new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'phone_number');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Auto-Approve Logic (Trigger): When submission is approved, insert into partner_verified_users
create or replace function public.handle_verification_approval()
returns trigger as $$
begin
  if (new.status = 'approved' and old.status != 'approved') then
    insert into public.partner_verified_users (partner_id, user_id, verification_id, submission_id, verified_at)
    values (new.partner_id, new.user_id, new.verification_id, new.id, now())
    on conflict (partner_id, user_id, verification_id) 
    do update set submission_id = new.id, verified_at = now(), valid_until = null; 
  elsif (new.status != 'approved' and old.status = 'approved') then
    -- Revoke verification if status changes back (e.g., cancelled)
    delete from public.partner_verified_users
    where submission_id = new.id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_submission_status_change
  after update on public.verification_submissions
  for each row execute procedure public.handle_verification_approval();
