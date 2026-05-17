# PRD: 통계·분석 도구 (Statistics & Analytics Tools)

## Summary

밍글릿의 통계/분석 인프라(Feature Flags, Product Analytics, BI Dashboard, Error Monitoring, Alerts)를 외부 SaaS 비용을 최소화하면서 Phase 1 기준으로 운영팀이 즉시 사용 가능한 형태로 구축한다.

## Motivation / Problem to Solve

- 운영팀이 DAU·결제·매칭 성공률 등 핵심 지표를 매일 추적할 채널이 없음 — 의사결정이 직관에 의존
- 신규 기능 출시 시 점진적 롤아웃 / kill switch 가 없어 사고 발생 시 즉시 차단 불가
- 결제·매칭 실패 등 임계치 초과 상황을 운영팀이 능동적으로 인지할 수단 부재 (Sentry 만으로는 비즈니스 지표 alert 불가)
- 외부 SaaS 비용을 DAU 10K 시점에 $600/월 이상 지불할 의향 없음 — 무료 티어 위주 도구 선정 필요

## Goals

### Target Users

- **운영팀 / PM**: 매출, DAU, 퍼널 전환율 등 일간 지표 조회 (Metabase 대시보드)
- **개발팀**: Feature flag 로 점진 출시 / kill switch 운영 (Statsig)
- **운영팀 (incident 대응)**: 임계치 초과 시 GitHub Issue 자동 생성 알림 수신

### Key Goals

- **P0**: Feature Flags + Product Analytics 무료 운영 (DAU 10K 시 월 $0)
- **P0**: BI 대시보드 셀프호스팅으로 PII 접근 차단된 read-only role 로 분리
- **P0**: 핵심 7종 이벤트만 수집 (이벤트 폭증 / 비용 증가 방지)
- **P0**: 임계치 기반 자동 알림 (에러율 / 매출 급락 / DLQ 적체) → GitHub Issue 자동 생성
- **P1**: dev / prod 환경 분리 (Statsig tier parameter)
- **P1**: 일간·주간 자동 리포트 (매일 9AM KST)

### Non-Goals

- Session Replay (Phase 2 검토)
- A/B 실험 자동 분석 (Statsig 기본 기능만 사용, 분석 자동화는 Phase 2)
- 30+ 이벤트 수집 (Lean 7종 고정, Phase 2 에서 확장 검토)
- Slack 알림 (GitHub Issues 로 통일)
- 사내 BI 대시보드 위 view 자체 빌드 (Metabase 연결까지만, 대시보드 구축은 Phase 2)

## Product Principles

1. **Lean events**: 추적 가치가 명확한 7종만 수집. 의사결정에 쓰지 않을 이벤트는 추가 금지
2. **무료 우선**: 무료 티어 / 셀프호스팅 우선 — 유료 전환은 명확한 ROI 산정 후
3. **PII 격리**: BI 도구는 집계 schema 만 접근. 원본 PII 컬럼(생년월일, CI/DI, 휴대폰) 접근 불가
4. **자동 알림 over 수동 모니터링**: 임계치 정의 → 초과 시 자동 Issue. 사람이 대시보드를 매번 들여다보지 않아도 됨

## Technical Approach

- **Feature Flags + Product Analytics**: Statsig (Flutter, Next.js 클라이언트 SDK + Edge Functions REST API 래퍼)
- **BI Dashboard**: Metabase (Oracle Cloud ARM 무료 인스턴스 + Cloudflare Tunnel + Zero Trust Access)
- **DB 접근**: `analytics` schema + 읽기 전용 role. 일별 집계 테이블(DAU / 이벤트 / 매출 / 퍼널)을 pg_cron 으로 갱신
- **Error Monitoring**: Sentry 유지 (Flutter + Edge Functions, sample rate 0.2)
- **Alerts**: metrics-alert Edge Function — 임계치 초과 시 GitHub Issues API 호출 + 중복 방지(open issue 존재 시 댓글)
- **외부 의존성**: Statsig, Metabase, Sentry, GitHub API, Oracle Cloud Free Tier, Cloudflare (Tunnel + Zero Trust)
- **환경 분리**: client key (공개) vs server key (시크릿). dev / prod tier parameter

## User Journey

### Scenario 1: 운영팀 일간 지표 조회 (CUJ 1-x)

운영팀이 매일 아침 Metabase 에 접속해 어제 매출 / DAU / 결제 성공률을 확인한다.

### Scenario 2: 개발팀 Feature Flag 운영 (CUJ 2-x)

개발팀이 신규 기능을 staging tier 에 먼저 켜고, 검증 후 production tier 활성. 사고 발생 시 즉시 OFF.

### Scenario 3: 임계치 초과 자동 알림 (CUJ 3-x)

결제 에러율이 5% 를 넘으면 metrics-alert 가 GitHub Issue 를 자동 생성. 운영팀이 라벨로 필터링해 대응.

### Scenario 4: 클라이언트 이벤트 수집 (CUJ 4-x)

유저가 앱을 열거나 결제를 완료하면 Statsig 에 이벤트가 기록되어 다음 날 집계 테이블에 반영된다.

## Data Flow

### Scenario 1

운영팀 → Cloudflare Zero Trust 이메일 OTP → Metabase 접속 → analytics schema 의 집계 테이블 조회 → 차트/대시보드 표시

### Scenario 2

Statsig 콘솔에서 flag 토글 → 클라이언트 SDK 가 다음 polling 주기에 새 값 반영 → 해당 코드 분기 활성/비활성

### Scenario 3

pg_cron(15분 간격) → metrics-alert 호출 → 임계치 초과 감지 → GitHub Issues API 로 신규 Issue 생성(또는 기존 open issue 에 댓글) → 운영팀 알림

### Scenario 4

클라이언트 SDK / Edge Functions → Statsig 이벤트 전송 → Statsig 일일 export → analytics 집계 테이블에 반영 → Metabase 에서 조회

## KPIs / Success Metrics

- **월 도구 비용**: $0 유지 (DAU 10K 시점 기준)
- **알림 응답 시간**: 임계치 초과 → GitHub Issue 생성까지 p95 < 15분
- **이벤트 수 유지**: 7종 고정 (분기 1회 audit 으로 미사용 / 중복 이벤트 제거)
- **BI 대시보드 가동률**: 월간 99% 이상 (Cloudflare Tunnel 연결 기준)
- **PII 노출 사고**: 0건 (analytics_reader role 분리)

## Launch Strategy

Phase 1 은 운영팀 / 개발팀 내부 한정 출시. 외부 노출 화면 없음. Phase 2 에서 대시보드 view 추가, 이벤트 확장(30종), Session Replay 검토.

## References

- Statsig Dart SDK: https://pub.dev/packages/statsig
- Statsig React SDK: https://www.npmjs.com/package/@statsig/react-bindings
- Metabase ARM Docker: https://hub.docker.com/r/metabase/metabase
- Cloudflare Tunnel: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- Sentry Flutter: https://docs.sentry.io/platforms/flutter/
- 비용 비교 근거: PostHog DAU 10K 시점 ~$600/월 vs Statsig 무제한 무료
