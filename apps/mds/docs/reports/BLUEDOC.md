# mds/docs/reports

MDS 문서/구현/CUJ 정합성 리포트 작업장. `FRESH_DOC` cycle 이 열리면 agent 는 `audit-report.md` 의 절차를 실행하고, 발견 사항마다 GitHub Issue 를 파일링한다.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`audit-report.md`](./audit-report.md) | 주간 MDS 정합성 audit 실행 절차 + 결과 로그 |
| [`FRESH_DOC`](./FRESH_DOC) | 7일 주기 report refresh job 정의 |

## 핵심 컨벤션

- **Agent runbook 우선** — 리포트는 agent 가 그대로 실행할 수 있는 절차, 명령, filing rule 을 포함한다.
- **리포트는 evidence-first** — 각 finding 은 spec path, code path, coverage output, issue 링크 중 하나 이상을 남긴다.
- **Issue 1건 = action item 1건** — 스펙 충돌, CUJ 누락, 구현 누락을 한 이슈에 섞지 않는다.
- **Spec 수정은 report-exec** — 사람/기획 판단이 필요한 spec 변경은 구현 큐가 아니라 `report-exec` 로 남긴다.
- **소스는 직접 수정하지 않는다** — 이 폴더는 audit trail 이며, 실제 spec 수정은 `../public/specs/<screen>/index.html` 에서 처리한다.
- **FRESH_DOC 수행 후 리포트 갱신** — 새 finding 이 없어도 날짜, 명령 결과, residual risk 를 갱신한다.

## 관련

- [`../BLUEDOC.md`](../BLUEDOC.md) — MDS docs 진입점
- [`../public/specs/BLUEDOC.md`](../public/specs/BLUEDOC.md) — 화면 spec 작성 규칙
- [`../../../../docs/infra/fresh-doc/BLUEDOC.md`](../../../../docs/infra/fresh-doc/BLUEDOC.md) — FRESH_DOC 규칙
- [`../../../../scripts/mds_render_coverage.dart`](../../../../scripts/mds_render_coverage.dart) — MDS render coverage
- [`../../../../scripts/cuj_coverage.dart`](../../../../scripts/cuj_coverage.dart) — CUJ coverage

---
_Reviewed: 2026-05-31 18:24_
