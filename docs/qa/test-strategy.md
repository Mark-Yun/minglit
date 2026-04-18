# 테스트 전략 — 7-Layer Taxonomy (SSOT)

> 이 문서는 Minglit 모노레포의 테스트 계층 정의 **Single Source of Truth**.
> 관련 이슈: #1586 (Phase A — 본 문서 재작성)
> 최근 업데이트: 2026-04-18 (taxonomy 확정, 용어 통일)

---

## 1. 왜 7-layer 인가

테스트 코드/워크플로우/문서가 여러 위치에 흩어져 있어 **이름 충돌**과 **용도 불명** 이 혼재했다.

| 혼동 예 | 기존 상황 | 원인 |
|--------|----------|------|
| "integration" 4중 의미 | `apps/*/test/integration/` (위젯 플로우) + `apps/*/integration_test/` (Patrol) + `tests/backend_integration/` (DB — 이미 이관) + `tests/client_cuj_integration/` (삭제) | 계층 이름에 `integration` 범람 |
| "Golden" 스크린샷 vs "시나리오" 스크린샷 | 동일 단어 "스크린샷"이 Alchemist 픽셀 비교 / CUJ 증거 사진 / AI agent 리뷰 3가지를 지칭 | Layer 정의 부재 |
| "E2E" 의미 불명 | "Patrol e2e" + "client-cuj-test" + "backend-simulator" 모두 E2E 로 불림 | 범위가 서로 다름 |

**해결**: 테스트 대상/프레임워크/주기 기준으로 7-layer 로 정규화. 이하 모든 문서/워크플로우/폴더명은 이 이름을 따른다.

---

## 2. 7-Layer Taxonomy

### 📱 App Level (`apps/app_*/`)

