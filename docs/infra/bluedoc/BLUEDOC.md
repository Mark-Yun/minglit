# BLUEDOC

폴더의 **진입점 + 이정표**. 아무것도 모르는 사람·에이전트가 폴더에 처음 들어오면 이 파일부터 읽는다. *"여기 뭐 있지 / 어디로 가야 하지"* 한 화면에 답한다.

## 배경

폴더 단위 문서가 늘면서 "어디부터 읽지" 가 매번 달라지는 문제를 해소한다. README·OVERVIEW·INDEX 는 의미가 모호하거나 다른 용도와 충돌하므로 별도 이름을 쓴다.

## 역할

- **이정표**: 폴더 안의 하위 항목 (subfolder·핵심 파일·sibling 문서) 표로 정리
- **개요**: 1~2 줄로 이 폴더의 정체성
- **링크**: 상세 문서(`architecture.md` 등) 와 외부 컨벤션 sibling 으로

## 내용

- 들어가는 것: 1 줄 정의 / 이정표 표 (subfolder · 핵심 파일 · sibling 문서) / 핵심 컨벤션 3~5 / 관련 문서 링크
- 들어가지 않는 것: 상세 아키텍처 → `architecture.md`, 빌드·실행 → `README.md`, 스펙·스키마·결정 기록 → 별도 sibling

## 형제 문서 컨벤션

| 파일 | 역할 |
|---|---|
| `BLUEDOC.md` | 진입점 + 이정표 (≤50 줄) |
| `architecture.md` | 상세 아키텍처·패턴·결정 기록 (분량 자유) — 있을 때만 |
| `README.md` | 빌드·실행·테스트 명령 — 있을 때만 |

폴더에 아키텍처 디테일이 있으면 `architecture.md` 를 옆에 두고 BLUEDOC 에서 링크. 폴더가 단순하면 BLUEDOC 만으로 충분.

## 제약

- **50 줄 이내.** 초과하면 진입점이 아니라 본문 — 내용을 sibling 으로 분리하고 BLUEDOC 은 링크만 남긴다.
- **새 문서 추가 시 BLUEDOC 의 이정표 표에 반드시 줄 추가.** 이정표가 stale 하면 BLUEDOC 의 가치가 무너진다.

## Reviewed 필드 + Freshness 검사

모든 BLUEDOC 마지막에 `_Reviewed: YYYY-MM-DD HH:MM_` (KST, 24-시간). `pr-gate.check-bluedoc-freshness` 가 두 가지 검사:

1. **Freshness**: 새 파일/폴더 추가나 파일 삭제 시, 그 변경의 *가장 가까운 (변경 전 존재한) 조상* `BLUEDOC.md` 가 같은 PR 에 포함돼야 함. 절차: **먼저 이정표 표 갱신이 필요한지 검토 → 필요하면 갱신 + Reviewed 날짜 bump / 불필요하면 Reviewed 날짜만 bump.**
2. **Format**: 모든 BLUEDOC 이 위 형식의 Reviewed 줄 포함. 형식만 검증 (값 범위 검증 없음).

위반 시 `ci-result` 실패. 상세: [`.github/scripts/check-bluedoc-freshness.sh`](../../../.github/scripts/check-bluedoc-freshness.sh).

---
_Reviewed: 2026-05-17 22:32_
