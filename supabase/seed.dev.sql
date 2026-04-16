
-- supabase/seed.dev.sql
-- DEV ONLY: 560 users (60 legacy + 500 regional) + 5 partner owners + 5 partners
--           + locations + verifications + roles + pgmq purge + env setting
--
-- Executed by GitHub Actions (dev branch only) via:
--   PGPASSWORD="..." psql "<pooler-url>" -f supabase/seed.dev.sql
--
-- Safety:
--   - Workflow guards with `if: ENV == 'dev'` — never runs on main/prod
--   - All inserts are idempotent (SELECT/INSERT/UPDATE, NOT EXISTS checks)
--   - Runs via session-mode pooler (port 5432) for DO block + ALTER DATABASE support

-- ── Phase 1: 560 Users + 5 Partner Owners ────────────────────────────────────
-- Uses SELECT + INSERT/UPDATE pattern (not ON CONFLICT) because:
--   - auth.users has a partial unique index on email (WHERE is_sso_user = FALSE),
--     not a plain unique constraint, making ON CONFLICT (email) invalid.
--   - PL/pgSQL local variable `email_val` would shadow the column reference anyway.
DO $$
DECLARE
  pwd_hash     text;
  current_year int := EXTRACT(YEAR FROM now())::int;

  -- 10 regions: [name, lat, lng]
  regions text[][] := ARRAY[
    ARRAY['강남',      '37.4979', '127.0276'],
    ARRAY['홍대',      '37.5575', '126.9245'],
    ARRAY['성수',      '37.5445', '127.0559'],
    ARRAY['이태원',    '37.5340', '126.9948'],
    ARRAY['잠실',      '37.5133', '127.1001'],
    ARRAY['판교',      '37.3948', '127.1112'],
    ARRAY['부산_해운대','35.1631', '129.1635'],
    ARRAY['부산_서면',  '35.1578', '129.0596'],
    ARRAY['대구_동성로','35.8690', '128.5941'],
    ARRAY['제주',      '33.4996', '126.5312']
  ];

  age           int;
  ri            int;
  gender_val    text;
  gender_short  text;
  last4         text;
  prefix        int;
  username_val  text;
  email_val     text;
  birth_year    int;
  birth_date_val text;
  phone_val     text;
  phone_prefix  int;
  verified_val  boolean;
  verif_short   text;
  existing_id   uuid;
  meta          jsonb;
