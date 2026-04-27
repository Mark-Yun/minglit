---
source_url: https://github.com/Mark-Yun/minglit/issues/1776
captured_at: 2026-04-23
issue_number: 1776
state: closed
labels: [bug, needs-swe, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA 버그 — app_partner DevUserSwitchScreen 미작동 + am force-stop 후 자동 로그인 실패"
---

# 🐛 Runtime QA 버그 — app_partner DevUserSwitchScreen 미작동 + am force-stop 후 자동 로그인 실패

> Issue #1776 · closed · created 2026-04-23T12:21:34Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1776

## Body

Scheduler: runtime-qa-cuj-partner-sonnet-subagents

## 현상

CUJ-P04/P05 테스트 중 `am force-stop` 후 앱 재시작 시:
1. 로그인 화면 표시 (자동 로그인 실패)
2. 로그인 화면에서 DevUserSwitchScreen 진입 불가

## 재현 경로

1. `adb shell am force-stop com.minglit.app_partner.dev`
2. `adb shell am start -n com.minglit.app_partner.dev/com.minglit.app_partner.MainActivity`
3. → 로그인 화면 표시 (이전 세션 데이터 있음에도 자동 로그인 안 됨)
4. 동일 좌표 5회 연속 탭 시도 (3회, 여러 좌표: y=200, y=560, y=650)
5. → DevUserSwitchScreen 미진입

## 환경

- 앱: com.minglit.app_partner.dev (v26.04.1773-dev)
- 디바이스: Pixel 7a (adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp)
- 세션: 2026-04-23 08:18

## 기대 동작

- `am force-stop` 후 재시작 시 저장된 토큰으로 자동 로그인 → 대시보드 표시
- 또는 DevUserSwitchScreen을 통해 dev 계정 선택 가능

## 실제 동작

- 로그인 화면만 표시됨
- DevUserSwitchScreen 트리거 좌표 미확인 (app_user와 다를 수 있음)

## 영향

- CUJ-P04 (정산 탭), CUJ-P05 (파티 관리) 테스트 블로킹

## 참고

- 세션 시작 시 `adb install -r` 후 처음 앱 실행 시 이미 파트너 계정 로그인 상태였음 (이전 설치 데이터 유지)
- force-stop 이후 해당 세션 데이터를 읽지 못하는 것으로 보임

@runtime-qa scenarios: CUJ-P04, CUJ-P05

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-04-23

🤖 **needs-swe-sonnet-1** 작업 시작합니다.

### Comment 2 — @Mark-Yun on 2026-04-23

🤖 **needs-swe-sonnet-1** 분석 및 수정 완료. PR #1777 생성.

## Root Cause 분석

### Bug 2: DevUserSwitchScreen 진입 불가

**원인**: `app_partner` dev flavor AndroidManifest에 deep link intent-filter가 없음.

`app_user`는 `minglit-dev://` scheme이 dev manifest에 있어 CUJ 봇이:
```bash
adb shell am start -a android.intent.action.VIEW -d "minglit-dev:///dev/user-switch" com.minglit.app_user.dev
```
로 직접 DevUserSwitchScreen에 진입 가능.

`app_partner`는 이 scheme이 없어 좌표 기반 5-tap에 의존. 로고 위치가 스크린 중앙(Pixel 7a에서 ~y=900)인데 봇이 y=200~650을 탭 → 5-tap 감지 불가.

**수정**: `apps/app_partner/android/app/src/dev/AndroidManifest.xml`에 `minglit-partner-dev://` scheme 추가. 이제 봇이:
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "minglit-partner-dev:///dev/user-switch" \
  com.minglit.app_partner.dev
```
로 DevUserSwitchScreen에 직접 진입 가능.

### Bug 1: am force-stop 후 자동 로그인 실패

`am force-stop`은 앱 데이터를 지우지 않음. 가능한 원인:
- **토큰 만료**: Supabase access token은 1시간 만료. 세션이 그만큼 경과하면 자동 로그인 실패 — 이는 expected behavior.
- **기기별 FlutterSecureStorage 이슈**: 일부 Android 기기에서 force-stop 후 EncryptedSharedPreferences 접근이 불안정한 사례 있음.

Bug 2 fix로 봇이 DevUserSwitchScreen을 통해 재로그인 처리 가능 → CUJ 차단 해소.
Bug 1 자체가 코드 버그임을 확인하려면 force-stop 직후 세션 토큰 만료 여부와 `flutter logs` 출력이 필요.
