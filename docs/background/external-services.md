# External Services Inventory

> **목적**: 코드·문서·env-reference에서 추출한 외부 벤더 기술 정보(WHAT). 비즈니스 결정(WHY)은 `<TODO:>` 플레이스홀더로 표시.
> **정렬**: 카테고리별 그룹화.

---

## 카테고리 목차

1. [Backend Infrastructure](#1-backend-infrastructure)
2. [Authentication](#2-authentication)
3. [Payment](#3-payment)
4. [AI / ML](#4-ai--ml)
5. [Observability](#5-observability)
6. [Deployment](#6-deployment)
7. [Tooling](#7-tooling)

---

## 1. Backend Infrastructure

### Supabase

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Supabase (Database + Auth + Storage + Edge Functions + Realtime) |
| **역할** | 플랫폼 전체의 백엔드 인프라. PostgreSQL DB, 인증(JWT 발급·OAuth), 파일 스토리지(3개 버킷), Deno 기반 Edge Functions(40+ 함수), Realtime(체크인 통계 실시간 구독)을 단일 플랫폼으로 제공. |
| **코드 위치** | `supabase/`, `shared/packages/minglit_kit/lib/src/data/repositories/`, `supabase/functions/_shared/supabase_client.ts` |
| **환경변수** | `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` (Flutter/Next.js), `SUPABASE_SERVICE_ROLE_KEY` (Edge Functions, auto-injected), `SUPABASE_ACCESS_TOKEN` (CI), `SUPABASE_DEV_PROJECT_ID`, `SUPABASE_MAIN_PROJECT_ID` |
| **왜 이 벤더?** | `<TODO: Supabase를 선택한 이유 — Firebase 대비 장단점, 비용, PostgreSQL 필요성>` |
| **계약 / tier / 비용** | `<TODO: 현재 plan tier, 월 비용, row limit, storage limit>` |
| **핵심 한계** | `<TODO: connection pool 한계, Edge Function 실행 timeout, Realtime 동시 구독 수 제한>` |
| **다운 시 영향** | `<TODO: Supabase 전면 장애 시 서비스 불가 범위 — 읽기·쓰기·인증·알림 모두 영향>` |
| **대안 검토** | `<TODO: Firebase, PlanetScale, Neon 등 대안 검토 여부>` |

---

### Firebase (FCM)

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Google Firebase Cloud Messaging (FCM) |
| **역할** | iOS/Android 유저 대상 푸시 알림 발송. `notification-worker` Edge Function이 PGMQ `q_notifications` 큐를 polling하며 FCM Admin SDK로 토큰별 푸시를 발송. `fcm_tokens` 테이블에 device_type(android/ios/web)별 토큰 저장. |
| **코드 위치** | `supabase/functions/notification-worker/`, `fcm_tokens` 테이블 |
| **환경변수** | `FIREBASE_SERVICE_ACCOUNT` (notification-worker 전용, Required) |
| **왜 이 벤더?** | `<TODO: FCM 선택 이유 — APNs 직접 연동 대비, 비용, iOS/Android 통일 처리>` |
| **계약 / tier / 비용** | `<TODO: FCM은 무료 tier 사용 중? 메시지 수 제한?>` |
| **핵심 한계** | `<TODO: FCM 메시지 전달 보장 없음(best-effort), 토큰 만료 처리>` |
| **다운 시 영향** | `<TODO: FCM 장애 시 푸시 알림 미발송 — 인앱 알림(user_notifications)은 별도 유지>` |
| **대안 검토** | `<TODO: OneSignal, Expo Push 등 대안 검토 여부>` |

---

## 2. Authentication

### Kakao Login

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Kakao OAuth 2.0 (카카오 로그인) |
| **역할** | 유저 소셜 로그인. Supabase Auth의 OAuth provider로 통합. Flutter 앱에서 Kakao SDK를 통해 인가 코드를 받아 Supabase Auth에 전달. 지도 기능에 Kakao Local REST API와 Kakao Map JS도 별도 사용. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/features/auth/`, Supabase Auth OAuth 설정 |
| **환경변수** | `KAKAO_LOCAL_REST_API_KEY` (Flutter), `KAKAO_MAP_JAVASCRIPT_KEY` (Flutter/Web) |
| **왜 이 벤더?** | `<TODO: 국내 유저 기반 — 카카오 로그인 선택 이유, 전환율>` |
| **계약 / tier / 비용** | `<TODO: 카카오 API 비용 구조 — 호출 수 제한, Kakao Map 사용량>` |
| **핵심 한계** | `<TODO: 카카오 API 정책 변경 리스크, 해외 유저 미지원>` |
| **다운 시 영향** | `<TODO: 카카오 로그인 불가 시 Apple/Google 대체 여부>` |
| **대안 검토** | `<TODO: 네이버 로그인, 전화번호 OTP 대안 검토>` |

---

### Apple Sign-In

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Apple Sign-In (Apple OAuth) |
| **역할** | iOS 유저 소셜 로그인. App Store 배포 앱에서 소셜 로그인을 제공하는 경우 Apple Sign-In 지원이 Apple 정책상 필수. Supabase Auth OAuth provider로 통합. `MOBILE_REDIRECT_SCHEME`으로 딥링크 처리. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/features/auth/`, Supabase Auth OAuth 설정 |
| **환경변수** | `MOBILE_REDIRECT_SCHEME` (Flutter OAuth redirect) |
| **왜 이 벤더?** | `<TODO: Apple 정책 의무 여부 + iOS 유저 비중>` |
| **계약 / tier / 비용** | `<TODO: Apple Developer 계정 비용 — $99/year>` |
| **핵심 한계** | `<TODO: Apple이 이메일을 숨길 수 있어 이메일 의존 로직 주의 필요>` |
| **다운 시 영향** | `<TODO: Apple 인증 서버 장애 시 iOS 유저 로그인 불가>` |
| **대안 검토** | `<TODO: 전화번호 OTP fallback 여부>` |

---

### Google Sign-In

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Google OAuth 2.0 |
| **역할** | 유저 소셜 로그인. Supabase Auth OAuth provider로 통합. `GOOGLE_WEB_CLIENT_ID`로 Web/Flutter 모두 커버. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/features/auth/`, Supabase Auth OAuth 설정 |
| **환경변수** | `GOOGLE_WEB_CLIENT_ID` (Flutter) |
| **왜 이 벤더?** | `<TODO: Android 유저 기반 — Google 계정 보급률>` |
| **계약 / tier / 비용** | `<TODO: Google OAuth는 무료, GCP 프로젝트 비용 여부>` |
| **핵심 한계** | `<TODO: Google Play 정책 변경 리스크>` |
| **다운 시 영향** | `<TODO: Google 장애 시 Android 유저 로그인 영향>` |
| **대안 검토** | `<TODO: 전화번호 OTP fallback 여부>` |

---

### PortOne / Iamport (본인인증)

> 결제 역할은 §3 Payment 참고. 여기서는 신원인증(identity-verify) 역할만 기술.

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | PortOne V2 PASS/SMS (본인인증) |
| **역할** | Layer 1 Identity Verification. `identity-verify` Edge Function이 PortOne V2 API의 `getIdentityVerification()`을 호출해 PASS 또는 SMS 본인인증 결과를 검증. 이름, 생년월일, 성별, 전화번호, CI/DI 추출 후 `user_profiles` 업데이트. |
| **코드 위치** | `supabase/functions/identity-verify/`, `supabase/functions/_shared/portone_client.ts` |
| **환경변수** | `PORTONE_V2_API_KEY` (identity-verify 전용) |
| **왜 이 벤더?** | `<TODO: PASS 본인인증 선택 이유 — 통신사 3사 커버, CI/DI 제공>` |
| **계약 / tier / 비용** | `<TODO: 본인인증 건당 비용>` |
| **핵심 한계** | `<TODO: PASS 앱 미설치 유저, 외국인 처리 방식>` |
| **다운 시 영향** | `<TODO: 본인인증 불가 시 신규 가입 차단 영향>` |
| **대안 검토** | `<TODO: KCB, NICE 등 타 본인인증 기관 검토 여부>` |

---

### JUSO API (도로명 주소)

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | 행정안전부 도로명 주소 API (juso.go.kr) |
| **역할** | 파트너 장소(Location) 등록 시 주소 검색. Flutter 앱에서 `JUSO_CONFIRM_KEY`를 이용해 API를 호출하고 표준화된 도로명 주소를 입력받음. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/ui/` (주소 검색 UI), `apps/app_partner/lib/src/features/party/` (파티 장소 편집) |
| **환경변수** | `JUSO_CONFIRM_KEY` (Flutter, Optional) |
| **왜 이 벤더?** | `<TODO: 공공 API 선택 이유 — 무료, 표준 주소 체계>` |
| **계약 / tier / 비용** | `<TODO: 무료 공공 API이나 일일 호출 수 제한 확인 필요>` |
| **핵심 한계** | `<TODO: 해외 주소 미지원, API 안정성(공공 인프라)>` |
| **다운 시 영향** | `<TODO: 주소 검색 불가 — 수동 입력 fallback 여부>` |
| **대안 검토** | `<TODO: Kakao 주소 검색 API 대안>` |

---

## 3. Payment

### PortOne / Iamport V1 (결제)

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | PortOne (구 Iamport) — Iamport V1 REST API |
| **역할** | 이벤트 티켓 결제 처리. Flutter 앱에서 Iamport SDK로 결제 요청 → `payment-verify` EF에서 API 재검증 + 금액 위변조 체크 → `payment-webhook` EF에서 PG 웹훅 수신(IP Whitelist 방어). 부분 환불 지원(`payment-cancel` EF). |
| **코드 위치** | `supabase/functions/payment-verify/`, `supabase/functions/payment-webhook/`, `supabase/functions/payment-cancel/`, `supabase/functions/_shared/iamport_client.ts`, `shared/packages/minglit_iamport_v1/` |
| **환경변수** | `PORTONE_API_KEY`, `PORTONE_API_SECRET` (payment-verify, payment-cancel, payment-webhook, user-cancel-order 모두 사용) |
| **왜 이 벤더?** | `<TODO: Iamport V1 선택 이유, V2 전환 계획 여부>` |
| **계약 / tier / 비용** | `<TODO: PG 수수료 구조 — 현재 코드에 3.5% 하드코딩됨>` |
| **핵심 한계** | Iamport V1은 웹훅 HMAC 서명 미지원 → IP Whitelist(`52.78.100.19`, `52.78.48.223`, `52.78.17.128`) 의존. 부분 환불 이력 다건 미관리. |
| **다운 시 영향** | `<TODO: PG 장애 시 결제 불가 — 이벤트 신청 차단 영향>` |
| **대안 검토** | `<TODO: 토스페이먼츠, NicePay 등 대안 PG 검토 여부>` |

---

### PortOne V2 (정산)

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | PortOne V2 REST API (정산·이체) |
| **역할** | 파트너 정산 이체 처리. `settlement-register-transfers`, `payout-sync`, `partner-sync`, `reconciliation-daily` Edge Functions에서 V2 API 사용. `portone_client.ts`(209 LOC)가 V2 API를 래핑. |
| **코드 위치** | `supabase/functions/_shared/portone_client.ts`, `supabase/functions/settlement-register-transfers/`, `supabase/functions/payout-sync/`, `supabase/functions/reconciliation-daily/` |
| **환경변수** | `PORTONE_V2_API_KEY` (settlement-register-transfers, payout-sync, partner-sync, identity-verify, reconciliation-daily) |
| **왜 이 벤더?** | `<TODO: 정산 기능을 V2로 분리한 이유 — partner 동기화, 정산 API 지원 여부>` |
| **계약 / tier / 비용** | `<TODO: 플랫폼 수수료 5% 하드코딩 — 실제 PortOne 정산 수수료와의 관계>` |
| **핵심 한계** | `<TODO: PortOne V2 정산 API SLA, 이체 처리 시간>` |
| **다운 시 영향** | `<TODO: 정산 이체 실패 시 FAILED/HOLD 상태 — 관리자 수동 개입 필요>` |
| **대안 검토** | `<TODO: 직접 은행 API 연동 대안 검토>` |

---

## 4. AI / ML

### OpenAI

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | OpenAI API (Embeddings + Chat Completions) |
| **역할** | 두 가지 용도: 1) `ai-embed` EF — text-embedding-ada-002 (또는 compatible) 모델로 파티/유저 1536차원 벡터 생성 → `party_embeddings`/`user_embeddings`에 저장 → 개인화 추천에 사용. 2) `ai-extract-tags` EF — 파티 설명에서 태그 자동 추출. |
| **코드 위치** | `supabase/functions/ai-embed/`, `supabase/functions/ai-extract-tags/` |
| **환경변수** | `OPENAI_API_KEY` (ai-embed, ai-extract-tags, GitHub Secrets) |
| **왜 이 벤더?** | `<TODO: OpenAI 선택 이유 — 임베딩 품질, 비용, 대안(Cohere, HuggingFace) 검토>` |
| **계약 / tier / 비용** | `<TODO: 임베딩 API 비용 — $0.0001/1K tokens, 월 예상 사용량>` |
| **핵심 한계** | OpenAI API 장애 시 임베딩 생성 불가(추천 갱신 중단). 배치 최대 50건. 모델 버전 변경 시 기존 벡터와 차원 불일치 리스크. |
| **다운 시 영향** | `<TODO: 신규 파티 추천 갱신 중단 — 기존 벡터로 서비스 지속 가능 여부>` |
| **대안 검토** | `<TODO: Cohere Embed, Voyage AI, 자체 임베딩 서버 검토>` |

---

### Anthropic

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Anthropic (Claude API) |
| **역할** | 코드에서 직접적인 운영 사용 확인 불가. `env-reference.md`나 Edge Function 환경변수에 Anthropic 관련 키 없음. OMC(oh-my-claudecode) 개발 도구로는 사용 중이나 프로덕션 백엔드 통합은 미확인. |
| **코드 위치** | 확인된 코드 위치 없음 |
| **환경변수** | 확인된 환경변수 없음 |
| **왜 이 벤더?** | `<TODO: 운영 환경에서 사용 여부 확인 필요>` |
| **계약 / tier / 비용** | `<TODO: 미사용이라면 N/A>` |
| **핵심 한계** | `<TODO: N/A>` |
| **다운 시 영향** | `<TODO: N/A>` |
| **대안 검토** | `<TODO: N/A>` |

---

## 5. Observability

### Sentry

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Sentry (Error Monitoring) |
| **역할** | Edge Function과 Flutter 앱의 에러 트래킹. Edge Function: `logger.ts`의 `initSentry()` + `withHandler()` 래퍼로 통합 (`tracesSampleRate: 0.2`). Flutter: `SENTRY_DSN` 환경변수로 초기화(Optional). |
| **코드 위치** | `supabase/functions/_shared/logger.ts`, Flutter: `shared/packages/minglit_kit/` (sentry 초기화) |
| **환경변수** | `SENTRY_DSN` (Flutter, Optional), `SENTRY_DSN_EDGE_FUNCTIONS` (GitHub Secrets, Edge Functions용, Required) |
| **왜 이 벤더?** | `<TODO: Sentry 선택 이유 — Datadog, Bugsnag 대비 비용/기능 비교>` |
| **계약 / tier / 비용** | `<TODO: 현재 plan, 이벤트 수 제한, 월 비용>` |
| **핵심 한계** | `<TODO: Sentry 샘플링 20% — 트레이스 누락 가능성, 민감정보 마스킹 처리(pii_masker.ts)>` |
| **다운 시 영향** | `<TODO: Sentry 장애 시 에러 모니터링 미작동 — 서비스 운영에는 직접 영향 없음>` |
| **대안 검토** | `<TODO: Datadog, Grafana Faro 등 대안>` |

---

### Axiom

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Axiom (Structured Log Management) |
| **역할** | Edge Function의 구조화 로그 저장 및 쿼리. `axiom_logger.ts`(130 LOC)가 로그를 Axiom으로 전송. `logger.ts`의 `log.info()`, `log.error()` 등이 내부적으로 Axiom과 연동. PII 마스킹 후 전송(`pii_masker.ts`). |
| **코드 위치** | `supabase/functions/_shared/axiom_logger.ts`, `supabase/functions/_shared/logger.ts` |
| **환경변수** | `AXIOM_API_TOKEN` (Edge Functions, Optional), `AXIOM_DATASET` (Edge Functions, Optional), `AXIOM_API_TOKEN` (GitHub Secrets, Optional) |
| **왜 이 벤더?** | `<TODO: Axiom 선택 이유 — Datadog Logs, Papertrail 대비 비용/기능>` |
| **계약 / tier / 비용** | `<TODO: Axiom free tier 사용 중? 데이터 보존 기간>` |
| **핵심 한계** | `<TODO: 로그 보존 기간, 쿼리 속도 제한>` |
| **다운 시 영향** | `<TODO: Axiom 장애 시 로그 유실 — 서비스 운영에는 직접 영향 없음>` |
| **대안 검토** | `<TODO: Datadog Logs, Grafana Loki 등 대안>` |

---

### Statsig

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Statsig (Feature Flags + Analytics) |
| **역할** | 피처 플래그 제어와 이벤트 로깅. Edge Function: `statsig_utils.ts`(115 LOC)의 `initStatsig()`, `logStatsigEvent()`. Flutter: `STATSIG_CLIENT_KEY`. Next.js 랜딩페이지: `NEXT_PUBLIC_STATSIG_CLIENT_KEY`. |
| **코드 위치** | `supabase/functions/_shared/statsig_utils.ts`, Flutter 앱 초기화, `apps/landing_user/`, `apps/landing_partner/` |
| **환경변수** | `STATSIG_CLIENT_KEY` (Flutter, Optional), `STATSIG_SERVER_KEY` (Edge Functions, Optional; GitHub Secrets Optional) |
| **왜 이 벤더?** | `<TODO: Statsig 선택 이유 — LaunchDarkly, GrowthBook 대비>` |
| **계약 / tier / 비용** | `<TODO: 현재 plan, MAU 기준 비용>` |
| **핵심 한계** | `<TODO: 피처 플래그 조회 지연이 초기 렌더링에 영향 여부>` |
| **다운 시 영향** | `<TODO: Statsig 장애 시 기본값(default) 동작 — 핵심 기능에는 영향 없어야 함>` |
| **대안 검토** | `<TODO: LaunchDarkly, GrowthBook, Supabase Edge Config 대안>` |

---

### Codecov

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Codecov (Test Coverage) |
| **역할** | CI 파이프라인에서 Flutter 테스트 커버리지 리포트를 수집·시각화. GitHub Actions에서 `CODECOV_TOKEN`으로 업로드. |
| **코드 위치** | `.github/workflows/` (CI 설정) |
| **환경변수** | `CODECOV_TOKEN` (GitHub Secrets, Optional) |
| **왜 이 벤더?** | `<TODO: Codecov 선택 이유>` |
| **계약 / tier / 비용** | `<TODO: 오픈소스 무료 plan 여부>` |
| **핵심 한계** | `<TODO: N/A — CI 도구>` |
| **다운 시 영향** | `<TODO: 커버리지 리포트 미업로드 — CI 차단 없음>` |
| **대안 검토** | `<TODO: Coveralls, SonarCloud 대안>` |

---

## 6. Deployment

### Vercel

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | Vercel (Next.js Hosting + Deploy) |
| **역할** | `landing_user`와 `landing_partner` 두 Next.js 랜딩페이지 호스팅. PR/push 시 자동 배포는 `ignoreCommand`로 차단. cron(2시간마다) 또는 `workflow_dispatch`(수동)로만 배포. 4개 앱 모두 매 cron마다 deploy. |
| **코드 위치** | `apps/landing_user/`, `apps/landing_partner/`, `.github/workflows/` (deploy workflow) |
| **환경변수** | Vercel project 내 설정 (코드 레벨 env var 없음, Next.js `NEXT_PUBLIC_SUPABASE_URL` 등은 Vercel 프로젝트 설정에서 관리) |
| **왜 이 벤더?** | `<TODO: Vercel 선택 이유 — Next.js 최적화, Edge Network, 비용>` |
| **계약 / tier / 비용** | `<TODO: Vercel plan, 4개 프로젝트 비용>` |
| **핵심 한계** | `<TODO: Vercel 함수 실행 시간 제한, 빌드 분당 제한>` |
| **다운 시 영향** | `<TODO: 랜딩페이지 접속 불가 — 앱 서비스에는 직접 영향 없음>` |
| **대안 검토** | `<TODO: Netlify, Cloudflare Pages 대안>` |

---

## 7. Tooling

### GitHub Actions (CI)

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | GitHub Actions (CI/CD) |
| **역할** | 모노레포 전체 CI 파이프라인. `ci-result` summary job이 게이트. 주요 job: `check-migration-versions`, `test-flutter-apps`(matrix: app_user, app_partner), `lint-landing-user`, `lint-landing-partner`, `test-supabase`(pgTAP), `test-edge-functions`(Deno). Auto Format PR(dart fix + format). Secret Scanning(Gitleaks). |
| **코드 위치** | `.github/workflows/` |
| **환경변수** | `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DEV_DB_PASSWORD`, `SUPABASE_DEV_PROJECT_ID`, `OPENAI_API_KEY`, `GH_PAT_FOR_BUG_REPORT`, `SENTRY_DSN_EDGE_FUNCTIONS`, `STATSIG_SERVER_KEY`, `AXIOM_API_TOKEN`, `CODECOV_TOKEN`, `SIM_USER_PASSWORD` (GitHub Secrets) |
| **왜 이 벤더?** | `<TODO: GitHub Actions 선택 이유 — GitHub 저장소와 통합, 비용>` |
| **계약 / tier / 비용** | `<TODO: GitHub Actions 분 사용량, 비용>` |
| **핵심 한계** | `<TODO: 동시 실행 제한, macOS runner 비용(iOS 빌드)>` |
| **다운 시 영향** | `<TODO: CI 불가 시 머지 차단 — PR 프로세스 중단>` |
| **대안 검토** | `<TODO: N/A — GitHub 저장소 사용 중 자연스러운 선택>` |

---

### CodeRabbit

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | CodeRabbit (AI Code Review) |
| **역할** | PR 생성 시 AI 자동 코드 리뷰. `ci-result` job 내에서 최대 30분 대기. 미해결 CodeRabbit 코멘트는 `required_conversation_resolution` 정책에 의해 머지를 차단. |
| **코드 위치** | `.github/workflows/` (ci-result job), `.coderabbit.yml` (있을 경우) |
| **환경변수** | 별도 GitHub Secrets 불필요 (GitHub App 통합) |
| **왜 이 벤더?** | `<TODO: CodeRabbit 선택 이유 — 리뷰 인원 부족 보완, 비용>` |
| **계약 / tier / 비용** | `<TODO: 현재 plan — OSS 무료 또는 유료 tier>` |
| **핵심 한계** | `<TODO: AI 리뷰 오탐(false positive) 처리 방식, 30분 타임아웃 CI 지연>` |
| **다운 시 영향** | `<TODO: CodeRabbit 미작동 시 ci-result 타임아웃 → 수동 재실행 필요>` |
| **대안 검토** | `<TODO: Reviewpad, Sourcery 대안>` |

---

### GitHub (Bug Report / Stats API)

| 항목 | 내용 |
|------|------|
| **벤더 / 제품** | GitHub REST API |
| **역할** | 두 가지 용도: 1) `bug-report`, `metrics-alert` Edge Functions에서 GitHub Issues 자동 생성. 2) `github-stats-sync` Edge Function에서 이슈/PR 통계 수집 → `analytics.github_daily_stats` 저장(매일 05:30 KST). |
| **코드 위치** | `supabase/functions/bug-report/`, `supabase/functions/metrics-alert/`, `supabase/functions/github-stats-sync/` |
| **환경변수** | `GITHUB_ACCESS_TOKEN` (bug-report, metrics-alert: Required; github-stats-sync: Optional), `GH_PAT_FOR_BUG_REPORT` (GitHub Secrets) |
| **왜 이 벤더?** | `<TODO: GitHub Issues를 버그 트래킹·알람 채널로 사용하는 이유>` |
| **계약 / tier / 비용** | `<TODO: GitHub API rate limit — 인증 시 5000 req/h>` |
| **핵심 한계** | `<TODO: rate limit 초과 시 이슈 생성 실패>` |
| **다운 시 영향** | `<TODO: GitHub API 장애 시 버그 리포트·알람 미생성 — 서비스 운영에는 직접 영향 없음>` |
| **대안 검토** | `<TODO: Jira, Linear 등 이슈 트래커 대안>` |

---

*생성 기준: 2026-04-25 / 소스: docs/guides/env-reference.md, docs/architecture/*.md, supabase/functions/_shared/*
