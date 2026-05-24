# Secret Migration Plan

GitHub repo secrets (`DEV_*`, `MAIN_*`, `PRD_*` prefix) → `minglit_env/{stage}/.env` 단일 파일 통합. private repo 신뢰 + 중복 제거 + workflow 단순화 목적.

## 배경

**현재 pain**:
- GH repo secrets ~수십 개 (prefix `DEV_`, `MAIN_`, `PRD_`)
- 같은 변수 의미가 여러 도메인 파일에 중복 (`SUPABASE_URL` 이 `flutter.env`, `supabase.env`, `nextjs.env` 에 모두)
- 값 변경 시 여러 곳 동기화 — 실수 위험
- workflow 에 `secrets.DEV_X` vs `secrets.PRD_X` 분기

**목표**:
- `minglit_env/{stage}/.env` 한 파일에 stage 의 모든 환경 변수
- 변수명 prefix = 도메인 (`SUPABASE_*`, `FIREBASE_*` 등), stage 구분은 파일 위치
- workflow 가 `inputs.stage` 따라 한 파일 로드, prefix-free 변수 사용

## Target 구조

```
minglit_env/
├── local/.env          # 로컬 개발자 환경
├── dev/.env            # CI 테스트 + dev workflow config
├── dev-staging → dev   # symlink (같은 env)
├── rc/.env             # RC Supabase branching workflow config (ephemeral rc-YYYY-Wxx branches)
├── main/.env           # production (main 머지가 deploy)
└── README.md           # 컨벤션 + 변수 카탈로그
```

> **RC env 의 역할**: `rc-deploy` 가 Supabase branching 으로 `rc-YYYY-Wxx` 임시 branch 를 만들고 main 배포 전 backend 검증에 사용한다. `rc-gate-pass` 는 deploy trigger 가 아니라 RC cut source marker 다.

기존 도메인별 파일 (`flutter.env`, `supabase.env`, `nextjs.env`, `metabase.env`) 은 통합 후 폐기.

## 변수명 컨벤션

| Prefix | 도메인 | 예시 |
|--------|--------|------|
| `SUPABASE_*` | DB / Edge Function / Auth | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_PROJECT_REF` |
| `FIREBASE_*` | RC / Crashlytics / FCM / App Check | `FIREBASE_PROJECT_ID`, `FIREBASE_ADMIN_SDK_JSON`, `FIREBASE_API_KEY_IOS`, `FIREBASE_API_KEY_ANDROID` |
| `STATSIG_*` | flag | `STATSIG_SDK_KEY_SERVER`, `STATSIG_SDK_KEY_CLIENT` |
| `SENTRY_*` | error tracking | `SENTRY_DSN_FLUTTER`, `SENTRY_DSN_EF`, `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT` |
| `STORE_IOS_*` | App Store Connect | `STORE_IOS_API_KEY_ID`, `STORE_IOS_API_KEY_BASE64`, `STORE_IOS_ISSUER_ID`, `STORE_IOS_TEAM_ID` |
| `STORE_AOS_*` | Google Play Console | `STORE_AOS_KEYSTORE_BASE64`, `STORE_AOS_KEY_ALIAS`, `STORE_AOS_KEY_PASSWORD`, `STORE_AOS_SERVICE_ACCOUNT_JSON` |
| `IAMPORT_*`, `KAKAO_*`, `NAVER_*` | 외부 SDK | (해당 시) |
| `NEXTJS_*` | landing 전용 (도메인 충분히 명확하면 생략) | TBD |

**stage prefix 안 씀** — 파일 위치가 stage 정보.

### Binary 값 처리

- `.p12`, `.jks`, `.json` 같은 파일 → **base64 encoded single-line string**
- 변수명에 `_BASE64` 또는 `_JSON` suffix (예: `STORE_IOS_API_KEY_BASE64`)
- workflow 가 base64 decode 후 임시 파일로 복원

```yaml
- run: |
    echo "$STORE_IOS_API_KEY_BASE64" | base64 -d > /tmp/app_store_key.p8
