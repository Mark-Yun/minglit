# GitHub Actions

`.github/actions/` 는 workflow 에서 재사용하는 local action 의 진입점이다. 새 action 을 추가할 때는 이 파일의 이정표를 갱신한다.

## 이정표

| Action | 내용 |
|--------|------|
| [deploy-flutter-app](./deploy-flutter-app/action.yml) | Flutter app deploy 공통 action |
| [deploy-nextjs-app](./deploy-nextjs-app/action.yml) | Next.js app deploy 공통 action |
| [ios-deploy](./ios-deploy/action.yml) | iOS deploy 공통 action |
| [release-bot-token](./release-bot-token/action.yml) | `minglit-release-bot` GitHub App installation token mint |

## 컨벤션

- Local action 은 workflow 내부 반복을 줄일 때만 추가한다.
- Secret 은 action 안에서 직접 참조하지 않고 input 으로 받는다.
- Protected branch/tag write 용 token 은 `release-bot-token` 을 통해 mint 한다.

---
_Reviewed: 2026-05-23 10:00_
