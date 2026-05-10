 Spec — PartnerApplicationDetailPage (app\_partner · PartnerApplicationDetailRoute)  

# 파트너 신청 상세 (관리자 검토)

## Overview

| Status | ✅ 디자인완료 |
|---|---|
| App | app_partner |
| Category | admin · partner application review |
| Route / Surface | PartnerApplicationDetailRoute |
| Path | /admin/applications/:applicationId |
| Hierarchy | Parent: — (admin 전용 상세 화면 · 별도 list 진입)Children: 이미지 미리보기 다이얼로그 (인라인) · 외부 앱(PDF/문서) |
| Purpose | 관리자(파트너 앱 내부 admin 권한)가 신규 파트너 신청서의 기본 정보 · 사업자 등록증 / 통장 사본 등 첨부 파일을 검토하고 승인 / 보완 요청 / 반려 중 한 가지 처분을 내린다. 신청자(일반 파트너 후보)가 보는 status 화면은 별도(PartnerApplyStatusPage) — 본 화면은 처분 권한 있는 admin 전용. |
| User journey | Entry points: admin 신청 목록 → 행 탭 (또는 push notification deep link) → 본 화면.Exit points: 처분 후 toast 노출 + provider invalidate (status가 'pending' → 'approved'/'rejected'/'needs_correction'으로 갱신, 같은 화면에서 결과 섹션이 review 섹션 자리로 교체) · AppBar back으로 list 복귀. |
| Background | 파트너 가입 심사는 사업자 진위 검증과 정산 계좌 일치성이 핵심이라 단순 form 승인이 아닌 첨부 문서 열람 + 관리자 코멘트 기록이 필요. 처분 3종(승인 / 보완 요청 / 반려)을 단일 화면 하단 가로 3-button으로 묶어 "신중한 한 번"을 유도. 디자인 검증을 위해 더미 ID로 진입하면 샘플 데이터를 화면에 보여주는 모드도 있음. |
| Frequency | admin이 신청 들어올 때만 (불규칙) |

## History

| Date | Version | Author | Changes |
|---|---|---|---|
| 2026-05-01 | 1.0 | mark-yun | v1.4 template 신규 작성. 6개 state enumerate (Pending baseline / Approved / Rejected / Needs correction / Loading / Error/Not-found). Image preview dialog는 별도 sub-state로. |

