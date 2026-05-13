# Graphify 자동 갱신 워크플로우

`.github/workflows/graphify-update.yml` 이 `graphify-out/` 을 자동으로 갱신한다. 로컬 hook 을 대체한다.

## 트리거

세 가지 경로로 실행된다.

| 트리거 | 조건 | 용도 |
|--------|------|------|
| `push` | `dev` 브랜치, `graphify-out/**` 외 변경 | PR 머지 직후 즉시 갱신 |
| `schedule` | 매일 04:00 UTC (13:00 KST) | 누락 보정용 안전망 |
| `workflow_dispatch` | 수동 | 디버깅 / 강제 갱신 |

`paths-ignore: ['graphify-out/**']` 로 자기 자신의 push 가 워크플로우를 재트리거하는 무한 루프를 막는다.

## 실행 단계

1. `dev` 브랜치 checkout (`GH_PAT_VERSION_BUMP` 시크릿 사용 — 보호된 브랜치에 직접 push 가능)
2. Python 3 환경 설정
3. `pip install graphifyy==0.4.23` (버전 핀)
4. `graphify update . --no-viz` 실행 (viz 단계는 노드 수 5000+ 에서 실패하므로 건너뜀)
5. `graphify-out/` 에 변경이 있으면:
   - `chore(graphify): auto-update [skip ci]` 커밋
   - `dev` 에 직접 push (CI 재실행 방지 위해 `[skip ci]`)
6. 변경 없으면 종료

## 동시 실행 방지

`concurrency.group: graphify-update` 로 동일 그룹의 워크플로우가 동시에 돌지 않게 한다. 푸시가 빠르게 연속되면 큐잉되어 순차 실행된다. `cancel-in-progress: false` — 이미 시작된 갱신을 중간에 끊지 않는다.

## 권한

- `contents: write` — graphify-out 갱신 커밋용
- `GH_PAT_VERSION_BUMP` 시크릿 — 보호된 `dev` 에 직접 push (version-bump.yml 과 동일 패턴)

## 실패 시 동작

- `pip install` 실패: 워크플로우 fail. 다음 push 또는 daily schedule 에서 재시도
- `graphify update` 실패: 워크플로우 fail. `[skip ci]` 없이 종료되므로 graphify-out 갱신 안 됨 → 다음 트리거에서 재시도
- `git push` 실패 (race condition): 워크플로우 fail. 다음 schedule 에서 재시도

영구 실패 알림은 별도로 두지 않는다. daily schedule 이 safety net 역할.

## 비용

- AST 추출 only (LLM 호출 없음) → CI 분당 비용 ~30초 ~ 1분 수준
- 매 dev push 마다 실행되므로 트래픽 많은 날 ~10회 실행 추정
