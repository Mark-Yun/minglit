---
source_url: https://github.com/Mark-Yun/minglit/issues/683
captured_at: 2026-03-28
issue_number: 683
state: closed
labels: [audit-report]
author: Mark-Yun
title: "🎨 UI/UX 감사 — 2026-03-29"
---

# 🎨 UI/UX 감사 — 2026-03-29

> Issue #683 · closed · created 2026-03-28T16:13:03Z · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/683

## Body

## UI/UX 디자인 감사 리포트 (2026-03-29)

### 1. 디자인 토큰 준수

#### A. 하드코딩 색상 — 12건 (3 파일)

| 파일 | 건수 | 내용 | 심각도 |
|------|------|------|--------|
| `app_partner/.../home/widgets/todo_summary_chips.dart` | 7 | 칩 배경색 `#FFF0F0`, `#F0F0FF`, `#FFF8E1`, `#F5F5F5`, 텍스트 `#AAAAAA` 등 | P2 |
| `app_partner/.../settlement/widgets/settlement_shimmer.dart` | 4 | shimmer 색상 `#3A3A3A`, `#E0E0E0`, `#4A4A4A`, `#F5F5F5` | P3 |
| `app_partner/.../checkin/checkin_placeholder_page.dart` | 1 | `Color(0xFF6C3CE1)` = MinglitPartnerColors.primary 직접 사용 (토큰 참조로 교체 가능) | P3 |

**todo_summary_chips.dart**가 가장 문제. 배경색 3종(`#FFF0F0`, `#F0F0FF`, `#FFF8E1`)이 디자인 토큰에 없는 새로운 색상. 시맨틱 색상 토큰 확장 또는 `colorScheme` 기반으로 전환 필요.

#### B. 하드코딩 폰트 크기 — 6건 (4 파일)

| 파일 | 건수 |
|------|------|
| `onboarding_step_guide.dart` | 3 |
| `ticket_list_item.dart` | 1 |
| `settlement_status_badge.dart` | 1 |
| `event_action_card.dart` | 1 |

TextTheme 슬롯 사용 권장.

#### C. 비표준 버튼 — 별도 스캔 필요 (이전 감사와 동일 수준으로 추정)

### 2. Golden Test 커버리지

| 항목 | 수치 |
|------|------|
| 전체 page/screen 파일 | **51** |
| golden test 파일 | **9** |
| 커버리지 | **17.6%** |
| 미커버 화면 | **46** |
| 골든 이미지 파일 (.png) | **30+** (light + dark) |

**주요 미커버 화면** (우선순위 높은 것):
- `event_detail_page.dart` (유저) — 핵심 화면
- `party_detail_page.dart` (파트너) — 핵심 화면
- `partner_home_page.dart` — 파트너 메인
- `purchase_history_page.dart` — 결제 내역
- `settlement_page.dart` / `settlement_detail_page.dart` — 정산
- `login_page.dart` / `partner_login_page.dart` — 인증
- `party_create_wizard_page.dart` — 핵심 생성 플로우
- `event_application_wizard_page.dart` — 핵심 신청 플로우

### 3. 골든 이미지 시각 분석

골든 이미지 30+ 장 존재 (app_partner/test/goldens). settlement 빈 상태, event card, upcoming events 등.
- light/dark 모드 쌍으로 관리되고 있어 양호
- CI용 별도 디렉토리(`goldens/ci/`) 분리되어 있어 체계적

### 4. 문서-코드 일치

`minglit_design_tokens.dart` ↔ `docs/ux/design-system/01-foundation.md` **완전 일치**.
- 신규 토큰 없음
- 삭제된 토큰 없음
- 값 변경 없음

### 5. 문서 최신화

현재 `docs/ux/design-system/` 7개 문서가 코드와 동기화 상태 양호. 이번 감사에서는 업데이트 불필요.

---

### 권장 조치

| # | 항목 | 우선순위 | 예상 작업 |
|---|------|----------|----------|
| 1 | `todo_summary_chips.dart` 하드코딩 색상 토큰화 | P2 | 시맨틱 색상 토큰 추가 또는 colorScheme 활용 |
| 2 | 핵심 화면 golden test 추가 (event_detail, party_detail, home 등) | P2 | 8~10개 golden test 추가 |
| 3 | `settlement_shimmer.dart` shimmer 색상 테마화 | P3 | 다크/라이트 모드별 shimmer 색상을 ThemeData에서 가져오기 |
| 4 | `checkin_placeholder_page.dart` 색상 토큰 참조 | P3 | `MinglitPartnerColors.primary` 상수 사용 |
| 5 | 하드코딩 fontSize 4파일 TextTheme 전환 | P3 | TextTheme 슬롯 매핑 |

## Comments (2)

### Comment 1 — @Mark-Yun on 2026-03-28

### 3. 골든 이미지 시각 분석 (추가)

골든 이미지를 직접 분석한 결과:

#### settlement_empty_state_default.png
- ✅ 중앙 정렬된 아이콘 + 텍스트 구조
- ⚠️ **디자인 시스템 미준수**: 03-patterns.md Empty State 표준은 아이콘 + 제목 + **설명 텍스트** + **CTA 버튼(선택)** 구조인데, 현재는 아이콘 + "정산 내역이 없습니다" 한 줄만 표시
- 설명 텍스트(예: "파티 이벤트를 진행하면 정산 내역이 여기에 나타나요") 추가 권장
- (subtitle 변형 골든은 별도 존재하므로 일부 해결된 상태일 수 있음)

#### event_card_full.png
- ✅ 브랜드 컬러(#9900FF purple) 사용: "20/20명" 텍스트
- ✅ 파티 제목 + 날짜/시간 + 인원 정보 계층 구조 양호
- ⚠️ 카드 이미지 영역이 빈 상태로 렌더링됨 (네트워크 이미지가 golden test에서 로드되지 않는 것은 정상이나, placeholder/fallback 이미지 표시 여부 확인 필요)
- ✅ 좌우 아이콘 버튼 배치 확인

### Comment 2 — @Mark-Yun on 2026-03-28

🤖 **tpm-staff** 분석 완료.

**결과:**
- actionable 항목: 0건 (신규 이슈 불필요)
- skip 항목: 5건

**Skip 이유:**
| # | 항목 | 이유 |
|---|------|------|
| 1 | todo_summary_chips.dart 하드코딩 색상 (P2) | 이미 #652 에서 P1으로 추적 중 (report-exec, 사람 판단 대기) |
| 2 | Golden test 커버리지 17.6% | 단순 수치 — 구체적 갭이 아니면 스킵 |
| 3 | settlement_shimmer.dart shimmer 색상 (P3) | 이미 #652 에서 추적 중 + P3 출시 전 배제 |
| 4 | checkin_placeholder_page.dart 색상 (P3) | P3 스타일/컨벤션 — 출시 전 배제 |
| 5 | 하드코딩 fontSize 4파일 (P3) | P3 스타일/컨벤션 — 출시 전 배제 |

**참고**: 주요 항목은 #652 (report-exec)에서 사람 판단 대기 중. 중복 이슈 생성하지 않음.

원본 리포트를 닫습니다.
