# Plan: 백엔드 시뮬레이터 EF 경유 통일

> Issue: #999 | Status: In Progress

## 1. 문제 정의

백엔드 시뮬레이터의 설계 의도는 **실제 유저 플로우를 EF로 재현**하여 E2E 파이프라인을 검증하는 것이다. 그러나 현재 6개 phase 중 3개가 EF를 아예 사용하지 않고, 나머지 3개도 EF 실패 시 direct DB fallback으로 조용히 우회한다.

### 현재 상태

| Phase | 동작 | EF 경유 | Direct DB fallback |
|-------|------|:-------:|:------------------:|
| create (파티/이벤트) | INSERT parties, events, entry_groups, tickets | X | O |
| apply (참가 신청) | `apply_event` RPC + 직접 INSERT fallback | △ | O |
| approve (심사) | INSERT/UPDATE verification_submissions | X | O |
| refund (환불) | `payment-cancel` EF | O | O |
| checkin (체크인) | `event-checkin` EF | O | O |
| match (매칭) | `event-matching` EF | O | O |
| complete (완료) | UPDATE events.status | X | O |
| settle (정산) | RPC `update_single_settlement_ready_status` | - | - |

### 핵심 문제

1. **create/approve는 기존 EF가 있는데도 사용하지 않음** — `partner-manage-party`, `partner-manage-event`, `partner-review-submission` EF가 이미 존재
2. **fallback이 EF 실패를 무시** — 시뮬레이터의 E2E 검증 의미 퇴색
3. **complete는 시스템 동작** — 프로덕션에서도 cron/trigger 기반이므로 EF 경유 불필요 (정당한 direct DB)

## 2. 설계 결정

### 2.1 `strict` 모드 도입

`SimConfig`에 `strict: boolean` (default: `false`) 필드를 추가한다.

- `strict: false` (기본값): 기존처럼 EF 실패 시 fallback 허용. 하위 호환 유지.
- `strict: true`: EF 실패 시 즉시 phase 실패. fallback 실행 안 함.

### 2.2 Phase별 전략

| Phase | 변경 | 사용 EF | 비고 |
|-------|------|---------|------|
| **create** | EF 경유로 전환 | `partner-manage-party` (create) + `partner-manage-event` (create) | 파트너 JWT 필요 |
| **apply** | 유지 | `apply_event` RPC | RPC는 SECURITY DEFINER — EF와 동등 |
| **approve** | EF 경유로 전환 | `partner-review-submission` (review) | 파트너 JWT 필요 |
| **refund** | strict 모드 적용 | `payment-cancel` (기존) | fallback을 strict 모드로 제어 |
| **checkin** | strict 모드 적용 | `event-checkin` (기존) | fallback을 strict 모드로 제어 |
| **match** | strict 모드 적용 | `event-matching` (기존) | fallback을 strict 모드로 제어 |
| **complete** | 유지 (direct DB) | 없음 | 프로덕션도 cron/trigger. 정당한 시스템 동작 |
| **settle** | 유지 (RPC) | 없음 | RPC는 SECURITY DEFINER |

### 2.3 파트너 인증

`sim_auth.ts`에 파트너 JWT 취득 함수 추가:
- `getSimPartnerToken(supabaseUrl, anonKey, partnerEmail, password) → JWT`
- 기존 `getSimUserToken`과 동일 패턴, 별도 캐시 키 (`partner_${email}`)
- 시뮬레이터의 partner 사용자 email은 DB에서 `partner_members` → `auth.users` 조인으로 조회

### 2.4 create phase 전환 상세

**현재**: `supabase.from("parties").insert(...)` → `supabase.from("events").insert(...)` → `supabase.from("entry_groups").insert(...)` → `supabase.from("tickets").insert(...)`

**변경 후**:
1. partner_id로 partner_member 조회 → partner 사용자 이메일 획득 → JWT 취득
2. `callEdgeFunction("partner-manage-party", { action: "create", partner_id, party, location, entry_group_templates, ticket_templates }, partnerToken)` → party_id 반환
3. `callEdgeFunction("partner-manage-event", { action: "create", party_id, event, tickets }, partnerToken)` → event_id 반환

**주의사항**:
- `partner-manage-event`의 tickets는 `ticket_templates`의 `template_id`를 참조해야 함 → party 생성 후 ticket_templates를 조회해서 매핑
- entry_group은 party 생성 시 template으로 저장되고, event 생성 시 자동 복제됨
- EF 실패 시: `strict=true`면 throw, `strict=false`면 기존 direct DB fallback

