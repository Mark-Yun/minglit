# 통합 테스트 전면 보강 — 테스트 전략 (Phase 2)

> Phase 1 산출물 (PM): `docs/qa/test-cases/app-user-smoke.md`, `app-partner-smoke.md`, `cuj-user.md`, `cuj-partner.md`
>
> 이 문서는 PM이 설계한 테스트 케이스를 **어떤 계층으로, 어떤 순서로 구현할지** 매핑한다.

---

## 1. 현재 상태 vs 목표

### 현재 (2026-04-05)

| 계층 | app_user | app_partner | 비고 |
|------|----------|-------------|------|
| Unit/Widget 테스트 | 78 파일 | 59 파일 | 개별 화면/로직 단위 |
| Golden 테스트 | 40 파일 | 91 파일 | Alchemist 기반 시각적 회귀 |
| Integration 테스트 (Mock) | 2 파일 | 0 파일 | `apple_sign_in`, `party_browse` |
| E2E 테스트 (실물 디바이스) | 0 | 0 | 없음 |

### PM 케이스 총량

| 구분 | app_user | app_partner | 합계 |
|------|----------|-------------|------|
| Smoke (화면 진입) | 18 화면 / 68 케이스 | 30 화면 / 98 케이스 | 166 |
| CUJ (핵심 여정) | 8 여정 / 42 스텝 / 10 변형 | 7 여정 / 51 스텝 / 9 변형 | 93 스텝 + 19 변형 |

### 목표 (Phase 3 구현 후)

| 계층 | 목표 | 근거 |
|------|------|------|
| Smoke (Widget) | 전 화면 48건 (18 + 30) | 크래시 없이 렌더링 보장 |
| CUJ Integration (Mock) | P0 7건 + P1 5건 = 12건 | 핵심 비즈니스 플로우 회귀 방지 |
| 리다이렉트/가드 | 12건 (5 user + 7 partner) | 인증 상태별 라우팅 정확성 |
| E2E (실물 디바이스) | 2~3건 | 결제/체크인 등 네이티브 연동 |

---

## 2. 테스트 계층 매핑

### 매핑 원칙

| PM 케이스 유형 | 테스트 계층 | 이유 |
|---------------|-----------|------|
| 화면 진입 Smoke | **Widget Test** | Mock Provider로 화면 렌더링만 검증. 빠르고 안정적 |
| 리다이렉트 검증 | **Widget Test** (Router) | GoRouter 설정 + Guard 로직을 단위 테스트로 검증 |
| 파라미터 엣지 케이스 | **Widget Test** | 에러 화면/빈 상태 렌더링 검증 |
| 화면별 액션 매트릭스 | **Widget Test** (대부분) / **Integration** (다화면 연동) | 단일 화면 내 액션은 Widget, 화면 전환은 Integration |
| CUJ P0 (결제/매칭/정산) | **Integration Test** (Mock) | 다화면 플로우. Mock으로 전체 여정 시뮬레이션 |
| CUJ P0 (결제 실제 PG) | **E2E Test** (실물 디바이스) | PG SDK 네이티브 연동은 Mock 불가 |
| CUJ P1 (검색/계정삭제) | **Integration Test** (Mock) | 다화면 플로우 |
| CUJ P2 (알림/차단) | **Widget Test** | 단순 CRUD, Integration 불필요 |

---

## 3. 우선순위별 구현 계획

### 🔴 P0 — 핵심 수익/비즈니스 경로 (1단계)

실패 시 서비스 가치 없음. **반드시 먼저 구현.**

#### Integration Tests (Mock 기반)

