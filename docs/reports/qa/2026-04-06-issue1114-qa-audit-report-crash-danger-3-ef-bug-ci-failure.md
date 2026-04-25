---
source_url: https://github.com/Mark-Yun/minglit/issues/1114
captured_at: 2026-04-06
issue_number: 1114
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🔍 QA Audit Report — 2026-04-07: 크래시 위험 3건, EF 프로덕션 디버그 코드, 반복 CI 실패 패턴"
---

# 🔍 QA Audit Report — 2026-04-07: 크래시 위험 3건, EF 프로덕션 디버그 코드, 반복 CI 실패 패턴

> Issue #1114 · closed · created 2026-04-06T21:04:55Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1114

## Body

Scheduler: audit-qa-claude-subagents

## 감사 요약

최근 14일간 머지된 PR 30건, 닫힌 이슈 28건, Flutter 코드베이스 및 Edge Function 50개를 분석한 정기 QA 감사 리포트.

---

## 🔴 크래시 위험 (Flutter)

### 1. `environment_info.dart:120` — `.first` on potentially empty Connectivity result
- **심각도**: Medium
- **위치**: `shared/packages/minglit_kit/lib/src/utils/environment_info.dart:120`
- **문제**: `Connectivity().checkConnectivity()`가 빈 리스트를 반환할 수 있으나 `.first` 호출에 가드 없음. `on Exception`으로 감싸져 있으나 `StateError`는 `Error`를 상속하므로 catch되지 않음.
- **수정**: `result.firstOrNull?.name ?? 'none'` 또는 `isNotEmpty` 가드 추가

### 2. `review_verification_screen.dart:209` — 타입 미검사 `as Map` 캐스트
- **심각도**: Medium
- **위치**: `apps/app_partner/lib/src/features/verification/review/review_verification_screen.dart:209`
- **문제**: `snapshotList.last as Map<String, dynamic>` — `isNotEmpty` 가드만 있고 타입 가드 없음. 백엔드가 non-map 원소를 반환하면 `TypeError`. `event_application_review_dialog.dart`에는 `is Map<String, dynamic>` 타입 체크가 적용되어 있으나 이 화면은 누락.
- **수정**: `last is Map<String, dynamic>` 타입 체크 추가 (기존 패턴과 일관성 확보)

### 3. `event_application_controller.dart:258-261` — 결제 경로 `.first` 가드 로직 오류
- **심각도**: Medium
- **위치**: `apps/app_user/lib/src/features/event/admission/event_application_controller.dart:261`
- **문제**: `if (reqIds.isEmpty || state.verificationData.isEmpty) return null` — OR 조건이므로 `reqIds`가 비어있어도 `verificationData`가 있으면 가드를 통과하여 `.first`에서 `StateError` 발생. 티켓 구매/인증 제출 경로.
- **수정**: `reqIds.isEmpty` 조건을 독립적으로 분리

---

## 🟡 Edge Function 품질 이슈

### 4. `vector-worker` — 프로덕션 디버그 로그 잔존
- **심각도**: Medium
- **위치**: `supabase/functions/vector-worker/index.ts` lines 37-40, 123-130
- **문제**: `debug_logs` 테이블에 매 호출마다 배치 메타데이터를 INSERT. `// DEBUG LOG` 주석이 있으나 프로덕션에서 매번 실행됨. DB 부하 + 데이터 누출 위험.
- **수정**: 제거하거나 `Deno.env.get("DEBUG") === "true"` 가드 추가

### 5. `reconciliation-daily`, `github-stats-sync` — 인라인 auth 패턴 불일치
- **심각도**: Low-Medium
- **위치**: `supabase/functions/reconciliation-daily/index.ts:94`, `supabase/functions/github-stats-sync/index.ts:29-31`
- **문제**: `_shared/auth_utils.requireServiceRole`를 사용하지 않고 인라인 서비스 롤 체크. env 미설정 시 500 에러 대신 빈 문자열과 비교하여 설정 오류가 숨겨짐.
- **수정**: `requireServiceRole` 공통 유틸로 마이그레이션

### 6. `github-stats-sync` — 테스트 없음
- **심각도**: Low
- **위치**: `supabase/functions/github-stats-sync/`
- **문제**: 50개 EF 중 유일하게 테스트 파일 없음
- **수정**: 기본 contract test 추가

### 7. `profile-update` — 사용되지 않는 배포된 코드
- **심각도**: Low
- **위치**: `supabase/functions/profile-update/index.ts`
- **문제**: 코드 첫 줄에 "현재 미사용" 주석. `verify_jwt = true`로 배포 중이나 `recommendation_updates` 큐가 존재하지 않음. HTTP 메서드 제한도 없음.
- **수정**: 삭제 또는 비활성화 판단 필요

