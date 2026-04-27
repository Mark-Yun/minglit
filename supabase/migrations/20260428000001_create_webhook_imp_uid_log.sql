-- Fix #1949: idempotency log for PortOne V1 payment webhooks.
-- Records successfully processed imp_uid values so replayed webhooks
-- are rejected before making a duplicate cross-check call to PortOne API.
CREATE TABLE IF NOT EXISTS webhook_imp_uid_log (
  imp_uid       text        NOT NULL,
  merchant_uid  text        NOT NULL,
  processed_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT webhook_imp_uid_log_pkey PRIMARY KEY (imp_uid)
);

-- Only the payment-webhook Edge Function should write to this table.
ALTER TABLE webhook_imp_uid_log ENABLE ROW LEVEL SECURITY;

-- Service role (used by Edge Functions) bypasses RLS by default.
-- No explicit policy needed — RLS is enabled to block anon/authenticated roles.
