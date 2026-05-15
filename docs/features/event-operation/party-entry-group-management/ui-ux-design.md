# Party Entry Group Management UX Design Guide

## Overview
이 문서는 파트너가 파티의 입장 조건(Entry Group)을 관리하는 화면에 대한 UX 디자인 가이드를 제공합니다. 기존의 "준비 중" 토스트 메시지를 대체하고, 실제적인 엔트리 그룹 추가, 수정, 삭제 기능을 제공하는 것을 목표로 합니다.

## UX Principles
- **Consistency**: 다른 관리 화면(인증 관리, 티켓 관리 등)과 일관된 레이아웃 및 디자인 토큰을 사용합니다.
- **Clarity**: 각 엔트리 그룹의 상세 조건을 명확하게 요약하여 보여주고, 편집 및 삭제 액션을 직관적으로 배치합니다.
- **Affordance**: 카드가 탭 가능하다는 시각적 힌트를 제공하여 편집기 진입을 용이하게 합니다.

## UI Specification

### 1. Screen Structure
- **AppBar**: `MinglitTheme.simpleAppBar`를 사용하며, 타이틀은 "입장 조건 관리"로 설정합니다.
- **Content Area**: 
  - 상단에 `AddActionCard`를 배치하여 "새로운 입장 조건 추가" 기능을 강조합니다.
  - 그 아래에 현재 설정된 엔트리 그룹 리스트를 배치합니다.
  - 리스트가 비어있을 경우 `MinglitEmptyState.inline`을 사용하여 상태를 알립니다.

### 2. Card Design (Entry Group Card)
- **Shape**: `MinglitRadius.card` 적용, `outlineVariant` 보더 사용.
- **Layout**:
  - `EntryGroupDetail` 위젯을 사용하여 정보를 표시합니다.
  - 우측 상단 또는 우측 중앙에 `Icons.chevron_right`를 배치하여 편집 가능함을 암시합니다.
  - 카드 우측 상단(또는 헤더 영역)에 `IconButton`으로 삭제(Icons.close 또는 Icons.delete_outline) 기능을 제공합니다.
- **Feedback**: 탭 시 `InkWell` 효과를 주어 반응성을 제공합니다.

### 3. Spacing & Tokens
- **Padding**: 화면 전체 패딩은 `MinglitSpacing.large`를 권장합니다 (다른 관리 화면과 일치).
- **Separation**: 카드 간 간격은 `MinglitSpacing.medium`을 사용합니다.

## Wireframe
아래 링크에서 개선된 UI 와이어프레임을 확인할 수 있습니다.
(wireframe.html 파일 생성 후 링크 예정)

## Feedback to SWE
- 현재 구현된 `PartyEntryGroupManagementScreen`에서 `AddActionCard`를 상단으로 이동시켜 주세요.
- 카드 디자인에서 배경색이 들어간 헤더 대신, 깔끔한 카드 스타일과 Chevron 아이콘 조합을 검토해 주세요.
- 패딩을 `MinglitSpacing.large`로 조정하여 여유로운 레이아웃을 확보해 주세요.
