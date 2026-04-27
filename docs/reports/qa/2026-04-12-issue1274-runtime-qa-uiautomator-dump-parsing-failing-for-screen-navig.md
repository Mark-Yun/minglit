---
source_url: https://github.com/Mark-Yun/minglit/issues/1274
captured_at: 2026-04-12
issue_number: 1274
state: closed
labels: [bug, needs-tpm, report-runtime-qa]
author: Mark-Yun
title: "🐛 Runtime QA — UIautomator dump parsing failing for screen navigation"
---

# 🐛 Runtime QA — UIautomator dump parsing failing for screen navigation

> Issue #1274 · closed · created 2026-04-12T08:28:26Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1274

## Body

**Scheduler:** runtime-qa-smoke-user-haiku

## Problem
UIautomator dump bounds extraction is returning [0,0][0,0] for all UI elements. This blocks screen navigation testing and verification.

## Evidence
- Session: qa-sessions/20260412-171342
- Device: Galaxy S10e (adb-R39M2033LFZ-McLWol._adb-tls-connect._tcp)
- Symptom: Button tap coordinates can't be extracted from uiautomator dump
  - Expected: bounds="[x1,y1][x2,y2]" format  
  - Actual: bounds="[0,0][0,0]"

## Impact
- U-S01 (HomePage) passes ✅ — visual verification confirms events loading
- U-S02+ screens cannot be tested via UIautomator extraction method
- Navigation automation blocked

## Workaround
Vision-based coordinate extraction (Gemini) works. Haiku flow needs different approach.

## Next Steps
- Investigate uiautomator dump format on Galaxy S10e
- Consider screenshot-based coordinate extraction for Haiku flow
- Or use native accessibility API instead of uiautomator

---
Session data: /session.log
Screenshots: /screenshots/

## Comments (5)

### Comment 1 — @Mark-Yun on 2026-04-12

## Detailed Investigation

**Environment:**
- Worker: runtime-qa-smoke-user-haiku
- Device: Galaxy S10e (SM_G970N)
- APK: com.minglit.app_user.dev (app-dev-debug.apk)
- Session: 20260412-171342

**Initial Success:**
- ✅ App build succeeded (after full Android clean)
- ✅ APK installed
- ✅ App launched
- ✅ HomePage loads with event cards visible (screenshot confirmed)

**Blocker Details:**
When running `adb exec-out uiautomator dump /dev/tty`, the XML contains UI elements but all bounds show [0,0][0,0]:
```
<Button ... bounds="[0,0][0,0]" text="마감임박" ... />
```

This prevents extraction of tap coordinates for navigation testing.

**Session Files:**
- Logs: qa-sessions/20260412-171342/session.log  
- Screenshots: qa-sessions/20260412-171342/screenshots/
  - U-S01_home.png — HomePage with events ✅
  - U-S02.png — Same screen (navigation failed)
  - app_screenshot_fresh.png — Full page with event data

**Recommendation:**
For Haiku flow (no vision), consider:
1. Use accessibility tree directly (`adb shell dumpsys accessibility`)  
2. Use native Android Espresso bindings if available
3. Switch Haiku back to screenshot + text-based OCR for coordinates

### Comment 2 — @Mark-Yun on 2026-04-12

🤖 **needs-qa-claude-1** 작업 시작합니다.

### Comment 3 — @Mark-Yun on 2026-04-12

## QA Lead 분석 — needs-qa-claude-1

### Root Cause

**Flutter 앱의 구조적 한계이며, Galaxy S10e 특정 문제가 아닙니다.**

Flutter는 Skia/Impeller 엔진으로 단일 `FlutterSurfaceView` 위에 모든 위젯을 렌더링합니다. Android UIautomator는 네이티브 View hierarchy를 탐색하므로, Flutter 위젯의 개별 bounds를 추출할 수 없습니다. 결과적으로 모든 요소가 `bounds="[0,0][0,0]"`으로 반환됩니다.

이는 **모든 Flutter 앱 + 모든 Android 디바이스**에서 동일하게 발생하는 알려진 제약입니다.

### 전략적 권고

runtime-qa 워커가 Flutter 앱의 화면 네비게이션을 자동화하려면, UIautomator 대신 다른 접근이 필요합니다:

| 방법 | 장점 | 단점 | 권장도 |
|------|------|------|--------|
| **1. Vision 기반 (Gemini)** | 이미 동작 확인됨. Flutter 무관. | Haiku에서 사용 불가. API 비용. | ✅ 현재 워크어라운드 유지 |
| **2. Flutter Semantics → Accessibility** | `adb shell dumpsys accessibility` | Flutter semantics 활성화 필요. 파싱 복잡도. 실제 tap 좌표 추출 가능성 미검증. | ⚠️ 검증 필요 |
| **3. Flutter Integration Test Driver** | Flutter 네이티브. 가장 안정적. | 별도 test harness 필요. runtime-qa 워커 아키텍처 변경 필요. | 🔮 장기 목표 |
| **4. 고정 좌표 매핑** | 구현 간단 | 해상도/레이아웃 변경 시 깨짐. 유지보수 비용. | ❌ 비권장 |

### 권장 조치

1. **단기**: Vision 기반 (Gemini) 워커를 primary로 사용. Haiku 워커는 vision 없이 실행 가능한 범위(앱 설치/실행/스크린샷 수집)로 역할 축소.
2. **중기**: Flutter Semantics 트리 + `adb shell dumpsys accessibility` 접근이 실제로 tap 좌표를 제공하는지 PoC 검증. 가능하면 Haiku 워커에 통합.
3. **장기**: `test-strategy.md`의 E2E 계층(Phase 3)에서 Flutter Integration Test Driver 도입 시 runtime-qa 워커도 이 인프라를 활용.

### 테스트 전략 문서 영향

현재 `docs/qa/test-strategy.md`에 runtime-qa 워커 계층이 명시되어 있지 않습니다. E2E 실물 디바이스 테스트 섹션에 runtime-qa 워커의 역할과 제약을 추가해야 합니다. 이 업데이트는 제가 처리하겠습니다.

### 라우팅

이 이슈는 앱 코드 수정이 아닌 **runtime-qa 워커 인프라 전략** 문제입니다.
- `needs-qa` 제거 (분석 완료)
- `needs-tpm` 추가 — 단기/중기/장기 조치 중 어떤 범위를 우선 실행할지 판단 요청

### Comment 4 — @Mark-Yun on 2026-04-12

🤖 **needs-qa-claude-1** PR 생성: #1277

test-strategy.md에 Runtime QA 계층 및 Flutter+UIautomator 비호환 제약을 문서화했습니다.

`needs-tpm` 라벨로 라우팅 완료 — 단기/중기/장기 조치 범위 결정 요청.

### Comment 5 — @Mark-Yun on 2026-04-12

🤖 **needs-qa-claude-1** 작업 완료.

- ✅ PR #1277 머지 완료 (2026-04-12)
- ✅ test-strategy.md §7에 Runtime QA 계층 및 Flutter+UIautomator 비호환 제약 문서화
- ✅ `needs-tpm` 라벨로 라우팅 — 단기/중기/장기 조치 범위 결정 대기 중
