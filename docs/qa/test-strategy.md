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

| 표현 | 정의 | 사용 예 |
|------|------|--------|
| "골든 스크린샷" / "golden" | Layer 1만 지칭. 픽셀 비교 | "이 위젯 golden 깨졌어" |
| **"시나리오 스크린샷"** | Layer 2만 지칭. CUJ 플로우 캡처 | "시나리오 스크린샷이 안 찍힌다" |
| "스크린샷 리뷰" / "agent 리뷰" | Layer 3만 지칭 | "agent 리뷰에서 잡혔다" |
| "스크린샷" (단독) | 혼동 유발 — 반드시 Layer 명시해서 사용 |

**경로 구분 (Layer 1 vs Layer 2)**:

- `goldens/` (또는 Alchemist 지정 경로) — Layer 1 전용. Layer 2 아티팩트를 여기 저장 금지.
- Layer 2 저장 경로는 아직 미정 (후보: `scenario_screenshots/` 하위, GitHub Artifacts 14d retention, 외부 버킷). 결정은 이슈 #1557에서 `report-exec` 라벨로 Mark 판단 대기.

**경로 구분 (Layer 2 대상 vs 비대상)**:

- `apps/app_user/test/integration/` + `apps/app_partner/test/integration/` → Layer 2 대상
- `tests/client_cuj_integration/` — 삭제됨 (stale 인프라 제거). Layer 2 대상 아님.

### 6.1 Patrol 전환 배경

기존 `IntegrationTestWidgetsFlutterBinding` 기반 E2E는 네이티브 인터랙션(카카오 로그인 WebView, PG 결제, 시스템 권한)을 처리할 수 없었다. Patrol(`patrol_test/` 3개)이 이미 도입되어 있으므로, 전체 integration 테스트를 Patrol로 통합한다.

### 6.2 스크린샷 내장 전략

기존 `scenario_screenshots_test.dart`(정적 화면 캡처)는 삭제됐으며, 각 integration 테스트에 스텝별 `takeScreenshot()`을 삽입한다.

| 항목 | Before | After |
|------|--------|-------|
| 스크린샷 위치 | 별도 파일 (삭제됨) | 각 테스트 내부 |
| 캡처 시점 | 정적 화면만 | setup/before/after/error |
| 네이티브 인터랙션 | 불가 | Patrol로 가능 |
| 예상 캡처 수 | ~40장 (골든 시나리오) | **~141장** (플로우 중간 상태 포함) |

### 6.3 캡처 포인트 정의

상세 포인트는 `docs/qa/screenshot-capture-points.md` 참고.

| 앱 | 파일 수 | 예상 캡처 수 |
|----|---------|------------|
| app_user (CUJ + Flow + 기타) | 25 | ~83 |
| app_partner (CUJ + 기타) | 11 | ~47 |
| patrol (E2E 네이티브) | 3 | ~11 |
| **합계** | **39** | **~141** |

### 6.4 CI 연동

- `patrol-e2e.yml`에 통합 (주 1회 또는 매일)
- 스크린샷 아티팩트 업로드 → Layer 3 agent의 semantic 리뷰 입력으로 활용 (픽셀 비교 아님 — §6.0 참고)
- 네이티브 E2E (카카오 로그인, PG 결제, 권한)는 실물 디바이스에서만 실행

### 6.5 Layer 2 재가동 현황 (2026-04-18)

이 섹션의 계획(§6.2~§6.4)은 머지됐지만 **실제 CI 실행 0건**. 전수 점검 및 복구 작업은 이슈 #1557에서 추적한다. 상세 갭 분석은 `docs/qa/screenshot-capture-points.md` 첫머리 "현재 상태" 블록 참고.

**재가동 선결 의존성**:

- #1553 / PR #1556 — Supabase pooler `aws-0 → aws-1` fix 머지. `seed-and-simulate` 복구 없이는 `client-cuj-test` / `partner-cuj-test` 실행 불가.
- #1539 — `GoldenCapture` CI headless hang 회피 skip을 재활성화 가능한 형태로 대체.
- `.github/scripts/run-client-cuj.sh` / `run-partner-cuj.sh` — 탐색 경로를 `apps/*/test/integration/`로 교정 (현재 `apps/*/integration_test/` 순회 중).

---

## 7. Runtime QA (실물 디바이스 자동화)

Runtime QA 워커는 실물 Android 디바이스에 APK를 설치하고, ADB를 통해 화면 네비게이션과 시각적 검증을 수행한다.

### 역할

- **Smoke 검증**: `docs/qa/test-cases/app-user-smoke.md`, `app-partner-smoke.md` 시나리오를 실물 디바이스에서 실행
- **CUJ 검증**: `cuj-user.md`, `cuj-partner.md`의 핵심 여정을 실물 디바이스에서 재현
- **시각적 회귀 탐지**: 스크린샷 기반으로 UI 렌더링 이상 확인

