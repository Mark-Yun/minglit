---
source_url: https://github.com/Mark-Yun/minglit/issues/987
captured_at: 2026-04-04
issue_number: 987
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Daily Report — 2026-04-04: MVP 피처 우선순위 제안 + 환불 정책 구현 추적"
---

# 📊 PM Daily Report — 2026-04-04: MVP 피처 우선순위 제안 + 환불 정책 구현 추적

> Issue #987 · closed · created 2026-04-04T08:04:15Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/987

## Body

Scheduler: pm-exec-report-claude-subagents

## Executive Summary

**D-88 (7월 출시)**. 이번 주 법적 필수 에픽 3건(account-deletion, signup-consent, partner-terms-privacy) 모두 완료. 팀 속도 역대 최고 — 이번 주만 27 PR 머지, 20 이슈 클로즈. 이제 **다음 MVP 피처 우선순위 결정**이 필요한 시점.

## 1. 🟢 Feature Progress (MVP 트래커)

### 완료된 피처 (출시 필수)

| 피처 | 에픽 | 상태 | 비고 |
|------|------|------|------|
| Account Deletion | #876 | ✅ 완료 | 개인정보보호법 §36/37 + 앱스토어 필수 |
| Signup Consent | #875 | ✅ 완료 | 개인정보수집동의, UX 재설계까지 완료 (#985) |
| Partner Terms/Privacy | #846 | ✅ 완료 | 파트너 랜딩 이용약관/개인정보처리방침 |
| Statistics Tools | — | ✅ Phase 1 완료 | |

### 설계 완료, 구현 대기 — 우선순위 제안

| 순위 | 피처 | 스펙 | 설계 | 구현 | 제안 근거 |
|------|------|------|------|------|----------|
| **1** | **Event Now Bar** | ✅ | ✅ 전체 완료 | ⏳ 미착수 | 당일 이벤트 실시간 안내. 매칭→만남 경험의 핵심 차별화 |
| **2** | **My Tickets** | ✅ | ✅ 전체 완료 | ⏳ 미착수 | 결제→참석 플로우 완성. QR 입장 필수 |
| **3** | **Tag Discovery** | ✅ | ✅ (기술설계 미확인) | ⏳ 미착수 | 현재 5개 하드코딩 피드뿐. 관심사 탐색 없이 리텐션 한계 |
| 4 | Partner Dashboard | ✅ | 미확인 | ⏳ | 파트너 일상 업무 UX |

**유저 여정 근거**: 발견(Tag) → 신청(완료) → 당일(Now Bar) → 입장(Tickets). Event Now Bar를 1순위로 제안하는 이유: **이벤트 당일 경험이 리텐션의 핵심**. 소모임 앱 DAU 12-14만의 비결도 "오프라인 모임 경험의 온라인 연결"에 있음.

> 💡 **판단 필요**: 위 우선순위 동의 시 Event Now Bar 에픽 이슈를 생성하겠습니다.

## 2. 📊 Market Pulse

### 경쟁사 동향

| 경쟁사 | 최근 움직임 | 밍글릿 시사점 |
|--------|-----------|-------------|
| **Bumble BFF** | 2025.09 리뉴얼 — Group 탭, Plan 도구(오프라인 약속), 앱 내 캘린더. 2026.02 그룹 디스커버리 출시 ([TechCrunch](https://techcrunch.com/2025/09/18/bumble-bffs-revamped-app-is-here-focusing-on-friend-groups-and-community-building/)) | "Plan" 같은 간편 약속 도구 참고 가치. 밍글릿은 이벤트 기반으로 더 구조화된 접근 |
| **소모임 앱** | DAU 12-14만 (틴더/글램 2배). 500만+ DL. 프리미엄/클래스/파워유저 구독 모델 ([나무위키](https://namu.wiki/w/%EC%86%8C%EB%AA%A8%EC%9E%84(%EC%95%B1))) | 한국 모임 1위. 밍글릿 차별화: 동호회 중심 vs 단발 이벤트 매칭 |
| **Timeleft/Meet5** | 2025 미국 $16M 소비자 지출, 4.3M DL. 로컬 친구 만들기 급성장 ([TechCrunch](https://techcrunch.com/2026/03/14/as-people-look-for-ways-to-make-new-friends-here-are-the-apps-promising-to-help/)) | 오프라인 만남 니즈 글로벌 검증 |

### 핵심 트렌드

> **"More meetings, not more matches"** — 2026년 소셜 앱 핵심 트렌드. 47% 젊은 성인이 "실제 활동을 위한 친구"를 원함. 밍글릿의 이벤트 기반 매칭이 정확히 이 트렌드에 부합.

### 규제 환경

| 규제 | 시행 | 밍글릿 영향 |
|------|------|-----------|
| 개인정보 안전성 확보조치 개정 | 2026-10-31 | 접속기록 확대. 현재 구조로 대응 가능, 출시 후 점검 |
| 온플법 | 국회 심의 중 | 밍글릿 규모에서 단기 영향 없음 |

## 3. 🔴 PM 관점 리스크

| # | 항목 | 심각도 | 상태 |
|---|------|--------|------|
| 1 | **환불 정책 약관-코드 불일치** | 🔴 법적 | #978 스펙 머지됨. **코드 구현 follow-up 필요** — 전자상거래법 §17/18 위반 가능성 |
| 2 | **#964 메인화면 이벤트 피드 안뜸** | 🔴 P1 | 유저 리포트. needs-swe 할당됨 |
| 3 | **iOS 배포 3주 차단** | 🟡 | #702. Apple 계정/인증서 점검 필요 |

## 4. 📈 주간 속도

| 지표 | 이번 주 (4/1~4/4) |
|------|-------------------|
| PR 머지 | **27건** (역대 최고) |
| 이슈 클로즈 | 20건 |
| P1 오픈 | 3건 |
| P3 백로그 | 20건 |

## 5. 다음 PM 액션

1. Mark 피처 우선순위 확인 후 → Event Now Bar 에픽 이슈 생성
2. 환불 정책 코드 구현 추적 (스펙 → 코드 반영 확인)
3. My Tickets 구현 이슈 준비

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-04

/needs-pm 

이벤트 나우바, 마이티켓 에픽 이슈 생성후 워크플로우 진행해주세요 

### Comment 2 — @Mark-Yun on 2026-04-04

🤖 **needs-pm-claude-1** 작업 시작합니다. Event Now Bar + My Tickets 에픽 이슈 생성 및 워크플로우 진행.

### Comment 3 — @Mark-Yun on 2026-04-04

🤖 **needs-pm-claude-1** 에픽 이슈 생성 완료.

| 피처 | 에픽 이슈 | 우선순위 | 다음 단계 |
|------|----------|----------|----------|
| Event Now Bar | #988 | P1 1순위 | `needs-swe` |
| My Tickets | #989 | P1 2순위 | `needs-swe` |

두 피처 모두 spec.md + wireframe.html + plan.md + test-plan.md가 완비되어 있어 SWE가 바로 구현 시작 가능합니다.

`needs-pm` 라벨을 제거합니다.
