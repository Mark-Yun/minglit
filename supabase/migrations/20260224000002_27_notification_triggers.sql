-- 27. Notification triggers: application status, event cancellation, partner new-application, verification result
set search_path to public, extensions;

-- T4: Application Status Trigger (AFTER UPDATE on event_applications)
create or replace function public.notify_application_status()
returns trigger
security definer
set search_path = public, extensions
as $$
declare
  event_title text;
  payload jsonb;
begin
  -- Only fire on actual status change
  if (old.status is distinct from new.status) then

    -- Get event title
    select coalesce(e.title, '이벤트') into event_title
    from public.events e where e.id = new.event_id;

    if (new.status = 'approved') then
      payload := jsonb_build_object(
        'id', gen_random_uuid()::text,
        'type', 'application_approved',
        'user_id', new.user_id,
        'title', '[이벤트 참가 확정] ' || event_title,
        'body', '이벤트 참가가 확정되었습니다.',
        'category', 'service',
        'data', jsonb_build_object(
          'event_id', new.event_id,
          'deep_link', '/events/' || new.event_id
        ),
        'meta', jsonb_build_object('occurred_at', now())
      );
      perform pgmq.send(queue_name := 'q_notifications', msg := payload);

    elsif (new.status = 'rejected') then
      payload := jsonb_build_object(
        'id', gen_random_uuid()::text,
        'type', 'application_rejected',
        'user_id', new.user_id,
        'title', '[신청 거절] ' || event_title,
        'body', '신청이 거절되었습니다.',
        'category', 'service',
        'data', jsonb_build_object(
          'event_id', new.event_id,
          'deep_link', '/events/' || new.event_id
        ),
        'meta', jsonb_build_object('occurred_at', now())
      );
      perform pgmq.send(queue_name := 'q_notifications', msg := payload);
    end if;

  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_application_status_notify on public.event_applications;
create trigger on_application_status_notify
  after update on public.event_applications
  for each row
  execute procedure public.notify_application_status();

-- T5: Event Cancellation (CREATE OR REPLACE the existing notify_event_update function)
create or replace function public.notify_event_update()
returns trigger
security definer
set search_path = public, extensions
as $$
declare
  applicant record;
  payload jsonb;
begin
  -- Check significant changes
  if (
    new.title is distinct from old.title or
    new.start_time is distinct from old.start_time or
    new.location_id is distinct from old.location_id or
    new.status is distinct from old.status
  ) then

    for applicant in
      select user_id
      from public.event_applications
      where event_id = new.id
      and status in ('approved', 'pending')
    loop

      -- Cancellation case: specific message
      if (new.status = 'cancelled' and old.status is distinct from 'cancelled') then
        payload := jsonb_build_object(
          'id', gen_random_uuid()::text,
          'type', 'event_cancelled',
          'user_id', applicant.user_id,
          'title', '[이벤트 취소] ' || coalesce(new.title, '이벤트'),
          'body', '진행 예정이었던 이벤트가 취소되었습니다.',
          'category', 'service',
          'data', jsonb_build_object(
            'event_id', new.id,
            'deep_link', '/events/' || new.id
          ),
          'meta', jsonb_build_object('occurred_at', now())
        );
      else
        -- General update case (existing behavior)
        payload := jsonb_build_object(
          'id', gen_random_uuid()::text,
          'type', 'event_update',
          'user_id', applicant.user_id,
          'title', '[이벤트 업데이트] ' || coalesce(new.title, '이벤트'),
          'body', '주최자가 이벤트 정보를 변경했습니다. 탭하여 확인해보세요.',
          'category', 'service',
          'data', jsonb_build_object(
            'event_id', new.id,
            'deep_link', '/events/' || new.id
          ),
          'meta', jsonb_build_object('occurred_at', now())
        );
      end if;

      perform pgmq.send(queue_name := 'q_notifications', msg := payload);

    end loop;

  end if;

  return new;
end;
$$ language plpgsql;

-- T6: Partner New Application Alert (AFTER INSERT on event_applications)
create or replace function public.notify_new_application_to_partner()
returns trigger
security definer
set search_path = public, extensions
as $$
declare
  event_title text;
  v_partner_id uuid;
  member record;
  payload jsonb;
begin
  -- Get event title and partner_id via: event -> party -> partner
  select coalesce(e.title, '이벤트'), p.partner_id
  into event_title, v_partner_id
  from public.events e
  join public.parties p on p.id = e.party_id
  where e.id = new.event_id;

  -- Loop through all partner members
  for member in
    select user_id
    from public.partner_member_permissions
    where partner_id = v_partner_id
  loop
    payload := jsonb_build_object(
      'id', gen_random_uuid()::text,
      'type', 'new_application',
      'user_id', member.user_id,
      'title', '[신규 신청] ' || event_title,
      'body', '새로운 이벤트 참가 신청이 도착했습니다.',
      'category', 'service',
      'data', jsonb_build_object(
        'event_id', new.event_id,
        'deep_link', '/events/' || new.event_id || '/applications'
      ),
      'meta', jsonb_build_object('occurred_at', now())
    );
    perform pgmq.send(queue_name := 'q_notifications', msg := payload);
  end loop;

  return new;
end;
$$ language plpgsql;

drop trigger if exists on_new_application_notify on public.event_applications;
create trigger on_new_application_notify
  after insert on public.event_applications
  for each row
  execute procedure public.notify_new_application_to_partner();

-- T7: Verification Result Trigger (AFTER UPDATE on verification_submissions)
create or replace function public.notify_verification_result()
returns trigger
security definer
set search_path = public, extensions
as $$
declare
  v_display_name text;
  payload jsonb;
  notification_type text;
  notification_title text;
  notification_body text;
begin
  if (old.status is distinct from new.status) then

    -- Get verification display_name
    select coalesce(v.display_name, '인증') into v_display_name
    from public.verifications v where v.id = new.verification_id;

    if (new.status = 'approved') then
      notification_type := 'verification_approved';
      notification_title := '[인증 승인] ' || v_display_name;
      notification_body := '인증이 승인되었습니다.';
    elsif (new.status = 'rejected') then
      notification_type := 'verification_rejected';
      notification_title := '[인증 거절] ' || v_display_name;
      notification_body := '인증이 거절되었습니다.';
    elsif (new.status = 'needs_correction') then
      notification_type := 'verification_needs_correction';
      notification_title := '[보완 필요] ' || v_display_name;
      notification_body := '보완이 필요합니다.';
    else
      return new; -- No notification for other status changes
    end if;

    payload := jsonb_build_object(
      'id', gen_random_uuid()::text,
      'type', notification_type,
      'user_id', new.user_id,
      'title', notification_title,
      'body', notification_body,
      'category', 'service',
      'data', jsonb_build_object(
        'verification_id', new.verification_id,
        'submission_id', new.id,
        'deep_link', '/verifications/' || new.verification_id
      ),
      'meta', jsonb_build_object('occurred_at', now())
    );
    perform pgmq.send(queue_name := 'q_notifications', msg := payload);

  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_verification_result_notify on public.verification_submissions;
create trigger on_verification_result_notify
  after update on public.verification_submissions
  for each row
  execute procedure public.notify_verification_result();
