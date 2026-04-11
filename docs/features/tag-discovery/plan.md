# 태그 기반 이벤트 발견 (Tag Discovery) — 기술 설계

## 개요

태그 시스템을 도입하여 유저가 관심사 기반으로 이벤트를 탐색할 수 있게 한다.
카테고리 없이 태그 단일 시스템으로 운영하며, 인기 태그(`is_featured`)가 카테고리 역할을 수행한다.

**출처 이슈**: #1136, #558
**스펙**: `docs/features/tag-discovery/spec.md`
**테스트 계획**: `docs/features/tag-discovery/test-plan.md`

## Phase 1 MVP 범위 (이번 구현)

4월 말까지 아래를 구현한다:

1. DB 스키마 (4 테이블) + RLS + 트리거 + 시드 데이터
2. RPC 함수 6개
3. Edge Function 변경 (partner-manage-party에 tag_ids 추가)
4. Dart 모델 (Tag) + TagRepository
5. Riverpod Provider (featured, trending, search, partiesByTag, userInterests, tagRecommendation)
6. 유저 앱: 홈 인기 태그 칩바 + 핫 태그 섹션 + 태그 이벤트 리스트 + 이벤트 카드 태그 뱃지
7. 파트너 앱: 파티 생성/수정 태그 선택

Phase 2 (후속): 검색 자동완성, 온보딩 관심 태그, 관심사 추천 피드

## 구현 이슈 분할

| 순서 | 제목 | 의존성 | 비고 |
|------|------|--------|------|
| 1 | DB: tags, party_tags, user_interest_tags, tag_usage_daily + RLS + 트리거 + 시드 | 없음 | Migration + pgTAP |
| 2 | RPC: 6개 함수 (get_featured_tags 등) | #1 | RPC + pgTAP |
| 3 | EF: partner-manage-party tag_ids 파라미터 추가 | #1 | create/update 양쪽 |
| 4 | Flutter: Tag 모델 + TagRepository + Provider | #2 | minglit_kit |
| 5 | Flutter: 유저 앱 태그 UI (칩바, 핫태그, 태그 리스트, 카드 뱃지) | #4 | app_user |
| 6 | Flutter: 파트너 앱 파티 태그 선택 | #4, #3 | app_partner |

## 수정 대상 파일

### 백엔드 — DB Migration

| 파일 | 변경 내용 |
|------|----------|
| **신규** `supabase/migrations/20260407000001_tag_discovery.sql` | 4 테이블 생성 + RLS + 트리거 + PGroonga 인덱스 + 시드 데이터 25개 |
| **신규** `supabase/tests/database/60_tag_discovery_schema_test.sql` | pgTAP: 스키마 4테이블 + FK + 제약조건 + 트리거 |
| **신규** `supabase/tests/database/61_tag_discovery_rls_test.sql` | pgTAP: RLS 정책 (tags, party_tags, user_interest_tags) |
| **신규** `supabase/tests/database/62_tag_discovery_rpc_test.sql` | pgTAP: RPC 6함수 테스트 |

### Migration 상세: `20260407000001_tag_discovery.sql`

