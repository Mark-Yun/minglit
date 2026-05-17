# Integration 테스트 스텝별 스크린샷 캡처 포인트 정의

> 관련: #1458 (Patrol 통합 + 스크린샷 내장), #1557 (인프라 재가동 전면 점검)
>
> 목적: 기존 37개 integration 테스트 + 3개 patrol 테스트에 스텝별 스크린샷을 내장할 때,
> 각 테스트의 어느 시점에 어떤 이름으로 캡처할지 정의한다.
>
> SWE는 이 문서를 보고 `GoldenCapture` 또는 Patrol `$.native.screenshot()` 호출을 삽입한다.

---

## 현재 상태 (2026-04-18 기준) — 실제 구현 vs 계획 갭

> 이 문서(캡처 포인트 매핑)는 머지됐지만 **실제 CI 실행 0건**. 아래는 전수 조사 결과이며, 재가동 작업은 이슈 #1557에서 추적한다.

### 파이프라인 단절 지점

| 단계 | 계획 | 실제 상태 (2026-04-18) | 차단 원인 |
|------|------|---------------------|----------|
| 1. 테스트 코드 내 캡처 호출 | 각 CUJ 테스트에 `takeScreenshot()` / `matchesGoldenFile()` 삽입 | `tester.capture()` / `GoldenCapture` 호출 존재 (app_user 62건 이상) — 포인트 매핑 기준 부분 구현 | 전 CUJ/flow 파일에 고르게 분포하지 않음. 본 문서 기준 완전 삽입은 Phase D 작업 |
| 2. `GoldenCapture` 유틸 실행 | CI headless 환경에서 동작 | **런타임 skip** (PR #1539) | headless hang 방지를 위한 임시 조치 — 대체 구현 미완 |
| 3. CUJ 테스트 실행 경로 | `apps/app_user/test/integration/` 순회 | `run-client-cuj.sh` / `run-partner-cuj.sh` 모두 `test/integration/*_test.dart` 순회 — **경로 수정 완료** (#1557) | 차단 없음 |
| 4. 상위 파이프라인 (`client-cuj-test`, `partner-cuj-test` job) | 매일 실행 | **skip 지속** | `needs: seed-and-simulate` 의존 — #1553 (CLOSED) / PR #1556 (MERGED 2026-04-18) 으로 선결 해소. 재가동 확인 필요 |
| 5. Patrol E2E (`monitor-patrol-e2e.yml`) | weekly cron | **run 이력 0건** | 한 번도 trigger되지 않음. 수동 실행도 없음 |
| 6. 아티팩트 업로드 | 생성된 png 보존 | `monitor-patrol-e2e.yml:66`은 `if: failure()` + build outputs만 업로드 (스크린샷 아님). `pr-gate.yml`은 golden 실패 / coverage / allure만 업로드 | Tier B 용 retention 경로 미구축 |

### 3-Tier 스크린샷 아키텍처

본 문서가 속한 **Tier B** (시나리오 스크린샷) 의 위치를 명확히 한다. 전체 전략은 `docs/qa/test-strategy.md` 의 "스크린샷 3-Tier 아키텍처" 섹션이 SSOT.

> **용어 주의**: 아래 "Tier" 는 7-layer taxonomy 의 "Layer" 와 다른 차원이다.
> - **Tier**: 스크린샷 자산의 성격 구분 (A=픽셀비교 / B=증거사진 / C=AI리뷰)
> - **Layer**: 테스트 계층 taxonomy (1-7) — `docs/qa/test-strategy.md §2`
>
> 연결: Tier A = 7-layer Layer 2b (Alchemist golden), Tier B = 7-layer Layer 3 (Patrol emulator) 내부 자산, Tier C = Layer 3 output 을 소비하는 후속 AI pipeline.

```
[Tier A] 골든 스크린샷 테스트 (7-layer Layer 2b, 기존 유지)
  - Alchemist 기반 widget 단위 golden (app_user 14 / app_partner 15 — 2026-04-18)
  - 픽셀 레벨 회귀 차단
  - 경로: apps/*/test/alchemist/**/*_golden_test.dart (`minglit_kit`: test/goldens/)

         ▲
         │
[Tier B] 시나리오 스크린샷 (7-layer Layer 3 내부, 본 문서 = 캡처 포인트 매핑)
  - Patrol CUJ 테스트의 스텝별 실제 플로우 스냅샷
  - 목적: "현재 실제 화면"의 시각적 로그 (픽셀 비교 아님)
  - 대상 경로: apps/app_*/emulator_test/
  - 저장: artifact retention 14d 이상 (Tier C agent 가 pull 할 수 있어야 함)

         ▲
         │
[Tier C] AI agent 스크린샷 리뷰 (후속 구현)
  - 매일 저장된 Tier B 스크린샷을 agent 가 전수 리뷰
  - 감지 대상: 깨진 이미지, 누락된 라벨, 레이아웃 오류, 품질 저하
  - 출력: bug-report 이슈 자동 생성
```

### Tier B 의 의미 재정의 (2026-04-18, 이슈 #1557 기반)

- **캡처는 "비교"가 아니라 "증거 사진"** — Tier C AI agent 의 semantic 리뷰 입력용.
- 따라서 아티팩트 저장 요구사항이 Tier A (골든 픽셀 비교) 와 다름:
  - ❌ PR 실패 시에만 업로드 (현재 `monitor-patrol-e2e.yml:66` 패턴)
  - ✅ **매일 성공 run 에서도 전량 저장**, retention 14 일 이상, Tier C agent 가 접근 가능한 경로
- 따라서 이 문서의 매핑은 "픽셀 고정"이 아니라 **"뭘 촬영할지"** 를 정의하는 쇼트 리스트로 해석.

### 시나리오 스크린샷이 죽어있는 동안 놓친 버그 (샘플)

- #1538 — CUJ-P01 파티 생성 위저드 FlutterQuill localization 에러. `cuj_event_create_wizard_test.dart` 가 동작했으면 Tier B 에서 포착 가능.
- #1540 — Home/EventDetail broken image. `cuj_event_detail_test.dart` / flow 테스트 범위.

### 경로 구분 (혼동 방지)

| 경로 | 역할 | Tier | 7-layer |
|------|------|------|---------|
| `apps/app_user/test/integration/` | Flutter 위젯 플로우 (mock 기반) — 향후 Patrol 이관 대상 (#1586 Phase D-2) | **Tier B 이관 대상** | Layer 2a |
| `apps/app_partner/test/integration/` | 동일 | **Tier B 이관 대상** | Layer 2a |
| `apps/app_*/emulator_test/` | Patrol 네이티브 테스트 — native surface 특수 테스트 | **Tier B 생성 위치** | Layer 3 |
| `apps/*/test/alchemist/` (`minglit_kit`: `test/goldens/`) | 픽셀 레벨 widget 골든 | Tier A | Layer 2b |
| `tests/client_cuj_integration/` | 삭제됨 (#1564) | — | — |
| (미정) `apps/app_*/emulator_test/screenshots/` | Tier B artifact 저장 경로 후보 | Tier B 저장 | Layer 3 output |

### 재가동 선결 의존성

- **#1553** — CLOSED (2026-04-18).
- **PR #1556** — MERGED (2026-04-18 04:44:53Z). Supabase pooler `aws-0 → aws-1` fix 완료.
- 선결 차단 해소됨. `seed-and-simulate` 재가동 확인 후 이 문서 기반 캡처 포인트 삽입 검증 가능.

---

## 네이밍 규칙

```
{test_id}_step{N}_{phase}.png
```

| 요소 | 설명 | 예시 |
|------|------|------|
| `test_id` | 테스트 파일의 고유 ID (아래 매핑 참고) | `cuj_u01`, `flow_u_search` |
| `N` | 스텝 번호 (0부터) | `0`, `1`, `2` |
| `phase` | 캡처 시점 | `setup`, `before`, `after`, `error` |

### phase 정의

| phase | 언제 캡처하는가 | 용도 |
|-------|---------------|------|
| `setup` | 테스트 앱 pumpWidget 직후, 첫 액션 전 | 초기 상태 (로딩, 리다이렉트 결과) 확인 |
| `before` | 사용자 액션(tap, input) 직전 | 액션 대상이 화면에 있는지 확인 |
| `after` | 사용자 액션 후 pumpAndSettle 완료 | 액션 결과 확인 |
| `error` | 에러 상태 유발 후 | 에러 UI가 정상 렌더링되는지 확인 |

---

## 캡처 포인트 밀도 기준

모든 testWidgets에 무조건 캡처를 넣지 않는다. 아래 기준으로 선별:

| 기준 | 캡처 여부 | 이유 |
|------|----------|------|
| 화면 전환이 있는 테스트 | **캡처** | 전환 전후 시각적 확인 |
| 단순 리다이렉트 검증 (expect만) | **setup 1장** | 리다이렉트 목적지 확인 |
| 위저드 스텝 진행 | **스텝마다 캡처** | 각 스텝의 UI 상태 |
| 에러/엣지 케이스 | **error 1장** | 에러 UI 확인 |
| 데이터 로드 후 목록 표시 | **after 1장** | 렌더링 결과 확인 |

---

## app_user CUJ 테스트 (12 files)

### cuj_signup_to_apply_test.dart — `cuj_u01` (8 tests, ~8 captures)

> 이미 `tester.capture()` 적용됨. Patrol 전환 시 네이밍만 통일.

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 비로그인 → 리다이렉트 | `cuj_u01_step0_setup` | setup |
| 로그인 페이지 (from 파라미터) | `cuj_u01_step1_setup` | setup |
| 위저드 접근 | `cuj_u01_step2_after` | after |
| 위저드 진행 바 | `cuj_u01_step3_after` | after |
| 무료 이벤트 위저드 | `cuj_u01_step4_after` | after |
| 에러 상태 | `cuj_u01_step5_error` | error |
| 제출 중 상태 | `cuj_u01_step6_after` | after |
| 성공 상태 | `cuj_u01_step7_after` | after |

### cuj_checkin_matching_test.dart — `cuj_u02` (8 tests, ~5 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 비로그인 → 티켓 목록 차단 | `cuj_u02_step0_setup` | setup |
| 로그인 → 티켓 목록 접근 | `cuj_u02_step1_after` | after |
| QR 화면 렌더링 | `cuj_u02_step2_after` | after |
| 투표 화면 | `cuj_u02_step3_after` | after |
| 매칭 결과 화면 | `cuj_u02_step4_after` | after |

### cuj_refund_test.dart — `cuj_u03` (5 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 환불 신청 화면 | `cuj_u03_step0_setup` | setup |
| 환불 정책 표시 | `cuj_u03_step1_after` | after |
| 환불 확인 다이얼로그 | `cuj_u03_step2_before` | before |
| 환불 완료 상태 | `cuj_u03_step3_after` | after |

### cuj_event_application_test.dart — `cuj_u04` (1 test, ~1 capture)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 신청 위저드 전체 플로우 | `cuj_u04_step0_after` | after |

### cuj_event_detail_test.dart — `cuj_u05` (1 test, ~1 capture)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 이벤트 상세 렌더링 | `cuj_u05_step0_setup` | setup |

### cuj_account_deletion_test.dart — `cuj_u06` (12 tests, ~6 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 삭제 확인 화면 | `cuj_u06_step0_setup` | setup |
| 유예 기간 안내 | `cuj_u06_step1_after` | after |
| 삭제 확인 다이얼로그 | `cuj_u06_step2_before` | before |
| 삭제 처리 완료 | `cuj_u06_step3_after` | after |
| 복구 다이얼로그 | `cuj_u06_step4_after` | after |
| 에러 상태 | `cuj_u06_step5_error` | error |

### cuj_matching_vote_test.dart — `cuj_u07` (9 tests, ~5 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 투표 화면 렌더링 | `cuj_u07_step0_setup` | setup |
| 투표 선택 UI | `cuj_u07_step1_before` | before |
| 투표 제출 후 | `cuj_u07_step2_after` | after |
| 결과 화면 | `cuj_u07_step3_after` | after |
| 타임아웃 상태 | `cuj_u07_step4_error` | error |

### cuj_identity_verification_test.dart — `cuj_u08` (4 tests, ~3 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 인증 화면 | `cuj_u08_step0_setup` | setup |
| 인증 진행 중 | `cuj_u08_step1_after` | after |
| 인증 완료 | `cuj_u08_step2_after` | after |

### cuj_event_now_bar_test.dart — `cuj_u09` (15 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 나우바 표시 (진행 중 이벤트) | `cuj_u09_step0_setup` | setup |
| 나우바 탭 → 이벤트 상세 | `cuj_u09_step1_after` | after |
| 나우바 미표시 (이벤트 없음) | `cuj_u09_step2_setup` | setup |
| 나우바 카운트다운 | `cuj_u09_step3_after` | after |

### cuj_ticket_qr_test.dart — `cuj_u10` (3 tests, ~2 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| QR 코드 렌더링 | `cuj_u10_step0_after` | after |
| QR 새로고침 | `cuj_u10_step1_after` | after |

### cuj_notification_test.dart — `cuj_u11` (1 test, ~1 capture)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 알림 목록 렌더링 | `cuj_u11_step0_setup` | setup |

### cuj_tag_discovery_test.dart — `cuj_u12` (2 tests, ~2 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 태그 검색 UI | `cuj_u12_step0_setup` | setup |
| 태그 선택 결과 | `cuj_u12_step1_after` | after |

---

## app_user Flow 테스트 (7 files)

### flow_event_browse_test.dart — `flow_u_browse` (10 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 홈 피드 렌더링 | `flow_u_browse_step0_setup` | setup |
| 이벤트 카드 탭 → 상세 | `flow_u_browse_step1_after` | after |
| 카테고리 필터 | `flow_u_browse_step2_after` | after |
| 빈 상태 | `flow_u_browse_step3_setup` | setup |

### flow_search_test.dart — `flow_u_search` (7 tests, ~3 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 검색 화면 초기 | `flow_u_search_step0_setup` | setup |
| 검색 결과 표시 | `flow_u_search_step1_after` | after |
| 검색 결과 없음 | `flow_u_search_step2_after` | after |

### flow_my_page_test.dart — `flow_u_mypage` (12 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 마이페이지 렌더링 | `flow_u_mypage_step0_setup` | setup |
| 구매 내역 | `flow_u_mypage_step1_after` | after |
| 개인정보 설정 | `flow_u_mypage_step2_after` | after |
| 비로그인 상태 | `flow_u_mypage_step3_setup` | setup |

### flow_ticket_application_test.dart — `flow_u_ticket` (10 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 신청 목록 | `flow_u_ticket_step0_setup` | setup |
| 신청 상세 | `flow_u_ticket_step1_after` | after |
| 결제 진행 | `flow_u_ticket_step2_after` | after |
| 에러 상태 | `flow_u_ticket_step3_error` | error |

### flow_admission_status_test.dart — `flow_u_admission` (13 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 입장 상태 화면 | `flow_u_admission_step0_setup` | setup |
| 체크인 완료 상태 | `flow_u_admission_step1_after` | after |
| 대기 상태 | `flow_u_admission_step2_after` | after |
| 거절 상태 | `flow_u_admission_step3_after` | after |

### flow_notification_routing_test.dart — `flow_u_noti` (10 tests, ~3 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 알림 목록 | `flow_u_noti_step0_setup` | setup |
| 알림 탭 → 딥링크 이동 | `flow_u_noti_step1_after` | after |
| 빈 알림 상태 | `flow_u_noti_step2_setup` | setup |

### flow_error_edge_cases_test.dart — `flow_u_error` (10 tests, ~3 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 네트워크 에러 화면 | `flow_u_error_step0_error` | error |
| 404 화면 | `flow_u_error_step1_error` | error |
| 재시도 후 복구 | `flow_u_error_step2_after` | after |

---

## app_user 기타 테스트 (6 files)

### auth_redirect_test.dart — `redirect_u_auth` (8 tests, ~3 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| GUEST → /login 리다이렉트 | `redirect_u_auth_step0_setup` | setup |
| AUTH → 보호 페이지 접근 | `redirect_u_auth_step1_setup` | setup |
| VERIFIED → 모든 페이지 접근 | `redirect_u_auth_step2_setup` | setup |

### consent_redirect_test.dart — `redirect_u_consent` (8 tests, ~2 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 약관 미동의 → 동의 화면 | `redirect_u_consent_step0_setup` | setup |
| 약관 동의 완료 → 원래 페이지 | `redirect_u_consent_step1_after` | after |

### home_navigation_test.dart — `nav_u_home` (5 tests, ~3 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 홈 탭 초기 | `nav_u_home_step0_setup` | setup |
| 탭 전환 | `nav_u_home_step1_after` | after |
| 딥링크 → 탭 복귀 | `nav_u_home_step2_after` | after |

### login_page_test.dart — `login_u` (3 tests, ~2 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 로그인 페이지 렌더링 | `login_u_step0_setup` | setup |
| 소셜 로그인 버튼 | `login_u_step1_before` | before |

### my_page_test.dart — `my_u` (3 tests, ~2 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 마이페이지 렌더링 | `my_u_step0_setup` | setup |
| 메뉴 항목 표시 | `my_u_step1_after` | after |

### smoke_test.dart / edge_cases_test.dart — 캡처 불필요

> Smoke: 전 화면 크래시 없이 렌더링만 검증 → 각 integration 테스트 내 스텝별 스크린샷으로 커버
> Edge cases: 파라미터 검증 → 캡처 가치 낮음

---

## app_partner CUJ 테스트 (10 files)

### cuj_onboarding_to_event_test.dart — `cuj_p01` (8 tests, ~8 captures)

> 이미 `tester.capture()` 적용됨. Patrol 전환 시 네이밍 통일.

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 비로그인 → 리다이렉트 | `cuj_p01_step0_setup` | setup |
| needsApplication → /welcome | `cuj_p01_step1_setup` | setup |
| draftInProgress → /apply | `cuj_p01_step2_setup` | setup |
| pendingReview → /apply/status | `cuj_p01_step3_setup` | setup |
| needsCorrection → /apply/status | `cuj_p01_step4_setup` | setup |
| hasPartner → 홈 | `cuj_p01_step5_setup` | setup |
| 파티 목록 접근 | `cuj_p01_step6_after` | after |
| 등록 완료 → /apply 리다이렉트 | `cuj_p01_step7_setup` | setup |

### cuj_application_review_test.dart — `cuj_p02` (6 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 신청 목록 화면 | `cuj_p02_step0_setup` | setup |
| 신청 상세 | `cuj_p02_step1_after` | after |
| 승인 처리 | `cuj_p02_step2_after` | after |
| 거절 처리 | `cuj_p02_step3_after` | after |

### cuj_application_action_test.dart — `cuj_p02a` (7 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 승인 버튼 탭 전 | `cuj_p02a_step0_before` | before |
| 승인 완료 | `cuj_p02a_step1_after` | after |
| 거절 확인 다이얼로그 | `cuj_p02a_step2_before` | before |
| 거절 완료 | `cuj_p02a_step3_after` | after |

### cuj_checkin_manage_test.dart — `cuj_p03` (4 tests, ~3 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 체크인 화면 | `cuj_p03_step0_setup` | setup |
| QR 스캔 결과 | `cuj_p03_step1_after` | after |
| 중복 체크인 에러 | `cuj_p03_step2_error` | error |

### cuj_checkin_qr_test.dart — `cuj_p03a` (9 tests, ~3 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| QR 스캐너 화면 | `cuj_p03a_step0_setup` | setup |
| 스캔 성공 | `cuj_p03a_step1_after` | after |
| 유효하지 않은 QR | `cuj_p03a_step2_error` | error |

### cuj_settlement_test.dart — `cuj_p04` (6 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 정산 목록 | `cuj_p04_step0_setup` | setup |
| 정산 상세 | `cuj_p04_step1_after` | after |
| 계좌 등록 | `cuj_p04_step2_after` | after |
| 계좌 수정 | `cuj_p04_step3_after` | after |

### cuj_event_create_wizard_test.dart — `cuj_p05` (스텝 수 확인 필요, ~6 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 위저드 Step 1: 기본정보 | `cuj_p05_step0_setup` | setup |
| 위저드 Step 2: 날짜/시간 | `cuj_p05_step1_after` | after |
| 위저드 Step 3: 티켓 | `cuj_p05_step2_after` | after |
| 위저드 Step 4: 검토 | `cuj_p05_step3_after` | after |
| 생성 완료 | `cuj_p05_step4_after` | after |
| 유효성 검사 에러 | `cuj_p05_step5_error` | error |

### cuj_team_management_test.dart — `cuj_p06` (8 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 멤버 목록 | `cuj_p06_step0_setup` | setup |
| 멤버 초대 | `cuj_p06_step1_after` | after |
| 권한 변경 | `cuj_p06_step2_after` | after |
| 멤버 제거 | `cuj_p06_step3_after` | after |

### cuj_partner_account_deletion_test.dart — `cuj_p07` (8 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 계정 삭제 화면 | `cuj_p07_step0_setup` | setup |
| 삭제 확인 다이얼로그 | `cuj_p07_step1_before` | before |
| 삭제 완료 | `cuj_p07_step2_after` | after |
| 에러 상태 | `cuj_p07_step3_error` | error |

### cuj_recurring_event_test.dart — `cuj_p08` (5 tests, ~3 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| 반복 설정 화면 | `cuj_p08_step0_setup` | setup |
| 반복 규칙 저장 | `cuj_p08_step1_after` | after |
| 반복 이벤트 목록 | `cuj_p08_step2_after` | after |

---

## app_partner 기타 테스트 (1 file)

### partner_redirect_test.dart — `redirect_p` (10 tests, ~4 captures)

| testWidgets | 캡처 포인트 | phase |
|-------------|-----------|-------|
| GUEST → /login | `redirect_p_step0_setup` | setup |
| NEEDS_APP → /welcome | `redirect_p_step1_setup` | setup |
| PENDING → /apply/status | `redirect_p_step2_setup` | setup |
| PARTNER → 홈 | `redirect_p_step3_setup` | setup |

---

## Patrol 테스트 (3 files)

### kakao_login_test.dart — `patrol_login`

| 캡처 포인트 | phase | 설명 |
|-----------|-------|------|
| `patrol_login_step0_setup` | setup | 로그인 화면 |
| `patrol_login_step1_before` | before | 카카오 로그인 버튼 탭 전 |
| `patrol_login_step2_after` | after | 카카오 WebView (네이티브) |
| `patrol_login_step3_after` | after | 로그인 완료 → 홈 |

### payment_pg_test.dart — `patrol_payment`

| 캡처 포인트 | phase | 설명 |
|-----------|-------|------|
| `patrol_payment_step0_setup` | setup | 결제 화면 |
| `patrol_payment_step1_before` | before | PG 결제 시작 전 |
| `patrol_payment_step2_after` | after | PG WebView (네이티브) |
| `patrol_payment_step3_after` | after | 결제 완료 |

### permission_grant_test.dart — `patrol_permission`

| 캡처 포인트 | phase | 설명 |
|-----------|-------|------|
| `patrol_permission_step0_setup` | setup | 권한 요청 전 |
| `patrol_permission_step1_after` | after | 시스템 권한 다이얼로그 (네이티브) |
| `patrol_permission_step2_after` | after | 권한 허용 후 |

---

## 요약

| 앱 | 테스트 유형 | 파일 수 | 예상 캡처 수 |
|----|-----------|---------|------------|
| app_user | CUJ | 12 | ~46 |
| app_user | Flow | 7 | ~25 |
| app_user | 기타 (redirect, nav, login) | 6 | ~12 |
| app_partner | CUJ | 10 | ~43 |
| app_partner | 기타 (redirect) | 1 | ~4 |
| patrol | E2E (네이티브) | 3 | ~11 |
| **합계** | | **39** | **~141** |

> 이슈 예상치 ~120장 대비 약간 많음. 실제 구현 시 단순 리다이렉트 검증의 setup 캡처를 줄이면 120장 수준으로 조정 가능.

---

## SWE 구현 가이드

### 1. 스크린샷 캡처 호출 위치

```dart
// apps/*/test/integration/ — flutter_test 기반 WidgetTester 테스트
final capture = GoldenCapture('cuj_u01');
await capture.setup(tester, 0);  // cuj_u01_step0_setup.png
await capture.before(tester, 1); // cuj_u01_step1_before.png
await capture.after(tester, 2);  // cuj_u01_step2_after.png
await capture.error(tester, 3);  // cuj_u01_step3_error.png

// apps/*/emulator_test/ — Patrol 기반 네이티브/E2E 테스트
await $.native.screenshot(name: 'permission_step1_after');
```

### 2. 삽입 원칙

- `pumpWidget()` 직후 → `setup` 캡처
- `tap()` / `enterText()` 직전 → `before` 캡처 (위저드/다이얼로그만)
- `pumpAndSettle()` 직후 → `after` 캡처
- expect에서 에러 UI 검증하는 테스트 → `error` 캡처

### 3. CI 아티팩트

캡처된 스크린샷은 CI에서 아티팩트로 업로드:

```yaml
- name: Upload screenshots
  uses: actions/upload-artifact@v7
  with:
    name: integration-screenshots-${{ matrix.app }}
    path: '**/screenshots/*.png'
```
