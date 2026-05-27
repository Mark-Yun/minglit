#!/usr/bin/env bash
set -euo pipefail

: "${SUPABASE_DEV_PROJECT_ID:?SUPABASE_DEV_PROJECT_ID is required}"
: "${SUPABASE_DEV_DB_PASSWORD:?SUPABASE_DEV_DB_PASSWORD is required}"
: "${TARGET_REF:?TARGET_REF is required}"
: "${TARGET_SHA:?TARGET_SHA is required}"
: "${GITHUB_ACCESS_TOKEN:?GITHUB_ACCESS_TOKEN is required for event-flow-simulator failure reporting}"
: "${POOLER_HOST:=aws-1-ap-northeast-2.pooler.supabase.com}"

if [ "${TARGET_REF}" != "dev" ]; then
  echo "::error::event-flow simulator cron can only be installed for TARGET_REF=dev"
  exit 1
fi

if ! [[ "${TARGET_SHA}" =~ ^[0-9a-fA-F]{40}$ ]]; then
  echo "::error::TARGET_SHA must be a full 40-character commit SHA"
  exit 1
fi

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

target_sha_esc="$(sql_escape "${TARGET_SHA}")"
conn_url="postgresql://postgres.${SUPABASE_DEV_PROJECT_ID}@${POOLER_HOST}:5432/postgres?sslmode=require"

PGPASSWORD="${SUPABASE_DEV_DB_PASSWORD}" psql "${conn_url}" -v ON_ERROR_STOP=1 <<SQL
DO \$\$
DECLARE
  job_id bigint;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM vault.decrypted_secrets
    WHERE name = 'supabase_url'
      AND decrypted_secret IS NOT NULL
      AND decrypted_secret <> ''
  ) THEN
    RAISE EXCEPTION 'vault secret supabase_url is required before installing dev-event-flow-simulator cron';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM vault.decrypted_secrets
    WHERE name = 'service_role_key'
      AND decrypted_secret IS NOT NULL
      AND decrypted_secret <> ''
  ) THEN
    RAISE EXCEPTION 'vault secret service_role_key is required before installing dev-event-flow-simulator cron';
  END IF;

  FOR job_id IN
    SELECT jobid
    FROM cron.job
    WHERE jobname IN (
      'dev-event-flow-simulator',
      'dev-event-flow-simulator-5m',
      'dev_event_flow_simulator',
      'dev_event_flow_simulator_5m',
      'event-flow-simulator-5m',
      'event_flow_simulator_5m'
    )
  LOOP
    PERFORM cron.unschedule(job_id);
  END LOOP;

  INSERT INTO public.ef_auth_manifest (ef_name, required_auth, description)
  VALUES (
    'event-flow-simulator',
    'service_role',
    'Dev event-flow simulator - pg_cron distributed soak tick'
  )
  ON CONFLICT (ef_name) DO UPDATE
    SET required_auth = EXCLUDED.required_auth,
        description = EXCLUDED.description;
END
\$\$;

SELECT cron.schedule(
  'dev-event-flow-simulator',
  '*/5 * * * *',
  \$cron\$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/event-flow-simulator',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (
          SELECT decrypted_secret FROM vault.decrypted_secrets
          WHERE name = 'service_role_key' LIMIT 1
        )
      ),
      body := jsonb_build_object(
        'ticks', 1,
        'usersPerTick', 5,
        'partnersPerTick', 2,
        'delayBetweenCallsMs', 400,
        'seed', extract(epoch from clock_timestamp())::bigint,
        'targetRef', 'dev',
        'targetSha', '${target_sha_esc}'
      )
    ) AS request_id;
  \$cron\$
);

SELECT jobid, jobname, schedule, active
FROM cron.job
WHERE jobname = 'dev-event-flow-simulator';
SQL
