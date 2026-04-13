-- DEV ONLY: Bulk RPC helpers for dev-seed Edge Function.
-- Replaces 560 admin.createUser() HTTP calls with 2 in-DB RPC calls.
-- Both functions are guarded to only run in local/development environments.

-- ─── RPC 1: dev_seed_bulk_users ──────────────────────────────────────────────
-- Upserts up to 560 test users into auth.users in a single transaction.
-- bcrypt hash computed once (all seed users share the same password).

CREATE OR REPLACE FUNCTION dev_seed_bulk_users(
  p_users jsonb,
  p_password text DEFAULT 'password1234!'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  pwd_hash text;
  u jsonb;
  created_count int := 0;
  updated_count int := 0;
  start_ts timestamptz := clock_timestamp();
  existing_id uuid;
BEGIN
  -- Guard: dev only (COALESCE ensures fail-closed when setting is NULL)
  IF COALESCE(current_setting('app.settings.environment', true), '') NOT IN ('local', 'development') THEN
    RAISE EXCEPTION 'dev_seed_bulk_users is blocked in production';
  END IF;

  -- Schema check — fail fast if Supabase upgrades auth schema
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'auth' AND table_name = 'users'
    AND column_name = 'encrypted_password'
  ) THEN
    RAISE EXCEPTION 'auth.users schema changed — dev_seed_bulk_users needs update';
  END IF;

  -- Password hash computed once (all seed users share the same password)
  pwd_hash := extensions.crypt(p_password, extensions.gen_salt('bf'));

  -- Bulk upsert
  FOR u IN SELECT * FROM jsonb_array_elements(p_users)
  LOOP
    SELECT id INTO existing_id FROM auth.users WHERE email = u->>'email';

    IF existing_id IS NULL THEN
      INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at, confirmation_token, recovery_token
      ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(), 'authenticated', 'authenticated',
        u->>'email', pwd_hash, now(),
        jsonb_build_object(
          'provider', 'email',
          'providers', jsonb_build_array('email'),
          'has_password', true
        ),
        jsonb_build_object(
          'name', u->>'name',
          'username', u->>'username',
          'gender', u->>'gender',
          'birth_date', u->>'birth_date',
          'phone_number', u->>'phone_number',
          'is_verified', (u->>'is_verified')::boolean,
          'sim_region', u->>'sim_region',
          'sim_lat', CASE WHEN u->>'sim_lat' IS NOT NULL THEN (u->>'sim_lat')::numeric ELSE NULL END,
          'sim_lng', CASE WHEN u->>'sim_lng' IS NOT NULL THEN (u->>'sim_lng')::numeric ELSE NULL END
        ),
        now(), now(), '', ''
      );
      created_count := created_count + 1;
    ELSE
      UPDATE auth.users SET
        encrypted_password = pwd_hash,
        raw_user_meta_data = jsonb_build_object(
          'name', u->>'name',
          'username', u->>'username',
          'gender', u->>'gender',
          'birth_date', u->>'birth_date',
          'phone_number', u->>'phone_number',
          'is_verified', (u->>'is_verified')::boolean,
          'sim_region', u->>'sim_region',
          'sim_lat', CASE WHEN u->>'sim_lat' IS NOT NULL THEN (u->>'sim_lat')::numeric ELSE NULL END,
          'sim_lng', CASE WHEN u->>'sim_lng' IS NOT NULL THEN (u->>'sim_lng')::numeric ELSE NULL END
        ),
        updated_at = now()
      WHERE id = existing_id;
      updated_count := updated_count + 1;
    END IF;
  END LOOP;

  -- auth.identities: backfill missing rows (idempotent)
  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id,
    created_at, updated_at, last_sign_in_at
  )
  SELECT u.id, u.id, u.raw_user_meta_data, 'email', u.email, now(), now(), now()
  FROM auth.users u
  WHERE u.email LIKE '%@test.com'
  ON CONFLICT (provider, provider_id) DO NOTHING;

  RETURN jsonb_build_object(
    'created', created_count,
    'updated', updated_count,
    'total', created_count + updated_count,
    'elapsed_ms', floor(extract(epoch from clock_timestamp() - start_ts) * 1000)::int
  );
END;
$$;

COMMENT ON FUNCTION dev_seed_bulk_users IS 'DEV ONLY — bulk upsert test users into auth.users. 560 users in ~2-3 seconds.';

-- ─── RPC 2: dev_seed_bulk_partners ───────────────────────────────────────────
-- Upserts partners, locations, verifications (global + local), and owner
-- permissions in a single transaction. Expects users to already exist
-- (created by dev_seed_bulk_users).
-- Fixes: original issue SQL had `WHERE partner_id = partner_id` (always-true
--        self-reference in the location existence check). Fixed by using a
--        dedicated variable `new_partner_id` throughout the function, and by
--        moving the DECLARE block for staff vars to the main DECLARE section.

