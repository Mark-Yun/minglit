# @minglit/web-kit

웹 MVP 공유 클라이언트 패키지. 아키텍처 기준: [docs/architecture/web-client.md](../../../docs/architecture/web-client.md) §2.1. 이정표는 [BLUEDOC.md](./BLUEDOC.md).

## 사용

빌드 스텝 없음 — TS 소스를 그대로 export 한다. 소비 앱(`landing_user`/`landing_partner`)의 `next.config` 에 다음을 추가해야 한다:

```ts
transpilePackages: ["@minglit/web-kit"]
```

```ts
import { createBrowserClient } from "@minglit/web-kit/supabase";
import { applyEvent, MinglitError } from "@minglit/web-kit/ef";
import { PURCHASE_STATUS_CHIPS, formatEventDateTime } from "@minglit/web-kit/domain";
import { StatusChip, Button, cn } from "@minglit/web-kit/ui";
import type { Database } from "@minglit/web-kit/types";
```

## DB 타입 생성 (`gen:types`)

`src/types/db.ts` 는 `supabase gen types typescript` 생성물이다 — **수기 수정 금지**. 현재는 placeholder 상태 (아직 미실행).

```sh
# local Supabase (supabase start 가 떠 있는 상태) — 기본 스크립트
npm run gen:types

# dev(원격) 프로젝트 기준으로 생성하려면 --project-id 사용.
# 프로젝트 ref 는 저장소에 하드코딩하지 않는다 — `minglit_env` (환경 설정 저장소) 의
# Supabase 설정 또는 `supabase projects list` 로 확인할 것.
supabase gen types typescript --project-id <dev-project-ref> > src/types/db.ts
```

## EF 클라이언트 규칙

- 쓰기는 EF 만 — 클라이언트는 DB 에 직접 INSERT/UPDATE/DELETE 하지 않는다.
- 함수명·인증 요구의 SSoT 는 `supabase/functions/auth-manifest.json`. wrapper 추가 시 manifest 와 EF `index.ts` 파싱 로직을 역산해 작성하고, 불확실한 필드는 `z.unknown()` + `TODO(web-kit)` 주석으로 남긴다.
- 에러는 `MinglitError` 로 정규화 — EF 에러 envelope `{ error, details? }` 기준.
