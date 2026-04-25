---
source_url: https://github.com/Mark-Yun/minglit/issues/1465
captured_at: 2026-04-15
issue_number: 1465
state: closed
labels: [enhancement, P1-high, report-exec]
author: Mark-Yun
title: "[PM] 참여 현황 UI 재설계 — 입장그룹별 표시 + 참여자 blur 정보 기획"
---

# [PM] 참여 현황 UI 재설계 — 입장그룹별 표시 + 참여자 blur 정보 기획

> Issue #1465 · closed · created 2026-04-15T10:56:50Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1465

## Body

## 배경

갤24 이벤트 상세 화면 "참여 현황" 섹션에서 3가지 문제 발견.

## 현재 화면 (스크린샷 근거)

\`\`\`
참여 현황

┌─────────────────────────────────┐
│ 남성                    2/10 👥 │
│ 📅 1990~2005년생  👫 남성       │
│ 2명 참여                        │
├─────────────────────────────────┤
│ 여성                    2/10 👥 │
│ 📅 1990~2005년생  👫 여성       │
│ 2명 참여                        │
└─────────────────────────────────┘
\`\`\`

## 문제점

### 1. 참여 인원 수 불일치 의심
- 상단 참가 현황 탭에서는 전체 참여 인원이 표시될 텐데
- 참여현황 섹션에서는 입장그룹별(남성 2명, 여성 2명)로 보임
- **전체 참여 인원(4명)과 그룹별 합계가 맞는지 확인 필요**
- 입장그룹이 3개 이상일 때 (예: 남성 20대, 여성 20대, 남성 30대, 여성 30대) 정확히 분리되는지?

### 2. UI 디자인 개선 필요
현재 카드가:
- 단순 텍스트 나열 (연생, 성별, 참여 수)
- 게이지 바가 작고 눈에 안 띔
- 전체적으로 **정보 밀도가 낮은데 공간은 많이 차지** (카드 높이 대비 내용 적음)
- 다크 모드에서 카드 테두리만 있고 배경이 비어서 밋밋

**개선 방향 제안**:
- 게이지 바를 더 시각적으로 (progress bar + 색상 채우기)
- 남/여 카드를 가로 병렬 배치 (현재 세로 스택 → 공간 낭비)
- 아이콘 + 숫자를 더 크게 강조
- 참고: 소모임, 문토 등 경쟁앱의 참여 현황 UI

### 3. 🆕 기능 추가: 참여자 blur 정보 (collapsed list)

**핵심 가치**: "어떤 사람들이 오는지" 미리 알 수 있으면 참가 결정에 도움. 근데 개인정보 보호 위해 blur 처리.

**제안 UX**:
\`\`\`
참여 현황

남성 (3/10)  ▼ 펼치기
┌──────────────────────────┐
│ 🔵 30대 초반 · 직장인     │
│ 🔵 20대 후반              │
│ 🔵 30대 중반 · 직장인     │
└──────────────────────────┘

여성 (2/10)  ▷ 접힘
\`\`\`

**표시 정보 (blur)**:
- 나이대: 20대 초반/중반/후반, 30대 초반/중반/후반 (정확한 나이 아닌 범위)
- 인증 뱃지: "직장인", "대학생" (인증된 경우만, 이름은 비공개)
- 프로필 사진: 없음 (blur 원칙)
- 이름/닉네임: 없음

**인터랙션**:
- 기본 상태: **접힌 상태** (그룹명 + 인원수만)
- 탭하면 **펼쳐서** 참여자 blur 리스트 표시
- 미로그인 시: "로그인하면 참여자 정보를 볼 수 있어요" CTA

**데이터 소스**:
- \`event_participants\` + \`user_profiles\` (birth_date → 나이대 계산)
- \`verification_submissions\` (인증 상태 → 뱃지)
- **RLS**: 같은 이벤트 참가자 or 이벤트 공개인 경우만 조회 가능

## PM 기획 요청 사항

1. **참여 인원 표시 규칙 정의** — 그룹별/전체 어떻게 표시? 그룹이 4개일 때는?
2. **참여 현황 카드 wireframe 재설계** — 현재 UI 개선안
3. **blur 정보 표시 범위 확정** — 나이대 + 인증 뱃지 외에 뭘 더 보여줄지 (지역? 관심 태그?)
4. **개인정보 영향 평가** — 나이대 범위가 "5세 단위"면 개인 식별 가능성?  k-anonymity 검토
5. **접힘/펼침 UX spec** — 기본 상태, 애니메이션, 미로그인 처리
6. **\`show_participant_list\` metadata 활용** — 이벤트별로 참여자 공개/비공개 설정이 이미 있음 (확인 필요)

## 참고

- 현재 이벤트 metadata: \`show_participant_list: true/false\` — 이미 공개 여부 설정 존재
- 경쟁앱 참고: 소모임 (참여자 프로필 카드), 문토 (참여자 연령대 분포), Eventbrite (attendee count)
- 개인정보보호법 제23조 (민감정보) — 나이대는 민감정보 아님, blur 처리면 안전

## 관련

- #1464 (MinglitContentLayout — 참여 현황 섹션도 이 레이아웃에 포함)
- #1236 (구매 내역 컬러 위계 — 전반적 UI 개선과 병행)
- \`apps/app_user/lib/src/features/event/detail/\` (이벤트 상세 화면)

## Comments (14)

### Comment 1 — @Mark-Yun on 2026-04-15

🤖 **needs-uiux-claude-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-15

## 🎨 UX 디자인 리뷰 — 참여 현황 UI 재설계

**Scheduler: needs-uiux-claude-1**

---

### Wireframe

**[`docs/features/participation-status-redesign/wireframe.html`](https://github.com/Mark-Yun/minglit/blob/ux/1465-participation-status-redesign/docs/features/participation-status-redesign/wireframe.html)** — 브라우저에서 직접 확인 가능.

4가지 variant를 포함합니다:
- **A: 2열 그리드** (추천) — 남/여 카드를 가로 병렬 배치
- **B: 풀와이드 스택** — 기존 세로 스택을 개선한 버전
- **C: 4그룹 케이스** — 남20대/여20대/남30대/여30대 등 다중 그룹
- **D: 비로그인** — 참여자 리스트 숨기고 로그인 CTA

Light/Dark 모드 전환 + 참여자 blur 리스트 접힘/펼침 인터랙션 포함.

---

### 현재 디자인 문제점 분석

| # | 문제 | 심각도 |
|---|------|--------|
| 1 | 세로 스택 레이아웃 — 카드 높이 대비 정보 밀도 낮음, 공간 낭비 | 🟡 Medium |
| 2 | 3칸 배터리 게이지 — 33% 단위로만 표현, 정확한 비율 전달 불가 | 🟡 Medium |
| 3 | "2명 참여" + 게이지 "2/10" 정보 중복 | 🟢 Low |
| 4 | 다크모드에서 카드가 밋밋 — 테두리만으로 시각적 구분 부족 | 🟡 Medium |
| 5 | 전체 참여 인원 합계를 한눈에 볼 수 없음 | 🟠 High |

---

### 디자인 결정

#### 1. 레이아웃: **2열 그리드 추천 (Option A)**

- 2그룹(남/여)일 때 가로 병렬 → 공간 효율 2배, 비교 직관적
- 3그룹 이상: 2열 그리드가 자연스럽게 확장 (마지막 행 1칸 가능)
- 참고: 토스 증권 종목 비교, 당근 채팅 리스트의 밀도감

#### 2. 프로그레스 바

- 3칸 배터리 → **연속 프로그레스 바**로 교체
- 그룹별 고유 색상: 남성 `#60A5FA` (Blue), 여성 `#F472B6` (Pink)
- 성별 무관 그룹: primary `#9900FF` 사용
- 높이 6px, radius 3px — 미니멀하지만 충분히 가시적

