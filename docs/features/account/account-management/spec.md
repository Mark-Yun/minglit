# Spec: 계정 관리

> **참조**
> - PRD: [prd.md](./prd.md)
> - MDS specs:
>   - [`account_management_page`](../../../../apps/mds/docs/public/specs/account_management_page/) — 계정 관리 서브 페이지 (6 state, kit-shared user+partner)
> - Wireframe: [wireframe.html](./wireframe.html) (구형 — MDS spec 이 SSoT)

## CUJs

| ID  | Priority | CUJ Name | Details | FR | NFR |
|-----|----------|----------|---------|----|----|
| 1-1 | P0 | (user) 본인인증 미완 상태에서 진입 | • MyPage → "계정 관리" 타일 탭<br>• ProfileGroup 카드 안 "본인인증" 타일 노출 (subtitle "인증하기")<br>• 본인인증 타일 탭 → CertificationRoute push | FR-1, FR-2, FR-3 | NFR-1 |
| 1-2 | P0 | (user) 본인인증 완료 상태에서 진입 | • 동일 진입<br>• 본인인증 타일: leading verified_user · subtitle "인증 완료" (success 톤)<br>• 탭 가능 (다시 들어가도 막지 않음) | FR-2, FR-3 | NFR-1 |
| 1-3 | P1 | (user) 본인인증 상태 외부 변경 즉시 반영 | • 화면이 떠 있는 동안 인증 완료됨<br>• leading icon + subtitle 이 success 톤으로 즉시 교체 (깜빡임 없음) | FR-4 | NFR-2 |
| 2-1 | P0 | (partner) 더보기 → 계정 관리 진입 | • MorePage → "계정 관리" 타일 탭<br>• ProfileGroup 카드 안 "파트너 프로필" 타일 노출 (본인인증 미노출)<br>• "계정 관리" 헤더 그룹은 user 와 동일 | FR-5, FR-7 | NFR-1 |
| 2-2 | P1 | (partner) 파트너 프로필 타일 탭 → SnackBar | • 파트너 프로필 타일 탭<br>• "준비 중입니다." SnackBar 표시 (비차단)<br>• 화면 이동 X (Phase 2 에서 실제 화면 push 로 교체 예정) | FR-6 | NFR-3 |
| 3-1 | P0 | 로그아웃 confirm 후 로그인 화면 복귀 | • "로그아웃" 타일 탭<br>• MinglitAlert.showConfirm 다이얼로그 표시<br>• "로그아웃" 탭 → signOut → `/login` redirect | FR-8, FR-9 | NFR-1, NFR-2 |
| 3-2 | P0 | 로그아웃 confirm 취소 | • 다이얼로그에서 "취소" 탭 또는 scrim/뒤로 가기<br>• 다이얼로그만 닫힘 — 로그아웃 진행 X | FR-8 | NFR-1 |
| 4-1 | P0 | 회원 탈퇴 진입 (추가 확인 없이) | • "회원 탈퇴" 타일 탭 (destructive 톤 — error color)<br>• 추가 confirm 없이 외부 coordinator 호출<br>• account-deletion wizard 1단계 진입 | FR-10 | NFR-1 |
| 4-2 | P0 | 뒤로 가기 → 부모 페이지 복귀 | • AppBar back 또는 시스템 back<br>• user → MyPage / partner → MorePage 복귀 | FR-11 | NFR-1 |

## Functional Requirements

> 제품 행동 정의 — 실제 라우트 path 나 Provider 이름은 MDS spec / 코드에서 SSoT.

