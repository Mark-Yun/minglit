# 태그 기반 이벤트 발견 + 태그 추천 파이프라인

## 개요

현재 이벤트 발견 경로는 5개 하드코딩 피드타입(`신규`, `마감임박`, `근처`, `얼리버드`, `AI추천`)과 PGroonga 제목 검색뿐이다. 카테고리/태그 인프라가 없어 유저가 **관심사 기반으로 이벤트를 탐색할 수 없다**.

### 핵심 원칙

- **태그 단일 시스템** — 카테고리 테이블 없이 태그 하나로 통합. 인기 태그(`is_featured`)가 카테고리 역할을 수행.
- **2-tier 태그** — 인기 태그(큐레이션, 홈 칩바 노출) + 자유 태그(파트너가 파티당 최대 5개 입력).
- **추천 파이프라인 분리** — 임베딩 기반(기존, 분위기 매칭) + 태그 기반(신규, 명시적 관심사 매칭) 독립 운영.

### 참고 앱/트렌드

| 앱 | 핵심 패턴 | 밍릿 적용 |
|---|---|---|
| **Meetup** | 온보딩 관심사 필수 선택 → 피드 개인화. 수평 스크롤 칩바 필터 | 인기 태그 칩바 + 온보딩 관심사 선택 |
| **Bumble BFF** | 150개 중 5개 관심 뱃지, OR 필터 로직, 프로필 카드에 필 칩 | 파티당 최대 5개 태그, OR 로직 필터 |
| **소모임** | 18개 카테고리 아이콘 그리드 + 동네 기반 추천 | 인기 태그 20~25개로 카테고리 역할 |
| **Luma** | 카테고리별 이벤트 수 표시 + Popular Events 섹션 | 핫 태그에 이벤트 수 뱃지 |
| **당근마켓** | 제목 입력 시 카테고리 자동 추천 (FastText) | 파티 생성 시 태그 자동 추천 (Phase 5+) |
| **TikTok/Instagram 2025** | 해시태그→키워드 시프트, 증가율 기반 트렌딩 | 핫 태그 = usage_count 증가율 기준 |

### 설계 결정 근거

1. **카테고리 대신 태그 단일 시스템을 선택한 이유**
   - Eventbrite, Meetup 등 대형 플랫폼은 Category→Subcategory 2-tier 사용. 하지만 밍릿은 초기 단계이며 이벤트 수가 적어 세분화된 카테고리는 빈 상태를 유발.
   - 태그 시스템은 카테고리보다 유연하고, `is_featured` 플래그로 인기 태그가 카테고리 역할을 대체 가능.
   - 이벤트 수 증가 시 `is_featured` 조정만으로 구조 변경 없이 대응 가능.

2. **OR 필터 로직 (Bumble 패턴)**
   - Bumble은 관심 뱃지 필터에 OR 로직 사용 — 여러 태그 선택 시 **하나라도 매칭되면** 표시.
   - AND 로직은 소규모 카탈로그에서 zero-result를 유발하므로 OR이 적합.

3. **온보딩 관심 태그 3~5개 (Bumble + Meetup 패턴)**
   - Bumble: 5개 뱃지, 90% 유저가 2개 이상 설정.
   - Meetup: 관심사 필수 선택이 피드 개인화의 핵심.
   - 밍릿: 최소 3개 선택을 Continue 조건으로 설정하여 cold-start 신호 확보.

---

## 구성 요소

### 1. DB 스키마 (3개 테이블)

```sql
-- 태그 마스터 (인기 태그 + 자유 태그 통합)
CREATE TABLE tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  is_featured boolean DEFAULT false,  -- true: 홈 칩바 + 온보딩 노출
  usage_count integer DEFAULT 0,      -- party_tags 연결 수 (트리거로 자동 관리)
  created_at timestamptz DEFAULT now()
);

-- 파티 ↔ 태그 (N:M, 파티당 최대 5개)
CREATE TABLE party_tags (
  party_id uuid REFERENCES parties(id) ON DELETE CASCADE,
  tag_id uuid REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (party_id, tag_id)
);

-- 유저 관심 태그 (온보딩 시 선택, 최대 5개)
CREATE TABLE user_interest_tags (
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  tag_id uuid REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, tag_id)
);
```

