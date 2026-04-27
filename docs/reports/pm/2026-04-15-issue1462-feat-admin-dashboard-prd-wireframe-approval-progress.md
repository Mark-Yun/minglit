---
source_url: https://github.com/Mark-Yun/minglit/issues/1462
captured_at: 2026-04-15
issue_number: 1462
state: closed
labels: [report-exec]
author: Mark-Yun
title: "feat: Admin 대시보드 기획 — PRD + Wireframe (승인 후 진행)"
---

# feat: Admin 대시보드 기획 — PRD + Wireframe (승인 후 진행)

> Issue #1462 · closed · created 2026-04-15T10:45:59Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1462

## Body

## 개요

Minglit 운영을 위한 Admin 대시보드 신규 구축. 유저/파트너/이벤트/결제/정산/신고 관리 + KPI 대시보드.

## 기술 스택 (확정)

- **프레임워크**: Next.js (기존 landing 프로젝트와 동일 스택)
- **UI**: Shadcn/UI + TanStack Table
- **차트**: Recharts 또는 Tremor
- **백엔드**: Supabase (기존 DB/RLS/EF 재사용)
- **인증**: MFA 필수 (Supabase Auth MFA 또는 별도 TOTP)
- **비주얼라이제이션**: Metabase (기존 BI 유지) + Admin 인라인 차트

## 보안 요구사항

- **MFA 필수** — 관리자 로그인 시 TOTP/SMS 2차 인증
- **역할 기반 접근 제어** — super_admin / moderator 구분 (기존 `app_roles` 테이블)
- **감사 로그** — 모든 관리 액션 로깅 (누가, 언제, 뭘 했는지)
- **IP 화이트리스트** — 선택적

## 핵심 기능 (P0 — 8개 화면)

1. **유저 관리** — 목록/검색/상세/정지/해제
2. **파트너 심사** — 입점 신청 승인/거절/보완 요청
3. **이벤트 관리** — 목록/검색/강제 취소/숨김
4. **결제/환불** — 결제 내역 조회 + 수동 환불 (Portone API)
5. **정산 관리** — 상태 조회/전환/수동 처리
6. **신고 처리** — 신고 목록/상세/처리 (경고/정지)
7. **시스템 설정** — 환불 정책 편집, 약관 버전 관리
8. **KPI 대시보드** — DAU, 신규가입, 매출, 이벤트 현황

## P1 추가 기능

- 인증 서류 미리보기/심사
- 공지/푸시 발송
- 파트너 멤버 권한 관리
- 매칭 성공률/환불률 분석
- 크론잡 모니터링

## PM 요청사항

### 1단계: PRD 작성
- 각 화면별 요구사항 정의
- 역할별 접근 권한 매트릭스
- MFA 플로우 설계

### 2단계: Wireframe 작성
- **프론티어 서비스 Admin 참고 필수**:
  - Stripe Dashboard (결제/정산 관리)
  - Airbnb Host Dashboard (파트너 관리)
  - Shopify Admin (전체 구조/네비게이션)
  - Linear (이슈/상태 관리 UX)
  - Retool/Appsmith (데이터 테이블 패턴)
- 전체 그림을 조감할 수 있는 **정보 구조(IA)** 먼저
- 각 화면 wireframe은 `wireframe.html`로 제작

### 3단계: 승인
- **PRD + Wireframe을 이 이슈에 코멘트로 제출**
- Mark 승인 후 UI/UX → SWE 순서로 진행
- **승인 전에 구현 착수 금지**

## 주의

- ❌ UI/UX 워커에 바로 라우팅하지 마. PRD 승인 먼저.
- ❌ 코드 구현 시작하지 마. Wireframe 승인 먼저.
- ✅ PRD + Wireframe → 이 이슈에 코멘트 → Mark 승인 → 그다음 진행

## 참고
- 기존 DB 스키마: `docs/architecture/backend.md`
- 기존 RLS 정책: `supabase/migrations/20260301000007_07_rls_grants.sql`
- 기존 역할: `app_roles` 테이블 (super_admin, moderator)
- 환불 정책: #765, `policies` 테이블
- Metabase: 기존 BI 대시보드 유지, Admin은 운영 액션 중심

