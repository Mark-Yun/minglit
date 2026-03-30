# 회원 탈퇴(계정 삭제) — 테스트 보강 계획

## 계층별 테스트 계획

### Layer 1: Edge Function 테스트 (Deno)

#### 1-1. `user-delete-account`

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `supabase/functions/user-delete-account/user-delete-account_test.ts` | 인증 없는 요청 → 401 | P1 |
| | 정상 탈퇴 요청 → `user_profiles.deleted_at` 설정 + 200 응답 (`grace_period_ends` 포함) | P1 |
| | 사유 코드 포함 요청 → `withdrawal_reasons` INSERT 확인 (user_id 미저장, 익명) | P1 |
| | 사유 없이 요청 → 정상 처리 (사유 선택 사항) | P1 |
| | 이미 `deleted_at` 설정된 유저 → 409 Conflict | P1 |
| | 활성 예약(미완료 이벤트) 존재 → 400 Bad Request + 에러 메시지 | P1 |
| | 미정산 잔액 존재 → 400 Bad Request | P1 |
| | FCM 토큰 삭제 호출 확인 (push 구독 해제) | P2 |
| | `grace_period_ends`가 현재 시각 + 7일인지 검증 | P2 |
| | `reason_text` 최대 200자 초과 시 처리 (truncate 또는 400) | P3 |

#### 1-2. `user-cancel-deletion`

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `supabase/functions/user-cancel-deletion/user-cancel-deletion_test.ts` | 인증 없는 요청 → 401 | P1 |
| | 유예 기간 중 취소 → `deleted_at = null` 복원 + 200 | P1 |
| | `deleted_at`이 null인 유저 → 404 (탈퇴 진행 중 아님) | P1 |
| | 7일 경과 후 취소 시도 → 적절한 에러 (이미 삭제됨 또는 404) | P2 |

### Layer 2: Database 테스트 (pgTAP)

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `supabase/tests/database/56_account_deletion_schema_test.sql` | `user_profiles.deleted_at` 컬럼 존재 (timestamptz, nullable) | P1 |
| | `withdrawal_reasons` 테이블 존재 + 컬럼 검증 (id, reason_code, reason_text, created_at) | P1 |
| | `blocked_dis` 테이블 존재 + 컬럼 검증 (di_hash PK, blocked_until, created_at) | P1 |
| | `archived_records` 테이블 존재 + 컬럼 검증 (id, user_id_hash, record_type, record_data, retention_until, created_at) | P1 |
| | `archived_records.record_type` CHECK 제약조건 ('contract', 'payment', 'dispute', 'login') | P1 |
| | `idx_archived_records_retention` 인덱스 존재 | P2 |
| | `idx_blocked_dis_until` 인덱스 존재 | P2 |
| `supabase/tests/database/57_account_deletion_rls_test.sql` | `withdrawal_reasons`: 일반 유저 읽기 불가 (서비스 롤만 접근) | P1 |
| | `blocked_dis`: 일반 유저 읽기/쓰기 불가 | P1 |
| | `archived_records`: 일반 유저 읽기/쓰기 불가 | P1 |
| | `user_profiles`: `deleted_at IS NOT NULL`인 유저가 다른 유저의 SELECT에서 제외 | P1 |
| | `user_profiles`: 본인은 `deleted_at IS NOT NULL`이어도 자기 레코드 조회 가능 | P2 |
| `supabase/tests/database/58_account_deletion_cascade_test.sql` | `auth.users` 삭제 시 `user_profiles` CASCADE 삭제 확인 | P1 |
| | `auth.users` 삭제 시 `event_participants` CASCADE 확인 | P1 |
| | `auth.users` 삭제 시 `push_tokens` CASCADE 확인 | P1 |
| | `auth.users` 삭제 시 `social_interactions` CASCADE 확인 | P2 |
| | 모든 user_id FK 테이블에 ON DELETE CASCADE 설정 확인 | P1 |

