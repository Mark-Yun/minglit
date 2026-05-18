# Spec: 로그인 다크 테마 일관성

> **참조**
> - PRD: [prd.md](./prd.md)
> - MDS specs:
>   - [`login_page`](../../../../apps/mds/docs/public/specs/login_page/) — 사용자 앱 LoginPage (4 state, light/dark cross-cutting)
>   - [`partner_login_page`](../../../../apps/mds/docs/public/specs/partner_login_page/) — 파트너 앱 PartnerLoginPage (4 state, 파트너 인디고)
> - Wireframe: [wireframe.html](./wireframe.html) — Fix #1542 before/after 시각 비교

## CUJs

| ID  | Priority | CUJ Name | Details | FR | NFR |
|-----|----------|----------|---------|----|----|
| 1-1 | P0 | 다크 모드 진입 시 Scaffold 배경 일관 | • 시스템 다크 모드<br>• 로그인 화면 진입<br>• Scaffold bg = #0F0F0F (홈과 동일) | FR-1 | NFR-1 |
| 1-2 | P0 | 다크 모드에서 Google 버튼 다크 변형 | • 다크 모드<br>• Google 버튼: bg #212121 · 흰 글자 · 보더 outlineVariant | FR-2 | NFR-1, NFR-3 |
| 1-3 | P0 | 다크 모드에서 Apple 버튼 white-on-dark 변형 | • 다크 모드<br>• Apple 버튼: 흰 바탕 · 검정 글자 (Apple HIG 다크 변형) | FR-3 | NFR-1, NFR-3 |
| 1-4 | P0 | 다크 모드에서 Kakao 노랑 고정 | • 다크 모드<br>• Kakao 버튼: bg #FEE500 (테마 무관) · near-black 글자 | FR-4 | NFR-3 |
| 2-1 | P0 | 라이트 모드 baseline (회귀 없음) | • 시스템 라이트 모드<br>• 기존 동작 그대로 — Scaffold #F9FAFB · Google 흰 바탕 · Apple 검정 바탕 · Kakao 노랑 | FR-1, FR-2, FR-3, FR-4 | NFR-1 |
| 3-1 | P0 | 보호 경로 redirect 시 깜빡임 제거 | • 다크 모드<br>• 보호 경로 진입 (비인증)<br>• 홈 → 로그인 redirect 시 같은 #0F0F0F 배경 유지 | FR-1, FR-5 | NFR-2 |
| 4-1 | P0 | 다크 골든 시나리오 등록 | • `login_scenarios.dart` 에 Brightness.dark 시나리오 추가<br>• CI 에서 `login_page_default_dark.png` 검증<br>• 후속 시각 회귀 차단 | FR-6 | — |
| 4-2 | P1 | partner 다크 골든 시나리오 등록 | • partner_login_scenarios.dart (또는 동등) 에 다크 시나리오<br>• PARTNER 배지 + 파트너 인디고가 다크 톤으로 자동 전환되는지 검증 | FR-7 | — |
| 5-1 | P1 | 실행 중 시스템 테마 토글 시 즉시 반영 | • 로그인 화면 노출 중 OS 테마 토글<br>• Scaffold + OAuth 버튼이 즉시 다크/라이트 변형 교체 (재진입 불필요) | FR-1, FR-2, FR-3 | NFR-4 |

## Functional Requirements

- **FR-1**: LoginPage 의 Scaffold 는 `theme.scaffoldBackgroundColor` 를 사용한다. `MinglitColors.background` 하드코딩 금지. 라이트 `#F9FAFB`, 다크 `#0F0F0F` (홈과 동일).
- **FR-2**: Google OAuth 버튼은 라이트/다크 변형. 라이트: 흰 바탕 + near-black 글자 + `outlineVariant` 보더. 다크: `#212121` + 흰 글자 + `outlineVariant` (다크 톤) 보더.
- **FR-3**: Apple OAuth 버튼은 Apple HIG 변형. 라이트: 검정 바탕 + 흰 글자. 다크: 흰 바탕 + 검정 글자 (Apple "white on dark").
- **FR-4**: Kakao OAuth 버튼은 테마 무관 `#FEE500` 바탕 + near-black 글자. 다크 모드에서도 변경 없음 (Kakao 브랜드 가이드).
- **FR-5**: 보호 경로 redirect 시 (홈 → 로그인) Scaffold 배경이 같은 톤을 유지 — 별도 fade / overlay 처리 없이 GoRouter 기본 전환만 사용.
- **FR-6**: `login_scenarios.dart` 에 Brightness.dark 변형을 추가하고 `login_page_default_dark.png` golden 을 등록. CI 에서 시각 변경 시 fail.
- **FR-7**: 동일한 다크 시나리오를 partner 변형 (MinglitLoginScreen(isPartner:true)) 에도 등록. PARTNER 배지 + "파트너 입점 문의" CTA 가 다크 톤 파트너 인디고로 자동 전환되는지 검증.

## Non-Functional Requirements

- **NFR-1**: 화면 진입 → first paint 200ms 이내 (에뮬레이터 baseline, p50 기준). 테마 read 추가로 인한 지연 없음.
- **NFR-2**: 다크 모드에서 redirect 시 별도 깜빡임 / flash 0 frames — 즉 같은 frame 에 같은 톤 배경.
- **NFR-3**: 접근성 — 다크 / 라이트 변형 모두 OAuth 버튼 텍스트 ↔ 배경 contrast ratio ≥ 4.5:1 (WCAG AA). Kakao 도 동일 (노랑 + near-black 으로 ≥ 4.5 만족).
- **NFR-4**: 시스템 테마 토글 후 UI 반영 100ms 이내 (Material rebuild, p50). 사용자가 토글하면 화면 떠 있는 동안에도 즉시 변형 교체.

