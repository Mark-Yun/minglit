# PRD: 개인정보 보호 — 동의·약관·인증 열람 권한 관리 (Privacy Protection)

## Summary

사용자가 자신의 개인정보 상태(동의 현황 · 약관 열람 · 본인인증 정보)를 한 곳에서 확인 / 토글 / 열람할 수 있는 settings surface (`/my/privacy`). 추가로 자신의 인증 데이터가 어떤 파트너에게 공유되고 있는지 투명하게 확인하고 열람 권한(`partner_verified_users`) 을 철회할 수 있는 영역을 포함 (Phase 2 — #556 기반). 회원 탈퇴 진입점도 본 페이지에 있다.

## Motivation / Problem to Solve

- 한국 개인정보보호법 / 위치정보법은 (1) 동의 현황 열람 (2) 선택 동의 철회 (3) 약관 원문 열람 을 사용자에게 보장해야 함 — 단일 surface 필요
- 본인인증 (CI/DI) 정보 / 사용자의 자격 인증 (직장 / 학력 / 자산) 이 파트너에게 공유되는데, **유저가 어떤 파트너에게 어떤 인증을 공유했는지 확인 / 철회할 surface 가 없음** (#556 — 미구현 상태로 ui-ux-design.md 만 존재)
- 회원 탈퇴 진입점이 흩어져 있던 IA 통합 필요 (Fix #1213 의 후속 — destructive 액션 모음)
- 처리방침에 본 페이지의 존재가 고지돼 있어 (자료 열람 / 동의 철회 / 권한 관리) 실제 surface 가 일관되게 운영돼야 함

## Goals

### Target Users

- **일반 유저**: 1~2 개 파트너에 인증을 공유한 상태 — 내 정보가 안전한지 확인하고 싶음
- **활발한 유저**: 5+ 파트너 이벤트 참여 — 어떤 파트너가 뭘 보는지 한눈에 파악
- **이탈 예정 유저**: 모든 공유 권한 일괄 철회 후 탈퇴 흐름 진입
- **마케팅 / 위치 동의 변경 사용자**: 가입 후 선택 동의 토글

### Key Goals

- **P0 (Phase 1 — 현재)**: 동의 현황 열람 + 선택 동의 토글 (제3자 제공 · 마케팅 · 위치)
- **P0 (Phase 1)**: 약관 원문 열람 (서비스 이용약관 · 개인정보처리방침 · 위치정보 이용약관)
- **P0 (Phase 1)**: 본인인증 정보 열람 (read-only · 인증 완료 / 미동의 상태 표시)
- **P0 (Phase 1)**: 회원 탈퇴 진입점 (탈퇴 진행 중 sub-variant 분기)
- **P1 (Phase 2 — #556 기반)**: 인증 열람 권한 관리 — 파트너별 권한 목록 + revoke
- **P1 (Phase 2)**: 30 일 내 만료 임박 표시 + 만료된 권한 접힌 섹션
- **P1**: 필수 동의 (이용약관 · 개인정보 수집·이용 · 본인인증) 는 read-only — 철회는 회원 탈퇴를 통해서만

### Non-Goals

- 회원 탈퇴 실제 흐름 — [`account-deletion`](../account-deletion/) feature 영역 (본 페이지는 진입점만)
- 초기 회원가입 동의 흐름 — [`signup-consent`](../signup-consent/) feature 영역 (본 페이지는 사후 관리 surface)
- 약관 자체 작성 / 버저닝 / 재동의 흐름 (별도 PR)
- 파트너 측 권한 관리 UI (본 spec 은 user 앱 한정)
- 본인인증 자체 흐름 — Certification feature 영역

## Product Principles

1. **투명성**: 내 인증이 어디에 공유됐는지 항상 확인 가능 — 파트너별 권한 목록 + 만료일 명시 (Phase 2)
2. **통제권**: 사용자가 언제든 선택 동의 / 공유 권한 철회 가능 — 즉시 반영
3. **안심**: 플랫폼이 만료 시점을 관리 — 만료일 카운트다운 + 자동 종료 안내 (Phase 2)
4. **신중한 액션**: revoke 는 되돌릴 수 없음 — 2 단계 확인 다이얼로그 (Phase 2)
5. **필수/선택 분리**: 필수 동의는 read-only, 선택 동의만 토글 — 법적 의무와 사용자 권리 분리
6. **destructive 위임**: 회원 탈퇴는 진입점만, 실제 확인은 account-deletion wizard 에서

## Technical Approach

- **화면**: PrivacyPage (ConsumerStatefulWidget) — `/my/privacy`. AppBar + ListView (3 섹션: 동의 현황 / 약관 보기 / 계정) + 향후 4 번째 섹션 (인증 열람 권한 — Phase 2)
- **저장 (Phase 1)**: `user_consents` (consent_key, policy_version, consented_at, withdrawn_at)
- **저장 (Phase 2)**: `partner_verified_users` (user_id, partner_id, verification_id, verified_at, valid_until) — RLS DELETE 정책 신규 필요
- **외부 의존성**: consentControllerProvider (Riverpod async) · ConsentDetailSheet (DraggableScrollableSheet · 약관 본문) · accountDeletionControllerProvider (탈퇴 진행 상태)
- **가드 / 정책**: 비로그인 유저는 도달 전 로그인 redirect

## User Journey

### Scenario 1: 선택 동의 토글 (CUJ 1-x)

`/my/privacy` 진입 → "동의 현황" 섹션의 SwitchListTile (제3자 제공 / 마케팅 / 위치) 토글 → 즉시 user_consents update → 실패 시 안내 메시지 + 원상복구.

### Scenario 2: 약관 / 동의 본문 열람 (CUJ 2-x)

필수 동의 항목 (서비스 이용약관 · 개인정보 수집·이용 · 본인인증 정보) 탭 또는 "약관 보기" 섹션의 ListTile 탭 → ConsentDetailSheet 가 아래에서 올라옴 (initialSize 0.82) → 스크롤로 전문 읽음 → 닫기.

### Scenario 3: 회원 탈퇴 진입 (CUJ 3-x)

"계정" 섹션 카드 의 "회원 탈퇴 시작하기" TextButton 탭 → appCoordinator.startAccountDeletion() → DeletionReasonRoute push. 탈퇴 신청 상태로 재진입 시 카드 변형 (모래시계 icon + "탈퇴 요청 진행 중" + "탈퇴 진행 상태 보기" 라벨).

### Scenario 4: 인증 열람 권한 확인 (Phase 2, CUJ 4-x)

`/my/privacy` 진입 → "인증 열람 현황" 섹션 (Phase 2 신규) → 파트너별 그룹 카드 + 인증별 만료일 / D-day → 만료 임박 30 일 이내 warning 톤.

### Scenario 5: 인증 열람 권한 철회 (Phase 2, CUJ 5-x)

권한 카드의 "권한 철회" 버튼 탭 → 확인 다이얼로그 → "철회하기" 탭 → DELETE partner_verified_users → SnackBar 피드백 → 목록 갱신.

## Data Flow

### Scenario 1

PrivacyPage 진입 → consentControllerProvider 가 user_consents 조회 → SwitchListTile 토글 → toggleConsent(type, consented:) → user_consents update → state rebuild → 실패 시 invalidate 후 원상복구 + SnackBar (Fix #886).

### Scenario 2

ListTile / SwitchListTile 탭 → showConsentDetailSheet(content) → ConsentDetailSheet 표시 → dismiss 시 동의 상태 변경 X.

### Scenario 3

"회원 탈퇴 시작하기" 탭 → appCoordinator.startAccountDeletion() → DeletionReasonRoute push (account-deletion wizard 시작).

### Scenario 4 (Phase 2)

PrivacyPage 진입 → verificationRepository.getMyVerificationPermissions() → partner_verified_users + partners + verifications JOIN → 파트너별 grouping → 만료 임박 / 만료됨 분류 → 렌더링.

### Scenario 5 (Phase 2)

권한 카드 "철회" 탭 → 확인 다이얼로그 → revokeVerificationPermission(partnerId, verificationId) → DELETE partner_verified_users WHERE user_id = auth.uid() AND partner_id = $1 AND verification_id = $2 → 목록 invalidate + SnackBar.

## KPIs / Success Metrics

- **선택 동의 토글 성공률** ≥ 99% (실패 시 Fix #886 의 원상복구 패턴 동작 확인)
- **약관 본문 시트 평균 체류시간**: 전문 읽음 여부 proxy
- **회원 탈퇴 진입 → 1 단계 완료 전환율** (account-deletion 1-1 까지 도달)
- **(Phase 2) 권한 철회 전환율**: 권한 카드 노출 대비 철회 비율
- **(Phase 2) 만료 임박 알림 효과**: 30 일 이내 만료 권한 노출 후 갱신 / 철회 비율

## Launch Strategy

Phase 1 (현재): 동의 / 약관 / 계정 — 즉시 전체 적용.
Phase 2 (#556 인증 열람 권한): 별도 PR 로 분리 — RLS DELETE 정책 + Repository + UI + 다이얼로그.

## Legal Basis

| 근거 | 내용 |
|------|------|
| 개인정보보호법 제35조 (개인정보 열람 요구권) | 본인의 개인정보 처리 사항 / 동의 내역 열람 보장 |
| 개인정보보호법 제37조 (처리정지 등) | 선택 동의 철회 권리 — 본 페이지의 SwitchListTile |
| 개인정보보호법 제36조 (개인정보 파기) | 회원 탈퇴 진입점 — account-deletion 으로 위임 |
| 위치정보법 제19조 (위치정보 이용 동의) | 위치 동의 토글 + 위치정보 이용약관 열람 |
| 정보통신망법 제27조의2 | 개인정보처리방침 / 약관 원문 열람 |
| Apple App Store Review / Google Play | 동의 관리 UI 제공 의무 — 마케팅 / 제3자 제공 / 위치 |

### 보존 기간

| 항목 | 기간 | 근거 |
|------|------|------|
| user_consents (동의 이력) | 최소 2 년 (권장 5 년) | 개인정보보호법 시행령 |
| partner_verified_users (인증 열람 권한) | `valid_until` 까지 자동 종료 | 데이터 최소 보존 원칙 (#556) |
| 만료된 권한 row | 만료 후 보관 X (즉시 hard delete 또는 soft expire) — 정책 미정 (Open Q) | — |

## References

- MDS spec: [`privacy_page`](../../../../apps/mds/docs/public/specs/privacy_page/) — 3 state (Default 로드 완료 / Loading / Error) + 탈퇴 진행 중 sub-variant
- 관련 이슈: #556 (Trust 인증 열람 권한 관리 — Phase 2 source) · Fix #886 (토글 실패 원상복구) · Fix #1157 (보유기간 명시) · Fix #1213 (계정 IA 통합)
- 관련 아키텍처: [`Trust & Verification`](../../../architecture/trust-and-verification.md) — 2-layer 신뢰 모델 (Identity + Qualification)
- 인접 feature: [`signup-consent`](../signup-consent/) (초기 동의 흐름) · [`account-deletion`](../account-deletion/) (탈퇴 wizard) · [`account-management`](../account-management/) (계정 관리 IA)
- 마이그레이션 source: 본 폴더의 `ui-ux-design.md` (v1.0, 2026-03-28, #556 기반) — 본 PRD 의 Phase 2 / Scenario 4·5 의 원본
