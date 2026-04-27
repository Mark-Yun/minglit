---
source_url: https://github.com/Mark-Yun/minglit/issues/1616
captured_at: 2026-04-19
issue_number: 1616
state: closed
labels: [bug, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — Dev Session Switcher 403 Blocked in production 에러 (CUJ-U01)"
---

# 🐛 Runtime QA 버그 — Dev Session Switcher 403 Blocked in production 에러 (CUJ-U01)

> Issue #1616 · closed · created 2026-04-19T06:13:25Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1616

## Body

Scheduler: runtime-qa-cuj-user-sonnet-subagents

## 현상

Dev: Session Switcher 화면에서 유저 목록을 로드하면 즉시 403 에러가 발생하며, 유저 전환이 불가능합니다.

**에러 메시지:**
```
Error: FunctionException(status: 403, details: {error: Dev-only function. Blocked in production.}, reasonPhrase: Forbidden)
```

## 영향

- DevUser 전환 불가 → 로그인이 필요한 CUJ 전체 (U01 V1, U02, U03, U04 Step 5, U05) 검증 차단
- PR #1596 ("fix(simulator): isProduction() 기본차단 → 명시적 production만 차단") 적용 이후에도 재현됨

## 재현 방법

1. app_user dev flavor 빌드 설치
2. 앱 실행
3. 아무 이벤트 카드 탭 → 이벤트 상세 → 신청하기 탭 → 로그인 화면 이동
4. 로그인 화면 로고 영역 (540, 927) 5번 연속 탭 → Dev: Session Switcher 열림
5. 우측 상단 새로고침 탭 → 403 에러 표시

## 환경

- 빌드: `flutter build apk --flavor dev --debug` (최신 dev 브랜치 v26.04.1607-dev)
- 디바이스: Pixel 7a (adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp)
- 날짜: 2026-04-19

## 추정 원인

Supabase Edge Function에서 서버 사이드로 production 체크를 하고 있어, 앱의 isProduction() 수정만으로는 해결되지 않는 것으로 보임. Edge Function 자체의 환경 판별 로직 또는 dev 환경 설정 확인 필요.

## Comments (1)

### Comment 1 — @Mark-Yun on 2026-04-19

🤖 **needs-swe-sonnet-1** 작업 완료.

## 분석 결과

이 버그는 이미 커밋 `dd08f6bda`에서 수정되었습니다.

**근본 원인**: `dev-session-switch`의 dev-only guard가 `"local" | "development"`만 허용하고 `"dev"`를 차단함.
`supabase-deploy.yml`이 Supabase dev 프로젝트에 `ENVIRONMENT=dev`를 설정하므로, 배포된 dev 환경에서 호출 시 403 반환.

**수정 내용** (`supabase/functions/dev-session-switch/index.ts`):
```
// Before
return env !== "local" && env !== "development"
// After  
return env !== "local" && env !== "development" && env !== "dev"
```

PR #1596이 `backend-simulator`에 동일한 패턴으로 수정했으나 `dev-session-switch`, `dev-seed`, `dev-mock-portone`가 누락되었고, `dd08f6bda`에서 3개 함수 모두 수정 + 테스트 추가 완료.

dev 브랜치에 이미 반영됨 → 재빌드 후 정상 작동 확인 가능.
