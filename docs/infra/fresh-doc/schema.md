# FRESH_DOC YAML 정의

`FRESH_DOC` 은 디렉토리마다 두는 메타파일이다. 본 문서는 그 파일의 위치·형식·필드를 정의한다.

## 위치 및 형식

파일명은 `FRESH_DOC` (확장자 없음, `OWNERS` / `CODEOWNERS` 스타일). 형식은 YAML. 관리할 문서가 있는 디렉토리 루트에 둔다. 관리 단위는 디렉토리이며, 파일별 명세는 두지 않는다.

하위 디렉토리는 `recursive: true` 일 때만 포함한다. 단, 하위 디렉토리에 별도 `FRESH_DOC` 이 있으면 상위의 관리에서 분리된다.

## 트리거 방식

검토 트리거는 시간 기반과 이벤트 기반 두 가지가 있다. **`cycle` 과 `watched_paths` 중 정확히 하나** 만 지정한다 (validator 가 검증).

### 시간 기반 — `cycle`

`last_verified` 로부터 `cycle` 기간이 경과하면 stale.

```yaml
cycle: 30d
priority: P3-low
last_verified: 2026-05-13
recursive: false
exclude:
  - "*-plan.md"
refresh_method: |
  관련 코드/스키마 변경을 확인하고 문서를 갱신한다.
```

### 이벤트 기반 — `watched_paths`

`watched_paths` 에 매칭되는 경로 중 `last_verified` 이후 커밋이 있으면 stale.

```yaml
watched_paths:
  - supabase/migrations/**
  - supabase/functions/**
priority: P2-medium
last_verified: 2026-05-13
recursive: false
refresh_method: |
  신규 마이그레이션과 Edge Function 을 backend.md 에 반영한다.
```

## 필드

| 필드 | 필수 | 타입 | 설명 |
|------|------|------|------|
| `cycle` | 조건부 | duration | 검토 주기. `7d` / `14d` / `30d` / `60d` / `90d`. `watched_paths` 와 상호 배타 |
| `watched_paths` | 조건부 | string[] | 레포 루트 기준 glob. 이 경로에 `last_verified` 이후 커밋이 있으면 stale. `cycle` 과 상호 배타 |
| `priority` | ✓ | enum | `P0-critical` / `P1-high` / `P2-medium` / `P3-low` |
| `last_verified` | ✓ | date | 마지막 검토 일자 (`YYYY-MM-DD`) |
| `recursive` | | bool | 기본 `false`. `true` 면 하위 디렉토리의 모든 `.md` 도 본 FRESH_DOC 관리 대상 |
| `exclude` | | string[] | FRESH_DOC 기준 상대 경로의 glob 배열 |
| `refresh_method` | | string | 이슈 본문에 포함될 갱신 가이드 (3~5줄 권장) |

## cycle 값 가이드

| 값 | 적합한 문서 |
|----|-------------|
| `7d` | 빠르게 변하는 운영 문서 (incident 대응 가이드 등) |
| `14d` ~ `30d` | 활성 개발 영역 아키텍처 |
| `60d` ~ `90d` | 안정된 컨셉 / 원칙 문서 |

## watched_paths 작성 지침

너무 넓으면 (`**/*.md`) 매번 stale 이 되어 노이즈가 쌓인다. 너무 좁으면 (`supabase/migrations/000123_*.sql`) 실제 변경을 놓친다. 디렉토리 단위 (`supabase/migrations/**`) 가 무난하다.

좋은 예: `supabase/migrations/**`, `apps/app_user/lib/features/auth/**`
피할 예: `**`, `*.md`, `supabase/`

## recursive 동작

```
docs/architecture/
├── FRESH_DOC            # recursive: true
├── overview.md
├── backend.md
└── subsystem/
    ├── auth.md          # 상위 FRESH_DOC 관리
    └── payment.md       # 상위 FRESH_DOC 관리
```

하위에 별도 `FRESH_DOC` 이 있으면 그 시점에 분리된다.

```
docs/architecture/
├── FRESH_DOC            # recursive: true
├── overview.md
└── subsystem/
    ├── FRESH_DOC        # 별도 존재
    ├── auth.md          # subsystem/FRESH_DOC 관리
    └── payment.md       # subsystem/FRESH_DOC 관리
```

## exclude 매칭

glob 패턴 (`*`, `**`, `?`) 을 지원한다. `recursive: true` 인 경우 `**/draft-*.md` 처럼 하위 경로도 매칭 가능하다. 경로는 FRESH_DOC 위치 기준 상대 경로다.

## 예시

`docs/architecture/FRESH_DOC` — 이벤트 기반:

```yaml
watched_paths:
  - supabase/migrations/**
  - supabase/functions/**
  - apps/app_user/lib/features/**
priority: P2-medium
last_verified: 2026-05-13
recursive: false
exclude:
  - "draft-*.md"
refresh_method: |
  - 신규 테이블·Edge Function 을 backend.md 에 반영
  - 신규 feature 디렉토리를 client.md 에 반영
```

`docs/standards/FRESH_DOC` — 시간 기반:

```yaml
cycle: 90d
priority: P3-low
last_verified: 2026-05-13
refresh_method: |
  외부 SDK·플랫폼 버전 변경 사항이 standards 에 반영되어 있는지 확인한다.
```
