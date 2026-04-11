# 태그 기반 이벤트 발견 (Tag Discovery) — 테스트 보강 계획

## 계층별 테스트 계획

### Layer 1: Database 테스트 (pgTAP)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| 스키마: `tags` | `supabase/tests/database/60_tag_discovery_schema_test.sql` | `tags` 테이블 존재 + 모든 컬럼 (id, name, is_featured, usage_count, created_at) | P1 |
| | | `name` UNIQUE 제약조건 | P1 |
| | | `is_featured` default false, `usage_count` default 0 | P2 |
| 스키마: `party_tags` | 동일 | `party_tags` 테이블 존재 + PK (party_id, tag_id) | P1 |
| | | `party_id` FK → `parties(id)` ON DELETE CASCADE | P1 |
| | | `tag_id` FK → `tags(id)` ON DELETE CASCADE | P1 |
| 스키마: `user_interest_tags` | 동일 | `user_interest_tags` 테이블 존재 + PK (user_id, tag_id) | P1 |
| | | `user_id` FK → `auth.users(id)` ON DELETE CASCADE | P1 |
| | | `tag_id` FK → `tags(id)` ON DELETE CASCADE | P1 |
| 스키마: `tag_usage_daily` | 동일 | `tag_usage_daily` 테이블 존재 + PK (tag_id, date) | P1 |
| | | `daily_count` default 0 | P2 |
| 트리거: usage_count | 동일 | `party_tags` INSERT → `tags.usage_count` +1 | P1 |
| | | `party_tags` DELETE → `tags.usage_count` -1 | P1 |
| | | 동일 태그에 여러 파티 연결 → usage_count 정확히 누적 | P2 |
| | | usage_count가 0 미만으로 내려가지 않음 (방어) | P3 |
| RLS: `tags` | `supabase/tests/database/61_tag_discovery_rls_test.sql` | 인증되지 않은 사용자 읽기 가능 (public read) | P1 |
| | | 일반 유저 INSERT/UPDATE/DELETE 차단 | P1 |
| | | admin 역할 INSERT/UPDATE/DELETE 가능 | P2 |
| RLS: `party_tags` | 동일 | 인증되지 않은 사용자 읽기 가능 (public read) | P1 |
| | | 파티 소유 파트너 멤버 INSERT/DELETE 가능 | P1 |
| | | 비소유 파트너 INSERT/DELETE 차단 | P1 |
| | | 일반 유저 INSERT/DELETE 차단 | P2 |
| RLS: `user_interest_tags` | 동일 | 본인 데이터 읽기/쓰기 가능 (auth.uid() = user_id) | P1 |
| | | 타인 데이터 읽기/쓰기 차단 | P1 |
| | | 인증되지 않은 사용자 접근 차단 | P2 |
| 시드 데이터 | 동일 | 인기 태그 25개 존재 확인 (is_featured=true) | P1 |
| | | 각 태그 name 유니크 + 비어있지 않음 | P2 |
| RPC: `get_featured_tags()` | `supabase/tests/database/62_tag_discovery_rpc_test.sql` | is_featured=true인 태그만 반환 | P1 |
| | | usage_count DESC 정렬 | P1 |
| | | is_featured=false 태그 미포함 | P2 |
| | | 결과 없을 때 빈 배열 | P3 |
| RPC: `get_trending_tags(limit, days)` | 동일 | 최근 N일간 daily_count 합산 상위 반환 | P1 |
| | | limit 파라미터 적용 (10개 요청 시 10개 이하) | P1 |
| | | days 파라미터 범위 밖 데이터 제외 | P1 |
| | | tag_usage_daily 데이터 없으면 빈 배열 | P2 |
| | | 동일 합산 수치일 때 정렬 안정성 | P3 |
| RPC: `get_parties_by_tag(tag_id, limit, offset)` | 동일 | 해당 태그의 활성 이벤트만 반환 | P1 |
| | | startTime ASC 정렬 | P1 |
| | | limit/offset 페이지네이션 동작 | P1 |
| | | 종료/취소된 이벤트 미포함 | P1 |
| | | 태그에 연결된 이벤트 없으면 빈 배열 | P2 |
| | | 존재하지 않는 tag_id → 빈 배열 | P2 |
| RPC: `get_tag_recommendations(user_id, limit)` | 동일 | 유저 관심 태그와 매칭되는 이벤트 반환 | P1 |
| | | 관심 태그 미설정 유저 → 빈 배열 | P1 |
| | | 복수 관심 태그 매칭 시 스코어 높은 순 | P2 |
| | | limit 파라미터 적용 | P2 |
| | | 비활성 이벤트 미포함 | P2 |
| RPC: `search_tags(query)` | 동일 | PGroonga prefix match 동작 (예: "러" → "러닝", "러닝크루") | P1 |
| | | 빈 쿼리 → 빈 배열 또는 인기 태그 | P2 |
| | | 매칭 없는 쿼리 → 빈 배열 | P2 |
| | | 한글/영문 모두 검색 가능 | P2 |
| RPC: `upsert_user_interest_tags(tag_ids)` | 동일 | 정상 저장 (3개 태그) | P1 |
| | | 기존 태그 교체 (upsert 동작) | P1 |
| | | 최대 5개 초과 시 에러 | P1 |
| | | 빈 배열 → 기존 태그 전체 삭제 | P2 |
| | | 존재하지 않는 tag_id 포함 시 FK 에러 | P2 |
| party_tags 최대 5개 제한 | 동일 | 파티당 6번째 태그 INSERT 시 에러 또는 제한 | P1 |

