# Minglit Architecture Guide

> 시스템 전체를 조망하는 조감도 문서다. 각 영역의 상세 설계는 링크된 전용 문서를 참고한다.

---

## 1. 시스템 조감도

### 1.1 Tech Stack

| Layer | Technology | 역할 |
|-------|-----------|------|
| **Client (User)** | Flutter 3.x + Riverpod + GoRouter | 유저 앱 (iOS/Android) |
| **Client (Partner)** | Flutter 3.x + Riverpod + GoRouter | 파트너 앱 (iOS/Android) |
| **Shared Library** | `minglit_kit` (Dart package) | 앱 공유 레이어 (Repository, UI Kit, Provider) |
| **Mutation Gateway** | Supabase Edge Functions (Deno) | 모든 데이터 변경의 단일 진입점 |
| **Database** | PostgreSQL (Supabase) | 핵심 데이터 저장소 |
| **Auth** | Supabase Auth | OAuth (Apple, Kakao), JWT 발급 |
| **Storage** | Supabase Storage | 이미지, 인증 서류 파일 |
| **Queue** | PGMQ (PostgreSQL 기반) | 알림, 임베딩, 이벤트 비동기 처리 |
| **Search** | PGroonga + pgvector | 한글 전문 검색 + AI 추천 |

### 1.2 시스템 흐름도

```text
Flutter App (User / Partner)
    │
    ├── Read  ──────> Supabase DB (직접 조회, RLS 적용)
    │
    └── Write ──────> Edge Functions (Deno)
                            │
                            ▼
                      PostgreSQL
                            │
                            ├── Triggers (비즈니스 로직, 상태 전환)
                            ├── PGMQ (비동기 큐: 알림, 벡터화)
                            └── pg_cron (이벤트 상태 전환)
```

상세: [client.md](./client.md), [backend.md](./backend.md)

---

## 2. 아키텍처 원칙

### 2.1 Feature-first 구조

코드는 기술적 레이어(`screens/`, `widgets/`)가 아닌 도메인 단위(`auth/`, `event/`, `verification/`)로 응집한다.

