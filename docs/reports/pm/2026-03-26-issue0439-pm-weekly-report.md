---
source_url: https://github.com/Mark-Yun/minglit/issues/439
captured_at: 2026-03-26
issue_number: 439
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Weekly Report — 2026-03-26"
---

# 📊 PM Weekly Report — 2026-03-26

> Issue #439 · closed · created 2026-03-26T02:38:32Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/439

## Body

## 📊 PM Weekly Report — 2026-03-26

### 이번 주 요약
- **이슈**: 30개 생성, 27개 종료 (해결률 90%)
- **PR**: 42개 머지 (Mark 41개, Dependabot 1개)
- **코드**: +26,337 / -15,036 (순증 +11,301 라인)
- **CI**: 핵심 워크플로우(CI, Format, Scanning) 100% 성공 / 보조 워크플로우(Version Bump, CUJ, Deploy) 12건 실패→전부 해결

### 🔍 트렌드 분석

#### 이슈 패턴

| 라벨 | 건수 | 비고 |
|------|------|------|
| `ci-failure` (P0) | 12건 | Version Bump 4, Daily CUJ 3, Vercel Deploy 3, Android Deploy 2 |
| `bug-report` (P2) | 5건 | 전부 UI 관련, 평균 해결 시간 ~1시간 |
| `audit-*` | 8건 | arch 4, qa 1, security 1, bug 1, uiux 1 |

**핵심 패턴**: CI 실패 이슈가 이슈의 40%를 차지. Version Bump 워크플로우가 가장 불안정(4건). 사용자 버그 리포트 5건은 모두 UI 렌더링/색상/레이아웃 관련으로, 디자인 시스템 적용 일관성 문제를 시사.

#### 코드 변경 집중 영역

| 영역 | PR 수 | 주요 내용 |
|------|-------|----------|
| **Edge Functions (신규)** | 10개 | partner-manage-* 5종, user-*-verification 2종, user-cast-vote, partner-register, partner-review-submission |
| **UI 버그 수정** | 6개 | 환불 정책 UI 2건, 대시보드 카드 잘림, 거리 필터 프리즈, 피드 정렬 |
| **CI/인프라** | 8개 | version-bump, daily-e2e, Vercel deploy, smoke test 안정화 |
| **아키텍처 정리** | 4개 | 감사 발견 사항 해결, lint 정리 |
| **테스트** | 3개 | golden test, CUJ Tier 2-3 |
| **문서/도구** | 4개 | 디자인 시스템 가이드 7종, IA 구조도, 디자인 카탈로그, audit-uiux 워커 |

이번 주는 **파트너 앱 백엔드 기능 대폭 확장** 주간. 10개의 Edge Function이 새로 추가되어 파트너 측 CRUD 기능이 서버 사이드로 이동.

---

### 💡 제안

#### 1. 🚨 pgvector 보안 업데이트 확인 (CVE-2026-3172)
**배경**: pgvector 0.6.0–0.8.1에 CVSS 8.1 (HIGH) 버퍼 오버플로우 취약점 발견. 병렬 HNSW 인덱스 빌드 시 민감 데이터 유출 또는 DB 크래시 가능.
**제안**: Supabase 대시보드에서 pgvector 버전 확인 (`SELECT extversion FROM pg_extension WHERE extname = 'vector';`). 0.8.2 미만이면 즉시 업그레이드 요청.
**기대 효과**: 보안 취약점 제거
**예상 비용**: 확인 5분, 업그레이드는 Supabase 측에서 처리
**우선순위 의견**: P0 — 보안 취약점이므로 즉시 확인 필요