**RLS 정책:**
- `tags`: 읽기 public, 쓰기 admin only
- `party_tags`: 읽기 public, 쓰기는 파티 소유 파트너 멤버
- `user_interest_tags`: 읽기/쓰기 본인만 (`auth.uid() = user_id`)

**트리거:**
- `party_tags` INSERT/DELETE 시 `tags.usage_count` 자동 증감

**시드 데이터 (인기 태그 25개):**

| 태그 | 대상 유저 | 비고 |
|------|----------|------|
| #소개팅 | 20~30대 | 핵심 카테고리 |
| #미팅 | 20~30대 | 그룹 만남 |
| #네트워킹 | 직장인 | 비즈니스 |
| #운동 | 전체 | 스포츠 전반 |
| #러닝 | 전체 | 인기 급상승 |
| #등산 | 전체 | 한국 특화 |
| #맛집 | 전체 | 식도락 |
| #와인 | 25~35 | 프리미엄 |
| #커피 | 전체 | 캐주얼 |
| #파티 | 20~30대 | 나이트라이프 |
| #클럽 | 20~30대 | 나이트라이프 |
| #루프탑 | 20~30대 | 장소 특화 |
| #스터디 | 20~30대 | 자기계발 |
| #독서 | 전체 | 문화 |
| #영화 | 전체 | 문화 |
| #음악 | 전체 | 문화 |
| #공연 | 전체 | 문화 |
| #전시 | 전체 | 문화 |
| #여행 | 전체 | 야외 |
| #캠핑 | 전체 | 야외 |
| #야외 | 전체 | 야외 전반 |
| #소규모 | 전체 | 그룹 사이즈 |
| #대규모 | 전체 | 그룹 사이즈 |
| #20대 | 20대 | 연령 |
| #30대 | 30대 | 연령 |

### 2. API (RPC 함수 + Edge Function)

| 함수 | 파라미터 | 반환 | 용도 |
|------|---------|------|------|
| `get_featured_tags()` | 없음 | `tags[]` | 홈 칩바 + 온보딩 (is_featured=true, usage_count DESC) |
| `get_trending_tags(limit, days)` | `limit int, days int` | `tags[]` | 🔥 핫 태그 (최근 N일 usage_count 증가율 기준) |
| `get_parties_by_tag(tag_id, limit, offset)` | `tag_id uuid, limit int, offset int` | `events[]` | 태그별 이벤트 조회 (활성 이벤트만, 시작일 ASC) |
| `get_tag_recommendations(user_id, limit)` | `user_id uuid, limit int` | `events[]` | 유저 관심 태그 ∩ 파티 태그 → 스코어링 |
| `search_tags(query)` | `query text` | `tags[]` | 태그 검색 (자동완성, PGroonga prefix match) |
| `upsert_user_interest_tags(tag_ids)` | `tag_ids uuid[]` | void | 유저 관심 태그 설정 (최대 5개 검증) |

**파티 생성/수정 EF 변경:**
- 기존 `create-party` / `update-party` EF에 `tag_ids: uuid[]` 파라미터 추가
- EF 내부에서 `party_tags` INSERT/DELETE 처리 (최대 5개 검증)

### 3. 클라이언트 모델 + Provider

**Dart 모델 (Freezed):**

```dart
@freezed
class Tag with _$Tag {
  const factory Tag({
    required String id,
    required String name,
    @Default(false) bool isFeatured,
    @Default(0) int usageCount,
  }) = _Tag;
}
```

**Riverpod Provider:**

