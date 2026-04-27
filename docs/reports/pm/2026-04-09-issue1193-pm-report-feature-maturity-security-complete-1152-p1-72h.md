---
source_url: https://github.com/Mark-Yun/minglit/issues/1193
captured_at: 2026-04-09
issue_number: 1193
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Report — 2026-04-09: Feature Maturity 대폭 교정 + 보안 하드닝 완료 + #1152 P1 체류 72h"
---

# 📊 PM Report — 2026-04-09: Feature Maturity 대폭 교정 + 보안 하드닝 완료 + #1152 P1 체류 72h

> Issue #1193 · closed · created 2026-04-09T08:07:41Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1193

## Body

Scheduler: pm-exec-report-claude-subagents

## Summary

코드베이스 전수 조사 결과 **Feature Maturity Matrix에 심각한 오류**를 발견했다. Refund Policy V2(20%→90%), Recurring Events(60%→90%)가 실제로는 거의 완성 상태였다. 이전 리포트들이 워크트리 vs 메인 브랜치를 잘못 구분해 과소평가한 것이 원인. 오늘 교정으로 **MVP 7개 피처 중 6개가 90% 이상** 도달 — Trust Badge만 미구현.

### 핵심 변경 3가지

1. **Feature Maturity 대교정**: 코드 전수 조사로 Refund V2(20%→90%), Recurring Events(60%→90%), Tag Discovery(75%→95%) 상향. 이전 리포트의 "워크트리에만 존재" 판단이 틀렸다 — 실제로 dev 브랜치에 머지 완료 상태.
2. **Tag Discovery 보안 하드닝 완료**: 4/8 하루 만에 보안 감사 → 5건 수정 → 전부 머지. Unicode 우회 차단, RPC anon 접근 차단, RLS 통일, P3 하드닝, 데이터 보유/압축 정책.
3. **#1152 P1 bug 72h 체류**: party_tags DELETE-first 로직 버그가 3일째 미착수. Mark에게 할당되어 있으나 코멘트 0건.

---

## Feature Maturity Matrix (코드 전수 조사 기반)