| ID | CUJ | 테스트 파일 | 스텝 | 검증 포인트 |
|----|-----|-----------|------|------------|
| IT-U01 | 회원가입→결제→신청 | `app_user/test/integration/cuj_signup_to_apply_test.dart` | 8 | 로그인 리다이렉트 복귀, 위저드 스텝 진행, Mock PG 결과 처리 |
| IT-U02 | 체크인→매칭투표→결과 | `app_user/test/integration/cuj_checkin_matching_test.dart` | 8 | QR 표시, 투표 UI 인터랙션, 매칭 결과 화면 |
| IT-U03 | 환불 신청 | `app_user/test/integration/cuj_refund_test.dart` | 5 | 환불 정책 검증, 상태 변경 |
| IT-P01 | 파트너가입→파티→이벤트 | `app_partner/test/integration/cuj_onboarding_to_event_test.dart` | 20 | 온보딩 위저드 전체 플로우, 파티 생성, 이벤트+티켓 |
| IT-P02 | 신청 심사 (승인/거절) | `app_partner/test/integration/cuj_application_review_test.dart` | 6 | 승인/거절 상태 전환, 동시 처리 방지 |
| IT-P03 | 체크인 관리 | `app_partner/test/integration/cuj_checkin_manage_test.dart` | 4 | QR 스캔 결과 처리, 중복 체크인 |
| IT-P04 | 정산 확인+계좌 | `app_partner/test/integration/cuj_settlement_test.dart` | 6 | 정산 내역, 계좌 CRUD |

**총 7건, 57 스텝**

#### Smoke Widget Tests (P0 화면)

| 화면 | 테스트 파일 | 케이스 수 |
|------|-----------|----------|
| 이벤트 신청 위저드 | `app_user/test/src/features/event/ui/event_application_wizard_smoke_test.dart` | 6 |
| 구매 내역 | `app_user/test/src/features/purchase/ui/purchase_history_smoke_test.dart` | 3 |
| 파트너 신청 위저드 | `app_partner/test/src/features/onboarding/ui/partner_apply_smoke_test.dart` | 5 |
| 파티 생성 위저드 | `app_partner/test/src/features/party/ui/party_create_wizard_smoke_test.dart` | 8 |
| 신청 관리 | `app_partner/test/src/features/application/ui/application_manage_smoke_test.dart` | 3 |
| 정산 | `app_partner/test/src/features/settlement/ui/settlement_smoke_test.dart` | 4 |
| 체크인 | `app_partner/test/src/features/checkin/ui/checkin_smoke_test.dart` | 2 |

**총 31건**

---

### 🟡 P1 — 필수 사용자 경험 (2단계)

실패 시 유저 이탈. P0 완료 후 구현.

#### Integration Tests

| ID | CUJ | 테스트 파일 | 스텝 |
|----|-----|-----------|------|
| IT-U04 | 검색→필터→신청 | `app_user/test/integration/cuj_search_to_apply_test.dart` | 5 |
| IT-U05 | 계정 삭제 | `app_user/test/integration/cuj_account_deletion_test.dart` | 5 |
| IT-U06 | 큐레이션→파트너→이벤트 | `app_user/test/integration/cuj_curation_browse_test.dart` | 5 |
| IT-P05 | 파티/이벤트/티켓 편집 | `app_partner/test/integration/cuj_party_edit_test.dart` | 8 |

**총 4건, 23 스텝**

#### Smoke Widget Tests (P1 화면)

| 화면 | 테스트 파일 | 케이스 수 |
|------|-----------|----------|
| 검색 | `app_user/test/src/features/search/ui/search_page_smoke_test.dart` | 4 |
| 마이페이지 | `app_user/test/src/features/my/ui/my_page_smoke_test.dart` | 5 |
| 개인정보 설정 | `app_user/test/src/features/settings/ui/privacy_page_smoke_test.dart` | 2 |
| 파티 상세 | `app_partner/test/src/features/party/ui/party_detail_smoke_test.dart` | 5 |
| 이벤트 생성 | `app_partner/test/src/features/event/ui/event_create_smoke_test.dart` | 2 |

**총 18건**

#### 리다이렉트/가드 테스트

| 앱 | 테스트 파일 | 케이스 수 |
|----|-----------|----------|
| app_user | `app_user/test/src/routing/auth_guard_test.dart` | 5 (U-R01~R05) |
| app_partner | `app_partner/test/src/routing/onboarding_guard_test.dart` | 7 (P-R01~R07) |

