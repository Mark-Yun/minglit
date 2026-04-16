# Admin Dashboard 스펙

**문서 상태:** 초안
**담당 PM:** needs-pm-claude-1 | **버전:** 1.0.0
**핵심 전략:** #WorkingBackwards #HypothesisDriven #JTBD #OperationalExcellence

---

## 1. 가상 보도자료 (Working Backwards)

> **[출시일: 2026년 6월]** "오늘 Minglit은 Admin Dashboard를 통해 운영팀이 유저·파트너·이벤트·결제를 하나의 화면에서 관리할 수 있게 되었음을 발표합니다. 이제 수동 DB 쿼리와 Metabase 대시보드를 오가며 운영하던 시대는 끝났습니다. 운영자는 파트너 심사를 평균 3분 내에 완료하고, 환불 처리를 클릭 한 번으로 실행하며, 실시간 KPI를 통해 서비스 건강도를 즉시 파악할 수 있습니다. Minglit의 '신뢰(Trust)' 가치는 운영 효율의 향상으로 더욱 강화됩니다 — 빠른 심사는 파트너의 신뢰를, 신속한 환불은 유저의 신뢰를 높입니다."

---

## 2. 가설 기반 문제 정의 및 신뢰 레이어 설계

### 관측된 문제 (The Pain)

- 파트너 입점 심사, 유저 정지, 환불 처리 등 운영 액션이 DB 직접 접근 또는 Edge Function 수동 호출에 의존
- Metabase는 조회 전용 — 운영 "액션"을 취할 수 없음
- 운영자 액션에 대한 감사 로그가 없어 "누가 언제 뭘 했는지" 추적 불가
- 7월 출시 전 운영 체계가 갖춰지지 않으면 유저 CS 대응 불가

### 핵심 가설

"운영 액션을 하나의 웹 대시보드로 통합하면, 파트너 심사 완료 시간이 현재 대비 70% 단축되고, 환불/정산 오류가 0건에 수렴하며, 감사 로그를 통해 운영 투명성이 확보될 것이다."

### 신뢰 레이어 매핑

- **Layer 1 (Identity):** 유저 관리 — 실존 인물 확인(CI/DI) 상태 조회, 계정 정지/해제
- **Layer 2 (Qualification):** 파트너 심사 — 사업자등록, 인증 서류 검토 후 승인/거절

---

## 3. 잡 스토리 및 심층 ICP 분석

### ICP 1: 운영 관리자 (Super Admin)

Minglit 운영팀 멤버. 서비스 전체를 관리하며, 유저 CS 대응, 파트너 심사, 결제/정산 관리, KPI 모니터링을 담당.

**Job Story:** "파트너 입점 신청이 들어왔을 때, 나는 사업자 서류를 빠르게 검토하고 승인/거절 처리를 하고 싶다. 왜냐하면 심사 지연은 파트너의 이탈과 첫인상 저하로 직결되기 때문이다."

### ICP 2: 콘텐츠 모더레이터 (Moderator)

파트너 심사와 유저 신고 처리를 담당하는 제한된 역할. 결제/정산/시스템 설정에는 접근 불가.

**Job Story:** "신고가 접수된 유저 프로필을 확인할 때, 해당 유저의 이벤트 참여 이력과 신고 내역을 한 화면에서 보고 싶다. 왜냐하면 맥락 없이 처분을 내리면 오판이 발생하기 때문이다."

### ICP 3: 재무 담당자 (Finance Admin — 향후 확장)

정산/환불에 특화된 역할. P1 단계에서 역할 분리 예정.

**Job Story:** "월말 정산 처리 시, 매칭되지 않은 거래와 미정산 건을 필터링해서 일괄 처리하고 싶다. 왜냐하면 건별 처리는 실수와 누락의 원인이기 때문이다."

---

## 4. 성공 지표, 가드레일 및 도메인 이벤트

### North Star Metric

- **파트너 심사 완료 시간:** 신청 접수 → 승인/거절까지 평균 24시간 이내 (현재: 수일)
- **환불 처리 시간:** 요청 접수 → 처리 완료까지 평균 1시간 이내

### Counter-Metrics (Guardrails)