| Provider | 타입 | 소스 | 캐시 |
|----------|------|------|------|
| `featuredTagsProvider` | `FutureProvider<List<Tag>>` | `get_featured_tags()` | 5분 keepAlive |
| `trendingTagsProvider` | `FutureProvider<List<Tag>>` | `get_trending_tags(10, 7)` | 5분 keepAlive |
| `partiesByTagProvider(tagId)` | `AsyncNotifier` (페이지네이션) | `get_parties_by_tag()` | 자동 dispose |
| `userInterestTagsProvider` | `AsyncNotifier<List<Tag>>` | `user_interest_tags` JOIN `tags` | 본인 데이터, invalidate on update |
| `tagSearchProvider(query)` | `FutureProvider.family` | `search_tags()` | 500ms 디바운스 |
| `tagRecommendationFeedProvider` | `AsyncNotifier` (페이지네이션) | `get_tag_recommendations()` | 5분 keepAlive |

**Repository:**

```dart
class TagRepository {
  Future<List<Tag>> getFeaturedTags();
  Future<List<Tag>> getTrendingTags({int limit = 10, int days = 7});
  Future<List<Event>> getPartiesByTag(String tagId, {int limit = 10, int offset = 0});
  Future<List<Event>> getTagRecommendations({int limit = 10});
  Future<List<Tag>> searchTags(String query);
  Future<void> upsertUserInterestTags(List<String> tagIds);
}
```

### 4. 유저 앱 UI

#### 4.1 홈 피드 상단: 인기 태그 칩바

```
┌─────────────────────────────────────┐
│ [SliverAppBar: 밍릿 로고]            │
├─────────────────────────────────────┤
│ 추천순 │ 마감임박 │ 가까운날짜 │ ...   │  ← 기존 ExploreFilterChipBar
├─────────────────────────────────────┤
│ #소개팅  #미팅  #네트워킹  #운동  ▸   │  ← 신규: 인기 태그 칩바 (가로 스크롤)
├─────────────────────────────────────┤
│ 🔥 핫 태그                           │
│ ┌──────┐ ┌──────┐ ┌──────┐         │
│ │#러닝  │ │#루프탑│ │#와인  │         │  ← 트렌딩 태그 (가로 스크롤 카드)
│ │ 32건 ↑│ │ 18건 ↑│ │ 15건 ↑│         │
│ └──────┘ └──────┘ └──────┘         │
├─────────────────────────────────────┤
│ [기존 큐레이션 피드 카드들...]         │
├─────────────────────────────────────┤
│ 📌 관심사 추천 (태그 기반)            │  ← 신규: 관심 태그 매칭 섹션
│ [이벤트 카드] [이벤트 카드] ...       │
└─────────────────────────────────────┘
```

**인기 태그 칩바 상세:**
- 위치: 기존 `ExploreFilterChipBar` 바로 아래
- UI: 가로 스크롤 `FilterChip` 리스트 (Material 3)
- 동작: 탭 시 해당 태그 이벤트 필터링 (OR 로직, 복수 선택 가능)
- 선택 상태: `primary` 색상 filled chip + 체크마크
- 디자인 토큰: `MinglitRadius.chip (100)`, `labelMedium (12px, w500)`, `MinglitSpacing.small (8px)` gap

**핫 태그 섹션 상세:**
- 위치: 인기 태그 칩바와 기존 큐레이션 피드 사이
- UI: 가로 스크롤 카드 (`MinglitRadius.card (16)`, `MinglitColors.surface` 배경)
- 내용: 태그명 + 이벤트 건수 + 상승 화살표
- 데이터: `get_trending_tags(10, 7)` — 최근 7일 증가율 상위 10개
- 빈 상태: 데이터 부족 시 섹션 자체를 숨김

#### 4.2 태그 탭 페이지 (태그 선택 시)

인기 태그 칩을 탭하면 해당 태그의 이벤트 리스트를 표시:

