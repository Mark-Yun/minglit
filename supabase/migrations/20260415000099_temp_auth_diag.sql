CREATE OR REPLACE FUNCTION public.temp_auth_diag()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE r jsonb;
BEGIN
  SELECT jsonb_build_object(
    'total', (SELECT count(*) FROM auth.users),
    'null_sso', (SELECT count(*) FROM auth.users WHERE is_sso_user IS NULL),
    'null_anon', (SELECT count(*) FROM auth.users WHERE is_anonymous IS NULL),
    'null_phone', (SELECT count(*) FROM auth.users WHERE phone IS NULL),
    'no_identity', (SELECT count(*) FROM auth.users u WHERE NOT EXISTS (SELECT 1 FROM auth.identities i WHERE i.user_id = u.id)),
    'multi_identity', (SELECT count(*) FROM (SELECT user_id FROM auth.identities GROUP BY user_id HAVING count(*) > 1) s),
    'sample_new', (SELECT jsonb_agg(row_to_json(x)) FROM (SELECT email, is_sso_user, is_anonymous, phone, aud, role FROM auth.users WHERE email LIKE 'user_18_m_%' LIMIT 2) x)
  ) INTO r;
  RETURN r;
END;
$$;