#### 2. Cross-Feature Coupling 전용 리팩토링
**배경**: 3일 연속 아키텍처 감사(#404, #412, #436)에서 동일 유형 지적 반복. app_user 16건+, app_partner 9건+, app_partner/party 내부 12건 순환 의존. 개별 PR로 일부 해결(#399, #405)했지만 근본적 해결 안 됨.
**제안**: `event↔payment↔ticket` 삼각 의존을 끊는 전용 리팩토링. Coordinator 패턴을 통한 간접 참조로 전환. 특히 `app_partner/party` 내부 12건 순환은 서브모듈 구조 재설계 필요.
**기대 효과**: 감사 반복 지적 제거, 기능별 독립 테스트 가능, 빌드 영향 범위 축소
**예상 비용**: 중간 (2-3일, 기존 코드 동작 변경 없이 import 구조만 변경)
**우선순위 의견**: P2 — 기능에는 영향 없지만, 매일 감사에서 지적되는 구조적 부채

#### 3. app_partner 테스트 커버리지 긴급 보강
**배경**: QA 감사(#434, #315)에서 app_partner 테스트 비율 29.1% (lib 144파일 / test 42파일). 이번 주 파트너 EF 10개 추가로 서버 사이드 로직은 강화됐지만, 클라이언트 측 연동 테스트가 부재. app_user(71.4%)와 대비해 심각한 격차.
**제안**: 이번 주 추가된 파트너 EF와 연동하는 클라이언트 코드(home, settlement, ticket, party 등)에 대한 위젯/통합 테스트 우선 작성. 목표: 40% (1차), 60% (2차).
**기대 효과**: 파트너 앱 리그레션 조기 감지, CI 게이트 실효성 확보
**예상 비용**: 높음 (102개 파일에 테스트 필요, 단계적 접근 권장)
**우선순위 의견**: P2 — 파트너 앱 기능이 빠르게 확장 중이라 리스크 증가

#### 4. Version Bump 워크플로우 안정화
**배경**: 이번 주 Version Bump 워크플로우가 4회 실패(#377, #376, #363, #357, #354, #353). PR #421에서 카운터→실제 PR 번호 방식으로 수정했지만, 동시 머지 시 브랜치 충돌 문제가 근본 원인.
**제안**: Version Bump을 동시 실행 방지(concurrency group)로 직렬화하거나, bump을 PR 머지 후 직접 dev에 커밋하는 방식으로 전환. 현재 별도 PR 생성 방식이 충돌을 유발.
**기대 효과**: P0 ci-failure 이슈 40% 감소 (12건 중 4-6건이 Version Bump 관련)
**예상 비용**: 낮음 (워크플로우 파일 수정, 1-2시간)
**우선순위 의견**: P1 — 매주 반복되는 CI 노이즈 제거

#### 5. Supabase OpenAPI 엔드포인트 Breaking Change 확인
**배경**: 2026-03-11부터 Supabase에서 anon key로 `GET /rest/v1/` (스키마 인트로스펙션) 호출 시 "Access to schema is forbidden" 에러 반환. 일반 테이블 데이터 API는 영향 없음.
**제안**: Edge Function과 클라이언트 코드에서 `/rest/v1/` 루트 엔드포인트를 anon key로 호출하는 곳이 있는지 확인. 있다면 service role key로 전환.
**기대 효과**: 잠재적 런타임 에러 사전 방지
**예상 비용**: 낮음 (코드 검색 10분)
**우선순위 의견**: P2 — 현재 에러 없으면 영향 없을 수 있지만 확인 필요

---

### ⚠️ 주의 사항
- **CI 실패 노이즈**: 이번 주 이슈의 40%가 ci-failure. 실제 코드 문제보다 인프라 불안정이 원인. Version Bump + Vercel Deploy 안정화가 시급.
- **파트너 앱 테스트 부채**: EF 10개 추가로 백엔드는 견고해졌지만, app_partner 클라이언트 테스트 29.1%는 위험 수준. 기능 추가 속도 대비 테스트 속도가 뒤처짐.
- **UI 버그 패턴**: 5건의 버그 리포트가 모두 UI 렌더링 관련(색상, 레이아웃, 잘림). 디자인 시스템 가이드(#416)와 카탈로그(#417)가 이번 주 추가됐으므로, 이를 활용한 일관성 검수가 필요.
- **감사 피로**: 매일 3-4개 감사 이슈가 생성되지만 같은 패턴 반복 지적. Cross-feature coupling을 근본 해결하지 않으면 감사 효용이 떨어짐.

### 📈 지표
| 지표 | 이번 주 | 비고 |
|------|---------|------|
| 이슈 생성 | 30 | ci-failure 12, bug-report 5, audit 8, 기타 5 |
| 이슈 종료 | 27 | 해결률 90% |
| PR 머지 | 42 | Mark 41, Dependabot 1 |
| 코드 순증 | +11,301 | EF 신규 구현이 대부분 |
| CI 성공률 (핵심) | 100% | CI, Format, Scanning |
| CI 실패 (보조) | 12건 | Version Bump, CUJ, Deploy |
| 소스 파일 수 | 7,259 | .dart + .ts |
| 테스트 파일 (Dart) | 155 | |
| 테스트 파일 (TS) | 53 | |
| Edge Function 수 | 42 | +10 신규 추가 |

---

_이 리포트는 PM Staff Worker가 자동 생성했습니다._