상세: [client.md §2.1](./client.md#21-feature-first-structure)

### 2.2 EF-only 원칙 (Mutation Gateway)

**모든 데이터 변경(mutation)은 Edge Function을 경유해야 한다.**

```text
Client App  ──→  Edge Function  ──→  PostgreSQL
Simulator   ──→  Edge Function  ──→  PostgreSQL
```

- 클라이언트는 DB에 직접 INSERT/UPDATE/DELETE를 실행하지 않는다.
- Simulator/테스트 코드도 동일한 규칙을 적용한다 (#999에서 EF 통일 진행 중).
- **예외**: pg_cron에 의한 이벤트 상태 전환(scheduled→active 등)은 DB 내부에서 직접 SQL UPDATE를 수행한다.

이 원칙의 이점:
- 인증(auth) 검증을 EF 레이어에서 일관되게 처리
- 비즈니스 로직이 EF에 집중되어 클라이언트가 단순해짐
- 감사(audit) 로그와 사이드이펙트 처리 지점 단일화

### 2.3 Repository 패턴

Supabase SDK를 UI에서 직접 호출하지 않는다. Repository 클래스가 데이터 접근을 추상화하며, Provider가 캐싱을 담당한다.

상세: [client.md §2.4](./client.md#24-repository-pattern-data-access)

---

## 3. 이벤트 라이프사이클

### 3.1 이벤트 상태 머신

이벤트(`events` 테이블)는 5개 상태를 가진다. **상태 전환은 pg_cron 크론잡이 자동 구동한다.**

```text
scheduled
    │
    ├── (시작 30분 전, 크론: activate-upcoming-events)
    ▼
 active
    │
    ├── (시작 시각, 크론: start-active-events)
    ▼
ongoing
    │
    ├── (종료 후 15분 주기, 크론: auto-complete-past-events)
    ▼
completed

scheduled / active
    │
    └── (파트너 수동, EF: partner-manage-event) ──→ cancelled
```

| 상태 | 설명 | 전환 트리거 |
|------|------|------------|
| `scheduled` | 이벤트 생성 직후, 아직 활성화 전 | 파티 생성 또는 이벤트 등록 시 초기값 |
| `active` | 모집 중 (앱 피드에 노출) | 크론: 시작 30분 전 |
| `ongoing` | 이벤트 진행 중 | 크론: 시작 시각 도달 |
| `completed` | 이벤트 종료 (정산 자동 생성) | 크론: 종료 후 (15분 주기) |
| `cancelled` | 파트너가 취소 | 파트너 수동 (EF 경유) |

**코드 작성 규칙**:
- 상태 전환 로직은 EF(`partner-manage-event`) 또는 pg_cron에서만 수행한다.
- 클라이언트가 `events.status`를 직접 UPDATE하지 않는다.
- `completed` 전환 시 `on_event_completed` 트리거가 정산(`settlements`)을 자동 생성한다.

### 3.2 Party → Event 템플릿 패턴

`parties` 테이블은 이벤트의 **템플릿**이다. 파티 하나에서 여러 회차의 이벤트를 생성할 수 있다.

```text
Party (템플릿)
  ├── entry_group_templates  →  Events (회차)
  │                               ├── entry_groups (복사본)
  └── ticket_templates       →   └── tickets (복사본)
```

- 파티 설정(`balance_config`, 인증 요구사항 등)은 이벤트 생성 시 복사된다.
- 이벤트별로 `start_time`, `end_time`이 독립적으로 관리된다.

상세: [backend.md §2.1](./backend.md#21-table-inventory)

---

## 4. 신뢰 및 검증 (Trust & Verification)

Minglit은 **"신뢰(Trust)"**를 핵심 자산으로 취급하며, 2단계 레이어로 관리한다.

### 4.1 Layer 1: Identity (신원)

- **정의**: "이 사람은 실존하며, 주장하는 나이/성별이 맞는가?"
- **데이터**: `user_profiles` 테이블 (`birth_date`, `gender`, `is_verified`)
- **검증 주체**: 플랫폼 (Iamport 본인인증 API)
- **특징**: 모든 유저의 기본 자격. 나이 제한 필터링 등에 즉시 사용.

### 4.2 Layer 2: Qualification (자격)

- **정의**: "이 사람은 우리 파티에 어울리는가?" (직장, 학력, 자산, 외모 등)
- **데이터**: `user_verifications` → `verification_submissions` → `partner_verified_users`
- **검증 주체**: 파트너 (사람이 심사)
- **특징**: 특정 파티/티켓이 요구하는 추가 자격 레이어.

상세: [trust-and-verification.md](./trust-and-verification.md)

---

## 5. 결제 및 환불 아키텍처

### 5.1 결제 파이프라인

```text
User App ──> Portone(Iamport V1) ──> payment-webhook
         ──> payment-verify ──> event_applications
                                      │ (approved → 트리거)
                                      ▼
                               event_participants (티켓 발권)
                                      │ (event completed → 트리거)
                                      ▼
                               settlements (정산 자동 생성)
```

상세: [payment-pipeline.md](./payment-pipeline.md)

### 5.2 환불 정책 아키텍처

환불은 **이원화 구조**로 운영된다.

| 구분 | 주체 | 방식 | 타이밍 |
|------|------|------|--------|
| **플랫폼 자동 환불** | 시스템 | `on_application_rejected` 트리거 → `payment-cancel` EF | 파트너가 신청을 거절할 때 즉시 |
| **파트너 환불** | 파트너 | 파트너 앱에서 수동 환불 요청 → `payment-cancel` EF | 파트너 재량 |

**코드 작성 규칙**:
- 환불 처리는 반드시 `payment-cancel` Edge Function을 통해 수행한다. DB 직접 UPDATE 금지.
- 수수료 정책(PG 3.5%, 플랫폼 5%)은 현재 `create_settlement_on_event_completion` 함수에 하드코딩되어 있다. 향후 `policies` 테이블의 tier 정책을 코드가 읽도록 개선 예정 (#765).
- 환불 상태: `none` → `requested` → `completed` / `failed`

상세: [payment-pipeline.md §5](./payment-pipeline.md#5-refund-flow)

---

## 6. 횡단 관심사 (Cross-cutting Concerns)

### 6.1 에러 처리

클라이언트에서 모든 에러 처리는 `minglit_kit`의 `handleMinglitError`를 통해 수행한다.

- `MinglitUserException`: 유저에게 보여줄 친절한 메시지 (SnackBar Secondary Color)
- `MinglitAuthException`: 인증 관련 오류
- `MinglitSystemException` / Unknown: 유저에게는 안전한 메시지, 시스템에는 StackTrace 로깅 (SnackBar Error Color)

Edge Function 에러는 `sentry_utils.ts`의 `withSentry` / `withSentryHandler`로 Sentry에 트래킹한다.

### 6.2 Provider 조직화

Provider와 Repository의 위치 결정 기준:

- **`minglit_kit` (공유)**: `app_user`와 `app_partner` 모두 필요하거나 Supabase 테이블을 래핑하는 경우
- **앱 feature 폴더**: 단일 앱에서만 쓰이거나 UI 상태(controller, form state), Coordinator인 경우

상세: [client.md §6](./client.md#6-provider-organization-guidelines)

---

## Related Documents

| 문서 | 내용 |
|------|------|
| [client.md](./client.md) | Flutter 앱 상세 아키텍처 (Feature-first, Coordinator, Repository, Design System) |
| [backend.md](./backend.md) | Supabase 백엔드 (테이블, Edge Functions, RLS, Triggers) |
| [trust-and-verification.md](./trust-and-verification.md) | 2-layer 신뢰 모델 상세 |
| [payment-pipeline.md](./payment-pipeline.md) | 결제/정산 파이프라인 상세 |
| [search-and-recommendation.md](./search-and-recommendation.md) | PGroonga 검색 + pgvector 추천 |
| [global-event-pipeline.md](./global-event-pipeline.md) | PGMQ 2-tier 이벤트 파이프라인 |

