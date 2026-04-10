# Dev 딥링크 QA 진입 가이드

## 목적

`DevUserSwitchScreen`에 빠르게 접근하기 위한 런타임 QA 진입 방법을 정리한다.
테스트 계정 전환, 인증 상태 리셋 등 QA 작업에 활용한다.

> **주의**: 아래 방법은 **dev 빌드 전용**이다. prod 빌드에서는 `/dev/*` 경로가 라우터에 등록되지 않아 동작하지 않는다.

---

## 진입 방법

### 1. Android — ADB 딥링크

```bash
adb shell am start \
  -a android.intent.action.VIEW \
  -d 'minglit-dev:///dev/switch' \
  -p com.minglit.app_user.dev
```

무선 ADB 환경에서는 기기 시리얼을 명시한다:

```bash
adb -s <시리얼> shell am start \
  -a android.intent.action.VIEW \
  -d 'minglit-dev:///dev/switch' \
  -p com.minglit.app_user.dev
```

### 2. iOS — Safari 딥링크

Safari 주소창에 아래 URL을 입력하고 이동한다:

```
minglit-dev://dev/switch
```

앱이 설치된 dev 빌드에서만 동작한다. Simulator에서도 동일하게 사용 가능.

### 3. 로그인 화면 로고 5탭 (기존 방법)

로그인 화면의 앱 로고를 빠르게 5번 탭하면 동일한 `DevUserSwitchScreen`으로 진입한다.
ADB/Safari를 사용할 수 없는 환경에서 대체 수단으로 활용한다.

---

## 보안 메모

- `minglit-dev://` 스킴과 `/dev/*` 라우트는 **dev flavor 빌드에만 존재**한다.
- prod 빌드(`com.minglit.app_user`)에는 해당 스킴과 라우트가 포함되지 않아 딥링크가 무시된다.
- dev 빌드가 실수로 외부에 배포되더라도 `DevUserSwitchScreen` 접근이 인증을 우회하지는 않는다 — 계정 전환 자체는 앱 내 권한 체계를 따른다.
