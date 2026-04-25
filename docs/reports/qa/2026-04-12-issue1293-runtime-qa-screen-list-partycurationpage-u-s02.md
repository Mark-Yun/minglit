---
source_url: https://github.com/Mark-Yun/minglit/issues/1293
captured_at: 2026-04-12
issue_number: 1293
state: closed
labels: [report-runtime-qa]
author: Mark-Yun
title: "❓ Runtime QA 의문 — 홈 화면에서 큐레이션 목록(PartyCurationPage) 진입 경로 미발견 (U-S02)"
---

# ❓ Runtime QA 의문 — 홈 화면에서 큐레이션 목록(PartyCurationPage) 진입 경로 미발견 (U-S02)

> Issue #1293 · closed · created 2026-04-12T09:08:48Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1293

## Body

Scheduler: runtime-qa-smoke-user-sonnet-subagents

## 관찰 내용

세션 ID: `20260412-173125`
디바이스: Galaxy S10e (`adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp`)
앱 버전: v26.04.1270-dev (app_user, dev flavor)
인증 상태: GUEST

테스트 케이스 U-S02: "큐레이션 목록 | /curation | PartyCurationPage | 홈 → 큐레이션"

홈 화면 uiautomator dump에서 "큐레이션" 텍스트 또는 /curation 경로로 이동하는 버튼을 발견하지 못함.

**홈 화면에서 확인된 섹션:**
- 정렬 필터: 추천순, 마감임박, 가까운날짜, 가까운 거리
- 태그 필터: #20대, #30대, #공연, #네트워킹 등
- 🔥 핫 태그 섹션
- 이벤트 카드 리스트

**질문:**
- PartyCurationPage(/curation)로 이동하는 UI 요소가 어디에 있는가?
- 해당 화면이 현재 앱에서 접근 가능한 상태인가?
- 테스트 케이스 U-S02 경로 "홈 → 큐레이션"이 여전히 유효한가?

![홈 화면](https://cnuahgrfzcqkmdyhunuk.supabase.co/storage/v1/object/public/bug-report-attachments/runtime-qa/20260412-173125/home_hot_tags.png)


## Comments (5)

### Comment 1 — @Mark-Yun on 2026-04-12

🤖 **needs-qa-claude-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-12

## QA 분석 결과

### 결론: Product Gap — 큐레이션 페이지 진입점 부재

### 코드 확인

1. **PartyCurationPage**: `party_curation_page.dart` — 위젯 존재, 정상 동작
2. **라우트**: `app_routes.dart:257-278` — `/curation` 라우트 정의됨 (HomeRoute의 하위 라우트)
3. **Coordinator**: `EventCoordinator.pushEventCuration(type)` 메서드 존재

### 문제

홈 화면에서 `/curation`으로 이동하는 **UI 요소가 없습니다.**

홈 화면 구성:
- AppBar (검색, 알림, 프로필 아이콘)
- ExploreFilterChipBar (필터 칩 — 필터 변경만, 네비게이션 안 함)
- FeaturedTagChipBar / TrendingTagSection (태그 이벤트 목록으로만 이동)
- 이벤트 카드 리스트

`pushEventCuration()` 메서드가 어디에서도 호출되지 않습니다 (테스트 코드 제외).

### 원인 추정

`69afe28c` 커밋 (홈/탐색 탭 통합) 이후, 기존 탐색 탭에 있던 큐레이션 진입점이 사라진 것으로 보입니다. 라우트와 페이지는 유지됐지만 UI 진입점이 orphan 상태입니다.

### 후속 조치

1. **테스트 케이스 업데이트**: `app-user-smoke.md` U-S02에 "⚠️ 현재 홈에서 진입 UI 없음" 주석 추가
2. **PM 판단 필요**: 큐레이션 페이지에 UI 진입점을 복원할지, 아니면 기능을 정리할지 결정 필요

→ `needs-qa` 제거, `needs-pm` 라벨 부착하겠습니다. PM이 큐레이션 기능의 방향을 결정해주세요.

### Comment 3 — @Mark-Yun on 2026-04-12

🤖 **needs-pm-claude-1** 작업 시작합니다.

### Comment 4 — @Mark-Yun on 2026-04-12

## PM 결정: 큐레이션 페이지 고아 코드 정리 (제거)

### 분석

| 항목 | 현황 |
|------|------|
| `PartyCurationPage` | `EventFeedType`별 페이지네이션 리스트 뷰 |
| `EventCurationRoute` `/curation` | HomeRoute 하위 라우트로 정의됨 |
| `pushEventCuration()` | 정의만 있고 UI에서 호출하는 곳 없음 |
| 원인 | `69afe28c` (홈/탐색 통합, 2026-02-28) 이후 진입점 소실 |
| 미사용 기간 | **약 6주** |

### EventFeedType vs 홈 필터칩 대응

| EventFeedType | 홈 필터칩 | 커버 여부 |
|---------------|-----------|-----------|
| `aiRecommended` (추천순) | 추천순 | ✅ |
| `closingSoon` (마감 임박) | 마감임박 | ✅ |
| `nearest` (거리순) | 가까운 거리 | ✅ |
| `newArrivals` (신규 오픈) | — | ❌ (추가 가능) |
| `earlyBird` (얼리버드) | — | ❌ (추가 가능) |

### 결정 근거

1. **홈 화면이 이미 주요 feed type을 필터칩으로 제공** — 별도 큐레이션 페이지는 중복
2. **6주간 접근 불가 상태에서 누구도 부재를 인지 못함** — 기능 가치가 낮다는 시그널
3. **MVP 출시 전 단계**에서 고아 코드는 유지보수 부담만 증가
4. `newArrivals`/`earlyBird`가 필요해지면 홈 필터칩 확장이 더 나은 UX (별도 페이지 전환 없이 즉시 필터링)

### 정리 대상

- `apps/app_user/lib/src/features/party/party_curation_page.dart`
- `apps/app_user/lib/src/routing/app_routes.dart` — `EventCurationRoute` 정의
- `apps/app_user/lib/src/features/event/logic/event_coordinator.dart` — `pushEventCuration()` 메서드
- `apps/app_user/test/integration/flow_search_curation_test.dart`
- `docs/ux/information-architecture.md` — EventCurationRoute 항목 제거
- QA 테스트 케이스 U-S02 제거

→ `needs-pm` 제거, 구현 이슈를 `needs-swe`로 생성합니다.

— **needs-pm-claude-1**

### Comment 5 — @Mark-Yun on 2026-04-13

🤖 **tpm-exec-report-claude-subagents** 정리.

QA 분석 → PM 결정 완료. 큐레이션 페이지 고아 코드 제거로 결론 → #1302 (needs-swe, P3-low) 생성됨.

원본 이슈를 닫습니다.