BEGIN
  -- Schema check: fail fast if Supabase upgrades auth schema
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'auth' AND table_name = 'users'
      AND column_name = 'encrypted_password'
  ) THEN
    RAISE EXCEPTION 'auth.users schema changed — seed.dev.sql needs update';
  END IF;

  -- Hash computed once (all seed users share the same password: password1234!)
  pwd_hash := extensions.crypt('password1234!', extensions.gen_salt('bf'));

  -- ── 500 Regional Users (ages 18-42 × 2 genders × 10 regions) ───────────────
  -- Username: user_{age}_{m|f}_{region}
  -- Phone:    010-{5000+ri*100+(age-18)}-{1000 male | 2000 female}
  FOR age IN 18..42 LOOP
    birth_year    := current_year - age + 1;
    birth_date_val := birth_year || '-01-01';

    FOR ri IN 0..9 LOOP
      prefix := 5000 + ri * 100 + (age - 18);

      FOREACH gender_val IN ARRAY ARRAY['male', 'female'] LOOP
        gender_short := CASE gender_val WHEN 'male' THEN 'm' ELSE 'f' END;
        last4        := CASE gender_val WHEN 'male' THEN '1000' ELSE '2000' END;
        username_val := 'user_' || age || '_' || gender_short || '_' || regions[ri + 1][1];
        email_val    := username_val || '@test.com';
        phone_val    := '010-' || prefix || '-' || last4;
        meta         := jsonb_build_object(
          'name',        age || CASE gender_val WHEN 'male' THEN '남' ELSE '여' END || '_' || regions[ri + 1][1],
          'username',    username_val,
          'gender',      gender_val,
          'birth_date',  birth_date_val,
          'phone_number',phone_val,
          'is_verified', true,
          'sim_region',  regions[ri + 1][1],
          'sim_lat',     regions[ri + 1][2]::numeric,
          'sim_lng',     regions[ri + 1][3]::numeric
        );

        SELECT id INTO existing_id FROM auth.users WHERE email = email_val;
        IF existing_id IS NULL THEN
          INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password,
            email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
            created_at, updated_at, confirmation_token, recovery_token,
            is_sso_user, is_anonymous, phone,
            email_change, email_change_token_new, email_change_token_current,
            phone_change, phone_change_token, reauthentication_token,
            email_change_confirm_status
          ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            gen_random_uuid(), 'authenticated', 'authenticated',
            email_val, pwd_hash, now(),
            '{"provider":"email","providers":["email"],"has_password":true}'::jsonb,
            meta, now(), now(), '', '',
            false, false, phone_val,
            '', '', '', '', '', '', 0
          );
        ELSE
          UPDATE auth.users
          SET encrypted_password = pwd_hash,
              raw_user_meta_data = meta,
              updated_at = now(),
              is_sso_user = COALESCE(is_sso_user, false),
              is_anonymous = COALESCE(is_anonymous, false),
              phone = COALESCE(phone, '')
          WHERE id = existing_id;
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;

  -- ── 60 Legacy Users (ages 20-34, m_ok/m_no/f_ok/f_no) ───────────────────────
  -- Email pattern: user_{age}_{m|f}_{ok|no}@test.com — preserved for E2E compat
  -- Phone prefix: age ≤ 24 → 1000+age, age ≥ 25 → 2000+age
  -- last4: {verified:1|0}{male:1|female:2}00
  FOR age IN 20..34 LOOP
    birth_year    := current_year - age + 1;
    birth_date_val := birth_year || '-01-01';
    phone_prefix  := CASE WHEN age <= 24 THEN 1000 + age ELSE 2000 + age END;

    FOREACH gender_val IN ARRAY ARRAY['male', 'female'] LOOP
      gender_short := CASE gender_val WHEN 'male' THEN 'm' ELSE 'f' END;

      FOREACH verified_val IN ARRAY ARRAY[true, false] LOOP
        verif_short  := CASE WHEN verified_val THEN 'ok' ELSE 'no' END;
        last4        := (CASE WHEN verified_val THEN '1' ELSE '0' END) ||
                        (CASE WHEN gender_val = 'male' THEN '1' ELSE '2' END) || '00';
        username_val := 'user_' || age || '_' || gender_short || '_' || verif_short;
        email_val    := username_val || '@test.com';
        phone_val    := '010-' || phone_prefix || '-' || last4;
        meta         := jsonb_build_object(
          'name',        age || (CASE gender_val WHEN 'male' THEN '남' ELSE '여' END) ||
                         '_' || (CASE WHEN verified_val THEN '인증O' ELSE '인증X' END),
          'username',    username_val,
          'gender',      gender_val,
          'birth_date',  birth_date_val,
          'phone_number',phone_val,
          'is_verified', verified_val
        );

        SELECT id INTO existing_id FROM auth.users WHERE email = email_val;
        IF existing_id IS NULL THEN
          INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password,
            email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
            created_at, updated_at, confirmation_token, recovery_token,
            is_sso_user, is_anonymous, phone,
            email_change, email_change_token_new, email_change_token_current,
            phone_change, phone_change_token, reauthentication_token,
            email_change_confirm_status
          ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            gen_random_uuid(), 'authenticated', 'authenticated',
            email_val, pwd_hash, now(),
            '{"provider":"email","providers":["email"],"has_password":true}'::jsonb,
            meta, now(), now(), '', '',
            false, false, phone_val,
            '', '', '', '', '', '', 0
          );
        ELSE
          UPDATE auth.users
          SET encrypted_password = pwd_hash,
              raw_user_meta_data = meta,
              updated_at = now(),
              is_sso_user = COALESCE(is_sso_user, false),
              is_anonymous = COALESCE(is_anonymous, false),
              phone = COALESCE(phone, '')
          WHERE id = existing_id;
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;

  -- ── 5 Partner Owners ─────────────────────────────────────────────────────────
  -- idx 0-1: birth 1990-01-01, phone 010-0000-{LPAD(idx, 4, '0')}
  -- idx 2-4: birth 1988-01-01, phone 010-0001-{LPAD(idx-2, 4, '0')}
  FOREACH email_val IN ARRAY ARRAY[
    'partner_owner_1@test.com',
    'partner_owner_2@test.com',
    'partner_hotplace_0@test.com',
    'partner_hotplace_1@test.com',
    'partner_hotplace_2@test.com'
  ] LOOP
    meta := CASE email_val
      WHEN 'partner_owner_1@test.com' THEN
        '{"name":"밍글 스튜디오 대표","username":"partner_owner_1","gender":"male","birth_date":"1990-01-01","phone_number":"010-0000-0000","is_verified":true}'::jsonb
      WHEN 'partner_owner_2@test.com' THEN
        '{"name":"파티룸 홍대 대표","username":"partner_owner_2","gender":"male","birth_date":"1990-01-01","phone_number":"010-0000-0001","is_verified":true}'::jsonb
      WHEN 'partner_hotplace_0@test.com' THEN
        '{"name":"서울 강남 소셜클럽 대표","username":"partner_hotplace_0","gender":"male","birth_date":"1988-01-01","phone_number":"010-0001-0000","is_verified":true}'::jsonb
      WHEN 'partner_hotplace_1@test.com' THEN
        '{"name":"서울 홍대 소셜클럽 대표","username":"partner_hotplace_1","gender":"male","birth_date":"1988-01-01","phone_number":"010-0001-0001","is_verified":true}'::jsonb
      ELSE
        '{"name":"서울 성수 소셜클럽 대표","username":"partner_hotplace_2","gender":"male","birth_date":"1988-01-01","phone_number":"010-0001-0002","is_verified":true}'::jsonb
    END;

    SELECT id INTO existing_id FROM auth.users WHERE email = email_val;
    IF existing_id IS NULL THEN
      INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at, confirmation_token, recovery_token,
        is_sso_user, is_anonymous, phone,
        email_change, email_change_token_new, email_change_token_current,
        phone_change, phone_change_token, reauthentication_token,
        email_change_confirm_status
      ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(), 'authenticated', 'authenticated',
        email_val, pwd_hash, now(),
        '{"provider":"email","providers":["email"],"has_password":true}'::jsonb,
        meta, now(), now(), '', '',
        false, false, meta->>'phone_number',
        '', '', '', '', '', '', 0
      );
    ELSE
      UPDATE auth.users
      SET encrypted_password = pwd_hash,
          raw_user_meta_data = meta,
          updated_at = now(),
          is_sso_user = COALESCE(is_sso_user, false),
          is_anonymous = COALESCE(is_anonymous, false),
          phone = COALESCE(phone, '')
      WHERE id = existing_id;
    END IF;
  END LOOP;
