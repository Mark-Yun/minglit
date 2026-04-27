# Operations & Incident Response — AI-first 모델

> minglit은 solo founder + AI 워커 운영 모델. 일반 startup과 incident response 다름.
> 운영 원칙 base: [ai-first-principle.md](../background/ai-first-principle.md)
> 인시던트 history: [docs/reports/ops/](../reports/ops/)

## 1. 운영 모델 핵심

### Mark vs AI 워커 책임 분담

```
[Mark] vision + 외부 자문 + 명확한 게이트 결정
   ↓
[AI 워커] 운영 / audit / 코드 / fix / 모니터링
   ↓
[GitHub] 단일 진실 (이슈/PR/리포트 모두 여기 모임)
```

### Mark 승인 필수 영역

✅ **반드시 Mark 게이트**:
- **UI 변경** (사용자 첫인상 영향)
- **새 feature 추가** (제품 방향 결정)

✅ **AI 워커 자율 가능** (Mark 승인 없이):
- 버그 fix (기능 회복)
- 코드 리팩토링
- 성능 최적화
- audit-* 리포트 작성
- 코드 리뷰 + PR 머지 (admin merge 포함, escrow 메커닉처럼 자동 게이트로 제어)
- 환경변수/설정 수정
- 마이그레이션 적용 (변경 영향 범위 small인 경우)
- 정기 운영 (정산 송금, retention 파기)

### 게이트 명확화 원칙 (ai-first-principle.md)

- 게이트는 **명확히 정의된 항목만**. 그 외 → AI 자율.
- 게이트 늘리면 minglit의 AI-first 사업 구조 자체가 약해짐.

## 2. 인시던트 Severity (CLAUDE.md 라벨)

| Label | 의미 | 처리 기한 |
|-------|------|----------|
| `P0-critical` | 서비스 장애, 즉시 수정 | 당일 |
| `P1-high` | 핵심 기능 버그 | 이번 주 |
| `P2-medium` | 일반 버그, 감사 이슈 | 다음 스프린트 |
| `P3-low` | 테스트 보강, enhancement | 여유 시 |

AI 워커 처리 순서: **P0 > P1 > P2 > P3 > 라벨 없음**, 같은 우선순위 내 이슈 번호 ↓.

## 3. 인시던트 탐지 시그널 (현재)

| 시그널 | 출처 | 형태 | 상태 |
|--------|------|------|------|
| **CI 실패** | GitHub Actions | `ops/alerts/` 자동 이슈 생성 | ✅ 작동 (백필 19건) |
| **Runtime QA 실패** | runtime-qa-* 워커 (ADB + 단말) | `report-runtime-qa` 라벨 이슈 | ✅ 작동 |
| **Audit 발견** | audit-* 워커 5종 (security/legal/uiux/qa/architecture) | `audit-report` 라벨 이슈 | ✅ 작동 |
| **Sentry 에러** | Flutter + Edge Function | 자동 알림 → 이슈? | ⚠️ **체계화 미흡** |
| **Statsig 메트릭** | feature flags + 실험 | 임계치 알림 | ⚠️ 미설정 |
| **Supabase 모니터링** | DB 부하 / 연결 | Supabase dashboard | ⚠️ 자동화 X |
| **사용자 신고 (in-app)** | bug-report 라벨 | runtime-qa-* 워커 triage | 🟡 일부 |

### Gap — 체계화 필요 (TODO)

현재 미흡한 영역:
- 앱 레벨 모니터링 체계 (Sentry → 자동 이슈/알림 룰)
- EF 레벨 모니터링 (Sentry + Axiom 통합)
- 임계치 기반 자동 alert (Statsig 메트릭)
- Database 모니터링 자동화 (Supabase)

**우선순위**: 첫 PRD 릴리즈 (2026-07) 후 즉시 체계화.

## 4. P0 발생 시 흐름

### 현재 (2026-04)

```
P0 발생
  ↓
audit/runtime-qa 워커 또는 CI 실패 트리거
  ↓
GitHub Issue 자동 생성 (ops/alerts/ 또는 ops/incidents/)
  ↓
Mark이 GitHub 알림으로 인지
  ↓
Mark이 AI 워커에게 위임 (또는 직접 게이트가 필요한 결정만 처리)
  ↓
워커 fix → PR → admin merge → 배포
```

### 한계

- **Mark이 자고 있을 때**: GitHub 알림만으로는 즉시 안 깨짐
- **Mark이 외부 일 중일 때**: 알림 놓칠 위험
- → P0 영향이 길어질 수 있음

### 향후 (Q3 2026 도입)

