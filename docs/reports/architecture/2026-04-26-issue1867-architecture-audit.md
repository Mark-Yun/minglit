---
source_url: https://github.com/Mark-Yun/minglit/issues/1867
captured_at: 2026-04-26
issue_number: 1867
state: open
labels: [audit-report, needs-tpm]
author: Mark-Yun
title: "🔍 Architect Audit Report — 2026-04-27: 아키텍처 건강도 정기 감사"
---

# 🔍 Architect Audit Report — 2026-04-27: 아키텍처 건강도 정기 감사

> Issue #1867 · open · created 2026-04-26 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1867

## Body

Scheduler: audit-arch-claude-subagents

## 감사 범위

- Architecture docs 정확도 검증 (overview/client/backend/payment/trust)
- 코드 구조 건강도 (대형 파일, cross-feature import, TODO/FIXME)
- 테스트 커버리지 (위험 도메인)
- 마이그레이션 건강도 (시퀀스, 잔존 진단 코드)

기준 시점: `dev` @ `9a06deb78` (2026-04-27).
이전 감사: #1092 (2026-04-05) 이후 22일 경과, 그동안 파생 이슈 #1094-1097 모두 closed.

---

## 1. 🔴 문서 ↔ 코드 불일치 (Identity Verification)

본인인증(Identity Verification) 영역의 docs와 실제 import가 어긋남. 이전 PR #1093에서 일부 수정됐지만 여전히 잔재.

| 위치 | 현재 기재 | 실제 코드 | 문제 |
|------|-----------|-----------|------|
| `docs/architecture/overview.md:153` | "검증 주체: 플랫폼 (**Iamport** 본인인증 API)" | EF `identity-verify`는 **Portone V2** SDK 호출 (`trust-and-verification.md:32`) | 같은 docs/architecture 내부에서 표현 충돌 |
| `docs/architecture/client.md:37` | "verification/ — **Iamport V2** 기반 실명 인증 화면" | `shared/packages/minglit_kit/lib/src/features/verification/ui/identity_verification_screen.dart:6`은 `package:minglit_iamport_v1/...` 임포트 | "V2 기반"이라고 적었지만 클라이언트는 V1 SDK 사용 |
| `docs/architecture/client.md:30` | "iamport/ — 결제 연동 (Iamport SDK 래퍼)" | `iamport/` feature 내 `iamport_controller.dart`, `iamport_repository.dart`도 V1 SDK 호출(결제 + 본인인증 모두) | 결제만 한정한다고 오해 가능 |

