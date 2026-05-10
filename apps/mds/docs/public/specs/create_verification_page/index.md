 Spec — CreateVerificationPage (app\_partner · CreateVerificationRoute)  

# Create Verification

## Overview

| Status | ✅ 디자인완료 — 8 state · 새 커스텀 인증 정의 + 입력 양식 빌더 |
|---|---|
| App | app_partner |
| Category | verification · partner ops · custom verification CRUD |
| Route / Surface | CreateVerificationRoute · widget: CreateVerificationPage |
| Path | /more/verifications/create |
| Hierarchy | Parent: VerificationManagePage (사용 중 탭의 AddActionCard 탭 시 push)Children: — (overlay만 — PopupMenu, snackbar; 내부 위젯 _FieldEditorCard는 별도 spec 없음) |
| Purpose | 파트너가 새 커스텀 인증을 정의하기 위한 풀-페이지 폼. 표시 이름·관리용 이름·설명 3개 기본 필드 + 동적으로 추가/재배치/삭제 가능한 입력 양식(text/file 필드)을 한 화면에 입력 후 저장. 파트너 인증 풀(verification_manage)에 새 row를 만드는 단일 진입점. |
| User journey | Entry points: 인증 관리 화면(사용 중 탭) → '새로운 인증 만들기' 카드 탭.Exit points: 저장 성공 → '인증이 생성되었습니다.' 안내 메시지가 노출되며 화면이 닫히고 사용 중 리스트에 새 인증이 등장 · AppBar back → 변경 무시하고 복귀 · 검증 실패 → 해당 입력란 아래에 inline 오류 노출 + 화면 유지 · 저장 오류 → 오류 안내 메시지가 잠깐 노출됨. |
| Background | 파트너 커스텀 인증은 (1) 표시 이름(유저에게 보임) · (2) 관리용 이름(내부 식별자) · (3) 설명(유저 가이드) · (4) 동적 입력 양식 4가지 요소로 구성. 양식은 빌더 패턴(추가→편집→재배치→삭제)으로 구현되어 우상단 + 아이콘에서 type을 고르면 새 필드 카드가 추가된다. drag handle은 44×44 영역으로 잡혀, 작은 hit으로 끌기에 실패하던 문제를 막는다. 저장이 완료되면 인증 관리 화면의 사용 중 리스트에 자동으로 반영된다. |
| Frequency | 활성 파트너 기준 분기당 0~수회. 셋업 직후 1~3회 집중 사용 후 가끔 신규 인증 추가. |

## History

이 spec의 주요 변경 이력. 최신 항목 위.

