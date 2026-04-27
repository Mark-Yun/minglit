---
source_url: https://github.com/Mark-Yun/minglit/issues/1774
captured_at: 2026-04-23
issue_number: 1774
state: open
labels: [report-exec]
author: Mark-Yun
title: "📊 PM Report — 2026-04-23: 법률 컴플라이언스 완성 + CUJ QA 결실 + 실행 공백 2주차"
---

# 📊 PM Report — 2026-04-23: 법률 컴플라이언스 완성 + CUJ QA 결실 + 실행 공백 2주차

> Issue #1774 · open · created 2026-04-23T08:06:52Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1774

## Body

Scheduler: pm-exec-report-claude-subagents

# PM Report — 2026-04-23: 법률 컴플라이언스 완성 + CUJ QA 결실 + 실행 공백 2주차

## Summary

지난 리포트(#1659, 3일 전) 이후 **~73건 PR 머지** — 역대 최고 속도 재갱신. 핵심 3가지: (1) **법률/컴플라이언스 retention 파이프라인 완성** — F1~F8 + admin 스키마 + RPC 화이트리스트 + 탈퇴 파기 pgTAP 증명까지 단일 사이클에 완료, 출시 전 법적 리스크가 구조적으로 해소됨. (2) **CUJ QA 파이프라인이 실제 기능 안정화**를 견인 — 파트너 위저드 회귀(#1741/1742/1743), QR 티켓(#1653), 네비게이션(#1630), 이미지 로딩(#1745) 등 발견→수정 사이클이 하루 안에 돌아감. (3) **피처 스펙 승인 후 실행 공백이 2주차로 지속** — 참여 현황(#1465)과 Admin 대시보드(#1462)는 여전히 후속 `needs-swe` 이슈 없음. Trust Badge는 **6주 연속** 5%.

## 핵심 변화 3가지

1. **법률 컴플라이언스 완성 (F1~F8)**: 전자상거래법 §6, PIPA §21, 위치정보법 §16, 통신비밀보호법까지 retention_policies 테이블 + admin RPC + pgTAP 증명 3층 구조로 완성. `docs/legal/retention-map.md` 매핑 문서도 함께 머지.
2. **CUJ QA 고속 사이클 정착**: Runtime QA 자동 발견 → 같은 날 수정 PR 머지 패턴이 파트너 CUJ-P02~P05에서 3건 반복 성공(#1741, #1742, #1743 → #1770, #1771, #1772).
3. **인프라 환경변수 미싱 퍼즐 대부분 해소**: #1575 PortOne secrets(#1684), TICKET_SIGNING_KEY env-manifest 등록(#1669), #1653 QR signing(#1671+#1676), pg_cron EF 401(#1761). **My Tickets 기능 불능 리스크 실질 해소**.

---

## 이전 액션 아이템 추적 (#1659)

| 이전 액션 | 상태 | 비고 |
|----------|------|------|
| #1653 Ticket QR signing key — needs-swe 긴급 | ✅ 완료 | #1669 env-manifest + #1671 INV-01 + #1676 RLS — 3-layer 해소 |
| #1575, #1606 인프라 환경변수 확정 | ✅ 완료 | #1684 supabase-deploy auto-inject |
| **참여 현황 재설계 구현 이슈 생성**(#1465 후속) | ❌ **미착수 2주차** | PM 자기 미션 미이행 |
| **Admin 대시보드 구현 이슈 생성**(#1462 후속) | ❌ **미착수 2주차** | 단, admin 스키마 infra(#1693)는 별도 경로로 완료 |
| Trust Badge MVP 스코프 최종 권고 | ❌ **6주 연속 미결** | — |
| #1630 Navigation 회귀 수정 | ✅ 완료 | #1727 merged |
| Apple Developer 계약 갱신 | ✅ 완료 | iOS Deploy #1509 closed |
| "사전 매칭" 포지셔닝 문서화 | ❌ **6회 이월** | `docs/features/positioning/` 없음 |
| 이벤트 수정/취소 SWE 구현(#1338) | 🔄 | #1338 open 유지, 아직 구현 PR 없음 |
| fromJson 타입 안전성 needs-arch 이슈 | ❌ 미착수 | — |
| 이미지 EXIF 메타데이터 스트립핑 | ❌ 미확인 | — |
| Runtime QA 발견/수정 balance 모니터링 | ✅ 결과 시현 | 같은 날 수정 사이클 동작 확인 |

**총평**: 12건 중 4건 완료, 1건 진행, 7건 미착수. **인프라/버그 항목은 완벽 처리(100%)**, **PM 자체 미션(기획→이슈 생성, 포지셔닝 문서, Trust Badge 결정 재권고)은 또다시 전부 미이행**. 이 패턴은 이번 사이클에서 반드시 깨야 한다.

---

## Feature Maturity Matrix

| Feature | #1659 | 현재 | 변화 | 근거 |
|---------|-------|------|------|------|
| Account Deletion | 97% | **98%** | ⬆️+1 | PIPA §21 탈퇴 즉시 파기 pgTAP 증명(#1728) |
| Tag Discovery | 96% | **96%** | → | |
| Signup Consent | 95% | **95%** | → | |
| Refund Policy V2 | 92% | **92%** | → | |
| Recurring Events | 93% | **93%** | → | |
| My Tickets | 90% | **95%** | ⬆️+5 | QR signing key 파이프라인 실환경 가동(#1669), 무료 티켓 예매 취소 수정(#1654), INV-01 승인 상태 수정(#1671) |
| Partner Dashboard | 79% | **85%** | ⬆️+6 | 파티 생성(#1680→#1724), 이번주 성과 null(#1611→#1642), 수정 위저드 회귀 3건 해소(#1770/1771/1772) |
| Event Edit/Cancel | 50% | **52%** | ⬆️+2 | #1338 미착수 / 수정 위저드 UX 개선(#1771) |
| Participation Status | 20% | **20%** | → | 🟡 스펙 승인 2주차, 여전히 SWE 이슈 미생성 |
| Admin Dashboard | 15% | **25%** | ⬆️+10 | admin 스키마·retention_policies infra(#1693) 완료 — UI는 미착수 |
| Trust Badge | 5% | **5%** | → | **6주 연속 미착수** |

**Legal/Privacy Compliance** (신규 추가): **100%** — F1~F8 완료, retention-map.md 매핑 문서 머지

**전체**: MVP 핵심 피처 8개 중 **6개 90%+**. Compliance 100% 도달. Trust Badge만이 유일한 결정 리스크.

---

## 법률 컴플라이언스 완성 — 이번 기간 최대 성과

출시 전 법률 리스크를 구조적으로 제거한 단일 사이클:

| 영역 | 법률 | 구현 PR |
|------|------|--------|
| 결제 레코드 5년 보호 | 전자상거래법 §6 | #1725 |
| 이벤트 참여자 30일 파기 | PIPA §21 | #1729 |
| 자격 인증 증빙 1년 보관 | PIPA/업계표준 | #1731 |
| 부정 이용 기록 1년 보관 | 업계표준 | #1730 |
| 탈퇴 즉시 파기 증명 | PIPA §21 | #1728 (pgTAP) |
| 위치 확인자료 6개월 보관 | 위치정보법 §16 | #1698 |
| GPS 미저장 증명 | 위치정보법 §16 | #1728 |
| archived_records 자동 파기 | 전자상거래법 §6 | #1726 (+ delete_expired_rows RPC) |
| 선언↔구현 매핑 문서화 | — | #1696 (retention-map.md) |
| admin 스키마 + retention_policies | infra | #1693 |
| admin retention RPC 테이블 화이트리스트 | security | #1754 |

**PM 시각**: 이 구조는 **출시 실사 통과에 결정적**. 7월 런칭 시 법무 검토에서 지적받을 핵심 영역이 pgTAP 테스트로 자동 증명된다. Security Audit(#1744)도 같은 사이클에서 발견·해소됨 — 자가 점검 능력이 성숙했다는 신호.

---

## CUJ QA 파이프라인 — 발견→수정 24h 사이클 정착

지난 리포트에서 "발견 속도와 수정 속도 balance"를 리스크로 지목했으나, 이번 기간 파트너 CUJ에서 **같은 날 발견→수정→머지가 3건 성공**:

| QA 발견 | 수정 PR | 소요 |
|---------|---------|------|
| #1743 파티 수정 위저드 Step4/Step5 로드 실패 | #1770/#1772 | 당일 |
| #1742 신청관리/체크인 이벤트명 빈 문자열 | #1770 | 당일 |
| #1741 티켓 수정 Ref disposed 오류 | #1771 | 당일 |
| #1739/#1740 DB 컬럼 불일치 | #1770 | 당일 |
| #1755 run-partner-cuj.sh exit 1 (30일 지속) | #1769 | 당일 |
| #1746 스플래시 로고 노출 | #1753 | 당일 |
| #1757 이벤트 상세 빈 상태 UX | #1767 | 당일 |

**PM 시각**: Partner 앱 안정화 속도가 비약적으로 상승. Partner Dashboard 85%로 점프한 주 요인.

**유일한 예외**: #1745 (홈 화면 카드 이미지 깨짐) — 4/23 발견, 아직 미수정. 시드 데이터 품질 문제(#1637 패턴 재발) 가능성 있음, 추적 필요.

---

## 두 개의 새 Hard Block

### 1. #1713 — Flutter SDK 미설치 (Runtime QA 모드 B 차단)

- runtime-qa-gemini 워커가 Flutter SDK 없어 정기 스모크 테스트 수행 불가
- 2026-04-23 기준 user + partner 양쪽 runtime-qa 모드 B 전면 차단 2일차
- `report-exec` 라벨, Mark 판단 대기 (옵션 A/B/C 제안됨)

**PM 영향 평가**: 정기 스모크가 돌지 않으면 **CUJ QA 파이프라인 커버리지가 최신 빌드를 놓침**. 이번 주 성과인 "발견→수정 24h" 사이클의 선행 조건이 사라지는 상황. 옵션 A(SDK 설치) 우선 판단 요청.

### 2. #1768 — review-presence required check 구조적 결함 재발

- approved PR이 `mergeStateStatus: BLOCKED`로 평균 수 시간 대기
- 현재 4시간+ 체류 PR(#1767, #1764, #1766) 발견
- #904(03-30) 이후 재발 — 즉, 구조적 문제가 30일째 미해결

**PM 영향 평가**: 머지 속도 저하는 **스펙→구현 파이프라인 전체 속도를 갉아먹음**. TPM이 옵션 B(근본 수정) 추천 — Mark 판단 대기.

---

## 운영 현황

| 지표 | 현재 | #1659 | 변화 |
|------|------|-------|------|
| 열린 이슈 | **4건** | 33건 | ⬇️-29 (역대 최저) |
| 열린 PR | **4건** | 27건 | ⬇️-23 (역대 최저) |
| P0 open | 0건 | 4건 | ✅ 완전 해소 |
| P1 open | 1건 (#1713) | 5건 | ⬇️-4 |
| 보안 PR 리뷰 대기 | 0건 | 0건 | → |
| 3일 머지 PR | **~73건** | — | 🏆 역대 최고 속도 |
| 3일 종료 이슈 | ~64건 | — | |
| report-runtime-qa 신규 | ~8건 | 15건+ | ⬇️ 안정화 신호 |

**이 수치는 과거 어느 리포트보다 깨끗한 상태**. 실질적으로 출시 차단 리스크가 없는 시점에 가까움.

### 열린 이슈 4건 (전부)
- #1338 (event-edit 통합 테스트, P2) — SWE 대기
- #1659 (지난 PM 리포트) — 이번 리포트로 교체 예정
- #1713 (Flutter SDK, P1 hard block) — Mark 판단
- #1768 (review-presence, TPM 리포트) — Mark 판단

### 열린 PR 4건
- #1582 (stale 테스트 인프라 정리) — CHANGES_REQUESTED
- #1626/#1627/#1628 (dependabot 번들) — #1626/#1627은 CHANGES_REQUESTED

---

## 신규 시장 동향 (3일 델타)

지난 리포트 이후 소셜/이벤트 매칭 시장에서 밍글릿 포지셔닝에 영향을 주는 변화는 제한적(리포트 간격 3일). 누적 관점 유지:

- **Timeleft Seoul 주간 디너 운영 중** → 포지셔닝 문서화 긴급도 지속
- **Synchrony(2026-03 런칭) "2단계 신원인증" 기본 탑재** → Trust Badge 업계 baseline 증거 유지
- **TechCrunch "외로움 경제" 섹터 형성** → 밍글릿 정렬 OK, 차별화 메시지 필요
- **Airbnb × Timeleft 공동 브랜딩 파일럿** → 밍글릿 장기 B2B 파트너 모델 관찰 가치

3일 간격에서 새로운 뉴스 사이클 유입은 적으므로, 이 섹션은 다음 리포트(~04-27)에서 2차 자료 점검 후 업데이트 예정.

---

## 리스크 매트릭스

| 리스크 | 확률 | 영향 | 대응 상태 |
|--------|------|------|----------|
| **Flutter SDK runtime 부재(#1713)** | 확정 | 🟡 QA 커버리지 누락 2일차 | 📋 Mark 판단 대기 |
| **review-presence 머지 병목(#1768)** | 확정 | 🟡 개발 속도 저하 | 📋 Mark 판단 대기 |
| **스펙 승인 → 구현 공백 2주차** | 확정 | 🔴 7월 출시 일정 리스크 | ❌ PM 미이행 |
| **Trust Badge 6주 미결** | 높음 | 🟡 업계 baseline 이탈 | ❌ 6주 연속 |
| **포지셔닝 문서 부재** | 높음 | 🟡 런칭 차별화 부족 | ❌ 6회 이월 |
| **#1745 이미지 깨짐 / 시드 품질 재발** | 중간 | 🟡 홈 UX 첫인상 | 🔄 추적 |

### 해소된 리스크

- ✅ Ticket QR signing key 전면 해소 (#1653 + #1669 + #1671 + #1676)
- ✅ 인프라 환경변수 누락 (#1575, #1606, #1684)
- ✅ iOS Deploy 차단 해소 (#1509)
- ✅ Navigation 회귀 해소 (#1630)
- ✅ 법률 컴플라이언스 공백 완전 해소

---

## PM 판단: 7월 출시 전망

### 상향: 🟢 **출시 가능권 진입** — 잔여 리스크는 "제품 차별화/결정"으로 전환

**긍정 신호**:
1. **법률 컴플라이언스 구조적 완성** — 출시 실사 통과 기반 확보
2. **열린 이슈/PR 4건/4건으로 역대 최저** — 기술 debt가 아닌 전략 debt만 남음
3. **Partner Dashboard 85%** — 사업자 파이프라인 준비
4. **CUJ QA 24h 사이클 정착** — 품질 확보 속도 달성
5. **My Tickets 95%** — 핵심 결제→입장 파이프라인 안정

**리스크 신호 (구조적)**:
1. **PM 자체 액션 2주차 미이행**: 참여 현황/Admin 대시보드 구현 이슈 미생성, 포지셔닝 문서 6회 이월. 코드 레벨 리스크는 사라졌는데, **"기획→실행" 전환이 PM 병목**.
2. **Trust Badge 6주 미결**: 의사결정 부채가 업계 baseline을 잠식.
3. **두 개의 Mark 판단 대기(#1713, #1768)**: 운영 속도 추가 저하 위험.

---

## 액션 아이템

| # | 긴급도 | 액션 | 담당 | 상태 |
|---|--------|------|------|------|
| 1 | 🔴 PM **다음 사이클 최우선** | **참여 현황 재설계 구현 이슈 생성**(#1465 후속) — `ui-ux-design.md` 존재 → `needs-qa` 라벨로 테스트 계획 단계 진입 | PM | 미이행 2주차 |
| 2 | 🔴 PM **다음 사이클 최우선** | **Admin 대시보드 구현 이슈 생성**(#1462 후속) — `ui-ux-design.md` 없음 → `needs-uiux` 라벨로 디자인 가이드 단계 | PM | 미이행 2주차 |
| 3 | 🔴 Mark | #1713 Flutter SDK 옵션 A/B/C 결정 | Mark | report-exec 대기 |
| 4 | 🔴 Mark | #1768 review-presence 옵션 B 승인 | Mark | report-exec 대기 |
| 5 | 🔴 Mark | Trust Badge MVP 스코프 — 6주차 최종 권고 | Mark | report-exec 누적 |
| 6 | 🟡 PM | "사전 매칭" 포지셔닝 문서화 — 6회 이월 | PM | 이번 주 내 착수 |
| 7 | 🟡 P2 | 이벤트 수정/취소 SWE 구현(#1338) | SWE | needs-swe |
| 8 | 🟡 QA | #1745 홈 화면 카드 이미지 깨짐 — 시드 품질 점검 | QA | 추적 |
| 9 | 🟢 PM | fromJson 타입 안전성 needs-arch 이슈 생성 | PM | 🆕 |
| 10 | 🟢 보안 | 이미지 EXIF 메타데이터 스트립핑 확인 | needs-security | 🆕 |

---

## PM 자기 미션: 다음 `needs-pm` 사이클 최우선

지난 리포트에서 "다음 사이클에 직접 구현 이슈 생성"을 명시했으나 2주차로 이월됨. 이번 실행은 report-only 트리거(`pm-exec-report-claude-subagents`)이므로 생성까지 수행하지 않음. **다음 `needs-pm` 사이클 최우선 액션**:

1. `feat: 참여 현황 UI 재설계 구현` 이슈 — `docs/features/participation-status-redesign/ui-ux-design.md`, `wireframe.html` 링크 인용 → **`needs-qa`** 라벨 (UX 완료 상태, 테스트 계획 단계)
2. `feat: Admin 대시보드 UI 구현` 이슈 — infra는 #1693 기반, UI는 미설계 → **`needs-uiux`** 라벨 (디자인 가이드 선행)

→ **3주차 이월은 PM 책무 불이행**. 다음 `needs-pm` 트리거에서 반드시 실행.

---

## PM 제안: Trust Badge — 6주차 최종 권고 (누적)

동일 제안 6주째 반복. Synchrony(2026-03) 런칭 사례가 "2단계 신원인증 = 업계 표준"을 확정 지은 상태에서, 밍글릿이 6주간 결정하지 못했다는 것 자체가 프로세스 실패 시그널.

### 최종 권고 (변경 없음): MVP에 포함 (2-3일 구현)

1. 프로필 이미지 우하단 ✓ 배지
2. 이벤트 카드 호스트 이름 옆 배지
3. 참여자 blur 리스트 인증 배지 (참여 현황 wireframe에 이미 포함)

**PM 판단 유지**: 구현 비용 극소(1-2일 UI) + 업계 baseline 도달. 결정을 미루는 비용이 구현 비용을 초과했음.

→ report-exec 라벨로 **6주차 최종 판단 요청**.

---

## PM 제안: 포지셔닝 문서 — 6회 이월, 이번 주 반드시 착수

Timeleft Seoul 주간 디너가 지금 당장 운영 중. **밍글릿 출시 시 "그냥 또 하나의 만남 앱"으로 포지셔닝될 리스크 실재**.

**이번 주 커밋**: `docs/features/positioning/` 폴더 생성 + `vs-timeleft.md` 최소 초안 1편 작성. 나머지(`vs-dating-apps.md`, `vs-meetup.md`)는 다음 주.

---

*Previous report: #1659 (2026-04-20)*
*Methodology: GitHub 73 merged PRs 분석, 4 open issues/PRs 상태 점검, 법률 컴플라이언스 11건 PR 검증, CUJ QA 발견→수정 사이클 추적, Feature Maturity Matrix 재계산*

