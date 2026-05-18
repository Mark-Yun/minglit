# FRESH_DOC YAML 정의

`FRESH_DOC` 은 디렉토리마다 두는 메타파일이다. 본 문서는 그 파일의 위치·형식·필드를 정의한다.

## 위치 및 형식

파일명은 `FRESH_DOC` (확장자 없음, `OWNERS` / `CODEOWNERS` 스타일). 형식은 YAML. 관리할 문서가 있는 디렉토리 루트에 둔다. 관리 단위는 디렉토리이며, **`target_files` 로 추적 대상을 명시**한다.

## 스키마 버전

| 버전 | 상태 | 식별자 필드 |
|------|------|------------|
| **v2** (권장) | 신규 표준 | `target_files` |
| v1 (deprecated) | backward compat | `last_verified` |

v1 → v2 마이그레이션은 점진적. validator 가 둘 다 통과시키되, 동시 사용 시 error.

## 트리거 방식

검토 트리거는 시간 기반과 이벤트 기반 두 가지. **`cycle` 과 `watched_paths` 중 정확히 하나**만 지정 (validator 검증).

### 시간 기반 — `cycle`

derived `last_verified` 로부터 `cycle` 기간이 경과하면 stale.

**v2 (권장)**:
```yaml
cycle: 14d
priority: P2-medium
target_files:
  - feature_audit_report.md
refresh_method: |
  본 카테고리 audit 수행 + 보고서 갱신.
```

**v1 (deprecated)**:
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

`watched_paths` 매칭 경로 중 derived `last_verified` 이후 commit 있으면 stale.

**v2 (권장)**:
```yaml
watched_paths:
  - supabase/migrations/**
  - supabase/functions/**
priority: P2-medium
target_files:
  - backend.md
refresh_method: |
  신규 마이그레이션과 Edge Function 을 backend.md 에 반영.
```

## 필드 (v2)

| 필드 | 필수 | 타입 | 설명 |
|------|------|------|------|
| `cycle` | 조건부 | duration | 검토 주기. `7d` / `14d` / `30d` / `60d` / `90d`. `watched_paths` 와 상호 배타 |
| `watched_paths` | 조건부 | string[] | 레포 루트 기준 glob. 매칭 경로 commit 발생 시 stale. `cycle` 과 상호 배타 |
| `target_files` | ✓ | string[] | 본 FRESH_DOC 이 추적하는 파일 (FRESH_DOC 위치 기준 상대 glob). 이 파일들의 `max(git log -1)` 가 derived `last_verified` |
| `priority` | ✓ | enum | `P0-critical` / `P1-high` / `P2-medium` / `P3-low` |
| `refresh_method` | | string | 이슈 본문에 포함될 갱신 가이드 (3~5줄 권장) |

## 필드 (v1 — deprecated)

| 필드 | 필수 | 타입 | 비고 |
|------|------|------|------|
| `last_verified` | ✓ | date | 수동 갱신 (`YYYY-MM-DD`). v2 에서 derived 로 대체 |
| `recursive` | | bool | v2 에서 `target_files: ["**/*.md"]` 글로브로 대체 |
| `exclude` | | string[] | v2 에서 `target_files` 글로브에 직접 표현 |

`cycle` / `watched_paths` / `priority` / `refresh_method` 는 두 버전 공통.

## `target_files` 작성 지침

- FRESH_DOC 위치 기준 상대 경로 (절대 / `../` 금지 — validator 차단)
- glob 지원 (`*`, `**`, `?`)
- 비어있으면 안 됨

**좋은 예**:
- `feature_audit_report.md` — 단일 보고서만 추적 (features 카테고리)
- `["*.md"]` — top-level .md 모두 (recursive 없는 단순 dir)
- `["**/*.md"]` — 하위 디렉토리 포함 모든 .md (옛 `recursive: true` 와 동일)
- `["backend.md", "client.md"]` — 핵심 문서만 선별

**피할 예**:
- `["**"]` — 너무 광범위 (코드 파일까지 매치)
- `["BLUEDOC.md"]` — BLUEDOC 은 별도 freshness 시스템 (`pr-gate.check-bluedoc-freshness`) 으로 관리 — FRESH_DOC 와 중복

## cycle 값 가이드

| 값 | 적합한 문서 |
|----|-------------|
| `7d` | 빠르게 변하는 운영 문서 (incident 대응 가이드 등) |
| `14d` ~ `30d` | 활성 개발 영역 아키텍처 |
| `60d` ~ `90d` | 안정된 컨셉 / 원칙 문서 |

## watched_paths 작성 지침

너무 넓으면 (`**/*.md`) 매번 stale 노이즈. 너무 좁으면 (`supabase/migrations/000123_*.sql`) 실제 변경 누락. 디렉토리 단위 (`supabase/migrations/**`) 가 무난.

좋은 예: `supabase/migrations/**`, `apps/app_user/lib/features/auth/**`
피할 예: `**`, `*.md`, `supabase/`

## 하위 디렉토리 경계 (v2)

`target_files: ["**/*.md"]` 같은 recursive 글로브를 쓸 때, 하위 디렉토리에 별도 FRESH_DOC 이 있으면 거기서 경계가 끊긴다. validator 와 워크플로우 둘 다 이 boundary 를 존중한다.

```
docs/architecture/
├── FRESH_DOC               # target_files: ["**/*.md"]
├── overview.md             # ← 상위 FRESH_DOC 관리
└── subsystem/
    ├── FRESH_DOC           # 별도 존재
    ├── auth.md             # ← subsystem/FRESH_DOC 관리
    └── payment.md          # ← subsystem/FRESH_DOC 관리
```

## 예시

`docs/features/account/FRESH_DOC` — v2 시간 기반:

```yaml
cycle: 14d
priority: P2-medium
target_files:
  - feature_audit_report.md
refresh_method: |
  본 카테고리 (account) 인스펙션 → feature_audit_report.md 갱신 + Action Items 마다 Issue 1건.
  절차: docs/features/feature_audit_report_template.md 의 "AI 실행 절차" 섹션 참조.
```

`docs/architecture/FRESH_DOC` — v2 이벤트 기반 (가상 예시):

```yaml
watched_paths:
  - supabase/migrations/**
  - supabase/functions/**
  - apps/app_user/lib/features/**
priority: P2-medium
target_files:
  - backend.md
  - client.md
refresh_method: |
  - 신규 테이블·Edge Function 을 backend.md 에 반영
  - 신규 feature 디렉토리를 client.md 에 반영
```
