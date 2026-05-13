# Validator 스펙

`FRESH_DOC` 파일의 형식·필드·참조를 검증하는 CLI. CI 에서 변경된 `FRESH_DOC` 마다 실행하여 잘못된 설정을 PR 단계에서 차단한다.

## 위치 및 실행

- 경로: `scripts/fresh-doc-lint.ts`
- 런타임: Deno (레포 Edge Functions 와 동일 환경)
- 호출:
  ```
  deno run --allow-read --allow-run scripts/fresh-doc-lint.ts [FILE...]
  ```

인자 없이 호출하면 레포 전체의 `FRESH_DOC` 파일을 스캔한다.

## 검증 단계

### 1. Schema 검증

| 항목 | 조건 |
|------|------|
| 필수 필드 | `priority`, `last_verified` 존재 |
| 트리거 | `cycle` 과 `watched_paths` 중 정확히 하나 (둘 다 또는 아무것도 없으면 에러) |
| `priority` | `P0-critical` / `P1-high` / `P2-medium` / `P3-low` 중 하나 |
| `last_verified` | `YYYY-MM-DD` 형식의 유효 날짜 |
| `cycle` | `\d+d` 형식 (예: `30d`) |
| `recursive` | bool |
| `exclude` | string 배열 |
| `watched_paths` | string 배열, 각 요소가 비어있지 않음 |

### 2. 참조 검증

| 항목 | 조건 |
|------|------|
| 디렉토리 내 `.md` 존재 | `exclude` 적용 후에도 1개 이상 |
| `watched_paths` 경로 존재 | glob 이 매칭하는 파일이 1개 이상 |
| `exclude` 매칭 | 매칭이 0건이면 경고 (사용되지 않는 패턴) |

### 3. Dry-run (선택)

`--dry-run` 플래그 시 오늘 기준 stale 판정 결과를 출력한다. PR 미리보기 용도.

```
$ deno run scripts/fresh-doc-lint.ts --dry-run
docs/architecture/FRESH_DOC: STALE (watched_paths, 3 commits since 2026-05-13)
docs/infra/FRESH_DOC: FRESH (cycle 60d, 12d elapsed)
docs/standards/FRESH_DOC: FRESH (cycle 90d, 45d elapsed)
```

## CI 통합

`.github/workflows/ci.yml` 에 job 추가:

- 트리거: `docs/**/FRESH_DOC` 또는 `scripts/fresh-doc-lint.ts` 변경
- 단계: validator 실행. 1·2 단계 실패 시 CI fail.
- `ci-result` 의 dependency 로 추가 → 머지 차단 효과.

## 종료 코드

| 코드 | 의미 |
|------|------|
| `0` | 모든 파일 통과 |
| `1` | Schema 검증 실패 |
| `2` | 참조 검증 실패 |

경고 (사용되지 않는 `exclude` 패턴 등) 는 종료 코드에 영향을 주지 않는다.

## 출력 형식

각 파일당 1줄. 에러는 파일 경로·라인·필드명·이유를 포함한다.

```
docs/architecture/FRESH_DOC:5 priority: invalid value 'P5-low' (expected: P0-critical | P1-high | P2-medium | P3-low)
docs/infra/FRESH_DOC:1 trigger: both 'cycle' and 'watched_paths' specified (must be exactly one)
docs/standards/FRESH_DOC: OK
```
