# Spec Walker

앱의 재현 경로(reproduction path)를 따라 실제 디바이스에서 walk 하며 각 단계의 스크린샷과 로그를 자동 갱신하는 워커.

## 배경

이전 spec walker 는 MDS flow graph 를 자체적으로 파싱하고 spec 비교 검증까지 수행했다. 비교 단계의 false positive 가 많고, 무엇을 walk 할지를 워커가 추론해야 했다. 책임을 분리한다.

- **피쳐 오너**: 관심 있는 재현 경로를 `flows/<name>.md` 에 markdown 으로 작성
- **워커**: 그 파일을 읽고 단순 실행 → `screenshot/<name>/` 의 스크린샷과 로그 갱신
- **비교/판단**: 워커 책임 아님. 사람이 screenshot/ 의 스크린샷 변화를 보고 판단

## 문서

- [flow-format.md](./flow-format.md) — 피쳐 오너용 flow 파일 작성 가이드
- [worker.md](./worker.md) — 워커가 무엇을 어떻게 실행하는지
- [FRESH_DOC](./FRESH_DOC) — 갱신 주기 설정

## 관련 컨벤션

- [BLUEDOC](../infra/bluedoc/BLUEDOC.md) — 진입점 컨벤션
- [FRESH_DOC](../infra/fresh-doc/BLUEDOC.md) — 워커 트리거 메커니즘

---
_Reviewed: 2026-05-17 22:32_
