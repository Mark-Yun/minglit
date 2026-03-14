# 파트너 앱 사용자 여정 (User Flows)

이 문서는 밍릿 파트너 앱(`app_partner`)의 주요 사용자 여정과 핵심 비즈니스 로직에 따른 화면 전이 흐름을 정의합니다. 모든 화면 명칭과 라우트 경로는 [화면 카탈로그(screen-catalog.md)](screen-catalog.md)를 준수합니다.

## 1. 개요
파트너 앱은 사용자가 파트너 권한을 획득하는 **온보딩** 단계부터, 자신의 공간을 등록하고 **이벤트를 운영**하며 **수익을 정산**받는 전 과정을 포괄합니다. 각 여정은 복잡한 상태 전이를 포함하며, 특히 인증 게이트를 통해 사용자의 권한 상태에 맞는 최적의 화면을 제공합니다.

---

## 2. 인증 게이트 및 초기 진입 플로우
앱 실행 시 사용자의 인증 상태와 파트너 온보딩 완료 여부를 체크하여 적절한 페이지로 리다이렉트합니다.

```mermaid
graph TD
    Start([앱 실행]) --> Loading[로딩 및 상태 확인]
    Loading --> AuthCheck{로그인 여부}
    
    AuthCheck -- No --> Login[파트너 로그인 /login]
    Login --> LoginSuccess[로그인 성공]
    LoginSuccess --> Loading
    
    AuthCheck -- Yes --> OnboardingCheck{온보딩 상태}
    
    OnboardingCheck -- "미신청 (needsApplication)" --> Apply[파트너 신청 위자드 /apply]
    OnboardingCheck -- "임시저장 (draftInProgress)" --> Apply
    
    OnboardingCheck -- "심사중 (pendingReview)" --> ApplyStatus[신청 상태 확인 /apply/status]
    OnboardingCheck -- "보완필요 (needsCorrection)" --> ApplyStatus
    
    OnboardingCheck -- "승인완료 (hasPartner)" --> Main[파트너 홈 /]
    
    ApplyStatus -- "수정하기 클릭" --> Apply
    Apply -- "제출 완료" --> ApplyStatus
    Main --> BottomNav[하단 내비게이션 활성화]
```

---

## 3. 여정 1 — 파트너 온보딩 (입점 신청)
일반 유저가 파트너가 되기 위해 사업자 정보와 증빙 서류를 제출하는 5단계 위자드 프로세스입니다.

```mermaid
graph TD
    A[PartnerApplyPage 진입] --> S1[Step 1: 기본 매장 정보]
    S1 -- "다음" --> S2[Step 2: 사업자 정보]
    S2 -- "이전" --> S1
    S2 -- "다음" --> S3[Step 3: 연락처 및 정산 계좌]
    S3 -- "이전" --> S2
    S3 -- "다음" --> S4[Step 4: 증빙 서류 업로드]
    S4 -- "이전" --> S3
    S4 -- "다음" --> S5[Step 5: 최종 확인 및 제출]
    
    S5 -- "제출" --> Submit{제출 처리}
    Submit -- "성공" --> Status[PartnerApplyStatusPage 심사중]
    Submit -- "오류" --> Error[에러 팝업/토스트]
    Error --> S5
    
    Status -- "관리자 보완 요청" --> Correction[상태: 보완 필요]
    Correction -- "수정하기" --> S1
    
    Status -- "관리자 최종 승인" --> Home[PartnerHomePage 진입]
```

---

## 4. 여정 2 — 파티 생성 (장소 등록)
파트너가 이벤트를 개최할 기반이 되는 파티(매장) 공간을 등록하는 6단계 위자드입니다.

```mermaid
graph TD
    List[PartyListPage] --> CreateBtn[파티 생성 버튼 클릭]
    CreateBtn --> W1[Step 1: 기본 정보 - 이름/설명/이미지]
    W1 -- "다음" --> W2[Step 2: 위치 - 지도/상세주소]
    W2 -- "다음" --> W3[Step 3: 인원 및 연락처]
    W3 -- "다음" --> W4[Step 4: 입장 규칙 - 그룹 설정]
    W4 -- "다음" --> W5[Step 5: 티켓 템플릿]
    W5 -- "다음" --> W6[Step 6: 최종 리뷰]
    
    W6 -- "생성 완료" --> Detail[PartyDetailPage]
    
    Detail -- "정보 수정" --> EditWizard[편집 모드 진입]
    EditWizard -- "기존 데이터 프리필" --> W1
```

