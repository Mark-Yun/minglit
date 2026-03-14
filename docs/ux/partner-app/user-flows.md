# 파트너 앱 사용자 여정 플로우 (User Flows)

이 문서는 밍릿 파트너 앱(`app_partner`)의 주요 사용자 여정을 플로우차트로 정의한 UX 레퍼런스입니다.
각 플로우에서 사용하는 화면명과 라우트 경로는 **[화면 카탈로그](./screen-catalog.md)** 를 기준으로 합니다.

---

## 목차

1. [인증 게이트 플로우](#인증-게이트-플로우)
2. [Flow 1 — 파트너 온보딩](#flow-1--파트너-온보딩)
3. [Flow 2 — 파티 생성](#flow-2--파티-생성)
4. [Flow 3 — 이벤트 생성 및 운영](#flow-3--이벤트-생성-및-운영)
5. [Flow 4 — 신청 심사](#flow-4--신청-심사)
6. [Flow 5 — 정산 확인](#flow-5--정산-확인)
7. [Flow 6 — QR 체크인](#flow-6--qr-체크인)
8. [공통 예외 경로](#공통-예외-경로)

---

## 인증 게이트 플로우

앱 진입 시 `GoRouter`의 `redirect` 로직이 인증 상태와 온보딩 상태를 순차적으로 검사하여 적절한 화면으로 분기한다.
분기 기준은 `currentUserProvider`(로그인 여부)와 `onboardingStateProvider`(파트너 신청 상태) 두 가지다.

```mermaid
flowchart TD
    A([앱 진입]) --> B{로그인 여부\ncurrentUserProvider}
    B -- 미인증 --> C[파트너 로그인\n/login]
    C -- 로그인 성공 --> B
    B -- 인증됨 --> D{onboardingState\n로드 완료?}
    D -- 로딩 중 --> E[스플래시/로딩 유지]
    E --> D
    D -- 완료 --> F{온보딩 상태\nonboardingStateProvider}

    F -- needsApplication --> G[파트너 신청 위자드\n/apply]
    F -- draftInProgress --> G
    F -- pendingReview --> H[신청 상태 확인\n/apply/status]
    F -- needsCorrection --> H
    F -- hasPartner --> I[파트너 홈\n/]

    G -- 이미 파트너 상태로 진입 시 --> I
    H -- 이미 파트너 상태로 진입 시 --> I

    style C fill:#fef3c7
    style G fill:#dbeafe
    style H fill:#dbeafe
    style I fill:#dcfce7
```

> **참고**: `/dev` 경로는 인증 없이 접근 가능 (개발 전용 DevMap).
> 로그인 상태에서 `/login` 접근 시 `/`로 즉시 리다이렉트.

---

## Flow 1 — 파트너 온보딩

일반 유저가 파트너 권한을 획득하기까지의 전체 여정.
신청 위자드(`PartnerApplyPage`)는 5단계로 구성되며, 각 단계 이동 시 임시 저장(draft)이 자동으로 수행된다.

```mermaid
flowchart TD
    A([앱 최초 진입\nneedsApplication 상태]) --> B[파트너 로그인\n/login]
    B -- 회원가입 링크 --> C[회원가입 완료]
    C --> B
    B -- 로그인 성공 --> D[파트너 신청 위자드\n/apply]

    D --> S1[Step 1\n기본 매장 정보\n브랜드명·소개·프로필 이미지]
    S1 -- 유효성 통과 → nextStep + saveDraft --> S2[Step 2\n사업자 등록 정보\n사업자 유형·번호·대표자명]
    S2 -- 유효성 통과 --> S3[Step 3\n연락처 및 정산 계좌\n전화·이메일·은행·계좌번호·세금계산서 이메일]
    S3 -- 유효성 통과 --> S4[Step 4\n증빙 서류 업로드\n사업자등록증·통장사본]
    S4 -- 유효성 통과 --> S5[Step 5\n최종 확인 및 제출]

    S1 -- 유효성 실패 --> S1
    S2 -- 유효성 실패 --> S2
    S3 -- 유효성 실패 --> S3
    S4 -- 유효성 실패 --> S4

    S2 -- 이전 --> S1
    S3 -- 이전 --> S2
    S4 -- 이전 --> S3
    S5 -- 이전 --> S4

    S5 -- 제출 성공 --> W[신청 상태 확인\n/apply/status\npendingReview 상태]
    S5 -- 제출 실패 --> ERR[에러 토스트 표시]
    ERR --> S5

    W --> R{관리자 심사 결과}
    R -- 승인 --> I[파트너 홈\n/\nhasPartner 상태]
    R -- 보완요청 --> K[신청 상태 확인\n/apply/status\nneedsCorrection + 보완 사유 표시]
    K -- 수정하기 --> D
    R -- 반려 --> L[신청 상태 확인\n/apply/status\n반려 사유 표시]
    L -- 재신청 --> D

    D -- 앱 종료 후 재진입\ndraftInProgress --> D2[임시저장 복원\n이어서 작성]
    D2 --> S1
```

### 온보딩 상태 전이 요약

| 상태 | 진입 화면 | 트리거 |
|------|-----------|--------|
| `needsApplication` | `/apply` (Step 1) | 최초 진입 |
| `draftInProgress` | `/apply` (저장된 스텝) | 임시저장 후 재진입 |
| `pendingReview` | `/apply/status` | 제출 완료 |
| `needsCorrection` | `/apply/status` | 관리자 보완요청 |
| `hasPartner` | `/` | 관리자 승인 |

---

## Flow 2 — 파티 생성

파트너가 새로운 파티(매장)를 등록하는 여정.
위자드는 `PartyCreateStep` enum 기준 6단계로 구성되며, 편집 시에는 기존 데이터가 프리필(`isPrefilled=true`)된다.

```mermaid
flowchart TD
    A([파트너 홈\n/]) --> B[파티 목록\n/parties]
    B -- FAB '파티 생성' 클릭 --> C[파티 생성 위자드\n/parties/create]

    C --> W1[Step 1: basicInfo\n파티명·설명·카테고리·이미지]
    W1 -- 유효성 통과 --> W2[Step 2: location\n지도 좌표·상세 주소·오시는 길]
    W2 -- 유효성 통과 --> W3[Step 3: capacityAndContact\n정원·최소인원·연락처·성비균형 허용치]
    W3 -- 유효성 통과 --> W4[Step 4: entryRules\n입장 그룹 설정\nEntryGroupTemplate 정의]
    W4 -- 유효성 통과 --> W5[Step 5: tickets\n티켓 템플릿 구성\nTicketTemplate 가격·수량·공개 여부]
    W5 -- 유효성 통과 --> W6[Step 6: review\n전체 입력 내용 최종 확인]

    W1 -- 유효성 실패 --> W1
    W2 -- 유효성 실패 --> W2
    W3 -- 유효성 실패 --> W3
    W4 -- 유효성 실패 --> W4
    W5 -- 유효성 실패 --> W5

    W2 -- 이전 --> W1
    W3 -- 이전 --> W2
    W4 -- 이전 --> W3
    W5 -- 이전 --> W4
    W6 -- 이전 --> W5

    W6 -- 생성 완료 --> D[파티 상세\n/parties/:partyId]
    W6 -- 생성 실패 --> ERR[에러 토스트]
    ERR --> W6

    D --> B

    B -- 기존 파티 '편집' 메뉴 --> E[파티 생성 위자드\n/parties/:partyId/edit\nisPrefilled=true]
    E --> W1
```

### 파티 생성 위자드 단계 요약

| 스텝 | `PartyCreateStep` | 주요 입력 |
|------|-------------------|-----------|
| 1 | `basicInfo` | 파티명, 설명, 카테고리, 이미지 |
| 2 | `location` | 지도 좌표(`Location`), 상세 주소, 오시는 길 안내 |
| 3 | `capacityAndContact` | 정원, 최소 인원, 연락처, 성비 균형 허용치(`balanceTolerance`) |
| 4 | `entryRules` | 입장 그룹(`EntryGroupTemplate`) 정의 |
| 5 | `tickets` | 티켓 템플릿(`TicketTemplate`), 공개 여부(`visibility`) |
| 6 | `review` | 전체 내용 최종 확인 후 제출 |

---

## Flow 3 — 이벤트 생성 및 운영

파티 상세에서 특정 일정(이벤트 회차)을 생성하고 운영하는 여정.

```mermaid
flowchart TD
    A[파티 상세\n/parties/:partyId] --> B[이벤트 관리 탭\nPartyEventManagementTab]
    B -- '이벤트 생성' 클릭 --> C[이벤트 생성\n/parties/:partyId/events/create]

    C --> D{날짜·시간·정원 입력\nEventCreatePage}
    D -- 유효성 실패 --> D
    D -- 저장 성공 --> E[이벤트 상세\n/parties/:partyId/events/:eventId]
    D -- 저장 실패 --> ERR1[에러 토스트]
    ERR1 --> D

    E --> F[참가 신청자 명단 확인]
    E --> G[체크인 현황 확인]
    E --> H[티켓 판매 통계 확인]
    E --> I[티켓 생성\n/parties/:partyId/events/:eventId/tickets/create]
    E --> J[티켓 수정\n.../tickets/:ticketId/edit]
    E --> K[QR 스캐너 실행\nQRScannerScreen]

    I --> L{티켓 정보 입력\nTicketCreatePage\n명칭·가격·수량·판매기간}
    L -- 유효성 실패 --> L
    L -- 저장 --> E

    J --> M{티켓 정보 수정\nTicketEditPage}
    M -- 저장 --> E

    K --> N[체크인 플로우\n→ Flow 6 참조]
    N --> E
```

---

## Flow 4 — 신청 심사

이벤트에 참가 신청한 유저를 개별 심사하는 여정.
`EventApplicationReviewController`가 `approved` / `rejected` 두 가지 상태를 처리하며,
인증 제출(`verification_submission`)이 연결된 경우 `verificationRepository`를 통해 처리한다.

```mermaid
flowchart TD
    A[이벤트 상세\n/parties/:partyId/events/:eventId] --> B[참가 신청자 명단\neventApplications 목록]
    B -- 신청자 항목 클릭 --> C[신청 상세 모달\n신청자 프로필·인증 서류]

    C --> VS{verification_submission\n존재 여부}
    VS -- 있음 --> VR[verificationRepository.reviewRequest\nVerificationStatus.approved/rejected]
    VS -- 없음 --> DR[event_applications 직접 업데이트\nstatus + rejection_reason]

    VR --> D{심사 결정}
    DR --> D

    D -- 승인 --> E[status: approved\n신청자에게 승인 알림 발송]
    D -- 거절 → 사유 없음 --> F[status: rejected]
    D -- 거절 → 사유 입력 --> G[status: rejected\nrejection_reason 저장]

    E --> H[명단 갱신\n승인 상태로 표시]
    F --> H
    G --> H

    H --> B

    B -- 전체 일괄 승인 --> I[일괄 approved 처리]
    I --> H

    C -- 심사 중 오류 --> ERR[에러 토스트\n재시도 안내]
    ERR --> C
```

### 심사 결과 상태값

| 결과 | `status` 값 | `rejection_reason` | 비고 |
|------|-------------|---------------------|------|
| 승인 | `approved` | — | 신청자 입장 확정, 알림 발송 |
| 거절 (사유 없음) | `rejected` | `null` | — |
| 거절 (사유 있음) | `rejected` | 사유 문자열 | 신청자에게 사유 전달 |

---

## Flow 5 — 정산 확인

정산 탭에서 수익 현황을 확인하는 여정. 상세 UI/UX 명세는
**[정산 UI/UX 설계서](../../features/partner-settlement/ui-ux-design.md)** 를 참조한다.

```mermaid
flowchart TD
    A([Bottom Nav\n수익관리 탭]) --> B[정산 관리\n/settlement\nSettlementPage]

    B --> C[정산 가능 금액 섹션]
    B --> D[월별 수익 리포트 그래프]
    B --> E[정산 계좌 관리]

    C -- 정산 신청 클릭 --> F{계좌 등록 여부}
    F -- 미등록 --> G[계좌 등록 안내\n→ 계좌 관리로 이동]
    G --> E
    F -- 등록됨 --> H[정산 신청 확인 다이얼로그]
    H -- 확인 --> I[정산 신청 완료\n처리 중 상태 표시]
    H -- 취소 --> B

    D -- 월 선택 --> J[해당 월 상세 내역]
    J -- 뒤로가기 --> B

    E -- 계좌 추가/변경 --> K[계좌 정보 입력 폼]
    K -- 저장 성공 --> B
    K -- 저장 실패 --> ERR[에러 토스트]
    ERR --> K
```

> 정산 플로우 상세(수수료 계산, 정산 주기, 세금계산서 등)는 [정산 UI/UX 설계서](../../features/partner-settlement/ui-ux-design.md)에서 관리한다.

---

## Flow 6 — QR 체크인

현장에서 유저의 QR 티켓을 스캔하여 입장을 처리하는 여정.
`CheckinController`는 `idle → processing → (success | invalid | alreadyCheckedIn | error) → idle` 사이클로 동작하며,
결과 표시 후 **3초 뒤 자동으로 `idle` 상태로 복귀**한다.

```mermaid
flowchart TD
    A([이벤트 상세\n/parties/:partyId/events/:eventId]) --> B[QR 스캐너 버튼 클릭]
    B --> C[QRScannerScreen\nCheckinResult: idle]

    C -- QR 코드 인식 --> D[CheckinResult: processing\nJSON 파싱 + TicketToken 생성]

    D --> E{서명 검증\nrepo.verifyAndCheckin}
    E -- 유효한 티켓 --> F[CheckinResult: success\n유저명 표시\n입장 처리 완료]
    E -- 이미 체크인 --> G[CheckinResult: alreadyCheckedIn\n중복 입장 경고]
    E -- 서명 불일치 --> H[CheckinResult: invalid\n'유효하지 않은 티켓입니다']
    E -- JSON 파싱 실패 --> I[CheckinResult: invalid\n'티켓 데이터를 읽을 수 없습니다']
    E -- 네트워크/기타 오류 --> J[CheckinResult: error\n오류 메시지 표시]

    F -- 3초 후 자동 복귀 --> C
    G -- 3초 후 자동 복귀 --> C
    H -- 3초 후 자동 복귀 --> C
    I -- 3초 후 자동 복귀 --> C
    J -- 3초 후 자동 복귀 --> C

    C -- 뒤로가기 --> A
```

### 체크인 결과 상태 요약

| `CheckinResult` | 표시 내용 | 후속 동작 |
|-----------------|-----------|-----------|
| `idle` | 스캐너 대기 화면 | — |
| `processing` | 로딩 인디케이터 | — |
| `success` | 유저명 + 성공 메시지 | 3초 후 idle 복귀 |
| `alreadyCheckedIn` | 중복 입장 경고 | 3초 후 idle 복귀 |
| `invalid` | 오류 메시지 | 3초 후 idle 복귀 |
| `error` | 오류 메시지 | 3초 후 idle 복귀 |

---

## 공통 예외 경로

모든 플로우에 공통으로 적용되는 예외 처리 원칙.

| 예외 상황 | 처리 방식 |
|-----------|-----------|
| 네트워크 단절 | 스낵바 안내 + 재시도 유도 |
| 권한 부족 | "권한이 없습니다" 팝업 (멤버 권한 설정에 따라) |
| 위자드 유효성 실패 | 해당 필드 강조 + 다음 단계 이동 차단 |
| 세션 만료 | `/login`으로 자동 리다이렉트 |
| 서버 오류 (5xx) | 에러 토스트 + 재시도 버튼 |

---

## 화면 간 연결 관계 요약

각 플로우에서 등장하는 화면의 전체 목록과 라우트는 **[화면 카탈로그](./screen-catalog.md)** 를 참조한다.

| 플로우 | 진입점 | 핵심 화면 | 종료점 |
|--------|--------|-----------|--------|
| 인증 게이트 | 앱 진입 | `파트너 로그인`, `파트너 신청 위자드`, `신청 상태 확인` | `파트너 홈` |
| 파트너 온보딩 | `파트너 로그인` | `파트너 신청 위자드` (5단계), `신청 상태 확인` | `파트너 홈` |
| 파티 생성 | `파티 목록` | `파티 생성 위자드` (6단계) | `파티 상세` |
| 이벤트 생성·운영 | `파티 상세` | `이벤트 생성`, `이벤트 상세`, `티켓 생성/편집` | `이벤트 상세` |
| 신청 심사 | `이벤트 상세` | 신청 상세 모달 | `이벤트 상세` |
| 정산 확인 | Bottom Nav 수익관리 탭 | `정산 관리` | `정산 관리` |
| QR 체크인 | `이벤트 상세` | `QRScannerScreen` | `이벤트 상세` |

---

## 관련 문서

- [화면 카탈로그](screen-catalog.md) — 각 화면의 상세 정보, 라우트 경로, UI 요소
- [디자인 시스템](design-system.md) — 디자인 토큰, 컴포넌트 테마, 위젯 패턴 카탈로그
- [정산 UI/UX 설계](../../features/partner-settlement/ui-ux-design.md) — 정산 플로우 상세 설계

---

*이 문서는 `app_router.dart`, `partner_apply_controller.dart`, `party_create_wizard_controller.dart`, `event_application_controller.dart`, `checkin_controller.dart` 소스를 기반으로 작성되었습니다.*
