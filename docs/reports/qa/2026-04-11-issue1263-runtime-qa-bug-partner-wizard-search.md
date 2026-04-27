---
source_url: https://github.com/Mark-Yun/minglit/issues/1263
captured_at: 2026-04-11
issue_number: 1263
state: closed
labels: [bug, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — 파트너 신청 위저드에서 주소 검색이 작동하지 않음"
---

# 🐛 Runtime QA 버그 — 파트너 신청 위저드에서 주소 검색이 작동하지 않음

> Issue #1263 · closed · created 2026-04-11T12:14:23Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1263

## Body

### 현상
파트너 신청 위저드 Step 3에서 주소 검색을 시도하면 '검색 결과가 없습니다' 메시지만 표시되고 검색이 되지 않음. (영어/한국어 입력 모두 실패)

### 재현 경로
1. 파트너 앱 실행 -> 신규 유저 로그인
2. 파트너 신청 위저드 진입
3. Step 3 (연락처 및 정산)에서 '사업자 등록 주소' 필드 탭
4. 주소 검색 화면에서 키워드 입력 후 검색 버튼 탭

### 관찰 내용
- 검색 API 응답이 없거나 처리가 안 되는 것으로 보임.
- 이로 인해 주소 필드가 '-'로 남게 되어 최종 단계에서 '신청하기' 버튼이 활성화되지 않음. (Hard Block)

### 환경
- Session ID: 20260411-210032
- Device: Android
- Build: 26.04.1252-dev

Scheduler: runtime-qa-cuj-partner-gemini

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-11

🤖 **needs-swe-sonnet-subagents-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-11

🤖 **needs-swe-sonnet-subagents-1** 작업 완료.

**Root Cause**: `JUSO_CONFIRM_KEY`가 Android/iOS CI 빌드 커맨드에서 누락되어 `String.fromEnvironment('JUSO_CONFIRM_KEY')`가 빈 문자열로 컴파일됨. 빈 confmKey로 JUSO API 호출 → 주소 검색 결과 없음.

**PR**: #1265 (auto-merge 활성화)

**변경 범위**:
- 4개 CI/CD 파일: `JUSO_CONFIRM_KEY` 빌드 주입 추가 (Android APK/AAB, iOS IPA)
- `address_search_dialog.dart`: confmKey 빈값 조기 감지 + 명확한 에러 메시지
- `address_search_dialog_test.dart`: 미설정 케이스 테스트 추가

**주의**: `JUSO_CONFIRM_KEY` GitHub Secret이 repo에 등록되어 있어야 실제 주소 검색이 작동합니다.

### Comment 3 — @Mark-Yun on 2026-04-11

🤖 **needs-swe-codex-1** PR #1265가 dev에 머지되어 작업 완료 확인했습니다.

- 머지 시각: 2026-04-11T12:43:46Z
- CI: `ci-result` 통과
- CodeRabbit 리뷰 스레드: resolved

이슈는 `Closes #1263`로 자동 close되었습니다.
