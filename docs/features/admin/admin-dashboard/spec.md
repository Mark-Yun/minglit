# Spec: Admin Console Dashboard

> **참조**
> - PRD: `docs/features/admin/admin-dashboard/prd.md`
> - MDS specs:
>   - `apps/mds/docs/public/specs/admin_console_dashboard/` — Supabase Google OAuth login, admin guard, extensible admin shell
> - Apps:
>   - 계획: `apps/admin/` — Next.js admin console
> - Backend EFs:
>   - P0: 해당 없음 — 서버 route/API 에서 Supabase 세션과 admin membership/capability 검증
> - CUJ tests:
>   - 계획: `apps/admin/e2e/cuj/admin_dashboard.spec.ts`

## Implementation Status

Issue #2559 확인 결과, 이 spec 의 Next.js admin dashboard 는 아직 구현되지 않았다.

| 항목 | 상태 |
|------|------|
| Canonical app path | `apps/admin_web/` |
| Current repo status | 디렉터리/Next.js app 미존재 |
| Existing Flutter admin screens | `apps/app_partner/lib/src/features/admin/` 의 파트너 신청 심사 보조 화면. 이 spec 구현으로 보지 않음 |
| Existing user-app admin harness | `apps/app_user/lib/src/features/admin/` 의 운영/통계 계약 하네스. 이 spec 구현으로 보지 않음 |
| Next implementation step | `apps/admin_web/` scaffold + auth/MFA skeleton + CI/deploy entry 정의 |

## CUJs

| ID  | Priority | CUJ Name | Details | FR | NFR |
|-----|----------|----------|---------|----|----|
| 1-1 | P0 | 비로그인 사용자는 admin 로그인으로 이동 | • `/admin` 직접 접근<br>• Supabase session 없음<br>• admin login 화면 표시<br>• shell/menu/data fetch 미실행 | FR-1, FR-2 | NFR-1, NFR-5 |
| 1-2 | P0 | Supabase Google 로그인 후 admin shell 진입 | • "Google로 로그인" 탭<br>• Supabase OAuth redirect 완료<br>• 서버가 현재 Supabase user 의 admin 권한 확인<br>• 권한 있으면 `/admin` shell 표시 | FR-1, FR-2, FR-3 | NFR-1, NFR-5 |
| 1-3 | P0 | 로그인했지만 admin 이 아닌 사용자는 403 | • Supabase session 은 있음<br>• admin 권한 없음<br>• 403 화면 노출<br>• sidebar/menu/internal data 미노출 | FR-3, FR-4 | NFR-5 |
| 1-4 | P0 | 세션 만료 시 재로그인 요구 | • shell 사용 중 session 만료<br>• 다음 fetch 에서 auth error<br>• admin 데이터를 숨기고 재로그인 안내<br>• 재로그인 후 원래 route 복귀 시도 | FR-5 | NFR-1, NFR-5 |
| 2-1 | P0 | 권한 기반 메뉴 렌더링 | • shell bootstrap<br>• menu registry 와 admin capability 비교<br>• 권한 있는 메뉴만 sidebar 노출<br>• active/coming_soon/hidden 상태 구분 | FR-6, FR-7 | NFR-1, NFR-2 |
| 2-2 | P0 | 사용 가능한 메뉴가 없으면 no-menu 상태 표시 | • admin 권한은 있음<br>• 현재 capability 에 매칭되는 active 메뉴 없음<br>• shell 은 유지하고 content outlet 에 no-menu empty state 표시 | FR-7, FR-8 | NFR-1 |
| 2-3 | P0 | 후속 메뉴 placeholder 는 shell 재작성 없이 연결 가능 | • 새 menu item 정의<br>• route/page/outlet 연결<br>• 공통 page header/loading/error/empty 패턴 재사용 | FR-6, FR-8 | NFR-2 |
| 3-1 | P0 | 권한 없는 메뉴 deep-link 차단 | • `/admin/users` 같은 권한 외 route 직접 접근<br>• capability 재검증<br>• 민감 데이터 fetch 없이 403 또는 no-menu/default 처리 | FR-4, FR-6 | NFR-5 |
| 3-2 | P0 | 권한 변경 후 메뉴/route 갱신 | • 사용 중 admin capability 회수<br>• 다음 route transition 또는 refresh 시 서버 재검증<br>• 기존 menu data 숨김<br>• 403 또는 no-menu 상태 표시 | FR-4, FR-5, FR-6 | NFR-5 |

## Functional Requirements

- **FR-1**: Admin console 은 Supabase Auth Google OAuth 로그인을 허용한다.
- **FR-2**: `/admin` 진입 시 Supabase session 이 없으면 login 화면을 표시한다. 이 상태에서는 admin shell, menu registry, 내부 메뉴 데이터 요청이 발생하지 않는다.
- **FR-3**: 로그인 후 서버가 현재 사용자의 admin membership / role claim 을 확인한다. 클라이언트가 들고 있는 role 문자열만으로 admin 권한을 신뢰하지 않는다.
- **FR-4**: admin 권한이 없거나 route capability 가 부족하면 403 화면을 표시한다. 권한 없는 메뉴명, 내부 데이터, 원본 토큰은 노출하지 않는다.
- **FR-5**: 세션 만료 또는 refresh 실패 시 현재 admin 데이터를 숨기고 재로그인을 요구한다. 재로그인 성공 시 원래 route 로 복귀를 시도한다.
- **FR-6**: 각 admin menu 는 `id`, `label`, `route`, `requiredCapability`, `status`(active / coming_soon / hidden)를 가진다. sidebar 는 capability 와 status 기준으로 렌더링한다.
- **FR-7**: P0 는 특정 기능 board 를 활성 메뉴로 고정하지 않는다. 사용 가능한 active 메뉴가 없으면 no-menu empty state 를 표시한다.
- **FR-8**: Shell 은 공통 AppBar, Sidebar, Breadcrumb, PageHeader, Loading, Empty, Error, 403, SessionExpired state 를 제공한다.

