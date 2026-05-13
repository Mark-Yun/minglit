# FRESH_DOC

`docs/` 하위 디렉토리에 두는 메타파일. 각 폴더의 문서들이 코드 변경에 뒤처지지 않도록 검토 시점을 추적하고, 매일 실행되는 GitHub 워크플로우가 stale 한 디렉토리에 Issue 를 자동 생성한다.

## 배경

문서는 stale 해도 알아채기 어렵다. 매번 사람이 점검할 수도 없다. 디렉토리마다 `FRESH_DOC` YAML 을 두고 시간 또는 코드 변경 이벤트로 검토 트리거를 잡는다. 이슈가 생성되면 그 이후의 검토·수정은 처리하는 에이전트나 사람의 몫이다.

## 문서

- [schema.md](./schema.md) — FRESH_DOC YAML 파일 정의 (필드, 타입, 예시)
- [github-workflow.md](./github-workflow.md) — 워크플로우의 stale 판정 및 이슈 생성 동작
- [schema-validator.md](./schema-validator.md) — 스키마 검증 CLI 스펙
- [test-plan.md](./test-plan.md) — validator / 워크플로우 테스트 범위
- [implementation-plan.md](./implementation-plan.md) — 도입 순서 및 후속 작업

## 관련 컨벤션

- [BLUEDOC](../bluedoc/BLUEDOC.md) — 본 폴더가 따르는 진입점 컨벤션
