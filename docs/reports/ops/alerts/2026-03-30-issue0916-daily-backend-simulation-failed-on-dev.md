---
source_url: https://github.com/Mark-Yun/minglit/issues/916
captured_at: 2026-03-30
issue_number: 916
state: closed
labels: [ci-failure, P0-critical, report-exec]
author: app/github-actions
title: "🚨 Daily Backend Simulation failed on dev"
---

# 🚨 Daily Backend Simulation failed on dev

> Issue #916 · closed · created 2026-03-30T22:29:35Z · author @app/github-actions
> https://github.com/Mark-Yun/minglit/issues/916

## Body

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 87bba1790ac162157ac514f9d08aa2568505a774
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/23770790867
**Triggered by**: N/A
**Actor**: Mark-Yun

## Comments (6)

### Comment 1 — @github-actions on 2026-03-31

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 1e309f735aca97cf94761ed4ec31866e8e176f88
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/23822377914
**Triggered by**: N/A
**Actor**: Mark-Yun

### Comment 2 — @github-actions on 2026-04-01

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: f8f15d3c4f4bec5cd2a4a0c449cb37239025264f
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/23874010253
**Triggered by**: N/A
**Actor**: Mark-Yun

### Comment 3 — @github-actions on 2026-04-02

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 1304d3381b5bff47009925fbe617ba1b1023b689
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/23924847683
**Triggered by**: N/A
**Actor**: Mark-Yun

### Comment 4 — @github-actions on 2026-04-03

**Workflow**: Daily Backend Simulation
**Branch**: dev
**Commit**: 1304d3381b5bff47009925fbe617ba1b1023b689
**Run**: https://github.com/Mark-Yun/minglit/actions/runs/23964493770
**Triggered by**: N/A
**Actor**: Mark-Yun

### Comment 5 — @Mark-Yun on 2026-04-04

🤖 TPM: report-exec 라벨 추가. #950(CUJ adb 5일 연속 실패)과 동일 인프라 원인으로 추정. 4/3까지 계속 실패 코멘트가 달리고 있으나 assignee/routing 없이 5일 방치 상태. 사람의 인프라 결정 필요.

### Comment 6 — @Mark-Yun on 2026-04-04

Duplicate of #950. Root cause: `android-emulator-runner@v2`가 스크립트를 `/usr/bin/sh`로 실행하여 bash 전용 명령어(`shopt`) 실패. #950 에서 수정 방안 제시됨.
