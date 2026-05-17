# minglit_kit/data — 데이터 계층

Supabase 테이블·RPC 접근의 단일 출처. Repository 클래스가 UI 와 DB SDK 사이의 추상화 레이어.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`models/`](./models/) | Freezed Data Models (테이블 row 매핑) |
| [`repositories/`](./repositories/) | Supabase 접근 클래스 — UI 가 직접 호출 금지, 여기 경유 |
| [`services/`](./services/) | 데이터 계층 보조 서비스 |
| [`architecture.md`](./architecture.md) | Repository Pattern + Split Pattern 상세 |

## 핵심 컨벤션

- **모든 Supabase 호출은 Repository 경유** — UI/Provider 에서 `Supabase.instance.client` 직접 호출 금지.
- **Repository 가 300 줄 초과 시 `part`/`mixin` split** — query 와 command 를 분리 (상세는 [architecture.md](./architecture.md)).
- **`@riverpod` 으로 provider 자동 생성** — manual provider 작성 금지.
- **새 Repository 는 [`repositories/`](./repositories/) 에만.** 앱 feature 폴더에 Repository 두지 않음.

## 관련

- [architecture.md](./architecture.md) — Repository Pattern · Split Pattern 상세
- [minglit_kit/architecture.md](../../architecture.md) — kit 전체 아키텍처 개요
- [minglit_kit/BLUEDOC.md](../../BLUEDOC.md)
- [apps/architecture.md](../../../../../apps/architecture.md) — kit 사용 측 (Flutter 앱)
