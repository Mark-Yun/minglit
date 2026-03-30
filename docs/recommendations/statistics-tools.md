# Statistics & Analytics Tools — Minglit

> **Status**: ✅ Implemented (Phase 1)  
> **Date**: March 2026  
> **Author**: Infrastructure Team

## Overview

Minglit의 통계/분석 인프라 선정 기준과 최종 구성을 정리한 문서입니다.
Phase 1에서 Statsig + Metabase + Sentry + GitHub Issues 알림 시스템을 구축했습니다.

---

## 도구 선정 요약

| 카테고리 | 선정 도구 | 탈락 도구 | 이유 |
|---------|---------|---------|------|
| Feature Flags + Analytics | **Statsig** | PostHog | 비용, 무료 티어 |
| BI Dashboard | **Metabase** | - | 자체 호스팅 무료 |
| Error Monitoring | **Sentry** (유지) | - | 기존 운용 중 |
| Alerts | **GitHub Issues** (자동) | Slack | 별도 도구 불필요 |

---

## 1. Feature Flags & Product Analytics — Statsig

### 선정 이유

#### PostHog vs Statsig 비교

| 항목 | PostHog (탈락) | Statsig (선정) |
|------|-------------|-------------|
| Feature Flags | 유료 (1M/월 이후 $0.0001/flag) | **무제한 무료** |
| Product Analytics | 1M 이벤트/월 무료 | **2M 이벤트/월 무료** |
| DAU 10K 예상 비용 | **~$600/월** | **$0/월** |
| 셀프호스팅 | 무료지만 기능 제한 | N/A |
| Dart SDK | 비공식 | **공식 pub.dev** |
| React SDK | 공식 | 공식 |
| Deno Edge Functions | SDK 미지원 | **REST API** 지원 |

### 구현 구성

- **Flutter 앱**: `StatsigAnalytics` 정적 클래스 (package:statsig v1.2.6)
- **Next.js 랜딩**: `@statsig/react-bindings` StatsigProvider
- **Edge Functions**: `statsig_utils.ts` REST API 래퍼

### Lean 이벤트 전략 (7종 고정)

| 이벤트 | 삽입 위치 | 목적 |
|--------|---------|------|
| `app_opened` | appStartup provider | DAU 추적 |
| `event_viewed` | 이벤트 상세 페이지 | 조회 퍼널 |
| `event_applied` | 신청 완료 후 | 신청 퍼널 |
| `payment_completed` | payment-verify 성공 | 결제 성공률 |
| `payment_failed` | payment-verify 실패 | 결제 실패율 |
| `matching_result` | 매칭 결과 화면 | 매칭 성공률 |
| `error_occurred` | 에러 핸들러 | 에러 추적 |

> ⚠️ 30+ 이벤트 수집 금지. 7종만 유지. Phase 2에서 확장 가능.

### 환경 분리

- `STATSIG_CLIENT_KEY` → Flutter + Next.js (클라이언트 공개 키)
- `STATSIG_SERVER_KEY` → Edge Functions만 (서버 시크릿 키)
- Statsig tier parameter: `development` (dev) / `production` (prod)

---

## 2. BI Dashboard — Metabase

### 아키텍처

```
Supabase PostgreSQL (analytics schema)
    ↓ (analytics_reader 읽기 전용)
Oracle Cloud ARM A1 Free Tier
  - Ubuntu 22.04
  - Docker + Metabase v0.53.5.4+
  - 2 OCPU / 12GB RAM
    ↓
Cloudflare Tunnel (무료, cloudflared)
    ↓
https://metabase.minglit.com
    ↓
Cloudflare Zero Trust Access (이메일 OTP, 50유저 무료)
```

### DB 접근 제어

- **Role**: `analytics_reader` — SELECT only
- **Schema**: `analytics` (집계 테이블만)
- **접근 불가**: `public`, `auth` 스키마
- **PII 접근 불가**: birth_date, ci, di, phone

### Analytics 집계 테이블 (pg_cron 자동 집계)

| 테이블 | 집계 내용 | pg_cron 실행 (UTC) |
|--------|---------|------------|
| `analytics.daily_active_users` | 앱별 DAU | 매일 19:00 (4AM KST) |
| `analytics.daily_events` | 이벤트별 일일 카운트 | 매일 19:15 |
| `analytics.daily_revenue` | 일별 총매출/환불 | 매일 19:30 |
| `analytics.funnel_daily` | 퍼널 단계별 전환율 | 매일 20:00 |

---

## 3. Error Monitoring — Sentry (기존 유지)

- Flutter: `sentry_flutter` (tracesSampleRate: 0.2)
- Edge Functions: `sentry_utils.ts` (initSentry + withSentry + withSpan)
- Phase 1 추가: DB 쿼리 performance spans (payment-verify)

---

## 4. Alerts — GitHub Issues 자동 생성

### metrics-alert Edge Function

4종 알림 타입:

| 타입 | 트리거 | GitHub 레이블 |
|------|--------|-------------|
| `performance` | 에러율 > 5%, 응답시간 > 2s | `metrics-alert`, `performance` |
| `business` | 매출 전일 대비 -30%, 전환율 -20% | `metrics-alert`, `business-metrics` |
| `infra` | DLQ > 10, cron 누락 | `metrics-alert`, `infrastructure` |
| `report` | 일간/주간 요약 | `metrics-alert`, `report` |

- 중복 방지: 동일 제목 open Issue 존재 시 → 댓글만 추가
- pg_cron: 15분마다 임계치 체크 + 매일 9AM KST 일간 리포트

---

## 5. Evolution Path (Phase 2+)

| 현재 (Phase 1) | Phase 2 가능 |
|----------------|-------------|
| Statsig 7 이벤트 | 이벤트 30+, Session Replay |
| Metabase 연결만 | Metabase 대시보드 구축 |
| analytics_reader 기본 권한 | 스키마 격리 강화 |
| Statsig Feature Flags | A/B 테스트 활성화 |
| — | OpenPanel 추가 (실시간 분석) |

---

## 참고 링크

- Statsig Dart SDK: https://pub.dev/packages/statsig
- Statsig React SDK: https://www.npmjs.com/package/@statsig/react-bindings
- Metabase ARM Docker: https://hub.docker.com/r/metabase/metabase
- Cloudflare Tunnel: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- Sentry Flutter: https://docs.sentry.io/platforms/flutter/
