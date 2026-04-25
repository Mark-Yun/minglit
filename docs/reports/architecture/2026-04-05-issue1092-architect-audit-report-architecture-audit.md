---
source_url: https://github.com/Mark-Yun/minglit/issues/1092
captured_at: 2026-04-05
issue_number: 1092
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🔍 Architect Audit Report — 2026-04-06: 아키텍처 건강도 정기 감사"
---

# 🔍 Architect Audit Report — 2026-04-06: 아키텍처 건강도 정기 감사

> Issue #1092 · closed · created 2026-04-05T21:02:48Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1092

## Body

Scheduler: audit-arch-claude-subagents

## 감사 범위

- Architecture docs 정확도 검증
- 코드 구조 건강도 (대형 파일, cross-feature import, TODO/FIXME, 테스트 커버리지, 마이그레이션)

---

## 1. 문서 정확도

### 🔴 overview.md: 본인인증 제공자 오류

| 항목 | 내용 |
|------|------|
| 파일 | `docs/architecture/overview.md:70` |
| 문제 | "플랫폼 (PASS/SMS API)"로 기술되어 있으나, 실제 구현은 **Iamport V2** 사용 |
| 근거 | `client.md:138,143`은 Iamport으로 정확히 기술. `minglit_kit/lib/src/features/iamport/` 디렉토리 존재 |
| 심각도 | High — 아키텍처 개요 문서가 실제 구현과 불일치하면 신규 팀원이 잘못된 가정으로 작업 |

### ⚠️ backend.md: 테이블 수 불일치

| 항목 | 내용 |
|------|------|
| 파일 | `docs/architecture/backend.md:44` |
| 문제 | "총 53개 테이블"이라고 명시하나, 같은 문서 내 실제 나열된 테이블은 **69개** |
| 심각도 | Medium — 숫자만 틀린 것이지만 문서 신뢰도를 떨어뜨림 |

### ℹ️ client.md: 신규 feature 누락

| 항목 | 내용 |
|------|------|
| 파일 | `docs/architecture/client.md` (feature inventory 섹션) |
| 문제 | `account_deletion`, `consent` feature가 app_user, minglit_kit 모두에 존재하나 client.md feature 목록에 미반영 |
| 심각도 | Low — 기능은 정상 동작하며, 문서 갱신만 필요 |

---

## 2. 대형 파일 (500+ lines, 생성 코드 제외)

