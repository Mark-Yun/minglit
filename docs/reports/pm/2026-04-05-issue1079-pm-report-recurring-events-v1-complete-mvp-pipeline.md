---
source_url: https://github.com/Mark-Yun/minglit/issues/1079
captured_at: 2026-04-05
issue_number: 1079
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Report — 2026-04-05: Recurring Events V1 완료 + MVP 피처 파이프라인 점검"
---

# 📊 PM Report — 2026-04-05: Recurring Events V1 완료 + MVP 피처 파이프라인 점검

> Issue #1079 · closed · created 2026-04-05T08:07:02Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1079

## Body

Scheduler: pm-exec-report-claude-subagents

## 1. 이번 주 주요 마일스톤

### Recurring Events V1 구현 완료

반복 이벤트 기능이 전체 구현 완료. 6개 이슈 모두 머지:
- #1033 DB migration, #1034 EF CRUD, #1035 cron, #1036 Flutter model, #1037 생성 UI, #1038 관리 화면

후속: QA E2E 테스트 + UX 실사용 점검 필요

## 2. 외부 시장 동향

- **Timeleft**: 200+ 도시, 150K 월간 참가자, 3M+ 유저. 단일 포맷(디너) 스케일 모델
- **문토**: 52만 회원, 16만 모임, 호스트 연 9500만원 정산 사례. 밍글릿의 직접 경쟁자
- **트레바리**: 10.7만 회원, 흑자 전환 추세, B2B 다각화 중
- **개보위 2026 점검**: 다크패턴 + 과잉수집 집중 점검 (2025.11~2026.04)

밍글릿 대응: 회원탈퇴/가입동의 구현 완료. 약관 법률 검토 needs-legal 확인 권장.

## 3. MVP 피처 파이프라인 (7월 출시)

구현 완료: Signup Consent, Account Deletion, Recurring Events, My Tickets
부분 구현: Event Now Bar
미구현 (높은 리스크):
- **Partner Terms/Privacy** — 법적 필수. 스펙+플랜 있으나 구현 0%
- **Refund Policy V2** — 결제 서비스 출시 필수. plan 미작성

### PM 우선순위 제안
1. Partner Terms/Privacy → needs-swe 즉시
2. Refund Policy V2 → needs-arch
3. Event Now Bar 완성
4. Tag Discovery → needs-arch

## 4. 운영 이슈

- Seed Dev 반복 이슈 (#1046): TPM 대응 중
- CI 의존성 (#990): Dependabot PR #784 대기

## 5. 결론

프로젝트 건강도: **양호 (Green)**
- MVP 필수 3개 완료, 파이프라인 깨끗 (needs-* 0건), 규제 대응 양호
- **긴급**: Partner Terms/Privacy + Refund Policy V2 착수 필요

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-05

## 보충: 시장 리서치 상세 (pm-exec-report-claude-subagents)

### 추가 경쟁사 동향

**Bumble BFF 전면 개편 (2025.09)**
- 1:1 매칭 탈피 → 그룹/커뮤니티 중심으로 전환. 인앱 캘린더, 이벤트 생성, RSVP, 그룹 챗 추가
- 제네바 플랫폼 인수 후 통합. 디스커버리 기능 2026.02 공개
- 밍글릿 시사점: BFF가 "이벤트 기반 커뮤니티"로 피벗한 것은 이 방향이 시장에서 검증되고 있다는 신호

**Meetup + Eventbrite 통합**
- Bending Spoons가 2026.03 Eventbrite 인수 완료 (Meetup과 동일 오너). 60M+ 회원
- 두 플랫폼 통합 시 글로벌 이벤트 마켓의 판도 변화 가능성

**시장 매크로**
- TechCrunch (2026.03): "가장 큰 변화는 사람들이 더 많은 매치가 아닌 더 많은 실제 만남을 원한다는 것"
- 2026년 미국 소셜 커넥션 앱 소비자 지출 $16M+ (Appfigures)

### 규제 추가 인사이트 (Action Required)

**개인정보보호법 3차 개정안 (2026.09.11 시행)**
1. **개인정보 전송요구권 신설** — 유저가 이벤트 참가 이력, 매칭 데이터 등의 내보내기를 요구 가능. 기술적 대응 준비 필요
2. 자동화된 결정 거부권 신설
3. 정보통신서비스 제공자 특례 → 일반 규정 통합

→ 출시(7월) 후 2개월 내에 전송요구권 시행. `needs-arch`로 데이터 export API 설계 검토 권장.

**Google Play 웹 기반 삭제 수단**
- 앱 삭제 후에도 접근 가능한 웹 기반 계정 삭제 수단 의무 (2024.05 시행)
- 현재 `account-deletion/spec.md`가 이 요건을 충족하는지 확인 필요 → `needs-qa`

### 반복 이벤트 경쟁 분석

- Meetup: 반복 이벤트 지원하나 **시리즈 일괄 RSVP 미지원** (회차별 별도 RSVP)
- GroupApp: 시리즈 전체 일괄 RSVP 지원 (Meetup 대비 차별점)
- 밍글릿 시사점: V2에서 "시리즈 일괄 등록" 기능은 차별화 포인트가 될 수 있음. 노쇼 관리(위약금/경고)도 반복 이벤트와 함께 설계 필요.

### 차별화 전략 주의점

> "신뢰 검증을 진입 장벽으로 만들면 공급(파트너)이 부족해진다. 런칭 초기에는 검증 프로세스의 마찰을 최소화하는 것이 선행 과제."

> "Timeleft가 증명한 것처럼, 알고리즘 매칭 + 즉시 오프라인이 가장 빠른 성장 루트다. 신뢰 레이어는 초기에는 유저가 체감하기 어렵다. 신뢰보다 '좋은 이벤트'가 먼저 보여야 유저가 모인다."

### Comment 2 — @Mark-Yun on 2026-04-06

🤖 **tpm-exec-report-claude-subagents** 리마인드 — 이 이슈가 3일째 열려있습니다. 확인 부탁드립니다.

### Comment 3 — @Mark-Yun on 2026-04-10

종합 리포트에서 내용 확인 완료. Recurring Events V1 완료 건은 이후 Feature Maturity 교정(#1193)에서 반영됨.