### Layer 2: Edge Function 테스트 (Deno)

| EF | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `partner-manage-party` (create + tag_ids) | `supabase/functions/partner-manage-party/partner-manage-party_test.ts` (기존 파일에 추가) | action=create + tag_ids 3개 → 파티 생성 + party_tags 3행 생성 | P1 |
| | | action=create + tag_ids 미포함 → 파티 생성 (태그 없이) | P1 |
| | | action=create + tag_ids 6개 → 400 (최대 5개 초과) | P1 |
| | | action=create + 존재하지 않는 tag_id → 400/422 | P2 |
| | | action=create + tag_ids 빈 배열 → 파티 생성 (태그 없이) | P2 |
| `partner-manage-party` (update + tag_ids) | 동일 | action=update + tag_ids 변경 → 기존 party_tags 삭제 + 새로 INSERT | P1 |
| | | action=update + tag_ids로 태그 일부 변경 (2개→3개) | P1 |
| | | action=update + tag_ids 빈 배열 → 기존 태그 전체 제거 | P2 |
| | | action=update + tag_ids 6개 → 400 (최대 5개 초과) | P2 |
| | | action=update + tag_ids 미포함 → 기존 태그 유지 (변경 없음) | P2 |

### Layer 3: Repository 테스트 (minglit_kit)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `getFeaturedTags()` | `shared/packages/minglit_kit/test/src/data/repositories/tag_repository_test.dart` | happy path — 인기 태그 리스트 반환 + Tag 모델 매핑 | P1 |
| | | 빈 결과 → 빈 리스트 | P2 |
| | | Supabase 에러 → MingleException throw | P2 |
| `getTrendingTags()` | 동일 | happy path — limit, days 파라미터 전달 + 결과 반환 | P1 |
| | | 기본값 적용 (limit=10, days=7) | P2 |
| | | Supabase 에러 → MingleException throw | P2 |
| `getPartiesByTag()` | 동일 | happy path — tagId로 이벤트 리스트 반환 | P1 |
| | | 페이지네이션 파라미터 (limit, offset) 전달 확인 | P1 |
| | | 빈 결과 → 빈 리스트 | P2 |
| | | Supabase 에러 → MingleException throw | P2 |
| `getTagRecommendations()` | 동일 | happy path — 추천 이벤트 리스트 반환 | P1 |
| | | limit 파라미터 전달 확인 | P2 |
| | | Supabase 에러 → MingleException throw | P2 |
| `searchTags()` | 동일 | happy path — 쿼리 문자열 전달 + 매칭 태그 반환 | P1 |
| | | 빈 결과 → 빈 리스트 | P2 |
| | | Supabase 에러 → MingleException throw | P3 |
| `upsertUserInterestTags()` | 동일 | happy path — tag_ids 전달 + 성공 | P1 |
| | | Supabase 에러 → MingleException throw | P2 |

