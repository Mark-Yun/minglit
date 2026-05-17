# Feature Audit Report — `<category>` · `<YYYY-MM-DD>`

> 인스펙션 리포트. `FRESH_DOC` cycle 트리거로 에이전트가 본 절차를 수행하고 발견 사항을 GitHub Issue 로 파일링한다. 본 문서는 **감사 추적(audit trail)** 이며, 직접 편집하지 않는다.
>
> 새 feature 의 PRD/spec 작성: [`_template/prd.md`](./_template/prd.md) · [`_template/spec.md`](./_template/spec.md). 컨벤션: [`BLUEDOC.md`](./BLUEDOC.md).

## AI 실행 절차 (issue 수령 후)

본 audit 을 수행하는 AI agent 는 아래 6 step 을 순차 실행. \`<category>\` 는 본 보고서의 카테고리로 치환.

### Step 1. 입력 수집 (병렬 실행 가능)

\`\`\`bash
# CUJ 테스트 커버리지
dart run scripts/cuj_coverage.dart --json > /tmp/cuj_cov.json

# MDS render 커버리지
dart run scripts/mds_render_coverage.dart --json > /tmp/mds_cov.json

# 본 카테고리 spec/PRD 파일
find docs/features/<category> -name "spec.md" -o -name "prd.md"

# 최근 7일 본 카테고리 활동
gh issue list --label "feature/<category>-*" --state all --search "updated:>7d" --json number,title,state,labels
gh pr list --state all --search "updated:>7d" --json number,title,headRefName | jq '[.[] | select(.headRefName | test("<category>"))]'
\`\`\`

### Step 2. Section 1 (Spec 점검) 채움

- 각 \`docs/features/<category>/<feature>/prd.md\` 존재 + [\`_template/prd.md\`](./_template/prd.md) 골격 확인
- 각 \`spec.md\` 존재 + 5섹션 (CUJs / FR / NFR / Edge / Open Q) 검증
- 누락/불완전 항목을 표 1-1 / 1-2 / 1-3 에 채움
- 각 발견 → Action Items 표에 P 등급 + Action 한 줄 추가

### Step 3. Section 2 (UI 완성도) 채움

- \`/tmp/mds_cov.json\` 의 uncovered_screens / incomplete_screens / orphan_catalogs → 표 2-1, 2-2
- \`apps/mds/docs/public/specs/<screen>/state_*.png\` 와 \`docs/infra/mds-emulator-render/<screen>/state-*.png\` 쌍을 시각 비교 → 표 2-3

### Step 4. Section 3 (테스트 현황) 채움

- \`/tmp/cuj_cov.json\` per_feature 에서 본 카테고리 필터 → 표 3-1, 3-2 (app_user / app_partner)
- \`supabase/functions/<관련 EF>/\` 디렉토리 + \`*_test.ts\` 매칭 → 표 3-3 EF Deno Unit 행
- \`supabase/tests/database/\` listing + 카테고리 키워드 grep → 표 3-3 Supabase pgTAP 행
- 최근 CI 실패: \`gh run list --branch dev --status failure --limit 20\` → 본 카테고리 path 변경 PR run

### Step 5. Action Items 와 Findings 파일링

발견 사항을 (1) Action Items 섹션 P 등급별 checkbox 로 정렬 + (2) 각각 GitHub Issue 1건 생성:

\`\`\`bash
gh issue create \\
  --title "[<category>] <섹션 ID>: <한 줄 요약>" \\
  --label "feature/<category>-<feature-name>" \\
  --body "<상세 + evidence + suggested action>"
\`\`\`

생성된 issue 번호를 Action Items / Findings 표에 기록.

### Step 6. last_verified 갱신 + 본 issue 닫기

- \`docs/features/<category>/FRESH_DOC\` 의 \`last_verified\` 를 오늘 날짜로 갱신
- 본 보고서 + FRESH_DOC 변경을 1 PR 로 묶어 commit (PR body 에 \`Closes #<원본 doc-refresh issue>\`)

---

## Summary

\`<category>\` 카테고리 (feature \`<N>\` 개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P0 — Critical | \`<N>\` | \`<#aaa>\` |
| P1 — Defect / Gap | \`<N>\` | \`<#bbb> <#ccc>\` |
| P2 — Improvement | \`<N>\` | \`<#ddd>\` |
| P3 — Low | \`<N>\` | \`<#eee>\` |

---

## Action Items by Priority

> 본 audit 의 모든 발견 사항을 처리 우선순위로 정렬. 각 항목은 GitHub Issue 1건과 1:1 매핑. AI agent 는 unchecked 항목 중 가장 높은 priority 를 골라 PR 생성. PR merge 시 checkbox 갱신.
>
> 항목 포맷: \`- [ ] **#<issue>** [Section ID] \\\`category/feature\\\` — <한 줄 설명>. **Action**: <구체 처리 방법>. **Evidence**: <path 또는 도구 출력>.\`

### P0 — Critical (즉시 처리)

> 서비스 장애 / 보안 / 법무 / 데이터 무결성. **당일 처리.**

- [ ] \`<#issue>\` \`[<섹션 ID>]\` \`<category>/<feature>\` — \`<설명>\`. **Action**: \`<처리 방법>\`. **Evidence**: \`<path>\`.

### P1 — Defect / Gap (이번 스프린트)

> spec ↔ 구현 / 테스트 누락 / 핵심 기능 버그. **이번 주.**

- [ ] \`<#issue>\` \`[<섹션 ID>]\` \`<category>/<feature>\` — \`<설명>\`. **Action**: \`<처리 방법>\`. **Evidence**: \`<path>\`.

### P2 — Improvement (다음 스프린트)

> UX 개선 / refactor / 비효율. **다음 스프린트.**

- [ ] \`<#issue>\` \`[<섹션 ID>]\` \`<category>/<feature>\` — \`<설명>\`. **Action**: \`<처리 방법>\`. **Evidence**: \`<path>\`.

### P3 — Low (여유 시)

> Cosmetic / 문서 보강 / 미세 조정. **여유 시.**

- [ ] \`<#issue>\` \`[<섹션 ID>]\` \`<category>/<feature>\` — \`<설명>\`. **Action**: \`<처리 방법>\`. **Evidence**: \`<path>\`.

---

## 1. Spec 점검

**Method**: `docs/features/<category>/<feature>/` 내 `prd.md` + `spec.md` 를 [`BLUEDOC.md`](./BLUEDOC.md) 5섹션 컨벤션 + [`_template/`](./_template/) + canonical example ([`account/signup-consent/`](./account/signup-consent/)) 와 대조.

### 1-1. PRD 누락 / 부족

| 점검 | 결과 |
|------|------|
| prd.md 부재 features | `<feature 목록>` |
| Summary / Motivation 누락 | `<feature 목록>` |
| Goals 의 P0/P1 / Non-Goals 모호 | `<feature 목록>` |
| User Journey ↔ CUJ ID prefix (`Scenario N → CUJ N-x`) 매핑 누락 | `<feature 목록>` |

### 1-2. spec.md 5섹션 완성도

| 점검 | 결과 |
|------|------|
| spec.md 부재 features | `<feature 목록>` |
| 5섹션 구조 미적용 (옛 포맷 / 자유 형식) | `<feature 목록>` |
| CUJs 테이블 행 부족 (1 scenario 당 평균 N+ 권장) | `<feature 목록 + 권장 추가 CUJ>` |
| FR ↔ CUJ 매핑 누락 | `<FR 번호>` |
| NFR 측정 불가능 ("빨라야 함" 류 — 환경/p50/p99 명시 X) | `<NFR 번호>` |
| Edge Cases 비어있음 | `<CUJ ID 목록>` |
| Open Questions 1주+ 방치 | `<항목 + 작성일>` |

### 1-3. PRD ↔ spec.md ↔ MDS 트레이스

| 점검 | 결과 |
|------|------|
| PRD Scenario 와 spec.md CUJ ID prefix 불일치 | `<scenario 번호>` |
| spec.md 참조 MDS state PNG 부재 | `<screen/state>` |
| 개발 detail 이 spec.md 에 포함됨 (SQL/Provider/메서드 시그니처 — dev SSoT 인 코드/migration 으로 이동 권고) | `<spec.md 위치>` |

**Findings**:
- `<#issue>` — `<한 줄 요약>`. Evidence: `<file path>`. Severity: `<P0/P1/P2>`.

