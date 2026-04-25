---
source_url: https://github.com/Mark-Yun/minglit/issues/1695
captured_at: 2026-04-21
issue_number: 1695
state: closed
labels: [P1-high, audit-report]
author: Mark-Yun
title: "[Audit-Legal] 개인정보처리방침 선언 보유기간 ↔ retention_policies 매핑 공백 — PIPA/전자상거래법/통신비밀보호법/위치정보법 전반"
---

# [Audit-Legal] 개인정보처리방침 선언 보유기간 ↔ retention_policies 매핑 공백 — PIPA/전자상거래법/통신비밀보호법/위치정보법 전반

> Issue #1695 · closed · created 2026-04-21T21:04:14Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1695

## Body

Scheduler: audit-legal-claude-subagents

## 배경

PR #1693(이슈 #1692)에서 `admin.retention_policies` 파이프라인이 새로 도입됐다. 스키마 자체는 훌륭하다 — `legal_min_days` 컬럼 + `retention_above_legal_min` CHECK로 "법정 최소보관기간보다 짧게 설정하면 insert 자체가 거절"되는 강력한 방어 수단을 마련했다.

다만 **seed된 6개 정책 모두 `legal_min_days = NULL`이며, 대상 또한 운영 로그(cron/net/pgmq/bug-report-attachments)에 한정**돼 있다. 개인정보처리방침(`apps/landing_user/src/app/privacy/page.tsx`)에서 사용자에게 선언한 **PIPA·전자상거래법·통신비밀보호법·위치정보법상 보유기간 약속이 단 하나도 이 파이프라인에 매핑되지 않았다**.

선언만 있고 집행이 없는 상태가 지속되면 다음 리스크가 발생한다:
- **개인정보보호위원회 조사 시**, 방침에 고지한 "30일 후 파기"를 실제로 이행했다는 증빙을 제출할 수 없다 (PIPA 제21조 — 파기 의무, 위반 시 과태료).
- 개발자가 신규 테이블을 추가하면서 의도치 않게 5년 이하로 결제 기록을 삭제하는 cleanup을 작성해도 **legal_min_days 방어가 seed에 없어서 통과**된다 — 전자상거래법 제6조 위반.

## 선언 vs 구현 매핑 (현 상태)

| 개인정보처리방침 고지 | 법적 근거 | 현재 자동 cleanup | 공백 |
|------|------|------|------|
| 계약/청약 철회 5년 | 전자상거래법 §6 | ❌ 없음 (보존 보호 없음) | **HIGH** — 삭제 방지 정책 필요 |
| 결제/재화공급 5년 | 전자상거래법 §6 | ❌ 없음 | **HIGH** |
| 소비자 불만/분쟁 처리 3년 | 전자상거래법 §6 | ❌ 없음 | HIGH |
| 로그인/접속 기록 3개월 | 통신비밀보호법 §15-2 | ❌ 없음 | HIGH (auth.audit_log_entries 경로) |
| 위치 확인자료 6개월 | 위치정보법 §16 | ❌ 없음 (선언만 존재) | HIGH |
| 자격 인증 증빙 1년 | 내부 정책 | ❌ 없음 | MEDIUM |
| 부정 이용 기록 1년 | 내부 정책 | ❌ 없음 | MEDIUM |
| 이벤트 종료 후 참여자 정보 30일 | 목적 달성 후 파기(PIPA §21) | ❌ 없음 (event_participants) | **HIGH** |
| 관심 태그/기기 정보 — 탈퇴 시 즉시 파기 | PIPA §21 | ✅ 일부 (archive on delete) | 검증 필요 |
| 임베딩 벡터 — 탈퇴 시 즉시 파기 | PIPA §21 | 검증 필요 | MEDIUM |
| 운영 로그 (cron/net/pgmq/bug-report) | 내부 | ✅ PR #1693 | — |

> 출처: `apps/landing_user/src/app/privacy/page.tsx` 라인 58–100, 215–231.

## 권고 조치

### 1. `docs/legal/retention-map.md` 신설 (legal-reviewer 소유)

| 컬럼 | 내용 |
|------|------|
| declared_period | 개인정보처리방침에 고지한 기간 |
| legal_basis | 법적 근거 조문 |
| data_location | 해당 DB 테이블/Storage 버킷/외부 시스템 |
| retention_policy_id | `admin.retention_policies.id` (구현 시) |
| legal_min_days | 최소 보존기간(의무 보존인 경우) |
| status | implemented / gap / declared-only |

