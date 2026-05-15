# 파트너 대시보드 리디자인 스펙

## 개요

파트너앱 홈 화면과 네비게이션을 **파트너 일상 업무 중심**으로 재구성한다.
핵심 원칙: "오늘 할 일 먼저, 통계 나중" (에어비앤비 호스트앱 + 카카오 비즈니스 패턴)

와이어프레임: [wireframe.html](./wireframe.html)

## 파트너 전용 테마

유저앱과 구분되는 파트너 전용 컬러를 사용한다.
`app_partner`에서 `colorScheme`을 오버라이드하는 방식으로 구현.

| 역할 | 유저앱 | 파트너앱 | 비고 |
|------|--------|---------|------|
| Primary | `#9900FF` (생생한 보라) | `#6C3CE1` (차분한 보라) | 같은 계열, 톤 다운 |
| Primary Light | - | `#8B5CF6` | 그라디언트용 |
| Primary Surface | - | `#F5F0FF` | 카드 배경 |
| Primary Border | - | `#E8E0FF` | 카드 보더 |
| Primary Container | - | `#F0EDFF` | 버튼 secondary 배경 |
| Secondary/Error/Success | 공유 | 공유 | `MinglitColors` 그대로 |

## 바텀 네비게이션 (4탭 → 5탭)

### 현재

```
홈 | 파티관리 | 수익관리 | 설정
```

### 변경

```
홈 | 신청관리 | 체크인 | 정산 | 더보기
```

| 탭 | 아이콘 | 경로 | 설명 |
|----|--------|------|------|
| 홈 | `home` | `/` | 할 일 대시보드 |
| 신청관리 | `assignment` | `/applications` | 이벤트별 그루핑된 신청 목록 |
| 체크인 | `qr_code_scanner` | `/checkin` | QR 스캐너 (이벤트 자동 선택) |
| 정산 | `account_balance` | `/settlement` | 매출 요약 + 정산 내역 |
| 더보기 | `more_horiz` | `/more` | 파티관리, 멤버, 인증, 설정 |

### 이동되는 항목

| 항목 | 현재 위치 | 변경 위치 |
|------|----------|----------|
| 파티 관리 | 바텀탭 2번 | 더보기 > 내 파티 관리 |
| 설정 | 바텀탭 4번 | 더보기 > 설정 섹션 |
| 멤버 관리 | 설정 내부 | 더보기 > 운영 섹션 |
| 인증 관리 | 설정 내부 | 더보기 > 운영 섹션 |

### 구현 주의사항

- `partner_scaffold.dart:16`의 `_rootPaths`를 `{'/', '/applications', '/checkin', '/settlement', '/more'}`로 변경 필수
- 기존 `PartyListRoute` 참조(`partner_home_page.dart:139,155` 등) 전수 조사 및 수정

## 홈 대시보드

### 구성 요소 (위→아래 순서)

```
1. 인사 + 할 일 요약 텍스트
2. 할 일 칩 (3개)
3. 이벤트 액션카드
4. 이번 주 성과
```

### 1. 인사 영역

```
👋 {파트너명} 님
오늘 할 일 {N}건
```

- 할 일 = 승인 대기 수
- 할 일 0이면: "오늘 할 일 없음"
- 이벤트 진행 중이면: "이벤트 진행 중!"
- 이벤트 종료 후: "오늘 이벤트 수고하셨어요!"

### 2. 할 일 칩 (3개)

| 칩 | 데이터 소스 | 탭 이동 | 0일 때 |
|----|------------|---------|--------|
| 승인 대기 N | `eventRepository.getPendingApplicationCount()` | 신청관리 탭 (대기중) | 회색 비활성 |
| 다가오는 이벤트 N | `eventRepository.getUpcomingEvents()` count | 더보기 → 파티관리 | 회색 비활성 |
| 미답변 리뷰 N | *미구현* — "준비 중" 표시, 탭 시 "곧 출시" 토스트 | - | 회색 + "준비 중" 라벨 |

> **Note**: 리뷰 기능은 현재 미구현. 리뷰 시스템 구현 후 `reviewRepository.getUnansweredCount()`로 교체 예정.