- 운영자 실수율 (잘못된 승인/거절) 증가 감시
- Admin 페이지 로딩 시간 3초 이내 유지
- 감사 로그 누락률 0% 유지

### 정의할 도메인 이벤트 (Domain Probes)

| 이벤트 | 설명 |
|--------|------|
| `admin.login` | 관리자 로그인 (MFA 포함) |
| `admin.partner_application.reviewed` | 파트너 심사 완료 (approve/reject) |
| `admin.user.suspended` | 유저 정지 처리 |
| `admin.user.unsuspended` | 유저 정지 해제 |
| `admin.refund.processed` | 환불 처리 완료 |
| `admin.settlement.status_changed` | 정산 상태 변경 |
| `admin.system_setting.updated` | 시스템 설정 변경 |
| `admin.event.force_cancelled` | 이벤트 강제 취소 |

---

## 5. 구성 요소

### 5.1 기술 스택

| 항목 | 선택 | 근거 |
|------|------|------|
| 프레임워크 | **Next.js** | 기존 landing 프로젝트와 동일 스택, SSR/SSG 지원, 풍부한 admin UI 라이브러리 생태계 |
| UI 라이브러리 | **Shadcn/UI** | Tailwind 기반, 커스터마이징 용이, 접근성 내장 |
| 데이터 테이블 | **TanStack Table** | 서버사이드 페이지네이션/필터링/정렬 지원 |
| 차트 | **Recharts** | 경량, 스파크라인 지원, React 네이티브 |
| 백엔드 | **Supabase** (기존) | DB/RLS/Edge Functions 재사용 |
| 인증 | **Supabase Auth + TOTP MFA** | 네이티브 MFA 지원, 추가 인프라 불필요 |
| 배포 | **Vercel** | 기존 landing과 동일 파이프라인 |

### 5.2 정보 구조 (IA) — Sidebar Navigation

Stripe의 3-tier 사이드바 + Shopify의 7-item 제한 원칙 적용. `app_roles`에 따라 항목 가시성 제어.

```
Admin Dashboard
├── 대시보드 (홈)           ← 모든 역할
├── 유저 관리               ← super_admin
│   ├── 전체 유저
│   ├── 인증 완료 유저
│   └── 신고/정지 유저
├── 파트너 관리             ← super_admin, moderator
│   ├── 활성 파트너
│   ├── 입점 심사            ← 심사 큐
│   └── 정산 관리            ← super_admin only
├── 이벤트 관리             ← super_admin
│   ├── 전체 이벤트
│   └── 활성 이벤트
├── 결제/환불               ← super_admin
│   ├── 거래 내역
│   └── 환불 처리
├── 모더레이션              ← super_admin, moderator
│   ├── 심사 큐
│   └── 인증 서류 검토
├── 시스템                  ← super_admin only
│   ├── 감사 로그
│   ├── 시스템 설정
│   └── 알림/알람
└── 설정                    ← super_admin only
    └── 관리자 계정/역할
```

### 5.3 화면별 상세

#### 5.3.1 대시보드 (홈)

Stripe의 KPI 카드 + Linear의 액션 큐 패턴. "지금 뭘 해야 하는가?"에 답하는 화면.

**Row 1: KPI 카드 4개** (F-패턴 스캔, 좌상단 = 가장 중요)

| 카드 | 데이터 소스 | 표시 |
|------|------------|------|
| 활성 유저 (7일) | `analytics.daily_active_users` | 수치 + 7일 트렌드 스파크라인 |
| 대기 중 심사 | `partner_applications WHERE status='pending'` | 건수 + "심사 큐로 →" 링크 |
| 오늘 매출 | `analytics.daily_revenue` | ₩ 금액 + 전일 대비 % |
| 미정산 건 | `settlement_items WHERE status='pending'` | 건수 + 총 금액 |

**Row 2: 차트 2개** (2-column)

| 차트 | 타입 | 기간 |
|------|------|------|
| 이벤트 신청 현황 | Stacked bar (승인/대기/거절) | 최근 30일 |
| 매출 트렌드 | Line chart | 최근 30일 |

**Row 3: 액션 큐 2개** (최근 5건)