- **FR-1**: 본인인증 타일은 user 모드에서만 노출. partner 모드에서는 통째로 빠진다 (분기 props null).
- **FR-2**: 본인인증 타일은 `isVerified` 상태에 따라 leading 아이콘 (shield_outlined / verified_user) + subtitle text ("인증하기" / "인증 완료") + 색 (textSecondary / success) 이 토글된다.
- **FR-3**: 본인인증 타일 탭 시 CertificationRoute 로 push. 인증 완료 상태에서 탭해도 진입 가능 (다시 들어가도 막지 않음).
- **FR-4**: 본인인증 상태가 외부에서 변경되면 (다른 화면에서 인증 완료) 이 화면이 떠 있는 동안 깜빡임 없이 즉시 success 톤으로 교체된다.
- **FR-5**: 파트너 프로필 타일은 partner 모드에서만 노출. user 모드에서는 통째로 빠진다.
- **FR-6**: 파트너 프로필 타일 탭 시 (현재 Phase 1) "준비 중입니다." SnackBar 표시. 화면 이동 없음. Phase 2 에서 실제 편집 화면 push 로 교체.
- **FR-7**: ProfileGroup 카드는 user/partner 양쪽에서 헤더 없음 (페이지 타이틀과 의미가 겹침). 분기 props 가 모두 null 이면 카드 자체 미렌더.
- **FR-8**: 로그아웃 타일 탭 시 MinglitAlert.showConfirm 다이얼로그 표시. 다이얼로그의 확인 버튼은 일반 강조 색 (위험 강조 X — 복구 가능 행위).
- **FR-9**: 다이얼로그 확인 시 authControllerProvider.notifier.signOut() 호출 후 GoRouter.go('/') 로 로그인 화면 redirect. 토큰/세션 저장소 모두 정리.
- **FR-10**: 회원 탈퇴 타일은 destructive variant — leading icon + title 모두 color-error. 탭 시 추가 confirm 없이 외부 coordinator (user: accountDeletionCoordinator.start() / partner: moreCoordinator.pushAccountDeletion()) 로 위임.
- **FR-11**: AppBar back / 시스템 back 으로 부모 페이지 복귀 (user → MyPage / partner → MorePage).

## Non-Functional Requirements

- **NFR-1**: 화면 진입 → first paint 200ms 이내 (에뮬레이터 baseline, p50 기준). 이 화면은 데이터 fetch 없음.
- **NFR-2**: 본인인증 상태 변경 → UI 반영 100ms 이내 (Riverpod rebuild, p50). 깜빡임 / placeholder 없음.
- **NFR-3**: SnackBar 표시 시 다른 타일 탭 차단 X (비차단). SnackBar 자체는 250ms motion (MinglitAnimation).
- **NFR-4**: 접근성 — 모든 타일 최소 터치 영역 48dp · semanticsLabel + leading icon · 확인 다이얼로그 키보드 트랩 / esc dismiss 지원.

## Edge Cases

| CUJ ID | 케이스 | 기대 동작 |
|--------|--------|----------|
| 1-1 | currentUserProfile 가 still loading | 화면 즉시 노출, 본인인증 타일은 "인증하기" 기본값 (안전 default) |
| 1-1 | currentUserProfile fetch 실패 | 화면 즉시 노출, "인증하기" 기본값 — 이 화면에서 별도 에러 처리 X |
| 1-3 | 외부 변경 도중 화면 떠 있음 | provider rebuild 만으로 즉시 success 톤 교체 (깜빡임 X) |
| 2-2 | SnackBar 표시 중 다른 타일 탭 | SnackBar 비차단 — 다른 액션 정상 동작 |
| 2-2 | 파트너 프로필 빠르게 여러 번 탭 | SnackBar 가 차례로 쌓여 노출 (현재 미차단) |
| 3-1 | 다이얼로그 떠 있는 동안 앱 background → foreground | 다이얼로그 유지 (state 보존) |
| 3-1 | signOut 도중 네트워크 끊김 | 로컬 세션 storage 는 정리됨 (서버 미반영 시 다음 요청 시 401 → /login redirect) |
| 3-2 | 다이얼로그 scrim 탭 | "취소" 와 동일 처리 — 다이얼로그만 닫힘 |
| 3-2 | 시스템 back | "취소" 와 동일 처리 |
| 4-1 | 회원 탈퇴 도중 앱 kill | 외부 coordinator wizard 가 자체 state 보존 (account-deletion 영역) |

