# 도입 계획

전체 `docs/` 에 한번에 도입하지 않는다. stale 빈도와 영향도가 높은 곳부터 점진 도입한다.

## 단계

1. **`docs/architecture/FRESH_DOC`** — 가장 빠르게 stale 된다. 시스템 구조 변경마다 갱신이 필요하다. `watched_paths` 기반 (`supabase/migrations/**`, `apps/app_user/lib/features/**`) 이 적합하다.
2. **`docs/infra/FRESH_DOC`** — 자체 dogfooding. cycle 기반 (`60d`) 으로 시작한다.
3. **`docs/standards/FRESH_DOC`** — 엔지니어링 원칙 류. cycle 기반 (`90d`) 으로 충분하다.
4. **그 외** — 필요 시 추가.

`docs/reports/` 등 report / archive 류 디렉토리는 도입 불필요하다. 한번 작성하면 archive 대상이다.

## 후속 작업 (별도 PR)

- `.github/workflows/doc-freshness.yml` — 일일 스케줄 워크플로우
- `scripts/fresh-doc-lint.ts` — validator 스크립트 ([schema-validator.md](./schema-validator.md))
- CI 통합 — 변경된 `FRESH_DOC` 에 validator 실행
- 파일럿 도입 — `docs/architecture/FRESH_DOC` 첫 작성
