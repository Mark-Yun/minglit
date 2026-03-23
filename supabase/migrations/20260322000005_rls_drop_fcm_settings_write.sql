-- Issue #294: user-manage-settings EF 전환 후 클라이언트 직접 write 차단
-- fcm_tokens, user_settings의 INSERT/UPDATE/DELETE 정책을 제거하고
-- Edge Function(service_role)을 통해서만 write 가능하도록 전환한다.

-- fcm_tokens: INSERT/DELETE 정책 제거 (SELECT만 유지)
DROP POLICY IF EXISTS "Users can insert/update their own FCM tokens" ON public.fcm_tokens;
DROP POLICY IF EXISTS "Users can delete their own FCM tokens" ON public.fcm_tokens;

-- user_settings: INSERT/UPDATE 정책 제거 (SELECT만 유지)
DROP POLICY IF EXISTS "Users can insert their own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can update their own settings" ON public.user_settings;

-- GRANT 조정: authenticated에서 write 권한 제거
REVOKE INSERT, UPDATE, DELETE ON public.fcm_tokens FROM authenticated;
REVOKE INSERT, UPDATE ON public.user_settings FROM authenticated;