```sql
-- 1. tags 테이블
CREATE TABLE tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  is_featured boolean DEFAULT false,
  usage_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- PGroonga 인덱스 (태그 검색용)
CREATE INDEX idx_tags_name_pgroonga ON tags USING pgroonga (name pgroonga_text_term_search_ops_v2);

-- 2. party_tags 테이블
CREATE TABLE party_tags (
  party_id uuid REFERENCES parties(id) ON DELETE CASCADE,
  tag_id uuid REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (party_id, tag_id)
);

-- party_tags 최대 5개 제한 (트리거로 구현)
CREATE OR REPLACE FUNCTION check_party_tags_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT count(*) FROM party_tags WHERE party_id = NEW.party_id) >= 5 THEN
    RAISE EXCEPTION 'A party can have at most 5 tags';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_party_tags_limit
  BEFORE INSERT ON party_tags
  FOR EACH ROW EXECUTE FUNCTION check_party_tags_limit();

-- 3. user_interest_tags 테이블
CREATE TABLE user_interest_tags (
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  tag_id uuid REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, tag_id)
);

-- user_interest_tags 최대 5개 제한
CREATE OR REPLACE FUNCTION check_user_interest_tags_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT count(*) FROM user_interest_tags WHERE user_id = NEW.user_id) >= 5 THEN
    RAISE EXCEPTION 'A user can have at most 5 interest tags';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_interest_tags_limit
  BEFORE INSERT ON user_interest_tags
  FOR EACH ROW EXECUTE FUNCTION check_user_interest_tags_limit();

-- 4. tag_usage_daily 테이블 (트렌딩 계산용)
CREATE TABLE tag_usage_daily (
  tag_id uuid REFERENCES tags(id) ON DELETE CASCADE,
  date date NOT NULL DEFAULT CURRENT_DATE,
  daily_count integer NOT NULL DEFAULT 0,
  PRIMARY KEY (tag_id, date)
);

-- usage_count 자동 증감 트리거
CREATE OR REPLACE FUNCTION update_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
    -- tag_usage_daily upsert
    INSERT INTO tag_usage_daily (tag_id, date, daily_count)
    VALUES (NEW.tag_id, CURRENT_DATE, 1)
    ON CONFLICT (tag_id, date) DO UPDATE SET daily_count = tag_usage_daily.daily_count + 1;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tags SET usage_count = GREATEST(usage_count - 1, 0) WHERE id = OLD.tag_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_tag_usage
  AFTER INSERT OR DELETE ON party_tags
  FOR EACH ROW EXECUTE FUNCTION update_tag_usage_count();

-- RLS 정책
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE party_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interest_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_usage_daily ENABLE ROW LEVEL SECURITY;

-- tags: 전체 읽기, admin만 쓰기
CREATE POLICY tags_read ON tags FOR SELECT USING (true);
CREATE POLICY tags_admin_insert ON tags FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY tags_admin_update ON tags FOR UPDATE USING (
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY tags_admin_delete ON tags FOR DELETE USING (
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);

-- party_tags: 전체 읽기, 파트너 멤버 쓰기 (service_role로 EF에서 처리하므로 간소화)
CREATE POLICY party_tags_read ON party_tags FOR SELECT USING (true);
CREATE POLICY party_tags_service ON party_tags FOR ALL USING (
  (SELECT current_setting('role', true)) = 'service_role'
);

-- user_interest_tags: 본인만
CREATE POLICY user_interest_tags_own ON user_interest_tags FOR ALL USING (auth.uid() = user_id);

-- tag_usage_daily: 읽기 전체, 쓰기는 service_role/트리거
CREATE POLICY tag_usage_daily_read ON tag_usage_daily FOR SELECT USING (true);
CREATE POLICY tag_usage_daily_service ON tag_usage_daily FOR ALL USING (
  (SELECT current_setting('role', true)) = 'service_role'
);

-- 시드 데이터: 인기 태그 25개
INSERT INTO tags (name, is_featured) VALUES
  ('소개팅', true), ('미팅', true), ('네트워킹', true),
  ('운동', true), ('러닝', true), ('등산', true),
  ('맛집', true), ('와인', true), ('커피', true),
  ('파티', true), ('클럽', true), ('루프탑', true),
  ('스터디', true), ('독서', true), ('영화', true),
  ('음악', true), ('공연', true), ('전시', true),
  ('여행', true), ('캠핑', true), ('야외', true),
  ('소규모', true), ('대규모', true), ('20대', true), ('30대', true);
```

### RPC 함수 상세

| 함수 | 구현 방식 |
|------|----------|
| `get_featured_tags()` | `SELECT * FROM tags WHERE is_featured = true ORDER BY usage_count DESC` |
| `get_trending_tags(p_limit int, p_days int)` | `tag_usage_daily`에서 최근 `p_days`일 `SUM(daily_count)` 상위 `p_limit`개 반환, `tags` JOIN |
| `get_parties_by_tag(p_tag_id uuid, p_limit int, p_offset int)` | `party_tags` → `events` JOIN, 활성 이벤트만 (`status = 'scheduled'`, `start_time > now()`), `start_time ASC`, LIMIT/OFFSET |
| `get_tag_recommendations(p_limit int)` | `user_interest_tags` ∩ `party_tags` → `events` JOIN, 매칭 태그 수 DESC 정렬 (`status = 'scheduled'`) |
| `search_tags(p_query text)` | PGroonga prefix match on `tags.name`, LIMIT 10 |
| `upsert_user_interest_tags(p_tag_ids uuid[])` | `array_length` ≤ 5 검증 → DELETE 기존 → INSERT 새로운 태그 |

