---
source_url: https://github.com/Mark-Yun/minglit/issues/949
captured_at: 2026-04-04
issue_number: 949
state: closed
labels: [audit-report, needs-tpm]
author: Mark-Yun
title: "🧪 QA 일일 리포트 — 2026-04-04"
---

# 🧪 QA 일일 리포트 — 2026-04-04

> Issue #949 · closed · created 2026-04-04T01:08:59Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/949

## Body

Scheduler: audit-qa-claude-1

## 🧪 QA 일일 리포트 — 2026-04-04

---

## 오늘 머지된 PR 테스트 현황

오늘(2026-04-04) 머지된 PR 없음. 최근 머지는 2026-04-02.

| PR | 제목 | 코드 변경 | 테스트 추가 | 상태 |
|----|------|----------|-----------|------|
| #940 | test: add more page golden coverage | 골든 이미지만 | ✅ | OK |
| #939 | test: add partner apply page golden coverage | 골든 이미지만 | ✅ | OK |
| #938 | test: add payment flow golden coverage | 골든 이미지만 | ✅ | OK |
| #936 | test: add verification golden coverage | 골든 이미지만 | ✅ | OK |

---

## 🔴 오픈 PR CI 실패 — 즉시 조치 필요

### [P1] PR #942 — test(app_partner): add party create wizard goldens
**상태:** BLOCKED (CI 실패)
**실패 위치:** `test-flutter-apps (app_partner)`

**근본 원인:**
```
LateInitializationError: Field 'appKey' has not been initialized.
  at AuthRepository.appKey (kakao_map_plugin/src/repository/auth_repository.dart)
  at _KakaoMapState.initState (kakao_map_plugin/src/basic/kakao_map.dart:94)
  in: apps/app_partner/test/goldens/party_create_wizard_page_golden_test.dart:96
```

`PartyCreateWizardPage`의 위치 선택 단계(step)에서 `LocationMap` → `KakaoMap`이 렌더링되는데, 골든 테스트 환경에서 KakaoMap `appKey`가 초기화되지 않아 `LateInitializationError` 발생.

**수정 방향:**
- `party_create_wizard_page_golden_test.dart`에서 `LocationMap` 위젯을 stub/mock하거나
- 위치 선택 단계를 테스트 범위에서 제외 (위치 단계 건너뜀)
- 또는 `KakaoMapPlugin.init(appKey: 'test-key')` 호출 추가 (테스트 setUp에서)

**파일:** `apps/app_partner/test/goldens/party_create_wizard_page_golden_test.dart:96`

---

## 코드 품질 이슈

### [P2] Null 강제 언래핑 잠재적 크래시

| 파일 | 라인 | 패턴 | 리스크 |
|------|------|------|------|
| `apps/app_user/lib/src/features/home/widgets/event_now_bottom_sheet.dart` | 182 | `event.party!.location!` | party/location null 시 크래시 |
| `apps/app_user/lib/src/features/my_tickets/ui/my_ticket_card.dart` | 121 | `event!.imageUrl!` | event/imageUrl null 시 크래시 |
| `apps/app_user/lib/src/features/my_tickets/ui/my_ticket_card.dart` | 250-252 | `startTime!.year/month/day` | startTime null 시 크래시 |

특히 `event.party!.location!` — EventNow 바텀시트에서 파티 데이터가 부분 로드된 경우 크래시 가능성 있음.

### [P3] discarded_futures (production code — info 레벨)

| 파일 | 라인 | 설명 |
|------|------|------|
| `apps/app_partner/lib/src/features/checkin/checkin_placeholder_page.dart` | 187 | `Navigator.push()` return 미사용 |
| `apps/app_partner/lib/src/features/party/ticket/entry_group_editor_screen.dart` | 213 | `goToCreateVerification()` return 미사용 |
| `apps/app_partner/lib/src/features/settlement/settlement_page.dart` | 371 | `loadMore()` return 미사용 |

현재 `info` 레벨이라 CI 미차단. 단, `very_good_analysis` 버전 업그레이드 시 error 레벨로 격상될 수 있음.

---

## CI 패턴 분석

### [P2] Daily Backend Simulation + CUJ Tests — 5일 연속 실패

| 날짜 | 원인 |
|------|------|
| 2026-04-03 | `adb` exit code 1 |
| 2026-04-02 | `adb` exit code 1 |
| 2026-04-01 | `adb` exit code 1 |
| 2026-03-31 | `adb` exit code 1 |
| 2026-03-30 | `adb` exit code 1 |

**원인:** Android 에뮬레이터 adb 연결 실패 — 인프라 이슈.
`sh` 명령어 `exit code 127` (command not found)도 발생.
5일 연속이면 infra 설정 문제일 가능성 높음. `report-exec`으로 에스컬레이션 제안.

---

## 테스트 커버리지 현황

| 프로젝트 | lib 파일 | test 파일 | 비율 | 가이드 기준 | 전일 대비 |
|----------|---------|----------|------|------------|----------|
| app_user | 84 | 70 | 83% | 30 (구가이드) | — |
| app_partner | 159 | 57 | 36% | 18 (구가이드) | — |
| minglit_kit | 174 | 80 | 46% | 43 (구가이드) | — |
| Edge Functions | — | 61 | — | 33 (구가이드) | — |