### 8. `notification-worker` — URL import (deno.json 미사용)
- **심각도**: Low
- **위치**: `supabase/functions/notification-worker/index.ts:6`
- **문제**: `import * as jose from 'https://deno.land/x/jose@v4.14.4/index.ts'` — Fix #179에서 다른 EF는 import map으로 마이그레이션했으나 이 파일은 누락.
- **수정**: `deno.json` import map으로 이전

---

## 🟡 반복 버그 패턴 & 테스트 갭

### 9. iOS 빌드 SDK 호환성 반복 실패 (3회)
- **관련 이슈**: #1083, #1081/#1082, #1111/#1112, #901
- **패턴**: `connectivity_plus 7.x`, `device_info_plus 12.4.x`, CI YAML heredoc — 각각 다른 패키지이나 동일 원인 (iOS SDK API가 CI runner Xcode 버전과 비호환)
- **제안**: Dependabot major 업데이트 PR에 Xcode 버전 매트릭스 검사 step 추가 또는 pubspec.yaml에 iOS SDK 최소 요구사항 주석 표준화

### 10. EF 추가 시 `deno.json` 누락 (2회 반복)
- **관련 이슈**: #897, #1048
- **패턴**: 새 EF 추가 시 `deno.json` 누락 → 배포 후에만 발견 → 연속 5회+ 배포 실패
- **제안**: `test-edge-functions` CI job에 `deno check` 단계 추가로 PR 단계에서 사전 탐지

### 11. `app_user` recurrence 이벤트 피드 통합 테스트 부재
- **심각도**: Medium
- **현황**: partner side 4개 + kit 1개 recurrence 테스트 존재. 그러나 app_user 측에서 recurrence 이벤트 조회·표시 경로 테스트 없음.
- **제안**: `apps/app_user/test/integration/` 에 recurrence 이벤트 노출 시나리오 추가

### 12. Android 에뮬레이터 인프라 불안정 (5일+ E2E 공백)
- **관련 이슈**: #1063, #1105, #950
- **현황**: adb exit code 1, sh exit code 127 반복. Daily Backend Simulation / CUJ 테스트 장기간 미실행.
- **제안**: 현재 상태 확인 필요. 지속 실패 시 대안 검토 (Firebase Test Lab 등)

---

## 🟢 에러 스와로잉 (정보성)

### 13. `event_now_bar_controller.dart:89,101` — 광범위 에러 무시
- **위치**: `apps/app_user/lib/src/features/home/widgets/event_now_bar_controller.dart`
- **문제**: `on Object catch (_)` 로 모든 예외 무시. 의도적(provider 미준비 시 스킵)이나 프로그래밍 오류도 숨김.
- **제안**: 구체적 예외 타입으로 축소하거나 `Log.w()` 추가

---

## 조치 우선순위

| 우선순위 | 항목 | 라벨 제안 |
|----------|------|-----------|
| P1 | #1, #2, #3 크래시 위험 수정 | `needs-swe`, `P1-high` |
| P2 | #4 디버그 로그 제거 | `needs-swe`, `P2-medium` |
| P2 | #10 EF deno.json CI 사전 탐지 | `needs-arch`, `P2-medium` |
| P2 | #11 app_user recurrence 통합 테스트 | `needs-swe`, `P2-medium` |
| P3 | #5, #6, #7, #8 EF 정리 | `needs-swe`, `P3-low` |
| P3 | #9 iOS 빌드 CI 보강 | `needs-arch`, `P3-low` |
| 정보성 | #12, #13 | 모니터링 |

---

*이 리포트는 `audit-qa-claude-subagents` QA 정기 감사 사이클에서 자동 생성되었습니다.*

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-06

🤖 **tpm-exec-report-claude-subagents** 분석 완료.

**결과:**
- **skip 3건** (항목 #1-3): #1115 / PR #1117에서 이미 수정 중
- **actionable 5건** → 이슈 생성:
  - #1120 — vector-worker debug_logs 제거 (P2, needs-swe)
  - #1121 — EF auth_utils 마이그레이션 + jose import + github-stats-sync 테스트 (P3, needs-swe)
  - #1122 — profile-update 미사용 EF 정리 판단 (P3, needs-arch)
  - #1123 — app_user recurrence 테스트 부재 (P2, needs-qa)
  - #1124 — CI 보강: EF deno.json + iOS 빌드 매트릭스 (P3, needs-arch)
- **skip 5건** (항목 #12-13 정보성, #9 iOS 패턴은 #1124에 포함)

원본 리포트를 닫습니다.
