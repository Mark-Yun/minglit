CREATE OR REPLACE FUNCTION public.temp_compare_users()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  RETURN jsonb_build_object(
    'old', (SELECT row_to_json(u) FROM auth.users u WHERE email = 'user_20_m_ok@test.com'),
    'new', (SELECT row_to_json(u) FROM auth.users u WHERE email = 'user_18_m_강남@test.com')
  );
END;
$$;
