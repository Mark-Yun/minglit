# PRD: 참여 현황 UI 재설계

## Summary

이벤트 상세의 참여 현황 섹션을 (1) 전체 합계 Summary Bar (2) 입장그룹 카드 가로 스크롤 + 연속 프로그레스 바 (3) blur 처리된 참여자 정보(나이대·인증뱃지) 3단계로 개편. 유저가 "어떤 사람들이 오는지" 사전 파악 후 참가 결정을 내릴 수 있게 한다.

## Motivation / Problem to Solve

- **공간 비효율**: 세로 스택 카드가 높이 대비 정보 밀도 낮음. 2그룹(남/여) 일 때 화면 절반 이상 차지
- **정보 전달력 부족**: 3칸 배터리 게이지가 33% 단위만 표현. "2명 참여" 텍스트 + "2/10" 게이지 중복
- **전체 합계 부재**: 그룹별 인원만 표시되어 전체 참여 인원 한눈에 파악 불가
- **참가 결정 정보 부족**: "어떤 사람들이 오는지" 전혀 알 수 없어 결정 불확실성 높음
- **다크모드 밋밋함**: 카드 테두리만으로 시각적 구분 부족
- **출처**: UX 디자이너 wireframe + PM 사용자 시뮬레이션 (페르소나 김지은 / 박민수 / 이수진)

## Goals

### Target Users

- **참가 결정 검토 중인 유저**: 처음 참가하는 이벤트에서 비슷한 또래·상황의 사람이 있는지 확인하고 싶음
- **마감 임박 이벤트 검토 유저**: 정원 마감 가까운 이벤트에서 남은 자리를 정확히 파악하고 빠르게 결정하고 싶음
- **파트너 (이벤트 주최자, 간접)**: 성비 밸런스 안심 정보 제공으로 막판 이탈 감소

### Key Goals

- **P0**: 전체 합계 Summary Bar — 전체 참여율 시각화
- **P0**: 입장그룹 카드 가로 스크롤 + 2그룹은 나란히 표시
- **P0**: 3칸 배터리 게이지 → 연속 프로그레스 바 교체
- **P0**: 숫자 위계 개선 — "N/M" 단일 표현, 중복 제거
- **P0**: 다크모드 color strip 으로 그룹 구분
- **P1**: 참여자 blur 리스트 (단일 토글로 전체 그룹 동시 펼침/접힘)
- **P1**: 나이대(초반/중반/후반) + 인증뱃지 표시
- **P1**: `show_participant_list` 메타데이터 와이어링 — false 시 blur 리스트만 숨김
- **P1**: k-anonymity 보장 — 그룹 내 참여자 3명 미만이면 blur 리스트 비표시
- **P1**: 비로그인 상태 처리 — 카운트는 공개, blur 리스트는 로그인 CTA

### Non-Goals

- 참여자 프로필 사진 노출 — 매칭 가치 훼손
- 참여자 간 사전 채팅/DM — 이벤트 전 커뮤니케이션은 현재 스코프 밖
- 참여자 "관심 있음" (Eventbrite 스타일) — 밍글릿은 유료 결제 모델이므로 불필요
- 파트너 앱 참여 현황 UI 개선 — 별도 이슈로 분리
- 관심 태그 추가 표시 — V2 (데이터 품질 검증 후)

## Product Principles

1. **신뢰 기반 매칭 보호**: 사전 프로필(사진·닉네임) 노출 금지. 인증된 범위 정보(나이대·뱃지)만 노출.
2. **k-anonymity 우선**: 식별 가능성 차단. 그룹 내 3명 미만은 blur 리스트 비표시.
3. **카운트는 항상 공개 / blur 만 게이팅**: `show_participant_list = false` 또는 비로그인 시에도 카운트 + 프로그레스 바는 공개 (소셜 프루프 유지).
4. **정보 위계 단순화**: 한 정보를 한 표현으로. 카운트와 게이지 중복 제거.

## Technical Approach

- **화면**: 이벤트 상세 페이지 "참가 현황" 탭 위젯 재설계 — 신규 라우트 없음
- **데이터 (기존)**: 그룹별 참여 카운트 / 이벤트 전체 카운트·max / 입장그룹 목록 / 티켓별 판매량·정원
- **데이터 (신규)**: 그룹별 참여자 blur 정보 (나이대 + 인증뱃지) 조회 — k-anonymity 가드(3명 미만 빈 배열) + RLS (이벤트 공개 또는 같은 이벤트 참가자)
- **메타데이터**: `show_participant_list` (이미 정의됨, 와이어링만 필요) — false 시 blur 리스트만 숨김
- **외부 의존성**: 없음

