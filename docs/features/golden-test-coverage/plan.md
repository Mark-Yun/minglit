# 골든 테스트 커버리지 보강 — 기술 설계

## 개요

골든 테스트 커버율을 전체 화면/컴포넌트로 확장한다. Issue #574 작성 시점(9%, 4개)에서 현재 상당히 진전되어 **Tier 1은 전부 완료**, 전체 약 25%(27/93)이다. 이 plan은 잔여 화면을 체계적으로 커버하는 구현 계획을 제시한다.

### 설계 원칙

1. **기존 패턴 일관성** — Alchemist + GoldenPageWrapper 패턴 그대로 유지. 새로운 프레임워크 도입 없음
2. **Controller 레벨 모킹** — Repository가 아닌 Controller/Coordinator의 `build()` override 패턴 사용 (기존 관례)
3. **PR 단위 = Feature 단위** — 한 feature 폴더 안의 화면들을 하나의 PR로 묶어 리뷰 효율 극대화
4. **CI 파이프라인 변경 불필요** — 현재 CI가 골든 비교 + 자동 재생성 + 자동 커밋까지 처리하므로 인프라 추가 없음

## 현황 분석

### 커버리지 현재 상태 (2026-04-04 기준)

| 앱/패키지 | 전체 화면 | 골든 커버 | 커버율 |
|-----------|----------|----------|--------|
| app_user | 22 | 12 | 55% |
| app_partner | 39 | 10 | 26% |
| minglit_kit | 32+ 위젯 | 1 | 3% |
| **합계** | **93** | **23** | **25%** |

### Tier 1 상태 (Issue 기준 8개)

**전부 완료.** EventDetailPage, EventApplicationWizardPage, TicketQRScreen, MatchingVoteScreen, PartnerHomePage, PartyListPage, EventDetailPage(partner), SettlementPage 모두 골든 테스트 존재.

## 구현 이슈 분할

| 순서 | 제목 | 앱 | 대상 화면 수 | 예상 규모 | 의존성 | 비고 |
|------|------|-----|-------------|----------|--------|------|
| 1 | test: app_user account/settings 골든 | app_user | 5 | M | 없음 | DeletionInfoPage(4화면), BlockedPartnersPage |
| 2 | test: app_user notification/identity 골든 | app_user | 3 | S | 없음 | NotificationList, NotificationSettings, IdentityVerification |
| 3 | test: app_user ticket 골든 | app_user | 2 | S | 없음 | MyTicketsPage, TicketSelectSheet |
| 4 | test: app_partner party detail 골든 (4탭) | app_partner | 1(4탭) | L | 없음 | PartyDetailPage — info/event/ticket/settings 탭 각각 시나리오 |
| 5 | test: app_partner event/ticket CRUD 골든 | app_partner | 4 | M | 없음 | EventCreatePage, TicketCreatePage, TicketEditPage, TicketManageScreen |
| 6 | test: app_partner member/admin 골든 | app_partner | 4 | M | 없음 | MemberListPage, MemberPermissionPage, ApplicationListPage, ApplicationDetailPage |
| 7 | test: app_partner party edit/location 골든 | app_partner | 5 | M | 없음 | PartyBasicInfoEdit, PartyCapacityEdit, PartyLocationEdit, LocationGuidePage, MatchingSettingsScreen |
| 8 | test: app_partner settlement/account 골든 | app_partner | 6 | M | 없음 | SettlementDetailPage, BankAccountPage, DeletionInfo/Reason/Verify/Complete |
| 9 | test: app_partner checkin/misc 골든 | app_partner | 4 | M | 없음 | CheckinPlaceholderPage, PartnerWelcomePage, ReviewVerificationScreen, EntryGroupEditorScreen |
| 10 | test: app_partner QR scanner 골든 | app_partner | 1 | S | #9 | QrScannerScreen — 카메라 플러그인 shim 필요, 별도 분리 |
| 11 | test: minglit_kit core 위젯 골든 (Batch 1) | minglit_kit | 8 | M | 없음 | MinglitButton, EmptyState, ErrorState, Skeleton, Badge, Tag, Chip, FilterChip |
| 12 | test: minglit_kit core 위젯 골든 (Batch 2) | minglit_kit | 8 | M | 없음 | BottomSheet, Dialog, ContentCard, Section, KeyValueRow, ListTile, TextField, BottomCTA |
| 13 | test: minglit_kit media/complex 위젯 골든 | minglit_kit | 8 | M | 없음 | Image, ImageCarousel, ImageSourceSheet, FilePicker, ParticipantGauge, NumberStepper, VerificationCard, AddActionCard |
| 14 | test: minglit_kit loading/notification 위젯 골든 | minglit_kit | 4 | S | 없음 | LoadingIndicator, MinglitAlert, NotificationTile, VerificationSelectCard |