| 큐 | 내용 |
|----|------|
| 모더레이션 큐 | 최신 대기 중 심사/신고 5건, 클릭 시 상세로 이동 |
| 파트너 입점 심사 | 최신 pending 5건, 클릭 시 심사 상세로 이동 |

#### 5.3.2 유저 관리

**목록 뷰:**
- **검색:** username, phone, email 통합 검색
- **필터 바:** 인증 상태 (전체/인증/미인증) | 상태 (전체/활성/정지) | 성별 | 가입일 범위
- **테이블 컬럼:** 프로필 이미지 | username | 성별 | 나이 | 인증 뱃지 | 가입일 | 최근 활동 | 이벤트 참여 수
- **페이지네이션:** 서버사이드, 25건/페이지
- **정렬:** 모든 컬럼 ASC/DESC 토글

**상세 뷰 (사이드 드로어):** — Stripe 패턴, 목록 컨텍스트 유지

| 탭 | 내용 |
|----|------|
| 프로필 | 기본 정보, CI/DI 인증 상태, 가입일 |
| 이벤트 | 참여한 이벤트 목록 (상태, 이벤트명, 날짜) |
| 결제 | 거래 내역, 환불 이력 |
| 인증 | 파트너별 인증 제출 내역 |
| 활동 로그 | 조회/좋아요/구매 등 주요 활동 |
| 관리 액션 | [정지] [정지 해제] [인증 초기화] — super_admin only |

#### 5.3.3 파트너 심사

**심사 큐 (Linear 워크플로우 패턴):**

상태 파이프라인: `pending` → `approved` / `rejected` / `needs_correction`

- **카드 뷰:** 우선순위 뱃지 | 업체명 | 사업자번호 | 제출일 | 카테고리
- **필터:** 상태 | 제출일 범위 | 카테고리
- **Summary bar:** "12건 대기 / 340건 승인 / 5건 거절" — 각 클릭 시 프리필터

**심사 상세 뷰:**

```
┌─────────────────────────────────────────────────┐
│ [상태 뱃지: PENDING]  서울라운지                    │
│ 사업자번호: 123-45-67890 | 제출일: 2026-04-14     │
├─────────────────────────────────────────────────┤
│ 좌측: 제출 서류 뷰어                               │
│ - 사업자등록증 (이미지/PDF 미리보기)                  │
│ - 대표자 신분증                                    │
│ - 기타 첨부 서류                                   │
├─────────────────────────────────────────────────┤
│ 우측: 심사 액션                                    │
│ - 관리자 코멘트 (텍스트 입력)                        │
│ - [승인] [거절 ▾ (사유 선택)] [보완 요청]            │
└─────────────────────────────────────────────────┘
```

#### 5.3.4 이벤트 관리

**목록 뷰:**
- **검색:** 이벤트명, 파트너명 통합 검색
- **필터:** 상태 (draft/active/closed/cancelled) | 날짜 범위 | 파트너 | 카테고리
- **테이블 컬럼:** 이벤트명 | 파트너 | 상태 뱃지 | 날짜 | 참가 신청 수 | 매출
- **액션:** [강제 취소] [숨김 처리] — 확인 다이얼로그 필수

**상세 뷰:**
- 이벤트 기본 정보 (파티 정보 포함)
- 티켓별 판매 현황
- 참가 신청 목록 (상태별)
- 관련 결제 내역

#### 5.3.5 결제/환불

**거래 내역:**
- **필터:** 상태 | 결제일 범위 | 금액 범위 | 파트너
- **테이블:** 거래 ID | 유저 | 이벤트 | 금액 | 상태 | 결제일
- **상세:** Portone 결제 정보, 환불 이력

**환불 처리:**
- **대기 큐:** 환불 요청 건 목록
- **처리 뷰:** 원결제 정보 | 환불 사유 | 환불 금액 (부분 환불 지원) | [환불 실행]
- **Portone API 연동:** 실제 환불은 Portone API를 통해 처리

#### 5.3.6 정산 관리

**정산 항목 목록:**
- **필터:** 상태 (pending/confirmed/paid/cancelled) | 정산 기간 | 파트너
- **테이블:** 정산 ID | 파트너 | 총 매출 | 수수료 | 정산액 | 상태 | 정산일
- **일괄 처리:** 체크박스 선택 → [일괄 확정] [일괄 지급 처리]

