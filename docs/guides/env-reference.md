# Environment Variable Reference

> Auto-generated from `env-manifest.json`. Do not edit manually.
> Manifest version: 1.0

## Flutter

| Key | Description | Required |
|-----|-------------|----------|
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase publishable key | Yes |
| `ENVIRONMENT` | development / production | Yes |
| `SENTRY_DSN` | Sentry error tracking | No |
| `STATSIG_CLIENT_KEY` | Statsig feature flags | No |
| `GOOGLE_WEB_CLIENT_ID` | Google OAuth client ID | No |
| `KAKAO_LOCAL_REST_API_KEY` | Kakao Local REST API | No |
| `KAKAO_MAP_JAVASCRIPT_KEY` | Kakao Map JS key | No |
| `JUSO_CONFIRM_KEY` | 주소 API 확인키 | No |
| `IAMPORT_USER_CODE` | PortOne identity verification | No |
| `MOBILE_REDIRECT_SCHEME` | OAuth redirect scheme | No |

## Edge Functions (common)

| Key | Description | Required |
|-----|-------------|----------|
| `SUPABASE_URL` | Supabase project URL (auto-injected) | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role JWT (auto-injected) | Yes |
| `SENTRY_DSN` | Sentry error tracking | No |
| `AXIOM_API_TOKEN` | Axiom structured logging | No |
| `AXIOM_DATASET` | Axiom dataset name | No |
| `ENVIRONMENT` | Runtime environment | No |
| `STATSIG_SERVER_KEY` | Statsig server-side | No |

### notification-worker

| Key | Description | Required |
|-----|-------------|----------|
| `FIREBASE_SERVICE_ACCOUNT` | FCM push notifications | Yes |

### payment-verify

| Key | Description | Required |
|-----|-------------|----------|
| `PORTONE_API_KEY` | PortOne V1 API key | Yes |
| `PORTONE_API_SECRET` | PortOne V1 API secret | Yes |

### payment-cancel

| Key | Description | Required |
|-----|-------------|----------|
| `PORTONE_API_KEY` | PortOne V1 API key | Yes |
| `PORTONE_API_SECRET` | PortOne V1 API secret | Yes |

### user-cancel-order

| Key | Description | Required |
|-----|-------------|----------|
| `PORTONE_API_KEY` | PortOne V1 API key | Yes |
| `PORTONE_API_SECRET` | PortOne V1 API secret | Yes |

### payment-webhook

| Key | Description | Required |
|-----|-------------|----------|
| `PORTONE_API_KEY` | PortOne V1 API key | Yes |
| `PORTONE_API_SECRET` | PortOne V1 API secret | Yes |

### settlement-register-transfers

| Key | Description | Required |
|-----|-------------|----------|
| `PORTONE_V2_API_KEY` | PortOne V2 API key | Yes |

### payout-sync

| Key | Description | Required |
|-----|-------------|----------|
| `PORTONE_V2_API_KEY` | PortOne V2 API key | Yes |

### partner-sync

| Key | Description | Required |
|-----|-------------|----------|
| `PORTONE_V2_API_KEY` | PortOne V2 API key | Yes |

### identity-verify

| Key | Description | Required |
|-----|-------------|----------|
| `PORTONE_V2_API_KEY` | PortOne V2 API key | Yes |

### reconciliation-daily

| Key | Description | Required |
|-----|-------------|----------|
| `PORTONE_V2_API_KEY` | PortOne V2 API key | Yes |

### vector-worker

| Key | Description | Required |
|-----|-------------|----------|
| `OPENAI_API_KEY` | OpenAI embedding API | Yes |

### bug-report

| Key | Description | Required |
|-----|-------------|----------|
| `GITHUB_ACCESS_TOKEN` | GitHub issue creation | Yes |

### metrics-alert

| Key | Description | Required |
|-----|-------------|----------|
| `GITHUB_ACCESS_TOKEN` | GitHub issue creation | Yes |

### github-stats-sync

| Key | Description | Required |
|-----|-------------|----------|
| `GITHUB_ACCESS_TOKEN` | GitHub API (higher rate limit) | No |

### backend-simulator

| Key | Description | Required |
|-----|-------------|----------|
| `ENVIRONMENT` | Dev guard (must be development) | Yes |

## Next.js (landing_user)

| Key | Description | Required |
|-----|-------------|----------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase URL | Yes |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Publishable key | Yes |
| `NEXT_PUBLIC_STATSIG_CLIENT_KEY` | Statsig client-side | No |

## Next.js (landing_partner)

| Key | Description | Required |
|-----|-------------|----------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase URL | Yes |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Publishable key | Yes |
| `NEXT_PUBLIC_STATSIG_CLIENT_KEY` | Statsig client-side | No |

## GitHub Secrets

| Key | Description | Required |
|-----|-------------|----------|
| `SUPABASE_ACCESS_TOKEN` | Supabase CLI auth | Yes |
| `SUPABASE_DEV_DB_PASSWORD` | Dev DB password | Yes |
| `SUPABASE_DEV_PROJECT_ID` | Dev project ref | Yes |
| `SUPABASE_DEV_PUBLISHABLE_KEY` | Dev publishable key | Yes |
| `SUPABASE_DEV_SECRET_KEY` | Dev service role key | Yes |
| `SUPABASE_MAIN_DB_PASSWORD` | Main DB password | Yes |
| `SUPABASE_MAIN_PROJECT_ID` | Main project ref | Yes |
| `SUPABASE_MAIN_PUBLISHABLE_KEY` | Main publishable key | Yes |
| `OPENAI_API_KEY` | OpenAI API | Yes |
| `GH_PAT_FOR_BUG_REPORT` | GitHub PAT for issues | Yes |
| `SENTRY_DSN_EDGE_FUNCTIONS` | Sentry DSN for EF | Yes |
| `STATSIG_SERVER_KEY` | Statsig server | No |
| `AXIOM_API_TOKEN` | Axiom logging | No |
| `CODECOV_TOKEN` | Codecov upload | No |

## Vault

| Key | Description | Required |
|-----|-------------|----------|
| `publishable_key` | Legacy anon JWT for pg_cron -> EF auth | Yes |
| `supabase_url` | Project URL for pg_cron -> EF calls | Yes |