### Layer 3.5: Model 테스트 (minglit_kit)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `Tag` (Freezed) | `shared/packages/minglit_kit/test/src/data/models/tag_test.dart` | JSON → Tag 역직렬화 (전체 필드) | P1 |
| | | isFeatured 기본값 false | P2 |
| | | usageCount 기본값 0 | P2 |
| | | copyWith 동작 | P3 |
| | | equality (동일 id → 동일 객체) | P3 |

### Layer 4: Controller/Provider 테스트

#### 4.1 유저 앱 (app_user)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `featuredTagsProvider` | `apps/app_user/test/src/features/home/logic/featured_tags_provider_test.dart` | 초기 로드 → loading → data 상태 전환 | P1 |
| | | 5분 keepAlive 캐시 동작 | P2 |
| | | 에러 시 error 상태 | P2 |
| `trendingTagsProvider` | `apps/app_user/test/src/features/home/logic/trending_tags_provider_test.dart` | 초기 로드 → loading → data 상태 전환 | P1 |
| | | 5분 keepAlive 캐시 동작 | P2 |
| | | 에러 시 error 상태 | P2 |
| `partiesByTagProvider` | `apps/app_user/test/src/features/tag/logic/parties_by_tag_provider_test.dart` | 초기 로드 → 첫 페이지 반환 | P1 |
| | | 다음 페이지 로드 (offset 증가) | P1 |
| | | 마지막 페이지 (결과 < limit) → hasMore false | P1 |
| | | 빈 결과 → 빈 리스트 + hasMore false | P2 |
| | | 에러 시 error 상태 | P2 |
| `userInterestTagsProvider` | `apps/app_user/test/src/features/onboarding/logic/user_interest_tags_provider_test.dart` | 초기 로드 → 본인 관심 태그 리스트 | P1 |
| | | upsert 호출 → invalidate + 재로드 | P1 |
| | | 관심 태그 미설정 → 빈 리스트 | P2 |
| | | 에러 시 error 상태 | P2 |
| `tagSearchProvider` | `apps/app_user/test/src/features/search/logic/tag_search_provider_test.dart` | 쿼리 입력 → 매칭 태그 반환 | P1 |
| | | 500ms 디바운스 동작 (빠른 연속 입력 시 마지막만 호출) | P1 |
| | | 빈 쿼리 → 빈 결과 또는 미호출 | P2 |
| | | 에러 시 error 상태 | P3 |
| `tagRecommendationFeedProvider` | `apps/app_user/test/src/features/home/logic/tag_recommendation_feed_provider_test.dart` | 초기 로드 → 추천 이벤트 반환 | P1 |
| | | 다음 페이지 로드 (페이지네이션) | P1 |
| | | 5분 keepAlive 캐시 동작 | P2 |
| | | 관심 태그 없는 유저 → 빈 결과 | P2 |
| | | 에러 시 error 상태 | P2 |

#### 4.2 파트너 앱 (app_partner)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| 파티 생성 태그 선택 컨트롤러 | `apps/app_partner/test/src/features/party/logic/party_tag_selection_controller_test.dart` | 태그 추가 (1개 선택) | P1 |
| | | 태그 제거 (선택 해제) | P1 |
| | | 최대 5개 초과 시 추가 차단 | P1 |
| | | 인기 태그 퀵 선택 → 선택 리스트에 추가 | P1 |
| | | 자동완성 검색 → tagSearchProvider 호출 | P1 |
| | | 이미 선택된 태그 중복 추가 방지 | P2 |
| | | 선택 태그 순서 유지 | P3 |
| 파티 수정 태그 로드 | 동일 | 기존 파티 태그 초기 로드 | P1 |
| | | 태그 변경 후 저장 → EF에 tag_ids 전달 | P1 |

### Layer 5: Widget/UI 테스트