#### 3. 숫자 위계

- 참여 인원을 **큰 숫자(20px bold)** 하나로 통합 (`2 / 10`)
- "2명 참여" 텍스트 + 게이지 중복 제거 → 정보 밀도 증가

#### 4. 전체 합계 summary bar

- 섹션 상단에 전체 참여 현황 바 배치 (`👥 전체 참여 4 / 20`)
- 그룹별 합계가 전체와 맞는지 한눈에 확인 가능

#### 5. 참여자 blur 리스트

- **기본 상태: 접힘** (그룹 카드 하단에 "참여자 정보 ▾" 토글)
- 펼치면 blur 처리된 참여자 리스트 표시
- **표시 정보**: 나이대 범위 (초반/중반/후반) + 인증뱃지 (있는 경우만)
- **나이대 분류**: 20대 초반(20~23), 중반(24~26), 후반(27~29) — 5세 단위가 아닌 초/중/후반으로 k-anonymity 확보
- 프로필 사진/이름/닉네임: 표시하지 않음 (blur 원칙)

#### 6. 비로그인 처리

- 참여자 리스트 토글 숨김
- 카드 하단에 로그인 CTA: "로그인하면 참여자 정보를 볼 수 있어요"
- CTA는 primary 색상의 소프트 배경 (`primary 5% opacity`)

