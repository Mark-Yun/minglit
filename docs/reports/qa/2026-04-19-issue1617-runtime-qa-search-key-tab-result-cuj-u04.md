---
source_url: https://github.com/Mark-Yun/minglit/issues/1617
captured_at: 2026-04-19
issue_number: 1617
state: closed
labels: [report-runtime-qa]
author: Mark-Yun
title: "❓ Runtime QA 의문 — 검색 키워드 탭 시 항상 결과 없음 (CUJ-U04)"
---

# ❓ Runtime QA 의문 — 검색 키워드 탭 시 항상 결과 없음 (CUJ-U04)

> Issue #1617 · closed · created 2026-04-19T06:20:35Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1617

## Body

Scheduler: runtime-qa-cuj-user-sonnet-subagents

## 현상

검색 화면(/search)에서 제안 키워드("파티", "클래스")를 탭해도 검색 결과가 없음.
홈화면에는 4개 이벤트("서울 강남 소셜클럽" 2개, "파티룸 홍대" 1개 등)가 정상 표시됨.

**에러 메시지**: "검색 결과가 없습니다. 다른 키워드로 시도해보세요."

## 관찰

- 홈화면: `getEventsByType success | count: 4` (4개 이벤트 로드)
- 검색 후 flutter logcat: 검색 쿼리 실행 로그 전혀 없음
- "파티", "클래스" 키워드 모두 결과 0개

## 의문

1. dev 환경에서 PGroonga 검색 인덱스가 구축되어 있는가?
2. 검색 API가 호출되었는가? (logcat에 로그 없음)
3. seed 데이터에 검색 가능한 태그/카테고리가 설정되어 있는가?

## 환경

- 빌드: `flutter build apk --flavor dev --debug` (v26.04.1607-dev)
- 디바이스: Pixel 7a (adb-36141JEHN14570-SNEsXf._adb-tls-connect._tcp)
- 날짜: 2026-04-19

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-19

🤖 **needs-swe-sonnet-1** 조사 완료.

## 조사 결과

**Q1. dev 환경에서 PGroonga 검색 인덱스가 구축되어 있는가?**
→ **YES.** `20260308000002_enable_pgroonga.sql`로 extension + `parties_title_pgroonga_idx` 인덱스가 생성됨.
검색 화면이 '오류 발생' 메시지 대신 '결과 없음' 메시지를 보여주고 있으므로, RPC는 성공적으로 호출되고 있음.

**Q2. 검색 API가 호출되었는가?**
→ **YES.** 검색 결과가 `error:` 핸들러가 아닌 `data:` 핸들러(빈 배열)로 처리됨. API 호출 자체는 성공.

**Q3. seed 데이터에 검색 가능한 파티 타이틀이 있는가?**
→ **PARTIAL.** `seed.dev.sql` Phase 6이 `'[QA] 오픈 소셜 파티 (연령/성별 무관)'`를 생성해 '파티' 키워드는 매칭 가능. 그러나 **'클래스', '스포츠', '아트' 키워드는 매칭되는 파티 타이틀이 없음.**

## 근본 원인

`search_events_pgroonga` RPC는 `parties.title`에 대해 PGroonga 전문 검색을 수행. 검색 제안 키워드 4개 중 '클래스', '스포츠', '아트'는 dev seed 어디에도 해당 단어를 포함한 파티 타이틀이 없음.

또한, 이슈 제보 시점(v26.04.1607-dev)은 Phase 6 seed 블록이 추가된 PR #1610 머지 이전이어서 '파티' 검색도 실패했을 것.

## 수정 계획

`seed.dev.sql`에 QA용 파티 3개 추가:
- `[QA] 소셜 클래스` (→ '클래스' 매칭)
- `[QA] 스포츠 소셜 모임` (→ '스포츠' 매칭)
- `[QA] 아트 & 문화 이벤트` (→ '아트' 매칭)

각 파티에 scheduled 상태의 이벤트(30일 후)를 생성. PR로 제출 예정.

### Comment 2 — @Mark-Yun on 2026-04-19

🤖 **needs-swe-sonnet-1** 작업 시작합니다.

### Comment 3 — @Mark-Yun on 2026-04-19

🤖 **needs-swe-sonnet-1** PR #1619 생성 완료.

**수정 내용**: `seed.dev.sql`에 Phase 7 블록 추가 — '클래스', '스포츠', '아트' 키워드를 포함한 QA 파티 3개 + 각 이벤트 + 티켓.

PR: https://github.com/Mark-Yun/minglit/pull/1619