```
┌─────────────────────────────────────┐
│ ← #소개팅                            │  ← AppBar: 태그명
├─────────────────────────────────────┤
│ 42개 이벤트                          │  ← 결과 수
├─────────────────────────────────────┤
│ [이벤트 카드 1]                      │
│ [이벤트 카드 2]                      │
│ ...                                 │  ← 무한 스크롤 페이지네이션
└─────────────────────────────────────┘
```

- 라우트: `/tags/:tagId` (신규)
- 데이터: `partiesByTagProvider(tagId)`
- 카드: 기존 `EventCard` 위젯 재사용
- 빈 상태: "아직 이 태그의 이벤트가 없어요" + 홈으로 돌아가기

#### 4.3 이벤트 카드 태그 뱃지

기존 이벤트 카드 하단에 태그 칩 표시:

```
┌─────────────────────────────────────┐
│ [이벤트 이미지]                      │
│ 이벤트 제목                          │
│ 3/29(토) 19:00 · 강남               │
│ #소개팅  #20대  #소규모              │  ← 신규: 태그 뱃지 (최대 3개)
│ ₩25,000~                            │
└─────────────────────────────────────┘
```

- UI: `labelSmall (11px)` + `MinglitRadius.chip (100)` + `surface` 배경
- 최대 3개 표시 (나머지는 `+N`)
- 탭 시 해당 태그 페이지로 이동

#### 4.4 검색 페이지 태그 자동완성

기존 PGroonga 검색에 태그 자동완성 추가:

```
┌─────────────────────────────────────┐
│ 🔍 러닝                              │  ← 검색 입력
├─────────────────────────────────────┤
│ 태그                                 │
│  #러닝 (32)  #러닝크루 (5)           │  ← 태그 자동완성 (prefix match)
├─────────────────────────────────────┤
│ 이벤트                               │
│ [이벤트 검색 결과...]                 │  ← 기존 PGroonga 결과
└─────────────────────────────────────┘
```

- 태그 섹션이 이벤트 결과보다 위에 표시
- 태그 탭 시 태그 페이지(`/tags/:tagId`)로 이동
- 검색어 없을 때: 인기 태그 + 최근 검색 표시

#### 4.5 온보딩: 관심 태그 선택

기존 인증 완료 후, 관심 태그 선택 화면 삽입:

```
┌─────────────────────────────────────┐
│                                     │
│  어떤 모임에 관심 있으세요?           │  ← headlineSmall (24px, bold)
│  3개 이상 선택해 주세요               │  ← bodyMedium (16px)
│                                     │
│  ┌────────┐ ┌────────┐ ┌────────┐  │
│  │ #소개팅 │ │ #미팅   │ │#네트워킹│  │
│  └────────┘ └────────┘ └────────┘  │
│  ┌────────┐ ┌────────┐ ┌────────┐  │
│  │ #운동   │ │ #러닝   │ │ #등산  │  │  ← 3열 Wrap 그리드
│  └────────┘ └────────┘ └────────┘  │
│  ┌────────┐ ┌────────┐ ┌────────┐  │
│  │ #맛집   │ │ #와인   │ │ #커피  │  │
│  └────────┘ └────────┘ └────────┘  │
│  ... (스크롤)                       │
│                                     │
│  ┌───────────────────────────────┐  │
│  │          다음 (3/5)            │  │  ← 선택 수 표시, 3개 미만 시 비활성
│  └───────────────────────────────┘  │
│                                     │
│  건너뛰기                            │  ← TextButton, 강조 안 함
│                                     │
└─────────────────────────────────────┘
```

- 라우트: 기존 인증 플로우 내 삽입 (redirect 로직 변경 필요)
- 데이터: `featuredTagsProvider` (is_featured=true 태그만)
- 선택 상태: `MinglitDecorations.selectableCard()` 패턴 (secondary 5% 배경 + secondary 보더)
- 최소 3개, 최대 5개 선택
- "건너뛰기" 허용 (cold-start 열화 감수, 강제 안 함)
- 완료 시 `upsert_user_interest_tags()` 호출