---

## 2. UI 완성도

**Method**:
- MDS spec (디자인 의도): `apps/mds/docs/public/specs/<screen>/state_*.png` ([`sync-mds-mockups.yml`](../../.github/workflows/sync-mds-mockups.yml) 가 Playwright 로 HTML → PNG 렌더)
- 앱 render (실 구현): `docs/infra/mds-emulator-render/<screen>/<state>.png` ([`mds_emulator_render_driver.dart`](../../apps/app_user/test_driver/mds_emulator_render_driver.dart) 가 emulator 위에서 캡처)
- 두 PNG 쌍을 시각 비교

### 2-1. MDS spec 완성도

| 점검 | 결과 |
|------|------|
| spec.md CUJ Details 에 언급된 상태가 MDS state PNG 로 존재 (loading / error / empty 등 누락 검출) | `<screen/state 누락>` |
| MDS state PNG 수가 spec.md CUJ 수에 비해 부족 | `<screen>: PNG <N> / CUJ <M>` |

도구: `dart run scripts/mds_render_coverage.dart` (spec.md ↔ MDS state count)

### 2-2. 앱 render coverage

| 점검 | 결과 |
|------|------|
| mds-emulator-render `_registry.dart` 미등록 screen (uncovered) | `<screen 목록>` |
| catalog 됐지만 state 불충분 (incomplete) | `<screen>: captured <N> / mds <M>` |
| catalog 됐지만 MDS spec 없음 (orphan) | `<catalog name>` |