#### 7. 다크모드 대응

- 카드 상단 color strip (3px) 으로 그룹 구분 + 밋밋함 해소
- 카드 배경 `surfaceContainerLowest` (#1A1A1A) 활용

---

### PM 확인 요청 사항

아래 항목은 PM 판단이 필요합니다:

1. **나이대 범위 분류 기준**: "20대 초반"(20~23), "20대 중반"(24~26), "20대 후반"(27~29) — 이 기준으로 진행 가능한지?
2. **`show_participant_list` = false일 때**: blur 리스트 전체 숨김 vs count만 표시?
3. **인증뱃지 없는 참여자 비율이 높을 때**: 나이대만으로 blur 리스트의 유저 가치가 충분한지?
4. **그룹 색상 정책**: 남성=Blue, 여성=Pink 외 성별 무관 그룹에 primary 사용 — 문제 없는지?
5. **개인정보 영향**: 나이대 "초반/중반/후반" 범위(3~4세 폭)가 k-anonymity에 충분한지 legal 확인 필요?

---

### 다음 단계

- PM 확인 사항 반영 후 → `needs-qa` (테스트 계획) → `needs-arch` (기술 설계) → `needs-swe` (구현)
- 이 이슈는 `needs-uiux` 라벨을 제거하고 `needs-pm`으로 라우팅합니다 (PM 확인 사항 해소 필요)
- 현재 `needs-tpm` 라벨도 붙어 있는데, 동시 2개는 규칙 위반이므로 정리합니다

---

*wireframe 브랜치: `ux/1465-participation-status-redesign`*

### Comment 3 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** 작업 시작합니다.

### Comment 4 — @Mark-Yun on 2026-04-15

## 🤖 **needs-pm-claude-1** — 참여 현황 UI 재설계 PRD + Wireframe 제출

PR: #1482

### 기능 요약
이벤트 상세 "참여 현황" 섹션 전면 재설계:
- **P0**: 전체 합계 Summary Bar + 2열 그리드 + 연속 프로그레스 바
- **P1**: 참여자 blur 리스트 (나이대 + 인증뱃지) — Bumble blur 패턴 + 밍글릿 인증 시스템 결합

### 산출물
- **spec.md**: Working Backwards + JTBD 기반 PRD (14개 섹션)
- **wireframe.html**: 5개 variant 인터랙티브 프로토타입 (Before, 2그룹, 4그룹, 비로그인, 빈 상태)

### 핵심 설계 결정

| 결정 | 근거 |
|------|------|
| Blur 리스트 (나이대+뱃지) | Bumble의 blur 패턴이 밍글릿 "신뢰 기반 매칭"에 최적. 소모임처럼 프로필 공개는 매칭 가치 훼손 |
| k-anonymity (3명 미만 비표시) | 소규모 이벤트 개인 식별 방지. Legal 리뷰 권장 |
| show_participant_list=false → 카운트만 | blur 리스트만 게이팅, 참여 카운트는 기본 정보로 항상 공개 |

### UX 디자이너 제안 5건 PM 확인
1. ✅ 나이대 초반/중반/후반 분류 승인
2. ✅ show_participant_list=false → 카운트만 공개
3. ✅ 뱃지 없어도 나이대만으로 가치 있음
4. ✅ 남=Blue, 여=Pink, 기타=Primary 승인
5. ✅ k-anonymity 3명 + Legal 리뷰 권장

### 다음 단계
PR 머지 → `report-exec` (Mark 승인) → `needs-uiux` → `needs-qa` → `needs-arch` → `needs-swe`

참여 현황 재설계는 **기존 UI 개선이 아닌 blur 리스트라는 신규 기능 포함**이므로 Mark 승인 필요.
`report-exec` 라벨 부착합니다.

### Comment 5 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** — PR #1482 → #1483으로 재생성 (base branch conflict 해소). 동일 내용.

### Comment 6 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** 세션 상태 기록:

- ✅ spec.md 작성 완료 (PRD: 14개 섹션, P0/P1/P2 우선순위 분리)
- ✅ wireframe.html 작성 완료 (5개 variant: Before, 2그룹, 4그룹, 비로그인, 빈 상태)
- ✅ UX 디자이너 제안 5건 PM 확인 완료
- ✅ PR #1483 생성 + auto-merge 활성화
- ✅ `needs-review` 라벨 부착, `report-exec` 라벨 부착
- ⏳ 리뷰 대기 중 (reviewer 미착수)
- ⏳ CI `ci-result` pending (CodeRabbit 대기)

**다음 사이클 할 일**: PR #1483 리뷰 상태 확인 → 머지 후 Mark 승인 대기

### Comment 7 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** 세션 상태 기록 (사이클 3):

- ✅ PR #1483 CI 실행 중 (`review-presence` 외 정상)
- ⏳ PR #1483 리뷰 대기 중 (`needs-review` 라벨, reviewer 미착수)
- ⏳ `report-exec` 라벨 — Mark 승인 대기

**다음 사이클 할 일**: PR #1483 리뷰 상태 확인 + Mark 승인 확인

### Comment 8 — @Mark-Yun on 2026-04-15

/needs-pm 펼치는 버튼은 하나만 넣는게 어떨까? 그리고 제안한대로 가로 스크롤로 ㅇㅇ

### Comment 9 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** Mark 피드백 반영 완료:

1. **단일 펼치기 버튼** — 그룹 카드별 개별 토글 제거, 카드 영역 하단에 "참여자 정보 ▾" 버튼 1개로 통합. 한 번 탭으로 모든 그룹 blur 리스트 동시 펼침/접힘.
2. **가로 스크롤 레이아웃** — 2열 그리드 → 가로 스크롤로 변경. 2그룹은 화면에 나란히 표시, 3그룹 이상은 카드가 잘려 보여 스크롤 어포던스 제공.

변경사항: PR #1483 커밋 `785763681`

### Comment 10 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** 세션 상태 기록 (사이클 4):

- ✅ Mark 피드백 반영 완료 (단일 펼치기 버튼 + 가로 스크롤)
- ✅ PR #1483 업데이트 push 완료 (커밋 `7857636`)
- ⏳ PR #1483 리뷰 대기 중 (`needs-review` 라벨, reviewer 미착수)
- ⏳ `report-exec` 라벨 — Mark 승인 대기

**다음 사이클 할 일**: PR #1483 리뷰 상태 확인 + Mark 승인 여부 확인

### Comment 11 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** `needs-pm` 라벨 제거합니다. PM 산출물(spec.md + wireframe.html)은 PR #1483으로 제출 완료. 현재 `report-exec` 라벨로 Mark 승인 대기 중입니다.

### Comment 12 — @Mark-Yun on 2026-04-16

/needs-pm 와이어프레임 스크린샷 첨부해줘

### Comment 13 — @Mark-Yun on 2026-04-16

## 참여 현황 UI 재설계 — 와이어프레임 스크린샷

PR #1483 의 `docs/features/participation-status-redesign/wireframe.html` 캡처입니다.

---

### 1. Before (현재 디자인)
![Before](https://raw.githubusercontent.com/Mark-Yun/minglit/pm/1465-participation-status-redesign/docs/features/participation-status-redesign/screenshots/01-before.png)

### 2. After: 2그룹 (접힘)
![After 2그룹](https://raw.githubusercontent.com/Mark-Yun/minglit/pm/1465-participation-status-redesign/docs/features/participation-status-redesign/screenshots/02-after-2group.png)

### 3. After: 2그룹 (펼침 — 참여자 blur 정보)
![After 2그룹 펼침](https://raw.githubusercontent.com/Mark-Yun/minglit/pm/1465-participation-status-redesign/docs/features/participation-status-redesign/screenshots/03-after-2group-expanded.png)

### 4. After: 4그룹 (가로 스크롤)
![After 4그룹](https://raw.githubusercontent.com/Mark-Yun/minglit/pm/1465-participation-status-redesign/docs/features/participation-status-redesign/screenshots/04-after-4group.png)

### 5. 비로그인 상태
![비로그인](https://raw.githubusercontent.com/Mark-Yun/minglit/pm/1465-participation-status-redesign/docs/features/participation-status-redesign/screenshots/05-nologin.png)

### 6. 빈 상태
![빈 상태](https://raw.githubusercontent.com/Mark-Yun/minglit/pm/1465-participation-status-redesign/docs/features/participation-status-redesign/screenshots/06-empty.png)

### 7. Dark 모드 (2그룹)
![Dark 모드](https://raw.githubusercontent.com/Mark-Yun/minglit/pm/1465-participation-status-redesign/docs/features/participation-status-redesign/screenshots/07-dark-2group.png)

---

**주요 변경점 요약:**
- **Summary Bar**: 전체 참여 현황을 프로그레스 바로 한눈에 파악
- **가로 스크롤 그룹 카드**: 2그룹은 나란히, 3그룹 이상은 스크롤 어포던스
- **단일 펼치기 버튼**: 모든 그룹의 blur 참여자 정보를 한 번에 펼침/접힘
- **K-anonymity**: 3명 미만 그룹은 개인정보 보호를 위해 정보 비표시
- **비로그인 CTA**: 로그인 유도 + 기본 수치는 공개
- **빈 상태**: 첫 참여 유도 메시지

### Comment 14 — @Mark-Yun on 2026-04-16

🤖 **needs-pm-claude-1** 세션 상태 기록:

- ✅ Mark 요청대로 와이어프레임 스크린샷 7장 캡처 + 이슈 코멘트 첨부 완료
  - Before, After 2그룹(접힘/펼침), 4그룹, 비로그인, 빈 상태, Dark 모드
  - 스크린샷 파일: PR #1483 브랜치의 `docs/features/participation-status-redesign/screenshots/`
- ✅ `needs-pm` 라벨 제거 완료 (PM 산출물 작업 완료)
- ⏳ PR #1483 리뷰 대기 중 (`needs-review` 라벨)
- ⏳ `report-exec` 라벨 — Mark 승인 대기

**다음 사이클 할 일**: PR #1483 리뷰 상태 확인 + Mark 승인 여부 확인
