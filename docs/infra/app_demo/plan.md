# app_demo — Plan

단계별 작업 + 합격 기준 + success metrics. 설계는 [architecture.md](./architecture.md), 진입점은 [BLUEDOC.md](./BLUEDOC.md).

## 목표 / 비-목표

**목표**
- 데모 flavor APK 가 **서버 0 연결**로 부팅·동작
- emulator-render 와 fixture SSoT 공유 (`minglit_demo` 패키지)
- prod 코드 drift 방지 (lint + CI 가 자동 잡음)
- 실제 라우터·뷰·Coordinator **100% 재활용**

**비-목표**
- 시나리오 선택 화면 / Storybook 모드 / 데모 전용 위젯 — 안 만듦

## Success Metrics

3 계층으로 측정. **출시 게이트는 binary**, **운영 건강성은 recurring**, **효과는 soft (사람의 회고)**.

### 1. 출시 게이트 (binary, P5 마일스톤에서 결정)

| 지표 | 기준 | 측정 도구 |
|---|---|---|
| **네트워크 격리** | 데모 부팅·홈·이벤트 상세·결제 플로우 동안 outbound 패킷 0 | Charles Proxy / mitmproxy 수동 캡처 1회 |
| **라우터 커버리지** | 모든 라우트가 데모 모드에서 진입 가능 (크래시 0) | smoke test (`flutter test` — 각 라우트 push → render) |
| **Lint 컴플라이언스** | Repository 외부에서 `Supabase.instance.client` 호출 0 | `dart-custom-lint` (P0 의 0e 룰) — 위반 시 PR fail |
| **CI demo 빌드** | `flutter build apk --flavor demo` 양 앱 통과 | GitHub Actions 잡 (P8 또는 P4 직후) |
| **Fixture SSoT** | mock 데이터 소스 5+ → 1 (`minglit_demo`) | repo grep — 다른 위치에 fixture 데이터 0 |
| **Freezed 모델 reuse** | fixture 가 prod 모델 import (별 모델 정의 0) | `dart analyze` + grep |
| **Prod 의존성 격리** | prod 빌드 그래프에 `minglit_demo` 0건. prod 코드 (`lib/main.dart`, `lib/src/`) 가 `minglit_demo` import 0건 | `dart pub deps --no-dev` + `grep -r "package:minglit_demo" apps/*/lib/main.dart apps/*/lib/src/` |
| **단방향 의존** | `minglit_kit` 가 `minglit_demo` import 0건 (반대 방향만 OK) | grep + `dart pub deps` audit |
| **`minglit_demo` 의 의존 청결** | `mocktail`, `flutter_test`, `supabase_flutter`, `firebase_*` 미포함 | `pubspec.yaml` audit |
| **리팩토링 효율 (net negative)** | P0-P4 누적 — 기존 통합·삭제된 코드 라인 ≥ 새로 추가된 prod 코드 라인 | PR diff stat 누적 audit (P5 시점) |

**P5 마일스톤 정의**: 위 10 가지 모두 green → "시연 가능 + 건강한 의존성" 선언.

리팩토링 효율 metric 의 의미: 데모를 위해 prod 가 부풀어선 안 됨. **기존 산재 (`Supabase.instance.client` 직접 호출, mock 5+ 위치 등) 흡수·삭제 라인이 새 prod 코드 라인보다 같거나 커야** 함. 그렇지 않으면 설계 재검토. (`minglit_demo` 패키지 자체의 라인은 별도 — prod 가 아니므로 카운트 제외.)

### 2. 운영 건강성 (P6 이후, recurring)