도구: `dart run scripts/mds_render_coverage.dart` — uncovered_screens / incomplete_screens / orphan_catalogs 출력.

### 2-3. 앱 render ↔ MDS spec drift (시각 비교)

매칭된 PNG 쌍에서 다음 검출:

| 항목 | 결과 |
|------|------|
| Color drift (primary / surface / on-surface) | `<screen/state>` |
| Layout drift (spacing / alignment / 요소 순서) | `<screen/state>` |
| Typography drift (font / weight / size) | `<screen/state>` |
| 컴포넌트 차이 (위젯 누락 / 추가) | `<screen/state>` |

시각 diff 도구: 현재 수동 검토 (자동 diff 도구화는 후속 작업).

**Findings**:
- `<#issue>` — `<한 줄 요약>`. Evidence: `<paired PNG paths>`. Severity: `<P0/P1/P2>`.

---

## 3. 테스트 현황

> spec.md CUJ 가 실제로 검증되는지 + 비즈니스 로직 / 데이터 무결성 / EF 통합이 cover 되는지.

### 3-1. app_user

| Layer | Path | 점검 항목 | 결과 |
|------|------|-----------|------|
| Unit | `apps/app_user/test/src/` | feature 별 핵심 비즈니스 로직 (logic/, repository/) cover 여부 | `<누락 모듈>` |
| Widget | `apps/app_user/test/` (golden 제외) | 화면별 widget test 존재 여부 (alchemist 옛 golden 은 deprecated) | `<누락 화면>` |
| CUJ integration | `apps/app_user/integration_test/cuj/` | spec.md CUJ ↔ cujGroup ID 매핑 (uncovered / orphan 검출) | `<feature: covered/spec>` |