| Feature | 이전(#1173) | 교정 | 변화 | 근거 | 잔여 |
|---------|------------|------|------|------|------|
| Account Deletion | 95% | **97%** | ⬆️+2 | 양 앱 전체 플로우 + EF 3개 + 테스트 9개 | RLS 세부 검증 |
| Tag Discovery | 75% | **95%** | ⬆️+20 | User 앱 UI(trending, tag event list) + Partner UI + 보안 하드닝 5건 완료 | #1152 P1 bug |
| Signup Consent | 90% | **90%** | → | 변동 없음 | — |
| Refund Policy V2 | 20% | **90%** | ⬆️+70 | 마이그레이션 + 시뮬레이터 EF 3개 + refund_calculator 유틸 + UI 표시 + 테스트 5개 | 환불 실행 EF 미확인 |
| Recurring Events | 60% | **90%** | ⬆️+30 | 마이그레이션 + 모델 3개 + 리포지토리 + EF 2개(cron+RPC) + 테스트 | User 앱 UI 확인 필요 |
| My Tickets | 80% | **80%** | → | 변동 없음 | — |
| Partner Dashboard | 70% | **70%** | → | 변동 없음 | — |
| Trust Badge | 5% | **5%** | → | 스펙+UX 문서만, 코드 구현 0 | 전체 구현 필요 |

### 교정 근거 (코드 전수 조사)

**Refund Policy V2 (20%→90%)**:
- 이전 리포트에서 "워크트리 드래프트만 존재"라고 판단했으나, 실제로는:
  - `20260317000001_refund_policy_binary.sql` — 메인 브랜치에 머지 완료
  - `sim_refund.ts`, `sim_refund_test.ts`, `refund_utils.ts` — 시뮬레이터 EF 존재
  - `event_detail_page.dart`에 환불 정책 표시 UI
  - `refund_calculator_test.dart` 등 테스트 5개
- 잔여: 실제 환불 실행 Edge Function의 프로덕션 배포 상태 확인 필요

**Recurring Events (60%→90%)**:
- `20260405000002_recurrence_rules.sql` — 메인 브랜치에 머지 완료
- `recurrence_rule.dart` 모델 + `recurrence_rule_repository.dart` + Freezed/Generated 파일
- `recurrence-cron/index.ts` (자동 이벤트 생성) + `recurrence-rules/index.ts` (CRUD RPC) — EF 2개
- 잔여: User 앱에서 반복 이벤트 표시 UI 확인 필요

**Tag Discovery (75%→95%)**:
- 이전 리포트에서 "User 앱 UI 미완성"이라 했으나 실제로는:
  - `tag_event_list_page.dart`, `tag_event_list_controller.dart` — 태그별 이벤트 목록
  - `trending_tag_section.dart`, `featured_tag_chip_bar.dart` — 홈 화면 태그 섹션
  - `selected_tags_provider.dart` — 태그 선택 상태 관리
  - 보안 하드닝 5건 (#1177, #1176, #1182, #1180, #1190) 전부 머지
- 잔여: #1152 P1 bug만 해결하면 완성

---

## 24시간 진척 요약

4/8 하루 동안 **8개 PR 머지** — 보안 하드닝 집중일.

| 카테고리 | PR 수 | 주요 항목 |
|---------|-------|----------|
| Security Hardening | 4 | Unicode 우회 차단(#1179), RPC anon 차단(#1178), P3 하드닝(#1189), RLS 통일(#1191) |
| Data Management | 1 | tag_usage_daily 2년 보유/압축 pg_cron(#1188) |
| Docs | 1 | 유출 대응 모니터링/통지 경로(#1187) |
| CI Fix | 2 | Seed Dev notify-failure 차단(#1186), CUJ env 전달(#1172) |

### 보안 감사 → 수정 사이클 (4/8 완전 수행)

```
보안 감사(#1175) → 5건 이슈 생성 → 5건 PR → 5건 머지 → 감사 이슈 닫힘
```

| 이슈 | 심각도 | 내용 | 해결 PR |
|------|--------|------|---------|
| #1177 | P1 | Unicode 우회로 민감 키워드 필터 우회 가능 | #1179 |
| #1176 | P1 | RPC 함수 anon 호출 가능 | #1178 |
| #1182 | P3 | P3 하드닝 일괄 | #1189 |
| #1180 | P2 | 데이터 보유/압축 정책 누락 | #1188 |
| #1190 | P3 | RLS auth.role() 불일치 | #1191 |

전체 보안 감사 → 수정 → 머지가 **같은 날 완료**. 팀 실행력 우수.

---

## 시장 업데이트

### 당근모임 — F&B 카테고리 프로모션 (4/9-23, 이번 주 신규)

- 4/9-23일 식음료 카테고리 모임 대상 프로모션 진행. 소스 세트 경품 + 이벤트 물품 소상공인 기부 연계.
- 단순 매칭 플랫폼 → **커뮤니티 문화 조성자**로 포지셔닝 이동 중.
- 전사 매출 2,707억원 (YoY +43%), 최초 흑자. 모임은 체류시간 플라이휠.
- **밍글릿 시사점**: 이벤트-소상공인 연결 스토리라인 참고 케이스. B2B 파트너 도구 차별화는 여전히 유효.
- 출처: [VentureSquare](https://www.venturesquare.net/1061511)

### Eventbrite — Bending Spoons 제품 로드맵 공개

- 2026.03.10 딜 클로징 완료. 공개 로드맵:
  - AI 기반 이벤트 생성 (초안 자동 작성)
  - 내장 메시징 기능
  - 2차 티켓 마켓(secondary ticketing) 진출 검토
  - 소비자 이벤트 중심 재편 (B2B 행사 이탈)
- **밍글릿 시사점**: AI 이벤트 생성은 파트너 앱에서 검토 가치 있음. 2차 티켓팅은 밍글릿 규모에서 아직 불필요.
- 출처: [TechCrunch](https://techcrunch.com/2025/12/02/bending-spoons-agrees-to-buy-eventbrite-for-500m-to-revive-stalled-brand/), [Music Business Worldwide](https://www.musicbusinessworldwide.com/eventbrite-eyes-jump-into-secondary-ticketing-market-after-500m-acquisition-by-bending-spoons/)

### IRL 매칭 가속 — Gen Z 앱 피로 심화

- Gen Z 절반 가까이 솔로, 앱 대신 대면 방식 선호. "Clear-Coding" (의도 명확화) 트렌드.
- The Weekend Club (6명 AI 매칭 브런치), BLK 서베이 (40% 런클럽/교회/브런치에서 데이트 상대 발견).
- **밍글릿 시사점**: "이벤트 참여 → 자연스러운 만남" 핵심 가치 제안이 시장 방향과 일치.
- 출처: [Agape Match](https://www.agapematch.com/blog/gen-z-ditching-dating-apps-2026), [The WKND Club](https://the-wknd.club/news-vision/best-way-to-meet-new-people-2026/)

---

## 규제 업데이트

### 개인정보보호법 개정 — 과징금 매출액 10% + ISMS-P 의무화 (2026.02.12 국회 통과)

이전 리포트에서 "접속기록 확대"만 언급했으나, 실제 개정 범위는 더 넓다:

| 항목 | 내용 |
|------|------|
| CPO 독립성 강화 | 대표자/이사회에 직접 보고 의무화 |
| ISMS-P 의무화 | 매출액·개인정보 처리 규모 기준 초과 시 인증 의무 |
| **과징금 강화** | **중대 위반 반복 시 전체 매출액의 최대 10%** |
| 유출 통지 범위 확장 | 위조·변조·훼손 포함, 법적 권리 안내 의무 추가 |

- **밍글릿 시사점**: 현재 규모에서는 ISMS-P 의무 대상 아님. 그러나 성장 시 대비 필요. 유출 통지 시 법적 권리(손해배상, 분쟁조정) 안내 의무는 기존 유출 대응 프로세스에 반영 필요.
- 출처: [법률신문](https://www.lawtimes.co.kr/news/articleView.html?idxno=217245)

### 다크패턴 — 집행 지속, 이번 주 신규 제재 없음

- 2025.10 OTT/음원/커머스 4개 사업자 과태료 부과 이후 추가 공개 집행 사례 없음.
- 금지 6가지 유형 중 밍글릿 해당: 취소/탈퇴 방해(유형5), 자동 갱신 비공개(유형1), 반복 확인(유형6).
- 환불 플로우(Refund V2) 90% 완성으로 리스크 대폭 완화.

---

## 운영 현황

| 지표 | 값 | 변화 |
|------|---|------|
| 열린 이슈 | 9건 (7 report-exec + 1 P1 bug + 1 TPM report) | -3 |
| 열린 PR | 0건 | → |
| 열린 CI 실패 | 0건 | ✅ |
| 24h 머지 PR | 8건 | ↓ (전일 22건 → 보안 집중일) |
| Hourly Simulation | ✅ 연속 성공 | ↑ |

---

## 리스크 매트릭스 (교정 후)

| 리스크 | 확률 | 영향 | 대응 상태 |
|--------|------|------|----------|
| Trust Badge 미완성 출시 | 높음 | 🟡 차별화 약화 | ❌ 5% — 유일한 미구현 피처 |
| #1152 P1 bug 장기 체류 | 높음 | 🟡 태그 편집 불안정 | ⚠️ 72h 미착수 |
| CUJ 테스트 5일+ 실패 | 중간 | 🟡 리그레션 감지 불가 | 🔄 env fix 머지됨, 결과 대기 |
| 과징금 상향 시 환불 미비 | 낮음↓ | 🟡→🟢 | ✅ Refund V2 90% — 리스크 완화 |

### 교정으로 해소된 리스크

- ~~Refund Policy V2 출시 지연~~ → 90% 완성. P0 리스크에서 해제.
- ~~Recurring Events 워크트리 미머지~~ → dev에 머지 완료. 리스크 해제.
- ~~Tag Discovery User UI 지연~~ → User 앱 UI 구현 완료 확인. #1152만 잔여.

---

## 액션 아이템

| # | 긴급도 | 액션 | 상태 |
|---|--------|------|------|
| 1 | 🔴 P1 | #1152 party_tags 버그 — 72h 미착수, 확인 필요 | ⚠️ Mark 할당됨 |
| 2 | 🟡 P1 | Trust Badge 구현 착수 — MVP 7개 중 유일한 미구현 | `needs-arch` 필요 |
| 3 | 🟡 P1 | CUJ 테스트 5일 실패 — env fix 적용 후 결과 확인 | 대기 |
| 4 | 🟢 P2 | report-exec 이슈 7건 정리 | TPM에 위임 |
| 5 | 🟢 P2 | Refund V2 환불 실행 EF 프로덕션 배포 상태 확인 | 신규 |
| 6 | 🟢 P2 | Recurring Events User 앱 반복 이벤트 표시 확인 | 신규 |
| 7 | 🟢 P2 | 유출 대응 프로세스에 법적 권리 안내 의무 반영 (개정법) | 신규 |

---

## 이전 액션 아이템 추적

| 이전(#1173) 액션 | 상태 |
|-----------------|------|
| Refund V2 워크트리→메인 머지 | ✅ 이미 메인에 있었음 (이전 판단 오류) |
| `needs-legal` 다크패턴 감사 | 🔄 법적 문서 머지됨, 감사 자체는 미실시 |
| Tag Discovery User UI 구현 | ✅ 이미 구현됨 (이전 판단 오류) |
| Recurring Events 워크트리→메인 | ✅ 이미 메인에 있었음 (이전 판단 오류) |
| Trust Badge 구현 시작 | ❌ 미착수 |
| 이미지 EXIF 메타데이터 제거 점검 | ❓ 미확인 |

### 리포트 정확성 개선 노트

이전 3개 리포트(#1108, #1133, #1173)에서 Feature Maturity를 과소평가한 원인:
1. `.claude/worktrees/` 경로의 파일만 탐지하고 메인 브랜치 코드를 누락
2. "워크트리에만 존재"라는 판단을 코드 전수 조사 없이 내림
3. 이전 리포트의 수치를 검증 없이 그대로 인용

**대응**: 이번부터 매 사이클 Feature Maturity는 Glob/Grep 기반 코드 전수 조사 후 작성. 이전 리포트 수치를 맹신하지 않는다.

---

*Previous report: #1173 (2026-04-08)*
*Methodology: Glob/Grep codebase-wide scan across migrations, edge functions, Flutter apps, and tests*
*Market sources: VentureSquare, TechCrunch, Music Business Worldwide, Agape Match, The WKND Club, 법률신문, CODIT Insights*

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-12

모든 주요 액션 처리 완료:
- #1152 P1 → CLOSED
- CUJ 실패 → #1272 (dev-seed root cause 수정)
- report-exec 정리 → 전부 닫힘
- Supabase 배포 → #1228로 이관, migration 전부 dev DB 반영 확인
- Feature Maturity → QA 버그 13건 전부 CLOSED로 코드 기준 복구
- Trust Badge (5%) — 사람 결정 보류
- Recurring Events User UI / PIPA 법적 권리 — minor, 후속 점검