### 2.5 approve phase 전환 상세

**현재**: `supabase.from("verification_submissions").insert(...)` → `.update({ status: "approved" })`

**변경 후**:
1. 각 pending_review application에 대해:
   - 기존 `_fetchAppInfo`, `_fetchPartnerInfo` 로직은 유지 (submission_id 확보 필요)
   - verification_submission을 pending 상태로 생성 (이건 유저가 제출한 것을 시뮬레이션 — 사전 조건)
   - `callEdgeFunction("partner-review-submission", { action: "review", submission_id, result: "approved"|"rejected" }, partnerToken)` 호출
2. EF가 submission.status 업데이트 → trigger 발동 → application 상태 변경 → 기존 assertion으로 검증

**주의사항**:
- submission INSERT는 사전 조건(유저 제출 시뮬레이션)이므로 direct DB 유지
- EF 호출은 파트너의 리뷰 동작만 대체

### 2.6 기존 EF phase의 strict 모드 적용

`sim_refund.ts`, `sim_event.ts`의 기존 fallback 분기에 strict 체크 추가:

```typescript
// Before (현재)
if (efResult.status !== 200) {
  log({ level: "warn", ... });
  // fallback to direct DB
}

// After
if (efResult.status !== 200) {
  if (strict) {
    throw new Error(`EF ${fnName} failed with status ${efResult.status} (strict mode)`);
  }
  log({ level: "warn", ... });
  // fallback to direct DB
}
```

## 3. 수정 대상 파일

| 파일 | 변경 내용 |
|------|----------|
| `sim_types.ts` | `SimConfig`에 `strict: boolean` 추가 |
| `sim_auth.ts` | `getSimPartnerToken()` 함수 추가 |
| `sim_create.ts` | `simCreateParties()`를 EF 경유로 전환 + strict fallback |
| `sim_approve.ts` | `simApproveVerifications()`를 EF 경유로 전환 + strict fallback |
| `sim_refund.ts` | 기존 fallback에 strict 체크 추가 |
| `sim_event.ts` | simCheckin/simMatch의 fallback에 strict 체크 추가 |
| `index.ts` | DEFAULT_CONFIG에 `strict: false` 추가, supabaseUrl/anonKey를 approve phase에도 전달 |
| `e2e_test.ts` | 새 config 필드 반영 |

## 4. 태스크 분배

### Task 1: 인프라 (sim_types.ts + sim_auth.ts + index.ts)
- `SimConfig`에 `strict` 필드 추가
- `sim_auth.ts`에 `getSimPartnerToken()` 추가
- `index.ts`에서 `strict` default, supabaseUrl/anonKey를 approve phase에 전달
- `e2e_test.ts`의 mock config에 `strict` 추가

### Task 2: create phase EF 전환 (sim_create.ts)
- `simCreateParties()` — partner JWT 획득 후 EF 경유로 전환
- strict 모드 분기 (EF 실패 시 throw vs fallback)
- 기존 직접 INSERT 코드를 fallback으로 보존

### Task 3: approve phase EF 전환 + 기존 phase strict 적용 (sim_approve.ts + sim_refund.ts + sim_event.ts)
- `simApproveVerifications()` — partner JWT 획득 후 `partner-review-submission` EF 호출
- `sim_refund.ts` — 기존 fallback에 strict 체크 추가
- `sim_event.ts` — simCheckin/simMatch의 fallback에 strict 체크 추가

## 5. 리스크

| 리스크 | 영향 | 대응 |
|--------|------|------|
| partner JWT 취득 실패 | create/approve phase 실패 | strict=false 시 기존 fallback 동작 유지 |
| EF 타임아웃 (120s curl) | 대량 배치에서 타임아웃 | 기존 배치 처리 패턴 유지 (10개 단위) |
| ticket_template 매핑 실패 | event 생성 실패 | party 생성 후 template 조회 로직 필수 |

## 6. 테스트 전략

- `e2e_test.ts`의 기존 테스트가 `strict: false` (default)로 통과하는지 확인
- strict 모드에서 EF mock이 실패 반환 시 phase가 실패하는지 검증
- 기존 assertion 라이브러리(`sim_assertions.ts`)는 변경 없음 — DB 상태 검증이므로 EF 경유 여부와 무관