## Non-Functional Requirements

- **NFR-1**: Admin shell first contentful paint 2.5s 이내 (프로덕션 CDN, desktop broadband, p75). Supabase session 확인 포함.
- **NFR-2**: 새 read-only 메뉴 추가 시 shell/auth/permission/layout 공통 코드를 수정하지 않고 menu registry + route/page 추가만으로 연결 가능해야 한다.
- **NFR-3**: Desktop-first layout 은 1280px 이상에서 sidebar + topbar + content outlet 을 한 화면에 유지하고, tablet width 에서는 sidebar collapse 또는 compact state 를 제공한다.
- **NFR-4**: 접근성 — sidebar/menu/dialog/empty/403 state 는 키보드 탐색 가능, 포커스 순서 준수, 색상 대비 4.5:1 이상.
- **NFR-5**: 인증/인가 실패 시 민감 데이터 노출 0건. 서버 API 는 매 요청마다 Supabase session 과 capability 를 검증한다.

## Edge Cases

| CUJ ID | 케이스 | 기대 동작 |
|--------|--------|----------|
| 1-1 | `/admin` deep-link 로 비로그인 접근 | login 화면 표시, OAuth 성공 후 원래 route 복귀 시도 |
| 1-2 | Google OAuth redirect 실패 | login 화면 유지 + "Google 로그인을 완료하지 못했습니다" 에러 |
| 1-3 | 일반 유저가 로그인한 상태로 `/admin` 접근 | 403 화면. sidebar/menu/internal data 미노출 |
| 1-4 | shell outlet 사용 중 세션 만료 | outlet 데이터 숨김, 재로그인 요구 |
| 2-1 | capability 가 하나도 없는 admin role | 403 대신 "사용 가능한 관리자 메뉴가 없습니다" 상태 표시 |
| 2-2 | coming soon 메뉴 클릭 | "준비 중인 메뉴입니다" empty state, route 는 유지 가능 |
| 2-3 | 후속 메뉴 route 는 있으나 page module 이 아직 없음 | shell 은 유지하고 해당 menu 의 unavailable/coming soon state 표시 |
| 3-1 | 숨겨진 route 직접 접근 | 서버 capability 재검증 후 403 |
| 3-2 | 메뉴를 보는 중 권한이 회수됨 | 다음 fetch/transition 에서 데이터 숨김 + 403/no-menu 처리 |

## Open Questions

- [ ] Admin app 위치를 `apps/admin` 으로 확정할지, 기존 landing/admin path 에 얹을지 결정.
- [ ] Supabase admin membership source: JWT custom claim, `admin_members` 테이블, 또는 둘의 조합 중 선택.
- [ ] P1 보안 강화에서 Supabase MFA(TOTP / phone factor)를 언제 켤지 결정.
- [ ] 첫 후속 운영 메뉴를 무엇으로 둘지 결정.
- [ ] Admin MDS spec 작성 시 web Shadcn 스타일을 MDS 토큰으로 감쌀지, 별도 admin design token 을 둘지 결정.

---

## 화면 구성 (참고)

### 정보 구조

```text
Admin Console
├── Login / Admin Guard            P0
├── Shell                          P0
│   ├── Sidebar(menu registry)
│   ├── Topbar(account/sign out)
│   ├── Page header
│   ├── Content outlet
│   └── Shared states
│       ├── Loading
│       ├── Empty / no-menu
│       ├── Error
│       ├── 403
│       └── Session expired
├── Users                          P1 candidate
├── Partners                       P1 candidate
├── Payments / Refunds             P1 candidate
├── Settlements                    P1 candidate
├── System                         P1 candidate
└── Audit Logs                     P1 candidate
```

### 화면 1: Login / Admin Guard

| State | 조건 | 표시 |
|-------|------|------|
| Login | Supabase session 없음 | "Google로 로그인" button |
| OAuth callback | Google OAuth redirect 완료 | session exchange + redirect |
| Checking role | session 확보, admin 권한 조회 중 | centered progress + "권한을 확인하고 있습니다" |
| 403 | session 있음, admin 권한 없음 | 권한 없음 설명 + sign out |
| Expired | 사용 중 session 만료 | 재로그인 CTA |

### 화면 2: Admin Shell

| 영역 | 표시 |
|------|------|
| Sidebar | 권한 있는 메뉴만 표시. active/coming soon/hidden 상태 구분 |
| Top bar | admin account, sign out, global action slot |
| Page header | title, subtitle, last updated/action slot |
| Content | 활성 메뉴 page 또는 no-menu empty state |
| Shared states | loading, empty, error, 403, session expired |

### Data Definitions

| 항목 | 설명 |
|------|------|
| Admin identity | Supabase Auth user + server-verified admin membership |
| Capability | 메뉴/route/action 접근 권한. 예: `admin.users.read`, `admin.system.read` |
| Menu registry | Admin menu metadata 와 route/page contract 의 source |
| No-menu state | admin 권한은 있으나 접근 가능한 active 메뉴가 없는 shell empty state |