## Open Questions

- [ ] **파트너 프로필 Phase 2 timing** — Phase 2 빌드 진행 우선순위 결정 필요 (현재 SnackBar placeholder)
- [ ] **본인인증 재진입 정책** — 인증 완료 후 다시 탭하면 진입 가능 (현 spec) vs 막기? (UX 마찰)
- [ ] **로그아웃 후 짧은 전환 구간 (State 5) 의 입력 차단** — 현재는 무시 처리, 별도 오버레이 안 띄움. 사용자 인식 차이 측정 필요?

---

## 화면 구성 (참고)

> dev 가 아닌 product/UX detail. MDS spec [`account_management_page`](../../../../apps/mds/docs/public/specs/account_management_page/) 이 SSoT — 본 섹션은 derived view.

### 화면 1: 계정 관리 (AccountManagementPage)

**표시 시점**: user — MyPage "계정 관리" 타일 탭 / partner — MorePage "계정 관리" 타일 탭.

**레이아웃** (위→아래):

```
┌──────────────────────────────────┐
│  ←  계정 관리                    │ ← AppBar (title + back)
├──────────────────────────────────┤
│                                  │
│  ┌────────────────────────────┐  │
│  │ 본인인증            인증하기 → │ ← (user only · ProfileGroup 카드 · 헤더 없음)
│  │ 파트너 프로필             → │ ← (partner only · 동일 카드)
│  └────────────────────────────┘  │
│                                  │
│  계정 관리                       │ ← 그룹 헤더 (uppercase · 13/500 · letter-spacing 0.5)
│  ┌────────────────────────────┐  │
│  │ 로그아웃                    │ ← 일반 톤
│  │ ─────────────────────────  │ ← indent 52 hairline divider
│  │ 회원 탈퇴                   │ ← destructive (leading + title color-error)
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

### State 변형 (MDS spec 요약)

| State | 조건 | 변화 |
|-------|------|------|
| 1. User · 본인인증 미완 (🎯 baseline) | user 진입, isVerified=false | 본인인증 "인증하기" subtitle, shield_outlined leading |
| 2. User · 본인인증 완료 | user 진입, isVerified=true | leading verified_user (success), subtitle "인증 완료" (success) |
| 3. Partner · 파트너 프로필 노출 | partner 진입 | 본인인증 미노출, 파트너 프로필 타일 노출 (subtitle 없음) |
| 4. 로그아웃 확인 다이얼로그 | 로그아웃 타일 탭 후 | MinglitAlert overlay · scrim 0.45 · 확인 = primary color (위험 색 X) |
| 5. 로그아웃 진행 중 | 확인 후 ~200ms | baseline 과 시각적으로 동일, 입력 무시, 곧 로그인 화면 교체 |
| 6. Partner · 파트너 프로필 SnackBar | partner 프로필 타일 탭 후 | Material SnackBar "준비 중입니다." (Phase 2 placeholder) |

### 데이터 정의 (참고)

| 항목 | source | 설명 |
|------|--------|------|
| isVerified | currentUserProfileProvider.asData?.value?.isVerified ?? false | user 본인인증 완료 여부 — user 모드에서만 prop 주입 |
| onCertification | user 라우트 한정 prop | 본인인증 타일 탭 시 콜백 (CertificationRoute push) |
| onPartnerProfile | partner 라우트 한정 prop | 파트너 프로필 타일 탭 시 콜백 (Phase 1: SnackBar) |
| onLogout | 양 모드 공통 prop | signOut 후 `/login` redirect |
| onDeleteAccount | 양 모드 공통 prop | user: accountDeletionCoordinator / partner: moreCoordinator |