이 표가 개인정보보호위원회 증빙의 핵심이 된다. 방침이 개정될 때마다 이 표를 먼저 갱신하고, 테이블에 선언과 집행 차이를 드러나게 한다.

### 2. PR #1693 머지 **전/후**로 seed에 `legal_min_days` 지정

운영 로그조차도 장래 결제/감사 데이터가 추가될 때 안전장치가 켜지도록, 설령 현재 seed엔 적용 대상이 없더라도 legal_min_days 사용 예시를 주석으로라도 남겨두자. 예:

```sql
-- 법적 최소 보존이 있는 테이블 예시 (실제 추가 시 아래 형태로 작성):
-- INSERT INTO admin.retention_policies (id, kind, retention_days, legal_min_days, target, description)
-- VALUES ('payments_core', 'db_table', 1830, 1825, '{...}', '전자상거래법 §6 — 5년 최소 보존');
```

### 3. 긴급 구현 스택 (우선순위 순)

1. **위치 확인자료 6개월 보관 로그** — 위치정보법 §16 의무. 현재 선언만 있고 대응 테이블이 없으면 "선언 위증" 상태.
2. **event_participants 30일 후 파기** (이벤트 종료 시점 기준). 방침에 명시된 구체 일수로 시용자가 삭제 권리를 약속받았다.
3. **PortOne 결제 레코드 보존 보호** — `legal_min_days = 1825` 정책을 등록해, 후속 개발자가 실수로 삭제 스크립트를 작성할 때 CHECK 제약으로 차단.
4. 접속 로그 3개월 정책 (auth.audit_log_entries 연계).

### 4. 탈퇴 파기 검증

방침은 "관심 태그/기기 정보/임베딩 벡터 — 탈퇴 시 즉시 파기"를 약속한다. `account_deletion` 플로우가 해당 테이블들까지 전부 clear하는지 pgTAP로 증명하는 테스트 추가.

## 판단 요약

- PR #1693 자체는 **머지 저지 사유 아님** (인프라 도입). 정상 머지 진행.
- 단, **선언-집행 일관성 작업을 별도 이슈로 따라붙여야** 처리방침이 빈 약속이 되지 않는다.
- `legal_min_days` 컬럼 설계 👍 — SWE가 이 설계 의도를 이해하고 후속 정책에 반드시 활용하도록 `docs/legal/retention-map.md`에 사용 가이드 포함.

## 후속 라벨링

- `needs-legal` → 이 audit-report 자체를 legal-reviewer가 후속 검토 (본 작성자가 legal-reviewer이므로 추가 문서 작업 수행하면 됨)
- `needs-arch` → 구현 설계(어떤 테이블을 policy에 추가할지)
- `needs-swe` → 실제 migration + retention_policies seed PR
- 병행 `needs-qa` → pgTAP 회귀 테스트 계획


## Comments (5)

### Comment 1 — @Mark-Yun on 2026-04-21

🤖 **needs-legal-claude-1** 작업 시작합니다.

핵심 산출물 계획:
1. `docs/legal/retention-map.md` 신설 — 개인정보처리방침 선언 vs 구현 매핑 표 (legal-reviewer 소유 문서)
2. 감사 권고를 우선순위별 후속 이슈로 분해 — 구현 티켓은 `needs-arch`/`needs-swe`로 라우팅
3. 본 이슈는 문서 작성 완료 시점에 후속 이슈들로 대체 후 `needs-arch` 전환 예정

### Comment 2 — @Mark-Yun on 2026-04-21

🤖 **needs-legal-claude-1** 1차 처리 완료.

## 산출물

- **PR #1696** — `docs/legal/retention-map.md` 신설 (선언 ↔ 구현 매트릭스 + F1~F8 분해)
- **이슈 #1697** — F1 (P1-URGENT): 위치 확인자료 6개월 로그 — 위치정보법 §16 허위 고지 해소, `needs-arch` 라우팅

## 매트릭스 핵심 결과

| 상태 | 건수 |
|------|------|
| CRITICAL GAP (허위 고지) | 1 (위치정보법 §16) |
| GAP | 6 (전자상거래 5년·3년, 통비법 3개월, 마케팅 2년, 이벤트 파트너 30일) |
| VERIFY | 3 (탈퇴 즉시 파기 약속들) |
| TBD | 2 (자격 인증 1년 / 부정 이용 1년 대상 식별) |

## 이후 처리

F2~F8 (7개 후속 작업)은 문서 §2에 우선순위별로 분해됐다. 단순히 이슈 7개를 한꺼번에 까는 대신, **본 이슈를 트래커로 유지**하고 `needs-tpm` 라벨을 붙여 **TPM이 스프린트 배분을 판단**하도록 넘긴다:

- **F2/F3** (P1): archived_records 자동 파기 + 활성 결제 테이블 5년 방어 — `admin.delete_old_rows` RPC 설계 확장 판단 필요
- **F4~F6** (P2): event_participants 30일, 부정 이용 1년, 자격 인증 1년 — 대상 테이블 식별 선행 필요
- **F7/F8** (P2): 탈퇴 즉시 파기 pgTAP 검증 + GPS 코드 경로 증명

TPM이 F2/F3 먼저 이슈로 분리해 `needs-arch` 넘기는 것을 권장. F4~F8은 동일 스프린트에 소화 가능하면 묶고, 아니면 개별 이슈화.

라벨 전환: `needs-legal` 제거 → `needs-tpm` 부여.

### Comment 3 — @Mark-Yun on 2026-04-22

🤖 **tpm-exec-report-claude-subagents** 트리아지

## F2~F8 후속 이슈 생성 보류

PR #1696 (retention-map.md)이 아직 CHANGES_REQUESTED 상태이고 reviewer가 F7 대상 테이블 / Row 10-11 (탈퇴 즉시 파기) 경로를 재지정 요구중이다. 지금 F2~F8을 이슈로 까면 spec이 바뀔 때마다 본문 churn이 생긴다.

**대기 조건**: PR #1696 머지
**머지 후 TPM 조치**:
- F2/F3 먼저 이슈화 → `needs-arch` (delete_old_rows RPC 설계 판단 필요)
- F4/F5/F6 개별 이슈화 → `needs-arch` (대상 테이블 식별 필요)
- F7 pgTAP 검증, F8 GPS 미저장 증명 → `needs-swe`

본 이슈는 트래커로 계속 유지. `needs-tpm` 라벨 유지 (PR #1696 머지 감지하면 재진입).

## 참고 진행 상황

- F1 (위치정보법 §16) — 완료. 이슈 #1697 closed, PR #1698 머지됨.
- 기타 F2~F8 — PR #1696 머지 대기중.

### Comment 4 — @Mark-Yun on 2026-04-22

🤖 **needs-tpm-claude-1** 트리아지 완료.

## 분석 결과

audit-legal 리포트의 F1~F8 actionable 분해는 PR #1696 (retention-map.md) 본문에 이미 수행되어 있었다.

| 항목 | 상태 |
|------|------|
| F1 — 위치 확인자료 6개월 보관 로그 (위치정보법 §16) | ✅ #1697 완료 (PR #1694 머지) |
| F2 — archived_records 자동 파기 + legal_min_days 방어 | ✅ #1703 파일링 (P1, needs-arch) |
| F3 — 결제 레코드 원본 테이블 삭제 방어 | ✅ #1704 파일링 (P1, needs-arch) |
| F4 — event_participants 30일 파기 | ✅ #1705 파일링 (P2, needs-arch) |
| F5 — 부정 이용 기록 1년 대상 테이블 식별 | ✅ #1706 파일링 (P2, needs-arch) |
| F6 — 자격 인증 증빙 1년 정책 | ✅ #1707 파일링 (P2, needs-arch) |
| F7 — 탈퇴 즉시 파기 pgTAP 검증 | ✅ #1708 파일링 (P2, needs-qa) |
| F8 — GPS 서버 미저장 증명 | ✅ #1709 파일링 (P2, needs-qa) |

## 라우팅 판단

- F2~F6은 설계 판단이 필요 ( 헬퍼 확장, 단일 vs per-type 정책, 보호 메타 정책 vs 신규 테이블, materialized column/뷰 등) → 
- F7, F8은 기존 구현 검증 테스트 성격 → 
- PR #1696이 retention-map.md를 dev에 landing시키면 각 이슈에서 §2 참조가 유효해진다. 현재는 PR 본문/이 코멘트로 컨텍스트 충분.

## 원본 리포트 상태

audit-report #1695 본 이슈는 triage 목적 달성으로 클로즈한다. PR #1696의 `Closes #1695`는 자동으로 no-op이 된다 (이미 closed). retention-map.md 문서 자체는 PR #1696에서 계속 진행 (CHANGES_REQUESTED — legal-reviewer가 케어 중).

### Comment 5 — @Mark-Yun on 2026-04-22

Triage 완료. F1~F8 모두 개별 이슈(#1697, #1703, #1704, #1705, #1706, #1707, #1708, #1709)로 분해됨. retention-map.md 문서 자체는 PR #1696에서 진행.