## User Journey

### Scenario 1: 첫 참가 유저가 사전 정보 확인 (CUJ 1-x)

유저가 이벤트 상세 → 참가 현황 탭 진입 → Summary Bar + 그룹별 카드 확인 → "참여자 정보" 토글 → 나이대 / 인증뱃지 확인 후 참가 결정.

### Scenario 2: 마감 임박 이벤트 결정 (CUJ 2-x)

유저가 이벤트 상세에서 연속 프로그레스 바로 "거의 다 찼다" 시각적 인지 → 빠른 결제 결정.

### Scenario 3: 비로그인 유저의 사전 탐색 (CUJ 3-x)

비로그인 유저가 이벤트 상세 → 카운트 / 프로그레스 바 확인 → blur 리스트 영역에 로그인 CTA → 로그인 후 원래 페이지 복귀.

### Scenario 4: 소규모 이벤트 / 메타데이터 비공개 처리 (CUJ 4-x)

소규모 이벤트(3명 미만 그룹) 또는 `show_participant_list = false` 이벤트에서 blur 리스트 비표시, 카운트만 노출.

## Data Flow

### Scenario 1

이벤트 상세 진입 → 참가 현황 탭 → 그룹 카운트 fetch → Summary Bar + 그룹 카드 렌더 → "참여자 정보" 토글 탭 → blur 정보 fetch (그룹별) → 각 카드 내 인라인 리스트 표시

### Scenario 2

이벤트 상세 → 참가 현황 → Summary Bar 80% 이상 시 시각적 강조 (V2 urgency 뱃지)

### Scenario 3

이벤트 상세 → 참가 현황 → 카운트 + 프로그레스만 표시 → blur 리스트 영역에 잠금 아이콘 + 로그인 CTA → CTA 탭 → 로그인 → 원래 이벤트 페이지 복귀

### Scenario 4

이벤트 상세 → 참가 현황 → 카운트 + 프로그레스만 표시 → blur 리스트 토글 미노출

## KPIs / Success Metrics

- **이벤트 상세 → 신청 전환율** (event_viewed → application_started): 현재 대비 +10% 목표 (North Star)
- **개인정보 관련 CS 문의 증가 여부** (Counter): 모니터링 (gauge가 아닌 가드레일)
- **이벤트 상세 페이지 로딩 시간 증가 없음** (Counter): blur 리스트 데이터 추가 로딩으로 인한 회귀 차단
- **특정 이벤트 기피 현상** (Counter): blur 정보로 인한 역효과 모니터링

### Domain Probes

| 이벤트 | 설명 |
|--------|------|
| `participation_section_viewed` | 참가 현황 탭 조회 |
| `participant_list_expanded` | blur 리스트 전체 펼침 |
| `participant_list_collapsed` | blur 리스트 전체 접힘 |
| `login_cta_tapped` | 비로그인 상태 로그인 CTA 탭 |

## Launch Strategy

P0 (Summary Bar / 그리드 / 프로그레스 바 / 위계 / color strip) MVP 1차 ship. P1 (blur 리스트 / 메타데이터 / k-anonymity / 비로그인 CTA) MVP 직후 2차 ship.

## Legal Basis

| 근거 | 내용 |
|------|------|
| 개인정보보호법 제23조 | 민감정보 정의 — 나이대 범위는 해당 없음 |
| k-anonymity 원칙 | 그룹 내 최소 3명 보장. 식별 가능성 차단 |

## References

- **Bumble Group Events** — blur 프로필 패턴, urgency messaging
- **소모임 (Somoim)** — 참여자 프로필 카드, 소셜 프루프 효과 (참고만, 사진 노출은 미적용)
- **문토 (Munto)** — 참여자 아바타 나열, 연령대 분포
- **Meetup** — capacity bar, attendee listing
- **Eventbrite** — "N going / N interested" 패턴 (interested 는 비적용)
- UX 디자이너 wireframe (needs-uiux-claude-1) + PM 사용자 시뮬레이션