도구: `dart run scripts/cuj_coverage.dart` — coverage_pct / uncovered_features / orphan_features 출력.

### 3-2. app_partner

| Layer | Path | 점검 항목 | 결과 |
|------|------|-----------|------|
| Unit | `apps/app_partner/test/src/` | 동일 | `<누락 모듈>` |
| Widget | `apps/app_partner/test/` | 동일 | `<누락 화면>` |
| CUJ integration | `apps/app_partner/integration_test/cuj/` | 동일 | `<feature: covered/spec>` |

도구: 동일 (`scripts/cuj_coverage.dart` 가 양 앱 cover).

### 3-3. Backend

| Layer | Path | 점검 항목 | 결과 |
|------|------|-----------|------|
| EF Deno Unit | `supabase/functions/<ef>/...test.ts` | edge function 별 단위 테스트 cover | `<누락 EF>` |
| Supabase pgTAP | `supabase/tests/database/*.sql` | RPC / trigger / RLS policy 테스트 | `<누락 RPC / 테이블>` |
| EF CUJ integration | `supabase/functions/_*_integration_tests/` (별도 PR 진행 중) | EF 다중 호출 결합 시나리오 | `<TBD — PR 머지 후>` |
| EF Event-flow integration | `supabase/functions/event-flow-simulator/` (별도 PR 진행 중) | end-to-end backend 시뮬레이션 (cascade 시나리오) | `<TBD — PR 머지 후>` |

### 3-4. CI 실패 패턴

- 최근 7일 본 카테고리 관련 CI 실패: `<job 이름 + 실패율>`
- 플레이키 (재실행으로 통과) 사례: `<test 이름 + 횟수>`

**Findings**:
- `<#issue>` — `<한 줄 요약>`. Evidence: `<test path 또는 CI run URL>`. Severity: `<P0/P1/P2>`.

---

## Findings (issue filing)

각 발견 사항을 GitHub Issue 로 파일링 + 본 표에 기록. 분류 prefix 는 위 섹션 번호 (1-1, 2-2, 3-3 등).

| ID | 분류 | 한 줄 설명 | Evidence | Severity | Effort |
|----|------|----------|----------|----------|--------|
| `<#issue>` | `1-1` | `<요약>` | `<path:line>` | `<P0/P1/P2>` | `<S/M/L>` |

---

## Inputs Consulted

| 입력 | 경로 / 도구 |
|------|-----------|
| PRD / spec | `docs/features/<category>/<feature>/{prd,spec}.md` |
| Templates | `docs/features/_template/{prd,spec}.md` |
| BLUEDOC | `docs/features/BLUEDOC.md` |
| MDS spec PNG | `apps/mds/docs/public/specs/<screen>/state_*.png` |
| 앱 render PNG | `docs/infra/mds-emulator-render/<screen>/state-*.png` |
| MDS render coverage | `scripts/mds_render_coverage.dart` |
| app_user CUJ tests | `apps/app_user/integration_test/cuj/<category>/<feature>_test.dart` |
| app_partner CUJ tests | `apps/app_partner/integration_test/cuj/<category>/<feature>_test.dart` |
| CUJ coverage | `scripts/cuj_coverage.dart` |
| Supabase pgTAP | `supabase/tests/database/*.sql` |
| EF Deno tests | `supabase/functions/*/...test.ts` |
| EF integration tests | `supabase/functions/_*_integration_tests/` |
| Event-flow simulator | `supabase/functions/event-flow-simulator/` |
| Recent activity | `gh issue list / pr list` (최근 7일, `<category>` 라벨 또는 path filter) |

---

## Run Metadata

- Agent: `<runner id>`
- Duration: `<HH:MM>`
- Cycle: `<Nd>` (next: `<YYYY-MM-DD>`)
- Template version: `<git sha>`