### 5. 파트너 앱 UI

#### 5.1 파티 생성 위저드 Step 1: 태그 선택

기존 Step 1 (기본정보: 제목, 설명, 이미지, 공개설정) 하단에 태그 선택 추가:

```
┌─────────────────────────────────────┐
│ Step 1. 기본정보                     │
├─────────────────────────────────────┤
│ 제목                                │
│ [________________]                  │
│                                     │
│ 설명                                │
│ [Quill Editor      ]               │
│                                     │
│ 커버 이미지                          │
│ [📷] [📷] [+]                       │
│                                     │
│ 공개 설정                            │
│ ◉ 공개  ○ 비공개                     │
│                                     │
│ 태그 (최대 5개)                      │  ← 신규
│ ┌─────────────────────────────────┐ │
│ │ 🔍 태그 검색...                  │ │  ← 자동완성 입력
│ └─────────────────────────────────┘ │
│ 인기 태그                            │
│ #소개팅  #미팅  #네트워킹  #운동     │  ← 인기 태그 퀵 선택
│                                     │
│ 선택된 태그                          │
│ #소개팅 ✕  #20대 ✕                  │  ← 선택 태그 (제거 가능)
│                                     │
└─────────────────────────────────────┘
```

- 인기 태그 퀵 선택: `featuredTagsProvider` 상위 10개
- 자동완성: `tagSearchProvider(query)` — 500ms 디바운스
- 선택 태그 chip: `InputChip` with trailing delete icon
- 최대 5개 초과 시 추가 선택 비활성

### 6. 홈 피드 최종 구조

```
홈 피드:
  ├─ [SliverAppBar] 밍릿 로고 + 알림 + 검색
  ├─ [기존] ExploreFilterChipBar (추천순/마감임박/가까운날짜)
  ├─ [신규] 인기 태그 칩바 (가로 스크롤, 복수 선택 OR 필터)
  ├─ [신규] 🔥 핫 태그 (트렌딩, 가로 스크롤 카드)
  ├─ [기존] 큐레이션 피드 (신규/마감임박/근처/얼리버드)
  ├─ [기존] AI 추천 (임베딩 기반)
  └─ [신규] 📌 관심사 추천 (태그 기반, 로그인 유저만)
```

---

## 데이터 소스

| UI 컴포넌트 | Provider | RPC/EF | 비고 |
|-------------|----------|--------|------|
| 홈 인기 태그 칩바 | `featuredTagsProvider` | `get_featured_tags()` | 5분 캐시 |
| 핫 태그 섹션 | `trendingTagsProvider` | `get_trending_tags()` | 5분 캐시 |
| 태그 이벤트 리스트 | `partiesByTagProvider(tagId)` | `get_parties_by_tag()` | 페이지네이션 |
| 이벤트 카드 태그 뱃지 | 기존 Event 모델 확장 | `events` JOIN `party_tags` + `tags` | 이벤트 조회 시 태그도 함께 반환 |
| 검색 태그 자동완성 | `tagSearchProvider(query)` | `search_tags()` | 디바운스 500ms |
| 온보딩 관심 태그 | `featuredTagsProvider` | `get_featured_tags()` | 동일 데이터 |
| 관심사 추천 피드 | `tagRecommendationFeedProvider` | `get_tag_recommendations()` | 로그인 유저만 |
| 파트너: 파티 태그 선택 | `featuredTagsProvider` + `tagSearchProvider` | 동일 | 파티 생성/수정 |

---

## 라우트 변경

### 유저 앱 (app_user)