END $$;

-- ── auth.identities cleanup (remove duplicates from previous seed runs) ──────
-- Previous seed used provider_id=email instead of provider_id=UUID, creating
-- duplicate identity rows that break GoTrue admin.listUsers().
DELETE FROM auth.identities
WHERE provider = 'email'
AND user_id IN (SELECT id FROM auth.users WHERE email LIKE '%@test.com')
AND provider_id LIKE '%@test.com';

-- ── auth.identities backfill (only for users without any identity) ────────────
-- GoTrue creates identities with provider_id = user UUID, not email.
-- Only backfill for users that have zero identity rows (newly created by this seed).
INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  created_at, updated_at, last_sign_in_at
)
SELECT u.id, u.id,
  jsonb_build_object(
    'sub', u.id::text,
    'email', u.email,
    'email_verified', false,
    'phone_verified', false
  ),
  'email', u.id::text, now(), now(), now()
FROM auth.users u
WHERE u.email LIKE '%@test.com'
AND NOT EXISTS (
  SELECT 1 FROM auth.identities i WHERE i.user_id = u.id
);

-- ── Phase 2: 3 Global Verifications ──────────────────────────────────────────
-- Uses NOT EXISTS because verifications has no unique index on internal_name.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.verifications WHERE internal_name = 'global_career' AND partner_id IS NULL) THEN
    INSERT INTO public.verifications (partner_id, category, internal_name, display_name, description, icon_key, form_schema)
    VALUES (NULL, 'career', 'global_career', '직장인 인증', '재직증명서 기반 직장인 인증', 'briefcase', '[{"type":"image","label":"재직증명서"}]'::jsonb);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.verifications WHERE internal_name = 'global_academic' AND partner_id IS NULL) THEN
    INSERT INTO public.verifications (partner_id, category, internal_name, display_name, description, icon_key, form_schema)
    VALUES (NULL, 'academic', 'global_academic', '대학생 인증', '학생증 기반 대학생 인증', 'school', '[{"type":"image","label":"학생증"}]'::jsonb);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.verifications WHERE internal_name = 'global_asset' AND partner_id IS NULL) THEN
    INSERT INTO public.verifications (partner_id, category, internal_name, display_name, description, icon_key, form_schema)
    VALUES (NULL, 'asset', 'global_asset', '자산 인증', '자산 보유 인증', 'diamond', '[{"type":"text","label":"자산 정보"}]'::jsonb);
  END IF;
END $$;