### 3. 이벤트 액션카드

가장 가까운 이벤트 1개를 표시. 시점에 따라 상태(phase)와 액션 버튼이 자동 변경된다.

#### 이벤트 선택 규칙

우선순위 순으로 1개를 선택:
1. `live` (진행 중인 이벤트) — 복수 시 시작 시각이 빠른 것
2. `preparing` (3시간 이내 시작) — 복수 시 시작 시각이 빠른 것
3. `ended` (종료 후 24시간 이내) — 복수 시 종료 시각이 최근인 것
4. `recruiting` (가장 가까운 예정 이벤트) — 복수 시 시작 시각이 빠른 것

나머지 이벤트는 "다가오는 이벤트 N" 칩 탭으로 확인 가능.

#### Phase 정의

| Phase | 조건 | 뱃지 | 색상 |
|-------|------|------|------|
| `recruiting` | 이벤트 시작까지 3시간 초과 | 🟢 모집 중 · {D-N 또는 날짜} | 초록 |
| `preparing` | 이벤트 시작까지 3시간 이하 | 🟠 준비 중 · {N시간 N분 후} | 오렌지 |
| `live` | 이벤트 시작 ~ 종료 | 🟣 LIVE · {N분 경과} | 보라 (pulse 애니메이션) |
| `ended` | 이벤트 종료 후 ~ 24시간 | ⚫ 종료 · {N시간 전} | 회색 |

- 종료 후 24시간 경과한 이벤트는 액션카드에서 사라짐

#### Phase별 액션 버튼

| Phase | 메인 CTA (width: 100%) | 보조 액션 |
|-------|----------------------|----------|
| `recruiting` | 📋 신청 현황 보기 | 이벤트 수정 · 공유/홍보 |
| `preparing` | 📱 체크인 준비 | 참석자 명단 · 안내 발송 |
| `live` | 📱 체크인 계속하기 | 참석 현황 |
| `ended` | 🔄 다음 회차 만들기 | 상세 결과 |

#### "다음 회차 만들기" 동작

이벤트 생성 폼으로 이동하되, 현재 이벤트의 정보를 **pre-fill**:
- 파티, 장소, 인원, 티켓 설정을 복사
- 날짜/시간만 비워둠 (파트너가 직접 설정)

#### 이벤트 없을 때

- 파티 있고 이벤트 없음: "이벤트를 만들어 신청을 받아보세요" + CTA
- 파티도 없음: 온보딩 스텝 가이드 표시 (아래 참고)

### 4. 이번 주 성과

3칸 그리드:

| 항목 | 데이터 소스 | 비교 |
|------|------------|------|
| 매출 | `settlementRepository.getWeeklyRevenue(partnerId)` | 지난주 대비 % |
| 신청 | `eventRepository.getWeeklyApplicationCount(partnerId)` | 지난주 대비 % |
| 체크인율 | `checkinRepository.getWeeklyCheckinRate(partnerId)` | 지난주 대비 % |

> **Note**: 위 3개 메서드는 **신규 생성 필요**. 각각 이번 주/지난주 2회 조회하여 비교.

- 데이터 없을 때 (신규 파트너): 섹션 숨김
- 로딩 중: Skeleton shimmer
- 에러 시: 섹션 숨김 (비핵심 섹션이므로 에러가 대시보드를 차단하지 않음)

### FAB 처리

기존 홈의 FAB("이벤트 생성")은 **제거**. 이벤트 생성은:
- 이벤트 액션카드의 CTA
- 더보기 → 파티관리 → 파티 상세 → 이벤트 생성
- ended 카드의 "다음 회차 만들기"

로 접근 가능하므로 FAB 불필요.

## 신청관리 탭

### 구조

```
[대기중 (N)] [승인됨] [거절됨]     ← 탭바
─────────────────────────────
이벤트 A 헤더 (이름 · 날짜)       ← 이벤트별 그루핑
  신청자 1  [✕] [✓]              ← 인라인 승인/거절
  신청자 2  [✕] [✓]
─────────────────────────────
이벤트 B 헤더
  신청자 3  [✕] [✓]
─────────────────────────────
[전체 승인 (N건)]                 ← 하단 고정 배치 액션
```

