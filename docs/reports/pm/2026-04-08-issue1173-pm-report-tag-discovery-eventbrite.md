---
source_url: https://github.com/Mark-Yun/minglit/issues/1173
captured_at: 2026-04-08
issue_number: 1173
state: closed
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Report — 2026-04-08: Tag Discovery 급진전 + Eventbrite 인수 후폭풍 + 과징금 상향 임박"
---

# 📊 PM Report — 2026-04-08: Tag Discovery 급진전 + Eventbrite 인수 후폭풍 + 과징금 상향 임박

> Issue #1173 · closed · created 2026-04-08T08:05:41Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1173

## Body

Scheduler: pm-exec-report-claude-subagents

## Summary

어제 P0으로 경고했던 Tag Discovery가 24시간 만에 Phase 1 MVP 머지 완료. Feature Maturity 매트릭스를 대폭 교정한다.
시장 측면에서 Bending Spoons의 Eventbrite 인수 완료(5억달러)로 글로벌 이벤트 플랫폼 시장 재편 중이며,
한국 다크패턴 과징금 상향 개정안이 2026 상반기 발의 예정이라 규제 긴급도를 유지한다.

### 핵심 변경 3가지

1. **Tag Discovery 0% → 75%**: Phase 1 MVP 머지(#1149), 민감 키워드 필터(#1167), 테스트 계획 162건(#1138) 완료. User 앱 UI만 남음.
2. **Eventbrite 인수 + "Reset to Real"**: Bending Spoons가 Eventbrite+Meetup 동시 보유. 18-35세 79%가 더 많은 이벤트 참석 계획 — 태그 기반 큐레이션 전략 검증.
3. **다크패턴 과징금 상향 임박**: 현행 최대 500만원 → 매출액 기반 과징금 전환 검토 중. 취소/탈퇴 방해가 최다 단속 유형(15건).

---

## Feature Maturity Matrix (코드 기반 교정)

| Feature | 이전(#1133) | 교정 | 변화 | BE | Flutter | 리스크 |
|---------|------------|------|------|-----|---------|--------|
| Tag Discovery | 0% | **75%** | ⬆️+75 | ✅ DB+API+Filter | Partner ✅ / User ❌ | 🟡 User UI 잔여 |
| Account Deletion | 60% | **95%** | ⬆️+35 | ✅ | ✅ Both apps | 🟢 RLS 폴리시 |
| Signup Consent | 미포함 | **90%** | NEW | ✅ | ✅ + Tests | 🟢 |
| My Tickets | 80% | **80%** | → | - | ✅ + Tests | 🟢 |
| Partner Dashboard | 70% | **70%** | → | - | ✅ | 🟢 |
| Recurring Events | 65% | **60%** | ⬇️-5 | ✅ DB | ⚠️ EF 워크트리 | 🟡 메인 머지 필요 |
| Refund Policy V2 | 40% | **20%** | ⬇️-20 | ❌ 최소 | ❌ 워크트리 | 🔴 크게 뒤처짐 |
| Trust Badge | 미포함 | **5%** | NEW | ❌ | ❌ | 🔴 스펙만 존재 |

### 교정 근거

- **Tag Discovery**: 어제 #1133 작성 시점에는 0%였으나, 같은 날 Phase 1 MVP(#1149)와 키워드 필터(#1167)가 연달아 머지. DB 스키마, PGroonga 검색, RPC, 시드 데이터, Partner 앱 UI + 테스트 모두 완료.
- **Account Deletion**: 어제 리포트에서 60%로 잡았으나 실제로는 양 앱 모두 전체 플로우 구현 완료. 95%로 상향.
- **Refund Policy V2**: 어제 40%로 잡았으나 실제 메인 브랜치에는 최소 마이그레이션만 존재. 대부분 워크트리 드래프트. 20%로 하향.
- **Trust Badge**: 스펙과 UX 문서(#1145, #1139)는 머지됐으나 코드 구현 제로.

---

## 24시간 진척 요약

어제(4/7) 하루 동안 **22개 PR 머지** — 프로젝트 역대 최고 일일 처리량.

| 카테고리 | PR 수 | 주요 항목 |
|---------|-------|----------|
| Tag Discovery | 3 | Phase 1 MVP, 민감 키워드 필터, 테스트 계획 |
| Legal/Privacy | 6 | 동의 아카이브, PIPA 강조, 개인정보처리방침 통일, 환불 정책 일치, 태그 통계 정책, 유출 대응 |
| Trust Badge | 2 | UX 설계 + 와이어프레임 |
| CI/Infra | 5 | DNS fallback, actions bump, 에뮬레이터 스크립트, IPv4 override, CUJ env |
| 기타 | 6 | 정책 문서, 버전 범프 등 |

---

## 시장 업데이트

### 당근모임 — 브랜드 콜라보 실험 본격화

- 4/7 을지로 야시장에서 Heinz 케첩 테마 모임 개최 (100명 선발). 브랜디드 오프라인 이벤트를 성장 수단으로 활용.
- 전사 매출 2,707억원 (YoY +43%), 최초 흑자. 모임은 체류시간 플라이휠 역할.
- **밍글릿 시사점**: 당근은 여전히 티켓팅/정산/파트너 툴 부재. B2B 레이어 차별화 유효.

### Eventbrite — Bending Spoons 인수 완료 (5억달러)

- 2025.12 인수 완료. IPO 시총 대비 70% 할인. Meetup도 2024.01 인수해 글로벌 이벤트 플랫폼 2개 동시 보유.
- **"Reset to Real" 리포트 핵심**:
  - 18-35세 **79%**가 2026년 더 많은 이벤트 참석 계획
  - **58%**가 "사교 자체가 메인이 아닌" 이벤트 선호 (저압력 연결)
  - **52%**가 언더레이더 이벤트 선호, 69%가 입소문으로 발견
  - 독특한 장소면 지출 44% 증가 의향
- **밍글릿 시사점**: 태그 기반 이벤트 큐레이션과 "저압력 연결" 니즈 — 우리 전략과 정확히 일치.

### Partiful — GPS 메타데이터 이슈

- MAU 500K, YoY +400%. 2025.10 사진 업로드 시 GPS 미제거 취약점 (TechCrunch).
- **밍글릿 시사점**: 이미지 업로드 시 EXIF 메타데이터 제거 여부 점검 필요.

---

## 규제 업데이트

### 다크패턴 — 과징금 상향 개정안 임박 ⚠️

- **현행**: 3회 이상 위반 시 최대 500만원 과태료
- **개정안 (2026 상반기 발의 예정)**: 매출액 기반 과징금 전환 검토
- 2025년 공정위 모니터링: 45건 중 **취소/탈퇴 방해 15건 최다**
- **밍글릿 해당**: Account Deletion 95%로 양호. Refund 20%는 리스크.

### 개인정보보호법 — 접속기록 확대 (2026.10.31 시행)

- 접속기록 보관 범위 확대 + 내부관리계획 개편. 출시 후 3개월 시점에 해당.

---

## 판단 요청 사항

### 1. Refund Policy V2 우선순위 판단 (P0 권고)

- 현재 20%로 크게 뒤처짐. 워크트리에 드래프트만 존재.
- 다크패턴 과징금 상향 개정안이 상반기 발의 예정이므로, 7월 출시 시 환불 플로우 미비는 법적 리스크.
- **권고**: Refund Policy V2를 P0으로 상향하고 SWE 리소스 우선 배정.

### 2. Trust Badge 출시 범위 조정

- 현재 5% (스펙만). 7월 출시까지 풀 구현은 현실적으로 어려움.
- **권고**: V1은 DB + 기본 배지 표시만. 고급 기능(Elite 배지, 상세 시트)은 출시 후.

### 3. EXIF 메타데이터 점검

- Partiful 사례(TechCrunch 보도)를 참고해 이미지 업로드 시 GPS 메타데이터 제거 여부 확인 필요.
- **권고**: `needs-security` 이슈 생성.

---

## 이전 액션 아이템 추적

| 이전(#1133) 액션 | 상태 |
|-----------------|------|
| Tag Discovery 파이프라인 가동 | ✅ Phase 1 MVP 머지 완료 |
| `needs-legal` 다크패턴 감사 | 🔄 법적 문서 6건 머지, 감사 자체는 미실시 |
| Signup Consent PIPA 재점검 | ✅ PIPA 강조 표시 의무 적용 (#1147) |
| Recurring Events User UI | 🔄 진행 중 |
| Trust Badge UI 기획 | ✅ UX 설계 + 와이어프레임 머지 (#1145, #1139) |

---

## 액션 아이템

| # | 긴급도 | 액션 | 상태 |
|---|--------|------|------|
| 1 | 🔴 P0 | Refund Policy V2 파이프라인 재가동 — 워크트리 코드 정리 + 구현 본격화 | 신규 |
| 2 | 🔴 P0 | `needs-legal`: 다크패턴 감사 (환불/결제 플로우) — 과징금 상향 전 완료 필수 | 유지 |
| 3 | 🟡 P1 | Tag Discovery User 앱 UI 구현 | 유지 |
| 4 | 🟡 P1 | Recurring Events 워크트리 코드 → 메인 머지 | 유지 |
| 5 | 🟡 P1 | 이미지 업로드 EXIF 메타데이터 제거 점검 → `needs-security` | 신규 |
| 6 | 🟢 P2 | Trust Badge V1 (최소 범위) 구현 시작 → `needs-arch` | 유지 |
| 7 | 🟢 P2 | 개인정보보호법 접속기록 확대 대응 준비 (2026.10.31) | 신규 |

---

*Previous report: #1133 (2026-04-07)*
*Open P1 bug: #1152 (party_tags 교체 로직)*
*Sources: 디지털데일리, VentureSquare, BusinessWire, Skift, TechCrunch, AInvest, 법률신문, 신김*

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-10

종합 리포트에서 내용 확인 완료.

**처리 결과**:
- Feature Maturity 수치(Refund V2 20%, Recurring Events 60%, Tag Discovery 75%)는 #1193에서 코드 전수조사로 재교정됨 (각각 90%, 90%, 95%)
- 시장 인사이트 (Eventbrite Reset to Real, 당근 Heinz 콜라보)는 기록 목적
- **EXIF 메타데이터 제거 점검은 별도 이슈로 생성** (코드베이스 grep 결과 EXIF 관련 로직 0건 — 실제 취약점 가능성 확인 필요)

#1193으로 최신 상태 유지 중.
