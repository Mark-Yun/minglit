-- backend-simulator v2 cascade 의 blocking invariant 가 호출하는 RPC.
--
-- 규칙: 유저가 partner 를 block 한 시점 이후 (social_interactions.created_at <
-- event_applications.refunded_at) 의 환불이 존재하면 위반. EF user-cancel-order
-- 가 block 상태를 검사해 거부해야 정상.
--
-- 본 함수는 위반 row 만 반환 (각 row 가 InvariantViolation.details 가 됨).
-- 빈 결과 = 통과.

set search_path to public, extensions;

CREATE OR REPLACE FUNCTION public.sim_invariant_blocking_refund_denied()
RETURNS TABLE(
  application_id uuid,
  user_id uuid,
  partner_id uuid,
  refunded_at timestamptz,
  block_created_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  SELECT
    a.id          AS application_id,
    a.user_id,
    p.partner_id,
    a.refunded_at,
    s.created_at  AS block_created_at
  FROM public.event_applications a
  JOIN public.events  e ON e.id = a.event_id
  JOIN public.parties p ON p.id = e.party_id
  JOIN public.social_interactions s
    ON s.user_id     = a.user_id
   AND s.target_id   = p.partner_id
   AND s.target_type = 'partner'
   AND s.interaction_type = 'block'
  WHERE a.refunded_at IS NOT NULL
    AND s.created_at < a.refunded_at;
$$;

REVOKE ALL ON FUNCTION public.sim_invariant_blocking_refund_denied() FROM public;
GRANT EXECUTE ON FUNCTION public.sim_invariant_blocking_refund_denied() TO service_role;

COMMENT ON FUNCTION public.sim_invariant_blocking_refund_denied() IS
  'backend-simulator v2 invariant: blocked partner 의 event 에 환불 발생 시 위반 row 반환';
