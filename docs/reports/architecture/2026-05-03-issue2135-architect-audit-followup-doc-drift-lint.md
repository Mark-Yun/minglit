---
source_url: https://github.com/Mark-Yun/minglit/issues/2135
captured_at: 2026-05-03
issue_number: 2135
state: open
labels: [audit-report]
author: Mark-Yun
title: "🔍 Architect Audit Report — 2026-05-04: 지난 감사 6/8 해소 + 신규 5건 (cleanup-retention doc / MDS workflow / lint enforcement)"
---

# 🔍 Architect Audit Report — 2026-05-04: 지난 감사 6/8 해소 + 신규 5건 (cleanup-retention doc / MDS workflow / lint enforcement)

> Issue #2135 · open · created 2026-05-03 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2135

## Body

Scheduler: audit-arch-claude-subagents

## 감사 범위

- 지난 감사(#1867, 2026-04-27) 후속조치 검증
- 신규 doc-code drift / 코드 구조 건강도
- Edge Function 인벤토리 doc 정합성
- 대형 파일·god widget / cross-feature import 재발

기준 시점: dev @ `2bc51a5f2` (2026-05-04). 지난 감사 이후 8일 / 약 250+ commits.

---

## ✅ 지난 감사 후속조치 — 6/8 해소

| # | 항목 | 상태 | 근거 |
|---|------|------|------|
| §1 | Identity Verification 문서/코드 동기화 | ✅ 해소 | `client.md:152`·`overview.md:153`·`trust-and-verification.md:31` 모두 "V1 SDK + V2 백엔드 병행 구조" 명시 |
| §2 | 진단 마이그레이션 7건 누수 | ✅ 해소 | `supabase/migrations/20260427000001_cleanup_temp_diag_functions.sql` 추가 |
| §3 | `partner-manage-party/index.ts` 827줄 | ✅ 해소 | index.ts **53줄**로 축소 + `_handlers/{create,update,update_status}.ts` + `_lib/{validators,constants}.ts`로 모듈화 |
| §5 | `event_repository_queries.dart` 758줄 / `boarding_pass_card.dart` 708줄 | ✅ 해소 | 둘 다 top 25 밖으로 이탈 |
| §6 | TODO 미추적 | ✅ 해소 | `feed_state_provider.dart` → #1891 추적, `payment-webhook` → #2026 추적 |
| §7 | 테스트 커버리지 | ➡ 별건 진행 | 별도 모니터링 |
| §4 | Cross-feature import 13건 + lint enforcement | 🟡 부분 (13→8) | 아래 §C 상세 |
| §8 | `boarding_pass_card.dart` 708줄 | ✅ §5와 동일 | |

**평가**: 지난 감사 액션 4건 완수, 1건 진행 중. 전반적으로 좋은 트랙. SWE 팀 엔지니어링 위생 OK.

---

## §A 🔴 EF 인벤토리 doc drift — `cleanup-retention` 누락

새 Edge Function이 추가됐으나 `docs/architecture/backend.md §3.1 Function Inventory`에 등재 누락.

| 위치 | 사실 |
|------|------|
| 코드 | `supabase/functions/cleanup-retention/index.ts` 존재 (135 lines, service-role) |
| 마이그레이션 | `20260423000004_retention_table_whitelist.sql` (`retention_table_whitelist` 테이블 + `delete_old_rows`/`delete_expired_rows` admin RPC) |
| Doc | `backend.md:235-288` Function Inventory 표에 **언급 없음** |

**역할**: `retention_policies` 기반 다종 (db_table / storage_bucket / pgmq_archive / db_custom_fn) 보존 기간 만료 데이터 cleanup 워커. 컴플라이언스 핵심 인프라.

**제안 추가 행** (backend.md §3.1에 System 도메인으로):
```
| `cleanup-retention` | System | 보존 기간 만료 데이터 정리 (db_table/storage/pgmq_archive/custom_fn 4종 — `retention_policies` 기반) |
```

**심각도**: Medium — 컴플라이언스/개인정보 관련 인프라가 docs에서 안 보이면 신규 팀원이 retention 정책을 잘못 이해할 위험.

---

## §B 🔴 MDS spec docs(`apps/mds/docs/`) 워크플로우가 architecture docs에 누락

CLAUDE.md는 `apps/mds/docs/`를 **디자인 시스템 SSOT**로 명시 (UI 변경 게이트 / mds-spec-change CI hook 자동 이슈 파일링까지 자동화). 그러나 `docs/architecture/client.md`는:

- §2.1.1 Shared Packages: `mds`, `mds_tokens`, `mds_icons`만 언급 (apps/mds/docs/ 미언급)
- §4 Design System & UI Infrastructure: `mds_storybook` (`apps/mds/storybook/`)만 언급, `apps/mds/docs/`는 미언급
- 신규 SWE가 "spec은 어디에 있나"를 못 찾고 코드만 읽고 시작할 위험

**현황**:
- `apps/mds/docs/public/specs/*.html` — 68개 화면 spec
- `apps/mds/docs/src/lib/components.ts` — 컴포넌트 카탈로그 SSOT
- `apps/mds/docs/src/components/specs/*Spec.tsx` — Next.js 기반 spec 페이지 (총 ~14k LOC)

**제안**: client.md §4(또는 신규 §4.0)에 "Design System Spec Source-of-Truth" 추가:
```
### 4.0 Design System Spec (SSOT)
- 화면 spec: `apps/mds/docs/public/specs/{screen}.html`
- 컴포넌트 카탈로그: `apps/mds/docs/src/lib/components.ts`
- UI 변경 PR은 본문에 spec 인용 필수 (CLAUDE.md "UI 변경 게이트")
- `apps/mds/storybook/`는 Widgetbook 런타임 카탈로그 (Flutter)
- `apps/mds/docs/`는 시각/IA spec 카탈로그 (Next.js, 권위 source)
```

**심각도**: Medium — process docs gap. CLAUDE.md ↔ architecture docs 사이의 분리.

---

## §C ⚠️ Cross-feature import 13건 → 8건 (잔존 + lint 게이트 부재)

지난 감사 권고에도 lint enforcement (`minglit_lints`에 `no_cross_feature_imports` 룰) 미도입. 5건 해소 + 신규/잔존 8건.

### app_user (7건)

| Source | Target | 파일:라인 |
|--------|--------|-----------|
| home | tag | `apps/app_user/lib/src/features/home/widgets/featured_tag_chip_bar.dart:1` |
| home | tag | `apps/app_user/lib/src/features/home/widgets/trending_tag_section.dart:1` |
| home | auth | `apps/app_user/lib/src/features/home/my_page.dart:3` |
| event | auth | `apps/app_user/lib/src/features/event/admission/event_admission_controller.dart:5` |
| event | ticket | `apps/app_user/lib/src/features/event/logic/event_coordinator.dart:3` (ticket_selection_sheet UI 직접 import) |
| my_tickets | ticket | `apps/app_user/lib/src/features/my_tickets/ui/my_tickets_page.dart:3` |
| tag | event | `apps/app_user/lib/src/features/tag/ui/tag_event_list_page.dart:3` |

### app_partner (1건)

| Source | Target | 파일:라인 |
|--------|--------|-----------|
| application | party/event | `apps/app_partner/lib/src/features/application/event_application_detail_page.dart:1` |

**근본 원인**: 지난 감사에서 지적한 lint rule 부재 동일. `minglit_lints` 패키지(`shared/packages/minglit_lints/lib/`)에 5개 룰 존재(no_hardcoded_colors 등) — 그러나 feature boundary 룰 없음.

**제안**:
1. `shared/packages/minglit_lints/lib/src/no_cross_feature_imports_rule.dart` 신규 생성 — `package:app_user/src/features/X/...`를 `features/Y/`에서 import 하는 패턴 차단
2. `_minglitLintsPlugin.getLintRules()`에 등록
3. 기존 8건은 인벤토리 이슈로 분리 (각 Coordinator 추출 / shared widget으로 승격)

**심각도**: Medium — 기능적 영향 없으나 재발 방지 게이트 부재가 메타 이슈.

---

## §D ⚠️ 신규 god 위젯 / 비대 화면 — 분리 필요

지난 감사 §5 트렌드 지속. `event_repository_queries.dart` 등 일부는 분리됐으나 신규/지속 비대 파일 다수.

| 파일 | 라인 | 클래스 수 | 분석 |
|------|------|----------|------|
| `shared/packages/minglit_kit/lib/src/ui/widgets/party/event_card.dart` | 624 | 7 (`MinglitEventCard` + 6개 private 위젯) | shared widget 비대화 — `_ParticipantDDayOverlay`, `_PartnerOverlay`, `_TagChipRow`, `_TagBadge`, `_EventCardSkeleton` 분리 가능 |
| `apps/app_partner/lib/src/features/settlement/settlement_page.dart` | 535 | **13 클래스** | `_DashboardTab`, `_PeriodSelector`, `_RevenueSummaryCard`, `_StatusSummaryGrid`, `_ListTab`, `_MonthHeaderWidget` 등 — tab/section 단위 파일 분리 권장 |
| `apps/app_partner/lib/src/features/home/widgets/event_action_card.dart` | 527 | 5 | `_EndedStatsRow`, `_StatCell`, `EventActionCardEmpty` 분리 가능 |
| `apps/app_user/lib/src/features/event/detail/event_detail_content.dart` | 510 | 3 | `_SliverTabBarDelegate` 분리 가능 (재사용 가능성 있는 generic) |
| `apps/app_user/lib/src/logic/feed_state_provider.dart` | 536 | (provider 다수) | TODO #1891 추적 중 — 별도 |

**심각도**: Medium — 동작 정상이나 리뷰/유지보수 부담.

---

## §E ⚠️ EF >600줄 3건 잔존

`partner-manage-party` 모듈화 모범사례 적용 가능 후보:

| EF | 라인 | 모듈 분리 상태 |
|------|------|----------------|
| `recurrence-rules/index.ts` | 659 | **단일 파일** — action별 (create/update/pause/resume/cancel) 분리 후보 |
| `process-pending-deletions/index.ts` | 647 | **단일 파일** — 단일 cron 진입점이지만 단계별 분리 가능 |
| `backend-simulator/index.ts` | 606 | ✅ 이미 `sim_*` 모듈 분리 (sim_approve, sim_create, sim_event 등) — 추가 조치 불필요 |

**제안**: `recurrence-rules`에 `partner-manage-party` 패턴 적용 (`_handlers/{create,update,pause,resume,cancel}.ts`).

**심각도**: Low — 기능 정상, 유지보수 부담 점진 증가.

---

## ℹ️ 마이그레이션 / EF 카운트 헬스체크

- 총 마이그레이션: 145개 (지난 감사 127개 → +18)
- 총 EF: **51개** (지난 감사 ~50개 → +1: `cleanup-retention`)
- backend.md §3.1 등재 EF: 50개 — **§A drift 1건 외 정합 OK**
- 시퀀스 갭: 추가 anomaly 없음. `KNOWN_GAPS.md` 정상.
- SECURITY DEFINER search_path 픽스 마이그레이션 (`20260428000003`) 추가됨 — 위생 OK
- pgmq_set_vt_wrapper, atomic_set_social_interaction, save_user_consents_server_timestamp 등 hotfix 잘 정리됨

---

## 권장 조치 (우선순위)

| 순위 | 항목 | 라벨 제안 | 우선순위 |
|------|------|-----------|----------|
| 1 | §A — `cleanup-retention` EF doc 추가 (`backend.md §3.1`) | `needs-arch` (Architect 본인) | **P2** |
| 2 | §B — MDS spec docs 워크플로우 client.md §4.0 추가 | `needs-arch` (Architect 본인) | **P2** |
| 3 | §C — `no_cross_feature_imports` lint rule 신규 (`minglit_lints`) | `needs-arch` → `needs-swe` | **P2** |
| 4 | §C — 잔존 cross-feature import 8건 정리 (lint 도입 후) | `needs-swe` | P3 |
| 5 | §D — `event_card.dart`(624) 위젯 파일 분리 | `needs-swe` | P3 |
| 6 | §D — `settlement_page.dart`(535, 13 클래스) tab 단위 분리 | `needs-swe` | P3 |
| 7 | §E — `recurrence-rules` 모듈화 (`partner-manage-party` 패턴 적용) | `needs-swe` | P3 |

---

## 다음 단계

이 리포트를 TPM이 리뷰하고 **§A·§B (Architect 본인 영역)**는 후속 PR로 즉시 처리 가능.
**§C lint rule** 도입은 SWE에 위임 — 룰 한 번 도입하면 §4 잔존 8건 + 향후 재발 모두 게이트됨.