---

## 5. 여정 3 — 이벤트 생성 및 운영
등록된 파티를 기반으로 실제 모집 일정(이벤트)을 생성하고 관리합니다.

```mermaid
graph TD
    PartyDetail[PartyDetailPage] --> EventTab[이벤트 관리 탭]
    EventTab --> CreateEv[이벤트 생성 버튼]
    CreateEv --> EvForm[EventCreatePage: 날짜/시간/정원 설정]
    EvForm -- "저장" --> PartyDetail
    
    PartyDetail --> EvList[이벤트 리스트]
    EvList -- "클릭" --> EvDetail[EventDetailPage: 운영 대시보드]
    
    EvDetail --> Ops{운영 작업}
    Ops --> Scan[QR 스캐너 실행]
    Ops --> Manage[참가자 명단 관리]
    Ops --> Ticket[티켓 설정 변경]
```

---

## 6. 여정 4 — 신청 심사 (참가 승인)
유저들이 신청한 이벤트 참가 요청을 검토하고 승인 또는 거절합니다.

```mermaid
graph TD
    EvDetail[EventDetailPage] --> AppList[신청자 명단 확인]
    AppList --> AppItem[개별 신청 상세/프로필]
    
    AppItem --> Review{심사 결정}
    Review -- "승인" --> Approve[상태: 승인됨/티켓 발송]
    Review -- "거절" --> Reject[거절 사유 입력]
    Review -- "보완요청" --> NeedsMore[보완 요청 메시지 발송]
    
    Approve --> Update[명단 현황 업데이트]
    Reject --> Update
    NeedsMore --> Update
```

---

## 7. 여정 5 — 정산 확인 및 관리
이벤트 운영을 통해 발생한 매출을 확인하고 정산을 관리합니다.

```mermaid
graph TD
    Tab[SettlementPage: 수익 관리] --> Summary[누적 수익 및 정산 가능 금액 확인]
    Summary --> History[월별/이벤트별 상세 내역]
    History --> Detail[정산 상세 리포트]
    
    Summary --> Account[정산 계좌 등록/변경]
    Summary --> Request[정산 신청]
    
    subgraph "상세 설계 참조"
        Ref[../../features/partner-settlement/ui-ux-design.md]
    end
    
    Detail -.-> Ref
```

---

## 8. 여정 6 — QR 체크인 플로우
현장에서 유저의 디지털 티켓을 스캔하여 입장을 확인하는 프로세스입니다.

```mermaid
graph TD
    EvDetail[EventDetailPage] --> ScanBtn[QR 스캔 버튼 클릭]
    ScanBtn --> Scanner[QRScannerScreen 실행]
    
    Scanner -- "QR 코드 인식" --> Proc{CheckinController: 검증}
    
    Proc -- "성공" --> Success[체크인 완료 표시/이름 확인]
    Proc -- "이미 체크인됨" --> Already[이미 입장한 유저 경고]
    Proc -- "유효하지 않음" --> Invalid[위변조 또는 타 이벤트 티켓 에러]
    Proc -- "네트워크 에러" --> Error[재시도 안내]
    
    Success --> Scanner
    Already --> Scanner
    Invalid --> Scanner
```

---

## 9. 예외 및 에러 경로
- **네트워크 단절**: 모든 API 요청 시 오프라인 상태이면 스낵바를 통해 안내하고 재시도를 유도합니다.
- **권한 부족**: 파트너 멤버 권한 설정에 따라 특정 메뉴(정산, 멤버 관리 등) 접근 시 "권한이 없습니다" 팝업을 노출합니다.
- **데이터 유효성 실패**: 위자드 단계 이동 시 필수 항목 누락 시 해당 필드를 강조하고 이동을 차단합니다.