### Layer 3: Repository 테스트 (minglit_kit)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `AccountRepository.deleteAccount()` | `shared/packages/minglit_kit/test/src/data/repositories/account_repository_test.dart` | 사유 포함 호출 → EF 요청 body에 reason_code + reason_text 포함 | P1 |
| | | 사유 없이 호출 → EF 요청 body에 reason 필드 없음 | P1 |
| | | EF 200 응답 → `DeletionStatus` 반환 (gracePeriodEnds 파싱) | P1 |
| | | EF 400 (활성 예약) → `MingleException` throw + 에러 메시지 전달 | P1 |
| | | EF 409 (이미 탈퇴 중) → `MingleException` throw | P1 |
| | | 네트워크 에러 → `MingleException` throw | P2 |
| `AccountRepository.cancelDeletion()` | 동일 파일 | 정상 취소 → success 반환 | P1 |
| | | EF 404 (탈퇴 미진행) → `MingleException` throw | P1 |
| | | 네트워크 에러 → `MingleException` throw | P2 |
| `AccountRepository.getDeletionStatus()` | 동일 파일 | `deleted_at` 있으면 → `DeletionStatus(isPending: true, gracePeriodEnds: ...)` | P1 |
| | | `deleted_at` null → `DeletionStatus(isPending: false)` | P1 |
| `AccountRepository.reauthenticate()` | 동일 파일 | 비밀번호 재인증 성공 | P2 |
| | | 비밀번호 재인증 실패 → 에러 | P2 |
| | | 소셜 재인증 성공 (Google/Apple/Kakao) | P2 |

### Layer 4: Controller 테스트

#### 4-1. `AccountDeletionController` (minglit_kit)

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `shared/packages/minglit_kit/test/src/features/account_deletion/logic/account_deletion_controller_test.dart` | 초기 상태: `AsyncData` with empty reason | P2 |
| | `setReason(code, text)` → 상태에 사유 반영 | P1 |
| | `submitDeletion()` → Repository.deleteAccount() 호출 + 성공 시 상태 업데이트 | P1 |
| | `submitDeletion()` → 활성 예약 에러 시 `AsyncError` 상태 + 에러 메시지 | P1 |
| | `submitDeletion()` → 이미 탈퇴 중 에러 시 `AsyncError` 상태 | P1 |
| | `cancelDeletion()` → Repository.cancelDeletion() 호출 + 성공 시 상태 복원 | P1 |
| | `cancelDeletion()` → 실패 시 `AsyncError` 상태 | P2 |
| | `reauthenticate(password)` → 성공 시 인증 완료 플래그 | P1 |
| | `reauthenticate(password)` → 실패 시 에러 상태 | P1 |
| | 로딩 중 중복 호출 방지 (submitDeletion 중 재호출 무시) | P2 |

