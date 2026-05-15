# 입장 그룹 관리 화면 — UX 리뷰 가이드

> **이슈**: #1733 [Bug] Entry Group edit blocking ticket creation
> **PR**: #1751 fix(partner): 입장 조건 편집 — '준비 중' 토스트 → EntryGroupManagementScreen
> **리뷰어**: needs-uiux-claude-1 (UX Designer)
> **작성일**: 2026-04-23
> **대상 파일**: `apps/app_partner/lib/src/features/party/detail/widgets/party_entry_group_management_screen.dart`

## 총평

파티 생성 위저드 Step4(`step4_entry_rules.dart`)의 패턴을 거의 그대로 재사용했다. Create 플로우와 Manage 플로우의 시각적 일관성이 높다. 디자인 시스템 토큰(`MinglitSpacing`, `MinglitRadius`, `MinglitOpacity`) 준수, `EntryGroupDetail`·`AddActionCard`·`MinglitEmptyState` 공유 위젯 사용은 올바른 선택이다.

**판정: 조건부 승인.** 아래 P0·P1만 반영하면 머지 가능.

## P0 — 삭제 전 확인 다이얼로그 (필수)

**현재**: 헤더의 `IconButton(Icons.close)` 탭 → 즉시 `removePartyEntryGroup` 호출 → 서버 반영 + `showMinglitSuccess` 표시.

**문제**:
1. **데이터 손실 위험**. `ticket_templates.target_entry_group_ids`가 entry group id를 참조한다. 그룹 삭제 시 참조 고립(orphan) 발생. Step4와 달리 이 화면은 **서버 영속화된 상태**를 다루므로 실수 한 번이 티켓 데이터 정합성을 깬다.
2. 파티 생성 위저드에서는 커밋 전이라 관대한 UX가 타당했다. 상세 화면에서는 파괴적(destructive) 액션 수준이 다르다.
3. `Icons.close`는 "닫기/해제"로 읽히기 쉽다. 삭제를 의도했다는 신호가 약하다.

**요구 사항**:

```dart
// party_entry_group_management_screen.dart — X 탭 핸들러
onPressed: () async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.entryGroup_delete_title),        // "입장 그룹 삭제"
      content: Text(context.l10n.entryGroup_delete_message),    // "이 입장 그룹을 삭제하면 연결된 티켓이 영향을 받을 수 있습니다. 삭제할까요?"
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.l10n.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(context.l10n.common_delete),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    coordinator.removePartyEntryGroup(partyId, group.id, context);
  }
},
```

**보강(선택)**: `coordinator.removePartyEntryGroup` 내부에서 "이 그룹에 연결된 티켓 N개" 카운트를 계산해 다이얼로그 본문에 주입하면 더 안전하다. N>0이면 빨간 경고 박스로 노출. 이번 PR 범위가 크다면 P2로 분리해도 무방.

## P0 — 삭제 아이콘 시맨틱 교체

- `Icons.close` → `Icons.delete_outline`
- `IconButton`에 `tooltip: context.l10n.common_delete` 추가 (접근성)
- 색상 `colorScheme.onSurfaceVariant` 유지하되, 다이얼로그에서 파괴성을 명시하므로 아이콘 자체는 과장할 필요 없음.

> 비고: Step4 위저드의 아이콘도 같은 방향으로 통일하면 create ↔ manage 경험이 일관된다. 단, 그 변경은 별도 PR로 분리한다 (이번 PR 범위는 관리 화면).

## P1 — AppBar 타이틀 개선

**현재**: `partyDetail_section_entranceCondition` (= "입장 조건") — 탭 섹션 라벨과 동일.

**문제**: 화면 진입 후에도 같은 텍스트가 AppBar에 남아 "어디에서 뭘 하고 있는지" 피드백이 약하다. 특히 `EntryGroupEditorScreen`으로 이동 후 back할 때 같은 제목이 연쇄로 보인다.

**제안**: `partyDetail_title_entryGroupManagement` 신규 키 — **"입장 조건 관리"** (영문: "Manage entry conditions").
- 편집 스크린은 `entryGroup_title_add` / `entryGroup_title_edit` ("입장 그룹 추가/편집")를 이미 사용 중 → 관리 vs 편집 위계가 명확해진다.

## P1 — Empty state를 fullPage variant로

**현재**: `MinglitEmptyState.inline(title: ...)` — 아이콘 없음, 폼/입력 필드용 플레이스홀더 스타일.