| 지표 | 목표 | 측정 방법 | 주기 |
|---|---|---|---|
| **MDS state 커버리지 (user)** | **≥95%** of MDS-defined screen states | `scripts/mds_render_coverage.dart` (P2 phase 2 산출) | 주간 |
| **MDS state 커버리지 (partner)** | **≥95%** (P7 이후) | 동일 도구 | 주간 |
| **user 앱 CUJ pass rate (demo flavor)** | **≥80%** of CUJ 테스트가 demo flavor 에서 pass | `flutter test integration_test/cuj/ --flavor demo` | PR 별 (CI) |
| **partner 앱 CUJ pass rate (demo flavor)** | ≥80% (P7 이후) | 동일 | PR 별 |
| Demo flavor 빌드 깨짐 빈도 | < 1회/월 | CI 실패 잡 추적 | 월간 review |
| Fixture 갱신 lag | 새 DB 모델 컬럼 추가 후 fixture 업데이트까지 < 1 PR | PR audit | 분기 |
| Demo APK 크기 vs prod | prod ±20% 이내 | 빌드 출력 비교 (CI 아티팩트) | PR 별 |
| Demo flavor 빌드 시간 | < 8분 (CI) | CI 메트릭 | PR 별 |
| Demo-only 버그 비율 | < prod 버그 30% (덜 깨짐) | Linear 라벨 `demo-only` | 월간 |

**Coverage metric 의미**:
- **MDS state 95%**: MDS 가 화면별로 정의한 state (empty/loading/error/dark/various data) 중 95% 이상이 `mds-emulator-render` 로 PNG 캡처됨. 현재 ~8.5% (`apps/app_user/integration_test/mds-emulator-render/architecture.md` 참고). 도달 = "데모의 시각적 완성도가 디자인 의도와 일치"
- **CUJ 80%**: 기존 `integration_test/cuj/` 의 critical user journey 테스트가 demo flavor 에서도 통과. 도달 = "데모가 기능적으로 시연 가능한 깊이까지 갖춰짐"

두 지표는 **P6 합격 기준** 으로 묶임 (아래 P6 섹션).

### 3. 효과 (장기, soft — 정량화 불완전)

| 지표 | 측정 방법 |
|---|---|
| 영업·마케팅 데모 활용 (월 횟수) | 영업팀 manual 회고 (분기 1회) |
| 스토어 스크린샷 demo flavor 출처 비율 | 마케팅팀 manual |
| 신규 입사자 onboarding 시 demo 활용 여부 | HR 회고 |
| 데모 보고 "앱 처음 보는 느낌" / "실 앱과 동일 느낌" 평 | 영업/투자자 회고 (정성) |

**측정 안 함 (vanity)**
- 데모 APK 다운로드 수 (개수보단 활용 횟수가 중요)
- 데모 fixture 라인 수 (양 = 품질 아님)
- 데모 flavor 코드 커버리지 (실 앱 코드와 동일이라 의미 없음)

## 단계별 작업

총 8 phase. **P0 → P1 → P2 → P3 → P4 → P5** 까지가 시연 가능 마일스톤. 이후 P6-P8 점진/병렬.

### P0 — Repository DI 통일 + lint 룰

**목표**: 모든 Repository / non-Repository 가 `ref.watch(supabaseClientProvider)` 경유. 단축경로 재발 차단.

**작업**
- [ ] **0a** Pattern A 5개: `auth, verification, staff, storage, checkin` provider 함수 → `ref.watch(supabaseClientProvider)` 주입
- [ ] **0b** Pattern B 15+개: `account, party, event, ticket, settlement, user, partner, location, consent, policy, tag, recurrence_rule, matching, iamport, social` 동일 패턴
- [ ] **0c** Pattern C 2개: `data/services/bug_report_collector.dart`, `features/social/logic/social_interaction_controller.dart` provider/ref 경유로 변환
- [ ] **0d** 신규 테스트: `ProviderContainer` 에 `supabaseClientProvider.overrideWith(...)` → 모든 repo 가 새 client 받는지 검증
- [ ] **0e** `shared/packages/minglit_lints/` 에 `no-direct-supabase-instance` 룰 (Repository 외부 호출 금지)

**합격 기준**
- prod 동작 동일 (회귀 테스트 100% 통과)
- 새 lint 룰 위반 0 (existing code clean)
- 새 테스트 green

