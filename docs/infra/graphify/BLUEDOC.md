# Graphify

레포 코드와 문서를 분석하여 지식 그래프 (`graphify-out/`) 를 생성/갱신하는 도구. AST 추출 기반으로 LLM 비용 없이 동작하며, 아키텍처 / 코드베이스 질문에 답할 때 god node 와 community 구조를 참조한다.

## 배경

이전에는 `graphify hook install` 로 설치된 로컬 `post-commit` hook 이 매 커밋 후 그래프를 재빌드했다. 매 커밋마다 1270 파일 AST 추출 (수십초), 자주 viz size limit 으로 rebuild 실패, dirty 상태로 working tree 오염 등의 문제로 인해 GitHub Actions 워크플로우로 이관했다. 로컬 hook 은 더 이상 사용하지 않는다.

## 문서

- [github-workflow.md](./github-workflow.md) — 자동 갱신 워크플로우 동작
- [local-setup.md](./local-setup.md) — 로컬 환경에서 옛 hook 제거 방법

## 관련 컨벤션

- [BLUEDOC](../bluedoc/BLUEDOC.md) — 본 폴더가 따르는 진입점 컨벤션
