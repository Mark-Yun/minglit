# Data Retention Policies

> minglit이 보관하는 모든 데이터의 보관 기간 + 파기 정책. PIPA / 전자상거래법 / 위치정보법 / 통신비밀보호법 등의 법적 의무 + 운영 결정 결합.
> 이 문서는 `supabase/migrations/` 의 retention_policies 테이블 INSERT 문에서 자동/수동 추출. 코드가 진실, 이 문서는 mirror.

---

## 정책 테이블 구조 (admin.retention_policies)

`supabase/migrations/20260421000002_add_admin_schema_retention_policies.sql` 에서 정의.

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | text PK | 정책 식별자 (예: `location_access_log`) |
| `kind` | enum | `db_table` / `storage_bucket` / `pgmq_archive` / `db_custom_fn` |
| `retention_days` | int | 실제 적용 보관 일수 |
| `legal_min_days` | int (nullable) | 법정 최소 보관일. CHECK 제약: `retention_days >= legal_min_days` 강제 |
| `target` | jsonb | 대상 지정. `db_table` → `{schema, table, ts_col}`, `storage_bucket` → `{bucket_id, path_prefix}`, `pgmq_archive` → `{queue_name}`, `db_custom_fn` → `{fn}` |
| `enabled` | boolean | `true` = 자동 파기 대상, `false` = 방어 등록만 (자동 파기 없음) |
| `description` | text | 정책 설명 |
| `last_run_at` / `last_run_rows_deleted` / `last_run_status` | — | 최근 실행 이력 |

**enforcement 메커니즘:**
- `cleanup-retention` Edge Function이 `admin.retention_policies` 테이블을 순회하며 kind별 파기 실행
- pg_cron으로 **매일 03:00 UTC (KST 12:00)** 자동 호출 (`20260421000003_schedule_cleanup_retention_cron.sql`)
- `admin.delete_old_rows(schema, table, ts_col, cutoff_days)` — `WHERE ts_col < now() - cutoff_days * interval '1 day'`
- `admin.delete_expired_rows(schema, table, ts_col)` — `WHERE ts_col < now()` (절대 만료시각 컬럼용, archived_records에 사용)
- `admin.archive_old_pgmq_messages(queue_name, cutoff_days)` — pgmq archive (배치 500개씩)
- `admin.anonymize_old_verification_submissions(cutoff_days)` — PII 컬럼 익명화 (하드 삭제 대신)
- `admin.retention_policy_audit` 테이블에 모든 정책 변경·실행 감사 로그 기록

---

## 카테고리별 retention

### 1. 결제·정산 (전자상거래법 §6 — 5년)

| 정책 ID | 테이블 | 보관 기간 | enabled | 근거 |
|---------|--------|---------|---------|------|
| `event_applications_payment` | `public.event_applications` | 1825일 (5년) | **false** (자동 파기 없음) | 전자상거래법 §6 — 결제/계약 기록 5년 보존 |
| `tickets_payment` | `public.tickets` | 1825일 (5년) | **false** | 전자상거래법 §6 — 티켓/재화공급 기록 5년 보존 |
| `ticket_templates_payment` | `public.ticket_templates` | 1825일 (5년) | **false** | 전자상거래법 §6 — 티켓 템플릿 기록 5년 보존 |

> `enabled=false`: 자동 파기 없음. `legal_min_days=1825` CHECK 제약으로 후속 개발자가 실수로 짧은 삭제 정책 등록 시 DB에서 차단.
> 소스: `supabase/migrations/20260422000003_payment_retention_protection.sql`

---

### 2. 위치정보 (위치정보법 §16 — 6개월)

| 정책 ID | 테이블 | 보관 기간 | enabled | 근거 |
|---------|--------|---------|---------|------|
| `location_access_log` | `public.location_access_log` | 180일 (6개월) | **true** | 위치정보법 §16 — 위치정보 이용·제공 확인자료 6개월 보관 의무 |

> GPS 좌표 원문은 서버에 저장하지 않음 (방침). `location_access_log`는 "언제 누가 위치 기반 검색을 했는가"의 확인자료만 보관.
> 소스: `supabase/migrations/20260422000001_location_access_log.sql`

---

### 3. Verification (PIPA §21 + 운영 결정 — 1년)

| 정책 ID | 대상 | 보관 기간 | enabled | 파기 방식 | 근거 |
|---------|------|---------|---------|----------|------|
| `verification_submissions_proof` | `public.verification_submissions` (PII 컬럼) | 365일 (1년) | **true** | **익명화** (snapshot_data → `{}`, reviewed_by → NULL) | 개인정보처리방침 §F6: 자격 인증 제출 기록 PII 1년 후 익명화 |
| `verification_proofs_storage` | `verification-proofs` Storage 버킷 | 365일 (1년) | **true** | **하드 삭제** | PIPA §21 파기 의무 — 원본 이미지/PDF 파기 |