-- ── Phase 3: 5 Partners + Locations + Local Verifications + Owner Permissions ─
DO $$
DECLARE
  new_partner_id uuid;
  owner_id       uuid;
  first_partner_id uuid;
  staff_users    uuid[];
BEGIN
  -- ── Partner 1: 밍글 스튜디오 (강남) ────────────────────────────────────────
  SELECT id INTO owner_id FROM auth.users WHERE email = 'partner_owner_1@test.com';

  SELECT id INTO new_partner_id FROM public.partners WHERE biz_number = '123-45-67890';
  IF new_partner_id IS NULL THEN
    INSERT INTO public.partners (name, introduction, biz_name, biz_number, contact_email)
    VALUES ('밍글 스튜디오', '서울 강남에서 운영하는 프리미엄 소셜 라운지', '(주)밍글스튜디오', '123-45-67890', 'partner1@test.com')
    RETURNING id INTO new_partner_id;
  END IF;
  first_partner_id := new_partner_id;

  INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
  VALUES (new_partner_id, owner_id, 'owner')
  ON CONFLICT (partner_id, user_id) DO UPDATE SET role = 'owner';

  IF NOT EXISTS (SELECT 1 FROM public.locations WHERE partner_id = new_partner_id AND name = '서울 강남') THEN
    INSERT INTO public.locations (partner_id, name, address, region_1, region_2, region_3, geo_point)
    VALUES (new_partner_id, '서울 강남', '서울특별시 강남구 역삼동', '서울', '강남구', '역삼동',
            public.ST_SetSRID(public.ST_MakePoint(127.0276, 37.4979), 4326));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.verifications WHERE internal_name = 'mingle_career' AND partner_id IS NOT NULL) THEN
    INSERT INTO public.verifications (partner_id, category, internal_name, display_name, description, icon_key, form_schema)
    VALUES (new_partner_id, 'career', 'mingle_career', '직장인 인증', '재직증명서 또는 명함 제출', 'briefcase', '[{"type":"image","label":"재직증명서"}]'::jsonb);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.verifications WHERE internal_name = 'mingle_academic' AND partner_id IS NOT NULL) THEN
    INSERT INTO public.verifications (partner_id, category, internal_name, display_name, description, icon_key, form_schema)
    VALUES (new_partner_id, 'academic', 'mingle_academic', '대학생 인증', '학생증 또는 재학증명서 제출', 'school', '[{"type":"image","label":"학생증"}]'::jsonb);
  END IF;

  -- ── Partner 2: 파티룸 홍대 ──────────────────────────────────────────────────
  SELECT id INTO owner_id FROM auth.users WHERE email = 'partner_owner_2@test.com';

  SELECT id INTO new_partner_id FROM public.partners WHERE biz_number = '987-65-43210';
  IF new_partner_id IS NULL THEN
    INSERT INTO public.partners (name, introduction, biz_name, biz_number, contact_email)
    VALUES ('파티룸 홍대', '홍대에서 가장 힙한 파티룸. 다양한 테마의 소셜 이벤트를 운영합니다.', '파티룸홍대', '987-65-43210', 'partner2@test.com')
    RETURNING id INTO new_partner_id;
  END IF;

  INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
  VALUES (new_partner_id, owner_id, 'owner')
  ON CONFLICT (partner_id, user_id) DO UPDATE SET role = 'owner';

  IF NOT EXISTS (SELECT 1 FROM public.locations WHERE partner_id = new_partner_id AND name = '서울 홍대') THEN
    INSERT INTO public.locations (partner_id, name, address, region_1, region_2, region_3, geo_point)
    VALUES (new_partner_id, '서울 홍대', '서울특별시 마포구 서교동', '서울', '마포구', '서교동',
            public.ST_SetSRID(public.ST_MakePoint(126.9245, 37.5575), 4326));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.verifications WHERE internal_name = 'hongdae_asset' AND partner_id IS NOT NULL) THEN
    INSERT INTO public.verifications (partner_id, category, internal_name, display_name, description, icon_key, form_schema)
    VALUES (new_partner_id, 'asset', 'hongdae_asset', '자산 인증', '프리미엄 파티 참가를 위한 자산 인증', 'diamond', '[{"type":"text","label":"자산 정보"}]'::jsonb);
  END IF;

  -- ── Partner 3: 서울 강남 소셜클럽 ──────────────────────────────────────────
  SELECT id INTO owner_id FROM auth.users WHERE email = 'partner_hotplace_0@test.com';

  SELECT id INTO new_partner_id FROM public.partners WHERE biz_number = '000-00-00000';
  IF new_partner_id IS NULL THEN
    INSERT INTO public.partners (name, introduction, biz_name, biz_number, contact_email)
    VALUES ('서울 강남 소셜클럽', '서울 강남 지역 대표 소셜 클럽', '서울 강남클럽', '000-00-00000', 'partner_hotplace_0@test.com')
    RETURNING id INTO new_partner_id;
  END IF;

  INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
  VALUES (new_partner_id, owner_id, 'owner')
  ON CONFLICT (partner_id, user_id) DO UPDATE SET role = 'owner';

  IF NOT EXISTS (SELECT 1 FROM public.locations WHERE partner_id = new_partner_id AND name = '서울 강남') THEN
    INSERT INTO public.locations (partner_id, name, address, region_1, region_2, region_3, geo_point)
    VALUES (new_partner_id, '서울 강남', '서울특별시 강남구 역삼동', '서울', '강남구', '역삼동',
            public.ST_SetSRID(public.ST_MakePoint(127.0276, 37.4979), 4326));
  END IF;

  -- ── Partner 4: 서울 홍대 소셜클럽 ──────────────────────────────────────────
  SELECT id INTO owner_id FROM auth.users WHERE email = 'partner_hotplace_1@test.com';

  SELECT id INTO new_partner_id FROM public.partners WHERE biz_number = '000-00-00001';
  IF new_partner_id IS NULL THEN
    INSERT INTO public.partners (name, introduction, biz_name, biz_number, contact_email)
    VALUES ('서울 홍대 소셜클럽', '서울 홍대 지역 대표 소셜 클럽', '서울 홍대클럽', '000-00-00001', 'partner_hotplace_1@test.com')
    RETURNING id INTO new_partner_id;
  END IF;

  INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
  VALUES (new_partner_id, owner_id, 'owner')
  ON CONFLICT (partner_id, user_id) DO UPDATE SET role = 'owner';

  IF NOT EXISTS (SELECT 1 FROM public.locations WHERE partner_id = new_partner_id AND name = '서울 홍대') THEN
    INSERT INTO public.locations (partner_id, name, address, region_1, region_2, region_3, geo_point)
    VALUES (new_partner_id, '서울 홍대', '서울특별시 마포구 서교동', '서울', '마포구', '서교동',
            public.ST_SetSRID(public.ST_MakePoint(126.9245, 37.5575), 4326));
  END IF;

  -- ── Partner 5: 서울 성수 소셜클럽 ──────────────────────────────────────────
  SELECT id INTO owner_id FROM auth.users WHERE email = 'partner_hotplace_2@test.com';

  SELECT id INTO new_partner_id FROM public.partners WHERE biz_number = '000-00-00002';
  IF new_partner_id IS NULL THEN
    INSERT INTO public.partners (name, introduction, biz_name, biz_number, contact_email)
    VALUES ('서울 성수 소셜클럽', '서울 성수 지역 대표 소셜 클럽', '서울 성수클럽', '000-00-00002', 'partner_hotplace_2@test.com')
    RETURNING id INTO new_partner_id;
  END IF;

  INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
  VALUES (new_partner_id, owner_id, 'owner')
  ON CONFLICT (partner_id, user_id) DO UPDATE SET role = 'owner';

  IF NOT EXISTS (SELECT 1 FROM public.locations WHERE partner_id = new_partner_id AND name = '서울 성수') THEN
    INSERT INTO public.locations (partner_id, name, address, region_1, region_2, region_3, geo_point)
    VALUES (new_partner_id, '서울 성수', '서울특별시 성동구 성수동', '서울', '성동구', '성수동',
            public.ST_SetSRID(public.ST_MakePoint(127.0559, 37.5445), 4326));
  END IF;

  -- ── Staff roles: first 2 legacy users as manager/staff on Partner 1 ─────────
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
END $$;

-- ── Phase 4: pgmq queue purge (best-effort — pgmq may not be available) ──────
DO $$
BEGIN
  PERFORM pgmq.purge('q_global_events');
  PERFORM pgmq.purge('q_notifications');
  PERFORM pgmq.purge('q_vectors');
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pgmq purge skipped: %', SQLERRM;
END $$;

-- ── Phase 5: dev environment setting ─────────────────────────────────────────
-- Removed: ALTER DATABASE SET requires superuser privileges not available on
-- hosted Supabase. The RPC guard that needed this setting is also being removed
-- (#1413) — seed.dev.sql runs directly via CLI, not through the RPC.
