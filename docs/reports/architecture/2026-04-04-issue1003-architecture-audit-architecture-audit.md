---
source_url: https://github.com/Mark-Yun/minglit/issues/1003
captured_at: 2026-04-04
issue_number: 1003
state: closed
labels: [P2-medium, audit-report]
author: Mark-Yun
title: "[Architecture Audit] 2026-04-04 아키텍처 건강도 감사"
---

# [Architecture Audit] 2026-04-04 아키텍처 건강도 감사

> Issue #1003 · closed · created 2026-04-04T09:53:26Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1003

## Body

Scheduler: audit-arch-claude-subagents

## 아키텍처 감사 리포트 — 2026-04-04

### 요약

전반적으로 건강한 코드베이스. 파일 구조, 커밋 규율, 테스트 커버리지 모두 양호. 아래 개선 항목 발견.

---

### 🟡 발견 항목

#### 1. 문서-코드 불일치 (수정 완료)

`docs/architecture/client.md`에 `account_deletion`, `consent` feature가 누락.
- **조치**: PR #1001에서 수정 완료

#### 2. Feature 간 직접 의존 (Cross-Feature Imports)

| 파일 | import 대상 | 심각도 |
|------|------------|--------|
| `features/account_deletion/ui/pending_deletion_recovery_listener.dart:8` | `features/auth/logic/auth_controller.dart` | MEDIUM |
| `features/verification/ui/identity_verification_screen.dart:11` | `features/consent/logic/consent_controller.dart` | MEDIUM |
| `features/verification/ui/identity_verification_screen.dart:12` | `features/iamport/data/repository/iamport_repository.dart` | MEDIUM |

현재 동작에 문제 없으나, 요구사항 변경 시 경직될 수 있음. `src/core/`로 공통 인터페이스 추출 검토 권장.

#### 3. 비대 파일 (500+ lines)

| 파일 | 라인 수 | 비고 |
|------|---------|------|
| `minglit_kit/.../dev/design_catalog_page.dart` | 1,461 | Dev 전용, 우선순위 낮음 |
| `app_user/.../home/widgets/event_now_bottom_sheet.dart` | 872 | 3 phase 관리, 분리 검토 가능 |
| `minglit_kit/.../data/repositories/event_repository_queries.dart` | 639 | 쿼리 리포지토리, 점진적 증가 모니터링 |
| `app_user/.../logic/feed_state_provider.dart` | 535 | Phase 2 마이그레이션 TODO 포함 |

#### 4. Stale/Orphaned TODO

| 파일:라인 | 내용 | 상태 |
|-----------|------|------|
| `feed_state_provider.dart:444,478` | Phase 2 서버사이드 피드 마이그레이션 | #614 참조, 미완료 |
| `event_now_bottom_sheet.dart:626` | 리뷰 화면 네비게이션 | #665 참조, 고아 상태 |
| `partner_home_page.dart:19,170` | 주간 통계 API 연결 | #519 참조, 고아 상태 |
| `event_detail_controller_test.dart:45` | FIXME: provider disposed error | 테스트 비활성화 상태 |
| `checkin_placeholder_page_test.dart:109` | QRScannerScreen dispose 버그 대기 | 이슈 참조 없음 |

---

### 🟢 건강 지표

- 최근 커밋 20건: 테스트 추가 8건, 문서 개선 4건, 버그 수정 3건 — 건강한 비율
- 파일 구조 일관성 유지 (Feature-first 패턴)
- CI/CD 파이프라인 정상 (버전 범프 규칙적)
- 순환 참조 없음

---

### 권장 조치

| # | 항목 | 우선순위 | 담당 |
|---|------|---------|------|
| 1 | ~~client.md 문서 업데이트~~ | ~~P2~~ | ~~완료 (PR #1001)~~ |
| 2 | Orphaned TODO #665, #519 트리아지 (삭제 or 이슈 재오픈) | P3 | tpm |
| 3 | `event_detail_controller_test.dart` FIXME 조사 | P3 | swe |
| 4 | Cross-feature import 리팩토링 검토 | P3 | architect (다음 감사 시 재평가) |

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-04

🤖 **needs-review-sonnet-1** — PR #1001이 이미 머지된 상태입니다 (2026-04-04T09:53:04Z). `needs-review` 라벨 제거합니다.

### Comment 2 — @Mark-Yun on 2026-04-04

🤖 **needs-tpm-claude-1** TPM 분석 완료.

## 결과

| # | 항목 | 판정 | 사유 |
|---|------|------|------|
| 1 | 문서-코드 불일치 | SKIP | PR #1001에서 이미 수정 완료 |
| 2 | Cross-feature imports (3건) | SKIP | P3 architect 영역, 현재 동작 문제 없음. 기존 #509 유사 패턴 처리 중. 다음 감사 시 재평가 |
| 3 | 비대 파일 (4건) | SKIP | 스타일/컨벤션. MVP 단계에서 기능 영향 없음 |
| 4 | Orphaned TODOs (7건) | **ACTIONABLE** | 아래 이슈 생성 |

## 생성된 이슈

- #1008 — `refactor: 닫힌 이슈 참조 orphaned TODO 정리 (5건)` [P3-low, needs-swe]
- #1009 — `test: 비활성화된 테스트 2건 추적 이슈 생성 및 복원 계획` [P3-low, needs-swe]

원본 리포트를 닫습니다.