**총 12건**

---

### 🟢 P2 — 전체 커버리지 확보 (3단계)

서비스 운영에 불편하지만 가능. P1 완료 후 점진적 구현.

#### Smoke Widget Tests (나머지 화면)

| 앱 | 대상 화면 수 | 예상 케이스 |
|----|------------|-----------|
| app_user | 7 (홈, 큐레이션, 이벤트상세, 파트너상세, 알림, 차단, 알림설정) | 25 |
| app_partner | 13 (홈, 멤버, 권한, 인증, 알림, 이벤트상세, 티켓편집 등) | 40 |

**총 65건**

#### CUJ P2 (Widget Test로 충분)

| ID | CUJ | 테스트 파일 |
|----|-----|-----------|
| WT-U07 | 알림 기반 재방문 | `app_user/test/src/features/notification/ui/notification_deeplink_test.dart` |
| WT-U08 | 파트너 차단/해제 | `app_user/test/src/features/block/ui/block_partner_test.dart` |
| WT-P06 | 멤버 관리+권한 | `app_partner/test/src/features/member/ui/member_permission_test.dart` |
| WT-P07 | 인증 관리 | `app_partner/test/src/features/verification/ui/verification_manage_test.dart` |

**총 4건**

#### 엣지 케이스 (파라미터 검증)

| 앱 | 케이스 수 | 범위 |
|----|----------|------|
| app_user | 7 (U-E01~E07) | 존재하지 않는 ID, 빈 목록 등 |
| app_partner | 9 (P-E01~E09) | 존재하지 않는 ID, 빈 상태 등 |

기존 Widget Test에 추가 케이스로 통합. 별도 파일 불필요.

---

## 4. 변형 시나리오 처리

PM이 정의한 변형 시나리오(19건)는 해당 CUJ Integration Test 내 `group()`으로 포함한다.

| CUJ | 변형 | 처리 방식 |
|-----|------|----------|
| U01-V1: 기존 유저 재구매 | IT-U01 내 별도 test | 스텝 자동 스킵 검증 |
| U01-V2: 결제 중 앱 종료 | **P3 (선택)** — 앱 생명주기 테스트는 E2E에서만 가능 |
| U01-V3: 무료 이벤트 | IT-U01 내 별도 test | 결제 스킵 검증 |
| U02-V1: 투표 시간 초과 | IT-U02 내 별도 test | 타이머 Mock |
| U02-V2: 체크인 없이 매칭 | IT-U02 내 별도 test | 접근 차단 검증 |
| U03-V1~V3: 환불 변형 | IT-U03 내 group | 부분환불, 당일환불, 무료취소 |
| P01-V1: 심사 보완 | IT-P01 내 별도 test | `needsCorrection` 상태 |
| P01-V2: 무료 이벤트 | IT-P01 내 별도 test | |
| P01-V3: 위저드 이탈 | **P3** — 앱 종료 시나리오 |
| P02-V1~V2: 심사 변형 | IT-P02 내 group | 정원 초과, 일괄 승인 |
| P03-V1~V2: 체크인 변형 | IT-P03 내 group | 카메라 거부, 오프라인 |
| P05-V1~V2: 편집 변형 | IT-P05 내 group | 진행중 이벤트, 티켓 템플릿 |

---

## 5. 테스트 인프라 보강

### 5.1 Integration Test 헬퍼 (신규)

현재 Integration Test 인프라가 거의 없다 (app_user 2개, app_partner 0개). 공통 헬퍼가 필요하다.

**필요한 유틸리티:**

| 파일 | 용도 |
|------|------|
| `apps/{app}/test/integration/utils/pump_app.dart` | 테스트용 앱 빌드 (ProviderScope + GoRouter + 필요한 Override) |
| `apps/{app}/test/integration/utils/cuj_helpers.dart` | 로그인/온보딩 등 반복 스텝 헬퍼 |
| `apps/{app}/test/integration/utils/mock_providers.dart` | CUJ별 Mock Provider 설정 |

