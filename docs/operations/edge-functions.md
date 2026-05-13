# Edge Function 디버깅 가이드

## 로깅 아키텍처

모든 Edge Function은 `_shared/logger.ts`의 통합 래퍼를 사용한다.

```
요청 → withHandler() → Axiom log "invoked"
                      → handler 실행
                      → 성공: Axiom log "completed"
                      → 실패: Axiom log error + Sentry captureException
                      → finally: Axiom flush
```

### 역할 분리

| 도구 | 역할 | 대상 |
|------|------|------|
| **Axiom** | 구조화 로깅 (관찰) | 모든 레벨 (debug/info/warn/error) |
| **Sentry** | 에러 트래킹 + 성능 | error + `withSpan()` |
| **Console** | 로컬 전용 | 항상 출력 (Axiom 미전송) |

### 함수 내부 로깅 패턴

```typescript
import { initSentry, withHandler, log, withSpan } from "../_shared/logger.ts";

const FN = "my-function";

await initSentry();
Deno.serve(withHandler(async (req) => {
  // 일반 흐름
  log({ function: FN, level: "info", message: "Processing started" });

  // DB 성능 측정 (Sentry span)
  const data = await withSpan("db.query.users", "db.query", () =>
    supabase.from("users").select("*")
  );

  // 에러 → 래퍼가 Sentry에도 자동 전송
  log({ function: FN, level: "error", message: "Failed", metadata: { detail: error } });

  return successResponse(data);
}));
```

## 로컬 디버깅

### 1. Edge Function 로컬 실행

```bash
# Supabase 로컬 시작 (DB + Auth + Storage + Edge Runtime)
supabase start

# 특정 함수만 serve (hot reload 포함)
supabase functions serve <function-name> --env-file minglit_env/local/supabase.env

# 전체 함수 serve
supabase functions serve --env-file minglit_env/local/supabase.env
```

### 2. Chrome DevTools 디버깅

`config.toml`에 `inspector_port = 8083`이 설정되어 있다.

```bash
# 1. 함수 serve
supabase functions serve --inspect

# 2. Chrome에서 접속
# chrome://inspect → Configure → localhost:8083 추가
# Remote Target에 함수가 나타나면 "inspect" 클릭
```

브레이크포인트, 변수 검사, 스텝 실행 모두 가능.

### 3. 로컬에서 함수 호출

```bash
# Service role key로 호출 (인증 우회)
curl -s -X POST "http://localhost:54321/functions/v1/<function-name>" \
  -H "Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'

# 응답 포맷팅
curl -s ... | python3 -m json.tool
```

로컬 환경에서는 Axiom 전송이 비활성화(`ENVIRONMENT=local`)되고 console만 출력된다.

## Dev 서버 디버깅

### 1. 함수 호출

```bash
# Dev 서버 직접 호출
curl -s -X POST "https://<project-ref>.supabase.co/functions/v1/<function-name>" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"phase": "verify"}'
```

환경 변수는 `minglit_env/dev/supabase.env`에서 확인.

### 2. 배포된 함수 목록 확인

```bash
supabase functions list --project-ref <project-ref>
```

### 3. 배포

Edge Function 배포는 CI를 통해서만 한다 (직접 `supabase functions deploy` 금지).

```
feature branch → PR → dev 머지 → supabase-deploy.yml 자동 실행
```

`supabase/functions/**` 경로 변경 시 자동 트리거.

## Axiom 로그 조회

### CLI

```bash
# 특정 run ID로 조회
axiom query "['edge-functions'] | where metadata.runId == '<run-id>'"

# 특정 함수의 에러만 조회
axiom query "['edge-functions'] | where function == 'payment-verify' and level == 'error'"

# 최근 1시간 특정 함수 로그
axiom query "['edge-functions'] | where function == 'notification-worker'" --start "-1h"
```

### 대시보드

