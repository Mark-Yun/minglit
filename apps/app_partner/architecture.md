# app_partner — 권한·온보딩 기반 라우팅

파트너 앱은 사용자 앱과 달리 **권한 + 온보딩 상태 + 정산 권한** 세 가지 축이 라우팅을 좌우한다. 모든 분기는 `lib/src/routing/app_router.dart` 의 `redirect` 콜백 한 곳에 모여있다. Feature 내부에서 "이 사람이 이 화면 볼 수 있나" 체크하지 않는다.

공통 Flutter 아키텍처 (Tech Stack, Coordinator, Repository pattern) 는 [`../architecture.md`](../architecture.md) 참고.

## Router 의 3 가지 listen 대상

라우터는 다음 3 가지 state 변화에 대해 자동 재평가 (`refreshListenable`):

| Listenable | Provider | 트리거 |
|---|---|---|
| Auth | `authStateChangesProvider` (Supabase) | 로그인/로그아웃 |
| Onboarding | `onboardingStateProvider` | 신청서 작성 단계 변화 |
| Settlement | `hasSettlementAccessProvider` | 정산 권한 변경 (Fix #1533) |

세 가지 중 하나라도 바뀌면 `redirect` 콜백이 다시 돈다.

## Redirect 의 우선순위

```text
1. /dev/* 라우트       → 인증 skip (개발용 우회)
2. !isLoggedIn         → /login
3. isLoggedIn + /login → / (홈)
4. isLoggedIn + onboarding state 분기
   - needsApplication → /welcome (신규 신청 안내)
   - draftInProgress  → /apply (이어서 작성)
   - approved         → 정상 라우트 진행
```

## 온보딩 상태 (`OnboardingState`)

| 상태 | 의미 | redirect |
|---|---|---|
| `needsApplication` | 파트너 신청서 미작성 | `/welcome` |
| `draftInProgress` | 신청서 작성 중 | `/apply/...` |
| `approved` | 승인 완료, 정상 사용 | 그대로 |

`onboardingStateProvider` 가 `currentPartnerInfoProvider` + 신청서 status 로 도출.

## 권한 모델 (`currentMemberPermissions`)

`partner_member_permissions` 테이블에서 현재 사용자의 권한 리스트 조회.

| 권한 | 의미 |
|---|---|
| `SETTLEMENT_VIEW` | 정산 조회 |
| `SETTLEMENT_EDIT` | 정산 편집 |

**폴백 규칙 (Fix #1568)**: `partner_member_permissions` 엔트리가 없으면 = 승인된 신청서 폴백 owner → `SETTLEMENT_VIEW + SETTLEMENT_EDIT` 자동 부여. (오너인데 멤버 테이블 없는 경우 대비)

`hasSettlementAccessProvider` 가 `SETTLEMENT_VIEW` 보유 여부로 정산 메뉴 표시 결정.

## Feature 안에서 권한 체크 금지

✗ **안티패턴**
```dart
// settlement_page.dart 안에서
if (!hasSettlementAccess) return UnauthorizedPage();
```

◯ **정답**
- Router redirect 에서 권한 없는 사용자는 정산 라우트 진입 자체 차단
- Feature 페이지는 "여기 들어왔다 = 권한 있다" 가정하고 작성

## 관련 Fix 이력

- #1217 / #1533: 정산 권한 변경 후 라우터 미반영 문제 (`refreshListenable` 에 `hasSettlementAccessProvider` 추가)
- #1568: 멤버 테이블 없는 owner 폴백
- #1825: `/dev` 단독 → `/dev/user-switch` 리다이렉트

## 관련 문서

- [BLUEDOC](./BLUEDOC.md) — 파트너 앱 진입점
- [apps/architecture.md](../architecture.md) — Flutter 공통 아키텍처
- [minglit_kit/architecture.md](../../shared/packages/minglit_kit/architecture.md) — Repository / Provider 디테일
