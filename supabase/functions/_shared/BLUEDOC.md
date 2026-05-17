# _shared

모든 Edge Function 이 import 하는 공용 라이브러리. EF 아님 (`_` prefix). 변경 시 영향 큼.

## 파일 그룹

### Wrapper / Auth (EF 진입점 표준)
- `edge_function.ts` — `minglitEdgeFunction(handler)` wrapper. auth-manifest 기반 envs/role 가드 + logger / sentry 통합. **모든 신규 EF 가 사용해야 함**
- `env_keystore.ts` — env-manifest 기반 환경변수 typed 접근

### Logging / Observability
- `logger.ts` — 콘솔 logger (local 전용)
- `axiom_logger.ts` — Axiom 구조화 로깅 (dev/prod). withHandler 가 자동 호출
- `statsig_utils.ts` — Statsig 이벤트 logging (no-op when key missing)
- `pii_masker.ts` — 로그 출력 시 PII 마스킹

### HTTP
- `request_utils.ts` — request body 파싱 helper
- `response_utils.ts` — corsResponse / errorResponse / successResponse

### DB
- `supabase_client.ts` — `createServiceClient()` / `createUserClient(token)`

### 외부 client
- `iamport_client.ts` — Iamport (구) PortOne v1 client
- `portone_client.ts` — PortOne v2 client

### 도메인 helper
- `partner_permissions.ts` — partner_members role 검증
- `refund_utils.ts` — 환불 정책 (#2131 cutoff 등)
- `temporal_utils.ts` — 시간/timezone 유틸
- `validation_utils.ts` — 입력 검증
- `worker_utils.ts` — PGMQ worker 패턴

### AI
- `ai/` — AI 어댑터 추상화 (OpenAI embedding / LLM)

### Tests
각 `*.ts` 의 `*_test.ts` 동반.

## 변경 정책

breaking change → 모든 EF 영향, 전수 회귀 필요. 신규 utility → 자유. deprecation → 단계적 (legacy 유지 → 마이그 PR → 삭제).

## 관련

- [edge-function-auth.md](../../../docs/architecture/edge-function-auth.md) — minglitEdgeFunction wrapper 상세
- [edge-functions.md](../../../docs/operations/edge-functions.md) — axiom / sentry 디버깅
- [functions/BLUEDOC.md](../BLUEDOC.md) — EF 디렉토리 진입점

---
_Reviewed: 2026-05-17 22:32_