**`pumpApp()` 설계:**
```dart
Future<void> pumpApp(
  WidgetTester tester, {
  required String initialRoute,
  required List<Override> overrides,
  AuthState authState = AuthState.guest,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(authState),
        ...overrides,
      ],
      child: MaterialApp.router(
        routerConfig: createTestRouter(initialRoute: initialRoute),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

### 5.2 CI 변경 사항

현재 CI(`ci.yml`)는 app_user의 `test/integration/`만 실행한다. 변경 필요:

| 변경 | 내용 |
|------|------|
| app_partner integration | `flutter test test/integration/` 추가 (app_partner에도) |
| 테스트 태그 | Integration Test에 `@Tags(['integration'])` 적용 — 필요시 분리 실행 |

---

## 6. E2E 테스트 (실물 디바이스) 계획

P0 CUJ 중 네이티브 SDK 연동이 필요한 2건은 E2E로만 검증 가능하다:

| 시나리오 | 이유 |
|----------|------|
| 실제 PG 결제 (Iamport) | 네이티브 WebView + PG SDK 연동 |
| QR 코드 스캔 (카메라) | 디바이스 카메라 API |

**방향:**
- 기존 `integration_test/` 디렉토리 활용 (Flutter integration_test driver)
- Dev 환경 PG 테스트 모드 사용
- CI에서는 실행하지 않음 (수동 디바이스 테스트)
- 상세 계획은 Phase 3에서 SWE와 협의

---

## 7. 갭 정량 요약

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

## 8. 실행 순서 요약

| 단계 | 내용 | 예상 테스트 수 | 우선순위 |
|------|------|-------------|---------|
| **1단계** | P0 CUJ Integration (7건) + P0 Smoke (31건) + 인프라 헬퍼 | 38 | 🔴 필수 |
| **2단계** | P1 CUJ Integration (4건) + P1 Smoke (18건) + 가드 (12건) | 34 | 🟡 권장 |
| **3단계** | P2 Smoke (65건) + P2 Widget (4건) + 엣지케이스 (16건) | 85 | 🟢 선택 |
| **E2E** | 실물 디바이스 결제/체크인 (2~3건) | 3 | Phase 3 협의 |
| **합계** | | **160건** | |

---

## 9. automation-test-guide.md 업데이트 계획

Phase 3 (SWE 구현) 시 아래 섹션을 업데이트한다:

| 섹션 | 변경 내용 |
|------|----------|
| §1 커버리지 현황 | Integration 수 업데이트, Smoke 수 추가 |
| §2 계층별 규칙 | Integration Test 패턴 추가 (`pumpApp`, CUJ 헬퍼) |
| §3 체크리스트 | Smoke Test를 "권장"에서 "필수"로 격상 (새 화면 추가 시) |
| §6 실행 명령어 | `flutter test test/integration/ --tags integration` 추가 |
| §8 CI 연동 | app_partner integration 실행 추가 |

---

## 부록: PM 케이스 → 테스트 계층 전수 매핑

### app_user Smoke (U-S01 ~ U-S18)

| ID | 화면 | 계층 | 기존 테스트 여부 | 비고 |
|----|------|------|----------------|------|
| U-S01 | 홈 | Widget | ✅ (golden 있음) | smoke 추가 불필요 |
| U-S02 | 큐레이션 | Widget | ❌ | 신규 |
| U-S03 | 검색 | Widget | ✅ (golden 있음) | smoke 추가 불필요 |
| U-S04 | 이벤트 상세 | Widget | ✅ (golden 있음) | smoke 추가 불필요 |
| U-S05 | 파트너 상세 | Widget | ❌ | 신규 |
| U-S06 | 파트너 이벤트 목록 | Widget | ❌ | 신규 |
| U-S07 | 로그인 | Widget | ✅ (golden 있음) | smoke 추가 불필요 |
| U-S08 | OAuth 콜백 | Widget | ❌ | 신규 |
| U-S09 | 마이페이지 | Widget | ✅ (golden 있음) | smoke 추가 불필요 |
| U-S10 | 개인정보 설정 | Widget | ❌ | 신규 |
| U-S11 | 차단 파트너 관리 | Widget | ✅ (golden 있음) | smoke 추가 불필요 |
| U-S12 | 알림 설정 | Widget | ❌ | 신규 |
| U-S13 | 구매 내역 | Widget | ❌ | 신규 — P0 |
| U-S14 | 알림 센터 | Widget | ❌ | 신규 |
| U-S15 | 본인인증 | Widget | ❌ | 신규 |
| U-S16 | 신청 위저드 | Widget | ✅ (golden 있음) | smoke 추가 불필요 |
| U-S17 | 개발 도구 | Widget | ❌ | P3 — dev only |
| U-S18 | 유저 전환 | Widget | ❌ | P3 — dev only |

**신규 Smoke 필요: 9건** (golden 기존 커버 제외, dev only 제외)

### app_partner Smoke (P-S01 ~ P-S30)

| ID | 화면 | 계층 | 기존 테스트 여부 | 비고 |
|----|------|------|----------------|------|
| P-S01 | 로그인 | Widget | ✅ (golden) | smoke 불필요 |
| P-S02 | 웰컴 | Widget | ❌ | 신규 |
| P-S03 | 파트너 신청 | Widget | ✅ (golden) | smoke 불필요 |
| P-S04 | 신청 상태 | Widget | ✅ (golden) | smoke 불필요 |
| P-S05 | 홈 | Widget | ✅ (golden) | smoke 불필요 |
| P-S06 | 장소 가이드 | Widget | ❌ | 신규 |
| P-S07 | 신청 관리 | Widget | ❌ | 신규 — P0 |
| P-S08 | 신청 상세 | Widget | ❌ | 신규 — P0 |
| P-S09 | 체크인 | Widget | ❌ | 신규 — P0 |
| P-S10 | 정산 | Widget | ✅ (golden) | smoke 불필요 |
| P-S11 | 계좌 관리 | Widget | ❌ | 신규 — P0 |
| P-S12 | 정산 상세 | Widget | ❌ | 신규 |
| P-S13 | 더보기 | Widget | ✅ (golden) | smoke 불필요 |
| P-S14 | 파티 목록 | Widget | ✅ (golden) | smoke 불필요 |
| P-S15 | 파티 생성 | Widget | ✅ (golden) | smoke 불필요 |
| P-S16 | 파티 상세 | Widget | ❌ | 신규 |
| P-S17 | 파티 편집 | Widget | ❌ | 신규 |
| P-S18 | 파티 티켓 편집 | Widget | ❌ | 신규 |
| P-S19 | 이벤트 생성 | Widget | ❌ | 신규 |
| P-S20 | 이벤트 상세 | Widget | ✅ (golden) | smoke 불필요 |
| P-S21 | 티켓 생성 | Widget | ❌ | 신규 |
| P-S22 | 티켓 편집 | Widget | ❌ | 신규 |
| P-S23 | 인증 관리 | Widget | ✅ (golden) | smoke 불필요 |
| P-S24 | 인증 생성 | Widget | ✅ (golden) | smoke 불필요 |
| P-S25 | 알림 설정 | Widget | ❌ | 신규 |
| P-S26 | 멤버 목록 | Widget | ❌ | 신규 |
| P-S27 | 멤버 권한 | Widget | ❌ | 신규 |
| P-S28 | 알림 센터 | Widget | ❌ | 신규 |
| P-S29 | 개발 도구 | Widget | ❌ | P3 — dev only |
| P-S30 | 유저 전환 | Widget | ❌ | P3 — dev only |

**신규 Smoke 필요: 18건** (golden 기존 커버 제외, dev only 제외)