### 백엔드 — Edge Function

| 파일 | 변경 내용 |
|------|----------|
| **수정** `supabase/functions/partner-manage-party/index.ts` | `tag_ids` 파라미터 추가 (create/update 양쪽) |
| **수정** `supabase/functions/partner-manage-party/partner-manage-party_test.ts` | tag_ids 관련 테스트 케이스 추가 |

#### EF 변경 상세

**create 액션**: 파티 생성 후 `tag_ids`가 있으면:
1. `tag_ids` 배열 검증 (최대 5개, UUID 형식)
2. `party_tags`에 INSERT

**update 액션**: `tag_ids`가 body에 포함되면:
1. 기존 `party_tags` 전체 DELETE (해당 party_id)
2. 새 `tag_ids`로 INSERT (빈 배열이면 전체 제거)

### 프론트엔드 — 모델/Repository (minglit_kit)

| 파일 | 변경 내용 |
|------|----------|
| **신규** `shared/packages/minglit_kit/lib/src/data/models/tag.dart` | `Tag` 모델 (freezed): id, name, isFeatured, usageCount |
| **신규** `shared/packages/minglit_kit/lib/src/data/repositories/tag_repository.dart` | `TagRepository` + provider (keepAlive: true) |
| **신규** `shared/packages/minglit_kit/lib/src/data/repositories/tag_repository_queries.dart` | 읽기 메서드 (getFeaturedTags, getTrendingTags, getPartiesByTag, getTagRecommendations, searchTags) |
| **신규** `shared/packages/minglit_kit/lib/src/data/repositories/tag_repository_commands.dart` | 쓰기 메서드 (upsertUserInterestTags) |
| **수정** `shared/packages/minglit_kit/lib/minglit_kit.dart` | Tag 모델 + TagRepository export 추가 |
| **수정** `shared/packages/minglit_kit/lib/src/data/models/event.dart` | `List<Tag>? tags` 필드 추가 (includeToJson: false) |
| **수정** `shared/packages/minglit_kit/lib/src/data/models/party.dart` | `List<Tag>? tags` 필드 추가 (includeToJson: false) |
| **신규** `shared/packages/minglit_kit/test/src/data/repositories/tag_repository_test.dart` | Repository 테스트 |

### 프론트엔드 — Provider (minglit_kit)

| 파일 | 변경 내용 |
|------|----------|
| **신규** `shared/packages/minglit_kit/lib/src/logic/providers/tag_providers.dart` | featuredTagsProvider, trendingTagsProvider, tagSearchProvider (family), tagRecommendationFeedProvider |

### 프론트엔드 — 유저 앱 (app_user)

| 파일 | 변경 내용 |
|------|----------|
| **신규** `apps/app_user/lib/src/features/tag/` | 태그 피처 디렉토리 |
| **신규** `apps/app_user/lib/src/features/tag/ui/tag_event_list_page.dart` | `/tags/:tagId` — 태그별 이벤트 리스트 (무한 스크롤) |
| **신규** `apps/app_user/lib/src/features/tag/logic/tag_event_list_controller.dart` | 태그 이벤트 리스트 페이지네이션 컨트롤러 |
| **신규** `apps/app_user/lib/src/features/tag/logic/tag_coordinator.dart` | 태그 관련 네비게이션 |
| **신규** `apps/app_user/lib/src/features/home/widgets/featured_tag_chip_bar.dart` | 홈 인기 태그 칩바 (가로 스크롤, 복수 선택) |
| **신규** `apps/app_user/lib/src/features/home/widgets/trending_tag_section.dart` | 🔥 핫 태그 섹션 (가로 스크롤 카드) |
| **신규** `apps/app_user/lib/src/features/home/logic/selected_tags_provider.dart` | 선택된 태그 상태 (OR 필터링용) |
| **수정** `apps/app_user/lib/src/features/home/home_page.dart` | 태그 칩바 + 핫 태그 섹션 추가 |
| **수정** `apps/app_user/lib/src/routing/app_routes.dart` | `/tags/:tagId` 라우트 추가 |
| **수정** `shared/packages/minglit_kit/lib/src/ui/widgets/party/event_card.dart` | 태그 뱃지 표시 (최대 3개 + `+N`) |
| **신규** `apps/app_user/test/src/features/tag/` | 태그 피처 테스트 |

