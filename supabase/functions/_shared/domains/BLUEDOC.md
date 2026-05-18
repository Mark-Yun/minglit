# _shared/domains

도메인별 **순수 비즈니스 로직** 모음. IO (DB / 외부 API / HTTP / env / Date.now) 없음.

## 왜 `_shared/domains/`?

Hexagonal 의 도메인 코어는 보통 EF 안 nested 폴더에 두지만, Supabase CLI 는 nested EF entrypoint 를 인식 못 함 ([Issue #3676](https://github.com/supabase/cli/issues/3676)). 차선책으로 `_shared/` 안에 도메인별 grouping. EF 폴더는 flat 유지.

## 현재 도메인

| 도메인 | 설명 | BLUEDOC |
|---|---|---|
| `payment/` | application status 분류, 환불 정책 (grace period + cutoff), 정책 파싱 | [payment/BLUEDOC.md](payment/BLUEDOC.md) |
| `event/` | event status 가드 (신청 가능 / 편집 가능), capacity, 시작 시각, participant (`isCheckedIn`) | [event/BLUEDOC.md](event/BLUEDOC.md) |

## 새 도메인 추가 가이드

1. EF 들이 동일한 분류 / 계산 / 분기 로직을 인라인으로 중복 구현 → 추출 신호
2. `_shared/domains/<domain>/` 폴더 생성
3. pure 함수만 — IO 가 필요하면 인자로 주입 (예: `now: Date`, `policyRaw: unknown`)
4. `<file>.ts` + `<file>_test.ts` 동반 작성, mock 0 / IO 0
5. `BLUEDOC.md` 추가 — 파일 목록 + 사용 패턴 + 변경 정책
6. 본 entry 점에 도메인 등록

## 변경 정책

- pure 함수만 — IO 필요 시 호출자에서 인자로 주입 (testable)
- breaking change → 사용 EF 전부 영향 → 도메인 unit test 가 1차 회귀 가드
- 신규 함수 추가 자유 (사용 안 하면 cost 0)

## 관련

- [_shared/BLUEDOC.md](../BLUEDOC.md) — `_shared/` 전체 entry
- [functions/BLUEDOC.md](../../BLUEDOC.md) — EF 디렉토리 entry
- [Issue #3676](https://github.com/supabase/cli/issues/3676) — nested entrypoint 미지원 (본 구조 선택 이유)

_Reviewed: 2026-05-18 00:00_