> 이슈 #1~#3 (app_user), #4~#10 (app_partner), #11~#14 (minglit_kit)는 독립적으로 병렬 진행 가능.

## 화면별 모킹 전략

### app_user 미커버 화면

| 화면 | 주요 의존성 | 모킹 방식 | pumpBeforeTest |
|------|------------|----------|---------------|
| DeletionInfoPage (4화면) | AccountDeletionCoordinator, GoRouter | overrideWithValue(mock) | pumpAndSettle |
| BlockedPartnersPage | BlockedPartnersController | Fake subclass (build override) | pumpAndSettle |
| NotificationListScreen | NotificationListController | Fake subclass | pumpAndSettle |
| NotificationSettingsScreen | NotificationSettingsController | Fake subclass | pumpAndSettle |
| IdentityVerificationScreen | IdentityVerificationController | Fake subclass | pumpAndSettle |
| MyTicketsPage | MyTicketsController, HomeCoordinator | Fake subclass | pumpAndSettle |
| TicketSelectSheet | TicketSelectController | Fake subclass | pumpAndSettle |

### app_partner 미커버 화면

| 화면 | 주요 의존성 | 모킹 방식 | pumpBeforeTest | 특이사항 |
|------|------------|----------|---------------|---------|
| PartyDetailPage (4탭) | PartyDetailCoordinator, EventRepository, TicketRepository | Mock repositories + Fake coordinator | pumpAndSettle | 탭별 4개 시나리오 필수 |
| EventCreatePage | EventCreateController, PartyRepository | Fake subclass | pumpAndSettle | 다단계 폼 — step별 시나리오 |
| TicketCreatePage/EditPage | TicketController | Fake subclass | pumpAndSettle | |
| QrScannerScreen | 카메라 플러그인 | **플러그인 shim 필요** | pump(Duration) | 카메라 스트림 무한 루프 — pumpAndSettle 금지 |
| LocationGuidePage | LocationRepository | overrideWithValue | pumpAndSettle | WebView shim (기존 _FakeWebViewPlatform 재사용) |
| MemberListPage/PermissionPage | MemberRepository | Mock repository | pumpAndSettle | |
| SettlementDetailPage | SettlementRepository | Mock repository | pumpAndSettle | |

### minglit_kit 위젯

| 위젯 | 모킹 | pumpBeforeTest | 특이사항 |
|------|------|---------------|---------|
| MinglitButton (variants) | 없음 (순수 UI) | pump | 6+ variants: primary, secondary, outlined, text, icon, disabled |
| MinglitEmptyState | 없음 | pump | |
| MinglitErrorState | 없음 | pump | |
| MinglitSkeleton | 없음 | pump(Duration(ms: 300)) | shimmer 애니메이션 — pumpAndSettle 금지 |
| MinglitImage | 없음 (placeholder) | pump | 네트워크 이미지는 placeholder로 대체 |
| MinglitBottomSheet | 없음 | pumpAndSettle | showModalBottomSheet 호출 후 settle |

## 공통 인프라 개선

### 1. 공통 fixture 파일 신설 (선택)

현재 각 테스트 파일에 인라인 fixture가 중복되어 있다. 반복이 심해지면 아래 파일을 신설:

```
apps/app_user/test/utils/golden_fixtures.dart
apps/app_partner/test/utils/golden_fixtures.dart
```

단, 현재 규모에서는 인라인 유지가 더 단순할 수 있으므로 **이슈 #3 이후 판단**.

### 2. QR Scanner 카메라 shim

`QrScannerScreen` 골든을 위해 카메라 플러그인의 platform shim이 필요하다:

