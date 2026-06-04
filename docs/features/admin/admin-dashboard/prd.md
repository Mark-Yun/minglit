# PRD: Admin Console Dashboard

## Summary

Minglit 내부 운영자가 Supabase Google 로그인으로 본인 확인을 마친 뒤, 서버에서 검증된 admin 권한에 따라 관리자 메뉴를 사용하는 웹 기반 admin console. 현재 출시 범위는 admin 로그인, 권한 확인, 확장 가능한 shell/menu 구조까지다. 기능 dashboard 는 후속 메뉴로 분리하고, 이번 범위에서는 별도 board/spec 를 만들지 않는다.

## Implementation Status

> Issue #2559 기준 현황 정리.

- 전용 Next.js admin dashboard 앱은 아직 모노레포에 없다. `apps/admin_web/` 이 canonical target 이지만 scaffold 전 상태다.
- `apps/app_partner/lib/src/features/admin/` 은 파트너 앱 내부의 입점 신청 심사 보조 화면이다. 이 PRD 의 Next.js admin console 구현으로 간주하지 않는다.
- `apps/app_user/lib/src/features/admin/` 은 운영/통계 계약 하네스 성격이며, admin-dashboard 제품 구현 대상이 아니다.
- 따라서 이 PRD 의 구현 상태는 **planned / unscaffolded** 이다. 구현 착수 PR 은 `apps/admin_web/` scaffold, `apps/BLUEDOC.md` 갱신, 배포/CI 엔트리 정의를 함께 포함해야 한다.

## Motivation / Problem to Solve

- admin 기능을 메뉴별로 추가할 기준 shell 이 없어, 기능이 늘수록 인증/권한/네비게이션/에러 UX 가 중복될 위험이 있다.
- admin 접근은 일반 앱 로그인과 분리하지 않되, Supabase Auth 세션과 서버 admin 권한 확인을 모두 통과해야 한다.
- 첫 메뉴가 무엇이든 동일한 shell contract, route guard, empty/403/session-expired state 를 재사용할 수 있어야 한다.

## Goals

### Target Users

- **Super Admin**: 모든 admin 메뉴 접근 가능. 향후 유저/파트너/정산/시스템 메뉴까지 관리.
- **Read-only Admin**: 부여된 메뉴를 조회하지만 destructive action 은 수행하지 않음.
- **Ops Admin**: 향후 운영 현황, 배포, 심사, 정산 같은 메뉴를 필요 권한에 따라 사용.

### Key Goals

- **P0**: Supabase Auth Google OAuth 로그인 후 admin 권한 확인. 비로그인 / 비관리자는 admin shell 진입 차단.
- **P0**: 확장 가능한 admin shell. 사이드바 메뉴는 registry 기반으로 추가 가능하고, 각 메뉴는 role / capability 로 노출 여부를 결정한다.
- **P0**: admin shell 은 메뉴 추가 시 인증/권한/레이아웃/로딩/빈 상태/에러 패턴을 재사용한다.
- **P0**: 아직 활성 메뉴가 없거나 사용자가 접근 가능한 메뉴가 없을 때 명확한 empty / no-menu 상태를 제공한다.
- **P1**: 운영 메뉴 추가: 유저 관리, 파트너 심사, 환불/정산, 감사 로그, 시스템 설정.

### Non-Goals

- P0 에서 기능별 운영 dashboard 를 구현하지 않는다.
- P0 에서 GitHub Actions UI, Vercel UI, Supabase console 을 대체하지 않는다.
- Supabase service_role key 를 클라이언트에 노출하지 않는다. admin 권한 확인과 외부 API proxy 는 서버에서만 수행한다.
- 모바일 admin 앱을 만들지 않는다. 데스크톱 웹 우선, 태블릿은 최소 반응형만 지원한다.

## Product Principles

1. **Auth first**: 모든 `/admin` route 는 Supabase 세션 확인 후 admin 권한 확인을 통과해야 한다.
2. **Extensible shell**: 새 기능은 메뉴 모듈로 추가한다. shell 은 nav, page header, permission guard, loading/error, empty state 를 공통 제공한다.
3. **Server-verified admin**: 클라이언트 role 문자열만으로 admin 권한을 신뢰하지 않는다.
4. **No leaked menu data**: 권한이 없는 사용자는 메뉴명, route detail, 내부 데이터, 원본 토큰을 보지 못한다.
5. **Deferred feature screens**: 기능 화면은 별도 screen/spec 로 정의되는 시점에 shell outlet 에 연결한다.