| 파일 | 라인 수 | 비고 |
|------|---------|------|
| `minglit_kit/lib/src/features/dev/design_catalog_page.dart` | 1,461 | dev-only이지만 유지보수 부담 |
| `app_user/lib/src/features/home/widgets/event_now_bottom_sheet.dart` | 872 | **5개 phase**(체크인 준비, 체크인 완료, 매칭, 결과, 종료)를 단일 위젯에서 처리. 분리 필요 |
| `minglit_kit/lib/src/data/repositories/event_repository_queries.dart` | 639 | 쿼리 메서드 집중. 도메인별 분리 검토 |
| `app_partner/lib/src/features/application/event_application_manage_page.dart` | 592 | UI 비대화 |
| `app_user/lib/src/logic/feed_state_provider.dart` | 535 | 전역 상태 관리 로직 집중 |
| `app_user/lib/src/features/consent/ui/signup_consent_page.dart` | 530 | 최근 추가 (#985) |

**가장 긴급**: `event_now_bottom_sheet.dart` — 서로 다른 5개 phase를 각각 독립 위젯으로 추출하면 테스트 용이성과 가독성 모두 개선.

---

## 3. 🔴 Cross-Feature Import 위반

Feature-first 아키텍처에서 feature 간 직접 import는 금지. 다음 위반 발견:

| 소스 파일 | 위반 import |
|-----------|------------|
| `app_user/.../home/widgets/event_now_bottom_sheet.dart` | `event/matching/widgets/matching_vote_content.dart`, `ticket/data/ticket_wallet_repository.dart`, `ticket/ui/widgets/ticket_qr_viewer.dart` |
| `app_user/.../home/my_page.dart` | `auth/logic/auth_coordinator.dart` |
| `app_user/.../event/admission/event_admission_controller.dart` | `auth/logic/auth_coordinator.dart` |
| `app_user/.../event/admission/event_application_wizard_page.dart` | `home/logic/home_coordinator.dart`, `payment/ui/payment_success_screen.dart` |
| `app_user/.../event/detail/event_detail_page.dart` | `ticket/logic/ticket_coordinator.dart` |

**Root cause**: Coordinator가 feature 내부에 위치하면서 다른 feature에서 직접 참조. 공유 coordinator 계층을 `src/logic/` 또는 별도 모듈로 추출하는 리팩토링 필요.

---

## 4. 🔴 TODO/FIXME 컨벤션 위반

프로젝트 컨벤션: "한 번에 제대로. TODO를 남기지 않는다."

| 파일 | 라인 | 내용 |
|------|------|------|
| `app_user/test/.../event_detail_controller_test.dart` | 45 | FIXME: "This test fails with 'provider disposed' error." |
| `app_partner/test/.../checkin_placeholder_page_test.dart` | 109 | TODO: "Re-enable after QRScannerScreen dispose bug is fixed." |
| `minglit_kit/lib/src/config/env_keystore.dart` | 7 | TODO: "Implement CI audit to detect drift between this file and env-manifest.json." |

3건 모두 코드 레벨 미완성 작업. 특히 테스트 FIXME/TODO는 버그를 숨기는 효과.

---

## 5. 🔴 테스트 커버리지 Gap

### 위험 도메인 커버리지

| 영역 | lib 파일 수 | test 파일 수 | 커버리지 | 위험도 |
|------|------------|-------------|---------|--------|
| app_partner/settlement | 21 | 4 | 19% | **금융 도메인 — Critical** |
| app_user/ticket | 9 | 2 | 22% | High |
| app_partner/party | 83 | 11 | 13% | High (핵심 비즈니스) |
| app_partner/auth | 1 | 0 | 0% | Medium |
| minglit_kit/verification | 2 | 0 | 0% | Medium |
| minglit_kit/theme | 3 | 0 | 0% | Low |

**전체 추정 커버리지**: ~43% (lib 대비 test 파일 기준)

---

## 6. 마이그레이션 건강도

**상태: 양호**

- 총 73개 마이그레이션 파일
- 네이밍 컨벤션 준수
- 하나의 시퀀스 갭: `20260322000003` 누락 (000002 → 000004). 의도적 삭제인지 확인 필요.

---

## 권장 조치 (우선순위)

| 순위 | 항목 | 라벨 제안 | 우선순위 |
|------|------|----------|---------|
| 1 | overview.md 본인인증 제공자 수정 (PASS→Iamport) | `needs-arch` | P2 |
| 2 | Cross-feature import 리팩토링 설계 | `needs-arch` | P2 |
| 3 | settlement 테스트 커버리지 보강 | `needs-qa` → `needs-swe` | P2 |
| 4 | event_now_bottom_sheet 위젯 분리 | `needs-arch` → `needs-swe` | P3 |
| 5 | TODO/FIXME 해소 (3건) | `needs-swe` | P3 |
| 6 | backend.md 테이블 수 + client.md feature 목록 갱신 | `needs-arch` | P3 |
| 7 | 마이그레이션 시퀀스 갭 확인 | `needs-tpm` | P3 |

---

## 다음 단계

이 리포트를 TPM이 리뷰하고 개별 이슈로 분리/트리아지할 것을 권장합니다.

## Comments (4)

### Comment 1 — @Mark-Yun on 2026-04-05

🤖 **audit-arch-claude-subagents** 문서 정확도 항목 수정 PR 생성: #1093

- overview.md 본인인증 제공자 수정 (PASS → Iamport)
- backend.md 누락 테이블 4건 추가
- client.md feature inventory 갱신

나머지 항목(cross-feature import, 테스트 커버리지, 대형 파일 등)은 개별 이슈로 분리 필요 → `needs-tpm` 라벨로 트리아지 요청합니다.

### Comment 2 — @Mark-Yun on 2026-04-05

🤖 **audit-arch-claude-subagents** PR #1093 머지 완료.

**완료된 항목:**
- ✅ overview.md 본인인증 제공자 수정 (PASS → Iamport)
- ✅ backend.md 누락 테이블 4건 추가
- ✅ client.md feature inventory 중복 정리

**TPM 트리아지 필요 항목 (개별 이슈 분리 권장):**
1. Cross-feature import 위반 5건+ → `needs-arch` P2
2. settlement 테스트 커버리지 19% → `needs-qa` P2
3. event_now_bottom_sheet 872줄 → `needs-arch` P3
4. TODO/FIXME 3건 → `needs-swe` P3
5. 마이그레이션 시퀀스 갭(20260322000003) → `needs-tpm` P3

### Comment 3 — @Mark-Yun on 2026-04-05

🤖 **needs-tpm-claude-1** 작업 시작합니다.

### Comment 4 — @Mark-Yun on 2026-04-05

🤖 **needs-tpm-claude-1** TPM 분석 완료.

**이미 완료된 항목 (PR #1093 머지):**
- ✅ overview.md 본인인증 제공자 수정 (PASS → Iamport)
- ✅ backend.md 테이블 수 수정
- ✅ client.md feature inventory 갱신

**Actionable 항목 → 이슈 생성 (4건):**
| 이슈 | 제목 | 라벨 | 우선순위 |
|------|------|------|---------|
| #1094 | Cross-feature import 위반 해소 설계 | `needs-arch` | P2 |
| #1095 | settlement 테스트 커버리지 보강 계획 | `needs-qa` | P2 |
| #1096 | event_now_bottom_sheet 5-phase 위젯 분리 설계 | `needs-arch` | P3 |
| #1097 | TODO/FIXME 미해소 항목 2건 처리 | `needs-swe` | P3 |

**Skip 항목 (1건):**
- 마이그레이션 시퀀스 갭 (20260322000003 누락) — 기능적 영향 없음, 번호가 건너뛴 것뿐

원본 리포트를 닫습니다.
