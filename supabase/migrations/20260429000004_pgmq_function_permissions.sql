-- Fix #2040: SECURITY DEFINER pgmq 래퍼 함수들의 실행 권한을 service_role 전용으로 제한
-- 2026-03-15 이후 컨벤션: SECURITY DEFINER 함수는 REVOKE ALL + GRANT TO service_role

revoke all on function public.pgmq_read(text, int, int) from public, anon, authenticated;
grant execute on function public.pgmq_read(text, int, int) to service_role;

revoke all on function public.pgmq_delete_batch(text, bigint[]) from public, anon, authenticated;
grant execute on function public.pgmq_delete_batch(text, bigint[]) to service_role;

revoke all on function public.pgmq_delete(text, bigint) from public, anon, authenticated;
grant execute on function public.pgmq_delete(text, bigint) to service_role;

revoke all on function public.pgmq_pop(text) from public, anon, authenticated;
grant execute on function public.pgmq_pop(text) to service_role;

revoke all on function public.pgmq_send(text, jsonb) from public, anon, authenticated;
grant execute on function public.pgmq_send(text, jsonb) to service_role;
