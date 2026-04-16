CREATE OR REPLACE FUNCTION public.temp_auth_diag2()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  RETURN jsonb_build_object(
    'old_user_identity', (
      SELECT jsonb_build_object('provider_id', i.provider_id, 'identity_data', i.identity_data)
      FROM auth.identities i JOIN auth.users u ON i.user_id = u.id
      WHERE u.email = 'user_20_m_ok@test.com' LIMIT 1
    ),
    'new_user_identity', (
      SELECT jsonb_build_object('provider_id', i.provider_id, 'identity_data', i.identity_data)
      FROM auth.identities i JOIN auth.users u ON i.user_id = u.id
      WHERE u.email = 'user_18_m_강남@test.com' LIMIT 1
    )
  );
END;
$$;