### 프론트엔드 — 파트너 앱 (app_partner)

| 파일 | 변경 내용 |
|------|----------|
| **신규** `apps/app_partner/lib/src/features/party/create/widgets/tag_selection_section.dart` | 태그 선택 UI (인기 태그 퀵 선택 + 검색 + 선택 칩) |
| **신규** `apps/app_partner/lib/src/features/party/create/logic/tag_selection_controller.dart` | 태그 선택 상태 관리 (최대 5개) |
| **수정** `apps/app_partner/lib/src/features/party/create/steps/step1_basic_info.dart` | 태그 선택 섹션 추가 |
| **수정** `apps/app_partner/lib/src/features/party/create/party_create_wizard_controller.dart` | tag_ids 필드 추가 |
| **수정** `apps/app_partner/lib/src/features/party/create/party_create_wizard_submit.dart` | EF 호출 시 tag_ids 포함 |
| **수정** `apps/app_partner/lib/src/features/party/create/party_create_wizard_load.dart` | 편집 시 기존 태그 로드 |
| **신규** `apps/app_partner/test/src/features/party/create/widgets/tag_selection_section_test.dart` | 위젯 테스트 |

## 작업 분배 (3 dev + 1 reviewer)

### dev-1: 백엔드 (DB + RPC + EF)

1. Migration 파일 작성 (4 테이블 + RLS + 트리거 + 시드)
2. RPC 함수 6개 작성
3. partner-manage-party EF에 tag_ids 추가
4. pgTAP 테스트 3개 파일
5. EF 테스트 케이스 추가

### dev-2: 공유 패키지 + 유저 앱

1. Tag 모델 (freezed) + TagRepository + Provider
2. Event/Party 모델에 tags 필드 추가
3. 유저 앱 태그 피처 (칩바, 핫태그, 태그 리스트 페이지)
4. EventCard 태그 뱃지
5. 라우트 추가
6. 유닛 테스트

### dev-3: 파트너 앱

1. 태그 선택 섹션 UI
2. 태그 선택 컨트롤러
3. 파티 생성 위저드에 태그 통합 (Step 1)
4. 파티 편집 시 기존 태그 로드
5. 위젯 테스트

### reviewer: 전체 코드 리뷰

## 설계 결정

### ADR-1: 카테고리 없이 태그 단일 시스템

- **결정**: `is_featured` 플래그로 인기 태그가 카테고리 역할 수행
- **근거**: 초기 이벤트 수가 적어 세분화된 카테고리는 빈 상태 유발. 태그가 더 유연.
- **리스크**: 태그 수 급증 시 관리 어려움 → `is_featured` 조정으로 대응 가능

### ADR-2: OR 필터 로직

- **결정**: 복수 태그 선택 시 하나라도 매칭되면 표시 (OR)
- **근거**: AND 로직은 소규모 카탈로그에서 zero-result 유발

### ADR-3: usage_count 트리거 + tag_usage_daily 이중 관리

- **결정**: party_tags INSERT/DELETE에 트리거로 usage_count 증감 + tag_usage_daily에 일별 기록
- **근거**: usage_count는 전체 누적용 (인기 태그 정렬), tag_usage_daily는 트렌딩 계산용 (최근 N일)
- **대안 기각**: pg_cron으로 일별 배치 집계 → 실시간성 부족, 트리거가 더 정확

### ADR-4: party_tags를 EF에서 관리 (RLS service_role)

- **결정**: party_tags 쓰기는 partner-manage-party EF 내에서 service_role로 처리
- **근거**: 기존 아키텍처에서 모든 mutation은 EF를 통해야 함 (EF-only 원칙). RLS로 파트너 멤버 검증하는 것보다 EF에서 이미 검증된 권한으로 처리하는 것이 일관적.
