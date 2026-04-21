# 개인정보 보유기간 선언 ↔ 구현 매핑

**Owner**: legal-reviewer
**개정**: 2026-04-22 (초판)
**관련 PR/이슈**: #1695 (audit) · #1693 (retention_policies 인프라) · #1692

> **⚠️ 의존성 경고**: 이 문서의 "구현" 경로 중 `admin.retention_policies` 를 경유하는 항목은
> **PR #1693이 `dev`에 머지되어야 실제 집행 가능**하다. PR #1693은 2026-04-22 기준 아직 OPEN 상태이다.
> 해당 항목의 상태가 **GAP** 또는 **TBD**로 표시된 이유는 인프라 미머지도 포함한다.
> PR #1693 머지 후 이 문서의 "현재 구현" 컬럼을 재검토하라.

---

## 이 문서의 목적

`apps/landing_user/src/app/privacy/page.tsx`에 고지한 개인정보 보유기간을
실제 DB/Storage/Edge Function 구현과 1:1로 매핑한다.

**왜 필요한가**
- **PIPA 제21조** 개인정보 파기 의무 — 방침에 고지한 기간이 지나면 파기했다는 증빙을 제출할 수 있어야 한다.
- **전자상거래법 제6조** 계약·결제·분쟁 기록 **최소 5년/3년 보존** — 개발자가 실수로 먼저 삭제하지 않도록 집행 방어가 필요하다.
- **위치정보법 제16조** 위치정보 이용·제공 확인자료 6개월 보존 — 선언만 있고 구현이 없으면 허위 고지가 된다.
- **통신비밀보호법 제15조의2** 접속 기록 3개월 보존.

이 표 한 장이 개인정보보호위원회 조사 시 "선언–집행 일치"를 증명하는 근거다.

---

## 매핑 원칙