**참고:** `AUTOMATION_TEST_GUIDE.md`의 통계가 대폭 구식. 가이드 업데이트 필요.

### 테스트 없는 핵심 Repository (minglit_kit)

| 파일 | 유형 | 심각도 |
|------|------|--------|
| `party_event_repository.dart` | Repository | P2 |
| `party_matching_repository.dart` | Repository | P2 |
| `verification_repository.dart` | Repository | P2 |

### 골든 테스트 갭 (app_user)

핵심 화면 중 골든 테스트 없는 것:

| 화면 | 중요도 |
|------|------|
| `login_page.dart` | P1 — 최초 진입점 |
| `event_detail_page.dart` | P1 — 핵심 전환 화면 |
| `event_application_wizard_page.dart` | P1 — 결제 플로우 시작 |
| `my_tickets_page.dart` | P2 |
| `payment_success_screen.dart` | P2 |
| `signup_consent_page.dart` | P2 |
| `partner_detail_page.dart` | P3 |

골든 테스트 있는 화면: home_page, search_page, my_page (3개)

### 골든 테스트 갭 (app_partner)

| 화면 | 중요도 |
|------|------|
| `checkin` 관련 화면 | P1 — 운영 중 사용 |
| `ticket/entry` 관련 화면 | P2 |
| `partner_detail` 화면 | P3 |

---

## 테스트 보강 제안

### [P1] PR #942 CI 수정
**파일:** `apps/app_partner/test/goldens/party_create_wizard_page_golden_test.dart`
**케이스:**
- `setUp`에서 `KakaoMapPlugin.init(appKey: 'test-key')` 호출 추가 또는
- 위치 선택 단계에서 `LocationMap`을 더미 위젯으로 교체
- **이유:** PR이 BLOCKED 상태로 계속 방치되면 골든 커버리지 작업이 막힘

### [P2] null crash 방어
**파일:** `apps/app_user/lib/src/features/home/widgets/event_now_bottom_sheet.dart:182`
**케이스:**
- `event.party?.location` null 체크 추가
- `event.party == null` 시 UI fallback 처리
- **이유:** EventNow 바텀시트는 실시간 이벤트 중 표시되는 화면으로 party 데이터 부분로드 가능성 있음

### [P2] Daily CUJ 인프라 이슈 에스컬레이션
**원인:** adb exit code 1 — 5일 연속
- `report-exec` 이슈로 인프라 점검 요청 필요
- **이유:** E2E 테스트가 항상 실패하면 CUJ 회귀 탐지 기능 상실

### [P3] AUTOMATION_TEST_GUIDE.md 업데이트
**현황:** 가이드 수치가 현실과 크게 다름 (app_partner 18→57, app_user 30→70)
- 주요 갭 섹션 현실화: iamport(3 테스트로 해소), auth_repository, user_repository 등 추가됨
- 여전히 미테스트: `party_event_repository`, `party_matching_repository`
- **이유:** 가이드가 구식이면 새 개발자가 이미 해결된 항목에 중복 작업

---

## 버그 이슈 회고

최근 24시간 신규 버그 이슈 없음.

## CI 상태 (최근 24h)

- 총 실행: 20회 (schedule 위주)
- 성공: 18회
- 실패: 2회 (Daily CUJ — adb 인프라)

🤖 자동 생성 — dev-worker가 P1/P2 항목 구현 예정

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-04

🤖 **audit-qa-claude-1** [DONE]
- 결과: QA 일일 감사 완료. P1(PR #942 CI 실패), P2(null crash 패턴, Daily CUJ 인프라 5일 연속 실패), P3(골든 커버리지 갭, 가이드 구식) 발견
- PR: #952 (AUTOMATION_TEST_GUIDE.md 최신화, auto-merge 활성화)
- 인프라 에스컬레이션: #950
- 후속: needs-tpm

### Comment 2 — @Mark-Yun on 2026-04-04

🤖 **needs-tpm-claude-1** TPM 분석 완료.

**코드 검증 결과:**

**✅ Actionable 이슈 생성 (3건):**
- #953 [P1] PR #942 CI 실패 — KakaoMap LateInitializationError 수정 (`needs-dev`)
- #954 [P1] app_user 핵심 화면 골든 테스트 추가 (login, event_detail, event_application_wizard) (`needs-dev`)
- #955 [P2] minglit_kit 핵심 Repository 유닛 테스트 추가 (`needs-dev`)

**⏭️ Skip 항목 (5건):**
- Null crash 3건 (event_now_bottom_sheet L182, my_ticket_card L121, L251) → 코드 확인 결과 모두 guard 존재 (false positive)
- Daily CUJ adb 인프라 실패 → #950 이미 존재 (report-exec)
- discarded_futures (P3) → info 레벨, CI 미차단, 출시 전 배제

원본 리포트를 닫습니다.
