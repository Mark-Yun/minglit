# Business Plan — Internal Decision Guide

> minglit 사업 의사결정 가이드. 외부 투자자 deck X.
> 미션/비전: [founding-story.md](./founding-story.md), 시장: [research/competitive-landscape.md](../research/competitive-landscape.md)
> Mark가 사업 결정할 때 첫 reference. AI 워커 (PM/TPM)도 참조.

## Quick Reference

| 항목 | 현재 |
|------|------|
| **Stage** | MVP 개발 (2026-07 런칭 목표) |
| **Funding** | Bootstrapped + Mark 별도 income source (외부 펀딩 필요 X) |
| **Runway** | **사실상 무한** (Mark의 외부 수입으로 minglit burn cover 가능) |
| **Team** | Solo founder + AI 워커 |
| **Burn** | ~$200/월 (현재) → ~50만원/월 (법인전환+유료 SaaS 후) |
| **Take rate** | 10% (수수료) |
| **GMV per Partner** | 800만/월 (시나리오: 5만×20명×8회) |
| **Break-even** | Partner ~0.6명 활성화 시 |

## 1. Mission + 5-year Goal

→ [founding-story.md](./founding-story.md)
- **Mission**: 인연을 찾아가는 통과 입구
- **5-year**: 결정사 대체, 200만 회원, 시장 1위

## 2. Unit Economics

### 가정 (시나리오 기반)
| 변수 | 값 | 출처 |
|------|----|----|
| 평균 참가비 | 50,000원 | Mark 시뮬레이션 (4-6만원 중간값) |
| 1회 평균 참가자 | 20명 | 4:4-12:12 평균 |
| Partner 월 운영 빈도 | 주 2회 (=월 8회) | 적극적 Partner 가정 |
| Take rate | 10% | 정률 (모든 유료 이벤트) |

### 계산
| 메트릭 | Partner 1명 | 100 Partner |
|--------|-----------|------------|
| GMV/월 | 800만원 | **8억원** |
| Net Revenue (10%) | 80만원 | **8,000만원** |
| LTV (12개월 가정) | 960만원 | — |

### 민감도
- 보수적 (P-2 개인 호스트, 월 1회): GMV 100만/월 → Net 10만
- 평균 (P-1 사업자, 월 8회): GMV 800만/월 → Net 80만
- 공격적 (대형 사업자, 월 20회): GMV 2,000만/월 → Net 200만

100 Partner pool에서 보수/평균/공격 분포 30:50:20 가정 시 → **월 Net Revenue ~5,500만**

## 3. Burn / Runway

### 현재 비용 구조 (월)
| 항목 | 비용 |
|------|------|
| Claude 구독 (개발 + dev tooling) | ~$200 |
| **합계 (현재)** | **~30만원** |

### 법인 전환 후 예상 (월)
| 항목 | 비용 |
|------|------|
| Claude (생산성 도구) | ~$200 |
| Supabase Pro tier | ~$25 |
| 도메인/DNS | ~$10 |
| 법인 운영비 (회계/세무) | ~20만원 |
| 기타 SaaS (Sentry/Statsig/Axiom — 무료 한도 내 유지) | $0 |
| **합계 (법인 전환 후)** | **~50만원** |

### Runway — 사실상 무한

**Mark의 외부 income source가 minglit 월 burn (~50만원) 충분 cover**.
- 자기자본 소진 시점 없음 (외부 수입이 burn 상회)
- → bootstrapped 모드 무한 유지 가능

### Strategic Implications

이건 minglit에 매우 큰 strategic flexibility를 줌:

| 일반 스타트업 | minglit |
|------------|---------|
| Runway 18개월 → 그 안에 PMF 못 찾으면 sunset | Runway 무한 → 천천히 PMF 검증 가능 |
| 빠른 fundraise 압박 | 외부 자본 의존 X → 결정권 보존 |
| 사용자/매출 KPI 압박 → 단기 결정 자주 | 장기 사용자 trust 우선 결정 가능 |
| 신중한 GTM 경쟁사 노출 risk | 천천히 검증 → 시장 큰 비밀 시간 |

**Trade-off**:
- 자본 효율 ↑ but 성장 속도는 외부 펀딩 받은 경쟁사 대비 늦을 수 있음
- 단, AI-first 사업 구조 → 적은 burn으로도 빠른 iteration 가능 → 자본 사용 효율은 오히려 ↑

### Burn 변동 트리거 (변경 없음)
- 사용자 ↑ → Supabase tier 상향
- AI 워커 호출 ↑ → Claude API 사용량 ↑
- 마케팅 비용 (현재 0) → 도입 시 burn 2-3배 가능

## 4. GTM Strategy

### Phase 1 — Proof (런칭 ~ 첫 10 Partner)
**Mark 직접 운영** + 아는 사람 동원:
- Mark 본인이 1-2 이벤트 직접 운영 (proof of concept)
- 인맥 네트워크에서 호스트 모집 (개인 호스트 P-2 페르소나)
- 목표: minglit 위에서 이벤트 운영 흐름 검증, 실제 사용자 피드백

**왜 이 방식?**: bootstrapped + AI-first 사업 구조 → 큰 sales 팀 X. Founder-led GTM이 가장 신뢰도 ↑ + 비용 ↓.

### Phase 2 — Convert (10-50 Partner)
기존 오프라인 업체 영업 (B2B):
- 감정적인 오렌지들 / 토크블라썸 등 [research/competitive-landscape.md](../research/competitive-landscape.md) 1차 흡수 대상
- 인센티브: 수수료 N개월 면제 + minglit이 기존 채널보다 효율적이라는 증명
- 1:1 미팅 + 데이터 (Phase 1에서 검증된 운영 효율성)