#### 5.1 유저 앱 (app_user)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| 인기 태그 칩바 | `apps/app_user/test/src/features/home/ui/featured_tag_chip_bar_test.dart` | 인기 태그 5개 → FilterChip 5개 렌더링 | P1 |
| | | 칩 탭 → selected 상태 (filled + 체크마크) | P1 |
| | | 복수 선택 가능 (OR 필터) | P1 |
| | | 선택 해제 동작 | P1 |
| | | 가로 스크롤 동작 (7개 이상 태그) | P2 |
| | | 로딩 → shimmer 5개 칩 표시 | P2 |
| | | 에러 → 섹션 숨김 | P2 |
| | | 빈 데이터 → 섹션 숨김 | P2 |
| 핫 태그 섹션 | `apps/app_user/test/src/features/home/ui/hot_tags_section_test.dart` | 트렌딩 태그 3개 → 카드 3개 렌더링 (태그명 + 건수) | P1 |
| | | 카드 탭 → 태그 이벤트 페이지 이동 | P1 |
| | | 가로 스크롤 동작 | P2 |
| | | 로딩 → shimmer 카드 3개 | P2 |
| | | 에러 → 섹션 숨김 | P2 |
| | | 데이터 부족 (0~1개) → 섹션 숨김 | P2 |
| TagEventListPage | `apps/app_user/test/src/features/tag/ui/tag_event_list_page_test.dart` | AppBar에 태그명 표시 | P1 |
| | | 이벤트 3건 → EventCard 3개 렌더링 | P1 |
| | | 무한 스크롤 → 다음 페이지 로드 트리거 | P1 |
| | | 빈 상태 → "아직 이 태그의 이벤트가 없어요" + 홈 이동 버튼 | P1 |
| | | 로딩 → shimmer 이벤트 카드 | P2 |
| | | 에러 → 재시도 버튼 + 에러 메시지 | P2 |
| 이벤트 카드 태그 뱃지 | `apps/app_user/test/src/features/home/ui/event_card_tag_badges_test.dart` | 태그 2개 → 뱃지 2개 표시 | P1 |
| | | 태그 5개 → 뱃지 3개 + "+2" 표시 | P1 |
| | | 태그 0개 → 뱃지 영역 미표시 | P1 |
| | | 뱃지 탭 → 해당 태그 페이지 이동 | P2 |
| | | 태그 정확히 3개 → 뱃지 3개, +N 없음 | P2 |
| 검색 태그 자동완성 | `apps/app_user/test/src/features/search/ui/search_tag_autocomplete_test.dart` | 검색어 입력 → 태그 섹션에 매칭 태그 표시 | P1 |
| | | 태그가 이벤트 결과보다 위에 표시 | P1 |
| | | 태그 탭 → 태그 이벤트 페이지 이동 | P1 |
| | | 인라인 로딩 인디케이터 | P2 |
| | | 매칭 없음 → "일치하는 태그가 없어요" | P2 |
| | | 검색어 없을 때 인기 태그 표시 | P3 |
| 온보딩 관심 태그 선택 | `apps/app_user/test/src/features/onboarding/ui/interest_selection_page_test.dart` | 인기 태그 그리드 렌더링 (3열 Wrap) | P1 |
| | | 태그 탭 → 선택 상태 토글 (secondary 배경 + 보더) | P1 |
| | | 3개 미만 선택 → "다음" 버튼 비활성 | P1 |
| | | 3개 이상 선택 → "다음" 버튼 활성 + 선택 수 표시 (예: "다음 (3/5)") | P1 |
| | | 6개째 선택 시도 → 추가 차단 (최대 5개) | P1 |
| | | "건너뛰기" 버튼 → upsert 미호출 + 다음 화면 이동 | P1 |
| | | "다음" 탭 → upsert_user_interest_tags 호출 + 다음 화면 이동 | P1 |
| | | 로딩 → 중앙 로딩 인디케이터 | P2 |
| | | 에러 → 재시도 버튼 | P2 |
| 관심사 추천 피드 섹션 | `apps/app_user/test/src/features/home/ui/tag_recommendation_section_test.dart` | 추천 이벤트 2건 → 카드 2개 렌더링 | P1 |
| | | 비로그인 유저 → 섹션 숨김 | P1 |
| | | 관심 태그 미설정 → 섹션 숨김 | P1 |
| | | 로딩 → shimmer 카드 2개 | P2 |
| | | 에러 → 섹션 숨김 | P2 |

