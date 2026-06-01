# Spec: 매칭 결과 연락처 공개

> **참조**
>
> - PRD: `docs/features/event-operation/matching-results-reveal/prd.md`
> - **MDS specs**:
>   - `apps/mds/docs/public/specs/event_matching_results_screen/` — shared `MatchResultsContent` modal bottom sheet contract, exact copy, states, motion, contact reveal policy.
>   - `apps/mds/docs/public/specs/event_now_bar/` — home event-now results entry surface.
>   - `apps/mds/docs/public/specs/home_page/` — `다음 이벤트 찾기` destination surface.
> - **Apps**:
>   - app_user: `apps/app_user/lib/src/common/widgets/match_results_content.dart`
>   - app_user: `apps/app_user/lib/src/features/home/widgets/event_now_phases/results_content.dart`
>   - app_user: `apps/app_user/lib/src/features/event/admission/event_admission_controller.dart`
> - **Backend EFs**:
>   - (해당 없음 — 기존 mutual match 결과 조회와 OS contact-save flow 사용)
> - **CUJ tests**:
>   - `apps/app_user/integration_test/cuj/event_operation/matching_results_reveal_test.dart`
> - **Related work**:
>   - MDS spec PR: #2918
>   - Implementation issue: #2919

## CUJs

| ID  | Priority | CUJ Name | Details | FR | NFR |
|-----|----------|----------|---------|----|----|
| 1-1 | P0 | 홈 결과 surface에서 매칭 결과 열기 | • 이벤트 종료 후 홈/event-now results surface 노출<br>• 사용자가 results surface를 열면 `매칭 결과` modal bottom sheet 표시<br>• loading resolves 후 matched contact cards 표시 | FR-1, FR-2, FR-3 | NFR-1, NFR-2 |
| 1-2 | P0 | 이벤트 상세에서 매칭 결과 열기 | • 이벤트 상세가 종료 후 결과 확인 가능 상태<br>• 사용자가 `매칭 결과 보기` tap<br>• 동일 `매칭 결과` modal bottom sheet 표시 | FR-1, FR-2, FR-3 | NFR-1, NFR-2 |
| 1-3 | P0 | 단일 매칭 연락처 저장 | • mutual match 1건<br>• card 1장을 중앙 정렬하고 horizontal scroll/dot indicator 없음<br>• 사용자가 `연락처 저장하기` tap<br>• 해당 partner만 OS 연락처 저장 flow로 전달 | FR-4, FR-5, FR-6, FR-8 | NFR-2, NFR-3 |
| 2-1 | P0 | 여러 매칭 카드 탐색 후 한 명 저장 | • mutual match 2건 이상<br>• horizontal cards와 dot indicator 표시<br>• 사용자가 swipe하면 active dot이 현재 card index 반영<br>• 선택 card의 `연락처 저장하기`만 해당 partner에 적용 | FR-4, FR-6, FR-7, FR-8 | NFR-2, NFR-3 |
| 3-1 | P0 | 매칭 없음 결과에서 다음 이벤트 찾기 | • mutual match 0건<br>• empty copy와 `다음 이벤트 찾기` CTA 표시<br>• CTA tap 시 sheet dismiss 후 Home feed 이동 | FR-9, FR-10 | NFR-2 |
| 3-2 | P0 | 조회 실패를 empty 결과로 처리 | • 결과 provider error 또는 조회 실패<br>• 내부 error detail 미노출<br>• empty copy와 `다음 이벤트 찾기` CTA 표시 | FR-9, FR-10, FR-11 | NFR-2, NFR-4 |

## Functional Requirements

- **FR-1**: 결과 sheet entry surface는 두 가지다. Home `EventNowBottomSheet` phase 6 results content와 이벤트 상세 `매칭 결과 보기` 버튼은 동일한 result content를 열어야 한다.
- **FR-2**: 결과 sheet의 title copy는 `매칭 결과`다. subtitle은 이벤트명이 있으면 해당 이벤트명, 없으면 `이벤트` fallback을 사용한다.
- **FR-3**: 결과 조회 loading 중에는 결과 list나 empty copy를 노출하지 않고 loading slot만 표시한다. 사용자는 sheet dismiss만 할 수 있다.
- **FR-4**: mutual match가 1건 이상이면 count copy는 match 수를 반영해 `{N}명과 매칭되었어요!` 형식으로 표시한다. 예: `1명과 매칭되었어요!`, `2명과 매칭되었어요!`.
- **FR-5**: matched state의 안내 copy는 정확히 `매칭된 상대방에게 서로의 연락처가 공유되었습니다.` / `오늘의 여운이 이어질 수 있게 편하게 연락해보세요.`를 사용한다.
- **FR-6**: contact card는 `공유된 연락처` label, partner name, full partner contact, `연락처 저장하기` CTA를 표시한다. mutual match 이후 `partnerContact`는 마스킹 없이 전체 표시한다. 예: `010-1234-5678`.
- **FR-7**: `matches.length == 1`이면 card 1장을 중앙 정렬하고 horizontal carousel, next-card peek, dot indicator를 만들지 않는다. `matches.length > 1`이면 horizontal carousel, next-card peek, dot indicator를 표시한다.
- **FR-8**: `연락처 저장하기`는 해당 card의 partner 한 명만 OS contact-save flow로 넘긴다. 여러 match가 있어도 `모두 저장` bulk action은 제공하지 않는다.
- **FR-9**: mutual match가 0건이거나 결과 조회가 실패하면 동일 empty state를 표시한다. empty copy는 정확히 `좋은 인연은 한번에 정해지지 않으니까요.` / `다음 자리에서 더 나은 인연을 만나길 기원합니다.`를 사용한다.
- **FR-10**: empty/error state CTA copy는 `다음 이벤트 찾기`다. CTA tap 시 현재 sheet를 닫고 Home feed로 이동한다. 이 CTA는 retry가 아니다.
- **FR-11**: 조회 실패의 내부 error detail은 사용자에게 노출하지 않는다. retry affordance는 제공하지 않는다.
- **FR-12**: partner name이 없으면 `알 수 없음`을 표시한다. partner contact가 없으면 phone row를 노출하지 않는다.