### Phase 3 — Scale (50+ Partner)
- AI 워커 자동 outreach (LinkedIn/Instagram/카카오톡 채널 자동 컨택 봇)
- 사용자 측 마케팅 본격 시작 (지금까진 파트너의 사용자 = minglit 사용자)
- 인플루언서 / 광고 채널 검토

## 5. Milestones

| 시점 | Milestone | KPI |
|------|---------|-----|
| 2025-12 | 개발 시작 | — |
| 2026-04 | docs/background 정비, AI-first 인프라 완성 | minglit-worker-runtime 운영 |
| 2026-07 | **MVP 런칭** | 첫 Partner 1+, 첫 사용자 100+ |
| 2026-09 | Phase 1 완료 | Partner 10, 사용자 500 |
| 2026-12 | Phase 2 시작 | Partner 30, GMV 1억/월, Net 1,000만/월 |
| 2027-06 | Phase 3 진입 | Partner 100+, GMV 8억/월, Net 8,000만/월 |
| 2028 | Profitability + 결정사 시장 진입 검토 | `<TODO>` |
| 2030 | 5-year goal: 200만 회원, 시장 1위 | — |

`<TODO: Mark 마일스톤 별 KPI 더 구체화 — 이건 운영 데이터 쌓이면 조정>`

## 6. 핵심 메트릭 (KPI)

### Partner 측
- 활성 Partner 수 (월간 1+ 이벤트 운영)
- Partner 평균 이벤트 빈도 (월)
- Partner 평균 GMV
- Partner retention (3/6/12 개월)
- Partner Verified 전환율 (정산 인증 완료 비율)

### User 측
- 가입 → 첫 신청 전환율
- 활성 User (월간 1+ 이벤트 신청)
- 매칭 성공률 (mutual interest 발생률)
- 이벤트 만족도 (사후 리뷰 — 향후 추가)
- Repeat 참여율 (1회 → 2회 전환율)

### 플랫폼
- GMV (월)
- Net Revenue (월)
- Take rate (실제 — 무료 이벤트 비중에 따라 변동)
- Burn rate
- Runway

## 7. Risk + Mitigation

| Risk | 가능성 | 영향 | Mitigation |
|------|------|------|------------|
| 법적 미신고로 영업정지 (위치기반서비스/통신판매업) | 중 | 매우 큼 | **변호사 자문 즉시 → 신고 절차 우선순위** ([legal-context.md](./legal-context.md)) |
| AI 도구 비용 폭증 (OpenAI 가격 인상 등) | 낮음 | 중 | 어댑터 패턴으로 swap 가능 ([external-services.md](./external-services.md)) |
| Partner 모집 실패 (Phase 1) | 중 | 큼 | Founder-led 운영으로 직접 검증 + 인맥 동원 |
| 사용자 신뢰 부족 (검증 부재) | 중 | 큼 | Identity Verification 의무 + Verified Partner badge |
| 결제 사고 (먹튀, chargeback) | 낮음 | 중 | Escrow 모델 (체크인 게이트), Identity Verification |
| Burn 폭증 (법인운영비 + 마케팅) | 중 | 중 | 마케팅은 Phase 3까지 0, AI-first로 인건비 0 유지 |

## 8. 의사결정 트리거

다음 시점에 plan 재평가:
- **Partner 10명 도달**: GTM 효과 검증, Phase 2 진입 결정
- **GMV 5,000만원/월 돌파**: 외부 투자 검토 시점 (선택적)
- **Burn 100만원/월 초과**: 비용 구조 점검
- **법적 의무 미이행 발견**: 즉시 외부 자문 + 일정 조정
- **AI 도구 비용 5배 이상 증가**: vendor 재선정 검토

## 9. 펀딩 전략

### 현재 입장: 외부 펀딩 받지 않음
- **Bootstrapped + Mark 외부 수입 cover** = 자본 충분
- 자기자본 + 매출 (Phase 2부터) 만으로 운영 가능 가설
- 외부 자본 도입 의사 X (현재)

### 외부 투자 검토 트리거 (예외 조건)
다음 중 하나 발생 시만 재검토:
- **Burn 폭증**: AI 도구 비용 5배+, 마케팅 비용 ↑↑ — 자기 cover 한계 초과 시
- **공격적 시장 진입 결정**: 경쟁사 시장 진입 임박 → 1년 내 시장 점유율 확보 필요 시
- **Partner outbound sales 팀 필요**: AI 워커로 안 풀리는 영역 (예: 대형 사업자 영업)

### Bootstrapped 유지 시 우위
- **결정권 보존**: 투자자 보드 압박 X
- **천천히 검증**: 사용자 trust 우선, 단기 매출 KPI 압박 X
- **AI-first 효율**: 적은 burn → 자본 사용 효율 ↑
- **mission alignment**: founder-led vision 유지

## 10. Internal Only — 미공개 결정

`<TODO: Mark이 별도로 보존하고 싶은 결정 사항. 자기자본 액수, 개인적 목표, 외부 자문 노트 등>`

- ✅ **Mark 외부 수입 source**: 현재 cover 가능 (구체 액수는 internal only, 별도 노트)
- `<TODO: 외부 수입 source 변동 시 plan 업데이트>`

---

> 이 문서는 **internal-only**. 외부 공유 X. 외부 투자자 deck은 별도 작성 (이 문서 일부 발췌).