**리스크**: 낮음 (semantic-equivalent). ~23 파일, ~150 line diff.

---

### P1 — `minglit_demo` 패키지 신설 + mock 흡수

**목표**: fixture SSoT 확보. test 의 mock 소스 5+ 곳을 흡수.

**작업**
- [ ] `shared/packages/minglit_demo/` 신규 (`pubspec.yaml`, `BLUEDOC.md`)
- [ ] `lib/fixtures/`: demo_user, demo_events, demo_parties, demo_tickets, demo_payments, demo_verifications, demo_settlements, demo_world
- [ ] `lib/overrides/demo_overrides.dart`: `demoOverrides({events?, empty?, ...})` 시그니처 (옵션 0개여도 확장 가능 형태)
- [ ] 기존 mock 소스 흡수 + import 갱신
  - `apps/app_user/integration_test/mds-emulator-render/_mocks/data.dart`
  - `apps/app_user/test/utils/mocks.dart`
  - `apps/app_user/test/integration/utils/test_mocks.dart`
  - `apps/app_user/test/integration/utils/mock_data.dart`
  - `apps/app_partner/test/utils/mocks.dart`
  - (P1 진입 전 1차 grep 으로 추가 소스 확인)

**합격 기준**
- 기존 test 모두 green (import 갱신만)
- `dart analyze` 통과 — Freezed 모델 reuse 검증
- 다른 위치 fixture 산재 0 (grep)

**리스크**: 중간. 흡수 과정에서 미묘한 차이 발견 가능 → 가장 풍부한 fixture 기준으로 통합.

---

### P2 — emulator-render 의 builder 가 `minglit_demo` 사용

**목표**: 첫 외부 소비자로서 `minglit_demo` 인터페이스 검증.

**작업**
- [ ] `apps/app_user/integration_test/mds-emulator-render/<screen>/builder.dart` × 5 (home_page, login_page, notification_*, search_page) — `_mocks/` 경유 → `minglit_demo` 경유
- [ ] `_mocks/coordinators.dart`, `_mocks/notifiers.dart` 는 Mocktail 의존이라 test 안 잔류 — 명확히 분리. `_mocks/data.dart` 는 제거 (minglit_demo 로 흡수됨)

**합격 기준**
- 기존 PNG 캡처 재실행 → 결과 동일 (golden 비교)
- `dart analyze` 통과

**리스크**: 낮음 — test 영역.

---

### P3 — `appStartup()` 컴포저블 분해

**목표**: 외부 SDK init 을 함수 단위로 분리, demo 모드 skip 가능.

**작업**
- [ ] `apps/app_user/lib/main.dart` — `appStartup()` 를 `_initSupabase()`, `_initFirebase()`, `_initStatsig()` 로 분해
- [ ] `apps/app_partner/lib/main.dart` — 위 + `_initKakao()`
- [ ] 각 함수가 demo 모드 인식 → main_demo.dart 에서는 호출 안 함
- [ ] `currentUserProvider` 단일 source audit — 여러 watcher 있어도 source provider 1개 보장

**합격 기준**
- prod 동작 동일
- demo 부팅 시 init 함수들 호출 안 됨 (단위 테스트로 검증)

**리스크**: 낮음.

---

### P4 — demo flavor 셋업 + main_demo.dart × 2 + BLUEDOC 정리 + CI demo 빌드 잡

**목표**: 빌드·실행 가능 첫 마일스톤 + CI 가 demo 깨짐 즉시 감지.

**선행 spike (P3 끝나기 전 4h timebox)**: iOS `RunnerDemo.xcscheme` 생성 검증. **Exit criteria**: `xcodebuild -scheme RunnerDemo -configuration Demo build` 성공 1회. 막히면 P4 일정 재산정.