**정산 상세:**
- 정산 항목별 거래 내역
- 조정 항목 (환불, 수수료 등)
- 정산 이력 (status 변경 타임라인)
- 지급 정보 (은행/계좌)

#### 5.3.7 신고 처리

**신고 큐:**
- **상태:** open → investigating → resolved / dismissed
- **카드:** 신고 유형 | 대상 유저/이벤트 | 신고자 | 접수일
- **상세:** 신고 내용 | 대상 프로필/이벤트 | 이전 신고 이력 | [경고] [정지] [해제]

#### 5.3.8 시스템 설정

- **환불 정책 편집:** `policies` 테이블 — 버전 관리, 변경 이력
- **약관 버전 관리:** 이용약관, 개인정보처리방침, 위치정보 이용약관
- **시스템 설정값:** `system_settings` 테이블 — key/value 편집 UI
- **알림 설정:** `settlement_alarm_results` — 알람 임계값 설정

#### 5.3.9 감사 로그

모든 관리 액션의 불변(immutable) 로그.

- **테이블:** 시각 | 관리자 | 액션 유형 | 대상 | 변경 전/후 | IP
- **필터:** 관리자 | 액션 유형 | 대상 테이블 | 날짜 범위
- **데이터 소스:** 신규 `admin_audit_logs` 테이블 (아래 데이터 소스 섹션 참고)

#### 5.3.10 KPI 대시보드 (상세)

대시보드 홈의 확장 버전. Metabase 대체가 아닌 보완.

| 차트 | 소스 | 타입 |
|------|------|------|
| DAU/WAU/MAU 트렌드 | `analytics.daily_active_users` | Line chart |
| 신규 가입 트렌드 | `analytics.funnel_daily` | Line chart |
| 매출 (일/주/월) | `analytics.daily_revenue` | Bar chart |
| 이벤트 현황 | `analytics.daily_events` | Stacked bar |
| 전환 퍼널 | `analytics.funnel_daily` | Funnel chart |
| 환불률 | `analytics.daily_revenue` (gross vs refunds) | Line chart |

---

## 6. 보안 요구사항

### 인증 (Authentication)

| 항목 | 사양 |
|------|------|
| 기본 인증 | Supabase Auth (이메일/비밀번호) |
| MFA | TOTP 필수 — Supabase Auth 네이티브 지원 |
| 세션 타임아웃 | 유휴 30분, 절대 8시간 |
| IP 화이트리스트 | P1 (선택적, `system_settings`에서 관리) |

### 인가 (Authorization)

기존 `app_roles` 테이블 활용. RLS 정책으로 DB 레벨 접근 제어.

| 역할 | 접근 범위 |
|------|----------|
| `super_admin` | 전체 접근 — 유저/파트너/이벤트/결제/정산/시스템/감사로그 |
| `moderator` | 제한 접근 — 파트너 심사, 모더레이션 큐, 유저 프로필 (읽기 전용) |

### 감사 로그

신규 테이블 `admin_audit_logs` 생성:

```sql
CREATE TABLE admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID NOT NULL REFERENCES auth.users(id),
  action_type TEXT NOT NULL,        -- 'partner_application.approved', 'user.suspended', etc.
  target_table TEXT NOT NULL,       -- 'partner_applications', 'user_profiles', etc.
  target_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 불변성 보장: UPDATE/DELETE 불가
-- RLS: super_admin만 SELECT 가능
```

---

## 7. 데이터 소스

### 기존 테이블 (재사용)

| 테이블 | 용도 |
|--------|------|
| `app_roles` | 관리자 역할 (super_admin/moderator) |
| `user_profiles` | 유저 기본 정보 |
| `partner_applications` | 파트너 입점 심사 |
| `partners` | 파트너 조직 정보 |
| `parties` | 파티(이벤트 그룹) 정보 |
| `events` | 개별 이벤트 |
| `event_applications` | 이벤트 참가 신청 |
| `tickets` | 티켓 정보 |
| `settlement_items` | 정산 항목 |
| `payouts` | 지급 정보 |
| `settlement_histories` | 정산 이력 |
| `adjustment_items` | 조정(환불 등) 항목 |
| `reconciliation_runs` | 일일 대사 |
| `system_settings` | 시스템 설정 KV |
| `policies` | 정책/약관 버전 관리 |
| `verification_submissions` | 인증 서류 제출 |
| `settlement_alarm_results` | 시스템 알람 |
| `analytics.daily_active_users` | DAU 메트릭 |
| `analytics.daily_revenue` | 일매출 |
| `analytics.daily_events` | 이벤트 볼륨 |
| `analytics.funnel_daily` | 전환 퍼널 |