## Technical Approach

- **앱**: 별도 Next.js admin app (`apps/admin` 예정). desktop-first admin UI.
- **인증**: Supabase Auth Google OAuth 로그인. 서버에서 현재 세션의 user 를 확인하고 admin membership / role claim 을 조회한다.
- **인가**: 메뉴 및 route 는 capability 기반으로 가드한다. 예: `admin.users.read`, `admin.partners.review`, `admin.system.read`.
- **메뉴 registry**: 각 메뉴는 `id`, `label`, `route`, `requiredCapability`, `status`, `loader/error/empty` contract 를 가진다.
- **보안 정책**: 클라이언트는 publishable anon key 와 session 만 사용. service_role, GitHub, Vercel token 은 서버 런타임에서만 사용한다.
- **후속 데이터 소스**: user management, partner review, system operations 등 feature menu 가 확정될 때 각 메뉴의 server loader 에서 별도 정의한다.

## User Journey

### Scenario 1: Admin 로그인과 권한 확인 (CUJ 1-x)

운영자가 `/admin` 접속 → Supabase Google 로그인 → 서버가 admin 권한 확인 → 권한 있으면 admin shell 진입, 권한 없으면 403 화면.

### Scenario 2: Admin shell 과 메뉴 확장 구조 확인 (CUJ 2-x)

운영자가 admin shell 에 진입 → 서버가 capability set 생성 → 사이드바는 권한 있는 메뉴만 표시 → 아직 활성 메뉴가 없으면 shell empty state 를 표시 → 향후 메뉴가 같은 레이아웃과 route guard 로 추가됨.

### Scenario 3: 권한 없는 메뉴 접근 차단 (CUJ 3-x)

운영자가 직접 route 로 접근하거나 메뉴 권한이 변경됨 → 서버가 route capability 를 재검증 → 권한 없으면 403 또는 접근 가능한 기본 메뉴/no-menu 상태로 전환.

## Data Flow

### Scenario 1

`/admin` 진입 → Supabase session 확인 → 없으면 login → Google OAuth callback → 서버에서 admin membership / role 조회 → capability set 생성 → shell 렌더링 또는 403.

### Scenario 2

Shell bootstrap → menu registry 로드 → 현재 admin capability 와 매칭 → 노출 가능한 메뉴만 sidebar 에 렌더링 → 활성 메뉴가 없으면 no-menu empty state 표시.

### Scenario 3

Deep-link 또는 메뉴 이동 → route capability 서버 재검증 → 허용 시 해당 menu outlet 렌더링 → 거부 시 민감 데이터 fetch 없이 403/no-menu 처리.

## KPIs / Success Metrics

- **권한 차단 정확성**: 비관리자 admin shell 접근 0건.
- **메뉴 추가 비용**: 새 read-only admin 메뉴 추가 시 shell/auth/permission 코드 재작성 없음.
- **로그인 성공률**: Google OAuth callback 이후 admin 권한 확인 성공/실패 상태가 100% 명확히 분기.
- **민감 데이터 노출**: 인증/인가 실패 경로에서 내부 메뉴 데이터 및 server token 노출 0건.

## Launch Strategy

1. **P0-A**: admin shell + Supabase Google login/admin guard + 403/expired-session/no-menu state.
2. **P0-B**: menu registry + capability 기반 sidebar/outlet contract.
3. **P1**: 첫 후속 운영 메뉴를 별도 spec/board 로 작성.
4. **P1+**: 유저 관리, 파트너 심사, 환불/정산, 시스템 설정, 감사 로그를 메뉴 모듈로 순차 추가.

## Legal / Security Basis

| 근거 | 내용 |
|------|------|
| 개인정보보호법 제29조 | 관리자 접근 제어, 권한 분리, 접속 기록 관리 |
| 내부 운영 보안 | Supabase Auth 세션 + admin membership 확인 없이는 admin route 접근 금지 |
| 최소 권한 원칙 | read-only / write capability 분리, 메뉴별 접근 제한 |
| 감사 가능성 | 후속 write action 부터 수행자 / 시각 / 대상 / 결과 기록 |

## References

- `apps/mds/docs/public/specs/admin_console_dashboard/` — admin login + shell MDS spec
- Supabase Auth Google OAuth docs — admin login provider
- Supabase Auth MFA docs — 후속 보안 강화 후보
- `docs/features/admin/statistics-tools/` — 기존 analytics / alert 도구와 후속 연계
