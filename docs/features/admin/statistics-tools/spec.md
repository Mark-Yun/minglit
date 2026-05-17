# Spec: 통계·분석 도구

> **참조**
> - PRD: [prd.md](./prd.md)
> - MDS specs: 해당 없음 — 운영팀 / 개발팀 전용 인프라 (외부 노출 화면 없음). Metabase / Statsig / Sentry 콘솔은 외부 SaaS UI 그대로 사용

## CUJs

| ID  | Priority | CUJ Name | Details | FR | NFR |
|-----|----------|----------|---------|----|----|
| 1-1 | P0 | 운영팀 Metabase 일간 지표 조회 | • Zero Trust 이메일 OTP 인증<br>• Metabase 접속 → 어제 DAU / 매출 / 결제 성공률 조회<br>• 차트 / 표 형식으로 확인 | FR-1, FR-2, FR-3 | NFR-1, NFR-2 |
| 1-2 | P1 | 매일 9AM KST 자동 일간 리포트 | • pg_cron 트리거<br>• 전일 핵심 지표 요약을 GitHub Issue 로 자동 생성<br>• `metrics-alert`, `report` 라벨 부여 | FR-9, FR-10 | NFR-4 |
| 1-3 | P1 | 주간 리포트 (PM/운영 정기 회의용) | • 매주 월요일 9AM KST<br>• 전주 핵심 지표 + 전주 대비 추이<br>• Issue 본문에 요약 표 | FR-9 | NFR-4 |
| 2-1 | P0 | 신규 기능 Feature Flag 점진 출시 | • Statsig 에서 flag 생성<br>• development tier 만 ON 으로 검증<br>• production tier 활성 후 모니터링 | FR-4, FR-5 | NFR-3 |
| 2-2 | P0 | 사고 발생 시 Feature Flag kill switch | • production tier 즉시 OFF<br>• 클라이언트 SDK polling 주기 내 반영<br>• 영향 범위 즉시 차단 | FR-5 | NFR-3 |
| 3-1 | P0 | 결제 에러율 임계치 초과 → 자동 Issue | • 15분 간격 임계치 체크<br>• 결제 에러율 > 5% 감지<br>• `metrics-alert`, `performance` 라벨 Issue 자동 생성 | FR-6, FR-7 | NFR-4, NFR-5 |
| 3-2 | P0 | 비즈니스 지표 급락 알림 | • 매출 전일 대비 -30% 또는 전환율 -20% 감지<br>• `business-metrics` 라벨 Issue 자동 생성 | FR-6, FR-7 | NFR-4 |
| 3-3 | P1 | 인프라 적체 알림 (DLQ / cron 누락) | • DLQ > 10 또는 cron 미실행 감지<br>• `infrastructure` 라벨 Issue 자동 생성 | FR-6, FR-7 | NFR-4 |
| 3-4 | P1 | 동일 알림 중복 차단 | • 같은 제목의 open Issue 가 이미 있으면 댓글 1줄만 추가<br>• 새 Issue 생성 차단 | FR-8 | NFR-4 |
| 4-1 | P0 | 앱 실행 시 DAU 이벤트 수집 | • 유저가 앱 콜드 스타트<br>• 클라이언트가 Statsig 에 `app_opened` 이벤트 전송<br>• 다음 날 일별 집계 테이블에 반영 | FR-11, FR-12 | NFR-1 |
| 4-2 | P0 | 결제 성공/실패 이벤트 수집 | • 결제 검증 EF 성공/실패 분기<br>• 각각 `payment_completed` / `payment_failed` 이벤트 전송<br>• 일별 결제 성공률 집계 | FR-11, FR-12 | NFR-1 |
| 4-3 | P1 | dev 환경 이벤트는 prod 와 분리 | • Statsig tier parameter 가 `development` 일 때 prod 대시보드에 미반영<br>• analytics schema 도 환경별 분리 | FR-13 | NFR-3 |
| 4-4 | P0 | BI 도구의 PII 접근 차단 | • analytics_reader role 로 접속<br>• `auth`, `public` schema 의 PII 컬럼 SELECT 시도 → 권한 거부 | FR-14, FR-15 | NFR-6 |

## Functional Requirements