### 신규 테이블

| 테이블 | 용도 |
|--------|------|
| `admin_audit_logs` | 관리 액션 감사 로그 (위 스키마 참고) |

### API 연동

| API | 용도 |
|-----|------|
| Portone API | 결제 조회, 환불 처리 |
| Supabase Auth Admin API | MFA 관리, 세션 관리 |

---

## 8. 라우트 변경

### 신규 라우트 (Next.js App Router)

```
/admin
├── /                        → 대시보드 (홈)
├── /users                   → 유저 목록
├── /users/[id]              → 유저 상세
├── /partners                → 파트너 목록
├── /partners/applications   → 입점 심사 큐
├── /partners/applications/[id] → 심사 상세
├── /partners/settlements    → 정산 관리
├── /partners/settlements/[id]  → 정산 상세
├── /events                  → 이벤트 목록
├── /events/[id]             → 이벤트 상세
├── /payments                → 거래 내역
├── /payments/refunds        → 환불 처리
├── /moderation              → 모더레이션 큐
├── /moderation/[id]         → 신고 상세
├── /system/audit-log        → 감사 로그
├── /system/settings         → 시스템 설정
├── /system/alarms           → 알림/알람
├── /settings/roles          → 관리자 계정/역할
└── /login                   → 로그인 (MFA 포함)
```

### 기존 라우트 변경: 없음

Admin은 독립 웹앱으로 기존 Flutter 앱 라우트에 영향 없음.

---

## 9. 에러/로딩 상태

| 섹션 | 로딩 | 빈 상태 | 에러 |
|------|------|---------|------|
| 대시보드 KPI | Shimmer 카드 (Stripe 패턴) | N/A (항상 데이터 있음) | "데이터를 불러올 수 없습니다. 새로고침해주세요." |
| 데이터 테이블 | Skeleton rows (5행) | "조건에 맞는 데이터가 없습니다." + 필터 초기화 버튼 | "데이터 로딩 실패. 잠시 후 다시 시도해주세요." + 재시도 버튼 |
| 심사 큐 | Skeleton cards | "처리할 심사 건이 없습니다 🎉" | 재시도 안내 |
| 서류 뷰어 | Spinner | "첨부된 서류가 없습니다." | "서류를 불러올 수 없습니다." + 다운로드 링크 |
| 차트 | Shimmer chart area | "아직 데이터가 충분하지 않습니다." | 차트 영역에 에러 텍스트 |
| 환불 실행 | 버튼 로딩 스피너 | N/A | Toast: "환불 처리에 실패했습니다. Portone 상태를 확인해주세요." |

---

## 10. 핵심 요구사항 및 비목표

### P0 (Must — 7월 출시 필수)

1. **로그인 + MFA** — Supabase Auth TOTP, 역할 기반 사이드바 렌더링
2. **대시보드 홈** — KPI 카드 4개 + 차트 2개 + 액션 큐 2개
3. **유저 관리** — 목록/검색/필터 + 상세 드로어 + 정지/해제
4. **파트너 심사** — 심사 큐 + 서류 뷰어 + 승인/거절/보완 요청
5. **이벤트 관리** — 목록/검색/필터 + 강제 취소/숨김
6. **결제/환불** — 거래 내역 조회 + 수동 환불 (Portone API)
7. **정산 관리** — 상태 조회/전환 + 지급 처리
8. **감사 로그** — 모든 관리 액션 기록, 조회 UI

### P1 (Should — 출시 후 1개월)

