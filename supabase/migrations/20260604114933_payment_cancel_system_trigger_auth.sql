-- Fix #2981: payment-cancel automatic refund trigger must call the EF as a
-- system caller. The old definition used publishable_key as Bearer auth, which
-- cannot satisfy the minglitEdgeFunction user/system manifest policy.

CREATE OR REPLACE FUNCTION public.handle_application_rejection()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, net
AS $$
DECLARE
  v_payment_id text;
  v_reason text;
  v_project_url text;
  v_service_role_key text;
BEGIN
  IF new.status = 'rejected' AND (old.status IS DISTINCT FROM 'rejected') THEN
    v_payment_id := new.payment_id;
    v_reason := new.rejection_reason;

    IF v_payment_id IS NOT NULL THEN
      -- Persist the requested state even if Vault or the EF call is unavailable.
      new.refund_status := 'requested';

      SELECT decrypted_secret INTO v_project_url
      FROM vault.decrypted_secrets
      WHERE name = 'supabase_url' LIMIT 1;

      SELECT decrypted_secret INTO v_service_role_key
      FROM vault.decrypted_secrets
      WHERE name = 'service_role_key' LIMIT 1;

      IF v_project_url IS NULL OR v_service_role_key IS NULL THEN
        RAISE WARNING 'handle_application_rejection: vault secret missing (supabase_url=%, service_role_key=%)',
          v_project_url IS NOT NULL, v_service_role_key IS NOT NULL;
        RETURN new;
      END IF;

      PERFORM net.http_post(
        url := v_project_url || '/functions/v1/payment-cancel',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'apikey', v_service_role_key,
          'Authorization', 'Bearer ' || v_service_role_key
        ),
        body := jsonb_build_object(
          'payment_id', v_payment_id,
          'reason', COALESCE(v_reason, '심사 반려로 인한 자동 환불'),
          'source', 'application_rejection_trigger'
        )
      );
    END IF;
  END IF;
  RETURN new;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_application_rejection failed: [%] %', SQLSTATE, SQLERRM;
  RETURN new;
END;
$$;