- **FR-1**: Metabase 는 Cloudflare Tunnel + Zero Trust Access (이메일 OTP) 뒤에서만 접근 가능. 인증 없는 직접 접근 차단.
- **FR-2**: Metabase 는 analytics_reader role 로만 DB 접근. SELECT 만 허용, DML/DDL 불가.
- **FR-3**: 일별 집계 테이블(DAU / 이벤트 / 매출 / 퍼널) 4종은 pg_cron 으로 매일 정해진 KST 새벽 시간대에 갱신.
- **FR-4**: Statsig 에서 신규 flag 생성 시 dev 환경에서 먼저 활성화 가능. prod 환경 활성은 별도 토글.
- **FR-5**: prod flag OFF 시 클라이언트 SDK 가 polling 주기 내(기본 60초 이하) 새 값 반영.
- **FR-6**: metrics-alert 는 4종 타입(performance / business / infra / report)을 지원. 각 타입별 임계치는 정책으로 정의.
- **FR-7**: 임계치 초과 시 GitHub Issues API 로 신규 Issue 생성. 타입별 정해진 라벨(`metrics-alert` + 타입별 라벨) 부여.
- **FR-8**: 같은 제목의 open Issue 가 이미 있으면 신규 생성 대신 해당 Issue 에 댓글만 추가 (중복 알림 방지).
- **FR-9**: 일간 리포트(매일 9AM KST) / 주간 리포트(매주 월요일 9AM KST) 는 임계치와 무관하게 항상 생성.
- **FR-10**: 리포트 Issue 본문에는 전일/전주 핵심 지표 요약 표 포함 (매출, DAU, 결제 성공률, 매칭 성공률, 에러율).
- **FR-11**: 클라이언트(Flutter, Next.js)는 7종 이벤트만 전송 (`app_opened`, `event_viewed`, `event_applied`, `payment_completed`, `payment_failed`, `matching_result`, `error_occurred`). 그 외 추가 금지.
- **FR-12**: 서버측(Edge Functions)에서 발생하는 이벤트(결제 성공/실패 등)는 Statsig REST API 로 전송.
- **FR-13**: Statsig tier parameter 로 dev / prod 이벤트가 명확히 분리. dev 이벤트는 prod 집계에 반영되지 않음.
- **FR-14**: analytics 집계 테이블 외 schema 의 PII 컬럼(생년월일, CI/DI, 휴대폰)은 analytics_reader role 로 접근 불가.
- **FR-15**: 신규 Edge Function 추가 시 결제 검증 EF 와 동일 패턴으로 Sentry span 자동 측정 (DB 쿼리 performance).

## Non-Functional Requirements

- **NFR-1**: 클라이언트 이벤트 전송은 비동기 fire-and-forget — 사용자 화면 응답에 영향 없음. p95 응답 < 50ms 영향 한도.
- **NFR-2**: Metabase 가동률 월간 99% 이상 (Cloudflare Tunnel 연결 기준). 분기당 다운타임 < 1시간.
- **NFR-3**: Feature flag prod OFF 후 클라이언트 반영 p95 < 60초.
- **NFR-4**: 임계치 초과 감지 → GitHub Issue 생성까지 p95 < 15분 (pg_cron 15분 주기 보장).
- **NFR-5**: metrics-alert 자체 가용성 — pg_cron 누락률 1% 미만. 누락 시 다음 cron 에서 보강.
- **NFR-6**: BI 도구의 PII 노출 사고 0건 (분기별 권한 audit). audit 발견 시 즉시 role 차단.
- **NFR-7**: Sentry sample rate 0.2 — 트래픽 대비 비용 안정. 결제 / 매칭 등 critical path 는 별도 100% sampling 검토.

## Edge Cases

| CUJ ID | 케이스 | 기대 동작 |
|--------|--------|----------|
| 1-1 | Cloudflare Tunnel 연결 끊김 | Metabase 접근 불가. Sentry / 운영팀 별도 알림 — 복구 시 자동 재연결 |
| 1-1 | pg_cron 집계 실패 (DB 부하) | 다음 cron 주기에서 보강. 누락 일은 운영팀에 별도 알림 |
| 1-2 | 일간 리포트 생성 실패 (GitHub API 장애) | 1회 재시도 → 실패 시 Sentry 에러. 다음 날 정상 생성 |
| 2-1 | dev tier 활성 상태에서 prod 트래픽이 dev 키 사용 | 환경 분리 검증 자동화 — 빌드 시 환경별 키 매칭 검증 |
| 2-2 | prod kill switch 후 클라이언트가 한참 동안 polling 안 함 (백그라운드) | 다음 포그라운드 진입 시 즉시 반영. 인 메모리 캐시 무효화 |
| 3-1 | 임계치 초과가 짧은 spike 인 경우 | 15분 윈도우 평균으로 판정 — 1분 spike 는 알림 생성 안 함 |
| 3-4 | open Issue 가 있지만 사람이 close 한 직후 재발 | 신규 Issue 생성 (close 후 1분 grace) |
| 4-1 | Statsig 일시 장애 | 클라이언트 이벤트 큐잉 후 복구 시 일괄 전송. 데이터 손실 최소화 |
| 4-3 | dev / prod 이벤트가 동일 키로 잘못 전송 | tier parameter 부재 시 빌드 실패 (lint / CI 차단) |
| 4-4 | 권한 변경 실수로 analytics_reader 가 PII 컬럼 SELECT 가능 | 분기 audit 에서 즉시 발견 → role 즉시 회수 |

