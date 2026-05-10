 Spec — DeletionVerifyPage (app\_user · DeletionVerifyRoute)  

# Deletion Verify Page

## Overview

| Status | 디자인완료 — wizard step 3/4 · 6 state (auth-method × verify-state) |
|---|---|
| App | app_user |
| Category | account · privacy · destructive · wizard-step · auth |
| Route / Surface | DeletionVerifyRoute — DeletionVerifyPage({reasonCode, reasonText}) |
| Path | /my/privacy/delete/verify · query: ?reasonCode=&reasonText= |
| Hierarchy | Parent: DeletionInfoPage — coordinator.pushVerify로 push.Children: DeletionCompletePage (success — coordinator.goComplete) · in-place confirm dialog (showMinglitConfirm) — wizard 마지막 mental gate. |
| Purpose | 탈퇴 요청 직전 본인 확인 — 비밀번호 사용자는 현재 비밀번호 입력으로, 소셜 사용자는 다음 단계의 reauth flow 안내로 가벼운 검증 추가. 탈퇴는 destructive + 되돌리기 어려운 액션이라 password / reauthenticate라는 사실상 두번째 인증을 명시적으로 통과하게 한다. |
| User journey | Entry points: 이전 안내 화면의 "계속 진행" 탭으로 진입.Exit points: ① "탈퇴 요청" 탭 + 본인 확인 통과 + 확인 다이얼로그의 "탈퇴 요청" → 마지막 완료 화면으로 이동 · ② 확인 다이얼로그의 "돌아가기" 또는 바깥 영역 탭 → 본 화면 그대로 유지 · ③ 비밀번호 빈 필드 / 잘못된 비밀번호 → 화면 머무름 (에러 안내 노출) · ④ 뒤로 가기 → 이전 안내 화면으로 복귀. |
| Background | 탈퇴가 타인이나 단말 탈취 시나리오에서 악용되지 않도록 본인 확인을 강제한다. 비밀번호 계정은 이 자리에서 비밀번호로 재확인하고, 소셜 계정은 다음 단계에서 재인증을 진행한다 (현재는 가벼운 통과 상태 — 향후 OAuth 재인증 단계가 추가될 예정). 확인 다이얼로그를 한 번 더 끼워 넣어 "버튼 잘못 누름" 사고를 막는다 — 다른 destructive flow와 동일한 톤. |
| Frequency | 매우 낮음 — 탈퇴 wizard 진입 시 1회. |

## History

이 spec의 주요 변경 이력. 최신 항목 위.

| Date | Version | Author | Changes |
|---|---|---|---|
| 2026-05-01 | 1.0 | mark-yun | v1.4 template으로 작성. wizard step 3/4 · 6 state — Password user(baseline · reason 동반) · Social user · 비밀번호 빈 필드 에러 · Submit loading · Confirm dialog · Reauth/Submit 실패. controller(accountDeletionControllerProvider) · usesPasswordAuth(user) · showMinglitConfirm · handleMinglitError 매핑. |