```

## Migration Step (순차)

### S1: 현 GH secret 인벤토리

```bash
gh secret list --json name | jq -r '.[].name' > /tmp/current-secrets.txt
```

각 secret 을 매핑 표로 정리 (이 PR 의 후속 issue 또는 별도 PR body 에):

| 기존 GH secret | 새 변수명 | 어느 stage file |
|----------------|-----------|----------------|
| `DEV_SUPABASE_URL` | `SUPABASE_URL` | `dev/.env` |
| `PRD_SUPABASE_URL` | `SUPABASE_URL` | `main/.env` |
| `DEV_APPLE_CERT_BASE64` | `STORE_IOS_CERT_BASE64` | `dev/.env` |
| ... | ... | ... |

### S2: minglit_env 신규 file 골격 생성

```bash
# minglit_env/main/.env 신규 (변수명만, 값은 비어있음)
cat > minglit_env/main/.env <<'EOF'
# === Supabase ===
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_PROJECT_REF=
# === Firebase ===
FIREBASE_PROJECT_ID=
FIREBASE_ADMIN_SDK_JSON=
# ... (전체 변수 골격)
EOF
```

`dev/.env`, `local/.env`, `main/.env` **동일한 변수 set** (값만 stage 별로 다름). main 의 값은 user 가 직접 채움.

### S3: 기존 dev 도메인 파일 통합

```
minglit_env/dev/flutter.env + supabase.env + nextjs.env + metabase.env
    → minglit_env/dev/.env (중복 제거)
```

backup 으로 도메인별 파일 잠시 유지 (별도 commit), 통합 검증 후 삭제.

### S4: README + 변수 카탈로그 갱신

`minglit_env/README.md`:
- 새 구조 설명
- 변수 카탈로그 (전체 변수 list + 의미)
- workflow 로딩 패턴
- 추가/수정 절차

### S5: Workflow 들 file 로딩으로 전환 (점진)

| Before | After |
|--------|-------|
| `${{ secrets.DEV_SUPABASE_URL }}` | `$SUPABASE_URL` (env file 로딩 후) |
| `${{ secrets.PRD_APPLE_CERT_BASE64 }}` | `$STORE_IOS_CERT_BASE64` |

각 workflow 1 PR. 검증 후 다음 workflow.

순서 권장 (위험도 낮은 것부터):
1. `monitor-*`, `sync-*` (orthogonal, 영향 적음)
2. `pr-gate`, `post-merge` (PR 흐름)
3. `deploy-supabase`, `deploy-android-*`, `deploy-ios-*` (deploy, 마지막)

### S6: 기존 GH secret 삭제

모든 workflow 전환 + 1주 안정 운영 후:

```bash
gh secret delete DEV_SUPABASE_URL
gh secret delete PRD_SUPABASE_URL
# ... 인벤토리 표대로 모두 삭제
```

남는 GH secret = `GITHUB_TOKEN` (native) + `MINGLIT_ENV_PAT` (submodule access) 만.

## Submodule + PAT 처리

`minglit_env` 는 별도 repo (`Mark-Yun/minglit_env`) 의 git submodule. workflow 가 cross-org checkout 하려면 PAT 필요.

### 필수 GH secret (migration 후에도 유지)

| Secret | 용도 | scope |
|--------|------|-------|
| `GITHUB_TOKEN` | GitHub 자동 주입 | 현 repo only |
| `MINGLIT_ENV_PAT` | `Mark-Yun/minglit_env` submodule checkout | read only, minglit_env 만 |

### Checkout 패턴

```yaml
- uses: actions/checkout@v6
  with:
    submodules: recursive
    token: ${{ secrets.MINGLIT_ENV_PAT }}
- uses: cardinalby/export-env-action@v2
  with:
    envFile: minglit_env/${{ inputs.stage }}/.env