9. **신고 처리** — 신고 큐 + 처리 워크플로우
10. **시스템 설정** — 환불 정책, 약관 버전 관리
11. **인증 서류 미리보기/심사** — 이미지/PDF 인라인 뷰어
12. **일괄 처리** — 정산 일괄 확정/지급, 심사 일괄 처리
13. **IP 화이트리스트** — 선택적 접근 제한

### P2 (Nice to have)

14. 공지/푸시 발송
15. 파트너 멤버 권한 관리
16. 매칭 성공률/환불률 심층 분석
17. 크론잡 모니터링
18. 실시간 알림 (Supabase Realtime)

### Non-Goals (하지 않을 것)

- **Metabase 대체:** Admin은 운영 "액션" 도구. 분석/BI는 Metabase 유지.
- **유저/파트너 앱 기능 복제:** 앱에서 가능한 건 앱에서. Admin은 운영자 전용 액션만.
- **자동 심사:** AI 기반 자동 승인/거절은 범위 밖. 사람이 판단하고 도구가 실행.
- **모바일 최적화:** Admin은 데스크톱 웹 전용. 태블릿은 반응형으로 최소 지원.
- **다국어:** 초기 버전은 한국어 단일 언어.

---

## 11. 구현 이슈 분할 (예상)

순서대로 진행. 각 이슈는 독립 배포 가능하도록 설계.

| # | 제목 | 의존성 | 우선순위 |
|---|------|--------|---------|
| 1 | Admin 프로젝트 초기 설정 (Next.js + Shadcn/UI + Supabase) | 없음 | P0 |
| 2 | 인증 — 로그인 + TOTP MFA + 역할 기반 라우팅 | #1 | P0 |
| 3 | 감사 로그 테이블 + 미들웨어 | #2 | P0 |
| 4 | 대시보드 홈 — KPI 카드 + 차트 + 액션 큐 | #2 | P0 |
| 5 | 유저 관리 — 목록/검색/상세/정지 | #2, #3 | P0 |
| 6 | 파트너 심사 — 큐 + 서류 뷰어 + 심사 액션 | #2, #3 | P0 |
| 7 | 이벤트 관리 — 목록/검색/강제 취소 | #2, #3 | P0 |
| 8 | 결제/환불 — 거래 조회 + Portone 환불 | #2, #3 | P0 |
| 9 | 정산 관리 — 상태 조회/전환/지급 | #2, #3 | P0 |
| 10 | 신고 처리 — 큐 + 워크플로우 | #2, #3 | P1 |
| 11 | 시스템 설정 — 정책/약관/설정값 편집 | #2 | P1 |
| 12 | 일괄 처리 + 고급 필터링 | #5-9 | P1 |

---

## 12. 참고 문헌 및 방법론 근거

### 시장 조사 참고 앱

| 앱 | 참고 포인트 | 적용 |
|----|-----------|------|
| **Stripe Dashboard** | KPI 카드 + 스파크라인, 사이드 드로어 상세, shimmer 로딩 | 대시보드 홈, 유저/결제 상세 뷰 |
| **Shopify Admin (Polaris)** | 축소형 사이드바, 7-item 제한, 명사형 네비게이션 | IA 설계, 사이드바 구조 |
| **Linear** | 상태 파이프라인, 키보드 퍼스트, 최소 UI | 심사 큐 워크플로우, 모더레이션 |
| **Retool/Appsmith** | 서버사이드 필터/정렬/페이지네이션, 벌크 액션 | 데이터 테이블 패턴 |
| **Airbnb Host Dashboard** | 파트너 퍼포먼스 뷰, 심사 워크플로우 | 파트너 관리 구조 |

### 방법론

1. **Ian McAllister (Amazon):** "Working Backwards: The PR/FAQ Process"
2. **Marty Cagan (SVPG):** "Inspired: How to Create Tech Products Customers Love"
3. **Minglit Architecture Guide:** Section 5 (Trust & Verification Architecture)
4. **Minglit Engineering Principles:** Section 1 (Domain-Oriented Observability)

### Confidence & Scope Risk

- **Confidence:** High — 기존 DB 스키마/RLS/Edge Functions 재사용, 검증된 기술 스택
- **Scope Risk:** Moderate — 8개 P0 화면은 많지만, 패턴이 반복적 (목록+상세+액션). 정산/환불의 Portone API 연동이 가장 큰 리스크.
