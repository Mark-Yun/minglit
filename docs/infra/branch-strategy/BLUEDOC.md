# Branch Strategy

4-stage (`dev-staging → dev → rc → main`) + merge queue + nightly snapshot + `rc-gate` green build picking + feature flag + 3가지 safety net. AI agent 가 dev-staging commit, backend/web 은 dev rc-gate-pass commit 마다 continuous deploy (Spotify 식), mobile 은 main 에서 월 1회 cut. 모든 cadence = target, slip 자연스러움.

## 4-stage 모델

| 단계 | 역할 | 진입 방식 |
|------|------|-----------|
| `dev-staging` | AI agent commit zone | merge queue + 가벼운 `pr-gate` |
| `dev` | nightly-validated trunk | daily `nightly-cut` → post-merge `rc-gate` |
| `rc/YYYY-Wxx` | mobile RC, 5일 soak | weekly cut from latest rc-gate-pass |
| `main` | mobile-stable snapshot | rc → main 머지 (soak 통과 시) |

## Safety Nets 3종

| Safety Net | 정책 / 명세 |
|------------|-------------|
| Version kill switch (Tier 2a soft + 2b hard) | 6개월 backward compat, Firebase RC source / [main-promotion.md](./main-promotion.md) |
| Expand-Migrate-Contract CI | 6개월 DB schema, Option C / [dev-staging-pipeline.md](./dev-staging-pipeline.md) |
| Flag-registration CI | unflagged 코드 차단 / [dev-staging-pipeline.md](./dev-staging-pipeline.md) |

## 이정표

| 문서 | 내용 |
|------|------|
| [branch-flow.md](./branch-flow.md) | flow + protection + tag + backport |
| [test-strategy.md](./test-strategy.md) | per-stage gates |
| [error-detection.md](./error-detection.md) | detection layers |
| [dev-staging-pipeline.md](./dev-staging-pipeline.md) | merge queue + pr-gate + safety net CI |
| [dev-pipeline.md](./dev-pipeline.md) | nightly-cut + rc-gate + auto-deploy chain |
| [rc-promotion.md](./rc-promotion.md) | rc-cut + soak + hotfix + backport |
| [main-promotion.md](./main-promotion.md) | rc → main + mobile-cut + min-version |
| [life-of-flag.md](./life-of-flag.md) | flag lifecycle |
| [versioning.md](./versioning.md) | CalVer + tag |

## 역할 (workflow 가 처리 못하는 edge case 만)

**release manager** 비상 min-version bump · workflow-blocked promotion 수동 처리 / **on-call** workflow 자동 복구 실패한 P0 / **feature owner** flag 정책 결정 · cleanup PR review / **RC owner** abandon 판단 (TBD)

## 핵심 컨벤션

- 코드 promotion = 한 방향 PR, 기능 promotion = flag flip
- 모든 branch linear ON — dev-staging: squash, dev/rc/main: rebase
- dev rc-gate-pass = backend/web continuous deploy (Spotify 식); mobile = main 에서 월 1회 cut + cherry-pick 자동화 (TBD)
- **Hotfix 는 rc 에서, dev-staging 으로 자동 backport** ([rc-promotion.md](./rc-promotion.md))
- Tag regex 는 `RELEASE.md` lock (TODO)

---
_Reviewed: 2026-05-19 09:47_