```dart
class FakeCameraPlatform extends CameraPlatform {
  // 최소 구현: availableCameras() → [], createCamera() → stub
}
```

이슈 #10에서 단독으로 처리하여 리스크 격리.

### 3. 다크모드 variant 전략

- **Tier 1 화면**: Light + Dark 필수 (이미 완료)
- **Tier 2 화면**: Light + Dark 필수
- **Tier 3 화면/컴포넌트**: Light 필수, Dark는 주요 상태 1개만 추가
- 표준 문서(Rule 3.1) 요구사항: Light/Dark + 접근성(Text Scale 1.5x/2.0x) + 상태별

> 접근성 variant는 이번 스코프에서 제외. 기본 상태 커버가 우선이며, 접근성 골든은 후속 이슈로 분리.

## 아키텍처 결정

### 1. PR 분할 단위: 화면 단독 vs Feature 묶음

**선택**: Feature 묶음 (1 PR = 1 feature 폴더 내 전체 화면)

화면 하나씩 PR을 만들면 40+ PR이 되어 리뷰 부하가 과도하다.
Feature 단위로 묶으면 mock 데이터와 helper를 공유할 수 있어 효율적이다.

### 2. Controller 모킹 레벨: Repository vs Controller

**선택**: Controller 레벨 (기존 관례 유지)

기존 골든 테스트가 모두 Controller/Coordinator의 `build()` override 패턴을 사용한다.
Repository 레벨로 내려가면 더 정확하지만 설정 코드가 급증하여 테스트 가독성이 떨어진다.

### 3. 접근성 variant 스코프

**선택**: 이번 스코프에서 제외

Rule 3.1이 Text Scale 1.5x/2.0x를 요구하지만, 현재 기본 커버리지가 25%인 상황에서 접근성까지 추가하면 작업량이 3배가 된다. 기본 Light/Dark 커버를 먼저 달성한 후 후속 이슈로 접근성을 추가한다.

### 4. QR Scanner 별도 분리

**선택**: 이슈 #10으로 단독 분리

카메라 플러그인 shim이 필요한 유일한 화면이다. 다른 화면과 함께 진행하면 shim 실패 시 전체 PR이 블록된다. 리스크 격리를 위해 단독 이슈로 처리한다.

## 리스크 및 대응

| 리스크 | 확률 | 영향 | 대응 |
|--------|------|------|------|
| PartyDetailPage 4탭 mock이 복잡하여 예상보다 시간 소요 | 중 | 중 | 이슈 #4를 L 규모로 산정. 탭별로 점진적 커밋하여 중간 리뷰 가능하게 구성 |
| QR Scanner 카메라 shim이 Flutter 버전에 따라 동작 불일치 | 중 | 저 | 이슈 #10을 다른 이슈와 독립적으로 진행. 실패 시 스킵하고 후속 처리 |
| minglit_kit 위젯 32개 골든 생성으로 CI 시간 증가 | 저 | 중 | 골든 테스트는 `--tags golden`으로 분리되어 있으므로 일반 테스트에 영향 없음. CI 시간이 문제되면 matrix 분할 검토 |
| 대규모 골든 이미지 커밋으로 repo 크기 증가 | 중 | 저 | CI 골든만 커밋 (Ahem 폰트, 작은 파일). Platform 골든은 .gitignore 처리 검토 |
| 인라인 fixture 중복이 유지보수 부담 | 중 | 저 | 이슈 #3 완료 후 중복 정도를 평가하여 공통 fixture 파일 신설 여부 결정 |

## 실행 순서 권장

```
Phase 1 (병렬):  이슈 #1~#3 (app_user)  +  이슈 #11~#12 (minglit_kit Batch 1, 2)
Phase 2 (병렬):  이슈 #4~#6 (app_partner core)  +  이슈 #13~#14 (minglit_kit Batch 3, 4)
Phase 3 (순차):  이슈 #7~#9 (app_partner remaining)
Phase 4 (순차):  이슈 #10 (QR Scanner — 리스크 격리)
```

Phase 1 완료 후 커버율: 약 55% → Phase 2 완료 후: 약 80% → Phase 3 완료 후: 약 95% → Phase 4 완료 후: 100%
