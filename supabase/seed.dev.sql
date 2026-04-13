-- supabase/seed.dev.sql
-- DEV ONLY: 560 users (60 legacy + 500 regional) + 5 partner owners + 5 partners
--           + locations + verifications + roles + pgmq purge + env setting
--
-- Executed by GitHub Actions (dev branch only) via:
--   PGPASSWORD="..." psql "<pooler-url>" -f supabase/seed.dev.sql
--
-- Safety:
--   - Workflow guards with `if: ENV == 'dev'` — never runs on main/prod
--   - All inserts are idempotent (ON CONFLICT DO UPDATE / DO NOTHING)
--   - Runs via session-mode pooler (port 5432) for DO block + ALTER DATABASE support

-- ── Phase 1: 560 Users + 5 Partner Owners ────────────────────────────────────
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

  age          int;
  ri           int;
  gender_val   text;
  gender_short text;
  last4        text;
  prefix       int;
  username     text;
  email        text;
  birth_year   int;
  birth_date   text;
  phone_number text;
  phone_prefix int;
  verified     boolean;
  verif_short  text;
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
    birth_year := current_year - age + 1;
    birth_date := birth_year || '-01-01';

    FOR ri IN 0..9 LOOP
      prefix := 5000 + ri * 100 + (age - 18);

      FOREACH gender_val IN ARRAY ARRAY['male', 'female'] LOOP
        gender_short := CASE gender_val WHEN 'male' THEN 'm' ELSE 'f' END;
        last4        := CASE gender_val WHEN 'male' THEN '1000' ELSE '2000' END;
        username     := 'user_' || age || '_' || gender_short || '_' || regions[ri + 1][1];
        email        := username || '@test.com';
        phone_number := '010-' || prefix || '-' || last4;

        INSERT INTO auth.users (
          instance_id, id, aud, role, email, encrypted_password,
          email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
          created_at, updated_at, confirmation_token, recovery_token
        ) VALUES (
          '00000000-0000-0000-0000-000000000000',
          gen_random_uuid(), 'authenticated', 'authenticated',
          email, pwd_hash, now(),
          '{"provider":"email","providers":["email"],"has_password":true}'::jsonb,
          jsonb_build_object(
            'name',        age || CASE gender_val WHEN 'male' THEN '남' ELSE '여' END || '_' || regions[ri + 1][1],
            'username',    username,
            'gender',      gender_val,
            'birth_date',  birth_date,
            'phone_number',phone_number,
            'is_verified', true,
            'sim_region',  regions[ri + 1][1],
            'sim_lat',     regions[ri + 1][2]::numeric,
            'sim_lng',     regions[ri + 1][3]::numeric
          ),
          now(), now(), '', ''
        )
        ON CONFLICT (email) DO UPDATE SET
          encrypted_password = EXCLUDED.encrypted_password,
          raw_user_meta_data = EXCLUDED.raw_user_meta_data,
          updated_at         = now();
      END LOOP;
    END LOOP;
  END LOOP;

  -- ── 60 Legacy Users (ages 20-34, m_ok/m_no/f_ok/f_no) ───────────────────────
  -- Email pattern: user_{age}_{m|f}_{ok|no}@test.com — preserved for E2E compat
  -- Phone prefix: age ≤ 24 → 1000+age, age ≥ 25 → 2000+age
  -- last4: {verified:1|0}{male:1|female:2}00
  FOR age IN 20..34 LOOP
    birth_year   := current_year - age + 1;
    birth_date   := birth_year || '-01-01';
    phone_prefix := CASE WHEN age <= 24 THEN 1000 + age ELSE 2000 + age END;

    FOREACH gender_val IN ARRAY ARRAY['male', 'female'] LOOP
      gender_short := CASE gender_val WHEN 'male' THEN 'm' ELSE 'f' END;

      FOREACH verified IN ARRAY ARRAY[true, false] LOOP
        verif_short  := CASE WHEN verified THEN 'ok' ELSE 'no' END;
        last4        := (CASE WHEN verified THEN '1' ELSE '0' END) ||
                        (CASE WHEN gender_val = 'male' THEN '1' ELSE '2' END) || '00';
        username     := 'user_' || age || '_' || gender_short || '_' || verif_short;
        email        := username || '@test.com';
        phone_number := '010-' || phone_prefix || '-' || last4;

        INSERT INTO auth.users (
          instance_id, id, aud, role, email, encrypted_password,
          email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
          created_at, updated_at, confirmation_token, recovery_token
        ) VALUES (
          '00000000-0000-0000-0000-000000000000',
          gen_random_uuid(), 'authenticated', 'authenticated',
          email, pwd_hash, now(),
          '{"provider":"email","providers":["email"],"has_password":true}'::jsonb,
          jsonb_build_object(
            'name',        age || (CASE gender_val WHEN 'male' THEN '남' ELSE '여' END) ||
                           '_' || (CASE WHEN verified THEN '인증O' ELSE '인증X' END),
            'username',    username,
            'gender',      gender_val,
            'birth_date',  birth_date,
            'phone_number',phone_number,
            'is_verified', verified
          ),
          now(), now(), '', ''
        )
        ON CONFLICT (email) DO UPDATE SET
          encrypted_password = EXCLUDED.encrypted_password,
          raw_user_meta_data = EXCLUDED.raw_user_meta_data,
          updated_at         = now();
      END LOOP;
    END LOOP;
  END LOOP;

  -- ── 5 Partner Owners ─────────────────────────────────────────────────────────
  -- idx 0-1: birth 1990-01-01, phone 010-0000-{LPAD(idx, 4, '0')}
  -- idx 2-4: birth 1988-01-01, phone 010-0001-{LPAD(idx-2, 4, '0')}

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token
  ) VALUES
    (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(), 'authenticated', 'authenticated',
      'partner_owner_1@test.com', pwd_hash, now(),
      '{"provider":"email","providers":["email"],"has_password":true}'::jsonb,
      '{"name":"밍글 스튜디오 대표","username":"partner_owner_1","gender":"male","birth_date":"1990-01-01","phone_number":"010-0000-0000","is_verified":true}'::jsonb,
      now(), now(), '', ''
    ),
    (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(), 'authenticated', 'authenticated',
      'partner_owner_2@test.com', pwd_hash, now(),
      '{"provider":"email","providers":["email"],"has_password":true}'::jsonb,
      '{"name":"파티룸 홍대 대표","username":"partner_owner_2","gender":"male","birth_date":"1990-01-01","phone_number":"010-0000-0001","is_verified":true}'::jsonb,
      now(), now(), '', ''
    ),
    (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(), 'authenticated', 'authenticated',
      'partner_hotplace_0@test.com', pwd_hash, now(),
      '{"provider":"email","providers":["email"],"has_password":true}'::jsonb,
      '{"name":"서울 강남 소셜클럽 대표","username":"partner_hotplace_0","gender":"male","birth_date":"1988-01-01","phone_number":"010-0001-0000","is_verified":true}'::jsonb,
      now(), now(), '', ''
    ),
    (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(), 'authenticated', 'authenticated',
      'partner_hotplace_1@test.com', pwd_hash, now(),
      '{"provider":"email","providers":["email"],"has_password":true}'::jsonb,
      '{"name":"서울 홍대 소셜클럽 대표","username":"partner_hotplace_1","gender":"male","birth_date":"1988-01-01","phone_number":"010-0001-0001","is_verified":true}'::jsonb,
      now(), now(), '', ''
    ),
    (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(), 'authenticated', 'authenticated',
      'partner_hotplace_2@test.com', pwd_hash, now(),
      '{"provider":"email","providers":["email"],"has_password":true}'::jsonb,
      '{"name":"서울 성수 소셜클럽 대표","username":"partner_hotplace_2","gender":"male","birth_date":"1988-01-01","phone_number":"010-0001-0002","is_verified":true}'::jsonb,
      now(), now(), '', ''
    )
  ON CONFLICT (email) DO UPDATE SET
    encrypted_password = EXCLUDED.encrypted_password,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    updated_at         = now();
