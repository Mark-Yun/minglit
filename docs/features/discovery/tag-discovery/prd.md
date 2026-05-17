# PRD: 태그 기반 이벤트 발견 (Tag Discovery)

## Summary

이벤트 탐색을 하드코딩 피드타입과 제목 검색에서 태그 기반 관심사 탐색으로 확장한다. 인기 태그 칩바·핫 태그·관심사 추천 피드·태그 자동완성 검색을 추가해 cold-start 유저도 자신의 관심사로 이벤트를 찾을 수 있게 한다.

## Motivation / Problem to Solve

- 현재 발견 경로가 5개 하드코딩 피드(`신규`, `마감임박`, `근처`, `얼리버드`, `AI추천`)와 PGroonga 제목 검색뿐 — 관심사 기반 탐색 부재
- 신규 유저는 어떤 키워드로 검색해야 할지 모르는 cold-start 문제 (Meetup·Bumble 온보딩 패턴 부재)
- 파트너가 이벤트 분류 시 의지할 분류 체계 없음 — 운영팀이 큐레이션으로만 노출 제어
- 카테고리 체계는 이벤트 수가 적은 초기 단계에서 빈 카테고리를 양산 — 유연한 태그 + `is_featured` 플래그가 적합

## Goals

### Target Users

- **신규 유저**: 첫 실행 직후 관심사 선택 → 개인화된 피드 진입
- **기존 유저**: 홈 칩바/핫 태그/검색으로 새 이벤트 발견
- **파트너**: 이벤트 생성 시 태그 부여로 도달 범위 확장

### Key Goals

- **P0**: 인기 태그 칩바로 홈에서 한 탭에 태그별 이벤트 진입
- **P0**: 이벤트 카드에 태그 뱃지로 분류 가시화
- **P0**: 파트너 파티 생성/수정 시 최대 5개 태그 부여
- **P1**: 핫 태그(트렌딩) 섹션으로 급상승 관심사 노출
- **P1**: 온보딩에서 관심 태그 3개 이상 선택 → 관심사 추천 피드
- **P1**: 검색 시 태그 자동완성

### Non-Goals

- 카테고리/서브카테고리 2-tier 체계 — 이벤트 수가 적은 초기에 빈 카테고리 양산 위험. `is_featured`로 대체
- 태그 자동 추천(당근식 FastText) — Phase 3+ 후속
- 시간대·지역별 트렌딩 — 단순 누적 증가율만 V1
- 태그 합성/별칭 — 관리자가 수동 큐레이션

## Product Principles

1. **태그 단일 시스템**: 카테고리 테이블 없이 태그 하나로 통합. 인기 태그가 카테고리 역할 수행
2. **OR 필터**: 다중 태그 선택 시 하나라도 매칭되면 노출 (Bumble 패턴). AND 는 zero-result 유발
3. **점진적 노출**: 빈 데이터 섹션은 숨김. 캐치-22 회피
4. **유저 통제**: 관심 태그는 언제든 변경. 자동 추천에 갇히지 않게 함

## Technical Approach

- **화면**: 홈 피드(인기 태그 칩바 + 핫 태그 + 관심사 추천 섹션 신규), TagEventListPage(신규), 검색 페이지(자동완성 추가), 온보딩 InterestSelectionPage(신규), 파트너 파티 생성/편집(태그 입력 추가)
- **저장**: `tags`(마스터, `is_featured`/`usage_count`), `party_tags`(N:M), `user_interest_tags`(유저 선택), `tag_usage_daily`(트렌딩용 일별 스냅샷)
- **외부 의존성**: PGroonga(태그명 prefix match), pg_cron(일별 집계)
- **가드**: `tags` 읽기 public / 쓰기 admin. `party_tags` 쓰기 파티 소유 파트너만. `user_interest_tags` 본인만

## User Journey

### Scenario 1: 홈에서 인기 태그로 이벤트 탐색 (CUJ 1-x)

유저가 홈 피드 상단의 인기 태그 칩을 탭해 해당 태그 이벤트 리스트로 진입한다.

### Scenario 2: 검색 시 태그 자동완성 (CUJ 2-x)

유저가 검색창에 키워드 입력 → 태그 자동완성 섹션이 이벤트 결과 위에 표시되고, 태그 탭 시 태그 페이지로 이동한다.

### Scenario 3: 온보딩 관심 태그 선택 → 관심사 추천 피드 (CUJ 3-x)

신규 유저가 인증 완료 후 관심 태그 3개 이상 선택 → 홈 하단 관심사 추천 피드에 매칭 이벤트가 표시된다.

### Scenario 4: 파트너 파티 생성 시 태그 부여 (CUJ 4-x)

파트너가 파티 생성 위저드 Step 1에서 인기 태그/검색을 통해 최대 5개 태그를 부여한다.

## Data Flow

### Scenario 1

홈 진입 → 인기 태그 칩바 표시(get_featured_tags) → 칩 탭 → `/tags/:tagId` 이동 → 태그별 이벤트 리스트 로드(get_parties_by_tag, 페이지네이션)

### Scenario 2

검색창 입력(500ms 디바운스) → 태그 자동완성(search_tags) + 이벤트 검색(PGroonga) 병렬 → 자동완성 결과 상단, 이벤트 결과 하단 → 태그 탭 시 `/tags/:tagId`

### Scenario 3

온보딩 InterestSelectionPage → 3~5개 선택 → upsert_user_interest_tags → 홈 진입 → 관심사 추천 섹션(get_tag_recommendations) 노출

### Scenario 4

파티 위저드 Step 1 → 인기 태그 퀵 선택 또는 검색(search_tags) → 최대 5개 선택 → 다음 단계 → 저장 시 partner-manage-party EF 에 `tag_ids` 전달 → party_tags upsert

## KPIs / Success Metrics

- **태그 칩 클릭률**: 홈 진입 세션 중 칩바 탭 비율 — 베이스라인 측정 후 점진 증가
- **태그 페이지 → 이벤트 신청 전환율**: 태그 페이지 이탈률 < 70%
- **온보딩 관심 태그 선택률**: 신규 유저의 50% 이상이 3개 이상 선택 (건너뛰기 50% 이하)
- **관심사 추천 피드 CTR**: AI 추천 피드 대비 ±20% 이내
- **파트너 태그 부여율**: 신규 파티의 80% 이상이 1개 이상 태그 부여

## Launch Strategy

- Phase 1 (MVP): DB + 인기 태그 칩바 + 이벤트 카드 태그 뱃지 + 파트너 태그 입력
- Phase 2: 검색 자동완성 + 온보딩 + 관심사 추천 피드
- Phase 3: 핫 태그 고도화, 태그 자동 추천

## References

- **Meetup**: 온보딩 관심사 필수 → 피드 개인화
- **Bumble BFF**: 5개 뱃지 OR 필터
- **소모임**: 카테고리 아이콘 그리드 (밍릿은 태그 칩으로 변형)
- **Luma**: 카테고리별 이벤트 수 뱃지
- **TikTok/Instagram 2025**: 증가율 기반 트렌딩
