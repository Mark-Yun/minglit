set search_path to public, extensions;

-- ============================================================================
-- RLS Hardening: user_profiles lockdown, social_interactions lockdown,
-- event_participants blurring columns, partner RPCs
-- ============================================================================

-- PART A: Add columns to event_participants
ALTER TABLE public.event_participants ADD COLUMN IF NOT EXISTS display_name text;
ALTER TABLE public.event_participants ADD COLUMN IF NOT EXISTS birth_year int;

-- PART B: Update issue_ticket_on_approval() to copy display_name/birth_year
CREATE OR REPLACE FUNCTION public.issue_ticket_on_approval()
RETURNS trigger
SET search_path = public
AS $$
DECLARE
  v_display_name text;
  v_birth_year int;
BEGIN
  IF (new.status IN ('approved', 'paid') AND old.status NOT IN ('approved', 'paid')) THEN
    SELECT name, extract(year FROM birth_date)::int
    INTO v_display_name, v_birth_year
    FROM public.user_profiles WHERE id = new.user_id;

    INSERT INTO public.event_participants (
      event_id, ticket_id, user_id, application_id, status, ticket_code,
      display_name, birth_year
    )
    VALUES (
      new.event_id, new.ticket_id, new.user_id, new.id, 'ticket_issued',
      upper(substring(md5(gen_random_uuid()::text) FROM 1 FOR 8)),
      v_display_name, v_birth_year
    )
    ON CONFLICT (event_id, user_id) DO NOTHING;
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PART C: Backfill existing event_participants
UPDATE public.event_participants ep
SET display_name = up.name,
    birth_year = extract(year FROM up.birth_date)::int
FROM public.user_profiles up
WHERE up.id = ep.user_id
  AND ep.display_name IS NULL;

-- PART D: RLS Policy changes

-- user_profiles: self-only
DROP POLICY IF EXISTS "Public read access" ON public.user_profiles;
CREATE POLICY "Users can read own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

-- social_interactions: self-only SELECT (keep ALL policy for write)
DROP POLICY IF EXISTS "Anyone can view interactions" ON public.social_interactions;
CREATE POLICY "Users can view own interactions" ON public.social_interactions
  FOR SELECT USING (auth.uid() = user_id);

-- event_participants: open to all authenticated
DROP POLICY IF EXISTS "Users can read own participants" ON public.event_participants;
CREATE POLICY "Authenticated users can read all participants" ON public.event_participants
  FOR SELECT USING (auth.role() = 'authenticated');

-- PART E: SECURITY DEFINER RPCs

-- RPC 1: get_matched_user_info
CREATE OR REPLACE FUNCTION public.get_matched_user_info(
  p_target_user_id uuid,
  p_target_event_id uuid
)
RETURNS TABLE(user_name text, profile_image_url text, phone_number text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.match_pairs
    WHERE event_id = p_target_event_id
      AND (
        (user_lower_id = auth.uid() AND user_higher_id = p_target_user_id) OR
        (user_lower_id = p_target_user_id AND user_higher_id = auth.uid())
      )
  ) THEN
    RETURN QUERY
      SELECT up.name, up.profile_image_url, up.phone_number
      FROM public.user_profiles up
      WHERE up.id = p_target_user_id;
  END IF;
END;
$$;

-- RPC 2: get_event_applications_with_user
CREATE OR REPLACE FUNCTION public.get_event_applications_with_user(p_event_id uuid)
RETURNS TABLE(
  application_id uuid, event_id uuid, ticket_id uuid, user_id uuid,
  payment_id text, payment_amount int, status text,
  created_at timestamptz, updated_at timestamptz,
  user_name text, user_phone text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.events e
    JOIN public.parties p ON p.id = e.party_id
    WHERE e.id = p_event_id
      AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
  ) THEN
    RETURN QUERY
      SELECT ea.id, ea.event_id, ea.ticket_id, ea.user_id,
             ea.payment_id, ea.payment_amount, ea.status,
             ea.created_at, ea.updated_at,
             up.name, up.phone_number
      FROM public.event_applications ea
      LEFT JOIN public.user_profiles up ON up.id = ea.user_id
      WHERE ea.event_id = p_event_id
      ORDER BY ea.created_at DESC;
  END IF;
END;
$$;

-- RPC 3: get_partner_members_with_user
CREATE OR REPLACE FUNCTION public.get_partner_members_with_user(p_partner_id uuid)
RETURNS TABLE(
  user_id uuid, partner_id uuid, role text, permissions text[],
  joined_at timestamptz, user_name text, user_profile_image text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.has_partner_permission(p_partner_id, 'MEMBER_MANAGE')
     OR EXISTS (
       SELECT 1 FROM public.partner_member_permissions
       WHERE partner_id = p_partner_id AND user_id = auth.uid()
     )
  THEN
    RETURN QUERY
      SELECT pmp.user_id, pmp.partner_id, pmp.role, pmp.permissions,
             pmp.joined_at, up.name, up.profile_image_url
      FROM public.partner_member_permissions pmp
      LEFT JOIN public.user_profiles up ON up.id = pmp.user_id
      WHERE pmp.partner_id = p_partner_id
      ORDER BY pmp.joined_at;
  END IF;
END;
$$;

-- RPC 4: get_pending_verification_requests_with_user
CREATE OR REPLACE FUNCTION public.get_pending_verification_requests_with_user(p_partner_id uuid)
RETURNS TABLE(
  submission_id uuid, partner_id uuid, user_id uuid,
  verification_id uuid, application_id uuid, status text,
  snapshot_data jsonb, created_at timestamptz, user_name text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.has_partner_permission(p_partner_id, 'VERIFY_LIST_VIEW') THEN
    RETURN QUERY
      SELECT vs.id, vs.partner_id, vs.user_id,
             vs.verification_id, vs.application_id, vs.status,
             vs.snapshot_data, vs.created_at, up.name
      FROM public.verification_submissions vs
      LEFT JOIN public.user_profiles up ON up.id = vs.user_id
      WHERE vs.partner_id = p_partner_id
        AND vs.status = 'pending'
      ORDER BY vs.created_at;
  END IF;
END;
$$;

-- PART F: GRANT EXECUTE
GRANT EXECUTE ON FUNCTION public.get_matched_user_info(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_event_applications_with_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_partner_members_with_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_verification_requests_with_user(uuid) TO authenticated;