> 하드 DELETE 불가 이유: `partner_verified_users.submission_id ON DELETE CASCADE` → 삭제 시 활성 파트너 인증 상태 연쇄 박탈. 대신 PII 컬럼만 익명화하고 레코드 골격(user_id, status 등)은 보존.
> 소스: `supabase/migrations/20260422000007_verification_retention.sql`

---

### 4. Tag / 분석 (운영 결정 — 2년 후 월별 압축)

| 대상 | 보관 기간 | 처리 방식 | 근거 |
|------|---------|----------|------|
| `public.tag_usage_daily` | 2년 (일별 원본) | 2년 초과분 → `tag_usage_monthly`에 월별 집계 후 일별 원본 삭제 | Security Audit #1175 Finding 4 데이터 최소화 원칙 |
| `public.tag_usage_monthly` | 무기한 | 집계 데이터 보존 (통계 트렌드) | 운영 결정 |

> pg_cron `compress-old-tag-usage-daily` 매월 1일 04:00 UTC 실행.
> retention_policies 테이블 미등록 (별도 cron으로 직접 관리).
> 소스: `supabase/migrations/20260409000003_tag_usage_daily_retention.sql`

---

### 5. 사기/분쟁 기록 (개인정보처리방침 §F5 — 1년)

| 정책 ID | 테이블 | 보관 기간 | enabled | 근거 |
|---------|--------|---------|---------|------|
| `report_details_fraud_record` | `public.report_details` | 365일 (1년) | **true** | 개인정보처리방침 §F5 — 신고 기록 1년 후 파기 |
| `blocked_dis_fraud_record` | `public.blocked_dis` | 365일 (등록만) | **false** | ⚠️ TTL 불일치: EF가 30일 TTL로 삭제 중 vs 처리방침 선언 1년. legal-reviewer 컨설트 필요 |

> `blocked_dis` 불일치: `cleanup-blocked-dis` EF가 `blocked_until < now()` (실질 30일 TTL)로 삭제 중이나 개인정보처리방침은 1년 선언. `enabled=false`로 추적 등록만. 법적 검토 후 처리방침 개정(30일로 단축) 또는 EF TTL 연장(1년) 결정 필요.
> 소스: `supabase/migrations/20260422000005_fraud_record_retention.sql`

---

### 6. Archived records (소프트 삭제 후 만료 파기)

| 정책 ID | 테이블 | 보관 기간 | enabled | 파기 방식 | 근거 |
|---------|--------|---------|---------|----------|------|
| `archived_records_expired` | `public.archived_records` | 1826일 (5년+1일) / `retention_until` 컬럼 기준 | **true** | 하드 DELETE (`retention_until < now()`) | 전자상거래법 §6 + PIPA §21 — archive의 `retention_until` 경과 후 파기 |

> `use_absolute_ts: true` — `ts_col = retention_until`은 cutoff_days 계산이 아닌 절대 만료시각. `admin.delete_expired_rows()` 함수 사용.
> `legal_min_days=1825`: 결제 관련 archive는 최소 5년 보장.
> 소스: `supabase/migrations/20260422000002_archived_records_retention.sql`

---

### 7. 인프라 / 운영 로그 (운영 결정)