1. **선언(declaration)** — 처리방침에 서면으로 고지한 보유기간.
2. **구현(implementation)** — 다음 셋 중 하나 이상으로 증명되어야 한다.
   - `admin.retention_policies`에 정책 등록 (자동 cleanup 파이프라인, PR #1693)
   - `process-pending-deletions` 플로우에서 `archived_records`로 이관 후 `retention_until` 경과 시 자동 파기
   - 코드 주석 + 테스트로 "저장하지 않음/즉시 파기"를 증명
3. **법적 최소(legal_min_days)** — 법정 의무 보존(예: 전자상거래법 5년)이 있는 테이블은 반드시
   `admin.retention_policies.legal_min_days`를 채워야 한다. 이 컬럼은 CHECK 제약(`retention_above_legal_min`)으로
   **더 짧은 retention_days 입력을 거절**해, 후속 개발자가 실수로 5년 미만으로 삭제 스크립트를 만드는 것을 차단한다.

### legal_min_days 사용 규칙

- **채워야 하는 경우**: 법정 최소 보존기간이 있는 데이터
  (결제 레코드 / 계약 / 분쟁 / 접속 로그 / 위치 이용 로그).
- **NULL이어도 되는 경우**: 순수 운영 로그, 시스템 내부 큐 등 법적 의무가 없는 데이터.
- **retention_days >= legal_min_days** 제약 위반 시 INSERT 자체가 거절된다. 이 특성을 신뢰하고
  신규 정책 추가 시 legal_min_days를 **항상 먼저** 지정하라.

예시:
```sql
-- 전자상거래법 §6 5년 최소 보존 — retention_days를 1825 미만으로 내릴 수 없음
INSERT INTO admin.retention_policies
  (id, kind, retention_days, legal_min_days, target, description)
VALUES
  ('archived_payments', 'db_table', 1830, 1825,
   '{"schema":"public","table":"archived_records","ts_col":"retention_until"}',
   '전자상거래법 §6 — 결제/재화공급 5년 보존');
```

---

## 1) 선언 vs 구현 매트릭스 (2026-04-22 현재)

| # | 선언 (처리방침) | 법적 근거 | 대상 테이블/버킷 | 현재 구현 | legal_min_days | 상태 |
|---|----------------|-----------|------------------|-----------|----------------|------|
| 1 | 계약/청약철회 기록 5년 | 전자상거래법 §6 | `public.archived_records` (record_type='contract') | `process-pending-deletions`에서 archive, **`retention_until` 경과 후 자동 파기는 미구현** | 필요 (1825) | **GAP** |
| 2 | 대금결제/재화공급 기록 5년 | 전자상거래법 §6 | `public.archived_records` (record_type='payment') | 동상 | 필요 (1825) | **GAP** |
| 3 | 소비자 불만/분쟁 처리 3년 | 전자상거래법 §6 | `public.archived_records` (record_type='dispute') | 동상 | 필요 (1095) | **GAP** |
| 4 | 접속 기록 3개월 | 통신비밀보호법 §15-2 | `public.archived_records` (record_type='login') / `auth.audit_log_entries` | 동상 + `auth.audit_log_entries`는 Supabase 관리 | 필요 (90) | **GAP** |
| 5 | 마케팅 동의 기록 2년 | PIPA §22-2, 내부 정책 | `public.archived_records` (record_type='consent') | 동상 | 없음(내부) | **GAP** (자동 파기 없음) |
| 6 | 위치 확인자료 6개월 | 위치정보법 §16 | **테이블 미존재** | ❌ 미구현 | 필요 (180) | **CRITICAL GAP — 허위 고지** |
| 7 | 파트너 제공 참여자 정보 — 이벤트 종료 후 30일 | PIPA §21 목적 달성 후 파기 | `public.event_participants` (또는 파생 뷰) | ❌ 자동 파기 없음 | 없음 | **GAP** |
| 8 | 자격 인증 증빙 1년 | 내부 정책 | `verification-proofs` 버킷 (Storage) + `public.verification_submissions` (메타/이력) | ❌ 자동 파기 없음 — Storage 버킷 만료 정책 미설정, DB 레코드 삭제 job 없음 | 없음 | **GAP** |
| 9 | 부정 이용 기록 1년 | 내부 정책 | `public.blocked_dis` (`blocked_until` TTL 30일), 기타 | 부분 — `blocked_dis`는 30일 TTL, "1년 보존" 대상 테이블 식별 필요 | 없음 | **TBD** |
| 10 | 관심 태그, 이용 기록, 기기 정보 — 탈퇴 시 즉시 파기 | PIPA §21 | `public.user_interest_tags` (관심 태그) · `public.fcm_tokens` (기기 토큰) | `process-pending-deletions` EF에서 각 테이블이 삭제되는지 검증 필요 | — | **VERIFY** |
| 11 | 임베딩 벡터 — 탈퇴 시 즉시 파기 | PIPA §21 | `public.user_embeddings` · `public.party_embeddings` | `process-pending-deletions` EF에서 삭제되는지 검증 필요 | — | **VERIFY** |
| 12 | GPS 좌표 — 검색 요청 처리 완료 즉시 파기 (서버 영구 저장 없음) | 위치정보법 §16 | 서버 미저장 원칙 | Edge Function 내 메모리 처리 가정 — 코드 주석 + 테스트로 증명 필요 | — | **VERIFY** |

### `admin.retention_policies` seed 예정 (PR #1693 머지 후 반영 — 2026-04-22 기준 미머지)

| id | kind | retention_days | legal_min_days | 비고 |
|----|------|----------------|-----------------|------|
| `cron_job_run_details` | db_table | 30 | NULL | pg_cron 실행 이력 (운영 로그) |
| `net_http_response` | db_table | 7 | NULL | net.http_post 응답 로그 |
| `pgmq_global_events_archive` | pgmq_archive | 14 | NULL | global_events 큐 |
| `pgmq_vectors_archive` | pgmq_archive | 14 | NULL | vectors 큐 |
| `pgmq_notifications_archive` | pgmq_archive | 7 | NULL | notifications 큐 |
| `storage_bug_reports` | storage_bucket | 30 | NULL | QA 버그 리포트 첨부 |

→ 6개 정책 모두 법적 의무가 없는 운영 로그. **개인정보 보유기간과의 매핑은 0건.**

---

## 2) 집행 우선순위 (follow-up 이슈로 분리)

아래는 `needs-arch` / `needs-swe`로 넘길 작업 단위다. 순서는 법적 리스크 기준.

### P1-URGENT — "허위 고지" 상태

#### F1. 위치 확인자료 6개월 보관 로그 (위치정보법 §16)

**현재**: 방침에 "위치정보법에 따른 자동 기록 확인자료(이용 일시·처리 사실)는 6개월간 보관하며, GPS 좌표 원문은 보관하지 않습니다"라고 선언. 대응 테이블 없음.

**필요 조치**:
1. `public.location_access_log` 신설 — 컬럼: `user_id`, `accessed_at`, `purpose`('nearby_search' 등), `country_code`(선택). **GPS 좌표 자체는 저장 금지**.
2. 주변 검색 Edge Function / API에서 access 발생 시 INSERT.
3. `admin.retention_policies`에 등록:
   ```sql
   INSERT INTO admin.retention_policies
     (id, kind, retention_days, legal_min_days, target, description)
   VALUES
     ('location_access_log', 'db_table', 180, 180,
      '{"schema":"public","table":"location_access_log","ts_col":"accessed_at"}',
      '위치정보법 §16 — 위치정보 이용·제공 확인자료 6개월');
   ```
4. pgTAP 테스트: retention_policies에서 정책이 조회되고 legal_min_days=180인지 확인.

### P1 — 전자상거래법 증빙 가능 상태 확보

#### F2. archived_records 자동 파기 + 법적 최소 보존 방어

**현재**: `public.archived_records.retention_until`이 passed되어도 실제 파기가 일어나지 않는다 (삭제 job 없음). 따라서 5년을 훨씬 넘긴 데이터가 쌓이는 구조.

**필요 조치**:
1. `admin.retention_policies` 4개 정책 추가 (record_type별 분리 or 단일 정책 + app-level filter). 단일 정책 접근 시:
   ```sql
   INSERT INTO admin.retention_policies
     (id, kind, retention_days, legal_min_days, target, description)
   VALUES
     ('archived_records_expired', 'db_table', 1830, 1825,
      '{"schema":"public","table":"archived_records","ts_col":"retention_until","condition":"retention_until < now()"}',
      '전자상거래법 §6 기반 archive의 retention_until 경과 후 파기');
   ```
   — `admin.delete_old_rows` 도우미 RPC는 현재 `WHERE ts_col < now() - cutoff_days * interval '1 day'` 형식이라,
   `retention_until`을 그대로 쓰려면 헬퍼를 확장(`p_strict_ts_col` 같은 모드 추가)하거나 별도 RPC를 만들어야 한다. **구현 시 설계 판단 필요**.
2. 또는 record_type별 4개 독립 정책 + `archive_retention_days` 열(이미 `retention_until`에 계산돼 있음) 활용.
3. pgTAP: retention_until=yesterday 레코드가 cleanup 후 삭제되는지.

#### F3. 결제 레코드 삭제 방어 (전자상거래법 §6 5년)

**현재**: `archived_records`만 보호하고, **활성 사용자의 결제 레코드가 저장된 원본 테이블(`public.payments` 등)은 retention 정책이 없다**. 후속 개발자가 청소 스크립트로 active 결제 데이터를 5년 미만에 지우는 것을 막을 수단이 없다.

**필요 조치**:
1. 결제 원본 테이블 식별 (아키텍트가 판단). `public.payments`, `public.event_applications` 등.
2. 해당 테이블에 대해 `retention_days=∞` 정책을 둘 수는 없으므로 **보존 방어용 메타 정책**을 `admin.retention_policies`에 `enabled=false` + `legal_min_days=1825`로 등록해 "이 테이블은 5년 이상 보존해야 함"을 DB 차원에서 문서화.
3. 또는 별도 `admin.retention_protected_tables` 테이블 신설을 architect가 검토.

### P2 — 선언 일관성 유지

#### F4. event_participants 이벤트 종료 후 30일 파기

**현재**: "파트너에게 제공한 참여자 정보는 이벤트 종료 후 30일 후 파기"를 선언. 자동 파기 없음.

**필요 조치**:
1. `event_participants` 테이블 또는 `event_partner_shared_data` 뷰에 대한 정책 등록.
2. `ts_col`은 이벤트의 `ended_at` 또는 `event_at + duration`. `admin.delete_old_rows`가 JOIN을 지원하지 않으므로
   **보조 뷰 또는 materialized column**이 필요하다 (architect 판단).

#### F5. blocked_dis / 부정 이용 기록 1년 정책 명문화

**현재**: `public.blocked_dis.blocked_until`은 30일(`BLOCKED_DI_DAYS=30`) TTL이지만, "부정 이용 기록 1년"은 별도 테이블에 있어야 한다. 어느 테이블이 해당하는지 식별 필요.

#### F6. 자격 인증 증빙 1년 정책 명문화

**현재**: 자격 인증 서류는 `verification-proofs` 버킷(private)에 저장되고, 메타데이터·이력은 `public.verification_submissions`에 기록된다 (`apps/app_user/lib/src/features/event/admission/wizard_verification_step.dart:113` 참조). 두 곳 모두 1년 후 자동 파기 정책 없음.

**필요 조치**:
1. Storage: `verification-proofs` 버킷에 Supabase Storage TTL 또는 `admin.retention_policies` `storage_bucket` kind 정책 등록.
2. DB: `public.verification_submissions`에 대해 `created_at` 기준 1년 삭제 정책 등록. 단, 심사 이력(법적 분쟁 근거)이므로 파기 전 `archived_records`로 이관하는 방식이 바람직한지 architect 검토 필요.
3. `public.user_verifications` (사용자 인증 캐시 레코드)도 동일 기간 정책 적용 여부 검토.

### P2 — 약속 이행 검증

#### F7. 탈퇴 시 즉시 파기 약속 검증 (pgTAP)

**대상 테이블 (실제 DB 객체)**:
- `public.user_interest_tags` — 관심 태그
- `public.fcm_tokens` — 기기 토큰 (`supabase/migrations/20260301000005_05_schema_system.sql:30`)
- `public.user_embeddings` — 사용자 임베딩 (`supabase/migrations/20260301000002_02_schema_core.sql:24`)
- `public.party_embeddings` — 파티 임베딩 (`supabase/migrations/20260301000003_03_schema_events.sql:30`)

**필요 조치**:
1. `process-pending-deletions` EF가 위 4개 테이블을 실제로 비우는지 각각 pgTAP 테스트 추가.
2. 누락된 테이블 있으면 EF 로직 보강.

#### F8. GPS 좌표 "서버 미저장" 증명

**필요 조치**: 주변 검색 EF / 쿼리 경로에 GPS 좌표가 **어디에도 INSERT되지 않음**을 단위 테스트 또는 정적 분석(코드 리뷰 체크리스트)으로 증명.

---

## 3) 신규 retention_policies 추가 절차 (개발자용)

개인정보를 포함하는 신규 테이블을 추가할 때 다음 절차를 따른다.

1. **법적 근거 식별** — PIPA/전자상거래법/통신비밀보호법/위치정보법/내부 정책 중 어느 쪽인가.
2. **legal_min_days 결정** — 법정 최소 보존 있으면 일수 계산. 없으면 NULL.
3. **retention_days 결정** — 최소 보존 + 버퍼 (예: 5년 의무 + 5일 = 1830).
4. **Migration 작성** — `admin.retention_policies`에 INSERT. legal_min_days 반드시 기재.
5. **pgTAP 추가** — 정책이 등록됐고 `enabled=true`이며 `retention_days >= legal_min_days`임을 확인.
6. **`docs/legal/retention-map.md` 업데이트** — 본 문서의 매트릭스에 행 추가. status = `implemented`로 표시.
7. **처리방침 동기화** — 신규 개인정보 카테고리면 `apps/landing_user/src/app/privacy/page.tsx` 개정 검토 후 legal-reviewer에게 `needs-legal` 라우팅.

---

## 4) 처리방침 개정 시 역방향 체크리스트

처리방침(`apps/landing_user/src/app/privacy/page.tsx`)이 개정되면 legal-reviewer는 **반드시** 다음을 확인한다.

- [ ] 신규 수집 항목의 저장 위치(테이블/버킷)가 식별됐는가.
- [ ] 신규 보유기간 선언이 `admin.retention_policies` 또는 `archived_records` 플로우로 집행 가능한가.
- [ ] 본 문서(`docs/legal/retention-map.md`)에 신규 행이 추가됐는가.
- [ ] legal_min_days가 필요한 선언이라면 정책 INSERT에 포함됐는가.
- [ ] "즉시 파기" 약속은 테스트로 증명됐는가.

개정일자가 바뀌었는데 위 항목 중 하나라도 미충족이면 `report-exec` 라벨로 블로커 선언.

---

## 5) 참조

- `apps/landing_user/src/app/privacy/page.tsx` — 사용자 선언 원문
- `supabase/migrations/20260421000002_add_admin_schema_retention_policies.sql` — PR #1693
- `supabase/migrations/20260330000005_account_deletion.sql` — archived_records 스키마
- `supabase/functions/process-pending-deletions/index.ts` — 탈퇴 시 아카이브 로직
- 법령: 개인정보보호법(PIPA), 전자상거래법, 통신비밀보호법, 위치정보의 보호 및 이용 등에 관한 법률