```

### PAT 관리

- Mark-Yun account 에서 **fine-grained PAT 발급** (Token-Token, scope = repo `Mark-Yun/minglit_env`, permission = Contents read-only)
- `team-minglit/minglit` 의 GH secret 으로 저장 (`MINGLIT_ENV_PAT`)
- 만료 정책: 90일 갱신 권장 (rotation 부담 vs 보안 trade-off)
- 대안: deploy key (SSH) — read-only 더 명확하지만 setup 1회 추가

## Workflow 로딩 패턴

```yaml
# 개념 — 모든 workflow 가 동일 패턴
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: cardinalby/export-env-action@v2
        with:
          envFile: minglit_env/${{ inputs.stage }}/.env
          expand: false
      # 이후 step 에서 $SUPABASE_URL, $FIREBASE_ADMIN_SDK_JSON 직접 참조
      - run: |
          echo "Using stage: ${{ inputs.stage }}"
          # ... actual work
```

**필수 변수 unset 시 fail (early check)**:
```yaml
- name: Validate required env
  run: |
    : "${SUPABASE_URL:?SUPABASE_URL not set}"
    : "${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY not set}"
```

## Risk + Mitigation

| Risk | 영향 | 대응 |
|------|------|------|
| 변수명 typo (file vs workflow) | workflow 가 빈 값 사용, 잘못된 deploy | 변수 카탈로그 README 명시 + early validation step |
| 잘못된 stage file 로딩 (dev workflow 가 main file) | prod 값이 dev 환경 노출 | workflow input `stage` 를 GitHub Environment 이름과 매칭 (`environment: ${{ inputs.stage }}`) — env-scoped 권한 활용 |
| .env 파일 노출 (private repo 가 public 됨) | 모든 secret 노출 | repo 권한 정기 audit, GitHub secret scanning 활성화, 진짜 critical 한 건 GH secret 유지 옵션 |
| Collaborator 추가 시 모든 secret 노출 | 신규 collaborator 가 prod 값 전부 봄 | collaborator 추가 시 review process, 권한 최소화 (read 분리) |
| Migration 중 부분 전환 → 혼란 | 일부 workflow 는 old GH secret, 일부 는 file | 매핑 dashboard 유지, 각 PR 별 전환 workflow 추적 |

## Rollback

- file 기반 workflow PR 별 revert 가능
- 기존 GH secret 은 S6 이전까진 유지 → 그 전까진 즉시 rollback 가능
- 완전 rollback: 모든 migration PR revert + GH secret 복원 (자동화 안 됨, 수동 입력)

## Verification

| Step | 검증 |
|------|------|
| S2 | file 골격이 올바른 syntax (`grep -E '^[A-Z_]+=' minglit_env/main/.env` 통과) |
| S3 | `dev/.env` 의 변수 set 이 기존 4개 file 의 union (script 로 비교) |
| S5 (각 PR) | 해당 workflow 가 통과 + side-effect 정상 (deploy 성공, build 성공) |
| S6 후 | `gh secret list` 결과가 `GITHUB_TOKEN` + `MINGLIT_ENV_PAT` + native (dependabot 등) 만 |

## TBD (구현 중 결정)

- 변수 카탈로그의 정확한 list — 현 GH secret 인벤토리 후 확정
- staging 환경 추가 시점 (execution-plan 의 Supabase staging branch 와 연계)
- workflow 의 `stage` 입력 받는 방식 (workflow_dispatch input vs branch detection)
- `_JSON` suffix 변수의 multi-line / escape 처리 (`FIREBASE_ADMIN_SDK_JSON` 같은 것)
- GitHub Environment 와 file stage 매칭 강제 정책
- migration 진행 중 dashboard / 추적 도구

## 관련

- [execution-plan.md](./execution-plan.md) — Phase 2/3 와 *별도 작업* 명시
- [workflow-spec.md](./workflow-spec.md) — workflow 들이 envFile 로딩하는 패턴
- `minglit_env/README.md` — 통합 후 갱신 대상

---
_Reviewed: 2026-05-19 09:47_
