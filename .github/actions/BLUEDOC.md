# .github/actions/

워크플로우가 `uses: ./.github/actions/<name>` 로 호출하는 **composite actions**. 여러 step 을 묶어 워크플로우 파일의 중복 제거.

## 이정표

| Action | 역할 | 호출자 |
|---|---|---|
| [`deploy-flutter-app/`](./deploy-flutter-app/) | Flutter web 앱 → Vercel 배포 (build + alias + smoke) | `deploy-vercel` (app_user, app_partner) |
| [`deploy-nextjs-app/`](./deploy-nextjs-app/) | Next.js 앱 → Vercel 배포 (env-manifest 복사 + node 설치 + vercel CLI) | `deploy-vercel` (landing_user, landing_partner, mds_docs) |
| [`ios-deploy/`](./ios-deploy/) | iOS 앱 → TestFlight 배포 (signing cert / provisioning profile + xcodebuild + altool) | `deploy-ios-user`, `deploy-ios-partner` |

각 action 의 inputs/outputs 는 해당 폴더의 `action.yml` 참고.

## 핵심 컨벤션

- **`runs: using: "composite"`** — Docker 액션 X, JavaScript 액션 X. 모든 자체 action 은 shell step 묶음 composite.
- **여러 워크플로우에서 같은 step 체인을 반복할 때만 composite 로 추출** — 단발성 외부 액션 호출 (checkout, setup-node 등) 은 워크플로우에서 직접 `uses:` OK. 중복 / 멀티-step orchestration 만 composite.
- **action 변경 시 호출자 워크플로우 회귀 검증** — 한 PR 에서 action.yml 만 바뀌어도 호출하는 deploy-* 워크플로우 다음 cron 까지 영향.
- **secrets 는 action 의 input 으로 전달** — action.yml 안에서 `${{ secrets.* }}` 직접 참조 금지 (calling workflow 의 책임).

## 관련

- [workflows/BLUEDOC.md](../workflows/BLUEDOC.md) — 어느 워크플로우가 어느 action 호출하는지
- [.github/BLUEDOC.md](../BLUEDOC.md) — 상위 진입점