**Root cause 가설**: 백엔드는 `verify-identity-v1` → `identity-verify` (Portone V2)로 마이그레이션했지만 (#기존 이슈), 프론트는 여전히 `minglit_iamport_v1` 패키지의 certification flow를 그대로 사용. 백엔드 Portone V2 API와 프론트 V1 SDK의 호환성 검증이 필요. 현재 본인인증이 정상 동작한다면 V1 SDK 호출 후 백엔드 V2 검증 단계에서 호환되는지 명시해야 한다.

**심각도**: High — 신규 팀원이 verification 코드를 만질 때 잘못된 레퍼런스를 참조하게 되며, 실제 마이그레이션이 끝나지 않은 부채를 가린다.

---

## 2. 🔴 진단 마이그레이션 7건 누수 (Production DB)

`supabase/migrations/20260415000099-000105` 7개 파일이 **임시 진단용** SECURITY DEFINER 함수를 정의한 채 그대로 dev/prod에 머지됨.

| Migration | 정의 함수 |
|-----------|-----------|
| `20260415000099_temp_auth_diag.sql` | `public.temp_auth_diag()` |
| `20260415000101_temp_diag2.sql` | `public.temp_auth_diag2()` |
| `20260415000102_diag_identity.sql` | `public.temp_auth_diag2()` (재정의) |
| `20260415000104_diag_all_cols.sql` | `public.temp_compare_users()` |
| `20260415000105_fix_null_strings.sql` | (nullable 정리) |

문제:
- 명명에 `temp_` 접두사가 있지만 **drop 마이그레이션이 없음** → DB에 영구 잔존.
- `SECURITY DEFINER` 함수가 진단용으로 생성됐으면 이슈 해결 후 즉시 제거해야 한다(공격면 축소).
- 시퀀스 갭(20260415000001 → 20260415000099)은 hotfix 우선순위 표시용으로 보이나 cleanup 누락.

**조치 권장**: `cleanup_temp_diag_functions` 마이그레이션 추가하여 DROP FUNCTION IF EXISTS 4종.

**심각도**: High — 보안 표면 + 코드 위생.

---

## 3. ⚠️ EF 비대화: `partner-manage-party/index.ts` 827 lines

이전 감사 이후 신규로 등장한 최대 EF.

| 파일 | 라인 |
|------|------|
| `supabase/functions/partner-manage-party/index.ts` | **827** |
| `supabase/functions/recurrence-rules/index.ts` | 659 |
| `supabase/functions/process-pending-deletions/index.ts` | 647 |
| `supabase/functions/backend-simulator/index.ts` | 606 |
| `supabase/functions/partner-manage-event/index.ts` | 594 |

`partner-manage-party`는 단일 EF에 파티 CRUD + 복구 + 권한 검증 + 사이드이펙트가 응집. EF 단일 진입점 원칙(`overview.md §2.2`)을 지키면서도 핸들러를 모듈로 분리(예: `_handlers/create.ts`, `_handlers/update.ts`)하는 패턴 도입 검토.

**심각도**: Medium — 동작은 정상, 유지보수 부담 증가.

---

## 4. ⚠️ Cross-feature Import 13건 (이슈 #1094 closed 후 재발/잔존)

이전 감사 이슈 #1094(refactor: cross-feature import 해소)는 closed 상태이지만 동일/신규 위반 다수 발견. lint 차원 enforcement가 없으면 재발이 반복된다.

### app_user (12건)

| Source feature | Import target | 파일 |
|----------------|---------------|------|
| event | auth, home, ticket | `event/admission/event_admission_controller.dart`, `event/logic/event_coordinator.dart` |
| home | auth, tag, ticket | `home/my_page.dart`, `home/widgets/featured_tag_chip_bar.dart`, `home/widgets/trending_tag_section.dart`, `home/logic/home_coordinator.dart` |
| my_tickets | home, ticket | `my_tickets/ui/my_tickets_page.dart` |
| settings | account_deletion, consent | `settings/privacy_page.dart` |
| tag | event | `tag/ui/tag_event_list_page.dart` |
| account_deletion | home | `account_deletion/ui/deletion_complete_page.dart` |

### app_partner (1건)
- `party → home` (`party/event/create/event_create_controller.dart`)

**근본 원인**: feature 내부에 Coordinator를 두는 패턴이 cross-feature 결합을 유도. lint rule (`avoid_relative_lib_imports` + custom `directory_discipline`) 또는 melos hook으로 차단 필요.

**심각도**: Medium — 이전 이슈 closed 후에도 13건 잔존, 재발 방지 게이트 부재.

---

## 5. ⚠️ 대형 파일 트렌드 (마지막 감사 이후 증가)

| 파일 | 4-05 | 4-27 | 변화 |
|------|------|------|------|
| `shared/packages/minglit_kit/lib/src/data/repositories/event_repository_queries.dart` | 639 | **758** | +119 (+19%) |
| `apps/app_user/lib/src/features/consent/ui/signup_consent_page.dart` | 530 | **619** | +89 |
| `apps/app_partner/lib/src/features/application/event_application_manage_page.dart` | 592 | **637** | +45 |
| `apps/app_user/lib/src/logic/feed_state_provider.dart` | 535 | 536 | +1 |
| `apps/app_user/lib/src/features/ticket/ui/widgets/boarding_pass_card.dart` | (신규) | **708** | new |
| `shared/packages/minglit_kit/lib/src/ui/widgets/party/event_card.dart` | (신규) | **618** | new |

`event_now_bottom_sheet.dart`는 #1096으로 분리 완료 (현재 top 25 밖). 다만 다른 파일들이 그 자리를 메우는 중.

**심각도**: Medium — 분리 노력 vs 신규 비대화 속도가 균형 안 맞음.

---

## 6. ⚠️ TODO/FIXME 7건 (이슈 #1097 closed 후 신규 등장)

| 위치 | 내용 | 추적 |
|------|------|------|
| `apps/app_user/patrol_test/permission_grant_test.dart` (×3) | "App 초기화 + 테스트 계정 로그인 구현 후 skip 제거" | #1436 |
| `apps/app_user/patrol_test/payment_pg_test.dart` | "PG sandbox 설정 후 skip 제거" | #1436 |
| `apps/app_user/patrol_test/kakao_login_test.dart` | "카카오 테스트 계정 준비 후 skip 제거" | #1436 |
| `apps/app_user/lib/src/logic/feed_state_provider.dart:445,479` | "migrate to recommendationEventsFromEf", "wire into explore UI behind a feature flag" | **미추적** |
| `supabase/functions/payment-webhook/index.ts` | "포트원 서버 호출자 검증 강화", "Migrate to produce_event() pattern" | **미추적** |

`feed_state_provider`와 `payment-webhook`의 TODO는 추적 이슈가 없음. 컨벤션 위반.

**심각도**: Low — 동작 영향 없으나 컨벤션 위반.

---

## 7. ✅ 테스트 커버리지: 큰 진전

이전 감사 우려 도메인의 개선 확인.

| 영역 | 4-05 | 4-27 | 변화 |
|------|------|------|------|
| `app_partner/settlement` | 19% (4/21) | **100% (13/13)** | ✅ 이슈 #1095 효과 |
| `app_partner/checkin` | — | **100% (12/12)** | ✅ |
| `app_user/ticket` | 22% (2/9) | 45% (5/11) | ⬆ |
| `app_partner/party` | 13% (11/83) | 27% (21/78) | ⬆ but still gap |
| `minglit_kit/iamport` | — | 27% (3/11) | 검증 가치 부족 |
| `minglit_kit/verification` | 0% (0/2) | 50% (1/2) | ⬆ |

**잔존 위험**: `app_partner/party` 27% — 핵심 비즈니스 도메인이지만 여전히 미흡. 별도 이슈로 추적 권장.

---

## 8. ℹ️ 마이그레이션 (시퀀스 + 무결성)

- 총 127개 마이그레이션 (이전 73개 → +54)
- 시퀀스 갭: `20260322000003`(이전부터), `20260415000002~000098`(hotfix 점프, 의도적), `20260422000008` (신규)
- 중복 파일명: `20260422000006_verification_retention.sql` + `20260422000007_verification_retention.sql` — **의도적** (#1707 Part 1/2 — `ALTER TYPE ADD VALUE` 트랜잭션 제약 때문)

→ 단일 위험 항목은 **§2의 진단 마이그레이션 누수**.

---

## 권장 조치 (우선순위)

| 순위 | 항목 | 라벨 제안 | 우선순위 |
|------|------|-----------|----------|
| 1 | 진단 마이그레이션 cleanup (§2) — DROP FUNCTION 4종 추가 | `needs-arch` → `needs-swe` | **P2** |
| 2 | Identity verification 문서/코드 동기화 (§1) — V1 SDK 사용 사실 명시 또는 V2 SDK 마이그레이션 | `needs-arch` | **P2** |
| 3 | Cross-feature import lint enforcement (§4) — 재발 방지 룰 도입 | `needs-arch` | P2 |
| 4 | `partner-manage-party/index.ts` 핸들러 분리 (§3) | `needs-arch` | P3 |
| 5 | `event_repository_queries.dart` 758줄 도메인별 분리 (§5) | `needs-arch` | P3 |
| 6 | `app_partner/party` 테스트 커버리지 보강 27% → 60%+ | `needs-qa` → `needs-swe` | P3 |
| 7 | TODO/FIXME 미추적 항목 3건 이슈화 (§6) | `needs-tpm` | P3 |
| 8 | `boarding_pass_card.dart` 708줄 위젯 분리 (§5) | `needs-arch` | P3 |

---

## 다음 단계

이 리포트를 TPM이 리뷰하고 §1·§2를 우선 actionable 이슈로 분리할 것을 권장.
