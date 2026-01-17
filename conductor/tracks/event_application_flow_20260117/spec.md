# 명세서: 원샷 이벤트 신청 플로우 (One-Shot Application Flow)

## 1. 개요
이벤트 상세 페이지에서 티켓을 선택한 후, **"인증(Verification) + 결제(Payment) + 신청(Admission)"**을 끊김 없이 한 번에 처리하는 프로세스를 구현합니다. 이를 통해 유저 이탈을 줄이고, 파트너는 '결제된 진성 유저'만 심사할 수 있는 효율적인 시스템을 구축합니다.

## 2. 핵심 로직 및 데이터 흐름
### 2.1. 데이터베이스 구조 변경
*   **`event_applications` (신청서):** 결제 정보 추적을 위해 `payment_id`, `payment_amount`, `refund_status` 컬럼 추가.
*   **`verification_submissions` (인증 서류):** 특정 신청 건에 종속됨을 명시하기 위해 `application_id` (FK to `event_applications`) 컬럼 추가.
*   **구조적 이점:** 1:N 관계(하나의 신청서에 여러 서류 제출)가 가능한 구조이므로, 향후 다중 인증 요구사항에도 유연하게 대응 가능.

### 2.2. 신청 시나리오 (One-Shot Transaction)
1.  **유저 액션:** 위저드에서 인증 정보 확인 후 "결제 및 신청" 클릭.
2.  **Mock 결제 성공:** 클라이언트에서 결제 성공 처리.
3.  **서버 트랜잭션 (Atomic Operation):**
    *   **Step 1:** `event_applications` 레코드 생성 (Status: `pending_review`).
    *   **Step 2:** `verification_submissions` 레코드 생성 (Status: `pending`, Step 1의 `id`를 `application_id`로 저장).

### 2.3. 파트너 승인 시나리오 (Approval Logic)
1.  **파트너 액션:** 관리자 앱에서 제출된 서류(`verification_submissions`) 검토 후 **[승인]** 클릭.
2.  **자동화 트리거 (Trigger Function):**
    *   **Action 1:** `verification_submissions` 상태를 `approved`로 변경.
    *   **Action 2:** **`partner_verified_users`** 테이블에 유효한 자격 증명 레코드 생성 (향후 재사용 가능).
    *   **Action 3:** 해당 서류에 연결된(`application_id`) `event_applications`의 상태를 자동으로 `approved`로 변경하여 입장 확정.
    *   **Action 4:** `event_applications`가 `approved`되면 자동으로 `event_participants` 테이블에 티켓 발권 레코드 생성.

## 3. 사용자 스토리
- **사용자**로서, 이미 입력해둔 인증 정보가 있다면 다시 입력하지 않고 확인만 거쳐 빠르게 신청하고 싶습니다.
- **사용자**로서, 신청이 완료되면 "심사 대기 중" 상태를 명확히 인지하고, 심사 통과 시 자동으로 티켓이 발권되기를 기대합니다.
- **파트너**로서, 결제까지 마친 유저의 신청서와 인증 서류를 한 화면에서 연결지어 보고 싶습니다.

## 4. 기능 요구사항 (Functional)
### 4.1. UI: 신청 위저드 (Full Screen)
- **1단계: 인증 정보 확인 (Verification)**
    - `user_verifications` 조회: 기존 데이터가 있으면 프리필(Pre-fill).
    - 수정 가능하며, 수정 시 `user_verifications` 원본도 업데이트(Upsert).
    - `partner_verified_users`에 이미 유효한 자격이 있다면 이 단계는 **자동 생략**.
- **2단계: 결제 및 확정 (Payment)**
    - 티켓 요약 정보 표시.
    - "결제하기" 버튼 클릭 시 Mock 결제 수행 후 서버 제출.

### 4.2. 에러 핸들링
- **신청 실패:** DB 트랜잭션 실패 시, 즉시 **자동 환불(Auto Refund)** 로직을 수행(Mock)하고 유저에게 "신청 실패 및 환불 완료" 메시지 표시.

## 5. 기술 요구사항 (Technical)
- **프레임워크:** Flutter (`app_user`)
- **언어:** Dart, SQL (PL/pgSQL)
- **상태 관리:** Riverpod (`EventApplicationController`)
- **마이그레이션:** SQL 스키마 변경 및 트리거 함수 작성/수정.

## 6. 제외 범위 (Out of Scope)
- 실제 PG 연동 (PortOne 등).