**작업**
- [ ] `apps/app_user/android/app/build.gradle.kts` — `demo { applicationIdSuffix = ".demo"; resValue("string", "app_name", "Minglit Demo") }`
- [ ] `apps/app_partner/android/app/build.gradle.kts` — 동일
- [ ] iOS `Runner.xcodeproj` — `Demo` scheme + Build Configuration (양 앱)
- [ ] `minglit_env/demo/flutter.env` — `ENVIRONMENT=demo` 필수, Supabase URL/anon key dummy (검증 통과만 보장)
- [ ] `apps/app_user/lib/main_demo.dart` — ProviderScope.overrides 로 `demoOverrides()` 적용 (minglit_kit + app-local provider 양쪽)
- [ ] `apps/app_partner/lib/main_demo.dart` — 동일
- [ ] BLUEDOC drift 정리: `dev_main.dart` 언급 제거, `main_demo.dart` 컨벤션 문서화 (`apps/app_user/BLUEDOC.md`, `apps/app_partner/BLUEDOC.md`)
- [ ] **CI demo 빌드 잡** — `.github/workflows/pr-gate.yml` (또는 신규 jobs) 에 `flutter build apk --flavor demo` 양 앱 추가. path filter: `shared/packages/minglit_demo/**`, `apps/*/lib/main_demo.dart`, `apps/*/android/app/build.gradle.kts` 변경 시. **이 잡이 P4 이후로 미루면 그동안 broken state 무음 가능 → P4 안에 포함 (P8 에서 제외)**

**합격 기준**
- `flutter build apk --flavor demo --dart-define-from-file=minglit_env/demo/flutter.env` 양 앱 통과
- 빌드 APK 가 실 디바이스에서 부팅 → 홈 도달 (네트워크 0 호출 — Charles 확인)
- CI 잡 green

**리스크**: 중. iOS Demo scheme 첫 작업. **선행 spike** 가 timebox 안에 끝나야 P4 본 작업 진입.

---

### P5 — PoC 한 플로우 끝까지

**목표**: 시연 가능한 첫 데모. 한 플로우 (홈 → 이벤트 상세 → 신청 → 결제 → 완료) 자연 동작.

**선행 (별 PR, P4 직전 권장)**: `MinglitImage.network(...)` wrapper 도입 — `shared/packages/minglit_kit/lib/src/ui/widgets/` 신설, 사용처 일괄 치환. demo flavor 에서 placeholder asset / picsum 으로 swap. (architecture.md "5% 의 예외" 표 NetworkImage 행 참고.)

**작업**
- [ ] demo fixture 확장 — 한 플로우 필요 데이터 보강 (이벤트/파티/티켓/결제 시뮬레이션)
- [ ] 라우터 redirect 디버깅 — 데모 유저가 모든 guard 통과
- [ ] 라우터 enumerate helper — `app_routes.dart` 의 type-safe 라우트 전체 list 화 (smoke test 인프라용, C2 보강)
- [ ] smoke test 작성 — 모든 라우트 push → render 검증
- [ ] **net-negative audit**: `git log P0..P5 --stat -- ':!shared/packages/minglit_demo/'` 으로 prod 영역 diff 집계 → 흡수·삭제 ≥ 새 prod 코드 라인 확인 (C1 명세)

**합격 기준**
- 영업팀 1명 pilot — "시연 가능" 판정
- 한 플로우 끝까지 크래시 0
- **출시 게이트 10 지표 모두 green** (Success Metrics 섹션 표)

**리스크**: 중. Image wrapper 사용처 grep 결과에 따라 범위 변동.

---

### P6a — 측정 도구 보강 (선행)

**목표**: P6b 의 metric 측정이 가능하도록 도구 준비.

**작업**
- [ ] **CUJ harness flavor-aware 화** — `apps/app_user/integration_test/cuj/_engine/cuj_test.dart` 가 `--flavor demo` 인식. demoOverrides 자동 주입 옵션
- [ ] **`scripts/mds_render_coverage.dart`** 도구 도입 — `mds-emulator-render/architecture.md` Phase 2 산출물. **scope 명시**: 이 도구는 emulator-render 의 별 작업이지만, P6b 의 metric 측정에 prerequisite. 따라서 emulator-render Phase 2 의 일부로 분류하되 app_demo P6 의 선행 작업으로 추적

