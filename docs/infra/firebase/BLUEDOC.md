# Firebase

minglit 의 Firebase 컴포넌트 진입점. mobile 의 crash 분석, 디바이스 farm, 원격 config, push notification.

## 사용 컴포넌트

| 컴포넌트 | 용도 | 상세 |
|----------|------|------|
| **Crashlytics** | mobile crash, crash-free rate (가장 신뢰성 높은 신호) | TBD |
| **Test Lab** | 실 디바이스 farm — `rc-gate` 일부 위임 | TBD |
| **Remote Config** | 단순 kill switch, **version kill source (Tier 2a soft `latest_version` + Tier 2b hard `kill_list_hard`)** | TBD |
| **App Check** (TBD 도입) | request 인증 (App Attest / Play Integrity / reCAPTCHA) — 버전 kill 과 무관, 별개 보안 layer | TBD |
| **Cloud Messaging (FCM)** | push notification | 기존 mobile 문서 |
| **Analytics** | 사용자 행동 (보조) | TBD |
| **App Distribution** | internal track 배포 | TBD |

## Statsig 와의 경계

- **Statsig**: 실험·gate·layered·dependent
- **Firebase RC**: 단순 on/off, kill switch, cold start fetch, min-version
- 상세: [../branch-strategy/life-of-flag.md](../branch-strategy/life-of-flag.md)

## Remote Config 운영 룰 (literature gotchas)

- **기본 fetch interval = 12시간** ([Firebase docs](https://firebase.google.com/docs/remote-config/loading)). kill switch 용은 short interval + quota 수용
- **cold-start default = 안전 상태** — 첫 cold start fetch 실패해도 사용자 미노출
- **iOS pre-6.3.0 throttle** (5 fetches / 60min). `lastFetchStatus` 체크 필수
- **flicker**: `fetchAndActivate()` async → bootstrap with cached values
- **Min-version endpoint**: 6개월 backward compat, `mobile-cut` 이 매월 자동 bump ([../branch-strategy/main-promotion.md](../branch-strategy/main-promotion.md))

## 핵심 컨벤션

- mobile crash = Crashlytics 1차, Sentry = backend / unhandled exception
- Test Lab 은 `rc-gate` 의 mobile job 일부 위임
- RC parameter description 에 owner / cleanup 일 명시
- 신규 mobile release 시 Crashlytics 에 dSYM (iOS) / mapping (Android) 등록

## 관련

- [../branch-strategy/error-detection.md](../branch-strategy/error-detection.md)
- [../branch-strategy/life-of-flag.md](../branch-strategy/life-of-flag.md)
- [../branch-strategy/main-promotion.md](../branch-strategy/main-promotion.md) — min-version
- [../statsig/BLUEDOC.md](../statsig/BLUEDOC.md)

---
_Reviewed: 2026-05-19 09:47_
