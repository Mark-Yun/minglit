-- Fix #594: PGMQ 시스템 테이블 RLS 정책 추가
-- processed_events, dead_letter_queue, event_routes는 RLS가 활성화되어 있으나
-- 정책이 없어 의도가 불명확했음. service_role 전용 정책을 명시적으로 추가한다.

CREATE POLICY "service_role_only" ON public.processed_events
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_only" ON public.dead_letter_queue
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "service_role_only" ON public.event_routes
  FOR ALL USING (auth.role() = 'service_role');