[🧱 Layout](#layout) [🎨 States](#states) [🔄 Global Behavior](#global-behavior) [📖 Reference](#reference)

🧱

## Layout

AppBar + 스크롤 body. body는 기본정보 → 첨부파일 → (심사 대기 상태면 검토, 아니면 결과) 섹션 순서.

## Blueprint & tree

AppBar(h56) + 스크롤 body(padding 16). Column(crossAxis: start)에 Section header → InfoRow\*N → 다음 Section header → ... 패턴. status 'pending' 시 하단에 TextField + 3-button. 그 외 status는 결과 섹션(상태 + admin comment).

![blueprint](blueprint.png)

**Scaffold** └─ **AppBar**('신청 상세') ← ① └─ **body**: 데이터 단계별 분기 ├─ 로딩 → 중앙 스피너 ├─ 에러 또는 신청 없음 → 중앙 평문 안내 └─ 결과 → 스크롤 body ├─ _기본정보 섹션_ ← ② │ · 헤더: '기본 정보' │ · 정보 행 6개 (브랜드명 / 사업자명 / 대표자 / 사업자번호 / 연락처 / 주소) │ ├─ Gap: `spacing-large (24px)` │ ├─ _첨부파일 섹션_ ← ③ │ · 헤더: '첨부 파일' │ · 파일 링크 행 (사업자등록증 · 통장사본) │ ├─ Gap: `spacing-large (24px)` │ ├─ 심사 대기 상태일 때: │ └─ _검토 섹션_ ← ④ │ · 헤더: '검토' │ · 관리자 코멘트 입력란 (3줄) │ · Gap spacing-medium │ · 3개 버튼 (승인 / 보완요청 / 반려) │ └─ 처분 완료 상태일 때: └─ _결과 섹션_ · 헤더: '검토 결과' · 상태 행 + (코멘트가 있으면) 코멘트 행

## Spacing & alignment rules

| # | Region | Alignment | Spacing |
|---|---|---|---|
| — | Outer body padding | — | all spacing-medium (16px) |
| ① | AppBar | title leading + back | height: 56 |
| ②③④ | Section | crossAxis: start | section 사이: spacing-large (24px) · header padding-bottom: spacing-small (8px) · row padding-bottom: spacing-small (8px) |
| — | InfoRow / FileLinkRow | label width: 100px (fixed) | label↔value: 0 (lays out via SizedBox(width: 100)) |
| ④ buttons | 3-button row | Expanded each · gap spacing-medium (16px) | height: ElevatedButton 기본 (44~48) |

## Sub-anatomy ① — InfoRow

좌측 100px 폭 라벨 + 우측 가변 폭 값. 라벨은 보조 색상의 작은 텍스트, 값은 본문 텍스트. 값이 비어있으면 '-' 폴백.

![blueprint](blueprint_2.png)

**Padding**(bottom: `spacing-small (8px)`) └─ **Row**(crossAxis: start) ├─ **SizedBox**(width: 100) ← ㉠ │ └─ **Text**(label, bodySmall, onSurfaceVariant) └─ **Expanded** ← ㉡ └─ **Text**(value ?? '-', bodyMedium)

## Sub-anatomy ② — FileLinkRow (image / PDF)

라벨 + "다운로드" 텍스트 버튼(눈 아이콘). 파일이 없으면 행 자체가 보이지 않음. 탭 시 이미지(jpg/png/gif/webp)는 인앱 미리보기 다이얼로그(0.5×~4× 줌)로, 그 외(PDF 등)는 OS 외부 앱으로 위임.

![blueprint](blueprint_3.png)

**Padding**(bottom: `spacing-small (8px)`) └─ **Row** ├─ **SizedBox**(width: 100) ← ㉠ │ └─ **Text**(label, bodySmall, onSurfaceVariant) └─ **TextButton.icon** ← ㉡ icon: visibility\_outlined (size: small=20) label: '다운로드' (l10n) onPressed: \_openFile(path)

🎨

## States

신청 상태에 따라 검토 섹션과 결과 섹션이 갈린다. 추가로 데이터 로딩/에러 분기.

### State summary

| State | Tag | 조건 (요약) | Key visual differentiator |
|---|---|---|---|
| Pending review 🎯 | baseline | 심사 대기 상태 | 하단에 코멘트 입력란 + 3개 버튼 (승인 / 보완요청 / 반려) |
| Approved | processed | 승인 처리 완료 | 하단 결과 섹션 — 상태 + 관리자 코멘트 |
| Rejected | processed | 반려 처리 완료 | 동일 결과 섹션 (상태값만 다름) |
| Needs correction | processed | 보완 요청 처리 완료 | 동일 결과 섹션 + 보완 안내 코멘트 |
| Loading | async | 데이터 로딩 중 | 중앙 스피너 |
| Not found / Error | error | 해당 신청 없음 또는 로딩 실패 | 중앙 평문 메시지 |
| Image preview (dialog) | overlay | 이미지 첨부파일 탭 | 전면 다크 다이얼로그 · 핀치 줌 · 우상단 닫기 X |

![visual](visual_1.png)

🔄

## Global Behavior

cross-cutting interactions, motion, edge cases.

## Cross-cutting interactions

| 사용자 액션 | 화면에 보이는 결과 |
|---|---|
| 뒤로 가기 (OS back / AppBar back) | 이전 화면(관리자 신청 목록 등)으로 복귀. |
| 처분 진행 중 다른 액션 | 전체 화면 로딩 overlay가 추가 입력을 차단. |
| 처분 완료 토스트 | "처리되었습니다 — 상태" 안내 + 검토 섹션이 결과 섹션으로 자동 교체. |
| 처분 실패 (예: 네트워크) | 에러 스낵바/다이얼로그로 안내 (서버 로그에도 함께 전송). |
| 외부 앱 진입 (PDF 등) | OS 기본 파일/PDF 뷰어로 위임 → 앱이 백그라운드. 복귀 시 본 화면 그대로 유지. |

## Motion & timing

| Token | Value | Use case |
|---|---|---|
| MinglitAnimation.fast | 200ms | 화면 진입/이탈 · 버튼 ripple |
| MinglitAnimation.medium | 350ms | 다이얼로그 진입 · 검토 → 결과 섹션 전환 |

| Transition | Duration (token) | Curve / notes |
|---|---|---|
| 화면 진입 | fast (200ms) | Material slide push |
| 처분 후 검토 → 결과 | medium (350ms) | 크로스페이드 |
| 이미지 미리보기 다이얼로그 진입 | medium (350ms) | scale + fade (기본 다이얼로그) |
| 이미지 핀치 줌 | 실시간 (제스처 추적) | 기본 — 별도 토큰 없음 |

## Global edge cases

-   **네트워크 끊김** — 처분 시 시간 초과 시 에러 스낵바로 안내. 사용자 재시도 가능.
-   **첨부파일 URL 만료** — 임시 URL은 1시간 후 만료. 미리보기에 오래 머문 뒤 다음 클릭 시 재발급 필요 (현재는 매 클릭 재발급).
-   **다크 모드** — 컬러 스킴 자동 전환. 액션 버튼은 partner primary로 자연 적응. 이미지 다이얼로그는 항상 다크 배경 유지.
-   **접근성** — 정보 행의 라벨 폭이 100px로 고정되어 큰 글씨 시 잘림 위험 — 향후 세로 레이아웃 검토.
-   **다국어** — 모든 라벨/문구가 다국어화. 영문 fallback 존재.

📖

## Reference

Implementation source + 인접 화면.

## Implementation source

| 항목 | Path / Reference |
|---|---|
| Widget class | PartnerApplicationDetailPage (ConsumerStatefulWidget) |
| File path | apps/app_partner/lib/src/features/admin/partner_application_detail_page.dart |
| Provider | partnerApplicationProvider(applicationId: ...) (riverpod_annotation FutureProvider) · partnerRepositoryProvider · globalLoadingControllerProvider |
| Repository methods | getAllApplications(status: 'all') · reviewApplication(applicationId, status, adminComment) · getSignedUrl(path) |
| Route | PartnerApplicationDetailRoute · path: /admin/applications/:applicationId · dummy-id 모드 지원 |

## Related screens

| Spec | Relation |
|---|---|
| PartnerApplyPage | 신청자 측 작성 화면 — 본 화면이 검토하는 데이터를 만든 곳. |
| PartnerApplyStatusPage | 신청자 측 결과 확인 화면 — 본 화면 처분 결과가 그쪽에 반영. |
| EventApplicationDetailPage | 구분 — 이름이 비슷하지만 역할 다름 (이벤트 자체 신청 상세). |
| VerificationManagePage | 유사 — admin 검증 관리 흐름의 형제. |