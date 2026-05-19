# PRD: 계정 관리 (Account Management)

## Summary

신원·계정에 귀속된 액션(본인인증 · 파트너 프로필 · 로그아웃 · 회원 탈퇴 진입)을 한 곳에 모은 서브-설정 페이지. user `/my/account` + partner `/more/account` 양쪽에서 동일 위젯(kit-shared) 사용. Fix #1213 으로 MyPage / MorePage 에서 흩어져 있던 destructive 액션을 통합했고, Fix #1378 로 로그아웃에 확인 다이얼로그를 추가, Fix #1861 로 본인인증 진입을 이 페이지로 이동.

## Motivation / Problem to Solve

- destructive 액션 (로그아웃 · 회원 탈퇴) 이 MyPage / MorePage 본문에 흩어져 있어 발견성/혼선 문제 발생 (Fix #1213)
- 로그아웃이 즉시 실행되어 사고가 잦음 — 다시 로그인하면 복구 가능하지만 진행 중 작업 / 미저장 상태 손실 위험 (Fix #1378)
- 본인인증이 MyPage 본문에 별도 entry 로 있어 "계정에 귀속된 신원 속성" 이라는 의도가 안 보임 (Fix #1861)
- 파트너 측에서도 "파트너 프로필" 편집 진입점 필요 (Phase 2 빌드 예정)

## Goals

### Target Users

- **user**: 본인인증 · 로그아웃 · 회원 탈퇴 진입이 필요한 시점
- **partner**: 파트너 프로필 편집 · 로그아웃 · 회원 탈퇴 진입이 필요한 시점

### Key Goals

- **P0**: 신원/계정 액션을 단일 서브 페이지로 통합 (`/my/account` · `/more/account`)
- **P0**: 로그아웃 시 확인 다이얼로그 (단일 단계 — 위험 색 X, 일반 강조 색)
- **P0**: 본인인증 진입점을 이 페이지로 이동 (계정 귀속 신원 속성)
- **P0**: 회원 탈퇴는 이 페이지에서 추가 확인 없이 외부 coordinator 로 위임 (실제 확인은 별도 wizard 화면에서)
- **P1**: 파트너 프로필 편집 진입점 (Phase 2 — 현재는 "준비 중입니다" SnackBar)
- **P1**: user / partner 양 앱에서 동일 위젯 (kit-shared) — 분기는 props 만

### Non-Goals

- 실제 회원 탈퇴 wizard 흐름 — [`account-deletion`](../account-deletion/) feature 영역
- 실제 본인인증 흐름 (Portone 등) — Certification feature 영역 (별도 spec)
- 파트너 프로필 편집 화면 자체 — Phase 2 별도 spec
- 로그인 / 인증 자체 — [`login-dark-theme`](../login-dark-theme/) feature 와 분리

## Product Principles

1. **destructive 통합**: 위험 액션은 한 곳에 모으되, 실제 확인은 그 다음 단계 화면에서 — 한 화면에 위험 액션을 몰아넣지 않음
2. **신원/destructive 시각 분리**: 같은 페이지지만 그룹 카드로 영역 분리 — 프로필 그룹 (헤더 없음) + "계정 관리" 헤더 그룹 (destructive)
3. **kit-shared, props 분기**: user/partner 동일 UX 골격, 분기 props 가 null 이면 해당 타일이 통째로 빠짐
4. **저장된 데이터 의존 최소화**: 이 화면 자체는 데이터를 fetch 하지 않음 — 부모가 isVerified 만 prop 으로 주입

## Technical Approach

- **화면**: AccountManagementPage (kit-shared StatelessWidget) — user `/my/account`, partner `/more/account`
- **저장**: 없음 — 이 화면 자체는 데이터 변경/저장 X. 로그아웃은 Supabase Auth signOut, 회원 탈퇴는 외부 coordinator
- **외부 의존성**: GoRouter, Supabase Auth (signOut), MinglitAlert.showConfirm (로그아웃 확인 다이얼로그)
- **가드 / 정책**: 비로그인 유저는 이 화면 도달 전에 로그인 화면으로 redirect (라우터 가드)

## User Journey

### Scenario 1: 본인인증 진입 (user, CUJ 1-x)

user 가 마이페이지 → "계정 관리" → 본인인증 타일 탭 → CertificationRoute push. 인증 미완 / 완료 상태에 따라 leading 아이콘 + subtitle 톤이 토글된다.

### Scenario 2: 파트너 프로필 진입 (partner, CUJ 2-x)

partner 가 더보기 → "계정 관리" → 파트너 프로필 타일 탭 → 현재는 "준비 중입니다" SnackBar (Phase 2 빌드 예정).

### Scenario 3: 로그아웃 (CUJ 3-x)

user/partner 모두: "로그아웃" 타일 탭 → 확인 다이얼로그 → "로그아웃" 탭 → signOut → `/login` 로 redirect.

### Scenario 4: 회원 탈퇴 진입 (CUJ 4-x)

user/partner 모두: "회원 탈퇴" 타일 탭 → 추가 확인 없이 외부 coordinator 로 위임 (account-deletion wizard 시작).

## Data Flow

### Scenario 1

MyPage → AccountManagementRoute push → AccountManagementPage 진입 → 본인인증 타일 탭 → onCertification 콜백 → CertificationRoute push.

### Scenario 2

MorePage → PartnerAccountManagementRoute push → AccountManagementPage 진입 → 파트너 프로필 타일 탭 → onPartnerProfile 콜백 → ScaffoldMessenger 가 SnackBar 표시 (Phase 2 에서 실제 화면 push 로 교체).

### Scenario 3

"로그아웃" 타일 탭 → MinglitAlert.showConfirm → "로그아웃" 탭 → authControllerProvider.notifier.signOut() → GoRouter.of(context).go('/') → LoginRoute.

### Scenario 4

"회원 탈퇴" 타일 탭 → onDeleteAccount 콜백 → user: accountDeletionCoordinatorProvider.start() / partner: moreCoordinator.pushAccountDeletion() → account-deletion wizard 1단계 진입.

## KPIs / Success Metrics

- **로그아웃 confirm 취소율**: 다이얼로그 표시 후 "취소" 비율 — 우발적 로그아웃 방지 효과 측정
- **본인인증 진입 → 완료 전환율**: 본인인증 타일 탭 후 실제 인증 완료까지 도달률
- **파트너 프로필 SnackBar 표시 빈도**: Phase 2 우선순위 신호로 활용

## Launch Strategy

별도 A/B 없음 — destructive 통합 / 로그아웃 confirm 은 안전성 의도라 즉시 전체 적용.

## Legal Basis

| 근거 | 내용 |
|------|------|
| 개인정보보호법 제36조 / 제37조 | 회원 탈퇴 경로 제공 — 진입점은 본 페이지, 실제 흐름은 account-deletion |
| Apple App Store Review 5.1.1 (v) / Google Play | 계정 삭제 경로 의무 — 진입점 명시 |
| 개인정보처리방침 | "설정 > 계정 관리에서 탈퇴 가능" 고지 — 본 페이지가 그 surface |

## References

- MDS spec: [`account_management_page`](../../../../apps/mds/docs/public/specs/account_management_page/) — 6 state 디자인 완료
- 관련 PR / 이슈: Fix #1213 (destructive 통합) · Fix #1378 (로그아웃 confirm) · Fix #1861 (본인인증 진입)
- 인접 feature: [`account-deletion`](../account-deletion/) · [`signup-consent`](../signup-consent/) · [`login-dark-theme`](../login-dark-theme/)