**합격 기준**
- `dart run scripts/mds_render_coverage.dart` 실행 → 현재 커버리지 리포트 출력
- `flutter test integration_test/cuj/ --flavor demo` 실행 가능 (pass rate 측정 가능)

**리스크**: 중. CUJ harness 의 기존 setup 패턴 / fixture 주입 방식이 flavor-aware 와 충돌할 가능성.

---

### P6b — fixture 확장 (모든 화면) + coverage 도달

**목표**: 모든 화면이 데모 부팅 후 fixture 로 채워진 상태 + 두 핵심 coverage metric 도달.

**작업**
- [ ] 화면별 누락 fixture 식별 (라우터 walk → empty/error 화면 리스트)
- [ ] fixture 보강 — emulator-render per-screen state 와 동기화
- [ ] partner 앱 fixture (`demo_settlements`, partner 권한 데이터)

**합격 기준 (성숙 마일스톤)**
- 데모 앱 모든 정상 화면이 비어있지 않은 상태로 보임
- **MDS state 커버리지 (user) ≥95%** — `mds_render_coverage.dart` 결과
- **user 앱 CUJ pass rate ≥80%** — `flutter test integration_test/cuj/ --flavor demo`

**리스크**: 점진적. 화면당 1 PR 가능.

---

### P7 — partner emulator-render + partner demo 점검

**목표**: 양 앱 균형. partner 도 user 와 같은 인프라 + coverage 도달.

**작업**
- [ ] `apps/app_partner/integration_test/mds-emulator-render/` 신설 (user 패턴 복제)
- [ ] partner-specific fixture 확장 (settlement, member, verification 심사)
- [ ] partner demo flavor 시연 시나리오 점검
- [ ] partner CUJ 테스트 flavor-aware 화

**합격 기준 (성숙 마일스톤, partner)**
- **MDS state 커버리지 (partner) ≥95%**
- **partner 앱 CUJ pass rate ≥80%** (demo flavor)
- partner demo flavor 안에서 매장 관리/정산 flow 동작

**리스크**: 낮음 (user 패턴 복제).

---

### P8 — APK 배포 동선

**목표**: 영업/마케팅 demo APK 수령 동선. (CI 빌드 잡은 P4 에서 처리됨, 여기선 배포만.)

**작업**
- [ ] `.github/workflows/build-demo-apk.yml` — manual trigger + nightly cron (PR 잡과 별개 — APK 아티팩트 산출 전용)
- [ ] APK 아티팩트 GitHub Release 또는 Firebase App Distribution (Q2 답에 따라)
- [ ] 영업/마케팅용 다운로드 동선 README 정리
- CalVer 는 prod 와 동기 — `bump-version.sh` 변경 없음 (F1 결정 결과)

**합격 기준**
- manual trigger 1번 → 양 앱 demo APK 산출
- 다운로드 동선 README 정리

**리스크**: 낮음 (기존 CI 패턴 복제).

## 리스크 정리

| 리스크 | 영향 | 완화 |
|---|---|---|
| P0 Pattern C 작업이 prod 동작 변경 | 회귀 | unit + integration test 풀 가동 |
| P1 mock 흡수 시 미묘한 fixture 차이 | 기존 test 깨짐 | 가장 풍부한 fixture 기준, 점진 통합 |
| iOS Demo scheme 설정 미숙 | P4 지연 | 사전 spike — RunnerDemo.xcscheme 사례 검색 |
| Fixture 양 증가로 패키지 비대화 | 빌드 시간 ↑ | 화면별 file 분리, lazy load |
| 영업팀이 데모 사용 안 함 | 비용 회수 X | P5 직후 1명 pilot, 피드백 후 확장 |
| `kIsDemo` flag 가 prod 코드 곳곳에 스며듦 | 코드 더러워짐 | flag 사용은 `main.dart` / `appStartup` 안에만 — 그 외 ProviderScope override 로 격리 |
| **prod 빌드 그래프에 `minglit_demo` 유출** | **prod APK 에 mock 데이터/코드 박힘 → 보안·용량 리스크** | **출시 게이트 metric (Prod 의존성 격리 / 단방향 의존) + CI grep 잡** |
| **`minglit_kit` → `minglit_demo` 역방향 의존 발생** | **dependency cycle → 빌드 깨짐 / 정신모델 붕괴** | **출시 게이트 metric + 코드 리뷰 시 의식적 확인** |
| **데모 작업이 prod 베이스를 부풀림** (new code > refactor) | **"효율적 리팩토링" 원칙 위반 → 부채 증가** | **리팩토링 효율 metric (net negative) P5 audit** |