### 핵심 기능

- **이벤트별 그루핑**: 신청을 이벤트 단위로 묶어 표시
- **인라인 승인/거절**: 상세 진입 없이 리스트에서 바로 처리
- **전체 승인**: 대기 중인 전체 신청을 일괄 승인
- **신청자 정보**: 이름 · 나이 · 성별 · 신청 시간

### 필요한 백엔드 API (신규)

| 메서드 | 위치 | 설명 |
|--------|------|------|
| `approveApplication(applicationId)` | `event_repository_commands.dart` | 단건 승인 |
| `rejectApplication(applicationId)` | `event_repository_commands.dart` | 단건 거절 |
| `bulkApproveApplications(eventId)` | `event_repository_commands.dart` | 이벤트 전체 대기건 일괄 승인 |
| `getApplicationsGroupedByEvent(partnerId)` | `event_repository_queries.dart` | 이벤트별 그루핑된 신청 목록 |

> **Note**: 승인/거절은 Supabase RPC 또는 Edge Function으로 구현. 단순 status 업데이트가 아니라 결제 트리거, 알림 발송 등 부수 효과가 있을 수 있으므로 EF 권장.

## 체크인 탭

### 진입 로직

```
오늘 진행 중/예정 이벤트가:
  0개 → "오늘 예정된 이벤트가 없습니다" 빈 상태
  1개 → 바로 QR 스캐너 진입
  2개+ → 이벤트 선택 바텀시트 → 선택 후 스캐너
```

- "오늘"의 범위: 이벤트 시작 3시간 전 ~ 이벤트 종료 후 1시간
- 빈 상태에서 다음 이벤트 정보 표시: "다음 이벤트: 3/28 (금) 19:00 금요 와인파티"

### QR 스캐너 화면

- **상단 바**: 이벤트명 + 체크인 카운터 (N/M명)
- **중앙**: QR 스캔 프레임
- **하단**: 스캔 결과 카드
  - 참석자 이름
  - 티켓 종류 · 나이 · 성별
  - **결제 상태 뱃지** (결제 완료 ✓ / 현장결제 / 미결제)

### 다크 모드

체크인 화면은 카메라 사용으로 **항상 다크 배경**. 해당 화면만 `Theme` 위젯으로 다크 오버라이드 (앱 전체 테마 전환 아님). 바텀탭 영역도 다크 배경으로 일관성 유지.

## 정산 탭

기존 `SettlementPage` UI를 유지하되, 상단에 매출 요약 카드를 추가.

### 구조

```
┌─ 매출 카드 (보라 그라디언트) ────┐
│  이번 달 총 매출: ₩1,280,000    │
│  정산 완료: ₩850,000            │
│  정산 대기: ₩430,000            │
└──────────────────────────────┘

정산 내역                [필터 ›]
┌──────────────────────────────┐
│  🎉 금요 와인파티              │
│  3/21 (금) · 12명 참석         │
│  ₩360,000      정산 완료       │
├──────────────────────────────┤
│  🎲 보드게임 나이트             │
│  ...                          │
└──────────────────────────────┘

계좌: 카카오뱅크 ****567
[계좌 변경 ›]
```

## 더보기 탭

### 섹션 구조

```
프로필 카드 (파트너명 · 대표자 · 가입일)
───────────────────
파티 관리
  내 파티 관리 (N개)
  티켓 템플릿
  매칭 설정
───────────────────
운영
  멤버 관리 (N명)
  인증 관리
  계좌 정보
───────────────────
설정
  알림 설정
  약관 및 정책
  고객센터
───────────────────
  로그아웃
```

## 신규 파트너 온보딩

### 전환 조건

| 상태 | 화면 |
|------|------|
| 파티 0개 + 이벤트 0개 | 스텝 가이드 (파티 만들기 유도) |
| 파티 1개+ + 이벤트 0개 | 이벤트 넛지 (이벤트 만들기 유도) |
| 이벤트 1개+ | 일반 대시보드 |

판단 기준:
- 파티 수: `partyRepository.getPartiesByPartnerId()` count
- 이벤트 수: `eventRepository.getUpcomingEvents()` count (과거 포함하면 `getAllEvents`)
- 계좌 등록 여부: `settlementRepository.getBankAccount()` null 체크

