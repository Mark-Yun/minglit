-- Fix NULL string columns in auth.users that GoTrue expects to be empty string ''.
UPDATE auth.users SET
  email_change = COALESCE(email_change, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  email_change_token_current = COALESCE(email_change_token_current, ''),
  phone_change = COALESCE(phone_change, ''),
  phone_change_token = COALESCE(phone_change_token, ''),
  reauthentication_token = COALESCE(reauthentication_token, '')
WHERE email LIKE '%@test.com'
AND (email_change IS NULL OR email_change_token_new IS NULL);

-- Cleanup
DROP FUNCTION IF EXISTS public.temp_compare_users();
