---
source_url: https://github.com/Mark-Yun/minglit/issues/727
captured_at: 2026-03-29
issue_number: 727
state: closed
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-03-29: 중복 이슈 생성 패턴 발견 + 운영 현황"
---

# ⚠️ TPM Report — 2026-03-29: 중복 이슈 생성 패턴 발견 + 운영 현황

> Issue #727 · closed · created 2026-03-29T03:29:18Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/727

## Body

## 요약

TPM 정기 분석 결과, 구조적 문제 1건과 운영 현황을 보고합니다.

---

## 1. 🔴 중복 이슈 생성 패턴 (조치 완료 + 재발 방지 필요)

**현상**: 디자인 패턴 카탈로그 에픽+서브이슈가 2세트 생성됨
- Set 1 (03-28): #692-#701 (10건)
- Set 2 (03-29): #711-#718 (8건, 더 상세)

**조치**: Set 1 (#692-#701) 10건을 중복으로 닫음

**근본 원인 추정**: 이슈 파일링 워커가 기존 유사 이슈 존재 여부를 충분히 검증하지 않고 새 세트를 생성. `gh issue list --search` 검색이 제목 유사도만 비교하거나, 워커 실행 간 타이밍 이슈.

**재발 방지 제안** (사람 판단 필요):
- 이슈 파일링 전 `gh issue list --search "epic: {feature-name}"` 외에 서브이슈 키워드도 검색
- 또는 에픽 이슈 생성 시 `docs/features/{name}/.epic-filed` 마커 파일 생성으로 멱등성 확보

---

## 2. 📊 운영 현황 (2026-03-22 ~ 03-29)

### 이슈/PR 트렌드
| 지표 | 값 |
|------|-----|
| 이슈 생성 | ~100건 |
| PR 머지 | ~45건 |
| 기여자 | 100% AI worker (Mark-Yun) |
| needs-dev 백로그 | **30건** (P1: 15, P2: 14, P3: 1) |

needs-dev P1 구성:
- 내 티켓 (My Tickets): #637-#641 (5건)
- Event Now Bar: #658-#665 (8건, PR #719 진행 중)
- 디자인 카탈로그 리뉴얼: #619-#621 (3건, 단 P3 에픽 #711과 별개)

### CI/배포 안정성
| 워크플로우 | 성공률 | 비고 |
|-----------|--------|------|
| CI | 83% (5/6) | 정상 |
| iOS deploy | **0% (0/9)** | 3주째 연속 실패, #702 추적 중 |
| Backend Simulation | 실패 | #703, #705 추적 중 |
| 기타 (Format, Secret, Vercel) | 100% | 정상 |

### 정리 작업 완료
- 중복 이슈 10건 닫음 (#692-#701)
- 만료된 report-exec 1건 닫음 (#655, #721로 대체)

---

## 3. 판단 요청

1. **중복 이슈 재발 방지**: 위 제안 중 선호하는 방식이 있는지, 또는 현재 수준으로 충분한지
2. **needs-dev P1 실행 순서**: 내 티켓 vs Event Now Bar 중 어느 피처를 먼저 완료할지 (현재 Event Now Bar PR #719 진행 중)
3. **iOS deploy (#702)**: 3주째 100% 실패 — 수동 조치 or 워크플로우 비활성화 검토 필요

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-29

TPM이 자체 해결할 문제. 중복 방지는 프롬프트 v2에서 known-issues.json 메모리로 대응.