| 변경 | 라우트 | 페이지 |
|------|--------|--------|
| **추가** | `/tags/:tagId` | `TagEventListPage` — 태그별 이벤트 리스트 |
| **추가** | `/onboarding/interests` | `InterestSelectionPage` — 관심 태그 선택 (온보딩) |
| **수정** | `/` | `HomePage` — 인기 태그 칩바 + 핫 태그 + 관심사 추천 섹션 추가 |
| **수정** | `/search` | `SearchPage` — 태그 자동완성 섹션 추가 |

### 파트너 앱 (app_partner)

| 변경 | 라우트 | 페이지 |
|------|--------|--------|
| **수정** | `/parties/create` | Step 1에 태그 선택 UI 추가 |
| **수정** | `/parties/:partyId/edit` | 동일 |

---

## 에러/로딩 상태

| 섹션 | 로딩 | 에러 | 빈 상태 |
|------|------|------|---------|
| 인기 태그 칩바 | Shimmer 플레이스홀더 (5개 칩 모양) | 섹션 숨김 (silent fail) | 섹션 숨김 |
| 핫 태그 | Shimmer 카드 (3개) | 섹션 숨김 | 섹션 숨김 (데이터 부족) |
| 태그 이벤트 리스트 | 기존 이벤트 카드 Shimmer | 재시도 버튼 + 에러 메시지 | "아직 이 태그의 이벤트가 없어요" |
| 태그 자동완성 | 인라인 로딩 인디케이터 | silent fail (이벤트 검색만 표시) | "일치하는 태그가 없어요" |
| 온보딩 관심 태그 | 중앙 로딩 인디케이터 | 재시도 버튼 | 건너뛰기 안내 |
| 관심사 추천 피드 | Shimmer 카드 (2개) | 섹션 숨김 | 섹션 숨김 (관심 태그 미설정 시) |
| 파트너 태그 선택 | 인라인 로딩 | 재시도 버튼 | 직접 입력 안내 |

---

## 구현 이슈 분할 (예상)

| 순서 | 제목 | 의존성 | 앱 |
|------|------|--------|-----|
| 1 | DB 스키마: tags, party_tags, user_interest_tags + RLS + 트리거 | 없음 | backend |
| 2 | 시드 데이터: 인기 태그 25개 INSERT | #1 | backend |
| 3 | RPC: get_featured_tags, get_trending_tags, search_tags | #1 | backend |
| 4 | RPC: get_parties_by_tag, get_tag_recommendations | #1 | backend |
| 5 | EF: create-party / update-party에 tag_ids 파라미터 추가 | #1 | backend |
| 6 | pgTAP: 태그 스키마 + RPC 테스트 | #3, #4 | backend |
| 7 | Dart 모델: Tag (Freezed) + TagRepository | #3 | shared |
| 8 | Provider: featuredTagsProvider, trendingTagsProvider, tagSearchProvider | #7 | shared |
| 9 | 유저 앱: 홈 인기 태그 칩바 + 필터링 | #8 | app_user |
| 10 | 유저 앱: 핫 태그 섹션 | #8 | app_user |
| 11 | 유저 앱: TagEventListPage (/tags/:tagId) | #8 | app_user |
| 12 | 유저 앱: 이벤트 카드 태그 뱃지 | #7 | app_user |
| 13 | 유저 앱: 검색 태그 자동완성 | #8 | app_user |
| 14 | 유저 앱: 온보딩 관심 태그 선택 | #8 | app_user |
| 15 | 유저 앱: 관심사 추천 피드 섹션 | #14 | app_user |
| 16 | 파트너 앱: 파티 생성 Step 1 태그 선택 | #8, #5 | app_partner |
| 17 | 파트너 앱: 파티 편집 태그 수정 | #16 | app_partner |

**Phase 1 (MVP):** #1~#12 — DB + API + 홈 피드 태그 칩바 + 이벤트 카드 뱃지 + 파트너 태그 입력
**Phase 2:** #13~#15 — 검색 통합 + 온보딩 + 관심사 추천
**Phase 3 (후속):** 핫 태그 고도화 (시간대/지역별), 태그 자동 추천 (당근 패턴)