END $$;

-- ── auth.identities backfill (idempotent) ─────────────────────────────────────
INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id,
  created_at, updated_at, last_sign_in_at
)
SELECT u.id, u.id, u.raw_user_meta_data, 'email', u.email, now(), now(), now()
FROM auth.users u
WHERE u.email LIKE '%@test.com'
ON CONFLICT (provider, provider_id) DO NOTHING;

-- ── Phase 2: 3 Global Verifications ──────────────────────────────────────────
INSERT INTO public.verifications (partner_id, category, internal_name, display_name, description, icon_key, form_schema)
VALUES
  (NULL, 'career',   'global_career',   '직장인 인증', '재직증명서 기반 직장인 인증', 'briefcase', '[{"type":"image","label":"재직증명서"}]'::jsonb),
  (NULL, 'academic', 'global_academic', '대학생 인증', '학생증 기반 대학생 인증',     'school',    '[{"type":"image","label":"학생증"}]'::jsonb),
  (NULL, 'asset',    'global_asset',    '자산 인증',   '자산 보유 인증',              'diamond',   '[{"type":"text","label":"자산 정보"}]'::jsonb)
ON CONFLICT (internal_name) WHERE partner_id IS NULL DO NOTHING;

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

  INSERT INTO public.verifications (partner_id, category, internal_name, display_name, description, icon_key, form_schema)
  VALUES
    (new_partner_id, 'career',   'mingle_career',   '직장인 인증', '재직증명서 또는 명함 제출',      'briefcase', '[{"type":"image","label":"재직증명서"}]'::jsonb),
    (new_partner_id, 'academic', 'mingle_academic', '대학생 인증', '학생증 또는 재학증명서 제출',    'school',    '[{"type":"image","label":"학생증"}]'::jsonb)
  ON CONFLICT (internal_name) WHERE partner_id IS NOT NULL DO NOTHING;

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

  INSERT INTO public.verifications (partner_id, category, internal_name, display_name, description, icon_key, form_schema)
  VALUES
    (new_partner_id, 'asset', 'hongdae_asset', '자산 인증', '프리미엄 파티 참가를 위한 자산 인증', 'diamond', '[{"type":"text","label":"자산 정보"}]'::jsonb)
  ON CONFLICT (internal_name) WHERE partner_id IS NOT NULL DO NOTHING;

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

-- ── Phase 4: pgmq queue purge ─────────────────────────────────────────────────
SELECT pgmq.purge('q_global_events');
SELECT pgmq.purge('q_notifications');
SELECT pgmq.purge('q_vectors');

-- ── Phase 5: dev environment setting ─────────────────────────────────────────
-- Ensures app.settings.environment is set for all DB connections in dev.
ALTER DATABASE postgres SET app.settings.environment = 'development';