#### 4-2. Coordinator 테스트 (app_user)

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_user/test/src/features/account_deletion/logic/account_deletion_coordinator_test.dart` | `start()` → `/my/privacy/delete` (사유 선택 화면) 이동 | P1 |
| | `pushInfo()` → `/my/privacy/delete/info` 이동 | P1 |
| | `pushVerify()` → `/my/privacy/delete/verify` 이동 | P1 |
| | `pushComplete()` → `/my/privacy/delete/complete` 이동 | P1 |
| | `complete()` → 3초 후 로그아웃 + 홈 화면 이동 | P2 |

#### 4-3. Coordinator 테스트 (app_partner)

| 테스트 파일 | 테스트 케이스 | 우선순위 |
|-----------|-------------|---------|
| `apps/app_partner/test/src/features/account_deletion/logic/account_deletion_coordinator_test.dart` | `start()` → `/more/account/delete` (사유 선택 화면) 이동 | P1 |
| | 나머지 네비게이션은 app_user와 동일 패턴 | P2 |

### Layer 5: Widget 테스트 (UI)

#### 5-1. 유저 앱 화면

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `DeletionReasonPage` | `apps/app_user/test/src/features/account_deletion/ui/deletion_reason_page_test.dart` | 6개 사유 라디오 버튼 렌더링 | P1 |
| | | 사유 선택 시 라디오 버튼 상태 변경 | P1 |
| | | "기타" 선택 시 자유 입력 필드 표시 (최대 200자) | P1 |
| | | "선택하지 않고 계속하기" 탭 → 사유 없이 다음 화면 이동 | P1 |
| | | "다음" 버튼 탭 → 선택한 사유와 함께 다음 화면 이동 | P1 |
| `DeletionInfoPage` | `apps/app_user/test/src/features/account_deletion/ui/deletion_info_page_test.dart` | 삭제 항목 목록 표시 (프로필, 매칭, 알림, 구매내역) | P1 |
| | | 법정 보존 항목 테이블 표시 (4개 항목 + 기간) | P1 |
| | | 7일 유예 기간 안내 텍스트 표시 | P1 |
| | | 30일 재가입 차단 안내 텍스트 표시 | P2 |
| | | "다음" 버튼 탭 → 본인 확인 화면 이동 | P1 |
| `DeletionVerifyPage` | `apps/app_user/test/src/features/account_deletion/ui/deletion_verify_page_test.dart` | 이메일 유저: 비밀번호 입력 필드 표시 | P1 |
| | | 소셜 유저: 소셜 재인증 버튼 표시 (Google/Apple/Kakao) | P1 |
| | | 비밀번호 불일치 → 인라인 에러 메시지 | P1 |
| | | 소셜 재인증 실패 → 에러 스낵바 | P1 |
| | | 인증 성공 → 최종 확인 다이얼로그 표시 | P1 |
| | | 최종 확인 다이얼로그: "정말 탈퇴할까요?" 제목 + "탈퇴하기"(error 컬러) / "돌아가기" 버튼 | P1 |
| | | "탈퇴하기" 탭 → submitDeletion 호출 + 로딩 인디케이터 | P1 |
| | | "돌아가기" 탭 → 다이얼로그 닫기 | P2 |
| | | API 호출 중 로딩 상태 표시 (CircularProgressIndicator) | P2 |
| | | API 에러 → "탈퇴 처리 중 문제가 발생했어요" 스낵바 | P2 |
| `DeletionCompletePage` | `apps/app_user/test/src/features/account_deletion/ui/deletion_complete_page_test.dart` | 체크 아이콘 + "탈퇴 요청이 완료됐어요" 텍스트 | P1 |
| | | "7일 후 계정이 영구 삭제돼요" 텍스트 | P1 |
| | | 3초 후 자동 로그아웃 + 홈 이동 (Timer 검증) | P2 |

#### 5-2. 파트너 앱 추가 테스트

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| 파트너 탈퇴 차단 조건 | `apps/app_partner/test/src/features/account_deletion/ui/deletion_verify_page_test.dart` | 미완료 이벤트 존재 → 탈퇴 차단 + 해결 항목 목록 표시 | P1 |
| | | 미정산 잔액 존재 → 탈퇴 차단 + 정산 페이지 바로가기 | P1 |
| | | 진행 중 환불 건 존재 → 탈퇴 차단 | P1 |
| | | 차단 조건 없음 → 정상 플로우 진행 | P1 |
| `MorePage` 메뉴 | `apps/app_partner/test/src/features/more/more_page_test.dart` (기존 파일에 추가) | "회원 탈퇴" 메뉴 항목 표시 | P2 |
| | | "회원 탈퇴" 탭 → coordinator.pushAccountDeletion() 호출 | P2 |

#### 5-3. 유예 기간 재로그인 복구

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| app_router redirect | `apps/app_user/test/src/routing/app_router_test.dart` (기존 파일에 추가) | `pending_deletion` 상태 감지 → 복구 다이얼로그 표시 | P1 |
| | | 다이얼로그 "취소할게요" 탭 → cancelDeletion() 호출 + 정상 진입 | P1 |
| | | 다이얼로그 "탈퇴 유지" 탭 → 로그아웃 | P2 |
| | | `deleted_at` null (정상 유저) → redirect 없음 | P2 |

### Layer 6: Golden 테스트 (시각적 회귀)

| 화면 | 변형 | 테스트 파일 | 우선순위 |
|------|------|-----------|---------|
| `DeletionReasonPage` | 사유 미선택 (light/dark) | `apps/app_user/test/goldens/deletion_reason_page_golden_test.dart` | P2 |
| | "기타" 선택 + 텍스트 입력 (light/dark) | 동일 | P3 |
| `DeletionInfoPage` | 기본 상태 (light/dark) | `apps/app_user/test/goldens/deletion_info_page_golden_test.dart` | P2 |
| `DeletionVerifyPage` | 이메일 유저 (light/dark) | `apps/app_user/test/goldens/deletion_verify_page_golden_test.dart` | P2 |
| | 소셜 유저 (light/dark) | 동일 | P3 |
| | 비밀번호 에러 상태 | 동일 | P3 |
| `DeletionCompletePage` | 기본 상태 (light/dark) | `apps/app_user/test/goldens/deletion_complete_page_golden_test.dart` | P2 |
| 최종 확인 다이얼로그 | 기본 상태 (light/dark) | `apps/app_user/test/goldens/deletion_confirm_dialog_golden_test.dart` | P2 |
| 복구 다이얼로그 | 유예 기간 재로그인 (light/dark) | `apps/app_user/test/goldens/deletion_recovery_dialog_golden_test.dart` | P3 |
| 파트너 탈퇴 차단 화면 | 차단 조건 목록 (light/dark) | `apps/app_partner/test/goldens/deletion_blocked_page_golden_test.dart` | P3 |

### Layer 7: Model 테스트 (minglit_kit)

| 대상 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `DeletionStatus` | `shared/packages/minglit_kit/test/src/data/models/deletion_status_test.dart` | JSON → `DeletionStatus` 역직렬화 (isPending: true, gracePeriodEnds 파싱) | P1 |
| | | isPending false 상태 역직렬화 | P1 |
| | | `gracePeriodEnds` ISO8601 문자열 → DateTime 변환 | P2 |
| `WithdrawalReason` | `shared/packages/minglit_kit/test/src/data/models/withdrawal_reason_test.dart` | reason_code + reason_text 직렬화/역직렬화 | P2 |
| | | reason_text null 허용 | P2 |

### 에지 케이스 및 경계값 테스트

아래는 각 레이어에 분산되어 포함되어야 하는 핵심 에지 케이스:

| 에지 케이스 | 해당 레이어 | 우선순위 |
|-----------|-----------|---------|
| 유예 기간 경계값: 정확히 7일 (168시간) 시점의 처리 | Layer 1 (EF) + Layer 2 (pgTAP CRON) | P1 |
| 재가입 차단 만료 경계: 정확히 30일 시점 | Layer 2 (pgTAP) | P2 |
| 동시 탈퇴 요청 (race condition): 같은 유저가 동시에 2번 요청 | Layer 1 (EF) | P2 |
| FK CASCADE 실패: `ON DELETE CASCADE` 미설정 테이블 존재 시 | Layer 2 (pgTAP) | P1 |
| 탈퇴 진행 중 유저의 이벤트 참여 시도 → 차단 | Layer 2 (RLS) | P1 |
| 아카이빙 중 트랜잭션 실패 → 롤백 확인 | Layer 1 (CRON EF) | P2 |
| `reason_text` 200자 경계: 199자, 200자, 201자 | Layer 1 (EF) | P3 |
| 소셜 재인증 토큰 만료 상태에서 재인증 시도 | Layer 3 (Repository) | P3 |

### 기존 테스트 회귀 검증

| 기존 테스트 | 검증 포인트 |
|-----------|-----------|
| `app_user/test/src/routing/app_router_test.dart` | auth redirect에 `pending_deletion` 로직 추가 후 기존 redirect 테스트 pass |
| `app_user/test/src/features/settings/` | PrivacyPage 확장 후 기존 설정 테스트 pass |
| `app_partner/test/src/features/more/` | "회원 탈퇴" 메뉴 추가 후 기존 더보기 테스트 pass |
| 기존 RLS 테스트 전체 | `deleted_at IS NULL` 조건 추가 후 기존 RLS 정책 테스트 pass |

## 실행 순서

**P1 (필수): 52건**
- Edge Function 테스트: `user-delete-account` 7건 + `user-cancel-deletion` 3건 = 10건
- pgTAP 스키마/RLS/CASCADE: 15건
- Repository `AccountRepository`: 9건
- Controller `AccountDeletionController`: 7건
- Coordinator (app_user): 4건 + (app_partner): 1건
- Widget (app_user 4화면): 15건
- Widget (app_partner 차단 조건): 4건
- 재로그인 복구: 2건
- Model: 2건

**P2 (권장): 30건**
- Edge Function 추가 케이스: 4건
- pgTAP 인덱스/세부: 4건
- Repository 네트워크 에러/재인증: 5건
- Controller 에지 케이스: 3건
- Coordinator 세부: 2건
- Widget 세부 (에러/로딩/다이얼로그): 6건
- Golden 메인 화면: 6건
- Model 세부: 3건
- 에지 케이스: 3건

**P3 (선택): 12건**
- Edge Function 경계값: 1건
- Golden 추가 변형: 5건
- Widget 세부: 2건
- 에지 케이스 세부: 4건

**총 94건**
