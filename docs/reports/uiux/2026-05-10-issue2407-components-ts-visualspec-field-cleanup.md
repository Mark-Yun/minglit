---
source_url: https://github.com/Mark-Yun/minglit/issues/2407
captured_at: 2026-05-10
issue_number: 2407
state: open
labels: [enhancement]
author: Mark-Yun
title: "[audit-uiux/개선] components.ts visualSpec 필드 — MinglitButton 1개만 사용 → legacy HTML spec 정리 필요"
---

# [audit-uiux/개선] components.ts visualSpec 필드 — MinglitButton 1개만 사용 → legacy HTML spec 정리 필요

> Issue #2407 · open · created 2026-05-10 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/2407

## Body

Scheduler: needs-uiux-claude-1

## 발견 위치

- `apps/mds/docs/src/lib/components.ts:213` — `MinglitButton` 컴포넌트만 `visualSpec: '/specs/components/minglit_button.html'` 필드를 갖고 있다
- `apps/mds/docs/public/specs/components/minglit_button.html` (354줄) — `public/specs/components/` 디렉토리에 존재하는 **유일한** 정적 HTML 컴포넌트 spec page
- `apps/mds/docs/src/components/specs/MinglitButtonSpec.tsx` (302줄) — 동일 컴포넌트의 React inline spec이 이미 별도로 존재

## 현재 / 권장

**현재 — 단일 컴포넌트만 이중 spec 보유**

- `MDS_COMPONENTS` 매니페스트의 30개 컴포넌트 중 단 1개(`MinglitButton`)만 `visualSpec` 필드 사용
- 나머지 29개 컴포넌트는 모두 React inline spec(`src/components/specs/<Name>Spec.tsx`)만 보유 — 일관된 패턴
- `MinglitButton`은 정적 HTML spec(354줄) + React inline spec(302줄)을 **동시에** 보유 → 단일 진실(SSOT) 원칙 위반
- 두 spec의 커버리지를 비교하면 거의 동일 (4 variants × 3 sizes × loading/disabled/icon 케이스 모두 양쪽에 중복 기재)
- `components.ts:107-112`의 `visualSpec` typedef 주석: *"Optional — not all components need a visual spec yet"* — 1년 가까이 사용자 1명만 유지된 "yet"
- `src/components/specs/README.md` 및 `components.ts` 매니페스트 헤더 주석에 안내된 컴포넌트 추가 워크플로우는 `.tsx` 인라인 스펙만 언급 — HTML spec 작성 단계는 없음 → React 인라인 스펙이 사실상 표준

**권장 — 옵션 A 강하게 추천**

| 옵션 | 작업 | 권장도 |
|------|------|--------|
| **A. legacy HTML 제거** | `public/specs/components/minglit_button.html` 삭제 + `components.ts:213` `visualSpec` 라인 제거 + `ComponentSpec` typedef에서 `visualSpec` 필드 제거 (사용처가 없어지므로) + 누락된 시각 케이스가 있다면 `MinglitButtonSpec.tsx`에 보강 | ★★★ |
| B. 모든 컴포넌트 HTML spec 확장 | 29개 컴포넌트 각각 HTML spec 신규 작성 | ★ (React inline spec과 중복, 유지비 큼) |

옵션 A의 경우, 작업 분량 추정:
- 삭제: HTML 1개 파일 + `visualSpec` 라인 1줄 + typedef 5줄
- React inline spec(`MinglitButtonSpec.tsx`)에 HTML 대비 누락된 시각 케이스가 있는지 1회 확인 (우리가 본 범위에선 거의 동일)

## reference

- `apps/mds/docs/src/lib/components.ts:107-112` — `visualSpec` typedef ("Optional ... yet")
- `apps/mds/docs/src/lib/components.ts:151-220` — `MDS_COMPONENTS[0]` MinglitButton 항목 (유일한 `visualSpec` 사용처)
- `apps/mds/docs/src/components/specs/README.md` — 컴포넌트 추가 워크플로우 (HTML 단계 없음)
- 일관성 baseline: 나머지 29개 컴포넌트는 `.tsx` inline spec only

## 카테고리

[audit-uiux/개선] — 디자인 시스템 spec **자체**의 인터널 컨플릭/일관성. spec 변경(파일 삭제)이 필요하므로 Mark 영역.

