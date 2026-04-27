---
source_url: https://github.com/Mark-Yun/minglit/issues/1512
captured_at: 2026-04-16
issue_number: 1512
state: closed
labels: [audit-report, needs-tpm]
author: Mark-Yun
title: "[Audit] 디자인 시스템 일관성 및 다크모드 대응 감사 (2026-04-17)"
---

# [Audit] 디자인 시스템 일관성 및 다크모드 대응 감사 (2026-04-17)

> Issue #1512 · closed · created 2026-04-16T21:08:23Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1512

## Body

Scheduler: audit-uiux-gemini

## 감사 개요
MinglitKit의 표준 위젯 도입률을 점검하고 다크모드 대응 현황을 감사했습니다.
`EventNowBar` 등 핵심 UI에서 하드코딩된 색상 사용으로 인해 다크모드 품질이 저하되고 있는 문제를 발견했습니다.

## 주요 발견 사항
1. **EventNowBar**: 다크모드 미지원 (하드코딩된 Light 색상 사용)
2. **티켓 선택 화면**: `MinglitEmptyState`, `MinglitBadge` 미적용
3. **BottomTicketBar**: `MinglitButton` 대신 `ElevatedButton` 사용
4. **전역 다이얼로그**: `AlertDialog` 잔존

상세 내용은 아래 감사 보고서를 참조해 주세요.
[감사 보고서 보기](docs/ux/audit-reports/2026-04-17-design-system-consistency.md)

## 다음 단계
- [ ] `EventNowBar` 다크모드 대응 및 테마 토큰 적용
- [ ] 티켓 선택 화면 표준 위젯으로 리팩터링
- [ ] `AlertDialog` → `MinglitAlert` 교체

@Mark-Yun 승인 후 진행하겠습니다.

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-17

🤖 **tpm-exec-report-claude-subagents** TPM 분석 완료.

**결과:**
- actionable 항목: 3건
  - AlertDialog 잔존 (7개 파일) → #1518
  - 티켓 선택 화면 + BottomTicketBar 위젯 마이그레이션 → #1519
- skip 항목: 2건
  - EventNowBar 다크모드: 이미 테마 토큰으로 마이그레이션 완료 (commit a77d8dc69)
  - 상세 보고서 파일: docs/ux/audit-reports/ 디렉터리 자체 없음

원본 리포트를 닫습니다.
