# Supabase

Minglit 의 **백엔드 구현 루트**. DB migration, Edge Functions, seed, backend test 가 모여 있으며 상세 설계는 `docs/architecture/` 로 분리한다.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`migrations/`](./migrations/) | Postgres schema, RLS, trigger, cron, extension 변경 이력 |
| [`functions/`](./functions/BLUEDOC.md) | Supabase Edge Functions 60+ 개와 공용 `_shared/`, 테스트 유틸 |
| [`tests/`](./tests/) | pgTAP / backend integration 성격의 Supabase 테스트 |
| [`config.toml`](./config.toml) | 로컬 Supabase project 설정과 function 등록 |
| [`seed.sql`](./seed.sql) | 공통 seed 데이터 |
| [`seed.dev.sql`](./seed.dev.sql) · [`seed.local.sql`](./seed.local.sql) | dev/local actor/base seed 데이터 |
| [`setup_local.sh`](./setup_local.sh) | 로컬 Supabase 초기화 보조 스크립트 |

## 핵심 컨벤션

- **상세 백엔드 설계는 문서로 이동** — DB inventory 와 도메인 관계는 `docs/architecture/backend.md` 가 기준.
- **쓰기 경로는 Edge Function 중심** — 클라이언트 직접 write 정책을 늘리지 않고 service_role EF 에서 검증한다.
- **dev seed 는 actor/base 만** — user/partner/permission/verification 까지. party/event/ticket state 는 EF 경유로 만든다.
- **migration 은 append-only** — 기존 migration 수정 대신 새 번호를 추가하고, 생성 전 `migrations/` 최신 번호를 확인한다.
- **function 은 manifest/wrapper 경유** — `functions/auth-manifest.json` 과 `minglitEdgeFunction` 규칙을 따른다.

## 관련

- [docs/architecture/backend.md](../docs/architecture/backend.md) — Supabase schema/RLS/trigger 상세
- [docs/architecture/edge-function-auth.md](../docs/architecture/edge-function-auth.md) — EF 인증/인가 모델
- [docs/architecture/global-event-pipeline.md](../docs/architecture/global-event-pipeline.md) — PGMQ 이벤트 파이프라인
- [docs/architecture/payment-pipeline.md](../docs/architecture/payment-pipeline.md) — 결제/정산 파이프라인
- [docs/operations/edge-functions.md](../docs/operations/edge-functions.md) — EF 디버깅/운영
- [docs/infra/bluedoc/BLUEDOC.md](../docs/infra/bluedoc/BLUEDOC.md) — BLUEDOC 컨벤션

---
_Reviewed: 2026-05-25 22:30_
