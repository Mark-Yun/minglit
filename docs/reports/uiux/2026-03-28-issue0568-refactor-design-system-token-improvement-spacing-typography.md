---
source_url: https://github.com/Mark-Yun/minglit/issues/568
captured_at: 2026-03-28
issue_number: 568
state: closed
labels: [refactor, P1-high, report-exec]
author: Mark-Yun
title: "refactor: 디자인 시스템 토큰 값 개선 (spacing, typography, radius)"
---

# refactor: 디자인 시스템 토큰 값 개선 (spacing, typography, radius)

> Issue #568 · closed · created 2026-03-28T03:16:40Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/568

## Body

## 배경

파트너앱/유저앱 모두 "눈에 잘 안 들어온다, 여백 부족, 글자가 작다"는 피드백.
토스 앱 비교 분석 결과, 밍릿 디자인 토큰이 업계 평균 대비 30~50% 좁고, line-height 미지정으로 텍스트가 답답하게 보임.

## 변경 사항

### 1. Spacing 토큰 (minglit_design_tokens.dart)

| 토큰 | 현재 | 변경 | 근거 |
|------|------|------|------|
| 화면 좌우 패딩 | 16px (medium) | **screenEdge = 20** 시맨틱 토큰 추가 | 토스 20dp 표준 |
| 카드 간 간격 | 8px (small) | **cardGap = 12** 시맨틱 토큰 추가 | 토스 12~16dp |
| 카드 내부 패딩 | 8px (small) | **cardContentV = 16** 시맨틱 토큰 추가 | 토스 16~20dp |
| 제목-부제 간격 | 2px (xxsmall) | **titleToBody = 4** 시맨틱 토큰 추가 | 4pt grid |
| 섹션 간 간격 | 없음 | **sectionGap = 40** 시맨틱 토큰 추가 | 토스 40dp+ |
| xxxlarge | 없음 | **xxxlarge = 64** 추가 | 대형 섹션 구분 |

### 2. Typography (minglit_theme.dart)

| 항목 | 현재 | 변경 |
|------|------|------|
| line-height | 미지정 (기본 ~1.2) | **모든 TextStyle에 height 추가** |
| bodySmall | 12px | **13px** |
| bodyLarge | 미정의 | **18px 추가** |
| headlineSmall | 미정의 | **24px bold 추가** |

line-height 매핑 (4pt grid 기반):
| fontSize | height 값 | 실제 px |
|----------|-----------|---------|
| 11px | 1.45 | 16px |
| 12~13px | 1.5 | 18~20px |
| 14px | 1.43 | 20px |
| 16px | 1.5 | 24px |
| 18px | 1.33 | 24px |
| 20px | 1.4 | 28px |
| 32px | 1.25 | 40px |

### 3. Border Radius (minglit_design_tokens.dart)

| 토큰 | 현재 | 변경 | 근거 |
|------|------|------|------|
| card | 24px | **16px** | 토스 12~16dp, 전문적 인상 |
| button | 16px | **12px** | 토스 8~12dp |

### 4. 섹션 디바이더 위젯 (신규)

`MinglitSectionDivider` 위젯 추가:
- thick: 높이 8px, 색상 surface
- thin: 높이 1px, 색상 divider

### 5. 디자인 시스템 문서 보강

| 문서 | 추가 섹션 |
|------|----------|
| `01-foundation.md` | Opacity 토큰, Partner Colors, line-height 가이드 |
| `03-patterns.md` | Screen Layout, Card Layout, Section Divider, Information Hierarchy, Content Density |

## 영향 범위

- **골든 테스트 전부 깨짐** — `--update-goldens`로 재생성 필요
- 앱 전체 UI에 cascading effect — spacing/radius 변경으로 레이아웃 달라짐
- 기존 하드코딩된 spacing 값들과의 불일치 발생 가능

## 검증 방법
- `flutter analyze` 통과
- 골든 이미지 재생성 후 시각적 비교
- 주요 화면 스크린샷 before/after 대조