## P0 진입 전 검증 결과 (2026-05-18)

| # | 가정 | 결과 | 후속 |
|---|---|---|---|
| B1 | `currentUserProvider` override 가능 | ✅ sync provider — `minglit_kit/lib/src/logic/providers/` 안. controller 다수가 `ref.watch` 패턴 사용 | demoOverrides 가 fake User return |
| B2 | secure storage 가 Repository 경유 | ⚠️ `secureStorage` provider 가 **`apps/app_user/lib/src/features/ticket/data/ticket_wallet_repository.dart:10`** — minglit_kit 아닌 **app-local** | demoOverrides 가 minglit_kit + app-local 양쪽 cover. main_demo.dart 가 app-local override 도 주입 |
| B3 | demo env 가 EnvKeyStore.validate 통과 | ✅ URL 정규식 없음, missing key 만 체크. `ENVIRONMENT=demo` 만 명시 | demo env 파일에 `ENVIRONMENT=demo` 포함 |
| B4 | IAMport 가 EF only | ⚠️ `minglit_iamport_v1` → `iamport_flutter ^0.10.19` (native plugin) | Repository fake 외에 결제 진입 화면에서 IAMport widget 자체 conditional render skip. P5 에서 처리 |
| B5 | OAuth signOut/signIn 처리 | ✅ AuthRepository 의 메서드 — override 가 다 가림 | 추가 작업 0 |
| B6 | `social_interaction_controller` 교체 가능 | ✅ sync 호출 (`Supabase.instance.client.auth.currentUser`), `currentUserProvider` 로 교체 가능 | P0 의 0c 진행 가능 |
| F1 | CalVer 정책 | ✅ **결정 (a)**: demo 가 prod 와 같은 버전 트랙. `bump-version.sh` 변경 0. 영업/마케팅이 "26.05.X 데모 빌드" 로 부름 | open question 닫힘 |
| F2 | minglit_lints 신규 룰 추가 | ✅ `custom_lint_builder 0.8.1` 사용 중, `lib/src/` 아래 룰 파일 추가 가능 | P0 의 0e 안전 |

**전체 판정**: P0 진입 가능. ⚠️ 2건 (B2, B4) 은 명세 보강 필요 (아래 architecture.md 에 반영됨).

## Open Questions (남은 항목)

1. **iOS Demo scheme 작업자** — Mark 직접 vs 외부 도움?
2. **데모 APK 배포 채널** — GitHub Release / Firebase App Distribution / TestFlight?
3. **P5 의 영업 pilot** — 누구를 1명 pilot 으로?
4. **P6 의 화면 우선순위** — 활동량 기반 (`mds-emulator-render/architecture.md` 의 priority next 패턴) 자동 도출 가능한지?

## 관련

- [BLUEDOC](./BLUEDOC.md) — 진입점
- [architecture.md](./architecture.md) — 설계 SSoT
- [apps/architecture.md](../../../apps/architecture.md) — Flutter 공통 아키텍처
- [shared/packages/minglit_kit/lib/src/data/architecture.md](../../../shared/packages/minglit_kit/lib/src/data/architecture.md) — Repository 패턴 SSoT
