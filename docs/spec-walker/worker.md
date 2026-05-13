# 워커 동작

spec-walker 워커는 `flows/` 의 각 `.md` 파일을 읽고 디바이스에서 실행하여 `results/<name>/` 를 갱신한다.

## 책임 범위

| 함 | 안 함 |
|----|------|
| flow 파일을 읽고 단계 추출 | flow 가 spec 과 일치하는지 검증 |
| 디바이스에서 각 단계 실행 | 이전 스크린샷과 시각적 비교 |
| 스크린샷 캡처 | 변경 사유 분석 |
| `walk-log.md` 에 실행 결과 기록 | 이슈 자동 파일링 |

비교·판단은 사람이 PR 리뷰 또는 `results/` 디렉토리 변경 사항을 보고 수행한다.

## 실행 단계

1. **flow 파일 로드** — `docs/spec-walker/flows/` 의 `.md` 파일을 모두 읽는다 (`_*.md` 는 예시이므로 제외)
2. **순회** — 각 flow 마다:
   1. Setup 섹션의 사전 조건을 만족하는지 확인 (불가능하면 그 flow skip + 로그)
   2. Steps 의 각 단계를 순서대로 실행
   3. `스크린샷: yes` 인 단계마다 `results/<name>/screenshots/step{N}-<route>.png` 저장
   4. 모든 단계 완료 또는 실패 시 `results/<name>/walk-log.md` 갱신
3. **직접 푸시** — 결과를 `dev` 브랜치에 직접 push (`chore(spec-walker): refresh results [skip ci]`)

## walk-log.md 형식

각 flow 의 결과 로그. 워커가 매 실행마다 덮어쓴다.

```markdown
# <flow name>

- 실행 시각: 2026-05-13T09:00:00Z
- 결과: OK / PARTIAL / FAILED
- 디바이스: <device id / emulator name>

## 단계별

1. [OK] 로그인 화면 진입 — screenshots/step1-login.png
2. [OK] 이메일 입력 — screenshots/step2-login-filled.png
3. [SKIP] 사전 조건 미충족 — OAuth 콜백 외부 의존
4. [FAIL] 홈 카드 탭 — UI 요소 찾기 3회 실패 (좌표 추론 실패)

## 메모

워커가 자동으로 남기는 짧은 메모. 사람이 후처리할 때 참고.
```

`OK` / `PARTIAL` / `FAILED` 만 사용. 워커는 판단하지 않는다 — 단순히 실행 가능 여부.

## 실패 처리

- 한 단계 실패: 그 단계만 FAIL, 가능하면 다음 단계 진행 시도. 못 하면 PARTIAL 로 종료
- 사전 조건 미충족: 그 flow 만 SKIP, 다른 flow 는 계속
- 디바이스 disconnect 등 인프라 실패: 전체 워커 fail, 다음 스케줄에서 재시도

## 트리거

[FRESH_DOC](./FRESH_DOC) 의 `cycle` 에 따라 GitHub Actions 워크플로우가 주기적으로 워커를 호출한다. 수동 실행도 가능 (`workflow_dispatch`).

워크플로우 구현은 별도 PR. 이 문서는 워커 측 동작 명세까지만 포함한다.