CREATE OR REPLACE FUNCTION dev_seed_bulk_partners(
  p_partners jsonb,
  p_global_verifications jsonb DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  p jsonb;
  v jsonb;
  new_partner_id uuid;
  owner_id uuid;
  loc_id uuid;
  partner_count int := 0;
  loc_count int := 0;
  verif_count int := 0;
  start_ts timestamptz := clock_timestamp();
  first_partner_id uuid;
  staff_users uuid[];
BEGIN
  -- Guard: dev only (COALESCE ensures fail-closed when setting is NULL)
  IF COALESCE(current_setting('app.settings.environment', true), '') NOT IN ('local', 'development') THEN
    RAISE EXCEPTION 'dev_seed_bulk_partners is blocked in production';
  END IF;

  -- 1. Global verifications upsert (idempotent)
  FOR v IN SELECT * FROM jsonb_array_elements(p_global_verifications)
  LOOP
    INSERT INTO public.verifications (
      partner_id, category, internal_name, display_name, description, icon_key, form_schema
    ) VALUES (
      NULL, v->>'category', v->>'internal_name', v->>'display_name',
      v->>'description', v->>'icon_key', COALESCE(v->'form_schema', '[]'::jsonb)
    )
    ON CONFLICT (internal_name) WHERE partner_id IS NULL DO NOTHING;
    verif_count := verif_count + 1;
  END LOOP;

  -- 2. Partners + locations + local verifications + owner permission
  FOR p IN SELECT * FROM jsonb_array_elements(p_partners)
  LOOP
    -- Owner lookup (must already exist from dev_seed_bulk_users)
    SELECT id INTO owner_id FROM auth.users WHERE email = p->>'owner_email';
    IF owner_id IS NULL THEN
      RAISE WARNING 'Owner % not found, skipping partner %', p->>'owner_email', p->>'name';
      CONTINUE;
    END IF;

    -- Partner upsert (biz_number as natural key)
    SELECT id INTO new_partner_id FROM public.partners WHERE biz_number = p->>'biz_number';
    IF new_partner_id IS NULL THEN
      INSERT INTO public.partners (name, introduction, biz_name, biz_number, contact_email)
      VALUES (p->>'name', p->>'introduction', p->>'biz_name', p->>'biz_number', p->>'contact_email')
      RETURNING id INTO new_partner_id;
    END IF;
    partner_count := partner_count + 1;

    -- Owner permission: runs on every rerun to recover from permission drift
    INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
    VALUES (new_partner_id, owner_id, 'owner')
    ON CONFLICT (partner_id, user_id) DO UPDATE SET role = 'owner';

    -- Location upsert: use new_partner_id variable (not column name) in WHERE
    IF NOT EXISTS (
      SELECT 1 FROM public.locations l
      WHERE l.partner_id = new_partner_id AND l.name = (p->'location'->>'name')
    ) THEN
      INSERT INTO public.locations (partner_id, name, address, region_1, region_2, region_3, geo_point)
      VALUES (
        new_partner_id,
        p->'location'->>'name',
        p->'location'->>'address',
        p->'location'->>'region_1',
        p->'location'->>'region_2',
        p->'location'->>'region_3',
        public.ST_SetSRID(public.ST_MakePoint(
          (p->'location'->>'lng')::float,
          (p->'location'->>'lat')::float
        ), 4326)
      );
      loc_count := loc_count + 1;
    END IF;

    -- Local verifications for this partner
    FOR v IN SELECT * FROM jsonb_array_elements(COALESCE(p->'local_verifications', '[]'::jsonb))
    LOOP
      INSERT INTO public.verifications (
        partner_id, category, internal_name, display_name, description, icon_key, form_schema
      ) VALUES (
        new_partner_id, v->>'category', v->>'internal_name', v->>'display_name',
        v->>'description', v->>'icon_key', COALESCE(v->'form_schema', '[]'::jsonb)
      )
      ON CONFLICT (internal_name) WHERE partner_id IS NOT NULL DO NOTHING;
      verif_count := verif_count + 1;
    END LOOP;
  END LOOP;

  -- 3. Staff roles: assign first 2 seed users as manager/staff on the first partner
  SELECT id INTO first_partner_id FROM public.partners
  WHERE biz_number = (p_partners->0->>'biz_number')
  LIMIT 1;

  IF first_partner_id IS NOT NULL THEN
    SELECT ARRAY(
      SELECT up.id FROM public.user_profiles up
      WHERE up.username IN ('user_20_m_ok', 'user_20_f_ok')
      ORDER BY up.username LIMIT 2
    ) INTO staff_users;

    IF array_length(staff_users, 1) >= 1 THEN
      INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
      VALUES (first_partner_id, staff_users[1], 'manager')
      ON CONFLICT (partner_id, user_id) DO UPDATE SET role = 'manager';
    END IF;
    IF array_length(staff_users, 1) >= 2 THEN
      INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
      VALUES (first_partner_id, staff_users[2], 'staff')
      ON CONFLICT (partner_id, user_id) DO UPDATE SET role = 'staff';
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'partners_processed', partner_count,
    'locations', loc_count,
    'verifications', verif_count,
    'elapsed_ms', floor(extract(epoch from clock_timestamp() - start_ts) * 1000)::int
  );
END;
$$;

COMMENT ON FUNCTION dev_seed_bulk_partners IS 'DEV ONLY — bulk upsert partners, locations, verifications, and roles. ~1 second for all seed partners.';