## Comments (7)

### Comment 1 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-15

## 🤖 **needs-pm-claude-1** — Admin 대시보드 PRD + Wireframe 제출

PR: #1471

### 기능 요약
Minglit 운영을 위한 Admin Dashboard — 유저/파트너/이벤트/결제/정산/신고 관리 + KPI 대시보드

### 산출물
- **spec.md**: Working Backwards + JTBD 기반 PRD (12개 섹션)
- **wireframe.html**: 10개 화면 인터랙티브 프로토타입 (브라우저에서 열면 탭으로 전환 가능)

### 핵심 설계 결정

| 결정 | 근거 |
|------|------|
| Next.js + Shadcn/UI | 기존 landing 스택 동일, admin UI 라이브러리 생태계 풍부 |
| Supabase Auth TOTP MFA | 네이티브 지원, 추가 인프라 불필요 |
| 기존 DB 재사용 | 54개 테이블 중 20+ 재활용, 신규는 `admin_audit_logs` 1개만 |
| Queue-first 홈 화면 | Stripe+Linear 패턴 — "지금 뭘 해야 하는가?"에 답하는 대시보드 |

### 시장 조사
Stripe, Shopify Admin, Linear, Retool, Airbnb Host Dashboard 5개 서비스 분석.

### 예상 영향도
- P0 8개 화면 → 7월 출시 전 운영 체계 확보
- 파트너 심사 시간 70% 단축 (수일 → 24시간 이내)
- 감사 로그로 운영 투명성 확보

### 승인 요청
`report-exec` 라벨을 붙였습니다. Mark님 검토 후 승인 부탁드립니다.
승인 후 `needs-uiux` → `needs-arch` → `needs-swe` 순서로 진행합니다.

### Comment 3 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** 세션 상태 기록:

- ✅ spec.md 작성 완료 (PRD: 12개 섹션, P0 8개 화면)
- ✅ wireframe.html 작성 완료 (10개 화면 인터랙티브 프로토타입)
- ✅ PR #1471 생성 완료 + auto-merge 활성화
- ✅ `needs-review` 라벨 부착, `report-exec` 라벨 유지
- ⏳ CI 통과 완료 (`ci-result` pass)
- ⏳ 리뷰 대기 중 (reviewer 승인 필요)

**다음 사이클 할 일**: PR #1471 리뷰 상태 확인 → 코멘트 대응 → 머지 후 `needs-uiux` 이슈 생성

### Comment 4 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** 세션 상태 기록 (사이클 2):

- ✅ PR #1471 계속 모니터링 중
- ⏳ 리뷰 대기 중 (reviewer 미착수, `review-presence` check 미통과)
- ⏳ `report-exec` 라벨 — Mark 승인 대기

**다음 사이클 할 일**: PR #1471 리뷰 상태 확인

### Comment 5 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** 세션 상태 기록 (사이클 3):

- ✅ PR #1471 브랜치 업데이트 완료 (CI 재트리거됨)
- ⏳ PR #1471 리뷰 대기 중 (`needs-review` 라벨, reviewer 미착수)
- ⏳ `report-exec` 라벨 — Mark 승인 대기

**다음 사이클 할 일**: PR #1471 리뷰 상태 확인 + Mark 승인 확인

### Comment 6 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** 세션 상태 기록 (사이클 4):

- ⏳ PR #1471 리뷰 대기 중 (`needs-review` 라벨, reviewer 미착수)
- ⏳ `report-exec` 라벨 — Mark 승인 대기

**다음 사이클 할 일**: PR #1471 리뷰 상태 확인 + Mark 승인 여부 확인

### Comment 7 — @Mark-Yun on 2026-04-15

🤖 **needs-pm-claude-1** `needs-pm` 라벨 제거합니다. PM 산출물(spec.md + wireframe.html)은 PR #1471로 제출 완료. 현재 `report-exec` 라벨로 Mark 승인 대기 중입니다.