1. [Axiom 대시보드](https://app.axiom.co) 접속
2. Dataset: `edge-functions` 선택
3. 필터: `function == '<name>'`, `level == 'error'`, `metadata.runId == '<id>'`

### 로그 구조

```json
{
  "_time": "2026-03-20T07:30:00Z",
  "function": "payment-verify",
  "level": "error",
  "environment": "development",
  "message": "Payment amount mismatch",
  "metadata": {
    "expected": 20000,
    "actual": 15000
  }
}
```

## Sentry 에러 트래킹

Sentry는 `withHandler` 래퍼에서 자동으로 에러를 캡처한다. 별도 호출 불필요.

성능 측정이 필요한 곳에서만 `withSpan()` 사용:

```typescript
const result = await withSpan("portone.verify", "http.client", () =>
  portoneClient.getPayment(impUid)
);
```

## 테스트

### 단위 테스트 실행

```bash
# 전체
deno test --allow-all --config supabase/deno.json supabase/functions/

# 특정 함수
deno test --allow-all --config supabase/deno.json supabase/functions/payment-verify/

# 특정 테스트 파일
deno test --allow-all --config supabase/deno.json supabase/functions/payment-verify/payment_verify_test.ts
```

### 테스트 유틸리티

| 유틸 | 위치 | 용도 |
|------|------|------|
| `createFetchMock()` | `_test_utils/mock_http.ts` | fetch 인터셉트 |
| `withMockedFetch()` | 동일 | fetch mock 적용 |
| `withEnv()` | 동일 | 환경변수 임시 설정 |
| `captureServeHandler()` | 동일 | Deno.serve 핸들러 캡처 |
| `createMockSupabaseClient()` | `_test_utils/mock_supabase_client.ts` | Supabase 클라이언트 mock |

### 시나리오 테스트 (backend-simulator)

```bash
# Dev 서버에서 전체 6-phase 시뮬레이션
curl -X POST ".../functions/v1/backend-simulator" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json"

# 특정 phase만 실행
curl -X POST "..." -d '{"phase": "verify"}'
curl -X POST "..." -d '{"phase": "create"}'
curl -X POST "..." -d '{"phase": "settle"}'
```

Assertion 실패 시 GitHub 이슈가 자동 생성되며, 이슈에 Axiom 쿼리가 포함된다.

## 환경변수 참조

| 변수 | 용도 | local | dev | prod |
|------|------|-------|-----|------|
| `ENVIRONMENT` | 환경 구분 | `local` | `development` | `production` |
| `AXIOM_API_TOKEN` | Axiom 로깅 | 미설정 (비활성) | 설정됨 | 설정됨 |
| `AXIOM_DATASET` | Axiom 데이터셋 | - | `edge-functions` | `edge-functions` |
| `SENTRY_DSN` | Sentry 에러 트래킹 | 미설정 (비활성) | 설정됨 | 설정됨 |
| `SUPABASE_URL` | Supabase API URL | `http://localhost:54321` | `https://<ref>.supabase.co` | `https://<ref>.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | 관리자 키 | 로컬 키 | 시크릿 | 시크릿 |

## 트러블슈팅

### Axiom 로그가 안 보일 때

1. `ENVIRONMENT`가 `local`이면 Axiom 비활성 → dev/prod에서 확인
2. `AXIOM_API_TOKEN` 미설정 확인: `supabase secrets list --project-ref <ref>`
3. `debugStatus()` 호출하여 상태 확인 (backend-simulator verify phase에서 `_axiom_debug` 필드)

### Edge Function 배포가 안 될 때

1. CI 워크플로우 확인: `gh run list --workflow=supabase-deploy.yml`
2. `supabase/functions/**` 경로 변경이 포함되었는지 확인
3. `workflow_dispatch`로 수동 트리거 가능

### 함수 호출 시 에러

| 에러 | 원인 | 해결 |
|------|------|------|
| `401 Unauthorized` | JWT 만료 또는 잘못된 키 | Service role key 사용 |
| `403 Forbidden` | `isProduction()` 가드 (dev-only 함수) | `ENVIRONMENT` 확인 |
| `500 Internal Server Error` | 함수 내부 에러 | Axiom/Sentry 로그 확인 |
| `Function not found` | 미배포 | `supabase functions list`로 확인 |