### 알려진 제약: Flutter + UIautomator 비호환

Flutter 앱은 Skia/Impeller 엔진으로 단일 `FlutterSurfaceView` 위에 렌더링한다. Android UIautomator는 네이티브 View hierarchy를 탐색하므로, **Flutter 위젯의 개별 bounds를 추출할 수 없다** (`bounds="[0,0][0,0]"` 반환). 이는 모든 Flutter 앱 + 모든 Android 디바이스에서 동일하게 발생하는 구조적 제약이다.

**결론**: UIautomator 기반 좌표 추출은 Flutter 앱에서 사용 불가.

### 네비게이션 방법별 비교

| 방법 | Flutter 호환 | 장점 | 단점 | 상태 |
|------|-------------|------|------|------|
| Vision 기반 (Gemini 등) | ✅ | 프레임워크 무관. 실제 화면 기반. | Vision 모델 필요. API 비용. | 운영 중 |
| `adb shell dumpsys accessibility` | ⚠️ 검증 필요 | 네이티브 API. | Flutter semantics 활성화 필요. 좌표 정확도 미검증. | PoC 필요 |
| Flutter Integration Test Driver | ✅ | 가장 안정적. Flutter 네이티브. | 별도 test harness. 워커 아키텍처 변경. | 장기 목표 |
| UIautomator dump | ❌ | — | Flutter에서 bounds 추출 불가. | **사용 불가** |
| 고정 좌표 매핑 | ✅ | 구현 간단. | 해상도/레이아웃 변경 시 깨짐. | 비권장 |

### 관련 이슈

- #1274 — UIautomator dump bounds=[0,0][0,0] 문제 분석 및 전략 결정

---

## 8. 갭 정량 요약

### 테스트 피라미드 현황 vs 목표

```
                     현재              목표 (Phase 3 후)
                   ┌──────┐           ┌──────┐
  E2E (디바이스)   │  0건  │           │  2건  │
                   ├──────┤           ├──────┤
  Integration      │  2건  │           │ 13건  │  ← 가장 큰 갭
  (Mock CUJ)       ├──────┤           ├──────┤
  Smoke/Widget     │137건  │           │251건  │  ← +114건 (48 smoke + 66 기타)
                   ├──────┤           ├──────┤
  Unit (기존)      │343건  │           │343건+ │  ← 유지 + α
                   └──────┘           └──────┘
```

### 핵심 갭

| 갭 | 현재 | 목표 | 위험도 |
|----|------|------|--------|
| **CUJ Integration (app_user)** | 2 | 9 | 🔴 결제/매칭/환불 플로우 미검증 |
| **CUJ Integration (app_partner)** | 0 | 4 | 🔴 파트너 운영 플로우 전무 |
| **Smoke (app_user)** | 부분적 | 18 화면 전체 | 🟡 일부 화면 크래시 미탐지 |
| **Smoke (app_partner)** | 부분적 | 30 화면 전체 | 🟡 신규 화면 추가 시 누락 |
| **라우팅 가드** | 0 (전용) | 12 | 🟡 #970, #965 같은 회귀 |

---

## 8.1 CI/CD 배포 파이프라인 테스트 (Phase 2.1 — #1433, #1434)

> 2026-04-15 배포 실패 인시던트(#1433 iOS, #1434 Android)로 추가.
> Partner 앱 배포 시 `JUSO_CONFIRM_KEY` Secret 미설정으로 빌드 실패.

| 문서 | 내용 | 케이스 수 |
|------|------|-----------|
| `ci-deploy-tests.md` | 배포 Secret 매트릭스, CI 자체 검증 스텝, 빌드 분기 검증 | 19 |

### 핵심 포인트

- **4개 배포 워크플로우** (Android/iOS × User/Partner)의 필수 Secret을 매트릭스로 정리
- Partner 전용 Secret (`JUSO_CONFIRM_KEY`)의 `required: false` 선언 불일치 식별 → 개선 제안 포함
- 배포 실패 알림(`notify-failure.yml`) 동작 검증 케이스 포함

---

## 8.2 에러/환경/미등록라우트 테스트 케이스 (Phase 2.1 — #1421)

> 2026-04-13 갭 분석(#1421) 결과 추가된 테스트 케이스 문서.

| 문서 | 내용 | 케이스 수 |
|------|------|-----------|
| `error-scenarios.md` | P1 에러 3건 (QR 토큰, 카메라 권한, 보완 재제출) + P2 에러 6건 | 35 |
| `environment-tests.md` | P1 딥링크 cold start, 세션 만료 + P2 warm start, 오프라인 복구 | 25 |
| `unregistered-route-tests.md` | GoRouter 미등록 화면 6개 위젯/통합 테스트 정의 | 30 |

### 구현 우선순위

| 순서 | 대상 | 근거 |
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
