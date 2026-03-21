-- Fix #189: get_event_ticket_balance_status에서 allowed 필드가 string으로 반환되는 버그 수정
-- 원인: ->> 연산자가 jsonb boolean을 text로 변환 → Dart 클라이언트에서 bool 캐스팅 실패
-- 수정: allowed 필드에 -> 연산자 사용하여 jsonb boolean 타입 유지

create or replace function public.get_event_ticket_balance_status(
  p_event_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb := '[]'::jsonb;
  v_ticket record;
  v_check_result jsonb;
begin
  for v_ticket in
    select id, name from public.tickets where event_id = p_event_id
  loop
    v_check_result := public.check_party_balance(p_event_id, v_ticket.id);
    -- Fix #189: -> 연산자로 boolean 타입 유지 (->>'allowed'는 text로 변환됨)
    v_result := v_result || jsonb_build_array(
      jsonb_build_object(
        'ticket_id', v_ticket.id,
        'ticket_name', v_ticket.name,
        'allowed', v_check_result->'allowed',
        'reason', v_check_result->>'reason'
      )
    );
  end loop;

  return v_result;
end;
$$;
