---
source_url: https://github.com/Mark-Yun/minglit/issues/1506
captured_at: 2026-04-16
issue_number: 1506
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Version Bump failed on dev"
---

# 🚨 Version Bump failed on dev

> Issue #1506 · closed · created 2026-04-16T09:33:56Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/1506

## Body

**Workflow**: Version Bump
**Branch**: dev
**Commit**: 38eeec610df7b3bc3d52be26edc39b9030ac242e
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24502967990
**Triggered by**: docs(qa): 배포 Secret 검증 + 스크린샷 캡처 포인트 정의
**Actor**: Mark-Yun

**Job Results**:
  ❌ bump: failure

## Comments (4)

### Comment 1 — @github-actions on 2026-04-16

**Workflow**: Version Bump
**Branch**: dev
**Commit**: 38030330787514327305b05a563f73804eba8466
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24502979758
**Triggered by**: docs: Admin 대시보드 스펙 + 와이어프레임
**Actor**: Mark-Yun

**Job Results**:
  ❌ bump: failure

### Comment 2 — @github-actions on 2026-04-16

**Workflow**: Version Bump
**Branch**: dev
**Commit**: cfa1631644892fb184673f87f4170688d0db214e
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24502998891
**Triggered by**: test(app): 위치정보 이용약관 스모크 테스트 추가
**Actor**: Mark-Yun

**Job Results**:
  ❌ bump: failure

### Comment 3 — @github-actions on 2026-04-16

**Workflow**: Version Bump
**Branch**: dev
**Commit**: 25b3dbc1186477424bc60678795890a5fc149b2c
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/24503016221
**Triggered by**: fix(security): payment-verify 소유권 검증 누락 — IDOR 취약점 수정
**Actor**: Mark-Yun

**Job Results**:
  ❌ bump: failure

### Comment 4 — @Mark-Yun on 2026-04-18

## 분석 완료 — 후속 이슈로 추적 전환

이 ci-failure 이슈는 **#1554** 로 진단 + 구조적 수정안을 이관했습니다.

### 요약
- 실제 원인: **push race condition** (\`cannot lock ref 'refs/heads/dev'\`, non-fast-forward)
- version-bump workflow의 checkout → commit → push 구간에 dev가 다른 경로(`Auto Format PR`, `chore: retrigger CI` 직접 push 등)로 전진
- 현재 concurrency group은 version-bump 인스턴스끼리만 직렬화 → 외부 push 경로는 막지 못함
- 집중 발생: 2026-04-16 09:33~09:34 6분간 PR 머지 폭주 때
- 최근 10 run은 전부 success — 현상은 자연 해소됐으나 **race window는 그대로 남아 재발 보장**

### 해결
`.github/workflows/sync-version.yml` push step에 pull-rebase + retry loop 추가 (#1554에 정확한 diff 포함).

실행 추적은 #1554로 이관되었으므로 이 자동 생성 ci-failure 이슈는 close합니다.
