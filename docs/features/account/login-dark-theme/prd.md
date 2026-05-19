# PRD: 로그인 다크 테마 일관성 (Login Dark Theme Consistency)

## Summary

보호 경로에서 로그인 화면으로 리다이렉트될 때 발생하는 다크→라이트 깜빡임을 제거. Scaffold 배경과 Google·Apple OAuth 버튼 색상을 시스템 테마에 연동, Kakao 는 브랜드 가이드라인에 따라 노랑 고정. 사용자 / 파트너 양 앱이 공유하는 MinglitLoginScreen 위젯에 적용. Fix #1542.

## Motivation / Problem to Solve

- 보호된 화면에서 비인증 redirect → 로그인 화면 진입 시, 홈 (다크 #0F0F0F) 과 로그인 (하드코딩 흰색) 사이 시각적 깜빡임 발생 (Fix #1542 의 root cause)
- LoginPage 의 Scaffold 배경이 `MinglitColors.background` 로 하드코딩되어 다크 모드 미지원
- Google / Apple OAuth 버튼이 라이트 변형만 사용 — 다크 모드 가독성 / 디자인 일관성 저하
- 회귀 방지: 다크 모드 시나리오의 golden test 부재 — 다음에도 비슷한 regression 발생 위험

## Goals

### Target Users

- **모든 사용자**: 다크 모드를 사용하는 user / partner. 비인증 상태로 보호 경로에 진입하다 로그인으로 redirect 되는 시점에 깜빡임 인지
- **디자인 시스템**: scaffold 배경 / OAuth 버튼 색을 토큰화해서 향후 컬러 변경 시 단일 지점 수정

### Key Goals

- **P0**: Scaffold 배경을 `theme.scaffoldBackgroundColor` 로 변경 — 라이트 `#F9FAFB` (홈과 동일 surface) / 다크 `#0F0F0F` (홈과 동일 배경)
- **P0**: Google 버튼 라이트/다크 변형 — 다크는 `#212121` (surface dark) + 흰 글자, 보더는 `outlineVariant` 토큰
- **P0**: Apple 버튼 라이트/다크 변형 — Apple HIG 의 "white on dark" 변형 (다크 시 흰 바탕 + 검정 글자)
- **P0**: Kakao 버튼은 테마 무관 노랑 고정 (`#FEE500` · 브랜드 가이드라인)
- **P0**: golden test 에 다크 시나리오 추가 (`login_scenarios.dart` → Brightness.dark · `login_page_default_dark.png`)
- **P1**: 동일 변경을 partner 앱 (PartnerLoginPage / MinglitLoginScreen(isPartner:true)) 에도 적용 — 같은 위젯 공유

### Non-Goals

- 라이트/다크 외 사용자 정의 테마 (현재 미지원)
- OAuth 버튼의 brand-locked 정책 변경 (Kakao 노랑 고정 유지)
- 시스템 테마 자동 추종 외 별도 in-app 테마 토글 (별도 PR)
- 로그인 자체 로직 / OAuth 흐름 변경 — [`account-management`](../account-management/) · [`signup-consent`](../signup-consent/) 영역과 분리

## Product Principles

1. **테마 토큰 사용**: 하드코딩된 색 제거, `theme.colorScheme` / `theme.scaffoldBackgroundColor` 사용 — 향후 컬러 변경 단일 지점
2. **brand-locked 예외 명시**: Kakao 노랑은 의도된 예외 — 코드 / spec 양쪽에 근거 명시
3. **회귀 방지 골든**: 시각 회귀는 골든 테스트로 차단 — 라이트 / 다크 모두 시나리오 등록
4. **kit-shared 일관성**: user / partner 동일 위젯 공유 — isPartner props 분기는 색 토큰만 다름 (라이트 보라 / 파트너 인디고)

## Technical Approach

- **화면**: LoginPage (user) · PartnerLoginPage (partner) — 양쪽 모두 MinglitLoginScreen (kit-shared) 사용
- **저장**: 없음 — 본 feature 는 시각만 변경
- **외부 의존성**: ThemeData / MaterialApp.theme — `theme.brightness` · `theme.colorScheme`. OAuth provider SDK 자체는 변경 없음
- **가드 / 정책**: 없음 — 시각 변경만
- **테스트**: `login_scenarios.dart` 에 Brightness.dark 시나리오 추가, golden snapshot 갱신

## User Journey

### Scenario 1: 다크 모드 환경에서 로그인 진입 (CUJ 1-x)

다크 모드 사용자가 앱 첫 실행 / 로그아웃 직후 / 보호 경로 redirect 로 로그인 화면 진입 — Scaffold 배경 / Google · Apple 버튼이 다크 변형으로 즉시 노출, Kakao 만 노랑.

### Scenario 2: 라이트 모드 환경에서 로그인 진입 (CUJ 2-x)

라이트 모드 사용자가 동일 진입 — Scaffold `#F9FAFB`, Google · Apple 버튼 라이트 변형, Kakao 노랑. (baseline 동일 — 기존 동작 보존)

### Scenario 3: 보호 경로 redirect (CUJ 3-x)

다크 모드 사용자가 비인증 상태로 보호 경로 진입 → 로그인 화면 redirect — 홈 (#0F0F0F) → 로그인 (#0F0F0F) 으로 같은 배경 톤 유지, 깜빡임 제거.

## Data Flow

### Scenario 1 / 2

App 시작 → 시스템 brightness 감지 → MaterialApp theme 적용 → LoginPage 진입 → Scaffold + buttons 가 theme 에서 색 read → 렌더링.

### Scenario 3

보호 경로 navigate → router redirect → LoginPage push → 직전 화면 (홈, 다크) 과 동일 scaffold bg 로 시각 연속성 유지.

## KPIs / Success Metrics

- **시각 회귀 차단**: 다크 골든 (`login_page_default_dark.png`) 추가 후 CI 에서 변경 감지율 100%
- **다크 모드 사용자 비율**: 측정 baseline 확보 후 다크 / 라이트 진입 비율 추적 (별도 분석 항목)
- **OAuth 진입 전환율 변화**: 다크 변형 적용 전후 OAuth 버튼 탭 비율 변화 없음을 확인 (시각만 바뀌어야 함)

## Launch Strategy

별도 A/B 없음 — 시각 일관성 / 회귀 방지 목적이라 즉시 전체 적용.

## Legal Basis

해당 없음 — 시각 변경.

## References

- MDS spec: [`login_page`](../../../../apps/mds/docs/public/specs/login_page/) — 4 state 디자인 완료, 다크 모드 토글이 cross-cutting 으로 정의됨
- MDS spec: [`partner_login_page`](../../../../apps/mds/docs/public/specs/partner_login_page/) — partner 변형 (PARTNER 배지 + 파트너 인디고)
- 관련 이슈: Fix #1542 (로그인 다크 테마 일관성)
- 외부 가이드: Google Sign-In 브랜드 가이드 (light/dark variants 허용) · Apple HIG Sign In with Apple (white on dark) · Kakao 브랜드 가이드 (노랑 고정)