## Open Questions

- [ ] **Sentry sample rate 0.2 적정성** — 결제 / 매칭 critical path 만 100% 로 분리할지?
- [ ] **임계치 정확한 수치** — 에러율 5% / 매출 -30% / DLQ 10 의 baseline 데이터 누적 후 재조정 필요
- [ ] **GitHub Issue spam 방지** — 동일 incident 가 다수 라벨로 중복 생성될 가능성 — 추가 dedupe rule 필요?
- [ ] **Phase 2 이벤트 확장 시점** — 30종 까지 늘리는 기준 (DAU? 비즈니스 마일스톤?)
- [ ] **A/B 실험 자동 분석** — Statsig 기본 통계 신뢰 vs 자체 분석 파이프라인?
- [ ] **운영팀 알림 채널 다양화** — GitHub Issue 외 추가 (인앱 / 이메일 / 모바일 푸시)?

---

## 화면 구성 (참고)

> 본 feature 는 외부 SaaS UI(Metabase / Statsig / Sentry / GitHub) 를 그대로 사용. 자체 UI 없음.

### 도구 구성

| 영역 | 도구 | 호스팅 |
|------|------|--------|
| Feature Flags + Product Analytics | Statsig | SaaS (무료 티어) |
| BI Dashboard | Metabase | Oracle Cloud ARM A1 Free Tier (Docker) |
| Error Monitoring | Sentry | SaaS (기존 유지) |
| Alerts | GitHub Issues (자동 생성) | GitHub |
| 접근 통제 | Cloudflare Tunnel + Zero Trust Access | Cloudflare 무료 |

### BI 인프라 토폴로지

```
Supabase PostgreSQL (analytics schema)
    ↓ (analytics_reader 읽기 전용)
Oracle Cloud ARM A1 (2 OCPU / 12GB RAM)
  · Ubuntu 22.04 · Docker · Metabase
    ↓
Cloudflare Tunnel (cloudflared)
    ↓
https://metabase.minglit.com
    ↓
Cloudflare Zero Trust Access (이메일 OTP)
```

### Lean 이벤트 7종 (참고)

| 이벤트 key | 발생 위치 | 목적 |
|-----------|-----------|------|
| `app_opened` | 앱 스타트업 | DAU |
| `event_viewed` | 이벤트 상세 진입 | 조회 퍼널 |
| `event_applied` | 신청 완료 | 신청 퍼널 |
| `payment_completed` | 결제 검증 성공 | 결제 성공률 |
| `payment_failed` | 결제 검증 실패 | 결제 실패율 |
| `matching_result` | 매칭 결과 화면 | 매칭 성공률 |
| `error_occurred` | 에러 핸들러 | 에러 추적 |

### Analytics 일별 집계 테이블 (참고)

| 테이블 | 집계 내용 | 갱신 주기 |
|--------|----------|----------|
| `analytics.daily_active_users` | 앱별 DAU | 매일 새벽 KST |
| `analytics.daily_events` | 이벤트별 카운트 | 매일 새벽 KST |
| `analytics.daily_revenue` | 일별 총매출 / 환불 | 매일 새벽 KST |
| `analytics.funnel_daily` | 퍼널 단계별 전환율 | 매일 새벽 KST |

### Alert 4종 (참고)

| 타입 | 트리거 조건 | GitHub 라벨 |
|------|-----------|-------------|
| `performance` | 에러율 > 5%, 응답시간 > 2s | `metrics-alert`, `performance` |
| `business` | 매출 전일 대비 -30%, 전환율 -20% | `metrics-alert`, `business-metrics` |
| `infra` | DLQ > 10, cron 누락 | `metrics-alert`, `infrastructure` |
| `report` | 일간 / 주간 정기 요약 | `metrics-alert`, `report` |

### 환경 분리 (참고)

| 키 | 사용처 | 가시성 |
|----|--------|--------|
| `STATSIG_CLIENT_KEY` | Flutter + Next.js | 클라이언트 공개 |
| `STATSIG_SERVER_KEY` | Edge Functions | 서버 시크릿 |
| Statsig `tier` | 모든 환경 | `development` / `production` |
