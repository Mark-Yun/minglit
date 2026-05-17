# tests/_coverage

Flutter 프로젝트별 **테스트 커버리지 아티팩트 저장소**. `.github/workflows/sync-test-coverage.yml` 가 dev push 시 자동 갱신.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`app_user/`](./app_user/) | `app_user` 프로젝트 커버리지 (lcov.info + summary.md) |
| [`app_partner/`](./app_partner/) | `app_partner` 프로젝트 커버리지 |
| [`minglit_kit/`](./minglit_kit/) | `minglit_kit` 패키지 커버리지 |

각 폴더 안:
- `lcov.info` — `flutter test --coverage` 원본 출력
- `summary.md` — 라인 커버리지 % + 파일 수 요약 (sync-test-coverage 가 생성)

## 핵심 컨벤션

- **자동 갱신만, 수동 편집 금지.** `sync-test-coverage` 가 dev push 시 갱신. PR 에서 직접 수정 시 다음 push 에 덮어쓰임.
- **lcov.info 의 파일 경로는 각 프로젝트 루트 기준** (예: `lib/src/features/...`). 리포지토리 루트 기준 아님.
- **워크플로우는 변경 없으면 commit skip** — 커버리지 동일 시 noise 안 만듦.

## 사용처

- 회귀 추적: PR 머지 후 커버리지 변동 확인
- 외부 도구 연동: Codecov / SonarCloud 등이 이 경로의 lcov.info 를 소비 가능 (현재 별도 업로드는 `pr-gate` 안의 `test-flutter-apps` job 이 직접 codecov 로 함 — 본 폴더는 in-repo 스냅샷)
- 사람이 읽기: 각 `summary.md` 로 빠른 커버리지 확인

## 관련

- [.github/workflows/sync-test-coverage.yml](../../.github/workflows/sync-test-coverage.yml) — 자동 갱신 워크플로우
- [.github/workflows/BLUEDOC.md](../../.github/workflows/BLUEDOC.md) — workflow prefix 컨벤션
- [BLUEDOC 컨벤션](../../docs/infra/bluedoc/BLUEDOC.md)

---
_Reviewed: 2026-05-17 22:32_
