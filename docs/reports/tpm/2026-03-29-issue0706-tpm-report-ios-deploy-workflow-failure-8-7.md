---
source_url: https://github.com/Mark-Yun/minglit/issues/706
captured_at: 2026-03-29
issue_number: 706
state: closed
labels: [report-exec]
author: Mark-Yun
title: "⚠️ TPM Report — 2026-03-29: iOS 배포 워크플로우 연속 실패 (8건/7일)"
---

# ⚠️ TPM Report — 2026-03-29: iOS 배포 워크플로우 연속 실패 (8건/7일)

> Issue #706 · closed · created 2026-03-29T00:48:36Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/706

## Body

## 상황

최근 7일간 `ios-deploy-reusable.yml` 워크플로우가 **8건 연속 실패**하고 있습니다.

## 분석

### 트리거
- `deploy-ios-user.yml` / `deploy-ios-partner.yml`이 **매일 cron (UTC 10:00, KST 19:00)**으로 default branch(dev)에서 실행
- push to main (경로 필터) 및 workflow_dispatch도 트리거 가능

### 실패 패턴
모든 실패가 2026-03-28에 집중. 커밋 내용과 무관하게 (docs, fix, merge 등) 일괄 실패 → **빌드 환경/시크릿 문제**로 판단.

| 날짜 | 커밋 | 결과 |
|------|------|------|
| 03-28 | docs: 디자인 패턴 카탈로그 테스트 계획 (#687) | failure |
| 03-28 | docs: architecture 감사 + design-pattern-catalog 기술 설계 (#684) | failure |
| 03-28 | fix(workers): SESSION_TIMEOUT unbound variable... | failure |
| 03-28 | (외 5건) | failure |

### 추정 원인 (수동 확인 필요)
1. **Apple 인증서 만료** — Distribution Certificate 또는 프로비저닝 프로파일
2. **GitHub Secrets 누락/만료** — `APPLE_CERTIFICATE_BASE64`, `APP_STORE_CONNECT_API_KEY_BASE64` 등
3. **Xcode/Flutter iOS 빌드 환경** — runner 환경 변경

## 요청 사항

1. GitHub Actions secrets에서 Apple 관련 시크릿 유효성 확인
2. Apple Developer Portal에서 인증서/프로파일 만료 여부 점검
3. 실패 로그 직접 확인 (gh run view로 로그 조회 불가 상태)
4. 7월 출시 전 iOS 배포 파이프라인 안정화 필요

## 참고
- CI required check(`ci-result`)에는 포함되지 않아 PR 머지에는 영향 없음
- 하지만 TestFlight 배포가 차단된 상태이므로 QA/테스트에 영향 가능

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-03-29

🤖 **tpm-staff**: #702와 동일 주제 (iOS deploy 연속 실패) 중복. #702로 통합 추적합니다.
