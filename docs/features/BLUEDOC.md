# Features

사용자에게 노출되는 product capability 단위의 spec 모음. 도메인 기준으로 8개 카테고리로 분류한다.

## 정의

**feature 의 조건**

- 사용자 가치가 식별 가능한 product capability
- `app_user` 또는 `app_partner` 의 UI 흐름에 대응
- 양면(user + partner) 으로 동작하는 경우가 일반적이므로 spec 안에 두 측면을 모두 기술

feature 가 아닌 것 (다른 위치로):

- 디자인 시스템 / UI 폴리시 → `docs/ux/`
- 아키텍처 / 인프라 / 마이그레이션 → `docs/architecture/`, `docs/infra/`
- 워커 / 프롬프트 / 자동화 → `docs/infra/`

## 카테고리 (MDS flow 기반)

| 카테고리 | 도메인 | MDS flow 매핑 |
|----------|--------|---------------|
| [event/](./event/) | 이벤트 자체 (CRUD, 정책) | user-main (EventDetail) + partner-main (ApplicationList) |
| [event-operation/](./event-operation/) | 이벤트 진행 중 (체크인, 매칭, 결과) | user-main (NowBar/CheckIn) + partner-main (Checkin) |
| [ticket/](./ticket/) | 티켓 (구매, 보유, 이력) | user-main (MyTickets) |
| [discovery/](./discovery/) | 탐색 (검색, 태그, 신뢰) | user-main (Home/Search/Tag) |
| [account/](./account/) | 계정 (가입, 동의, 프라이버시) | user-auth + partner-onboarding |
| [notification/](./notification/) | 알림 (수신/설정) | user-main (NotificationCenter) |
| [settlement/](./settlement/) | 정산 (partner-only) | partner-main (Settlement) |
| [admin/](./admin/) | 관리자 운영 도구 | (앱 외 또는 partner 내 별도 권한) |

## Feature spec 구조

각 feature 디렉토리 안에 `spec.md` 가 단일 진실 소스. 양면 feature 는 spec 안에 user-side / partner-side 섹션을 둔다.

```markdown
## User-side (app_user)
- 화면: <Route>
- 동작: ...

## Partner-side (app_partner)
- 화면: <Route>
- 동작: ...

## 공유 데이터 / 비즈니스 규칙
- 테이블: ...
- 정책: ...
```

## 관련 컨벤션

- [BLUEDOC](../infra/bluedoc/BLUEDOC.md) — 진입점 컨벤션
- [MDS flow](../../apps/mds/docs/src/lib/flow-data.ts) — UI 네비게이션 그래프 (카테고리 매핑의 근거)