#### 5.2 파트너 앱 (app_partner)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| 파티 생성 태그 선택 UI | `apps/app_partner/test/src/features/party/ui/party_tag_selection_test.dart` | 자동완성 입력 필드 렌더링 | P1 |
| | | 인기 태그 퀵 선택 칩 표시 (상위 10개) | P1 |
| | | 인기 태그 탭 → 선택 태그에 추가 | P1 |
| | | 자동완성 입력 → 매칭 태그 드롭다운 표시 | P1 |
| | | 선택 태그 InputChip 렌더링 + 삭제 아이콘 | P1 |
| | | 삭제 아이콘 탭 → 태그 제거 | P1 |
| | | 5개 선택 상태에서 추가 선택 비활성 | P1 |
| | | 인라인 로딩 표시 (자동완성 검색 중) | P2 |
| | | 에러 → 재시도 버튼 | P2 |
| | | 매칭 태그 없음 → 안내 텍스트 | P2 |
| 파티 수정 태그 UI | `apps/app_partner/test/src/features/party/ui/party_tag_edit_test.dart` | 기존 태그 초기 표시 (InputChip) | P1 |
| | | 태그 추가/삭제 후 저장 동작 | P1 |

### Layer 6: Golden 테스트 (시각적 회귀)

#### 6.1 유저 앱 (app_user)

| 화면 | 변형 | 테스트 파일 | 우선순위 |
|------|------|-----------|---------|
| 인기 태그 칩바 | 5개 태그 미선택 (light/dark) | `apps/app_user/test/goldens/featured_tag_chip_bar_golden_test.dart` | P2 |
| | 2개 태그 선택 (light/dark) | 동일 | P2 |
| | shimmer 로딩 (light/dark) | 동일 | P3 |
| 핫 태그 섹션 | 카드 3개 (light/dark) | `apps/app_user/test/goldens/hot_tags_section_golden_test.dart` | P2 |
| | shimmer 로딩 (light/dark) | 동일 | P3 |
| TagEventListPage | 이벤트 3건 (light/dark) | `apps/app_user/test/goldens/tag_event_list_page_golden_test.dart` | P2 |
| | 빈 상태 (light/dark) | 동일 | P3 |
| 이벤트 카드 태그 뱃지 | 태그 3개 (light/dark) | `apps/app_user/test/goldens/event_card_tag_badges_golden_test.dart` | P2 |
| | 태그 5개 + "+2" (light/dark) | 동일 | P3 |
| 온보딩 관심 태그 | 태그 25개 그리드 미선택 (light/dark) | `apps/app_user/test/goldens/interest_selection_page_golden_test.dart` | P2 |
| | 4개 태그 선택 (light/dark) | 동일 | P2 |
| 관심사 추천 섹션 | 추천 카드 2건 (light/dark) | `apps/app_user/test/goldens/tag_recommendation_section_golden_test.dart` | P3 |

#### 6.2 파트너 앱 (app_partner)

| 화면 | 변형 | 테스트 파일 | 우선순위 |
|------|------|-----------|---------|
| 태그 선택 UI | 미선택 + 인기 태그 표시 (light/dark) | `apps/app_partner/test/goldens/party_tag_selection_golden_test.dart` | P2 |
| | 3개 선택 + 자동완성 드롭다운 (light/dark) | 동일 | P3 |

## 실행 순서

**P1 (필수): 82건**
- pgTAP 스키마 + FK + PK (10건)
- pgTAP 트리거 usage_count 증감 (2건)
- pgTAP RLS 핵심 정책 (7건)
- pgTAP 시드 데이터 (1건)
- pgTAP RPC 핵심 동작 (16건)
- pgTAP party_tags 최대 5개 제한 (1건)
- Edge Function create/update happy path + 검증 (5건)
- Repository happy path (6건)
- Tag 모델 역직렬화 (1건)
- Controller/Provider 핵심 상태 전환 (14건)
- Widget 핵심 렌더링 + 인터랙션 (19건)

**P2 (권장): 62건**
- pgTAP 스키마 기본값 + 추가 RLS + 시드 검증 (8건)
- pgTAP RPC 엣지 케이스 (12건)
- Edge Function 엣지 케이스 (5건)
- Repository 빈 결과 + 에러 핸들링 (9건)
- Tag 모델 기본값 (2건)
- Controller/Provider 캐시 + 에러 + 엣지 케이스 (12건)
- Widget 로딩/에러/빈 상태 + 부가 인터랙션 (14건)

**P3 (선택): 18건**
- pgTAP usage_count 방어 + RPC 빈 결과/정렬 안정성 (3건)
- Repository 에러 추가 (1건)
- Tag 모델 copyWith + equality (2건)
- Controller 순서 유지 + 디바운스 에러 (2건)
- Widget 부가 UI (검색어 없을 때 인기 태그 등) (1건)
- Golden 추가 변형 (9건)

**총 162건**
