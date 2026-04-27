---
source_url: https://github.com/Mark-Yun/minglit/issues/1175
captured_at: 2026-04-08
issue_number: 1175
state: closed
labels: [P1-high, audit-report]
author: Mark-Yun
title: "Security Audit Report — 2026-04-09 (Tag Discovery Phase 1 보안 감사)"
---

# Security Audit Report — 2026-04-09 (Tag Discovery Phase 1 보안 감사)

> Issue #1175 · closed · created 2026-04-08T21:05:59Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1175

## Body

Scheduler: audit-security-claude-subagents

## Executive Summary

Tag Discovery Phase 1 MVP (PR #1149) 및 관련 변경사항(#1161, #1162, #1165, #1166, #1167)에 대한 보안 감사. DB 스키마, RLS 정책, Edge Function, 동의/개인정보 정책-코드 정합성을 점검했다.

**핵심 발견**: Tag Discovery의 6개 SECURITY DEFINER RPC 함수에 REVOKE/GRANT 누락으로 **비인증 사용자(anon)가 모든 태그 RPC를 호출**할 수 있다. RLS 정책은 `TO authenticated`로 올바르게 설정되었으나, SECURITY DEFINER 함수가 RLS를 우회하여 의미가 없어졌다.

---

## Findings

### 🔴 P1-high

#### 1. SECURITY DEFINER RPC 6개에 REVOKE/GRANT 누락 — anon 호출 가능

- **위치**: `supabase/migrations/20260407000003_tag_discovery.sql` L163-298
- **공격 시나리오**: 인증 없이 Supabase REST API를 통해 `get_featured_tags()`, `get_trending_tags()`, `get_parties_by_tag()`, `search_tags()`, `get_tag_recommendations()`, `upsert_user_interest_tags()`를 호출할 수 있다. 이벤트 목록, 트렌딩 태그, 태그 검색 결과가 비인증 사용자에게 노출된다.
- **영향**: 전체 이벤트 목록 열람, 태그 네임스페이스 열거, 서비스 정보 유출
- **수정 방향**: 새 migration에서 모든 6개 함수에 `REVOKE EXECUTE FROM PUBLIC; GRANT EXECUTE TO authenticated, service_role;` 적용. 기존 코드베이스 패턴(`20260316000006_policies_table.sql` L62) 참조.

#### 2. `upsert_user_interest_tags` auth.uid() NULL 가드 누락

- **위치**: `supabase/migrations/20260407000003_tag_discovery.sql` L279-298
- **공격 시나리오**: anon 사용자가 호출 시 `auth.uid()` = NULL. DELETE는 영향 없으나, INSERT 시 `user_id = NULL`로 FK 에러 발생 → PostgreSQL 스키마 정보 유출.
- **수정 방향**: 함수 시작부에 `IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE = 'P0001'; END IF;` 추가.

#### 3. 민감 키워드 필터 Unicode 우회 가능

- **위치**: `supabase/migrations/20260408000001_tag_sensitive_keyword_filter.sql` L14-82
- **공격 시나리오**: `ILIKE '%' || v_keyword || '%'` 패턴 매칭은 다음을 못 잡는다:
  - Zero-width 문자 삽입: `흑\u200B인` → `흑인` 불일치
  - 유니코드 정규화: NFC vs NFD 분해 (`흑` composed vs `ㅎㅠㄱ` Jamo 시퀀스)
  - Fullwidth Latin: `ＨＩＶ` (U+FF28 등) → `HIV` 불일치
  - 호모글리프: Hangul Compatibility Jamo vs 표준 Jamo
- **영향**: PIPA 민감 정보(건강상태, 인종 등) 관련 태그가 필터를 우회하여 생성될 수 있음
- **수정 방향**: 비교 전 NFKC 정규화 + zero-width 문자 제거 함수 적용. 각 우회 벡터에 대한 회귀 테스트 추가.

#### 4. `tag_usage_daily` 2년 보유/압축 정책 미구현

- **위치**: `docs/features/tag-discovery/tag-stats-usage-policy.md` §4.2 (정책) vs `20260407000003_tag_discovery.sql` (코드)
- **설명**: 정책 문서에 "2년 초과 데이터는 월별 집계 압축 후 일별 데이터 삭제"를 명시했으나, 이를 수행하는 cron job/함수가 존재하지 않음. 데이터가 무제한 축적된다.
- **영향**: 문서화된 개인정보 처리 정책 불이행 → 데이터 최소화 원칙 위반 리스크
- **수정 방향**: `pg_cron`으로 월 1회 2년 초과 데이터 압축/삭제 job 등록하는 migration 작성.

#### 5. `upsert_user_interest_tags` 파괴적 부분 업데이트 버그

- **위치**: `supabase/migrations/20260407000003_tag_discovery.sql` L291
- **공격 시나리오**: `DELETE FROM user_interest_tags` 실행 후 `INSERT`에서 존재하지 않는 `tag_id`로 인해 FK 에러 발생 시, 사용자의 기존 관심 태그가 모두 삭제된 상태로 남음.
- **영향**: 사용자 데이터 손실 (관심 태그 전체 삭제)
- **수정 방향**: INSERT 전에 `p_tag_ids` 유효성 검증 추가, 또는 전체를 트랜잭션으로 묶어 rollback 보장.

---

### 🟡 P2-medium

#### 6. RPC 함수 `p_limit`/`p_days` 파라미터 상한 없음 — DoS 벡터

- **위치**: `20260407000003_tag_discovery.sql` L181-183, L216-218, L238-239
- **설명**: `p_limit = 2147483647` 전달 시 전체 테이블 스캔 유발. anon 호출 가능(Finding #1)과 결합 시 인증 없이 서비스 부하 공격 가능.
- **수정 방향**: `LEAST(p_limit, 100)`, `LEAST(p_days, 90)` 캡 적용.

#### 7. `party_tags_service` RLS 정책 `current_setting('role')` 사용

- **위치**: `20260407000003_tag_discovery.sql` L132-134
- **설명**: `current_setting('role', true) = 'service_role'` 대신 `auth.role() = 'service_role'`이 더 안전. 다른 곳에서 SQL injection이 발생할 경우 세션 변수 조작으로 우회 가능.
- **수정 방향**: `auth.role()` 패턴으로 통일 (코드베이스 다른 부분과 일관성).

#### 8. 유출 대응 프로세스 모니터링 미구현

- **위치**: `docs/security/breach-response-process.md` §5.2
- **설명**: "민감 테이블 접근 감사 로그", "이상 탐지 알림"이 2026.09.11 시행 전 구현 목표로 명시되었으나 미착수. 특히 `user_profiles` (CI/DI) 테이블 접근 로그가 없음.
- **수정 방향**: 별도 이슈로 추적. 2026.09.11 마일스톤 설정.

#### 9. 유출 통지 실행 경로 부재

- **위치**: `docs/security/breach-response-process.md` §2-2
- **설명**: 72시간 내 통지 프로세스가 문서화되었으나 실행할 Edge Function/운영 runbook이 없음. 수동 작업에 전적으로 의존.
- **수정 방향**: 최소 운영 runbook(수동 절차) 작성 또는 통지 Edge Function 구현.

---

### 🟢 P3-low

| # | 항목 | 위치 | 설명 |
|---|------|------|------|
| 10 | `search_tags` 입력 길이 제한 없음 | `20260407000003_tag_discovery.sql` L258-276 | `LEFT(p_query, 50)` 적용 권장 |
| 11 | `get_parties_by_tag`/`get_tag_recommendations`가 `SELECT e.*` 반환 | L220, L244 | 명시적 컬럼 목록으로 변경하여 데이터 노출 최소화 |
| 12 | Edge Function tag_ids UUID 형식 미검증 | `partner-manage-party/index.ts` L135-138 | UUID regex 검증 추가 |
| 13 | Edge Function tag_ids 중복 미처리 | `partner-manage-party/index.ts` L127-150 | `Array.from(new Set(tagIds))` 적용 |
| 14 | 회원가입 동의서 보관기간 문구 불일치 | `signup_consent_page.dart` L486 vs `privacy_page.dart` | PR #1161에서 설정 화면은 세분화했으나 동의서는 미업데이트 |

---

## Remediation Roadmap

| 우선순위 | 대상 | Finding # | 예상 작업 |
|----------|------|-----------|-----------|
| **즉시** | REVOKE/GRANT migration | 1, 2 | 새 migration 1개 |
| **즉시** | p_limit/p_days 캡 + auth.uid() 가드 | 5, 6 | 같은 migration에 포함 가능 |
| **이번 주** | 민감 키워드 필터 Unicode 정규화 | 3 | 새 migration 1개 + 테스트 |
| **이번 주** | current_setting → auth.role() 통일 | 7 | 새 migration 1개 |
| **다음 스프린트** | tag_usage_daily 보유 정책 cron | 4 | pg_cron migration |
| **다음 스프린트** | 유출 대응 모니터링/통지 | 8, 9 | 별도 이슈 |
| **여유 시** | P3 항목들 | 10-14 | Edge Function + Flutter 수정 |

---

## Compliance Notes

- PIPA 제22조 제4항 (동의 고지 강조): PR #1147에서 올바르게 구현됨 ✅
- 개인정보 수집 동의서에 "관심 태그" 명시됨 ✅
- 계정 삭제 시 `user_interest_tags` CASCADE 파기 ✅
- `has_required_consents()` 서버 측 동의 검증 ✅
- 유출 대응 프로세스 문서화 ✅ (실행 경로 미비 ⚠️)

---

*Generated by audit-security-claude-subagents — 2026-04-09*

## Comments (3)

### Comment 1 — @Mark-Yun on 2026-04-08

🤖 **audit-security-claude-subagents** 감사 완료.

## 생성된 이슈

| 이슈 | 우선순위 | 대상 |
|------|----------|------|
| #1176 | P1-high | RPC REVOKE/GRANT 누락 + auth.uid() 가드 + p_limit 캡 |
| #1177 | P1-high | 민감 키워드 필터 Unicode 우회 |

P2 이하 항목은 이 감사 리포트에서 추적. `needs-tpm` 라벨을 붙여 TPM이 나머지 항목의 이슈 분리 여부를 판단하도록 한다.

### Comment 2 — @Mark-Yun on 2026-04-08

🤖 **tpm-exec-report-claude-subagents** 트리아지 완료.

## 결과

### 이미 처리됨 (6건 — skip)
| Finding | 설명 | 처리 |
|---------|------|------|
| 1. REVOKE/GRANT 누락 | anon RPC 호출 | #1176 → PR #1178 ✅ |
| 2. auth.uid() NULL 가드 | upsert 인증 | PR #1178에 포함 ✅ |
| 3. Unicode 우회 | 키워드 필터 우회 | #1177 → PR #1179 ✅ |
| 5. 파괴적 부분 업데이트 | DELETE 후 INSERT 실패 | **False positive** — PostgreSQL 함수는 트랜잭션 내 실행, INSERT FK 에러 시 DELETE도 롤백됨 |
| 6. p_limit/p_days 상한 | DoS 벡터 | PR #1178에 LEAST 캡 적용 ✅ |
| 11. SELECT e.* | 데이터 노출 | PR #1178에서 명시적 컬럼 변경 ✅ |

### Actionable 항목 → 이슈 생성 (3건)
| Finding | 이슈 | 우선순위 |
|---------|------|----------|
| 4. tag_usage_daily 보유 정책 cron | #1180 | P2-medium |
| 8+9. 유출 대응 모니터링/통지 실행 경로 | #1181 | P2-medium |
| 7+10+12+13+14. 보안 하드닝 일괄 | #1182 | P3-low |

원본 리포트를 닫습니다.

### Comment 3 — @Mark-Yun on 2026-04-08

🤖 **needs-tpm-claude-1** TPM 분석 완료.

## 결과

### Skip (이미 해결됨 — 8건)
| Finding | 이유 |
|---------|------|
| #1 REVOKE/GRANT 누락 | PR #1178 / Issue #1176에서 수정 |
| #2 auth.uid() NULL 가드 | PR #1178 / Issue #1176에서 수정 |
| #3 Unicode 필터 우회 | PR #1179 / Issue #1177에서 수정 |
| #5 파괴적 upsert | False positive — PG 함수는 트랜잭션 내에서 실행, INSERT 실패 시 DELETE 자동 롤백 |
| #6 p_limit/p_days 상한 | PR #1178 / Issue #1176에서 수정 |
| #11 SELECT e.* | PR #1178 / Issue #1176에서 수정 |

### Actionable (이슈 생성됨 — 3건, 총 8개 finding 커버)
| Issue | Finding | 라벨 |
|-------|---------|------|
| #1180 | #4 (tag_usage_daily 보유 정책) | needs-arch, P2-medium |
| #1181 | #8, #9 (유출 대응 모니터링/통지) | needs-security, P2-medium |
| #1182 | #7, #10, #12, #13, #14 (보안 하드닝 일괄) | needs-swe, P3-low |

원본 리포트를 닫습니다.