### 스텝 가이드 (파티 생성 전)

```
🎊 환영합니다!
파트너 가입이 승인되었어요

[진행률 바: 2/4 완료 ██░░]

✅ 1. 파트너 가입          완료
✅ 2. 계좌 등록            완료
🟣 3. 첫 파티 만들기       [시작 →]
🔒 4. 첫 이벤트 만들기     파티 생성 후 가능

[🎉 첫 파티 만들기]        ← 메인 CTA

┌─ 이렇게 진행돼요 ────────────┐
│ 🎉 파티 → 📅 이벤트 → 👥 신청 → 💰 정산 │
└────────────────────────────┘
```

### 이벤트 넛지 (파티 생성 후)

```
👋 {파트너명} 님
파티가 생성됐어요! 한 단계 남았어요

[진행률 바: 3/4 완료 ███░]

✅ 1. 파트너 가입
✅ 2. 계좌 등록
✅ 3. 첫 파티 만들기       방금 완료!
🟣 4. 첫 이벤트 만들기     [시작 →]

┌─ 생성된 파티 카드 ──────────┐
│ 🎉 금요 와인파티             │
│ 강남라운지 · 이벤트 0개       │
└────────────────────────────┘

[📅 첫 이벤트 만들기]       ← 메인 CTA
```

### 온보딩 완료 후

첫 이벤트 생성 완료 → 스텝 가이드 사라짐 → 일반 대시보드 전환.
이벤트 액션카드에 방금 만든 이벤트가 `recruiting` phase로 표시.

## 라우트 변경

### 현재 ShellRoute (4 branch)

```
/ (홈) | /parties (파티관리) | /settlement (정산) | /more (설정)
```

### 변경 ShellRoute (5 branch)

```
/ (홈) | /applications (신청관리) | /checkin (체크인) | /settlement (정산) | /more (더보기)
```

### 신규 라우트

| 경로 | 화면 | 비고 |
|------|------|------|
| `/applications` | 신청 관리 (탭: 대기/승인/거절) | 신규 branch |
| `/applications/:id` | 신청 상세 | 기존 이동 |
| `/checkin` | 체크인 (이벤트 선택 or 바로 스캐너) | 신규 branch |
| `/checkin/:eventId` | QR 스캐너 | 기존 이동 |

### 이동되는 라우트

| 기존 경로 | 새 경로 | 비고 |
|----------|---------|------|
| `/parties` | `/more/parties` | 더보기 하위로 이동 |
| `/parties/create` | `/more/parties/create` | 동일 |
| `/parties/:id` | `/more/parties/:id` | 동일 |

### 마이그레이션 체크리스트

- [ ] `partner_scaffold.dart` `_rootPaths` 업데이트
- [ ] `PartyListRoute` 참조 전수 조사 (`partner_home_page.dart:139,155` 등)
- [ ] `app_routes.dart`에서 `PartyListRoute` path를 `/more/parties`로 변경
- [ ] 딥링크/푸시 알림에서 `/parties` 경로 사용 여부 확인

## 에러 및 상태 처리

### 로딩

| 섹션 | 로딩 UI |
|------|---------|
| 할 일 칩 | Skeleton shimmer (3개 칩 플레이스홀더) |
| 이벤트 액션카드 | Skeleton shimmer (카드 형태) |
| 이번 주 성과 | Skeleton shimmer (3칸 그리드) |
| 신청관리 목록 | 리스트 Skeleton |

### 에러

| 섹션 | 에러 처리 |
|------|----------|
| 할 일 칩 | 개별 칩이 "-" 표시 (다른 칩은 정상 표시) |
| 이벤트 액션카드 | "데이터를 불러올 수 없습니다" + 재시도 버튼 |
| 이번 주 성과 | 섹션 숨김 (비핵심) |
| 신청관리/정산 | 전체 화면 에러 + 재시도 |

### 각 섹션 독립 로딩

