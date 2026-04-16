CREATE OR REPLACE FUNCTION public.temp_auth_diag2()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  RETURN jsonb_build_object(
    'total', (SELECT count(*) FROM auth.users),
    'null_phone', (SELECT count(*) FROM auth.users WHERE phone IS NULL),
    'empty_phone', (SELECT count(*) FROM auth.users WHERE phone = ''),
    'no_identity', (SELECT count(*) FROM auth.users u WHERE NOT EXISTS (SELECT 1 FROM auth.identities i WHERE i.user_id = u.id)),
    'multi_identity', (SELECT count(*) FROM (SELECT user_id FROM auth.identities GROUP BY user_id HAVING count(*) > 1) s),
    'new_user_sample', (SELECT jsonb_agg(jsonb_build_object(
      'email', u.email, 'phone', u.phone, 'is_sso', u.is_sso_user, 'is_anon', u.is_anonymous,
      'has_identity', EXISTS(SELECT 1 FROM auth.identities i WHERE i.user_id = u.id)
    )) FROM auth.users u WHERE u.email LIKE 'user_18_m_%' LIMIT 3)
  );
END;
$$;