[🧱 Layout](#layout) [🎨 States](#states) [🔄 Global Behavior](#global-behavior) [📖 Reference](#reference)

🧱

## Layout

AppBar(title) + Expanded ListView(heading + 옵셔널 reason recap + auth input(password OR social info)) + Bottom CTA(단일 FilledButton, loading 시 spinner).

## Blueprint & tree

Scaffold + AppBar("본인 확인") + SafeArea Column. 위젯은 `currentUserProvider`를 watch — user가 null이면 빈 Scaffold(SizedBox.shrink) 반환(전이 frame). 일반적 진입 시: _heading + 14px sub copy + (옵셔널 reason recap Card) + (password TextField OR social info Card)_. `usesPasswordAuth(user)`로 비밀번호 vs 소셜 분기 — 두 경우의 두 번째 자식만 swap된다.

![blueprint](blueprint.png)

**Scaffold** └─ _if user == null: return Scaffold(SizedBox.shrink) — 빈 frame (transition)_ └─ **AppBar**(_title: Text("본인 확인")_) ← ① └─ **SafeArea** └─ **Column** ├─ **Expanded** ← ② │ └─ **ListView**(padding: `spacing-large (24)`) │ ├─ _heading group_ ← ㉠ │ │ ├─ Text("회원 탈퇴 전에 본인 확인이 필요해요.", titleMedium) │ │ ├─ SizedBox(`spacing-small (8)`) │ │ └─ Text("탈퇴 요청이 접수되면 7일 동안 복구할 수 있어요.", bodyMedium) │ ├─ SizedBox(`spacing-large (24)`) │ │ │ ├─ _if reason != null:_ ← ㉡ │ │ ├─ **Card** │ │ │ └─ **ListTile** │ │ │ ├─ leading: Icon(_check\_circle\_outline_) │ │ │ ├─ title: "선택한 탈퇴 사유" │ │ │ └─ subtitle: _withdrawalReasonLabel(reason.reasonCode)_ │ │ └─ SizedBox(`spacing-medium (16)`) │ │ │ └─ _if isPasswordUser:_ ← ㉢ │ └─ **MinglitTextField**(_label: "비밀번호" · obscure: true · errorText: \_passwordErrorText · hint: "현재 비밀번호를 입력해주세요"_) │ _else:_ │ └─ **Card** → **Padding**(`spacing-medium (16)`) → Text("소셜 로그인 계정은 다음 단계에서 재인증이 진행돼요.") │ └─ **Padding**(24, 8, 24, 24) ← ③ └─ **SizedBox**(width: ∞) └─ **FilledButton**(_onPressed: isLoading ? null : \_submitDeletion_) └─ child: _isLoading ? CircularProgressIndicator(20×20, strokeWidth 2) : Text("탈퇴 요청")_

| # | Region | Alignment | Spacing |
|---|---|---|---|
| — | Body padding | — | ListView padding spacing-large (24) all sides |
| ① | AppBar | title centered · leading back auto | height 56 · scaffold gray bg · border-bottom 없음 |
| ② | ListView body | vertical scroll | heading↔reason recap 사이 SizedBox spacing-large (24) · reason recap↔auth 사이 spacing-medium (16) |
| ㉠ | heading group | start · title + sub | title (titleMedium) ↔ sub (bodyMedium) 사이 SizedBox spacing-small (8) |
| ㉡ | reason recap (옵셔널) | ListTile default | Material Card · ListTile leading 24px · title bodyMedium · subtitle bodySmall |
| ㉢ | auth input | full width | password: TextField radius radius-input (12) · maxLines 1 · obscureText. social: Card padding spacing-medium (16) |
| ③ | Bottom CTA | full width | Padding(24, 8, 24, 24) · FilledButton 단일 · loading 시 spinner 20×20 stroke 2 |

## Sub-anatomy ① — Reason recap (옵셔널 ListTile in Card)

이전 안내 화면과 마찬가지로 사유가 없으면 통째로 빠진다. 안내 화면의 사유 카드와 달리 여기서는 한 줄짜리 가벼운 카드(좌측 아이콘 + 제목 + 부제) — 이미 사유를 한 번 보여준 뒤의 reminder 톤.

![blueprint](blueprint_2.png)

**Card** └─ **ListTile** ├─ leading: **Icon**(_Icons.check\_circle\_outline_) ← ㉠ ├─ title: **Text**("선택한 탈퇴 사유") ← ㉡ └─ subtitle: **Text**(_withdrawalReasonLabel(reason.reasonCode)_) ← ㉢

| # | Element | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | leading icon | vertical center · 좌측 16 | Material 24px Icons.check_circle_outline · color text-primary (default) |
| ㉡ | title | start · single line | typography bodyMedium |
| ㉢ | subtitle | start · single line | typography bodySmall · color text-secondary |

🎨

## States

6가지 시각 변형. baseline = 비밀번호 사용자 · 사유 동반. 소셜 사용자 · 비밀번호 빈 필드 에러 · 제출 진행 중 · 확인 다이얼로그 · 본인 확인/제출 실패.

### State summary — 6개 state

| State | Tag | 조건 (요약) | Key visual differentiator |
|---|---|---|---|
| Password user · 사유 동반 | baseline | 비밀번호 계정 + 이전 단계에서 사유 동반 | 사유 카드 + 비밀번호 입력란 + "탈퇴 요청" 활성 |
| Social user | variant | 소셜 계정 (Google / Apple / Kakao 등) | 비밀번호 입력란 대신 안내 카드 "다음 단계에서 재인증이 진행돼요" |
| 비밀번호 빈 필드 에러 | validation | 비밀번호 계정이 빈 필드로 "탈퇴 요청" 시도 | 입력란 빨간 외곽선 + 에러 안내 "비밀번호를 입력해주세요." |
| 제출 진행 중 | loading | 탈퇴 요청이 백엔드로 전송되고 응답을 기다리는 동안 | "탈퇴 요청" 버튼 위치에 회전하는 스피너 (라벨 사라짐) |
| Confirm dialog | modal | 본인 확인 통과 직후 한 번 더 묻는 단계 | 어두운 배경 + 다이얼로그 "정말 탈퇴할까요?" — 돌아가기 / 탈퇴 요청 |
| 본인 확인 / 제출 실패 | error | 본인 확인이나 탈퇴 요청이 실패한 경우 | 화면 하단에 에러 안내 스낵바 — 화면 그대로 유지 |

![visual](visual_1.png)

🔄

## Global Behavior

cross-cutting — 모든 state에 적용되는 액션 / motion / global edge cases.

## Cross-cutting interactions

| 사용자 액션 | 화면에 보이는 결과 |
|---|---|
| 뒤로 가기 (시스템 / AppBar) | 이전 안내 화면으로 복귀하며, 비밀번호 입력 내용은 사라진다. |
| 비밀번호 입력 중 키보드 등장 | 본문 영역이 자동으로 축소되어 입력란이 가려지지 않으며, 하단 CTA 영역은 안전 영역 하단에 고정된다. |
| "탈퇴 요청" 탭 | 비밀번호 계정이 빈 필드면 빈 필드 에러로 전이, 그렇지 않으면 본인 확인을 거쳐 확인 다이얼로그가 뜬다. |
| "탈퇴 요청" 탭 피드백 | 탭 시 짧은 ripple 피드백. |
| 다크 모드 토글 | 배경/카드/입력란/다이얼로그 모두 다크 토큰으로 자동 전환되며, error 톤도 다크에서 동일하게 유지된다. |
| 로그인 상태가 일시적으로 비는 순간 | 본문이 잠시 빈 화면으로 보일 수 있으며, 정상 흐름에서는 거의 발생하지 않는다. |

## Motion & timing

Source: `shared/packages/mds/core/lib/src/theme/minglit_design_tokens.dart` → `MinglitAnimation`.

| Token | Value | Use |
|---|---|---|
| MinglitAnimation.micro | 100ms | 버튼 / 입력란 포커스 ripple. |
| MinglitAnimation.fast | 200ms | 화면 진입 / 마지막 완료 화면으로의 전환 / 입력란 에러 외곽선 변화. |
| MinglitAnimation.medium | 350ms | 확인 다이얼로그 등장 / 스피너 등장과 사라짐. |
| (시스템 기본) 스피너 | 1000ms loop | 스피너 회전 주기. |

| Transition | Duration (token) | Curve / notes |
|---|---|---|
| 이전 단계 → 이 화면 진입 | fast (200ms) | 표준 좌→우 slide 전환. |
| 확인 다이얼로그 등장 | medium (350ms) | 화면 위에 페이드인. |
| 탈퇴 요청 성공 → 완료 화면 | fast (200ms) | 스택을 교체하는 전환. |
| "탈퇴 요청" 활성 ↔ 진행 중 스피너 | cut | 전환 애니메이션 없이 즉시 교체. |
| 입력란 에러 외곽선 | fast (200ms) | 외곽선이 부드럽게 빨간색으로 전환. |
| 스낵바 등장 / 사라짐 | ~250ms | 약 4초 후 자동으로 사라짐. |

## Global edge cases

-   **네트워크 끊김** — 본인 확인이나 탈퇴 요청이 실패하면 화면 하단 스낵바로 안내되고 화면은 그대로 유지된다.
-   **다크 모드** — 배경/카드/입력란/다이얼로그 모두 다크 토큰으로 자동 전환되고, 비밀번호의 점 문자도 다크에 맞는 톤으로 보인다.
-   **접근성** — 비밀번호는 가려져 있어 스크린 리더가 직접 읽지 않으며, 에러 안내는 별도로 안내된다.
-   **키보드 자동 포커스** — 화면 진입 직후 자동 포커스는 없다. 사용자가 입력란을 탭해야 키보드가 등장하며, 이는 의도된 한 단계의 mental gate.
-   **비동기 도중 화면 사라짐** — 본인 확인이나 탈퇴 요청 중 화면이 사라지면 후속 안내(스낵바, 화면 전환)는 자동으로 생략된다.

📖

## Reference

Implementation source + 인접 화면 link. Components / Tokens는 위 mini-table에 분산.

## Implementation source

| 항목 | Path / Reference |
|---|---|
| Widget class | DeletionVerifyPage · ConsumerStatefulWidget |
| File path | apps/app_user/lib/src/features/account_deletion/ui/deletion_verify_page.dart |
| Controller | accountDeletionControllerProvider — reauthenticate(password?) · requestDeletion({reason}) · controller state(isLoading) watch |
| Coordinator | accountDeletionCoordinatorProvider.goComplete() · account_deletion_coordinator.dart |
| Auth helper | usesPasswordAuth(user) — identities/appMetadata 검사 · account_deletion_flow.dart |
| Confirm | context.showMinglitConfirm(title, message, confirmLabel, cancelLabel) · handleMinglitError(context, error, stackTrace) · minglit_kit |
| Local state | _passwordController: TextEditingController · _passwordErrorText: String? |
| Route | DeletionVerifyRoute({reasonCode?, reasonText?}) · path: /my/privacy/delete/verify · app_routes.dart |

## Related screens

| Spec | Relation |
|---|---|
| DeletionReasonPage | Step 1/4 — 사유 선택. |
| DeletionInfoPage | Previous step (2/4) — coordinator.pushVerify로 진입. |
| DeletionCompletePage | Next (4/4) — confirm + requestDeletion 성공 시 goComplete. |
| LoginPage | 로그아웃 후 도착지 — CompletePage 단계에서 signOut 발생. |