- **Slack 또는 Discord 봇 push** — P0 라벨 이슈 즉시 push 알림
- **모바일 push 알림** — Mark 폰으로 직접
- **AI 워커 자율 hot-fix 권한 확대** — 명확히 정의된 케이스 (예: env 변수 수정, rollback)
- **자동 mitigation** (서비스 일시 중단 / 안전 모드 등)

## 5. AI 워커 자율 hot-fix 가능 영역

### 자율 OK

- 버그 fix PR (테스트 통과 시)
- env 변수 hot-fix (특정 환경)
- 마이그레이션 적용 (RLS 추가 같은 보수적 변경)
- 사용자 알림 발송 (사전 정의된 템플릿)
- 정기 작업 (정산, retention 파기)

### Mark 승인 필수

- UI 변경
- 새 feature
- 외부 vendor 통신 (PortOne 일괄 환불 같은 large-scale)
- 약관 변경
- 사업자 정보 변경
- 무엇을 자율로 할지 결정 자체 (이 문서의 정의)

### Default 원칙

> "이 게이트가 늘어나면 AI-first 사업 구조 자체가 약해짐. 게이트는 명확히 정의된 것만, 그 외엔 AI 자율."

## 6. 배포 정책

### 현재 (2026-04)

- dev → main 머지 = production 배포 트리거
- Vercel: cron + workflow_dispatch
- Supabase: 마이그레이션 push로 적용
- Flutter: TestFlight / Play Console 별도 빌드 (현재 manual)

### 향후 (첫 PRD 릴리즈 후)

- **Statsig A/B 테스트** — 새 feature 점진 롤아웃
- **Continuous Integration release** — 자동 deploy pipeline
- **카나리 / blue-green** — 사고 영향 최소화
- **Auto rollback** — 에러율 임계치 시 자동 이전 버전

`<TODO: 첫 PRD 릴리즈 후 운영 정책 ADR 추가>`

## 7. Post-Mortem 흐름

### 현재 모델

- **자동 작성** by audit-* 워커 (특히 audit-arch / audit-qa)
- 저장 위치: `docs/reports/{architecture|qa|security|...}/`
- 형태: GitHub Issue + frontmatter + 본문 분석
- audit-report-work.txt 프롬프트가 docs/reports/{category}/ 자동 동기화 ([minglit-worker-runtime](https://github.com/Mark-Yun/minglit-worker-runtime))

### Triggering events

- P0 인시던트 자동 → audit-arch 또는 audit-security 워커
- 정기 cycle (주간/일간) → 패턴 분석
- 동일 인시던트 반복 (동일 root cause 3회+) → 별도 분석

### Post-mortem 표준 구조

1. 발생 시점 + 영향 범위
2. 탐지 → 대응까지 timeline
3. Root cause
4. 임시 mitigation
5. 영구 fix
6. 재발 방지 조치
7. Action items + 담당 워커

## 8. 알려진 운영 갭 (TODO)

- 🔲 **모니터링 체계화** (Q3 2026) — 앱/EF/DB 통합 알림
- 🔲 **P0 즉시 알림 채널** — Slack/Discord 봇 + 모바일 push
- 🔲 **AI 워커 자율 hot-fix 영역 확대** — 정의 + 권한 부여
- 🔲 **CI/CD pipeline + 카나리** — 첫 PRD 릴리즈 후
- 🔲 **on-call rotation X** — solo founder + AI 모델은 rotation 개념 다름. AI 워커가 24/7 모니터링하므로 사실상 "AI on-call"

## 9. 사용자/Partner 영향 시 communication

### Outage 알림

- **In-app 배너** — 상태 페이지 또는 앱 시작 시
- **Partner 직접 알림** (이메일/카카오톡) — 정산 지연 등 영향 시
- **공식 status page** — `<TODO: status.minglit.com 같은 페이지 별도 운영 검토>`

### Post-incident 사용자 communication

- 큰 영향 시: 사과 + 보상 (포인트, 환불, 무료 이벤트 권한 등)
- 작은 영향 시: 별도 communication X (조용히 fix)
- Mark 게이트: 큰 영향 communication은 Mark 승인 필수

## 10. 다른 docs와의 관계

- [ai-first-principle.md](../background/ai-first-principle.md) — Mark 게이트 정의 + AI 워커 자율 영역
- [business-plan-internal.md](../background/business-plan-internal.md) §7 — Risk + Mitigation
- [legal-context.md](../background/legal-context.md) — 법적 의무 위반 시 인시던트
- [CLAUDE.md](../../CLAUDE.md) — P0-P3 라벨 정의
- [docs/reports/ops/](../reports/ops/) — 인시던트 이력
