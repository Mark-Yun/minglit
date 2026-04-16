-- Fix new user identities: update provider_id and identity_data to match GoTrue format.
-- GoTrue expects:
--   provider_id = user UUID (not email)
--   identity_data = {"sub": UUID, "email": email, "email_verified": false, "phone_verified": false}

UPDATE auth.identities i
SET
  provider_id = u.id::text,
  identity_data = jsonb_build_object(
    'sub', u.id::text,
    'email', u.email,
    'email_verified', false,
    'phone_verified', false
  )
FROM auth.users u
WHERE i.user_id = u.id
AND i.provider = 'email'
AND NOT (i.identity_data ? 'sub');  -- only fix identities missing 'sub' field

-- Cleanup temp diagnostic
DROP FUNCTION IF EXISTS public.temp_auth_diag2();