| Date | Version | Author | Changes |
|---|---|---|---|
| 2026-05-01 | 1.0 | mark-yun | v1.4 template으로 작성. 8 state(Default empty builder · Filled basic info · Add field popup · Field editor card · Reorder dragging · Validation error · Saving · Save success/error) → mini-table per state, baseline = Default(폼 비어있고 builder도 empty hint 노출). 파트너 brand color(#6c3ce1) viewport-scoped. |

[🧱 Layout](#layout) [🎨 States](#states) [🔄 Global Behavior](#global-behavior) [📖 Reference](#reference)

🧱

## Layout

화면 구조 — 영역, 정렬, 간격 규칙. 색·타이포 무시.

## Blueprint & tree

Scaffold = simpleAppBar('새 인증 만들기') + body(Form + ListView · pad `spacing-medium = 16`) + bottomNavigationBar(SafeArea + Padding(h:16, v:8) + ElevatedButton '저장하기'). body는 위에서 BasicInfo(섹션 타이틀 + 3 TextFormField) + 16gap + FormBuilder(타이틀 + add icon + ReorderableListView 또는 empty hint). 이 화면 자체에는 Loading 분기가 없음 — 로컬 상태만 사용 (controller는 fetch 안 함).

![blueprint](blueprint.png)

**Scaffold** ├─ **appBar**: simpleAppBar(title:'새 인증 만들기') ├─ **body**: **Form**(key) │ └─ **ListView**(pad `spacing-medium = 16`) │ ├─ _BasicInfo_ ← ② │ │ ├─ Text('기본 정보' · titleLarge) │ │ ├─ SizedBox(`spacing-medium`) │ │ ├─ TextFormField(label '인증 이름 (유저에게 표시)') │ │ ├─ SizedBox(`spacing-medium`) │ │ ├─ TextFormField(label '관리용 이름 (내부 식별용)') │ │ ├─ SizedBox(`spacing-medium`) │ │ └─ TextFormField(label '설명' · maxLines:2) │ ├─ SizedBox(`spacing-large = 24`) │ │ │ └─ _FormBuilder_ ← ③ │ ├─ Row.spaceBetween │ │ ├─ Text('입력 양식 설정' · titleLarge) │ │ └─ **PopupMenuButton<String>** (icon: add\_circle) │ │ └─ items: PopupMenuItem('text', '텍스트 입력') · PopupMenuItem('file', '파일 업로드') │ ├─ SizedBox(`spacing-small`) │ └─ if state.fields.isEmpty │ → **Container**(dashed-ish · '+ 버튼을 눌러 필드를 추가하세요') │ else │ → **ReorderableListView.builder**(shrinkWrap · NeverScrollable · proxyDecorator(Material radius-card)) │ └─ **\_FieldEditorCard** × N │ ├─ Card(Padding all `spacing-medium`) │ ├─ Row\[typeIcon · typeLabel · Spacer · IconButton(delete) · ReorderableDragStartListener(44×44 drag\_handle)\] │ ├─ Divider │ └─ Row\[Expanded(TextField '라벨') · gap 16 · Row\[Checkbox · '필수'\]\] └─ **bottomNavigationBar**: SafeArea + Padding(h 16, v 8) + ElevatedButton('저장하기') ← ④

## Spacing & alignment rules

| # | Region | Alignment | Spacing |
|---|---|---|---|
| — | Outer page padding | ListView pad-all spacing-medium (16) | 좌우 16 · 상하 16 (tile-내부 padding은 별도) |
| ① | AppBar | height 56 · centerTitle:false · scaffold-gray bg | title typography app-bar-title (18 / 700) |
| ② | BasicInfo | Column.start · 좌측 정렬 | title → field spacing-medium (16) · field 사이 spacing-medium (16) |
| ③ | FormBuilder | Column.start · header는 Row.spaceBetween (title 좌 + add icon 우) | title row → list spacing-small (8) · field card 사이 spacing-medium (16) |
| — | FieldEditor Card 내부 | Padding all spacing-medium (16) · Column | header row → divider, divider → label row 사이 spacing-small (8) · drag handle 44×44 |
| ④ | bottomNavigationBar | SafeArea + Padding(h spacing-medium (16), v spacing-small (8)) | button height 48 · 풀폭 |

## Sub-anatomy ① — TextFormField (basic info × 3)

Material InputDecoration default + label + hint. hintStyle은 onSurfaceVariant @ 0.6 opacity (Fix #1801). validator 실패 시 inline error 텍스트 + border error 색.

![blueprint](blueprint_2.png)

**TextFormField**(controller, onChanged → controller.update\*, validator) ├─ decoration: InputDecoration │ ├─ labelText: '인증 이름 (유저에게 표시)' ← ㉠ │ ├─ hintText: '예: 골프 핸디캡 인증' │ └─ hintStyle: bodyMedium · onSurfaceVariant @ 0.6 opacity └─ validator: (v) => v.isEmpty ? '이름을 입력해주세요.' : null ← ㉡

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | label | top-left · floating Material default | typography caption · color onSurface |
| ㉡ | input border | radius radius-input (12) · border 1px / focused 2px primary | height ~44 · padding-horizontal spacing-small (8) · text bodyMedium |

## Sub-anatomy ② — \_FieldEditorCard (양식 빌더 row)

각 필드는 Card 한 장. header(typeIcon + typeLabel + delete + drag) → divider → Row\[label 입력 + 필수 체크박스\]. drag handle은 44×44 명시 (Fix #1801) — 작은 hit target으로 인한 reorder 실수를 막음.

![blueprint](blueprint_3.png)

**Card**(margin only-bottom `spacing-medium (16)`) └─ **Padding**(all `spacing-medium`) └─ Column ├─ Row\[**Icon**(typeIcon · 18 / small) ← ㉠ │ gap `spacing-small (8)` │ **Text**(typeLabel · titleMedium bold) ← ㉡ │ **Spacer** │ **IconButton**(delete) ← ㉢ │ **ReorderableDragStartListener**(SizedBox 44×44 drag\_handle) ← ㉣ ├─ **Divider** └─ Row\[ Expanded → **TextField**(focusNode, label '라벨 (질문 내용)' · isDense · onChanged → onUpdate(field.copyWith(label))) ← ㉤ gap `spacing-medium (16)` Row\[**Checkbox**(activeColor primary, value field.required) · **Text**('필수' bodyMedium)\] ← ㉥ \]

| # | Region | Alignment | Spacing / tokens |
|---|---|---|---|
| ㉠ | typeIcon | 좌측 · 18 size | color onSurfaceVariant · icon: text→text_fields · file→upload_file · number→numbers · date→calendar_today |
| ㉡ | typeLabel | 좌측 flex 자유 | typography titleMedium bold · color onSurface |
| ㉢ | delete IconButton | 우측 | icon delete · color onSurfaceVariant |
| ㉣ | drag handle | 우측 · SizedBox 44×44 (Fix #1801) | icon drag_handle · ReorderableDragStartListener wrap — 길게 누르고 끌어 이동 |
| ㉤ | label TextField | flex · isDense:true | focusNode 사용 · onChanged → field.copyWith(label) · didUpdateWidget에서 외부 변경이 있을 땐 focus 없을 때만 sync |
| ㉥ | required check | 우측 · Row[Checkbox · Text] | activeColor color-primary · label bodyMedium |

🎨

## States

시각 변형 8종. baseline = Default(빈 폼 + empty builder hint), 나머지는 additive diff.

**State 식별 기준**: 표시 이름 / 관리용 이름 / 설명 / 입력 양식 입력 상태 · 검증 결과 · 필드 추가 메뉴 노출 여부 · 재배치 드래그 진행 여부 · 저장 진행 / 결과(성공·오류). 첫 진입 시 별도 데이터 조회 없이 빈 폼이 즉시 노출됨.

### State summary — 8 states

| State | Tag | 조건 (요약) | Key visual differentiator |
|---|---|---|---|
| Default · empty form | baseline | 진입 직후 · 입력 양식 0개 | 3개 빈 입력란 · '입력 양식' 아래 점선 empty hint · 저장 버튼 활성 |
| Basic info filled | progress | 3개 필드에 텍스트 입력 | 각 입력란에 텍스트 + 라벨이 위로 떠오른 상태 · 검증 통과 |
| Add field popup | overlay | + 아이콘 탭 | 우상단 팝업 메뉴(텍스트 입력 / 파일 업로드 2 항목) |
| Field editor card | builder | 입력 양식 1+ 추가됨 | 각 필드 카드(타입 아이콘 + 타입 라벨 + 삭제 + 드래그 + 라벨 + 필수 체크) |
| Reorder dragging | builder | 드래그 핸들을 길게 누르고 끄는 중 | 해당 카드가 약간 떠올라 그림자 강조 · 다른 카드 위치 swap 애니메이션 |
| Validation error | error | 저장 시 표시 이름/관리용 이름 빈 값 | 해당 입력란 테두리가 빨강 + 아래 '이름을 입력해주세요.' 안내 |
| Saving | async | 저장 진행 중 | 저장 버튼 자체는 시각적 변화 없음 — 별도 로더 표시 없음 |
| Save success / error | overlay | 저장 결과 | 성공 → '인증이 생성되었습니다.' 안내 + 화면 닫힘 · 오류 → 오류 안내 메시지 노출 |

![visual](visual_1.png)

🔄

## Global Behavior

cross-cutting · motion · global edges.

## Cross-cutting interactions

| 사용자 액션 | 화면에 보이는 결과 |
|---|---|
| OS back / AppBar back | 모든 state에서 가능 — 인증 관리 화면으로 복귀. 미저장 변경 보호 없음(변경 무시). |
| 키보드 호출/dismiss | 입력란을 탭하면 키보드가 올라오고 본문이 그만큼 스크롤됨. 빈 영역 탭 / focus를 잃으면 키보드가 내려감 |
| 앱 background → foreground | 입력 중이던 값은 그대로 유지 — 다시 돌아와도 보존됨. (앱 강제 종료 시는 사라짐) |
| 가로 회전 / 큰 글씨 | 모든 항목이 스크롤 가능 · 잘림 없음 |

## Motion & timing

| Token | Value | Use case |
|---|---|---|
| MinglitAnimation.micro | 100ms | Checkbox toggle ripple · IconButton ripple |
| MinglitAnimation.fast | 200ms | TextField focus border transition (1px → 2px) · Save button press feedback |
| MinglitAnimation.medium | 350ms | route push from VerificationManage · PopupMenu enter/exit · ReorderableListView item swap · snackbar slide-up |

| Transition | Duration (token) | Curve / notes |
|---|---|---|
| verification_manage → create (push) | medium (350ms) | Material default route transition |
| label floating animation | fast (200ms) | Material InputDecoration default — focus/blur 시 |
| PopupMenu open/close | medium (350ms) | Material default scale + fade |
| Reorder swap | medium (350ms) | ReorderableListView default reorderAnimationDuration |
| add field → editor card 등장 | fast (200ms) | setState 후 ListView 자체 layout — 별도 AnimatedSwitcher 없음 |

## Global edge cases

-   **네트워크 끊김** — 저장 시도 시 오류 안내 메시지가 잠깐 노출되며 폼은 그대로 유지됨
-   **인증 만료** — 인증 만료가 감지되면 오류 안내 메시지가 노출됨
-   **다크 모드** — 모든 색상이 다크 톤으로 자동 전환. focus 테두리 / 저장 버튼 / empty hint 영역 모두 다크 톤으로 dim
-   **접근성** — 입력 라벨, '필수' 체크박스, 드래그 핸들, 팝업 메뉴 모두 음성 안내 가능
-   **저성능 디바이스** — 드래그가 무거울 수 있음 — 명시적 드래그 영역에서만 동작하므로 비교적 가벼움

📖

## Reference

Implementation source + 인접 화면 link.

## Implementation source

| 항목 | Path / Reference |
|---|---|
| Widget class | CreateVerificationPage · 내부: _FieldEditorCard |
| File path | apps/app_partner/lib/src/features/verification/create/create_verification_page.dart |
| Controller | create_verification_controller.dart · createVerificationControllerProvider |
| State | CreateVerificationState(displayName · internalName · description · fields · submitting · error) · freezed |
| Route | CreateVerificationRoute({this.partnerId}) · path: /more/verifications/create |

## Related screens

| Spec | Relation |
|---|---|
| VerificationManagePage | Parent — 진입점, 저장 후 active 리스트 자동 갱신 |
| MorePage | Grandparent — 더보기 탭 root |