# PRD: 매칭 결과 연락처 공개

## Summary

이벤트 종료 후 서로 좋아요를 보낸 사용자에게 매칭 상대의 연락처를 전체 공개하고, 한 명씩 연락처를 저장할 수 있게 하는 결과 확인 흐름. 홈의 진행 중 이벤트 결과 surface와 이벤트 상세의 `매칭 결과 보기` 버튼이 같은 결과 바텀시트로 연결된다.

## Motivation / Problem to Solve

- 매칭 투표 후 결과 확인 진입점이 분산되어 있어 사용자가 이벤트 종료 뒤 어느 화면에서 결과를 확인해야 하는지 놓칠 수 있다.
- mutual match가 성립된 뒤에도 연락처 공개 정책이 모호하면 사용자는 실제 연락으로 이어가기 어렵다.
- 매치 없음과 조회 실패를 구분해 노출하면 사용자가 내부 오류를 결과로 오해하거나, 반대로 재시도를 기대할 수 있다.

## Goals

### Target Users

- **이벤트 참가자**: 이벤트 종료 후 본인의 mutual match 결과를 확인하려는 사용자.
- **다중 매칭 사용자**: 둘 이상과 mutual match가 성립되어 여러 연락처 중 일부를 저장하려는 사용자.
- **매칭 없음 사용자**: mutual match가 없거나 결과 조회가 실패해 다음 이벤트 탐색으로 이동해야 하는 사용자.

### Key Goals

- **P0**: 홈의 event-now results surface와 이벤트 상세 `매칭 결과 보기` 버튼에서 동일한 매칭 결과 바텀시트로 진입한다.
- **P0**: mutual match가 1건 이상이면 `partnerContact`를 마스킹 없이 전체 표시하고, 각 상대별 `연락처 저장하기` CTA를 제공한다.
- **P0**: 여러 명과 매칭되면 가로 카드 탐색과 dot indicator로 현재 카드를 구분하며, 저장 액션은 선택한 한 명에게만 적용한다.
- **P0**: mutual match가 없거나 조회 실패하면 같은 empty copy와 `다음 이벤트 찾기` CTA를 노출한다.
- **P1**: loading에서 matched 또는 empty 상태로 전환될 때 sheet 높이 급변 없이 결과가 드러난다.

### Non-Goals

- `모두 저장` bulk action 제공. 연락처 저장은 항상 단일 partner 단위다.
- 연락처 마스킹, 부분 공개, 메시지 CTA 제공. mutual match 이후 연락처는 공개 정보로 전체 표시한다.
- retry 버튼 또는 내부 오류 상세 노출. 조회 실패는 empty 결과와 같은 사용자 경험으로 처리한다.
- 이벤트 매칭 투표 입력 화면 변경. 이 문서는 종료 후 결과 reveal만 다룬다.

## Product Principles

1. **Mutual match 이후 명확한 공개**: 서로 좋아요가 성립된 뒤 연락처 교환이 목적이므로 연락처는 숨기거나 축약하지 않는다.
2. **사용자 통제 단위는 한 명**: 다중 매칭이어도 저장은 각 카드의 한 상대에게만 적용해 실수로 여러 연락처를 저장하지 않게 한다.
3. **실패 세부 은닉**: 매치 없음과 provider error는 같은 empty 결과로 처리해 내부 조회 실패를 사용자에게 노출하지 않는다.
4. **진입 surface parity**: 홈 shortcut과 이벤트 상세 진입은 같은 콘텐츠, 같은 copy, 같은 정책을 사용한다.

## Technical Approach

- **화면**: 결과 전용 modal bottom sheet content. 단독 route가 아니라 홈 event-now results phase와 이벤트 상세의 결과 보기 버튼 sheet 안에서 열린다.
- **저장**: 신규 product data 없음. 기존 이벤트, 참가 상태, mutual match 결과, partner 연락처 데이터를 결과 표시와 OS 연락처 저장 flow에 사용한다.
- **외부 의존성**: OS 연락처 저장 flow. 사용자가 `연락처 저장하기`를 누른 한 partner만 저장 대상으로 넘긴다.
- **가드 / 정책**: 참가자가 해당 이벤트의 mutual match 결과를 볼 수 있는 상태에서만 결과 surface를 노출한다. 내부 조회 실패 상세는 사용자에게 노출하지 않는다.

## User Journey

### Scenario 1: 결과 surface 진입과 단일 매칭 저장 (CUJ 1-x)

이벤트가 종료되고 mutual match가 1건 이상 있는 사용자가 홈 결과 surface 또는 이벤트 상세 `매칭 결과 보기`에서 결과 바텀시트를 열고, loading 후 공개된 연락처 카드에서 한 상대의 연락처를 저장한다.

### Scenario 2: 여러 명과 매칭된 결과 탐색 (CUJ 2-x)

여러 명과 mutual match가 성립된 사용자가 가로 카드 목록을 넘기며 dot indicator로 현재 상대를 확인하고, 원하는 한 명의 연락처만 저장한다.

### Scenario 3: 매칭 없음 또는 조회 실패 (CUJ 3-x)

mutual match가 없거나 결과 조회가 실패한 사용자는 동일한 empty 안내와 `다음 이벤트 찾기` CTA를 보고 Home feed로 돌아가 다음 이벤트를 탐색한다.

## Data Flow

### Scenario 1

이벤트 종료 상태 도달 → 홈 results surface 또는 이벤트 상세 `매칭 결과 보기` 노출 → 사용자가 결과 sheet open → 결과 loading → mutual match 1건 이상 확인 → 매칭 count/copy와 contact card 표시 → `연락처 저장하기` tap → 해당 partner만 OS 연락처 저장 flow로 전달

### Scenario 2

결과 sheet open → mutual match 2건 이상 확인 → horizontal card carousel 표시 → 사용자가 swipe → dot indicator가 현재 card index 반영 → 선택한 card의 `연락처 저장하기` tap → 해당 partner만 저장 대상으로 전달

### Scenario 3

결과 sheet open → mutual match 0건 또는 조회 실패 → 내부 실패 상세 숨김 → empty copy와 `다음 이벤트 찾기` 표시 → CTA tap → sheet dismiss 후 Home feed로 이동

## KPIs / Success Metrics

- **결과 확인률**: 결과 surface 노출 사용자 중 결과 sheet open 비율.
- **연락처 저장 전환율**: mutual match 1건 이상 사용자 중 `연락처 저장하기` 완료 비율.
- **다중 매칭 탐색률**: matches 2건 이상 사용자 중 첫 카드 외 카드까지 swipe한 비율.
- **empty CTA 전환율**: empty/error 사용자 중 `다음 이벤트 찾기` CTA tap 비율.

## Launch Strategy

MDS spec PR #2918의 shared bottom-sheet contract를 기준으로 구현 issue #2919에서 앱 동작을 맞춘다. 본 feature 문서는 CUJ와 product policy의 기준이며, 실제 출시 gate는 구현 PR의 widget/controller coverage와 app integration sensor를 따른다.

## Legal Basis

| 근거 | 내용 |
|------|------|
| Product privacy policy | mutual match 성립 후 연락처 교환이 사용자 기대 행동이다. 이 상태의 partner contact는 마스킹 없이 전체 표시하되, bulk save는 제공하지 않는다. |

## References

- MDS spec PR: #2918
- Implementation issue: #2919
- MDS screen: `apps/mds/docs/public/specs/event_matching_results_screen/index.html`
