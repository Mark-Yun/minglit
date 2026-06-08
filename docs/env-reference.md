# Environment Variable Reference

> Auto-generated from `env-manifest.json`. Do not edit manually.
> Manifest version: 1.0

## Flutter

| Key | Description | Required |
|-----|-------------|----------|
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase publishable key | Yes |
| `ENVIRONMENT` | local / development / dev / production | Yes |
| `IS_DEMO` | Demo flavor flag — short-circuits all network SDK init when true | No |
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
| `SUPABASE_SERVICE_ROLE_KEY` | Legacy service_role JWT (auto-injected) | Yes |
| `SUPABASE_SECRET_KEYS` | Supabase sb_secret API key JSON dictionary (auto-injected in hosted Edge Functions) | No |
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
| `PORTONE_V2_API_KEY` | PortOne V2 API key for web payment verification | Yes |

### user-create-order

| Key | Description | Required |
|-----|-------------|----------|
| `PORTONE_V2_STORE_ID` | PortOne V2 public store id for browser checkout | Yes |
| `PORTONE_V2_CHANNEL_KEY` | PortOne V2 public channel key for browser checkout | Yes |
| `LANDING_USER_ORIGIN` | User landing origin used to build PortOne checkout redirectUrl | No |

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

### event-flow-simulator

| Key | Description | Required |
|-----|-------------|----------|
| `ENVIRONMENT` | Dev guard (dev) | Yes |
| `GITHUB_ACCESS_TOKEN` | GitHub issue/status reporting for simulator failures | Yes |

### ai-embed

| Key | Description | Required |
|-----|-------------|----------|
| `OPENAI_API_KEY` | OpenAI embedding API | Yes |

### ai-extract-tags

| Key | Description | Required |
|-----|-------------|----------|
| `OPENAI_API_KEY` | OpenAI API key for tag extraction | Yes |

### user-get-ticket-token

| Key | Description | Required |
|-----|-------------|----------|
| `TICKET_SIGNING_PRIVATE_KEY_JWK` | Ed25519 private key (OKP JWK) for signing ticket QR tokens | Yes |

### event-checkin

| Key | Description | Required |
|-----|-------------|----------|
| `TICKET_SIGNING_PUBLIC_KEY_JWK` | Ed25519 public key (OKP JWK) for verifying QR token signatures | Yes |

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
| `SUPABASE_DEV_SECRET_KEY` | Dev elevated Supabase API key (legacy service_role JWT or sb_secret_ secret key) | Yes |
| `SUPABASE_MAIN_DB_PASSWORD` | Main DB password | Yes |
| `SUPABASE_MAIN_PROJECT_ID` | Main project ref | Yes |
| `SUPABASE_MAIN_PUBLISHABLE_KEY` | Main publishable key | Yes |
| `SUPABASE_MAIN_SECRET_KEY` | Main elevated Supabase API key (legacy service_role JWT or sb_secret_ secret key) | Yes |
| `OPENAI_API_KEY` | OpenAI API | Yes |
| `GH_PAT_FOR_BUG_REPORT` | GitHub PAT for issues | Yes |
| `SENTRY_DSN_EDGE_FUNCTIONS` | Sentry DSN for EF | Yes |
| `STATSIG_SERVER_KEY` | Statsig server | No |
| `AXIOM_API_TOKEN` | Axiom logging | No |
| `CODECOV_TOKEN` | Codecov upload | No |
| `SIM_USER_PASSWORD` | Dev simulator user password (event-flow-simulator EF 전용) | No |

## Vault

| Key | Description | Required |
|-----|-------------|----------|
| `service_role_key` | Elevated Supabase API key for pg_cron -> EF auth (legacy service_role JWT or sb_secret_ secret key) | Yes |
| `supabase_url` | Project URL for pg_cron -> EF calls | Yes |