**문제**: 이 화면은 **풀스크린**이고 목록이 비면 화면의 절반 이상이 비는 상황이다. inline variant는 폼 필드 빈 값 표시용으로 설계되었고, 풀스크린에서는 시각적 무게감이 부족해 "로딩 중인가? 에러인가?" 혼동이 생긴다.

**요구 사항**:

```dart
if (groups.isEmpty)
  MinglitEmptyState(
    icon: Icons.tune,                                       // 또는 Icons.group_outlined
    title: context.l10n.entryGroup_empty_title,             // "아직 입장 조건이 없어요"
    subtitle: context.l10n.entryGroup_empty_subtitle,       // "입장 그룹을 만들면 티켓별로 성별·연령·인증 조건을 다르게 지정할 수 있습니다."
    actionLabel: context.l10n.partyCreate_button_addEntryGroup,
    onAction: () => _openGroupEditor(context, ref, coordinator: coordinator),
  )
```

- CTA를 empty state 안에 넣으면 `AddActionCard`는 중복이 되므로, `groups.isNotEmpty` 조건에서만 렌더하거나 empty 케이스에서는 `AddActionCard`를 생략한다.
- `AddActionCard`는 **목록이 있는 상태에서 "하나 더 추가"** 맥락이 타당하다.

## P2 — 짧은 설명 배너 (onboarding context)

**현재**: 화면 진입 시 바로 카드 목록. 입장 그룹이 뭔지 모르는 파트너에겐 "여기서 뭘 관리하는 건가?"가 불명확.

**제안**: `MinglitSpacing.medium` 위에 1줄 설명 추가.

```
[AppBar] 입장 조건 관리

입장 그룹은 티켓의 판매 대상을 정의합니다. 성별·연령·인증 조건을 
그룹으로 묶어 티켓별로 서로 다르게 적용할 수 있습니다.

[카드 1] 입장 그룹 1                          🗑️
         남성 · 1995~2005년생
         ──────────────
         인증: 휴대폰, 재직

[카드 2] 입장 그룹 2                          🗑️
         ...

─────────────────────────────────────
⊕  입장 그룹 추가
   티켓 대상을 세분화할 수 있어요.
```

- `theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)` 로 톤 다운.
- Step4 위저드의 `partyCreate_desc_entryRules` 문구를 재사용해도 좋다 (wording 일관성).

## P2 — 순서 의미 명시

**현재**: 헤더 "입장 그룹 1, 2, 3" — 인덱스는 배열 순서. 순서에 의미가 있는지, 재정렬 가능한지 사용자가 알 길이 없다.

**옵션 A (간단)**: 번호를 뺀다. 그룹 label(`group.label`)이 있으면 그것을, 없으면 조건 요약("남성 · 20대")을 헤더로 사용.

**옵션 B (완전)**: `ReorderableListView`로 전환 + drag handle. 단 서버 측 순서 컬럼이 있어야 하므로 이번 PR 범위 밖.

**이번 PR에서는 옵션 A를 권장**. 이후 순서 기반 매칭이 필요하면 별도 이슈로 트리아지.

## P3 — 헤더 대비(contrast) 검증

헤더 배경 `colorScheme.surfaceContainerHighest.withValues(alpha: MinglitOpacity.muted)` + 헤더 텍스트 `bodyMedium.bold`. 다크모드에서 WCAG AA(4.5:1)를 충족하는지 Widgetbook/catalog에서 확인.

위반 시: alpha를 `MinglitOpacity.strong`으로 올리거나, 배경을 `surfaceContainerHigh` (alpha 없이)로 교체.

## 산출물 요약

| 항목 | 우선순위 | 비고 |
|------|---------|------|
| 삭제 전 confirmation dialog | **P0 (blocker)** | 데이터 정합성 |
| 삭제 아이콘 `delete_outline` + tooltip | **P0** | 시맨틱/접근성 |
| AppBar 제목 "입장 조건 관리" | P1 | 신규 l10n 키 |
| Empty state fullPage + CTA | P1 | 풀스크린 맥락 |
| 설명 배너 | P2 | onboarding |
| 헤더 번호 → label/요약 | P2 | 순서 혼동 방지 |
| 다크모드 대비 검증 | P3 | catalog/golden |

## 다음 단계

1. SWE가 P0·P1을 반영하여 PR #1751 업데이트.
2. 신규 l10n 키 3개 추가 (`entryGroup_delete_title`, `entryGroup_delete_message`, `partyDetail_title_entryGroupManagement`, `entryGroup_empty_title`, `entryGroup_empty_subtitle`).
3. PR description에 본 문서 링크 인용: `docs/features/entry-group-management/ui-ux-design.md`.
4. `needs-uiux` 제거 · `needs-swe` 유지로 라우팅.