## Edge Cases

| CUJ ID | 케이스 | 기대 동작 |
|--------|--------|----------|
| 1-1 | 시스템 다크 모드 + 사용자 정의 wallpaper / color | Scaffold 는 무조건 `#0F0F0F` (홈 일관). 사용자 정의 wallpaper 영향 X |
| 1-2 | 다크 모드 + Google 보더 색 다크 톤 미정의 | `outlineVariant` 토큰의 다크 변형 사용 — material color scheme 기본값에 위임 |
| 1-3 | iOS / macOS / Web 에서 Apple 버튼 노출 (다크) | white-on-dark Apple 변형 적용. Android 는 Apple 버튼 미노출 (기존 정책 유지) |
| 1-4 | 다크 모드에서 Kakao 노랑 색약 사용자 | Kakao 브랜드 강제 — 별도 처리 X. WCAG 는 글자 색 (near-black) 으로 보장 |
| 3-1 | 보호 경로 redirect 도중 시스템 테마 토글 | 새 테마로 즉시 redirect 도착 (race 없음 — MaterialApp 가 단일 source) |
| 4-1 | 골든 등록 후 다크 모드에서 fontFamily 변경 | golden 재생성 필요 — PR 본문에 명시 |
| 5-1 | 시스템 테마 토글 도중 OAuth 인증 외부 페이지 떠 있음 | OS / 외부 페이지 영역은 OS 가 처리. 복귀 시 in-app 테마는 새 모드로 반영 |

## Open Questions

- [ ] **시스템 테마 외 in-app 토글 지원** — 현재 시스템 추종만. 향후 별도 PR 에서 사용자 토글 추가 시 본 spec 의 FR 도 갱신
- [ ] **partner 인디고 다크 변형 토큰** — `color-partner-primary` 의 다크 변형이 토큰 시스템에 등록돼 있는지 검증 필요 (디자인 시스템 확장 가능성)
- [ ] **Kakao 노랑 다크 톤 우회 가능성** — 일부 다크 OS 에서 노랑이 지나치게 튀어 보이는 피드백 시 별도 검토 (현재는 브랜드 정책 그대로)

---

## 화면 구성 (참고)

> MDS spec [`login_page`](../../../../apps/mds/docs/public/specs/login_page/) 이 SSoT — 본 섹션은 derived. Fix #1542 wireframe.html 의 before/after 시각 비교 참조.

### 화면 1: LoginPage / PartnerLoginPage

**표시 시점**: 앱 첫 실행 / 로그아웃 직후 / 보호 경로 비인증 redirect.

**레이아웃** (라이트 baseline · 변경 X):

```
┌────────────────────────────┐
│       Spacer (flex 1)      │
│   ┌────────────────────┐   │
│   │   Logo (64px h)    │   │
│   │   PARTNER 배지       │   │ ← partner only
│   │   Slogan (textSec) │   │
│   └────────────────────┘   │
│       Spacer (flex 1)      │
│   ┌────────────────────┐   │
│   │  Google (h48)      │   │ ← 라이트: 흰바탕 · 다크: #212121
│   │  Apple (h48, cond) │   │ ← 라이트: 검정 · 다크: 흰바탕
│   │  Kakao (h48)       │   │ ← 항상 #FEE500
│   └────────────────────┘   │
│   Terms / Partner CTA      │
│   Bottom safe area         │
└────────────────────────────┘
```

### 색 토큰 변경 요약 (라이트 / 다크)

| 영역 | 라이트 | 다크 | 출처 |
|------|--------|------|------|
| Scaffold bg | `#F9FAFB` (color-surface) | `#0F0F0F` (홈과 동일) | `theme.scaffoldBackgroundColor` |
| Google bg | `#FFFFFF` | `#212121` | brand-locked 변형 (Google 가이드) |
| Google border | `color-divider` | `outlineVariant` (다크) | theme.colorScheme.outlineVariant |
| Google text | near-black | 흰색 | brand-locked |
| Apple bg | 검정 (`#111827`) | 흰 (`#FFFFFF`) | Apple HIG "white on dark" |
| Apple text | 흰 | 검정 | brand-locked |
| Kakao bg | `#FEE500` | `#FEE500` (고정) | Kakao 브랜드 가이드 |
| Kakao text | near-black | near-black (고정) | brand-locked |
| Slogan / Terms | `theme.colorScheme.outline` / `theme.textTheme` | 동일 (자동 톤 전환) | 기존 토큰 (변경 없음) |
| PARTNER 배지 (partner) | `color-partner-primary` (#6c3ce1) | 다크 톤 파트너 인디고 | theme scoped |

### 테스트 정의 (참고)

| 항목 | 위치 | 설명 |
|------|------|------|
| 라이트 golden | `login_scenarios.dart` → Brightness.light | 기존 `login_page_default.png` 유지 |
| 다크 golden (user) | 신규 `login_scenarios.dart` → Brightness.dark | 신규 `login_page_default_dark.png` |
| 다크 golden (partner) | partner 측 scenarios | 신규 (FR-7) |
| 토큰 단위 unit | scaffoldBackgroundColor / OAuth 버튼 색 read 검증 | 회귀 시 즉시 fail |