| # | Layer | 대상 | 위치 (현재 — 2026-04-18) | 프레임워크 | 주기 |
|---|-------|------|---------------------------|-----------|------|
| 1 | **Unit test** | Feature/logic 순수 단위 (repository, controller, util) | `apps/app_*/test/src/`, `shared/packages/minglit_kit/test/src/` | `flutter_test` (headless) | PR 마다 |
| 2a | **Widget flow test** | 다화면 위젯 인터랙션 (mock 기반) | `apps/app_*/test/integration/` *(향후 `test/flows/` rename 검토 — #1586 Phase C)* | `flutter_test` (headless) | PR 마다 |
| 2b | **Golden image test** | 시각 회귀 감지 (픽셀 비교) | `apps/app_*/test/goldens/` *(향후 `test/alchemist/` rename — #1586 Phase C, PR #1582)* | Alchemist | PR 마다 |
| 3 | **Emulator test** | Patrol 기반 네이티브 surface + 실 DB CUJ + 시나리오 스크린샷 | `apps/app_*/integration_test/` *(향후 `emulator_test/` rename — #1582)* | Patrol | 주 1회 + 수동 |

### 🗄️ Backend Level (`supabase/` + EF)

| # | Layer | 대상 | 위치 | 프레임워크 | 주기 |
|---|-------|------|------|-----------|------|
| 4 | **pgTAP** | DB 스키마 / 트리거 / RPC / RLS 계약 | `supabase/tests/database/` | pgTAP | PR 마다 |
| 5 | **Deno EF test** | Edge Function TypeScript 로직 단위 | `supabase/functions/**/*_test.ts` | `deno test` | PR 마다 |
| 6 | **DB monitor** | Runtime invariant 감시 | `check_db_invariants()` RPC + `.github/workflows/db-invariants.yml` | SQL | 매시간 cron |
| 7 | **Tick simulator** | 서버 pipeline 관통 시뮬 (시간 전진 + 파이프라인 부하) | `backend-simulator` EF + `.github/workflows/daily-backend-simulation.yml` + `hourly-user-activity.yml` | EF + HTTP | 매시간 + 매일 |

### 보조 (taxonomy 밖, 유지)

| 항목 | 위치 | 성격 |
|------|------|------|
| Secret scan | `.github/workflows/secret-scan.yml` | 보안 |
| Migration version check | `ci.yml` job | Pre-test gate |
| Env manifest sync | `ci.yml` job | 환경변수 정합성 |
| Landing lint/build | `ci.yml` job | Next.js 빌드 |
| Allure report | `allure-report.yml` | 결과 집계 |
| Update goldens | `update-goldens.yml` | Layer 2b 유지보수 |

---

## 3. Layer 별 책임 / 비책임

**원칙**: 각 layer 는 본인 책임 범위에만 집중한다. 다른 layer 가 담당하는 것을 테스트하면 **중복** 이 생기고, 실패 분석과 유지보수 비용이 증가한다.

### Layer 1 — Unit

| ✅ 책임 | ❌ 비책임 |
|--------|----------|
| repository 메서드 happy path + error case | UI 렌더링 (→ 2a/2b) |
| controller/provider 상태 전이 | 외부 서비스 호출 (→ 5/7) |
| util/formatter 순수 함수 | 네이티브 surface (→ 3) |
| minglit_kit 공유 로직 | DB 스키마 검증 (→ 4) |

### Layer 2a — Widget flow

| ✅ 책임 | ❌ 비책임 |
|--------|----------|
| GoRouter guard / redirect 로직 | 실 네트워크 / 실 DB (→ 3) |
| 다화면 위젯 조합 (mock provider override) | 픽셀 레벨 시각 검증 (→ 2b) |
| 로그인 상태별 분기 렌더링 | PG/WebView 등 네이티브 브릿지 (→ 3) |
| 딥링크 파라미터 처리 | |

### Layer 2b — Golden image

| ✅ 책임 | ❌ 비책임 |
|--------|----------|
| 디자인 토큰 / 컴포넌트 시각 회귀 차단 | 상태 변화 / 인터랙션 (→ 2a) |
| Ahem 폰트 기반 CI golden (OS 무관) | 실 DB 데이터 렌더링 (→ 3) |
| `@Tags(['golden'])` 로 분리 실행 | 스텝별 플로우 스냅샷 (→ 3, "시나리오 스크린샷") |

### Layer 3 — Emulator

| ✅ 책임 | ❌ 비책임 |
|--------|----------|
| 실 Android emulator 에서 Patrol 실행 | 단위 로직 회귀 감지 (→ 1) |
| 네이티브 surface (카카오 WebView, PG SDK, 시스템 권한) | 픽셀 비교 (→ 2b) |
| 실 dev Supabase 연동 CUJ (auth/RLS 실경로) | DB 스키마 계약 (→ 4) |
| 스텝별 "시나리오 스크린샷" 생성 (Layer 3 agent 리뷰 input) | |

### Layer 4 — pgTAP

| ✅ 책임 | ❌ 비책임 |
|--------|----------|
| 테이블 / 컬럼 존재 검증 | EF 로직 (→ 5) |
| RLS 정책 / 트리거 동작 | 앱 렌더링 (→ 1-3) |
| RPC 함수 시그니처 | runtime invariant 감시 (→ 6) |

### Layer 5 — Deno EF

| ✅ 책임 | ❌ 비책임 |
|--------|----------|
| EF handler TypeScript 로직 | DB 스키마 (→ 4) |
| 외부 API mock (Iamport, FCM) | 실 DB 데이터 (→ 7) |
| 입력 검증 / 에러 분기 | 다중 EF 파이프라인 관통 (→ 7) |

### Layer 6 — DB monitor

| ✅ 책임 | ❌ 비책임 |
|--------|----------|
| 매시간 invariant 감시 (고아 row, 정원 초과 등) | 계약 회귀 감지 (→ 4) |
| 실 dev DB 데이터에 대한 실시간 검증 | 기능 테스트 (→ 1-5) |
| alert 발송 | |

### Layer 7 — Tick simulator

| ✅ 책임 | ❌ 비책임 |
|--------|----------|
| 시간 전진 (시뮬레이션 tick) → 이벤트 생명주기 관통 | 단일 EF 단위 테스트 (→ 5) |
| 매칭 / 결제 / 정산 파이프라인 연쇄 검증 | 앱 UI (→ 1-3) |
| 매시간 user activity 시뮬 | 스키마 검증 (→ 4) |

---

## 4. 현재 커버리지 수치 (2026-04-18)

실측 기반. Issue #1586 Phase D-1 측정 결과.

### Layer 1 — Unit

| 앱 | 위치 | 파일 수 |
|----|------|--------|
| minglit_kit | `shared/packages/minglit_kit/test/` | 99 |
| app_user | `apps/app_user/test/src/` | 65 |
| app_partner | `apps/app_partner/test/src/` | 71 |

### Layer 2a — Widget flow

| 앱 | 위치 | 파일 수 |
|----|------|--------|
| app_user | `apps/app_user/test/integration/` | 26 |
| app_partner | `apps/app_partner/test/integration/` | 11 |

### Layer 2b — Golden image

| 앱 | 위치 | `*_golden_test.dart` |
|----|------|---------------------|
| app_user | `apps/app_user/test/goldens/` | 14 |
| app_partner | `apps/app_partner/test/goldens/` | 15 |

### Layer 3 — Emulator (Patrol)

| 앱 | 위치 | 파일 수 | 성격 |
|----|------|--------|------|
| app_user | `apps/app_user/integration_test/` | 5 | `apple_sign_in`, `kakao_login`, `payment_pg`, `permission_grant`, `scenario_screenshots` — **native surface 특수 테스트만**. CUJ 이관 0% |
| app_partner | `apps/app_partner/integration_test/` | 1 | `scenario_screenshots` 만 |

**Layer 3 런타임 상태**: `patrol-e2e.yml` 실행 이력 0건. `scenario_screenshots_test.dart` 내부 캡처 호출 0건. **사실상 죽은 상태.** 재가동 계획은 §6 로드맵 및 #1586 Phase D-2 참고.

### Layer 4 — pgTAP

- `supabase/tests/database/` : 80 파일 (*.sql)
- `tests/backend_integration/` → 2026-04-18 Deno/pgTAP 흡수 완료 (#1574)

### Layer 5 — Deno EF

- `supabase/functions/**/*_test.ts` : 75 파일

### Layer 6 — DB monitor

- RPC: `check_db_invariants()` (supabase/migrations 에서 정의)
- 워크플로우: `.github/workflows/db-invariants.yml` — 매시간 cron
- 상태: **구현 존재. 2026-04-15 이슈 #1549 로 재등록 확인.**

### Layer 7 — Tick simulator

- EF: `supabase/functions/backend-simulator/`
- 워크플로우:
  - `daily-backend-simulation.yml` — 매일 (PR #1584 로 pg_cron 에서 GH Actions 로 이관)
  - `hourly-user-activity.yml` — 매시간
- 상태: **정상 동작.**

---

## 5. 스크린샷 3-Tier 아키텍처 (Layer 2b + 3 + Layer 3-agent 의 관계)

"스크린샷" 이라는 단어가 세 가지 독립 자산을 가리키므로 용어를 분리한다. 본 섹션이 팀 전체의 SSOT.

> 주의: 아래 **Tier** 는 7-layer taxonomy 의 **Layer** 와 별개 차원이다. 혼동 방지 위해 "Tier" 용어 사용.

```
[Tier A] 골든 스크린샷 (7-layer 의 Layer 2b)
  - Alchemist 픽셀 비교
  - 디자인 토큰 / 컴포넌트 회귀 차단
  - 실패 시 PR 차단

[Tier B] 시나리오 스크린샷 (7-layer 의 Layer 3 내부)
  - Patrol CUJ 테스트 내 스텝별 `$.native.screenshot(name: ...)`
  - "지금 실제 화면" 증거 사진 — 픽셀 비교 아님
  - 출력: artifact retention 14d 이상 (Tier C agent 접근용)

[Tier C] AI agent 스크린샷 리뷰 (후속 구현)
  - Tier B 아티팩트를 agent 가 전수 semantic 리뷰
  - 감지: 깨진 이미지, 누락 라벨, 레이아웃 오류
  - 출력: bug-report 이슈 자동 생성
```

**용어 규칙**:

| 표현 | 정의 | 예시 |
|------|------|------|
| "golden" / "골든" | Tier A 만 지칭 (7-layer Layer 2b) | "이 위젯 golden 깨졌어" |
| **"시나리오 스크린샷"** | Tier B 만 지칭 (7-layer Layer 3) | "시나리오 스크린샷이 안 찍힌다" |
| "스크린샷 리뷰" / "agent 리뷰" | Tier C 만 지칭 | "agent 리뷰에서 잡혔다" |
| "스크린샷" (단독) | **혼동 유발 — Tier 명시 필수** | |

**경로 구분**:

| 경로 | Tier | Layer |
|------|------|-------|
| `apps/*/test/goldens/` (향후 `test/alchemist/`) | Tier A | Layer 2b |
| `apps/*/integration_test/` (향후 `emulator_test/`) — Patrol | Tier B 생성 위치 | Layer 3 |
| `apps/*/*/screenshots/` (Patrol 출력 — 향후 경로) | Tier B 저장 | Layer 3 |

상세 캡처 포인트 매핑: `docs/qa/screenshot-capture-points.md`.

---

## 6. 로드맵

### 🔴 최우선 — Layer 3 재가동 (Issue #1586 Phase D-2)

현재 Patrol 이관률 0%. 37 CUJ/flow 파일 (`apps/app_user/test/integration/` 26 + `apps/app_partner/test/integration/` 11) 을 Patrol + 실 dev Supabase 로 전환.

- D-2 PoC: 2-3 CUJ Patrol 변환 + CI 돌아감 + 스크린샷 생성 (2026-04)
- D-2 전량: CUJ 5-10 개 단위로 쪼갠 PR 병합 (15-23일 FTE 예상)
- D-3-a: `patrol-e2e.yml` 수동 trigger 성공 1회 확인
- D-3-b: matrix shard 6-8 → wall-clock < 20min 달성
- D-4: 스크린샷 git commit 파이프라인 (또는 auto-PR) 가동

### 🟡 중기 — 폴더 / 워크플로우 정합 (Issue #1586 Phase B / C)

- Phase B: 워크플로우 이름 layer 명시 (`Weekly: Emulator Test (Patrol)` 등)
- Phase C: `test/visual_qa/` 삭제, `test/scenarios/` 흡수, `test/integration/` → `test/flows/` rename 검토

### 🟢 상시 — Layer 1-2 보강

- CUJ P0 범위 widget flow 보강 (체크인, 매칭, 정산)
- 신규 화면 추가 시 Layer 1 unit + Layer 2a flow 동반 필수

### ✅ 최근 완료

| 완료 | 내용 | PR / Issue |
|------|------|-----------|
| Layer 4 통합 | `tests/backend_integration/` → pgTAP 이관 | #1574 |
| Layer 7 복구 | backend-simulation pg_cron → GH Actions | #1584 |
| 스크린샷 3-tier 아키텍처 명문화 | `screenshot-capture-points.md` | #1559 |
| Layer 3 artifact upload wiring | `run-client/partner-cuj.sh` 경로 수정 | #1577 |

---

## 7. 관련 문서

| 문서 | 역할 |
|------|------|
| [automation-test-guide.md](automation-test-guide.md) | Layer 별 작성 규칙 + 샘플 코드 + 체크리스트 |
| [screenshot-capture-points.md](screenshot-capture-points.md) | Tier B (시나리오 스크린샷) 캡처 포인트 매핑 |
| [routing-test-plan.md](routing-test-plan.md) | Layer 2a 라우팅 테스트 상세 계획 |
| [test-cases/](test-cases/) | runtime-qa 워커가 실행하는 실물 디바이스 시나리오 카탈로그 |
| [dev-deeplink-guide.md](dev-deeplink-guide.md) | 딥링크 수동 테스트 가이드 |

---

## 8. 변경 이력

| 날짜 | 변경 | 이슈 |
|------|------|------|
| 2026-04-18 | 7-layer taxonomy 정식 도입. Phase 2 초안 전면 재작성 | #1586 Phase A |
| 2026-04-18 | 스크린샷 3-tier 용어 통일 ("Layer" → "Tier" 로 분리) | #1586 Phase A |
| 2026-04-18 | `tests/backend_integration/` → pgTAP 흡수 반영 | #1574 |
| 2026-04-15 | 스크린샷 3-layer 아키텍처 초안 | #1557 |
| 2026-04-15 | Patrol 전환 + 스크린샷 내장 결정 | #1458 |
| 2026-04-05 | Phase 2 초안 (Widget / Integration / E2E 3 계층) | — |
