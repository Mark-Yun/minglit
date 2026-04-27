-- Fix #1870: Drop temporary diagnostic SECURITY DEFINER functions added for
-- auth debugging. These are no longer needed in production.
DROP FUNCTION IF EXISTS public.temp_auth_diag();
DROP FUNCTION IF EXISTS public.temp_auth_diag2();
DROP FUNCTION IF EXISTS public.temp_compare_users();