현재 `PartnerDashboardState`는 단일 `AsyncValue`이나, 리디자인 후에는 **섹션별 독립 provider**로 분리:
- `pendingApplicationCountProvider` — 할 일 칩
- `primaryEventProvider` — 이벤트 액션카드
- `weeklyStatsProvider` — 이번 주 성과

한 섹션 실패가 다른 섹션을 차단하지 않도록 한다.

## 구현 이슈 분할

| 순서 | 제목 | 라벨 | 의존성 | 비고 |
|------|------|------|--------|------|
| 0 | feat: 신청 승인/거절 API (EF + Repository) | `enhancement, P1-high` | 없음 | BE 선행 작업 |
| 1 | refactor: 파트너앱 바텀탭 5개 구조로 변경 | `refactor, P1-high` | 없음 | `_rootPaths`, 라우트 마이그레이션 포함 |
| 2 | feat: 파트너 홈 대시보드 리디자인 (할 일 칩 + 성과) | `enhancement, P1-high` | #1 | FAB 제거, 섹션별 provider 분리 |
| 3 | feat: 이벤트 액션카드 시점별 상태 분기 | `enhancement, P1-high` | #2 | 이벤트 선택 규칙, 다음 회차 pre-fill |
| 4 | feat: 신규 파트너 온보딩 스텝 가이드 | `enhancement, P2-medium` | #2 | 전환 조건 판단 로직 |
| 5 | feat: 신청관리 탭 (이벤트별 그루핑 + 인라인 승인) | `enhancement, P1-high` | #0, #1 | BE API 필요 |
| 6 | feat: 체크인 탭 (이벤트 자동 선택 + QR 스캐너) | `enhancement, P1-high` | #1 | 다크 오버라이드, 빈 상태 |
| 7 | feat: 파트너 전용 테마 컬러 적용 | `enhancement, P2-medium` | 없음 | colorScheme 오버라이드 |
| 8 | feat: 정산 탭 매출 요약 카드 추가 | `enhancement, P2-medium` | 없음 | 기존 UI 위에 카드 추가 |

## 수정 대상 파일

### 프론트엔드

| 파일 | 변경 내용 |
|------|----------|
| `app_partner/lib/src/routing/app_routes.dart` | ShellRoute 5 branch, 라우트 이동 |
| `app_partner/lib/src/ui/shell/partner_scaffold.dart` | 바텀탭 5개 정의, `_rootPaths` 변경 |
| `app_partner/lib/src/features/home/partner_home_page.dart` | 대시보드 재구성, FAB 제거 |
| `app_partner/lib/src/features/home/partner_dashboard_controller.dart` | 섹션별 provider 분리 |
| `app_partner/lib/src/features/home/widgets/todo_summary_chips.dart` | 신규 |
| `app_partner/lib/src/features/home/widgets/event_action_card.dart` | 신규 |
| `app_partner/lib/src/features/home/widgets/weekly_stats_row.dart` | 신규 |
| `app_partner/lib/src/features/home/widgets/onboarding_step_guide.dart` | 신규 |
| `app_partner/lib/src/features/application/` | 신청관리 feature 신규 |
| `app_partner/lib/src/features/checkin/` | 체크인 진입 로직 리팩터링 |
| `app_partner/lib/src/features/more/more_page.dart` | 더보기 구조 변경 |
| `app_partner/lib/src/features/settlement/settlement_page.dart` | 상단 매출 요약 카드 추가 |

### 백엔드 (신규)

| 파일 | 변경 내용 |
|------|----------|
| `supabase/functions/approve-application/index.ts` | 신청 승인 EF (신규) |
| `supabase/functions/reject-application/index.ts` | 신청 거절 EF (신규) |
| `minglit_kit/lib/src/data/repositories/event_repository_commands.dart` | `approveApplication()`, `rejectApplication()`, `bulkApproveApplications()` 추가 |
| `minglit_kit/lib/src/data/repositories/event_repository_queries.dart` | `getApplicationsGroupedByEvent()`, `getWeeklyApplicationCount()` 추가 |
| `minglit_kit/lib/src/data/repositories/checkin_repository.dart` | `getWeeklyCheckinRate()` 추가 |
| `minglit_kit/lib/src/data/repositories/settlement_repository.dart` | `getWeeklyRevenue()` 추가 |