| 정책 ID | 대상 | 보관 기간 | enabled | 근거 |
|---------|------|---------|---------|------|
| `cron_job_run_details` | `cron.job_run_details` | 30일 | true | pg_cron 실행 이력 — 운영 결정 |
| `net_http_response` | `net._http_response` | **14일** (Fix #1759: 7일 → 14일 연장) | true | net.http_post 응답 로그. 디버깅 시 24h cleanup으로 로그 소실 방지 (#1758) |
| `pgmq_global_events_archive` | pgmq `global_events` 큐 archive | 14일 | true | global_events 큐 archive — 운영 결정 |
| `pgmq_vectors_archive` | pgmq `vectors` 큐 archive | 14일 | true | vectors 큐 archive (pgvector 비동기) |
| `pgmq_notifications_archive` | pgmq `notifications` 큐 archive | 7일 | true | notifications 큐 archive |
| `storage_bug_reports` | `bug-report-attachments` Storage 버킷 | 30일 | true | QA 버그 리포트 첨부파일 |

> 소스: `supabase/migrations/20260421000002_add_admin_schema_retention_policies.sql` (초기 seed), `20260423000002_extend_net_http_response_retention.sql` (net_http_response 연장)

---

## 파기 메커니즘

**자동 파기 (enabled=true):**
- pg_cron `cleanup-retention` → `cleanup-retention` Edge Function → `admin.retention_policies` 순회
- 매일 03:00 UTC (KST 12:00) 실행
- kind별 실행 함수:
  - `db_table` → `admin.delete_old_rows(schema, table, ts_col, retention_days)`
  - `db_table` + `use_absolute_ts` → `admin.delete_expired_rows(schema, table, ts_col)`
  - `db_custom_fn` → target.fn 직접 호출 (예: `admin.anonymize_old_verification_submissions`)
  - `storage_bucket` → Storage API로 파일 삭제
  - `pgmq_archive` → `admin.archive_old_pgmq_messages(queue_name, retention_days)`

**수동 파기:**
- super_admin이 `admin.retention_policies`를 직접 업데이트하거나 admin RPC 호출

**소프트 삭제 vs 하드 삭제:**
- 소프트 삭제: `archived_records`에 아카이빙 후 `retention_until` 컬럼으로 만료 관리 → 만료 후 하드 삭제
- 하드 삭제: `admin.delete_old_rows()` / `admin.delete_expired_rows()` — 복구 불가
- 익명화 (pseudo-deletion): `verification_submissions` — FK 무결성 유지 위해 PII 컬럼만 제거, 레코드 골격 보존

**감사 로그:**
- `admin.retention_policy_audit` 테이블에 모든 정책 변경 (create/update/delete/enable/disable) + 실행 이력 기록

---

## 컴플라이언스 매핑

| 법령 | 조항 | 의무 | minglit 대응 |
|------|------|------|-------------|
| **PIPA §21** | 파기 의무 | 목적 달성 후 파기 | retention_policies 파이프라인 전체 |
| **PIPA §21** | 파기 의무 | 자격 인증 증빙 파기 | `verification_submissions_proof` (익명화) + `verification_proofs_storage` (하드 삭제) |
| **위치정보법 §16** | 확인자료 6개월 보관 | 위치정보 수집·이용 확인자료 6개월 | `location_access_log` retention_days=180, enabled=true |
| **전자상거래법 §6** | 거래기록 5년 보존 | 계약·청약철회 5년, 소비자불만·분쟁처리 3년 | `event_applications_payment`, `tickets_payment`, `ticket_templates_payment` (enabled=false, legal_min_days=1825) |
| **전자상거래법 §6** | 거래기록 5년 보존 | archive 파기 방어 | `archived_records_expired` legal_min_days=1825 |
| **통신비밀보호법 §15-2** | 접속 기록 3개월 보관 | 로그인·접속 기록 3개월 | ⚠️ **미구현** — `auth.audit_log_entries` retention 정책 없음 (이슈 #1706) |
| **개인정보처리방침 §F5** | 부정 이용 기록 1년 | 신고 기록 1년 | `report_details_fraud_record` (enabled=true) |
| **개인정보처리방침 §F5** | 부정 이용 기록 1년 | 기기 차단 목록 1년 | `blocked_dis_fraud_record` (enabled=false — TTL 불일치, 법적 검토 대기) |
| **개인정보처리방침 §F6** | 자격 인증 증빙 1년 | 인증 제출 PII + 증빙 파일 | `verification_submissions_proof` + `verification_proofs_storage` |

---

## 알려진 갭

| 이슈 | 내용 | 상태 |
|------|------|------|
| #1706 | 통신비밀보호법 접속 기록 3개월 retention — `auth.audit_log_entries` 정책 미구현 | 진행 중 |
| #1703 | `archived_records` 5년 방어 설계 완성 | 완료 (`archived_records_expired` 등록) |
| #1704 | 결제 레코드 5년 방어 | 완료 (`event_applications_payment` 등 등록) |
| #1705 | 소비자불만·분쟁 3년 retention 정책 미구현 | 진행 중 |
| — | `blocked_dis` TTL 불일치 (30일 EF vs 처리방침 1년) | ⚠️ legal-reviewer 컨설트 필요 |
| — | `tag_usage_daily` retention_policies 테이블 미등록 (별도 cron 직접 관리) | 추적 갭 |

---

## 참조

- 코드: `supabase/migrations/20260421000002_add_admin_schema_retention_policies.sql` (베이스 테이블 + 인프라 seed)
- 코드: `supabase/migrations/20260421000003_schedule_cleanup_retention_cron.sql` (cron 스케줄)
- 코드: `supabase/migrations/20260422000001_location_access_log.sql` (위치정보법)
- 코드: `supabase/migrations/20260422000002_archived_records_retention.sql` (archived_records)
- 코드: `supabase/migrations/20260422000003_payment_retention_protection.sql` (결제 5년 방어)
- 코드: `supabase/migrations/20260422000005_fraud_record_retention.sql` (사기 기록)
- 코드: `supabase/migrations/20260422000007_verification_retention.sql` (자격 인증)
- 코드: `supabase/migrations/20260423000002_extend_net_http_response_retention.sql` (net_http_response 연장)
- 코드: `supabase/migrations/20260409000003_tag_usage_daily_retention.sql` (tag 압축)
- 관련 audit: `docs/reports/security/2026-04-22-issue1744-*.md` (retention RPC 위험 지적)
- 관련 문서: `docs/background/legal-context.md` §1 (PIPA), §2 (위치정보법), §3 (전자상거래법)