## Non-Functional Requirements

- **NFR-1**: 결과 sheet open 후 first content paint는 캐시 hit 기준 에뮬레이터 baseline p95 300ms 이내다.
- **NFR-2**: loading에서 matched 또는 empty state로 전환할 때 sheet height jump가 사용자 입력을 방해하지 않아야 한다. Loading slot은 120px 완충 영역을 사용한다.
- **NFR-3**: carousel swipe와 dot indicator transition은 저사양 기기 baseline에서 60fps를 유지한다.
- **NFR-4**: error fallback은 실패 상세를 화면 copy, toast, retry label로 노출하지 않는다.
- **NFR-5**: OS reduce motion 설정이 켜진 경우 loading-to-result reveal animation duration은 0ms이며 최종 상태만 즉시 표시한다.

## Edge Cases

| CUJ ID | 케이스 | 기대 동작 |
|--------|--------|----------|
| 1-1, 1-2 | sheet open 직후 결과 pending | `매칭 결과` title과 이벤트 subtitle은 유지하고 loading slot만 표시한다. |
| 1-3 | mutual match 1건 | 단일 card를 중앙 정렬한다. dot indicator와 horizontal scroll affordance는 없다. |
| 1-3, 2-1 | partner contact 존재 | full contact를 표시한다. 마스킹, truncation, 일부 숨김을 하지 않는다. |
| 1-3, 2-1 | partner contact 없음 | phone row를 숨기고, 저장 CTA는 구현 정책에 따라 숨기거나 disabled 처리한다. |
| 1-3, 2-1 | partner name 없음 | card title에 `알 수 없음`을 표시한다. |
| 2-1 | mutual match 2건 이상 | horizontal card carousel과 dot indicator를 표시하고, active dot은 현재 card index를 따른다. |
| 2-1 | 사용자가 두 번째 card에서 저장 | 두 번째 partner만 OS contact-save flow로 전달한다. 다른 card는 저장하지 않는다. |
| 3-1 | mutual match 0건 | empty copy와 `다음 이벤트 찾기` CTA를 표시한다. |
| 3-2 | 결과 조회 실패 | empty copy와 `다음 이벤트 찾기` CTA를 표시하고 내부 오류는 숨긴다. |
| 3-1, 3-2 | empty CTA tap | sheet dismiss 후 Home feed로 이동한다. retry 동작을 하지 않는다. |

## Open Questions

- [ ] partner contact가 없는 mutual match card에서 `연락처 저장하기` CTA를 disabled로 둘지 숨길지는 구현 PR #2919에서 확정한다.
- [ ] 연락처 저장 성공/취소/실패 후 toast 또는 snackbar copy는 OS save flow 연동 정책에 맞춰 별도 구현 단계에서 확정한다.

---

## 화면 구성 (참고)

> MDS spec이 UI SSoT다. 이 섹션은 product behavior와 exact user-facing copy 추적을 위한 요약이다.

### Entry Surfaces

| Surface | Trigger | Expected Sheet |
|---------|---------|----------------|
| Home/event-now results surface | 이벤트 종료 후 results phase surface tap | `매칭 결과` shared result content |
| Event detail result button | `매칭 결과 보기` tap | 동일 `매칭 결과` shared result content |

### Matched State Copy

| 위치 | Copy |
|------|------|
| Sheet title | `매칭 결과` |
| Match count | `{N}명과 매칭되었어요!` |
| Matched message line 1 | `매칭된 상대방에게 서로의 연락처가 공유되었습니다.` |
| Matched message line 2 | `오늘의 여운이 이어질 수 있게 편하게 연락해보세요.` |
| Contact label | `공유된 연락처` |
| Save CTA | `연락처 저장하기` |

### Empty / Error Copy

| 위치 | Copy |
|------|------|
| Empty message line 1 | `좋은 인연은 한번에 정해지지 않으니까요.` |
| Empty message line 2 | `다음 자리에서 더 나은 인연을 만나길 기원합니다.` |
| Empty CTA | `다음 이벤트 찾기` |

### Privacy / Product Policy

| Policy | Contract |
|--------|----------|
| Contact reveal | mutual match 성립 후 연락처 교환이 목적이므로 `partnerContact`는 전체 표시한다. |
| No masking | `010-1234-5678` 같은 전체 번호를 표시하며 마스킹, truncation, 부분 공개를 하지 않는다. |
| Single save only | `연락처 저장하기`는 해당 card의 partner 한 명에게만 적용한다. |
| No bulk save | `모두 저장` bulk action은 제공하지 않는다. |
| Error privacy | provider error와 empty result는 같은 copy를 사용하며 내부 오류 상세를 노출하지 않는다. |
