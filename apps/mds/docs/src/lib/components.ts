/**
 * mds component manifest — single source of truth for what mds ships.
 *
 * Authored from:
 *   - shared/packages/mds/core/lib/src/ui/widgets/**  (file inventory)
 *   - apps/mds/storybook/lib/main.dart                (which have stories)
 *   - apps/app_user, app_partner                       (where used)
 *
 * Categories follow the storybook structure (Buttons / Inputs / Cards /
 * Feedback / Layout / Loading / Overlay).
 *
 * Adding a new component:
 *   1. Drop the Dart widget into shared/packages/mds/core/lib/src/ui/widgets/
 *   2. Add an entry below (props / variants / states / tokens / guidelines)
 *   3. Author the inline visual playground — see
 *      `src/components/specs/README.md` for the workflow. Start by copying
 *      `src/components/specs/_template.tsx` and importing the shared atoms
 *      from `src/components/specs/_atoms.tsx` (do NOT redeclare PreviewTable
 *      etc. locally).
 *   4. Register the new <Component>Spec in `src/app/components/page.tsx`
 *      INLINE_SPECS map.
 *   5. Optionally add a Widgetbook story (kept until 2026-06)
 *
 * Tone rule (same as the screen specs):
 *   The `description` text on each entry — purpose / guideline body /
 *   prop notes — should describe what the user sees and the visual
 *   contract. Implementation details (provider names, controller
 *   methods, lifecycle calls) belong in the Dart source, not here.
 *   `dartUsage` sample code is the explicit exception.
 */

export type ComponentCategory =
  | 'Action'        // primary CTA buttons
  | 'Chips'         // selectable / filter chips
  | 'Inputs'        // text fields, steppers
  | 'Cards'         // content card containers
  | 'Tags & Badges' // small inline labels
  | 'Sections'      // page section scaffolding
  | 'Lists'         // list rows, scroll groups
  | 'Layouts'       // content area scaffolding
  | 'Settings'      // settings groups & tiles
  | 'Feedback'      // empty / error states
  | 'Loading'       // skeleton, spinner, async wrapper
  | 'Overlay'       // dialog, sheet, alert
  | 'Media';        // image, carousel

/**
 * mds component spec — design intent first, implementation follows.
 *
 * Spec-first principle: this manifest defines what each component IS.
 * The Dart widget under shared/packages/mds/core/ is the implementation
 * of this spec — not the other way around. Adding/changing a component
 * starts here.
 */

/** Rich prop definition — type / default / required / notes. */
export interface PropDef {
  name: string;
  type: string;
  /** Default value (Dart literal). Omit for required props. */
  default?: string;
  required?: boolean;
  notes?: string;
}

/** Visual usage guideline — paired with a recipe component or short note. */
export interface GuidelineEntry {
  kind: 'do' | 'dont';
  /** Short imperative text. */
  text: string;
  /** Optional preview key — looked up in inline spec module. */
  recipeKey?: string;
}

export interface ComponentSpec {
  /** Component name (PascalCase). */
  name: string;
  /** Visual / functional grouping. */
  category: ComponentCategory;
  /** One-line role description. */
  purpose: string;
  /**
   * Public API contract. String for stub/quick listing; PropDef for rich
   * specs that should render as a table with type / default / required.
   */
  props?: Array<string | PropDef>;
  /** Visual variants (e.g. primary / secondary / destructive). */
  variants?: string[];
  /** Interactive states (e.g. default / disabled / loading / focused). */
  states?: string[];
  /**
   * mds_tokens this component consumes. String for stub entries; TokenUsage
   * for rich specs that should render as a `token | where applied` table.
   */
  tokens?: Array<string | TokenUsage>;
  /** Accessibility requirements (ARIA, keyboard nav). */
  accessibility?: string[];
  /**
   * Usage guidelines — string for plain bullet, GuidelineEntry for
   * structured do/don't pairs that render visually.
   */
  guidelines?: Array<string | GuidelineEntry>;
  /** Copy-paste Dart usage example (rendered as code block). */
  dartUsage?: string;
  /** Where this component lives on a screen + spacing relations. */
  placement?: PlacementSpec;
  /**
   * Path under /public/specs/components/ to a static HTML design spec
   * (visual mockup with spec-mode annotations). Optional — not all
   * components need a visual spec yet.
   */
  visualSpec?: string;
  /** Routes / specs that reference this component (anchor IDs). */
  usedIn?: string[];
}

/** Type guard for PropDef vs plain string entry. */
export function isPropDef(p: string | PropDef): p is PropDef {
  return typeof p === 'object' && p !== null && 'name' in p;
}

/** Type guard for GuidelineEntry vs plain string. */
export function isGuidelineEntry(g: string | GuidelineEntry): g is GuidelineEntry {
  return typeof g === 'object' && g !== null && 'kind' in g;
}

/** Token usage row — token name + where it's applied. */
export interface TokenUsage {
  name: string;
  where: string;
}

export function isTokenUsage(t: string | TokenUsage): t is TokenUsage {
  return typeof t === 'object' && t !== null && 'name' in t && 'where' in t;
}

/** Placement guidance — where this component sits on a screen and how
 *  it spaces against neighbours. Bridges between scaffold-level layout
 *  (/foundations/layout) and component-level visual spec. */
export interface PlacementSpec {
  /** Where this component typically lives. Free-form descriptions, e.g.
   *  "Bottom CTA", "Inline in form", "AppBar trailing slot". */
  where: string[];
  /** Spacing relations to common neighbours. */
  spacing?: Array<{ neighbor: string; gap: string; note?: string }>;
  /** Common compositions with other components. recipeKey looks up an
   *  inline preview in the spec module's GUIDELINE_RECIPES. */
  compositions?: Array<{ label: string; description?: string; recipeKey?: string }>;
}

export const MDS_COMPONENTS: ComponentSpec[] = [
  // ---------- Buttons ----------
  {
    name: 'MinglitButton',
    category: 'Action',
    purpose: 'Unified CTA button enforcing mds tokens. 4 variants × 3 sizes, with loading + leading icon.',
    props: [
      { name: 'label',     type: 'String',         required: true,  notes: 'Visible button text.' },
      { name: 'onPressed', type: 'VoidCallback?',  default: 'null', notes: '`null` disables the button.' },
      { name: 'icon',      type: 'IconData?',      default: 'null', notes: 'Optional leading icon.' },
      { name: 'isLoading', type: 'bool',           default: 'false', notes: 'Shows spinner, blocks taps.' },
      { name: 'size',      type: 'MinglitButtonSize', default: 'large', notes: 'sm / md / lg. text variant defaults to medium.' },
      { name: 'expand',    type: 'bool',           default: 'true',  notes: 'Stretch to parent width. text variant defaults to false.' },
    ],
    variants: ['primary', 'secondary', 'text', 'destructive'],
    states: ['default', 'hovered', 'pressed', 'disabled', 'loading'],
    tokens: [
      { name: 'color-primary',     where: 'primary bg · secondary border+text · text fg' },
      { name: 'color-on-primary',  where: 'primary text (literal #fff)' },
      { name: 'color-error',       where: 'destructive bg' },
      { name: 'color-on-error',    where: 'destructive text (literal #fff)' },
      { name: 'spacing-small',     where: 'icon ↔ label gap (8px)' },
      { name: 'spacing-medium',    where: 'horizontal padding (16px)' },
      { name: 'radius-button',     where: 'border radius (12px)' },
    ],
    accessibility: [
      'Disabled state announced to screen readers (onPressed == null)',
      'Loading state blocks taps; spinner color matches foreground (onPrimary / onError / primary)',
      'Min touch target ≥ 36px (size=small) — prefer medium/large for primary CTAs',
    ],
    guidelines: [
      { kind: 'do',   text: '한 화면에 primary 버튼은 하나 — 메인 CTA만.',                recipeKey: 'do-single-primary' },
      { kind: 'dont', text: 'primary 두 개를 같은 뷰에 쌓지 말 것 — 사용자가 어느 쪽이 메인인지 모름.', recipeKey: 'dont-double-primary' },
      { kind: 'do',   text: 'destructive는 항상 confirm dialog와 짝 — 취소 + 삭제.',     recipeKey: 'do-destructive-pair' },
      { kind: 'dont', text: 'destructive를 단독으로 두지 말 것 — 실수 클릭 위험.',         recipeKey: 'dont-bare-destructive' },
      { kind: 'do',   text: '비동기 액션엔 isLoading 사용 — 중복 탭 차단.',                recipeKey: 'do-loading-async' },
    ],
    dartUsage: `// Primary CTA
MinglitButton(
  label: '참여하기',
  onPressed: () => submit(),
)

// Destructive with confirm dialog
MinglitButton.destructive(
  label: '삭제하기',
  icon: Icons.delete_outline,
  onPressed: () async {
    final ok = await MinglitAlert.showConfirm(
      context,
      title: '정말 삭제하시겠어요?',
    );
    if (ok) await deletePost();
  },
)

// Inline text action
MinglitButton.text(
  label: '더보기',
  icon: Icons.arrow_forward,
  onPressed: () => viewMore(),
)`,
    visualSpec: '/specs/components/minglit_button.html',
    placement: {
      where: [
        'Bottom CTA — `Detail + Bottom CTA` 스캐폴드의 하단, expand=true 풀폭.',
        'Form action — `Form + Bottom CTA` 스캐폴드의 마지막 필드 아래.',
        'Dialog action — `Centered dialog`의 액션 row, secondary와 페어로.',
        'Inline (text variant) — 카드 안 인라인 / AppBar trailing 슬롯.',
      ],
      spacing: [
        { neighbor: '바로 위 form 필드',          gap: 'spacing-large (24px)',     note: '입력과 액션의 시각적 분리' },
        { neighbor: '같은 액션 row의 sibling 버튼', gap: 'spacing-small (8px)',      note: 'cancel + primary 페어' },
        { neighbor: '바로 위 섹션 본문',          gap: 'spacing-medium (16px)',    note: '버튼은 자기 섹션의 마지막 요소' },
        { neighbor: '화면 좌/우 가장자리 (expand=true)', gap: 'spacing-screen-edge (16px)' },
      ],
      compositions: [
        { label: 'Cancel + Primary pair',  description: '폼 액션 row의 표준 — 좌측 cancel, 우측 primary.', recipeKey: 'do-single-primary' },
        { label: 'Destructive + Cancel pair', description: 'destructive를 단독으로 두지 않는 안전 패턴.',     recipeKey: 'do-destructive-pair' },
        { label: 'Loading async',            description: '비동기 액션엔 isLoading으로 더블 탭 차단.',       recipeKey: 'do-loading-async' },
      ],
    },
  },
  {
    name: 'MinglitChip',
    category: 'Chips',
    purpose: 'Small selectable label / status chip. 크기 3가지, 선택적 색상 오버라이드, 선택적 탭 핸들러를 지원하는 다목적 인라인 레이블.',
    props: [
      { name: 'label',   type: 'String',          required: true,  notes: '칩 안에 표시되는 텍스트 레이블.' },
      { name: 'icon',    type: 'IconData?',        default: 'null', notes: '선택적 리딩 아이콘. medium/large 크기에서는 아이콘과 텍스트 사이에 1px 수직 구분선 자동 삽입.' },
      { name: 'size',    type: 'MinglitChipSize',  default: 'medium', notes: 'small(h≈22) / medium(h≈28, default) / large(h≈34).' },
      { name: 'color',   type: 'Color?',           default: 'null', notes: '배경 색상 오버라이드. null이면 surfaceContainerHighest 베이스. 밝기에 따라 텍스트 색 자동 결정.' },
      { name: 'onTap',   type: 'VoidCallback?',    default: 'null', notes: 'null이면 읽기 전용. 값이 있으면 InkWell + 48dp 최소 터치 타겟 + Semantics(button: true) 적용.' },
    ],
    variants: ['surface', 'primary', 'success', 'info', 'warning'],
    states: ['default (read-only)', 'interactive (onTap)', 'disabled (opacity 0.4)'],
    tokens: [
      { name: 'radius-chip',           where: '칩 border radius (100px — fully rounded)' },
      { name: 'spacing-small',         where: 'small 크기 수평 패딩 (8px)' },
      { name: 'spacing-sm',            where: 'large 크기 수평 패딩 (12px)' },
      { name: 'spacing-xxsmall',       where: 'small 크기 수직 패딩 (2px)' },
      { name: 'spacing-xsmall',        where: 'medium 크기 수직 패딩 + icon↔sep 갭 (4px)' },
      { name: 'spacing-xsmall2',       where: 'large 크기 수직 패딩 (6px)' },
      { name: 'color-text-primary',    where: '색상 오버라이드 없을 때 onSurfaceVariant 기반 텍스트' },
      { name: 'color-primary',         where: 'primary variant 배경' },
      { name: 'color-success',         where: 'success variant 배경' },
      { name: 'color-divider',         where: 'border (outlineVariant, 0.5px)' },
      { name: 'typography-font-size-caption',    where: 'small 크기 폰트 (10px)' },
      { name: 'typography-font-size-chip-label', where: 'medium/large 크기 폰트 (13–14px)' },
    ],
    accessibility: [
      'onTap != null 이면 Semantics(button: true, label: label) 적용.',
      '최소 터치 타겟 48dp × 48dp (WCAG 2.5.5). ConstrainedBox + InkWell + Center 구조.',
      'onTap == null 이면 Semantics(button: false) — 읽기 전용 레이블로 선언.',
      'color 오버라이드 시 명암비 직접 보장 필요 (자동 텍스트 색 추정 있지만, 커스텀 팔레트는 확인 권장).',
    ],
    guidelines: [
      { kind: 'do',   text: '카드 안 상태 표시(모집 중 / 마감)는 small size에 success / warning 색상 칩을 사용한다.', recipeKey: 'do-status-in-card' },
      { kind: 'dont', text: '한 카드에 7개 이상 칩을 줄바꿈으로 쌓지 말 것 — 시각적 노이즈. MinglitChipGroup(wrap)으로 제한하거나 칩 수를 줄인다.', recipeKey: 'dont-overload-chips' },
      { kind: 'do',   text: '아이콘은 의미를 보강할 때만 추가한다 — 장르엔 음표, 정렬엔 sort 아이콘.', recipeKey: 'do-icon-with-semantics' },
      { kind: 'dont', text: '같은 그룹 안에서 크기를 섞지 말 것 — small + large 혼용은 시각적 정렬 파괴.', recipeKey: 'dont-mix-sizes-inline' },
      { kind: 'do',   text: '인터랙티브 칩(onTap 있음)에는 반드시 의미 있는 label을 제공하여 스크린 리더가 "재즈 버튼"처럼 읽도록 한다.' },
    ],
    dartUsage: `// 읽기 전용 상태 칩
MinglitChip(
  label: '모집 중',
  color: MinglitColors.success,
)

// 아이콘 있는 카테고리 칩
MinglitChip(
  label: '재즈',
  icon: Icons.music_note,
)

// 인터랙티브 칩 (탭 가능)
MinglitChip(
  label: '인디',
  size: MinglitChipSize.large,
  onTap: () => filterByGenre('indie'),
)`,
    placement: {
      where: [
        '`List + Filter chips` 스캐폴드 — MinglitChipGroup 안의 자식 칩.',
        '`Detail + Bottom CTA` 스캐폴드 — MinglitSection 안 태그 row (읽기 전용, small/medium).',
        'MinglitContentCard 내 상태/카테고리 인라인 레이블 (small size).',
      ],
      spacing: [
        { neighbor: 'sibling 칩 (MinglitChipGroup 안)',  gap: 'spacing-small (8px)',      note: 'MinglitChipGroup.spacing 기본값' },
        { neighbor: '카드 내 sibling 텍스트',            gap: 'spacing-xsmall (4px)',     note: '인라인 레이블은 텍스트와 타이트하게' },
        { neighbor: 'MinglitChipGroup 외부 패딩',         gap: 'spacing-screen-edge (16px)', note: '화면 가장자리까지 표준 패딩' },
      ],
      compositions: [
        { label: 'Status + Genre tags in card',  description: 'MinglitContentCard 안 small 상태칩 + 장르칩 인라인 조합.', recipeKey: 'do-status-in-card' },
        { label: 'Tag cloud in detail section',  description: 'scrollable=false Wrap 레이아웃으로 상세 페이지 태그 목록.', recipeKey: 'dont-overload-chips' },
      ],
    },
  },
  {
    name: 'MinglitFilterChip',
    category: 'Chips',
    purpose: 'Toggleable filter chip with selected state. YouTube-style 색상 반전으로 선택/미선택을 직관적으로 구분하는 필터·정렬 전용 칩.',
    props: [
      { name: 'label',      type: 'String',         required: true,  notes: '칩 안에 표시되는 텍스트 레이블.' },
      { name: 'isSelected', type: 'bool',            required: true,  notes: 'true: onSurface 배경 + surface 텍스트. false: tintFill 배경 + onSurfaceVariant 텍스트.' },
      { name: 'onTap',      type: 'VoidCallback',    required: true,  notes: '탭 시 항상 호출. setState로 isSelected 토글. GestureDetector + 48dp 최소 터치 타겟.' },
      { name: 'icon',       type: 'IconData?',       default: 'null', notes: '선택적 리딩 아이콘. MinglitChip과 달리 구분선 없음 — 아이콘 바로 옆 레이블.' },
      { name: 'size',       type: 'MinglitChipSize', default: 'large', notes: 'small(h≈26) / medium(h≈32) / large(h≈36, default). FilterChip은 large가 기본 — MinglitChip medium 기본과 다름에 주의.' },
    ],
    variants: ['unselected', 'selected'],
    states: ['unselected', 'selected', 'disabled (opacity 0.4)'],
    tokens: [
      { name: 'radius-chip',           where: '칩 border radius (100px — fully rounded)' },
      { name: 'spacing-sm',            where: 'medium/large 수평 패딩 (12px)' },
      { name: 'spacing-small',         where: 'small 수평 패딩 (8px)' },
      { name: 'spacing-xsmall',        where: 'large 수직 패딩 + icon↔label 갭 (4px)' },
      { name: 'spacing-xsmall2',       where: 'medium 수직 패딩 (6px)' },
      { name: 'spacing-xxsmall',       where: 'small 수직 패딩 (2px)' },
      { name: 'color-text-primary',    where: 'selected: surface 텍스트 (다크모드는 dark-background 기반)' },
      { name: 'color-surface',         where: 'selected 텍스트 색 — colorScheme.surface' },
      { name: 'color-text-secondary',  where: 'unselected: onSurfaceVariant 텍스트' },
      { name: 'typography-font-size-chip-label', where: 'medium 크기 폰트 (13px, ext.chipLabel)' },
    ],
    accessibility: [
      'Semantics(selected: isSelected, button: true, label: label) 적용 — 스크린 리더가 "최신순 선택됨 버튼" 등으로 읽음.',
      '최소 터치 타겟 48dp × 48dp. GestureDetector(behavior: opaque) + ConstrainedBox 구조.',
      '정렬 그룹(단일 선택) 패턴은 상위에 Semantics(label: "정렬 기준") 등으로 그룹 의미 제공 권장.',
    ],
    guidelines: [
      { kind: 'do',   text: '정렬 그룹은 단일 선택 — 한 번에 하나만 selected=true. onTap에서 index setState로 관리.', recipeKey: 'do-single-select-sort' },
      { kind: 'dont', text: '정렬 그룹에서 모든 칩을 동시에 selected로 설정하지 말 것 — 사용자가 현재 기준을 알 수 없음.', recipeKey: 'dont-all-selected' },
      { kind: 'do',   text: '장르/카테고리 멀티 토글은 복수 selected 허용. 아이콘으로 그룹 의미를 강화한다.', recipeKey: 'do-multi-toggle-genre' },
      { kind: 'dont', text: 'FilterChip을 "파티 만들기" 같은 액션 버튼으로 사용하지 말 것 — MinglitButton 사용.', recipeKey: 'dont-filter-chip-as-button' },
      { kind: 'do',   text: 'MinglitChipGroup(scrollable=true) 안에서 사용하는 것이 표준 패턴 — 칩이 많을 때 가로 스크롤 자동 지원.' },
    ],
    dartUsage: `// 정렬 단일 선택 패턴
MinglitFilterChip(
  label: '최신순',
  isSelected: _sortIndex == 0,
  icon: Icons.sort,
  onTap: () => setState(() => _sortIndex = 0),
)

// 장르 멀티 토글 패턴
MinglitFilterChip(
  label: '재즈',
  isSelected: selectedGenres.contains('jazz'),
  icon: Icons.music_note,
  onTap: () => setState(() {
    if (selectedGenres.contains('jazz')) {
      selectedGenres.remove('jazz');
    } else {
      selectedGenres.add('jazz');
    }
  }),
)`,
    placement: {
      where: [
        '`List + Filter chips` 스캐폴드 — AppBar 바로 아래 MinglitChipGroup(scrollable=true) 안.',
        'MinglitBottomSheet 안 필터 옵션 그룹 (scrollable=false Wrap 레이아웃).',
      ],
      spacing: [
        { neighbor: 'sibling FilterChip',        gap: 'spacing-small (8px)',        note: 'MinglitChipGroup.spacing 기본값' },
        { neighbor: 'AppBar 하단 경계',           gap: 'spacing-xsmall (4px)',       note: 'MinglitChipGroup이 자체 패딩 처리' },
        { neighbor: '아래 카드 리스트 상단',       gap: 'spacing-small (8px)',        note: 'ChipGroup 높이 40px + 아래 여백' },
      ],
      compositions: [
        { label: 'Sort + Filter group in list',   description: '정렬 칩(단일 선택) + 필터 칩(멀티 선택) 혼합 scrollable 그룹.', recipeKey: 'do-single-select-sort' },
        { label: 'Genre multi-toggle in sheet',   description: 'MinglitBottomSheet 안 wrap=false 멀티 토글 장르 필터.', recipeKey: 'do-multi-toggle-genre' },
      ],
    },
  },
  {
    name: 'MinglitChipGroup',
    category: 'Chips',
    purpose: 'Horizontal/scrollable chip container. MinglitChip / MinglitFilterChip 반복 패턴을 가로 스크롤 또는 줄바꿈으로 일관되게 배치하는 레이아웃 합성 위젯.',
    props: [
      { name: 'children',    type: 'List<Widget>',    required: true,  notes: '칩 위젯 목록. MinglitChip, MinglitFilterChip 모두 지원.' },
      { name: 'scrollable',  type: 'bool',            default: 'true', notes: 'true: ListView.separated 가로 스크롤 (height 고정). false: Wrap 줄바꿈 (높이 가변).' },
      { name: 'height',      type: 'double',          default: '40',   notes: 'scrollable=true일 때만 사용. SizedBox height (px). false면 무시.' },
      { name: 'spacing',     type: 'double',          default: 'MinglitSpacing.small (8)', notes: '칩 사이 간격. scrollable: separator width. wrap: spacing + runSpacing 공통.' },
      { name: 'padding',     type: 'EdgeInsets',      default: 'EdgeInsets.symmetric(horizontal: spacing-medium)', notes: '그룹 외부 패딩. 스크롤 시 양끝 여백으로 작동.' },
    ],
    variants: ['scrollable (default)', 'wrap'],
    states: ['stateless (자식 칩이 상태 보유)'],
    tokens: [
      { name: 'spacing-small',         where: '칩 사이 기본 간격 (8px)' },
      { name: 'spacing-medium',        where: '기본 외부 수평 패딩 (16px)' },
      { name: 'spacing-screen-edge',   where: '화면 가장자리 기준 외부 패딩 (16px, spacing-medium과 동일 값)' },
    ],
    accessibility: [
      '가로 스크롤 모드: 스크롤 가능성을 명시적으로 전달하기 위해 상위에 Semantics(label: "필터 목록, 가로 스크롤 가능") 권장.',
      '각 자식 칩이 자체 Semantics 보유 — ChipGroup 자체는 추가 a11y 마크업 없음.',
    ],
    guidelines: [
      { kind: 'do',   text: '`List + Filter chips` 스캐폴드 상단 필터 행에는 scrollable=true를 사용 — 칩이 5개 이상일 때 화면 이탈 없이 스크롤.', recipeKey: 'do-scrollable-filter-row' },
      { kind: 'dont', text: '필터 행에 scrollable=false(Wrap)를 사용하지 말 것 — 칩이 많으면 2-3줄로 터져 카드 리스트 공간을 침범.', recipeKey: 'dont-wrap-filter-row' },
      { kind: 'do',   text: '상세 페이지 태그 목록처럼 칩 수가 가변적이고 줄바꿈이 자연스러운 경우는 scrollable=false(Wrap)를 사용.', recipeKey: 'do-wrap-tag-list' },
      { kind: 'dont', text: '한 화면에 MinglitChipGroup을 2개 이상 수직으로 쌓지 말 것 — 특히 scrollable=true 두 개 중첩은 스크롤 충돌.', recipeKey: 'dont-nested-groups' },
      { kind: 'do',   text: 'height=40이 표준. 특수 레이아웃이 아니면 변경하지 않는다 — FilterChip large size와 정확히 맞는 값.' },
    ],
    dartUsage: `// 표준 가로 스크롤 필터 행
MinglitChipGroup(
  children: [
    MinglitFilterChip(label: '최신순', isSelected: _sortIndex == 0, icon: Icons.sort, onTap: () => setState(() => _sortIndex = 0)),
    MinglitFilterChip(label: '인기순', isSelected: _sortIndex == 1, onTap: () => setState(() => _sortIndex = 1)),
    MinglitFilterChip(label: '재즈', isSelected: selectedGenres.contains('jazz'), icon: Icons.music_note, onTap: () => _toggleGenre('jazz')),
  ],
)

// 줄바꿈 태그 목록 (상세 페이지)
MinglitChipGroup(
  scrollable: false,
  spacing: MinglitSpacing.sm,
  children: party.tags.map((tag) => MinglitChip(label: tag)).toList(),
)`,
    placement: {
      where: [
        '`List + Filter chips` 스캐폴드 — AppBar 바로 아래, 카드 리스트 위 고정 필터 행.',
        '`Detail + Bottom CTA` 스캐폴드 — MinglitSection 안 태그 목록 (scrollable=false).',
        'MinglitBottomSheet 안 — scrollable=false Wrap으로 필터 옵션 그룹.',
      ],
      spacing: [
        { neighbor: 'AppBar 하단 / 카드 리스트 상단', gap: 'spacing-small (8px)',        note: '스캐폴드에서 Filter row 위아래 여백' },
        { neighbor: '화면 좌/우 가장자리',            gap: 'spacing-screen-edge (16px)', note: 'padding 기본값으로 처리 — 별도 Padding 위젯 불필요' },
        { neighbor: '그룹 내 칩 사이',                gap: 'spacing-small (8px)',        note: 'spacing 기본값' },
      ],
      compositions: [
        { label: 'Sort + Filter row (scrollable)',    description: '스캐폴드 상단 정렬+필터 칩 가로 스크롤 행. 표준 패턴.', recipeKey: 'do-scrollable-filter-row' },
        { label: 'Tag cloud (wrap, detail page)',     description: '상세 페이지 태그 목록 줄바꿈 레이아웃.', recipeKey: 'do-wrap-tag-list' },
      ],
    },
  },
  {
    name: 'MinglitBottomCta',
    category: 'Action',
    purpose: '화면 하단에 고정되는 핵심 액션 바. Scaffold.bottomNavigationBar 슬롯에 배치하며, 키보드가 올라오면 자동으로 사라져 입력 폼을 가리지 않는다.',
    props: [
      { name: 'label',             type: 'String',         required: true,  notes: '주요 버튼 텍스트.' },
      { name: 'onPressed',         type: 'VoidCallback?',  default: 'null', notes: 'null이면 비활성. 풀스크린 로딩 / 폼 미완성 시 사용.' },
      { name: 'icon',              type: 'IconData?',       default: 'null', notes: '주요 버튼 leading 아이콘. single / withPrice 변형에서만 지원.' },
      { name: 'enabled',           type: 'bool',            default: 'true', notes: 'false면 모든 버튼이 비활성. onPressed null과 동일한 시각.' },
      { name: 'secondaryLabel',    type: 'String',          notes: 'dual 변형 전용 — 좌측 외곽선 버튼 텍스트.' },
      { name: 'onSecondaryPressed', type: 'VoidCallback?', notes: 'dual 변형 전용 — 좌측 버튼 콜백.' },
      { name: 'priceText',         type: 'String',          notes: 'withPrice 변형 전용 — 좌측 가격 텍스트 (예: "20,000원~").' },
      { name: 'priceSubText',      type: 'String?',         default: 'null', notes: 'withPrice 변형 전용 — 가격 위 작은 회색 라벨 (예: "최저가").' },
    ],
    variants: ['single', 'dual', 'withPrice'],
    states: ['default', 'disabled', 'with icon', 'keyboard up (자동 숨김)'],
    tokens: [
      { name: 'color-surface',         where: 'scaffold 배경 — bottom CTA 컨테이너 배경.' },
      { name: 'color-divider',         where: '상단 0.5px 구분선 (outlineVariant).' },
      { name: 'color-primary',         where: '주요 버튼 fill (ElevatedButton).' },
      { name: 'color-text-primary',    where: '외곽선 버튼 라벨 / 가격 텍스트.' },
      { name: 'color-text-secondary',  where: '가격 위 부가 라벨 (priceSubText).' },
      { name: 'spacing-screen-edge',   where: '좌우 padding (16px).' },
      { name: 'spacing-sm',            where: '위아래 padding (12px) · withPrice 가격↔버튼 갭.' },
      { name: 'spacing-small',         where: 'dual 변형의 두 버튼 사이 갭 (8px).' },
      { name: 'radius-button',         where: '버튼 모서리 (12px).' },
    ],
    accessibility: [
      'SafeArea 자동 처리 — 시스템 인셋(노치 / 홈 인디케이터) 위에 안전하게 위치.',
      '키보드 표시 중에는 자동 숨김 — 입력 폼이 가려지지 않도록.',
      '버튼은 시각 비활성 시 onPressed: null로 실제 탭도 차단.',
    ],
    guidelines: [
      { kind: 'do',   text: '핵심 액션 한 가지만 있으면 single 변형. 화면 하단에 안전하게 고정.',           recipeKey: 'do-single-primary' },
      { kind: 'do',   text: '저장 / 취소처럼 짝 액션이 필요할 때 dual 변형 — 좌측 보조, 우측 주요.',          recipeKey: 'do-dual-save-pair' },
      { kind: 'do',   text: '가격이 액션과 함께 보여야 할 때 withPrice — 좌측에 정보, 우측에 액션.',          recipeKey: 'do-price-context' },
      { kind: 'dont', text: 'AppBar 위 / 화면 중간에 사용 금지 — 이 컴포넌트는 화면 하단 고정 슬롯 전용.' },
    ],
    placement: {
      where: [
        '`Detail + Bottom CTA` 스캐폴드 / `Form + Bottom CTA` 스캐폴드의 하단 슬롯.',
        '스크롤 영역 바깥에 고정. safe area 위에 위치.',
      ],
      spacing: [
        { neighbor: '화면 좌/우 가장자리',  gap: 'spacing-screen-edge (16px)', note: 'CTA 버튼은 풀폭이지만 컨테이너 패딩으로 처리' },
        { neighbor: 'safe area bottom',    gap: '0',                          note: '시스템 인셋 바로 위' },
      ],
    },
    dartUsage: `// 단일 버튼
MinglitBottomCTA(
  label: '참여하기',
  onPressed: () => coordinator.apply(),
)

// 좌우 두 버튼
MinglitBottomCTA.dual(
  label: '저장',
  onPressed: () => save(),
  secondaryLabel: '취소',
  onSecondaryPressed: () => Navigator.pop(context),
)

// 가격 + 버튼
MinglitBottomCTA.withPrice(
  label: '참여하기',
  onPressed: () => apply(),
  priceText: '20,000원~',
  priceSubText: '최저가',
)`,
  },

  // ---------- Inputs ----------
  {
    name: 'MinglitTextField',
    category: 'Inputs',
    purpose: '테마-어웨어 텍스트 입력. error / disabled / prefix·suffix 아이콘 지원. Material InputDecoration을 mds 토큰으로 래핑.',
    props: [
      { name: 'label',           type: 'String',                       required: true,  notes: '필드 위에 float하는 레이블. Semantics label로도 사용됨.' },
      { name: 'controller',      type: 'TextEditingController?',       default: 'null', notes: '외부에서 값 읽기/쓰기가 필요할 때. 없으면 내부 uncontrolled.' },
      { name: 'hintText',        type: 'String?',                      default: 'null', notes: '필드가 비었을 때 나타나는 플레이스홀더. `hint`가 아닌 `hintText` 사용 주의.' },
      { name: 'errorText',       type: 'String?',                      default: 'null', notes: 'null이 아니면 error 상태로 전환. 필드 아래 color-error로 표시.' },
      { name: 'helperText',      type: 'String?',                      default: 'null', notes: 'errorText가 없을 때 필드 아래 보조 안내 문구.' },
      { name: 'prefixIcon',      type: 'Widget?',                      default: 'null', notes: '입력 영역 왼쪽 아이콘. Icon 위젯 직접 전달.' },
      { name: 'suffixIcon',      type: 'Widget?',                      default: 'null', notes: '입력 영역 오른쪽 아이콘. 지우기(×) 버튼, 비밀번호 토글 등.' },
      { name: 'enabled',         type: 'bool',                         default: 'true', notes: 'false이면 탭 불가, outline opacity muted, 배경 surface.' },
      { name: 'maxLines',        type: 'int',                          default: '1',    notes: '1 초과 시 multiline textarea. obscureText=true와 함께 사용 불가.' },
      { name: 'obscureText',     type: 'bool',                         default: 'false', notes: '비밀번호 마스킹. maxLines=1 필수.' },
      { name: 'onChanged',       type: 'ValueChanged<String>?',        default: 'null', notes: '텍스트 변경 시 콜백.' },
      { name: 'onSubmitted',     type: 'ValueChanged<String>?',        default: 'null', notes: '키보드 완료 액션 시 콜백.' },
      { name: 'keyboardType',    type: 'TextInputType?',               default: 'null', notes: '이메일, 숫자, 전화 등 키보드 유형 지정.' },
      { name: 'inputFormatters', type: 'List<TextInputFormatter>?',    default: 'null', notes: '입력 마스킹 / 포맷 검증. 전화번호 형식 등에 사용.' },
      { name: 'textInputAction', type: 'TextInputAction?',             default: 'null', notes: '키보드 액션 버튼 유형 (done, next, search 등).' },
      { name: 'focusNode',       type: 'FocusNode?',                   default: 'null', notes: '외부에서 포커스 제어가 필요할 때 전달.' },
      { name: 'autofocus',       type: 'bool',                         default: 'false', notes: '위젯 빌드 시 자동 포커스. 단일 입력 화면에서만 사용.' },
    ],
    variants: [
      'default — prefix/suffix 없는 기본형',
      'with prefix icon — prefixIcon: Icon(Icons.search) 등',
      'with suffix icon — suffixIcon: 지우기 버튼, 비밀번호 토글',
      'multiline — maxLines > 1, 자기소개 / 메모 입력',
    ],
    states: [
      'default — enabled=true, errorText=null',
      'focused — FocusNode 획득, 테두리 color-primary 2px (Flutter 자동 처리)',
      'with value — 값 입력됨, label float',
      'error — errorText != null, 테두리 + 하단 텍스트 color-error',
      'disabled — enabled=false, opacity muted, 탭 불가',
    ],
    tokens: [
      { name: 'color-primary',        where: 'focused 테두리 색 (colorScheme.primary)' },
      { name: 'color-error',          where: 'error 테두리 + errorText 색 (colorScheme.error)' },
      { name: 'color-surface',        where: 'disabled 상태 배경' },
      { name: 'color-divider',        where: 'enabled 기본 테두리 (colorScheme.outline)' },
      { name: 'color-text-secondary', where: 'hintText 색, helperText 색' },
      { name: 'radius-input',         where: '테두리 반경 12px (OutlineInputBorder 모든 상태)' },
      { name: 'spacing-medium',       where: 'contentPadding horizontal 16px' },
      { name: 'spacing-sm',           where: 'contentPadding vertical 12px' },
    ],
    accessibility: [
      'Semantics(textField: true, label: label) 래핑 — 스크린 리더가 필드 역할과 레이블을 읽음.',
      'errorText가 있으면 Flutter가 자동으로 error semantic을 전달.',
      'ConstrainedBox(minHeight: kMinInteractiveDimension) — 최소 48px 터치 영역 보장.',
      'obscureText=true 필드는 suffixIcon으로 토글 버튼을 제공해 접근성 향상.',
      'label은 생략하지 말 것 — placeholder만 있는 필드는 포커스 시 의미를 잃음.',
    ],
    guidelines: [
      { kind: 'do',   text: '모든 필드에 label을 지정 — 포커스 시에도 사용자가 필드 의미를 파악할 수 있어야 함.', recipeKey: 'do-label-every-field' },
      { kind: 'dont', text: 'hintText만 쓰고 label을 생략하지 말 것 — 입력 시작 후 필드 의미가 사라짐.',           recipeKey: 'dont-placeholder-only' },
      { kind: 'do',   text: '유효성 오류는 errorText로 필드 아래에 — 인라인 toast나 별도 텍스트 금지.',           recipeKey: 'do-error-below' },
      { kind: 'dont', text: 'errorText를 필드 옆 인라인으로 두지 말 것 — 스크린 리더가 연관을 인식 못함.',          recipeKey: 'dont-inline-error' },
      { kind: 'do',   text: 'enabled=false로 읽기 전용 데이터 표시 — 편집 불가임을 시각적으로 명확히.',             recipeKey: 'do-disabled-readonly' },
    ],
    dartUsage: `// 기본 텍스트 필드
MinglitTextField(
  label: '이름',
  hintText: '홍길동',
  onChanged: (v) => setState(() => _name = v),
)

// 이메일 + 유효성 오류
MinglitTextField(
  label: '이메일',
  hintText: 'example@minglit.com',
  keyboardType: TextInputType.emailAddress,
  errorText: _emailError,
  textInputAction: TextInputAction.next,
  onChanged: _validateEmail,
)

// 검색 prefix 아이콘
MinglitTextField(
  label: '검색',
  hintText: '이벤트 검색...',
  prefixIcon: const Icon(Icons.search),
  onChanged: _onSearch,
)

// 멀티라인 (소개글)
MinglitTextField(
  label: '소개',
  hintText: '자기소개를 입력하세요...',
  maxLines: 4,
  onChanged: (v) => setState(() => _bio = v),
)`,
    placement: {
      where: [
        '`Form + Bottom CTA` 스캐폴드의 세로 스택 — 대부분의 입력 폼.',
        '`Centered dialog` 안 단일 입력 필드 (이름, 코드 입력 등).',
        '`List + Filter chips`의 상단 검색 바 (prefixIcon: Search).',
      ],
      spacing: [
        { neighbor: '같은 폼의 sibling 필드', gap: 'spacing-medium (16px)',     note: '필드 간 명확한 분리' },
        { neighbor: '폼 마지막 필드 → CTA 버튼', gap: 'spacing-large (24px)',   note: '입력과 액션의 시각적 분리' },
        { neighbor: '섹션 헤더 → 첫 필드',     gap: 'spacing-medium (16px)' },
        { neighbor: '화면 좌/우 가장자리',     gap: 'spacing-screen-edge (16px)', note: 'MinglitContentLayout 패딩으로 처리' },
      ],
      compositions: [
        { label: 'Form + Bottom CTA',    description: '이름/이메일/연락처 등 순차 필드 + 하단 primary CTA.', recipeKey: 'do-label-every-field' },
        { label: 'Error state + Submit', description: '유효성 실패 시 errorText로 인라인 피드백, 버튼은 그대로 활성.', recipeKey: 'do-error-below' },
        { label: 'Search bar',           description: 'prefixIcon=Search, 단독 필드로 상단 배치.' },
      ],
    },
  },
  {
    name: 'NumberStepperInput',
    category: 'Inputs',
    purpose: '정수 값 증감용 스테퍼. − / 값 / + 3-파트 row. min/max 경계에서 버튼 자동 비활성.',
    props: [
      { name: 'value',      type: 'int',                  required: true,  notes: '현재 표시값. 외부에서 관리 (controlled).' },
      { name: 'onChanged',  type: 'ValueChanged<int>',    required: true,  notes: '증감·직접 입력으로 값이 바뀔 때 호출. min..max 범위 보장됨.' },
      { name: 'label',      type: 'String?',              default: 'null', notes: 'null이 아니면 스테퍼 위에 bold labelMedium 라벨 표시.' },
      { name: 'min',        type: 'int',                  default: '0',    notes: '허용 최솟값. value == min이면 − 버튼 비활성.' },
      { name: 'max',        type: 'int',                  default: '999999', notes: '허용 최댓값. value == max이면 + 버튼 비활성.' },
      { name: 'step',       type: 'int',                  default: '1',    notes: '증감 단위. step=5이면 0→5→10. 직접 입력 시 clamp 처리.' },
      { name: 'suffixText', type: 'String?',              default: 'null', notes: '숫자 뒤 단위 문자열 (예: "명", "개", "회"). titleSmall onSurfaceVariant 스타일.' },
    ],
    variants: [
      'default — label 없음, suffixText 없음, step=1',
      'with label — 스테퍼 위 라벨 (참여 인원, 모집 수 등)',
      'with suffixText — 숫자 뒤 단위 (명, 개)',
      'custom step — 5 / 10 단위 증감',
    ],
    states: [
      'default — min < value < max, 양방향 버튼 활성',
      'min reached — value == min, − 버튼 비활성',
      'max reached — value == max, + 버튼 비활성',
    ],
    tokens: [
      { name: 'color-surface',        where: '스테퍼 컨테이너 배경 (colorScheme.surface)' },
      { name: 'color-divider',        where: '스테퍼 컨테이너 테두리 (colorScheme.outlineVariant)' },
      { name: 'color-text-secondary', where: '비활성 버튼 아이콘 색 (colorScheme.outlineVariant)' },
      { name: 'radius-input',         where: '컨테이너 테두리 반경 12px' },
      { name: 'spacing-xsmall',       where: '컨테이너 horizontal padding 4px' },
      { name: 'spacing-sm',           where: '값 입력 필드 vertical padding 12px' },
      { name: 'spacing-small',        where: 'label → stepper row 간격 8px' },
    ],
    accessibility: [
      '− / + 버튼에 aria-label="감소" / "증가" 제공 (Flutter에서 Tooltip 또는 Semantics 추가 권장).',
      '버튼 최소 터치 타깃 40×40px (MaterialTapTargetSize.shrinkWrap + minimumSize: Size(40,40)).',
      '비활성 버튼은 onPressed=null — 스크린 리더가 disabled로 읽음.',
      '직접 입력 시 범위 벗어난 값은 clamp 처리 — 유효하지 않은 상태가 persist 되지 않음.',
      'suffixText는 시각적 단위 보조 — 스크린 리더에도 읽혀야 하므로 Semantics label에 포함 고려.',
    ],
    guidelines: [
      { kind: 'do',   text: 'min / max를 실제 비즈니스 제약에 맞게 지정 — 이벤트 최대 정원 등.', recipeKey: 'do-show-min-max' },
      { kind: 'dont', text: 'max를 999999 기본으로 두지 말 것 — 제약 없는 입력처럼 보임.',     recipeKey: 'dont-hide-limits' },
      { kind: 'do',   text: '단위가 있는 수치에는 suffixText 제공 — "5" 대신 "5 명"이 맥락을 명확히 함.', recipeKey: 'do-suffix-unit' },
      { kind: 'dont', text: '단위 없는 숫자만 표시하지 말 것 — 무엇의 5인지 알 수 없음.',         recipeKey: 'dont-raw-number' },
      { kind: 'do',   text: '큰 단위 증감(step=10 등)은 label이나 helperText로 스텝 크기를 사용자에게 안내.' },
    ],
    dartUsage: `// 기본 스테퍼 (참여 인원)
NumberStepperInput(
  label: '참여 인원',
  value: _participants,
  min: 1,
  max: _event.maxParticipants,
  suffixText: '명',
  onChanged: (v) => setState(() => _participants = v),
)

// 5명 단위 스테퍼
NumberStepperInput(
  label: '참여 그룹 수',
  value: _groupCount,
  min: 1,
  max: 50,
  step: 5,
  suffixText: '팀',
  onChanged: (v) => setState(() => _groupCount = v),
)`,
    placement: {
      where: [
        '`Form + Bottom CTA` 스캐폴드 — 이벤트 생성 / 수정 폼 안 정수 입력 필드.',
        '`Bottom sheet` 안 — 빠른 인원 선택 시트.',
      ],
      spacing: [
        { neighbor: '같은 폼의 sibling 필드 (MinglitTextField 등)', gap: 'spacing-medium (16px)' },
        { neighbor: '폼 마지막 스테퍼 → CTA 버튼', gap: 'spacing-large (24px)' },
        { neighbor: '스테퍼 label → row',          gap: 'spacing-small (8px)', note: 'Dart 소스 고정값' },
      ],
      compositions: [
        { label: 'Form with stepper', description: 'MinglitTextField (이름/날짜) 아래 NumberStepperInput (인원) 세로 스택.', recipeKey: 'do-show-min-max' },
        { label: 'Bottom sheet quick pick', description: '인원 선택 sheet: 타이틀 + 스테퍼 + 확인 버튼.' },
      ],
    },
  },

  // ---------- Cards ----------
  {
    name: 'MinglitContentCard',
    category: 'Cards',
    purpose: '둥근 모서리 + 회색 보더의 통일된 카드 컨테이너. 콘텐츠 그룹핑 / 정보 묶음 / 선택 옵션 등 다목적으로 사용. highlighted=true면 보더가 primary 색으로 변경되어 강조 / 선택 상태를 표시.',
    props: [
      { name: 'child',       type: 'Widget',           required: true, notes: '카드 내부에 들어갈 콘텐츠. 자유 구성 (텍스트 / 이미지 / 리스트 등).' },
      { name: 'padding',     type: 'EdgeInsetsGeometry?', default: 'null', notes: '내부 padding 오버라이드. null이면 기본 vertical card-content-v + horizontal medium.' },
      { name: 'onTap',       type: 'VoidCallback?',    default: 'null', notes: '탭 콜백. 있으면 잉크 리플 + 탭 가능 (둥근 모서리 안쪽까지 리플).' },
      { name: 'highlighted', type: 'bool?',            default: 'false', notes: 'true면 보더가 primary 색으로 변경 — 선택 / 추천 / 활성 상태 시각화.' },
    ],
    variants: ['default', 'highlighted', 'tappable'],
    states: ['default', 'pressed (잉크 리플)', 'highlighted'],
    tokens: [
      { name: 'color-background',     where: '카드 배경 (colorScheme.surface = 라이트 화이트).' },
      { name: 'color-divider',        where: '기본 보더 (1px outlineVariant).' },
      { name: 'color-primary',        where: 'highlighted 보더 색.' },
      { name: 'radius-card',          where: '카드 모서리 (16px).' },
      { name: 'spacing-card-content-v', where: '내부 vertical padding (16px) — 기본값.' },
      { name: 'spacing-medium',       where: '내부 horizontal padding (16px) — 기본값.' },
    ],
    accessibility: [
      'onTap이 있으면 Material InkWell이 tap target / focus ring을 처리.',
      'highlighted 상태는 시각만 — 선택 의미가 있으면 부모가 Semantics(selected: true)를 추가해야 함.',
    ],
    guidelines: [
      { kind: 'do',   text: '여러 옵션 중 선택된 항목을 highlighted=true로 표시. 한 번에 하나만 강조.',  recipeKey: 'do-highlight-selected' },
      { kind: 'dont', text: '여러 카드를 동시에 highlighted로 두지 말 것 — 강조 의미가 사라짐.',          recipeKey: 'dont-stacked-highlights' },
      { kind: 'do',   text: 'onTap이 있으면 카드 전체가 탭 영역. 내부에 별도 버튼 두지 않는 것이 자연스러움.' },
    ],
    placement: {
      where: [
        '`List + Filter chips` 스캐폴드의 리스트 항목 — 카드 단위 컨텐츠.',
        '`Detail + Bottom CTA`의 본문 안 정보 그룹핑.',
      ],
      spacing: [
        { neighbor: '같은 리스트의 sibling 카드', gap: 'spacing-card-gap (12px)' },
        { neighbor: '카드 내부 상하 패딩',         gap: 'spacing-card-content-v (16px)' },
        { neighbor: '카드 내부 좌우 패딩',         gap: 'spacing-medium (16px)' },
      ],
    },
    dartUsage: `// 일반 카드
MinglitContentCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('루프탑 라운지', style: titleMedium),
      Text('강남 · 5월 3일 · 19:00', style: bodySmall),
    ],
  ),
)

// 탭 가능 + 강조 (선택된 옵션)
MinglitContentCard(
  highlighted: isSelected,
  onTap: () => onSelect(option),
  child: Text(option.label),
)`,
  },
  {
    name: 'MinglitTag',
    category: 'Tags & Badges',
    purpose: '읽기 전용 인라인 컬러 레이블. 카테고리·상태 표시 전용 — 상호작용 없음. MinglitChip과 달리 onTap 없음, MinglitBadge와 달리 icon + size 2가지 지원.',
    props: [
      { name: 'label', type: 'String',          required: true,  notes: '태그 안에 표시되는 텍스트 레이블.' },
      { name: 'color', type: 'Color',           required: true,  notes: '배경 tint + 텍스트/아이콘 색. MinglitColors.primary / success / warning / error / info 중 하나 권장.' },
      { name: 'icon',  type: 'IconData?',       default: 'null', notes: '선택적 leading 아이콘. label과 동일 color. spacing-xsmall(4px) gap.' },
      { name: 'size',  type: 'MinglitTagSize',  default: 'medium', notes: 'small(h≈22, font 10px, icon 12px) / medium(h≈28, font 13px, icon 14px).' },
    ],
    variants: ['primary', 'success', 'warning', 'error', 'info'],
    states: ['default (read-only)'],
    tokens: [
      { name: 'radius-chip',                       where: 'tag border radius (100px — fully rounded, MinglitRadius.chip)' },
      { name: 'spacing-small',                     where: 'small 크기 수평 패딩 (8px)' },
      { name: 'spacing-sm',                        where: 'medium 크기 수평 패딩 (12px)' },
      { name: 'spacing-xxsmall',                   where: 'small 크기 수직 패딩 (2px)' },
      { name: 'spacing-xsmall',                    where: 'medium 크기 수직 패딩 + icon↔label gap (4px)' },
      { name: 'color-primary',                     where: 'primary variant 배경 tint + 텍스트' },
      { name: 'color-success',                     where: 'success variant 배경 tint + 텍스트' },
      { name: 'color-warning',                     where: 'warning variant 배경 tint + 텍스트' },
      { name: 'color-error',                       where: 'error variant 배경 tint + 텍스트' },
      { name: 'color-info',                        where: 'info variant 배경 tint + 텍스트' },
      { name: 'typography-font-size-caption-tiny', where: 'small 크기 폰트 (10px)' },
      { name: 'typography-font-size-chip-label',   where: 'medium 크기 폰트 (13px)' },
    ],
    accessibility: [
      'MinglitTag는 항상 읽기 전용 — Semantics(button: false, label: label). 스크린 리더가 단순 텍스트로 읽음.',
      '상호작용이 필요하면 MinglitChip(onTap 있음)을 사용한다.',
    ],
    guidelines: [
      { kind: 'do',   text: '카드 인라인 카테고리/상태 표시는 small size Tag를 사용한다. MinglitContentCard 하단 row에서 MinglitParticipantGauge와 페어링.', recipeKey: 'do-tag-in-card' },
      { kind: 'dont', text: 'MinglitTag를 버튼처럼 사용하지 말 것 (클릭 유도 텍스트 "+" 포함 등) — 항상 read-only 의미.', recipeKey: 'dont-tag-as-button' },
      { kind: 'do',   text: '상태 색상은 시스템 의미에 맞게 — success=승인, warning=대기, error=취소. 커스텀 색상 사용 시 명암비 직접 확인.', recipeKey: 'do-status-mapping' },
      { kind: 'dont', text: '인터랙티브 태그가 필요하면 MinglitTag가 아닌 MinglitChip(onTap)을 사용할 것.', recipeKey: 'dont-override-with-chip' },
      { kind: 'do',   text: '공간이 제한된 카드 인라인 위치(리스트 행, trailing slot)에는 size=small을 사용한다.', recipeKey: 'do-small-size-inline' },
    ],
    dartUsage: `// 카테고리 태그 (medium, default)
MinglitTag(label: '음악', color: MinglitColors.primary, icon: Icons.music_note)

// 상태 태그 (small, 카드 인라인)
MinglitTag(label: '승인', color: MinglitColors.success, size: MinglitTagSize.small)

// 경고 상태 (icon 있음)
MinglitTag(label: '대기', color: MinglitColors.warning, icon: Icons.hourglass_empty, size: MinglitTagSize.small)`,
    placement: {
      where: [
        'MinglitContentCard 하단 row — 좌측에 MinglitParticipantGauge와 Row(spacer) 패턴으로 페어링. size=small.',
        '`Detail + Bottom CTA` 스캐폴드 — MinglitSection 안 카테고리/상태 row. size=medium.',
        '`List + Filter chips` 스캐폴드 — 카드 인라인 메타데이터 row. size=small.',
      ],
      spacing: [
        { neighbor: 'sibling MinglitTag (Wrap)',     gap: 'spacing-small (8px)',  note: 'Wrap(spacing: MinglitSpacing.small) 기본값' },
        { neighbor: 'MinglitParticipantGauge (Row)', gap: 'Spacer()',             note: '카드 하단 row — 태그 좌측, 게이지 우측' },
        { neighbor: '카드 내 상위 텍스트',           gap: 'spacing-xsmall (4px)', note: '제목 → 태그 row 간격' },
      ],
      compositions: [
        { label: 'Tag + Gauge in card row', description: 'MinglitContentCard 하단 — tag(left) + Spacer + gauge(right).', recipeKey: 'do-tag-in-card' },
        { label: 'Status tags in detail',   description: '상세 페이지 MinglitSection 내 Wrap — 카테고리 + 상태 태그 2–3개.' },
      ],
    },
  },
  {
    name: 'MinglitBadge',
    category: 'Tags & Badges',
    purpose: '앱 전역 상태 배지 — 정산·파티·이벤트 상태 표시, 알림 카운트 등. 직사각형 rounded 모서리(radius-small). MinglitTag와 달리 icon 없음, compact 모드 있음.',
    props: [
      { name: 'label',   type: 'String', required: true,  notes: '배지 안에 표시되는 텍스트. 상태 단어, 숫자 카운트, 분류 레이블 가능.' },
      { name: 'color',   type: 'Color',  required: true,  notes: '배경 tint + 텍스트 색. MinglitColors.* 사용 권장.' },
      { name: 'compact', type: 'bool',   default: 'false', notes: 'true: labelSmall(11px) + padding h:8px v:2px. false(default): labelMedium(13px) + h:12px v:4px.' },
    ],
    variants: ['success', 'warning', 'error', 'primary', 'info'],
    states: ['default', 'compact'],
    tokens: [
      { name: 'radius-small',                    where: 'badge border radius (8px) — MinglitRadius.small, 직사각형 pill' },
      { name: 'spacing-small',                   where: 'compact 수평 패딩 (8px)' },
      { name: 'spacing-sm',                      where: 'default 수평 패딩 (12px)' },
      { name: 'spacing-xxsmall',                 where: 'compact 수직 패딩 (2px)' },
      { name: 'spacing-xsmall',                  where: 'default 수직 패딩 (4px)' },
      { name: 'color-success',                   where: 'success variant 배경 tint + 텍스트' },
      { name: 'color-warning',                   where: 'warning variant 배경 tint + 텍스트' },
      { name: 'color-error',                     where: 'error variant 배경 tint + 텍스트' },
      { name: 'color-primary',                   where: 'primary variant 배경 tint + 텍스트' },
      { name: 'color-info',                      where: 'info variant 배경 tint + 텍스트' },
      { name: 'typography-font-size-chip-label', where: 'default 폰트 (13px, labelMedium)' },
      { name: 'typography-font-size-caption',    where: 'compact 폰트 (11px, labelSmall)' },
    ],
    accessibility: [
      'MinglitBadge는 읽기 전용 상태 레이블. 스크린 리더는 label 텍스트를 직접 읽음.',
      '숫자 카운트 배지는 aria-label로 맥락 제공 권장 (예: "알림 3개").',
      '99 초과 카운트는 "99+"로 표시 — label 문자열 처리는 caller 책임.',
    ],
    guidelines: [
      { kind: 'do',   text: '리스트 행/테이블 셀의 상태 표시에 compact=true를 사용한다. 넓은 공간(상세 섹션)에는 default를 사용.', recipeKey: 'do-badge-in-list-row' },
      { kind: 'dont', text: 'MinglitBadge를 액션 버튼으로 사용하지 말 것 ("+", "요청" 등 행위 동사 포함) — MinglitButton 사용.', recipeKey: 'dont-badge-as-action' },
      { kind: 'do',   text: '알림 카운트 배지는 99 초과 시 "99+"로 고정한다. caller에서 label = count > 99 ? "99+" : "$count" 처리.', recipeKey: 'do-max-overflow' },
      { kind: 'do',   text: '상태 색상은 앱 전역 일관성을 유지: success=승인됨, warning=대기, error=거절. 같은 화면에서 색상 재사용하지 않을 것.', recipeKey: 'do-status-consistency' },
      { kind: 'dont', text: '같은 화면에 5가지 이상 색상 배지를 쓰지 말 것 — 색상 피로도. 배지 종류는 2–3가지로 제한.' },
    ],
    dartUsage: `// 정산 상태 배지
MinglitBadge(label: '승인됨', color: MinglitColors.success)

// 대기 상태 (compact — 리스트 trailing)
MinglitBadge(label: '대기', color: MinglitColors.warning, compact: true)

// 알림 카운트 (99+ 처리)
MinglitBadge(
  label: notificationCount > 99 ? '99+' : '$notificationCount',
  color: MinglitColors.error,
  compact: true,
)`,
    placement: {
      where: [
        '`Detail + Bottom CTA` 스캐폴드 — MinglitSection 안 상태 row. default size.',
        '리스트 행 trailing 슬롯 (MinglitListTile trailing). compact=true.',
        'AppBar / 알림 아이콘 위 오버레이 카운트 배지. compact=true.',
        '`Settings groups` — 설정 타일 trailing 상태 표시. compact=true.',
      ],
      spacing: [
        { neighbor: '리스트 tile 좌측 텍스트',  gap: 'Spacer()',                note: 'trailing 배치 — Row(MainAxisAlignment.spaceBetween)' },
        { neighbor: '상세 섹션 sibling 요소',   gap: 'spacing-xsmall (4px)',    note: '인라인 배지는 텍스트와 타이트하게' },
        { neighbor: 'AppBar 아이콘 (오버레이)', gap: '0 (absolute position)',   note: 'Stack + Positioned으로 아이콘 우상단 오버레이' },
      ],
      compositions: [
        { label: 'Status in list row',    description: '리스트 행 우측 trailing — compact 배지로 상태 표시.', recipeKey: 'do-badge-in-list-row' },
        { label: 'Count overlay on icon', description: 'AppBar 알림 아이콘 위 오버레이. Stack + Positioned.', recipeKey: 'do-max-overflow' },
      ],
    },
  },
  {
    name: 'MinglitParticipantGauge',
    category: 'Tags & Badges',
    purpose: '파티/이벤트 참여자 수를 3-세그먼트 배터리 게이지로 시각화. current/max 비율에 따라 세그먼트 수와 색상이 자동 결정됨. 텍스트(N/M) + people 아이콘 포함 pill 컨테이너.',
    props: [
      { name: 'current', type: 'int', required: true, notes: '현재 참여자 수.' },
      { name: 'max',     type: 'int', required: true, notes: '최대 정원. 0이면 비율 0으로 처리.' },
    ],
    variants: ['empty (0)', 'low (1-seg)', 'medium (2-seg)', 'full (3-seg)'],
    states: ['empty (0/n)', 'partial (1 or 2 segments)', 'full (n/n)'],
    tokens: [
      { name: 'radius-chip',                   where: '컨테이너 border radius (100px — 완전한 pill)' },
      { name: 'spacing-xsmall2',               where: '컨테이너 수평 패딩 (6px)' },
      { name: 'spacing-xxsmall',               where: '컨테이너 수직 패딩 + 세그먼트 간 gap (2px)' },
      { name: 'spacing-small',                 where: '각 세그먼트 높이 (8px = spacing-small)' },
      { name: 'color-secondary',               where: '1-세그먼트 색 (orange, 0–33%)' },
      { name: 'color-tertiary',                where: '2-세그먼트 색 (mint, 34–66%)' },
      { name: 'color-primary',                 where: '3-세그먼트 색 (purple, 67–100%)' },
      { name: 'color-divider',                 where: '비활성 세그먼트 색 (outlineVariant)' },
      { name: 'typography-font-size-caption',  where: '레이블 텍스트 11px (labelSmall, w700)' },
    ],
    accessibility: [
      'Semantics(label: "$current/$max 참여") 제공 권장 — 스크린 리더가 게이지 수치를 읽음.',
      '색상만으로 상태를 전달하므로 텍스트 레이블(N/M) + 아이콘이 반드시 함께 표시됨 (색맹 대응).',
    ],
    guidelines: [
      { kind: 'do',   text: 'MinglitContentCard 하단 row에서 MinglitTag(좌)와 Row + Spacer()로 배치. 카드 단위 참여 현황을 한눈에.', recipeKey: 'do-gauge-in-card' },
      { kind: 'dont', text: '"참여자: 7/20명" 같은 raw 텍스트로 대체하지 말 것 — 시각적 밀도와 스캔성이 떨어짐.', recipeKey: 'dont-show-raw-text' },
      { kind: 'do',   text: 'full 상태(n/n)는 primary 색상 3-세그먼트로 자동 강조됨 — 추가 스타일 없이 마감 상태를 전달.', recipeKey: 'do-full-state-highlight' },
      { kind: 'dont', text: '세그먼트 색상을 직접 오버라이드하지 말 것 — 색상 의미(orange→mint→purple) 일관성이 앱 전역 기대값.', recipeKey: 'dont-override-colors' },
      { kind: 'do',   text: 'max=0 엣지 케이스는 위젯이 ratio=0으로 처리하므로 null 체크 없이 바로 사용 가능.' },
    ],
    dartUsage: `// 기본 사용 (카드 하단 row)
MinglitParticipantGauge(
  current: event.currentParticipants,
  max: event.maxParticipants,
)

// 카드 내 태그 + 게이지 패턴 (storybook 예시)
Row(
  children: [
    MinglitTag(label: event.categoryLabel, color: MinglitColors.primary, size: MinglitTagSize.small),
    const Spacer(),
    MinglitParticipantGauge(current: event.currentParticipants, max: event.maxParticipants),
  ],
)`,
    placement: {
      where: [
        'MinglitContentCard 하단 row 우측 trailing — MinglitTag(좌)와 Spacer()로 배치.',
        '`Detail + Bottom CTA` 스캐폴드 — MinglitSection 안 참여 현황 row.',
        '`List + Filter chips` 스캐폴드 — 카드 리스트 각 행 하단.',
      ],
      spacing: [
        { neighbor: 'MinglitTag (Row 좌측)', gap: 'Spacer()',                       note: '카드 하단 row — 태그 좌측 고정, 게이지 우측 고정' },
        { neighbor: '카드 하단 패딩',         gap: 'spacing-card-content-v (16px)',  note: 'MinglitContentCard 내부 패딩 기준' },
      ],
      compositions: [
        { label: 'Tag + Gauge in card row', description: 'MinglitContentCard 하단 — MinglitTag(small, left) + Spacer + MinglitParticipantGauge(right).', recipeKey: 'do-gauge-in-card' },
        { label: 'Gauge in detail section', description: '상세 페이지 참여 현황 섹션 — 단독 row, 전체 너비.' },
      ],
    },
  },

  // ---------- Feedback ----------
  {
    name: 'MinglitEmptyState',
    category: 'Feedback',
    purpose: '데이터가 없는 빈 상태를 통일된 UI로 표시. 아이콘 + 제목 + 선택적 부제 + 선택적 CTA 구성. fullPage / card / inline 3가지 variant.',
    props: [
      { name: 'title',       type: 'String',                       required: true,  notes: '빈 상태를 설명하는 주 메시지. 구체적으로 — "저장된 모임이 없어요" 수준.' },
      { name: 'icon',        type: 'IconData',                     default: 'Icons.inbox_outlined', notes: 'variant=inline일 때 무시됨. fullPage 48px · card 32px.' },
      { name: 'subtitle',    type: 'String?',                      default: 'null', notes: '보조 메시지. 짧게 — 1~2줄 이내.' },
      { name: 'actionLabel', type: 'String?',                      default: 'null', notes: 'CTA 버튼 텍스트. onAction과 함께 제공해야 버튼이 노출됨. fullPage variant 전용.' },
      { name: 'onAction',    type: 'VoidCallback?',                default: 'null', notes: 'CTA 버튼 콜백. actionLabel과 함께 제공해야 버튼이 노출됨. fullPage variant 전용.' },
      { name: 'variant',     type: 'MinglitEmptyStateVariant',     default: 'fullPage', notes: 'fullPage: 탭/페이지 레벨, 투명 배경. card: 카드/섹션 내부, surface 배경+radius-card. inline: 폼 플레이스홀더, surface+divider 보더+radius-card.' },
    ],
    variants: ['fullPage', 'card', 'inline'],
    states: ['default'],
    tokens: [
      { name: 'color-text-primary',   where: 'title 텍스트 색상' },
      { name: 'color-text-secondary', where: 'subtitle 텍스트 색상 · 아이콘 색상 (outlined)' },
      { name: 'color-surface',        where: 'card variant 배경 · inline variant 배경' },
      { name: 'color-divider',        where: 'inline variant 보더 색상' },
      { name: 'color-primary',        where: 'CTA 버튼(FilledButton) 배경' },
      { name: 'radius-card',          where: 'card/inline variant container border-radius' },
      { name: 'spacing-medium',       where: '아이콘 → title 갭 (16px)' },
      { name: 'spacing-small',        where: 'title → subtitle 갭 (8px)' },
      { name: 'spacing-large',        where: 'subtitle → CTA 갭 (24px)' },
      { name: 'spacing-xlarge',       where: 'container 내부 padding (32px)' },
      { name: 'typography-font-size-button',        where: 'title 폰트 사이즈' },
      { name: 'typography-font-size-body',          where: 'subtitle 폰트 사이즈' },
      { name: 'typography-font-weight-semi-bold',   where: 'title 폰트 굵기' },
    ],
    accessibility: [
      '아이콘은 aria-hidden — 의미는 title이 전달. 별도 aria-label 불필요.',
      'CTA 버튼은 충분히 구체적인 label 사용 (예: "모임 찾기", not "확인").',
      '빈 상태 영역 전체를 role="status" region으로 래핑하면 스크린 리더가 데이터 없음을 알림.',
    ],
    guidelines: [
      { kind: 'do',   text: '구체적인 한국어 copy 사용 — "저장된 모임이 없어요" (not "Empty").',           recipeKey: 'do-specific-copy' },
      { kind: 'dont', text: '영문 generic copy 사용 금지 — "No data available" 등.',                     recipeKey: 'dont-generic-copy' },
      { kind: 'do',   text: '사용자가 취할 수 있는 다음 행동이 있으면 CTA로 안내.',                        recipeKey: 'do-cta-when-actionable' },
      { kind: 'dont', text: '빈 리스트에 ErrorState를 쓰지 말 것 — 에러와 빈 상태는 다른 개념.',           recipeKey: 'dont-error-for-empty' },
      { kind: 'do',   text: 'card/inline variant에는 CTA 없음 — 컨테이너 수준 액션은 부모에게 위임.' },
    ],
    dartUsage: `// fullPage — 탭/페이지 수준 빈 상태
MinglitEmptyState(
  icon: Icons.bookmark_border,
  title: '저장된 모임이 없어요',
  subtitle: '새로운 모임을 만들거나 참여해보세요.',
  actionLabel: '모임 찾기',
  onAction: () => context.push(Routes.eventBrowse),
)

// fullPage — 검색 결과 없음 (CTA 없음)
MinglitEmptyState(
  icon: Icons.search_off,
  title: '검색 결과가 없어요',
  subtitle: '다른 키워드로 검색해보세요.',
)

// card — 카드/섹션 내부 빈 상태
MinglitEmptyState.card(
  title: '등록된 공지사항이 없어요',
  subtitle: '파트너가 공지를 남기면 여기에 표시됩니다.',
)

// inline — 폼 플레이스홀더
MinglitEmptyState.inline(
  title: '선택된 항목 없음',
  subtitle: '위에서 항목을 선택하세요.',
)`,
    placement: {
      where: [
        '`List + Filter chips` 스캐폴드 — 필터 결과가 0건일 때 리스트 영역 전체를 대체.',
        '`Detail + Bottom CTA` 스캐폴드 — 섹션 본문 영역이 비었을 때 (card variant).',
        '`Form + Bottom CTA` 스캐폴드 — 입력 선택 필드 플레이스홀더 (inline variant).',
        '`Settings groups` 스캐폴드 — 설정 그룹 내 항목이 없을 때 (card variant).',
      ],
      spacing: [
        { neighbor: '위 Filter chip row',          gap: 'spacing-medium (16px)',  note: 'fullPage 시 리스트 전체 교체' },
        { neighbor: 'MinglitContentCard 내부 padding', gap: 'spacing-xlarge (32px)', note: 'card variant는 container 내부 padding 포함' },
      ],
      compositions: [
        { label: 'EmptyState in List',  description: 'List + Filter chips 스캐폴드에서 결과 0건 — fullPage variant로 리스트 영역 대체.', recipeKey: 'do-specific-copy' },
        { label: 'EmptyState in Card',  description: 'MinglitContentCard 안 섹션이 빔 — card variant 삽입, CTA 없음.',                  recipeKey: 'do-cta-when-actionable' },
      ],
    },
  },
  {
    name: 'MinglitErrorState',
    category: 'Feedback',
    purpose: '에러 발생 시 통일된 UI를 표시. 아이콘 + 제목 + 선택적 부제 + 선택적 재시도 버튼. fullPage / card / inline 3가지 variant.',
    props: [
      { name: 'title',      type: 'String',                       default: "'오류가 발생했습니다.'", notes: '에러를 설명하는 주 메시지. 구체적으로 — "데이터를 불러올 수 없어요" 수준.' },
      { name: 'icon',       type: 'IconData',                     default: 'Icons.error_outline', notes: 'variant=inline일 때 무시됨. fullPage 64px · card 32px.' },
      { name: 'subtitle',   type: 'String?',                      default: 'null', notes: '에러 원인 힌트 또는 사용자 조치 안내. 예: "네트워크 연결을 확인해주세요."' },
      { name: 'onRetry',    type: 'VoidCallback?',                default: 'null', notes: '재시도 콜백. null이면 재시도 버튼 미노출. fullPage variant 전용.' },
      { name: 'retryLabel', type: 'String',                       default: "'다시 시도'", notes: '재시도 버튼 텍스트. 필요 시 커스터마이즈 (예: "새로고침").' },
      { name: 'variant',    type: 'MinglitErrorStateVariant',     default: 'fullPage', notes: 'fullPage: 탭/페이지 레벨, 투명 배경. card: 카드/섹션, error tinted 배경+radius-card. inline: 폼/필드, error tinted+error 보더+radius-card.' },
    ],
    variants: ['fullPage', 'card', 'inline'],
    states: ['default'],
    tokens: [
      { name: 'color-error',          where: 'icon 색상 · title 텍스트 색상 · retry 버튼 보더+텍스트 · inline 보더 색상' },
      { name: 'color-text-secondary', where: 'subtitle 텍스트 색상' },
      { name: 'color-surface',        where: 'card/inline variant 배경 기반 (error tint 위에 blend)' },
      { name: 'radius-card',          where: 'card/inline variant container border-radius' },
      { name: 'spacing-medium',       where: '아이콘 → title 갭 (16px)' },
      { name: 'spacing-small',        where: 'title → subtitle 갭 (8px)' },
      { name: 'spacing-large',        where: 'subtitle → retry 버튼 갭 (24px)' },
      { name: 'spacing-xlarge',       where: 'container 내부 padding (32px)' },
      { name: 'typography-font-size-button', where: 'title 폰트 사이즈' },
      { name: 'typography-font-size-body',   where: 'subtitle 폰트 사이즈' },
      { name: 'typography-font-weight-bold', where: 'title 폰트 굵기' },
    ],
    accessibility: [
      '아이콘은 aria-hidden — 에러 의미는 title이 전달.',
      '재시도 버튼은 의미 있는 label 사용 — "다시 시도" / "새로고침" 등.',
      '에러 영역을 role="alert"로 래핑하면 스크린 리더가 에러 발생을 즉시 알림.',
      '재시도 중에는 isLoading=true인 MinglitButton으로 교체하거나 버튼을 비활성화해 중복 탭 차단.',
    ],
    guidelines: [
      { kind: 'do',   text: '네트워크/서버 오류 시에만 ErrorState 사용. 빈 결과는 EmptyState.',                            recipeKey: 'do-retry-on-network-error' },
      { kind: 'dont', text: '데이터가 없는 것(빈 상태)에 ErrorState 쓰지 말 것.',                                          recipeKey: 'dont-retry-on-empty' },
      { kind: 'do',   text: '구체적인 에러 메시지 제공 — "서버에 연결할 수 없어요" + "인터넷 연결 확인" 같은 조치 안내.',  recipeKey: 'do-specific-error-message' },
      { kind: 'dont', text: '"오류가 발생했습니다." 단독 노출 금지 — subtitle 없으면 사용자가 원인 모름.',                  recipeKey: 'dont-generic-error-only' },
      { kind: 'do',   text: 'onRetry가 의미 있을 때만 CTA 제공. 에러가 재시도로 해결 불가면 버튼 생략.' },
    ],
    dartUsage: `// fullPage — 네트워크 오류, 재시도 가능
MinglitErrorState(
  title: '데이터를 불러올 수 없어요',
  subtitle: '네트워크 연결을 확인하고 다시 시도해주세요.',
  onRetry: () => ref.invalidate(eventsProvider),
)

// card — 카드/섹션 에러 (재시도 버튼 없음)
MinglitErrorState.card(
  title: '정산 내역을 불러오지 못했어요',
  subtitle: '잠시 후 다시 시도해주세요.',
)

// inline — 폼 필드 수준 에러 표시
MinglitErrorState.inline(
  title: '올바르지 않은 값입니다',
  subtitle: '입력 형식을 확인해주세요.',
)`,
    placement: {
      where: [
        '`List + Filter chips` 스캐폴드 — 목록 로드 실패 시 리스트 영역 전체를 대체 (fullPage).',
        '`Detail + Bottom CTA` 스캐폴드 — 섹션 데이터 로드 실패 시 (card variant).',
        '`Form + Bottom CTA` 스캐폴드 — 제출 실패 메시지 (inline variant).',
        '`MinglitAsyncValueWidget`의 error builder 슬롯 — Riverpod AsyncError 시 자동 렌더링.',
      ],
      spacing: [
        { neighbor: '위 Filter chip row',          gap: 'spacing-medium (16px)',   note: 'fullPage 시 리스트 전체 교체' },
        { neighbor: 'MinglitContentCard 내부 padding', gap: 'spacing-xlarge (32px)', note: 'card variant는 container 내부 padding 포함' },
        { neighbor: '폼 필드 아래',                 gap: 'spacing-small (8px)',     note: 'inline variant — 필드 직하단 배치' },
      ],
      compositions: [
        { label: 'ErrorState + AsyncValueWidget', description: 'MinglitAsyncValueWidget의 error 슬롯에 자동 연결 — onRetry로 ref.invalidate 전달.', recipeKey: 'do-retry-on-network-error' },
        { label: 'ErrorState in Card',            description: 'MinglitContentCard 안 데이터 로드 실패 — card variant, 재시도 버튼 없음.',          recipeKey: 'do-specific-error-message' },
      ],
    },
  },

  // ---------- Layout ----------
  {
    name: 'MinglitSection',
    category: 'Sections',
    purpose: '제목 + 본문 + 옵션 trailing 액션을 통일된 구조로 감싸는 섹션 래퍼. 상세 / 리스트 페이지에서 콘텐츠를 의미 있는 그룹으로 묶어주는 가장 기본 atom.',
    props: [
      { name: 'title',      type: 'String',           required: true, notes: '섹션 제목 — 굵은 titleMedium으로 표시.' },
      { name: 'child',      type: 'Widget',           required: true, notes: '제목 아래 본문 콘텐츠.' },
      { name: 'trailing',   type: 'Widget?',          default: 'null', notes: '제목 우측 액션 — 보통 "더보기 →" TextButton.' },
      { name: 'padding',    type: 'EdgeInsetsGeometry?', default: 'null', notes: '외곽 padding 오버라이드. null이면 horizontal screenEdge 16.' },
      { name: 'titleStyle', type: 'TextStyle?',        default: 'null', notes: '제목 스타일 오버라이드. null이면 titleMedium.bold.' },
      { name: 'spacing',    type: 'double?',           default: 'null', notes: '제목 ↔ 본문 간격. null이면 sm(12).' },
    ],
    variants: ['default', 'with trailing'],
    states: ['default'],
    tokens: [
      { name: 'spacing-screen-edge', where: '외곽 horizontal padding 기본값 (16px).' },
      { name: 'spacing-sm',          where: '제목 ↔ 본문 간격 기본값 (12px).' },
      { name: 'color-text-primary',  where: '제목 색상.' },
      { name: 'color-primary',       where: 'trailing 액션 (TextButton) 텍스트 색.' },
    ],
    accessibility: [
      'title은 Semantics에서 heading으로 노출 — 스크린리더가 섹션 단위로 빠르게 탐색 가능.',
      'trailing이 있으면 별도의 button Semantics — 제목 자체는 read-only.',
    ],
    guidelines: [
      { kind: 'do',   text: '리스트가 잘려 있을 때 "더보기 →" trailing으로 전체 보기 진입점 제공.', recipeKey: 'do-trailing-for-overflow' },
      { kind: 'dont', text: '아무 액션 없는 섹션에 trailing을 두지 말 것 — 시각적 노이즈만 추가.',  recipeKey: 'dont-trailing-without-action' },
    ],
    placement: {
      where: [
        '`Detail + Bottom CTA`의 스크롤 본문 안 — 한 화면당 여러 섹션을 세로로 쌓음.',
        '`MinglitContentLayout` 안의 직계 자식.',
      ],
      spacing: [
        { neighbor: '다음 섹션',           gap: 'spacing-section-gap (40px)', note: '큰 토픽 단위 분리' },
        { neighbor: '섹션 헤더 → 본문',    gap: 'spacing-sm (12px)', note: '기본값 — spacing prop으로 조정 가능' },
        { neighbor: '섹션 내 그룹 사이',    gap: 'spacing-large (24px)' },
      ],
    },
    dartUsage: `// 단순 섹션
MinglitSection(
  title: '이번 주 일정',
  child: ScheduleList(items),
)

// 더보기 액션이 있는 섹션
MinglitSection(
  title: '추천 이벤트',
  trailing: TextButton(
    onPressed: () => goToAll(),
    child: const Text('더보기'),
  ),
  child: HorizontalScrollGroup(child: cards),
)`,
  },
  {
    name: 'MinglitSectionDivider',
    category: 'Sections',
    purpose: '콘텐츠 영역을 구분하는 두 가지 굵기의 디바이더. thin(1px)은 같은 그룹 내 행 사이 부드러운 구분, thick(8px)은 큰 섹션 간 강한 분리.',
    props: [
      { name: 'isThick', type: 'bool', required: true, notes: 'true면 8px 회색 띠, false면 1px 얇은 선. 보통 named constructor (.thick / .thin)로 사용.' },
    ],
    variants: ['thin (1px)', 'thick (8px)'],
    states: ['default (정적)'],
    tokens: [
      { name: 'color-divider',                where: 'thin 선 색상 (1px).' },
      { name: 'color-surface-container-highest', where: 'thick 띠 배경 (회색 8px).' },
      { name: 'spacing-small',                where: 'thick 변형 높이 (8px).' },
    ],
    accessibility: [
      '순수 시각 디바이더 — Semantics에 노출되지 않음 (스크린리더는 무시).',
      '의미 있는 구분이 필요하면 부모가 별도 heading / Semantics를 제공.',
    ],
    guidelines: [
      { kind: 'do',   text: '카드 / 그룹 안에서 행과 행을 가를 때 thin — 부드러운 시각적 호흡.',         recipeKey: 'do-thin-inside-group' },
      { kind: 'do',   text: '큰 섹션(계정 / 알림 등) 사이를 강하게 분리할 때 thick.',                    recipeKey: 'do-thick-between-sections' },
      { kind: 'dont', text: 'thick을 연속으로 여러 번 쓰지 말 것 — 화면이 회색 띠로 도배되는 인상.',     recipeKey: 'dont-stacked-thicks' },
    ],
    placement: {
      where: [
        '섹션 사이 명시적 시각 구분이 필요할 때만 — 보통은 spacing-section-gap 만으로 충분.',
        'thick(8px) — 섹션 단위 강한 분리. thin(1px) — 그룹 단위 약한 분리.',
      ],
    },
    dartUsage: `// 같은 그룹 내 행 구분
const MinglitSectionDivider.thin()

// 큰 섹션 사이 분리
const MinglitSectionDivider.thick()`,
  },
  {
    name: 'MinglitListTile',
    category: 'Lists',
    purpose: '제목 + 옵션 부제 + 좌측 leading / 우측 trailing 슬롯을 가진 일반 리스트 행. 멤버 / 알림 / 도메인 데이터 같은 일반 리스트에 사용 (vs SettingsTile은 설정 화면 전용 48px 고정).',
    props: [
      { name: 'title',    type: 'String',          required: true, notes: '주 라벨 (bodyLarge).' },
      { name: 'subtitle', type: 'String?',         default: 'null', notes: 'title 아래 보조 텍스트 — 들어가면 행이 2-line으로 자라남.' },
      { name: 'leading',  type: 'Widget?',         default: 'null', notes: '좌측 슬롯 — 아이콘 / 직접 위젯. avatar가 함께 있으면 무시됨.' },
      { name: 'avatar',   type: 'ImageProvider?',  default: 'null', notes: '편의 prop — 이미지를 CircleAvatar로 자동 래핑. leading보다 우선.' },
      { name: 'trailing', type: 'Widget?',         default: 'null', notes: '우측 슬롯 — chevron / 뱃지 / 텍스트 등 자유.' },
      { name: 'onTap',    type: 'VoidCallback?',   default: 'null', notes: '탭 콜백 — 있으면 잉크 리플 + Semantics(button: true).' },
      { name: 'enabled',  type: 'bool',            default: 'true', notes: 'false면 흐려지고 탭 차단. 권한 부족 / 잠긴 항목.' },
    ],
    variants: ['avatar leading', 'icon leading', 'no leading'],
    states: ['default', 'disabled', 'with subtitle (2-line)', 'title only (1-line)'],
    tokens: [
      { name: 'color-text-primary',    where: 'title 텍스트.' },
      { name: 'color-text-secondary',  where: 'subtitle 텍스트 / leading 아이콘 색.' },
      { name: 'spacing-medium',        where: '좌우 padding (16px) · leading↔title 갭.' },
      { name: 'spacing-xsmall',        where: 'tile vertical padding (4px).' },
      { name: 'radius-small',          where: 'InkWell shape (8px) — 탭 시 잉크 리플 모서리.' },
    ],
    accessibility: [
      'onTap이 있으면 button: true Semantics, 비활성 시 enabled: false.',
      'avatar가 있으면 CircleAvatar는 image label 부재 — 시각 보조에만 사용.',
      'subtitle이 단순 보조 정보일 때만 — 핵심 정보는 title에 둘 것.',
    ],
    guidelines: [
      { kind: 'do',   text: '사람 / 파트너 같은 entity는 avatar leading + 이름 title + 역할 subtitle.', recipeKey: 'do-avatar-person-row' },
      { kind: 'do',   text: '추상 개념 / 시스템 알림은 24px 아이콘 leading.',                            recipeKey: 'do-icon-concept-row' },
      { kind: 'dont', text: '설정 화면 행에는 사용하지 말 것 — MinglitSettingsTile (48px 고정)이 그 용도.', recipeKey: 'dont-use-for-settings' },
    ],
    placement: {
      where: [
        '리스트 / 멤버 / 알림 같은 동질적 row의 반복 단위.',
        '`MinglitContentCard` 안에서도 사용 가능 (카드 내부 row).',
      ],
      spacing: [
        { neighbor: '같은 리스트의 sibling tile', gap: '0', note: '연속 row는 보더 없이 붙음 (divider는 별도)' },
        { neighbor: '내부 vertical padding',       gap: 'spacing-xsmall (4px)', note: 'Material ListTile 기본 + minVerticalPadding small' },
      ],
    },
    dartUsage: `// 사람 행 — 아바타 + 역할
MinglitListTile(
  avatar: NetworkImage('https://example.com/photo.jpg'),
  title: '홍길동',
  subtitle: '파트너 매니저',
  trailing: const Icon(Icons.chevron_right),
  onTap: () => coordinator.openMember(id),
)

// 알림 행 — 아이콘 + 시간
MinglitListTile(
  leading: const Icon(Icons.mail_outline),
  title: '새 메시지 도착',
  subtitle: '2시간 전',
  onTap: () => openNotification(),
)`,
  },
  {
    name: 'MinglitKeyValueRow',
    category: 'Lists',
    purpose: '왼쪽 라벨 + 오른쪽 값 양 끝 정렬 행. 결제 / 정산 요약 카드, 이벤트 메타 정보 등 정형화된 정보 표시에 사용.',
    props: [
      { name: 'label',      type: 'String',  required: true, notes: '좌측 라벨 (bodyMedium · onSurfaceVariant 회색).' },
      { name: 'value',      type: 'String',  required: true, notes: '우측 값 (bodyMedium).' },
      { name: 'bold',       type: 'bool',    default: 'false', notes: 'true면 값 굵게 — 가격 / 합계 / 강조 숫자.' },
      { name: 'valueColor', type: 'Color?',  default: 'null', notes: '값 색상 오버라이드 — 부족(error)·강조(primary) 등 의미 색상.' },
    ],
    variants: ['default', 'bold', 'colored value'],
    states: ['default'],
    tokens: [
      { name: 'color-text-secondary', where: '라벨 색 (onSurfaceVariant).' },
      { name: 'color-text-primary',   where: '값 색 (기본).' },
      { name: 'color-primary',        where: '값 강조 색 — 합계 / 환불액 등.' },
      { name: 'color-error',          where: '값 경고 색 — 잔여 부족 / 마이너스.' },
      { name: 'spacing-xsmall',       where: '위아래 padding (4px) — 여러 row stack 시 답답하지 않은 간격.' },
    ],
    accessibility: [
      'label / value가 함께 한 row를 형성하므로 스크린리더는 자연스럽게 "label, value" 순으로 읽음.',
      '강조 색상은 시각만 — 의미가 있으면 부모 카드의 Semantics가 보강해야 함.',
    ],
    guidelines: [
      { kind: 'do',   text: '여러 row를 stack한 후 마지막 합계 row만 bold + 강조 색으로.', recipeKey: 'do-bold-for-total' },
      { kind: 'dont', text: '모든 row를 bold로 두면 강조의 의미가 사라짐.',                  recipeKey: 'dont-everything-bold' },
    ],
    placement: {
      where: [
        '`MinglitContentCard` 내부 — 정산 / 상세 정보 / 통계 row.',
        'bold + valueColor는 합계 / 강조 row 1개에만.',
      ],
      spacing: [
        { neighbor: '같은 카드 안 sibling row', gap: 'spacing-xsmall (4px)' },
        { neighbor: '합계 row 위 divider',      gap: 'thin divider', note: '합계 앞에 명시적 구분' },
      ],
    },
    dartUsage: `// 결제 / 환불 요약
MinglitKeyValueRow(label: '결제 금액', value: '35,000원'),
MinglitKeyValueRow(label: '수수료',    value: '-5,000원'),
const Divider(thickness: 0.5),
MinglitKeyValueRow(
  label: '환불 금액',
  value: '30,000원',
  bold: true,
  valueColor: theme.colorScheme.primary,
)`,
  },
  {
    name: 'MinglitContentLayout',
    category: 'Layouts',
    purpose: '상세 페이지의 섹션들을 통일된 간격으로 세로 나열하는 스캐폴드. 자체는 Column이라 어떤 스크롤 컨텍스트(SliverToBoxAdapter / SingleChildScrollView 등)에도 안전하게 사용. 스크롤은 부모가 관리.',
    props: [
      { name: 'sections',       type: 'List<Widget>', required: true, notes: '표시할 섹션 위젯 리스트 (보통 MinglitSection). 빈 리스트면 SizedBox.shrink.' },
      { name: 'sectionGap',     type: 'double?',      default: 'null', notes: '섹션 사이 간격. null이면 sectionGap(40).' },
      { name: 'topPadding',     type: 'double?',      default: 'null', notes: '첫 섹션 위 여백. null이면 large(24).' },
      { name: 'bottomPadding',  type: 'double?',      default: 'null', notes: '마지막 섹션 아래 여백. null이면 xlarge(32).' },
      { name: 'showDividers',   type: 'bool',         default: 'false', notes: 'true면 섹션 사이에 thin divider + halfGap을 좌우로 배치.' },
    ],
    variants: ['default (no dividers)', 'with dividers'],
    states: ['default'],
    tokens: [
      { name: 'spacing-section-gap', where: '섹션 사이 간격 기본값 (40px).' },
      { name: 'spacing-large',       where: '상단 padding 기본값 (24px).' },
      { name: 'spacing-xlarge',      where: '하단 padding 기본값 (32px).' },
      { name: 'color-divider',       where: 'showDividers=true일 때 thin 선 색.' },
    ],
    accessibility: [
      '의미 있는 콘텐츠 흐름은 sections의 각 MinglitSection이 자체 heading을 가짐 — 이 컴포넌트는 시각 컨테이너만.',
      '빈 sections 리스트일 때 SizedBox.shrink 반환 — 빈 컨테이너가 스크린리더에 노출되지 않음.',
    ],
    guidelines: [
      { kind: 'do',   text: '대부분 default(no dividers) — 여백만으로 섹션 분리가 충분함.',          recipeKey: 'do-no-dividers-default' },
      { kind: 'do',   text: '섹션 경계가 명확해야 할 때만 showDividers — 입력 / 확인 흐름 등.',       recipeKey: 'do-dividers-only-when-needed' },
    ],
    placement: {
      where: [
        '대부분의 화면 본문 — `Detail + Bottom CTA`, `Form + Bottom CTA`, `List + Filter chips` 스캐폴드의 body root.',
        'AppBar 아래 / Bottom CTA 위에 배치. 스크롤은 부모(SliverList / SingleChildScrollView)가 처리.',
      ],
      spacing: [
        { neighbor: '좌/우 화면 가장자리', gap: 'spacing-screen-edge (16px)', note: '각 섹션 자체 padding으로 처리 — 이 컴포넌트는 horizontal 0' },
        { neighbor: '내부 sections 사이',  gap: 'spacing-section-gap (40px)', note: 'sectionGap prop으로 조정' },
        { neighbor: '상단 (AppBar 아래)',  gap: 'spacing-large (24px)', note: 'topPadding 기본값' },
      ],
    },
    dartUsage: `// 일반 상세 페이지
MinglitContentLayout(
  sections: [
    MinglitSection(title: '이벤트 정보', child: ...),
    MinglitSection(title: '장소',       child: ...),
    MinglitSection(title: '후기',       child: ...),
  ],
)

// 디바이더로 강하게 분리하고 싶을 때
MinglitContentLayout(
  showDividers: true,
  sections: [...],
)`,
  },
  {
    name: 'MinglitHorizontalScrollGroup',
    category: 'Lists',
    purpose: '가로 스크롤 콘텐츠의 affordance를 자동으로 처리해주는 wrapper. 양 끝에 콘텐츠가 더 있는지를 페이드 + chevron으로 시각화 — 스크롤이 가능하다는 것을 사용자가 즉시 알 수 있다.',
    props: [
      { name: 'child', type: 'Widget', required: true, notes: '가로 스크롤 가능한 위젯 (ListView / SingleChildScrollView 등).' },
    ],
    variants: ['scroll start', 'scrolling middle', 'scroll end'],
    states: [
      'no fades (콘텐츠가 화면에 다 들어옴)',
      'right fade + chevron (시작 위치)',
      'both fades (스크롤 중)',
      'left fade only (끝 위치)',
    ],
    tokens: [
      { name: 'color-surface',        where: '페이드 그라디언트의 시작/끝 색 — scaffold 배경과 동일.' },
      { name: 'color-text-secondary', where: 'chevron 인디케이터 색 (40% opacity).' },
      { name: 'spacing-medium',       where: '페이드 너비 (16px).' },
    ],
    accessibility: [
      '페이드 / chevron은 시각적 힌트만 — IgnorePointer로 감싸 탭 동작에 영향 없음.',
      '스크린리더는 child의 ListView를 그대로 탐색 — affordance는 시각 보조 역할.',
    ],
    guidelines: [
      { kind: 'do',   text: '필터 칩 / 카테고리 칩처럼 가로로 펼쳐지는 row를 감쌀 때 사용.',           recipeKey: 'do-chips-row' },
      { kind: 'dont', text: '콘텐츠가 화면에 다 들어와 스크롤이 불필요한 경우 감싸지 말 것 — 페이드 / chevron이 안 뜨고 단순 wrap만 됨.', recipeKey: 'dont-wrap-non-scrollable' },
    ],
    placement: {
      where: [
        '섹션 안에서 sibling 카드들이 가로로 펼쳐질 때 — 추천 / 인기 / 최근 같은 카탈로그.',
        '한 화면 안에 2-3개 이상 스택하지 말 것 (수직 정보가 묻힘).',
      ],
      spacing: [
        { neighbor: '내부 카드 사이',          gap: 'spacing-card-gap (12px)', note: '내부 ListView가 처리' },
        { neighbor: '좌/우 첫·마지막 카드 패딩', gap: 'spacing-screen-edge (16px)', note: '스크롤 끝에서 화면 가장자리까지' },
      ],
    },
    dartUsage: `MinglitHorizontalScrollGroup(
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.screenEdge),
    itemCount: chips.length,
    separatorBuilder: (_, _) => const SizedBox(width: MinglitSpacing.cardGap),
    itemBuilder: (_, i) => MinglitChip(label: chips[i]),
  ),
)`,
  },
  {
    name: 'MinglitTimeline',
    category: 'Lists',
    purpose:
      '시간 순으로 진행된 이벤트를 vertical stepper로 보여주는 generic wrapper. 각 step은 좌측 dot + 그 아래로 이어지는 line + 우측 heading row(title + trailing slot) + 자유 children slot. 마지막 step은 line 없음. dot 색은 tone 분기 — success / progress / error / neutral / muted (semantic-neutral · 어떤 도메인 lifecycle도 매핑 가능). pulsing은 tone과 orthogonal한 박동 효과 (현재 진행 강조).',
    props: [
      { name: 'children', type: 'List<MinglitTimelineStep>', required: true, notes: '하나 이상의 step. 시간 순 (위→아래).' },
    ],
    variants: ['(step의 tone 별로 분기 — Tone 표 참조)'],
    states: [
      'success (dot color-success — 달성/통과)',
      'progress (dot color-primary — 현재 진행)',
      'error (dot + title color-error — 실패/거절)',
      'neutral (dot color-text-secondary — 종결 비강조)',
      'muted (outline only · color-text-secondary border — 미래/대기)',
      'pulsing=true (1.4s loop — tone과 orthogonal)',
    ],
    tokens: [
      { name: 'color-success',        where: 'success tone dot.' },
      { name: 'color-primary',        where: 'progress tone dot + title.' },
      { name: 'color-error',          where: 'error tone dot + title.' },
      { name: 'color-text-secondary', where: 'neutral / muted dot · trailing 메타 텍스트 색.' },
      { name: 'color-divider',        where: 'connecting line 2px 색.' },
      { name: 'spacing-xlarge',       where: 'step 간 vertical gap (32px).' },
      { name: 'spacing-small',        where: 'title ↔ trailing inline gap (8px).' },
    ],
    accessibility: [
      'step title은 의미를 한국어로 명확히 전달 — 색에 의존하지 않고 라벨로도 인지 가능.',
      'pulsing은 시각 단서 — screen reader는 title만 읽음.',
      '저성능 디바이스 / OS 모션 감소 설정 시 pulsing 제거하고 정적 dot으로 fallback 권장.',
    ],
    guidelines: [
      { kind: 'do',   text: '시간 순 진행을 보여줄 때 (신청/심사 review · 정산 진행 · 환불 진행 · 주문 추적 등). tone 매핑은 use case별로 자유.', recipeKey: 'application-review' },
      { kind: 'do',   text: '주문 추적 같이 미래 step도 보여주려면 muted tone 사용 — outline only로 "아직 도달 안 함" 시각화.', recipeKey: 'order-tracking' },
      { kind: 'do',   text: 'step 안 사유 / 메시지 / collapsible 같은 page-specific 컨텐츠는 children slot으로 주입. component 자체는 structure(dot/line/heading)만 책임.', recipeKey: 'rejection-flow' },
      { kind: 'dont', text: '단순 step 리스트(번호 매김 / 순서 안내)에 쓰지 말 것 — 시간 / 진행 metaphor가 있을 때만.' },
    ],
    placement: {
      where: [
        '카드 안의 메인 컨텐츠 — 카드 전체가 timeline 한 개일 때.',
        '사용 예: EventApplicationReviewPage 진행 단계 카드 (첫 use case).',
        '향후 use case: 정산 진행 / 환불 진행 / 주문/배송 추적 / 알림 history 등.',
      ],
      spacing: [
        { neighbor: '카드 padding 안쪽', gap: 'spacing-medium (16px)', note: 'dot column 32px 추가 padding-left' },
        { neighbor: 'step 간',           gap: 'spacing-xlarge (32px)' },
      ],
    },
    dartUsage: `// 신청 review use case (tone 매핑 — completed→success / active→progress+pulsing / failed→error / cancelled→neutral)
MinglitTimeline(
  children: [
    MinglitTimelineStep(
      tone: TimelineTone.success,
      title: '신청',
      trailing: Text('2026.04.10 19:42'),
    ),
    MinglitTimelineStep(
      tone: TimelineTone.success,
      title: '결제 완료',
      trailing: Text('2026.04.10 19:43 · 25,000원'),
    ),
    MinglitTimelineStep(
      tone: TimelineTone.progress,
      pulsing: true,
      title: '심사 진행 중',
      isLast: true,
      child: Text('이벤트 시작까지 자동 환불 안내'),
    ),
  ],
)`,
    usedIn: [
      'event_application_review_page',
    ],
  },

  // ---------- Confirmation / Success ----------
  {
    name: 'MinglitConfirmationPage',
    category: 'Feedback',
    purpose:
      '액션 완료 후 노출되는 풀 화면 success 페이지 (Toss "Confirmation Page" 패턴). 결제 / 신청 / 매칭 / 전송 등 사용자 액션이 성공적으로 끝났을 때 culmination 시각으로 노출. AppBar 미렌더 · centered icon + title + description + 바텀 CTA 단순 구조. 약 1.5초 sequence 애니메이션(circle scale-bounce + check stroke draw + 텍스트 stagger)으로 emotional 마무리.',
    props: [
      { name: 'title',       type: 'String',         required: true,  notes: '큰 bold 헤드라인 (22/700). 1-2줄 권장.' },
      { name: 'description', type: 'String?',        default: 'null', notes: '제목 아래 부가 설명 (14/secondary). 1-2줄 권장 · 긴 안내는 별도 페이지로.' },
      { name: 'icon',        type: 'IconData',       default: 'Icons.check', notes: '원 안에 흰색으로 노출 (52px · stroke-width 4). check / heart / send / info / warning 등.' },
      { name: 'tone',        type: 'ConfirmationTone', default: 'success', notes: 'icon circle bg 색 분기 — success(초록) · primary(보라) · info(파랑) · warning(주황).' },
      { name: 'ctaLabel',    type: 'String',         default: '"확인"', notes: '바텀 CTA 라벨. 다음 단계 forward action으로 사용 가능.' },
      { name: 'onPressed',   type: 'VoidCallback',   required: true,  notes: '기본 = pop. forward action일 경우 push.' },
      { name: 'autoDismiss', type: 'Duration?',      default: 'null', notes: '지정 시 일정 시간 후 자동 pop — 짧은 confirmation. CTA는 그대로 노출.' },
    ],
    variants: ['success (default)', 'primary', 'info', 'warning'],
    states: ['default', 'auto-dismissing (timer 진행 중)'],
    tokens: [
      { name: 'color-success',        where: 'success tone — icon circle bg 초록 #16a34a.' },
      { name: 'color-primary',        where: 'primary tone — icon circle bg 보라 + CTA bg.' },
      { name: 'color-info',           where: 'info tone — icon circle bg 파랑.' },
      { name: 'color-warning',        where: 'warning tone — icon circle bg 주황.' },
      { name: 'color-background',     where: 'scaffold + check icon stroke (흰색).' },
      { name: 'color-text-primary',   where: 'title.' },
      { name: 'color-text-secondary', where: 'description.' },
      { name: 'radius-button',        where: 'CTA 버튼 corner.' },
      { name: 'spacing-medium',       where: 'icon ↔ title ↔ description gap (16px).' },
      { name: 'spacing-large',        where: 'h-padding (24px) · description max-width 280.' },
    ],
    accessibility: [
      'AppBar 미렌더 — 시스템 back / 명시적 CTA로만 dismiss. iOS swipe-to-back은 그대로 동작.',
      'autoDismiss 사용 시 screen-reader에 "X초 후 자동으로 닫힙니다" announce 권장.',
      'icon은 시각 보조 — 의미는 title + description 텍스트로 명확히 전달.',
      '저성능 디바이스 / OS 모션 감소 설정 시 scale-bounce / draw animation 즉시 완료 상태로 fallback.',
    ],
    guidelines: [
      { kind: 'do',   text: '액션 성공 후 짧은 culmination 순간을 만들 때 — 사용자가 "내 액션이 완료됐다"를 명확히 인지하도록.', recipeKey: 'do-matching-submitted' },
      { kind: 'do',   text: 'tone은 액션 성격에 맞게 — 일반 성공은 success(초록), brand-distinctive 액션(좋아요 / 연결)은 primary(보라).', recipeKey: 'do-brand-action-primary' },
      { kind: 'do',   text: 'CTA는 "확인" 기본 · forward action(다음 단계로 가는 흐름)이면 명확한 라벨로 변경 ("이벤트 둘러보기" 등).' },
      { kind: 'dont', text: 'title / description 너무 길지 않게 — 각 1-2줄 max. 긴 안내는 별도 페이지로.', recipeKey: 'dont-too-many-lines' },
      { kind: 'dont', text: 'autoDismiss를 default로 X — 사용자가 culmination 순간을 충분히 즐기게.' },
    ],
    placement: {
      where: [
        'route push로 풀 화면 노출 — Confirm Dialog 또는 mutation 성공 후 자연스러운 transition.',
        '사용 예: EventMatchingScreen Submitted state · 결제 완료 / 신청 완료 / 회원가입 완료 등.',
        '향후 use case: 환불 신청 완료 · 후기 작성 완료 · 정산 신청 완료 등.',
      ],
      spacing: [
        { neighbor: '바텀 CTA',         gap: 'spacing-large (24px)', note: 'CTA 위쪽 divider 없음 — centered 레이아웃이라 노이즈가 됨' },
        { neighbor: 'icon ↔ title',    gap: 'spacing-medium (16px)' },
        { neighbor: 'title ↔ description', gap: 'spacing-medium (16px)' },
      ],
    },
    dartUsage: `// 매칭 좋아요 전송 완료 — success tone
MinglitConfirmationPage(
  title: '좋아요를 보냈어요',
  description: '매칭 결과는 매칭이 모두 종료된 후 알려드릴게요',
  ctaLabel: '확인',
  onPressed: () => Navigator.of(context).pop(),
)

// brand-distinctive 액션 — primary tone + heart icon
MinglitConfirmationPage(
  title: '요청을 보냈어요',
  description: '상대방이 수락하면 알려드릴게요',
  icon: Icons.favorite,
  tone: ConfirmationTone.primary,
  onPressed: () => Navigator.of(context).pop(),
)

// 회원가입 완료 — forward action CTA
MinglitConfirmationPage(
  title: '회원가입이 완료됐어요',
  description: '이제 이벤트를 둘러볼 수 있어요',
  ctaLabel: '이벤트 둘러보기',
  onPressed: () => homeCoordinator.goToHome(),
)`,
    usedIn: [
      'event_matching_screen',
    ],
  },

  // ---------- Settings ----------
  {
    name: 'MinglitSettingsGroup',
    category: 'Settings',
    purpose: '여러 SettingsTile을 카드로 묶어주는 wrapper. 옵션 헤더 라벨이 카드 위에 회색 대문자로 표시되어 그룹의 의미를 명시한다. 카드 모서리(radius 16) 안쪽으로 콘텐츠가 깔끔히 잘리고, 행 사이에는 0.5px 얇은 선이 leading icon 폭만큼 들여쓰기 되어 그어진다.',
    props: [
      { name: 'children', type: 'List<Widget>', required: true, notes: '카드 안에 들어갈 SettingsTile들.' },
      { name: 'header',   type: 'String?',      default: 'null', notes: '카드 위 헤더 라벨 — 자동 대문자 변환. null이면 헤더 없이 카드만.' },
    ],
    variants: ['with header', 'without header'],
    states: ['default'],
    tokens: [
      { name: 'color-background',        where: '카드 배경 (라이트모드 surfaceContainerLowest = 흰색).' },
      { name: 'color-text-secondary',    where: '헤더 라벨 색 (onSurfaceVariant).' },
      { name: 'color-divider',           where: '행 사이 0.5px 얇은 선 (outlineVariant).' },
      { name: 'radius-card',             where: '카드 모서리 (16px).' },
      { name: 'spacing-medium',          where: '카드 좌우 horizontal padding (16px).' },
      { name: 'spacing-small',           where: '헤더 ↔ 카드 간격 (8px).' },
      { name: 'spacing-xsmall',          where: '헤더 좌측 들여쓰기 (4px).' },
    ],
    accessibility: [
      '헤더는 텍스트만 — 의미 있는 그룹화는 부모 화면이 보강 (Semantics group).',
      '내부 SettingsTile들이 각자 button Semantics를 가짐 — 그룹은 시각 컨테이너.',
    ],
    guidelines: [
      { kind: 'do',   text: '같은 화면에 여러 그룹이 있으면 각각 헤더 라벨을 붙여 의미 분리 (계정 / 알림 / 정보 등).', recipeKey: 'do-multiple-groups-with-headers' },
      { kind: 'dont', text: '한 그룹에 모든 설정을 다 쑤셔넣지 말 것 — 토픽별로 나누는 것이 스캔성에 유리.',          recipeKey: 'dont-giant-single-group' },
    ],
    usedIn: ['user-MyPageRoute', 'user-AccountManagementRoute', 'user-NotificationSettingsRoute'],
    placement: {
      where: [
        '`Settings groups` 스캐폴드 — 한 화면에 여러 그룹을 세로로 스택.',
        '같은 토픽의 설정 tile들을 묶음. 헤더 라벨로 그룹 의미 명시.',
      ],
      spacing: [
        { neighbor: '다음 그룹',          gap: 'spacing-large (24px)' },
        { neighbor: '그룹 헤더 → 첫 tile', gap: 'spacing-small (8px)' },
        { neighbor: '내부 tiles 사이',     gap: '0', note: '0.5px divider만 leading 폭(52)만큼 들여쓰기 되어 그어짐' },
      ],
    },
    dartUsage: `MinglitSettingsGroup(
  header: '계정',
  children: [
    MinglitSettingsTile(
      leading: Icons.email_outlined,
      title: '이메일',
      subtitle: 'user@example.com',
      trailing: SettingsTileTrailing.navigation,
      onTap: () => coordinator.openEmail(),
    ),
    MinglitSettingsTile(
      leading: Icons.lock_outline,
      title: '비밀번호',
      onTap: () => coordinator.openPassword(),
    ),
    MinglitSettingsTile(
      leading: Icons.logout,
      title: '로그아웃',
      trailing: SettingsTileTrailing.none,
      destructive: true,
      onTap: () => signOut(),
    ),
  ],
)`,
  },
  {
    name: 'MinglitSettingsTile',
    category: 'Settings',
    purpose: '설정 / 마이페이지 화면 전용 compact 행. 1줄(title만)일 때는 minHeight 48 고정, 2줄(title + subtitle)일 때는 자연스럽게 자라며 위아래 padding 12 유지. 우측 trailing은 navigation chevron / toggle / value text / none 중 선택.',
    props: [
      { name: 'title',         type: 'String',                required: true, notes: '주 라벨 (bodyMedium).' },
      { name: 'leading',       type: 'IconData?',             default: 'null', notes: '좌측 20px 아이콘 (회색 onSurfaceVariant). 없으면 좌측 비움.' },
      { name: 'subtitle',      type: 'String?',               default: 'null', notes: '현재 값 한 줄 (예: "한국어", "켜짐"). 들어가면 행이 ~58px로 자라남.' },
      { name: 'trailing',      type: 'SettingsTileTrailing',  default: 'navigation', notes: 'navigation(chevron) · toggle(Switch) · value(text) · none.' },
      { name: 'trailingValue', type: 'String?',               default: 'null', notes: 'trailing=value일 때 우측에 표시할 텍스트.' },
      { name: 'toggleValue',   type: 'bool',                  default: 'false', notes: 'trailing=toggle일 때 스위치 상태.' },
      { name: 'onToggleChanged', type: 'ValueChanged<bool>?', default: 'null', notes: 'trailing=toggle일 때 토글 변경 콜백.' },
      { name: 'onTap',         type: 'VoidCallback?',         default: 'null', notes: '행 탭 콜백. trailing=toggle일 때는 동작 안 함 (토글만 반응).' },
      { name: 'destructive',   type: 'bool',                  default: 'false', notes: 'true면 title + leading icon이 error 색(빨강) — 로그아웃 / 탈퇴.' },
      { name: 'enabled',       type: 'bool',                  default: 'true', notes: 'false면 흐려지고 탭 차단.' },
    ],
    variants: ['navigation', 'toggle', 'value', 'none'],
    states: ['default', 'with subtitle', 'destructive', 'disabled'],
    tokens: [
      { name: 'color-text-primary',    where: 'title 색 (기본).' },
      { name: 'color-text-secondary',  where: 'leading icon · subtitle · value text · chevron 색.' },
      { name: 'color-error',           where: 'destructive 시 title + leading icon 색.' },
      { name: 'color-primary',         where: 'toggle ON 시 트랙 색.' },
      { name: 'color-divider',         where: 'toggle OFF 시 트랙 색.' },
      { name: 'spacing-medium',        where: '좌우 padding (16px) · leading↔title 갭.' },
      { name: 'spacing-sm',            where: '위아래 padding (12px) — 고정.' },
    ],
    accessibility: [
      'onTap이 있으면 InkWell button Semantics. trailing=toggle은 행 탭이 아니라 토글만 반응.',
      'destructive 시각 강조는 색상만 — 의미 있는 destructive 액션은 confirm dialog와 함께.',
      'enabled=false는 InkWell 차단 + 텍스트 / 아이콘 muted opacity.',
    ],
    guidelines: [
      { kind: 'do',   text: '다음 화면으로 이동하는 행은 navigation — 우측에 chevron으로 진입 신호.',     recipeKey: 'do-navigation-row' },
      { kind: 'do',   text: '온/오프 즉시 반영은 toggle — 행 탭은 비활성, 토글만 반응.',                  recipeKey: 'do-toggle-row' },
      { kind: 'do',   text: '로그아웃 / 탈퇴 같은 종결 액션은 destructive + 그룹의 마지막에.',            recipeKey: 'do-destructive-last' },
      { kind: 'dont', text: '한 그룹에 navigation / toggle / value를 무작위로 섞어서 시선이 분산되게 하지 말 것.', recipeKey: 'dont-mixed-trailing' },
    ],
    usedIn: ['user-MyPageRoute', 'user-AccountManagementRoute', 'user-NotificationSettingsRoute', 'user-PrivacyRoute'],
    placement: {
      where: [
        '`MinglitSettingsGroup` 내부 직계 자식. 단독 사용 안 함.',
        'destructive=true는 그룹의 마지막 tile에 — 계정 삭제 / 로그아웃 같은 종결 액션.',
      ],
      spacing: [
        { neighbor: '같은 그룹 sibling tile', gap: '0', note: '연속 row는 붙고 group의 0.5px divider가 사이를 그음' },
        { neighbor: '내부 vertical padding',  gap: 'spacing-sm (12px)', note: '고정 — 1줄 / 2줄 모두 동일' },
        { neighbor: '내부 horizontal padding', gap: 'spacing-medium (16px)' },
      ],
    },
    dartUsage: `// 진입 행
MinglitSettingsTile(
  leading: Icons.language,
  title: '언어',
  subtitle: '한국어',
  trailing: SettingsTileTrailing.navigation,
  onTap: () => coordinator.openLanguage(),
)

// 토글 행
MinglitSettingsTile(
  leading: Icons.notifications_outlined,
  title: '알림 받기',
  trailing: SettingsTileTrailing.toggle,
  toggleValue: enabled,
  onToggleChanged: (v) => controller.setEnabled(v),
)

// destructive — 그룹 마지막
MinglitSettingsTile(
  leading: Icons.logout,
  title: '로그아웃',
  trailing: SettingsTileTrailing.none,
  destructive: true,
  onTap: () => signOut(),
)`,
  },

  // ---------- Loading ----------
  {
    name: 'LoadingIndicator',
    category: 'Loading',
    purpose: 'App-wide loading spinners. MinglitCircularProgressIndicator (centered spinning ring) and MinglitLinearProgressIndicator (horizontal track bar) — the two mds loading primitives used by AsyncValueWidget and Button.',
    props: [
      { name: 'size',            type: 'double',  default: '24',   notes: 'MinglitCircularProgressIndicator: width × height in px.' },
      { name: 'strokeWidth',     type: 'double',  default: '2',    notes: 'Ring stroke thickness.' },
      { name: 'color',           type: 'Color?',  default: 'null', notes: 'Arc / bar color override. null → theme primary (colorScheme.primary).' },
      { name: 'value',           type: 'double?', default: 'null', notes: 'MinglitLinearProgressIndicator: 0.0–1.0. null = indeterminate.' },
      { name: 'backgroundColor', type: 'Color?',  default: 'null', notes: 'Track fill color (linear). null → theme surfaceVariant.' },
    ],
    variants: ['circular-sm (size:16)', 'circular-md (size:24, default)', 'circular-lg (size:48)', 'linear-indeterminate', 'linear-determinate', 'linear-success'],
    states: ['spinning (default)', 'value 0–1 (linear only)', 'color-overridden'],
    tokens: [
      { name: 'color-primary', where: 'arc / bar default fill' },
      { name: 'color-divider', where: 'circular track bg / linear track bg' },
      { name: 'color-success', where: 'progress complete color override (upload, step done)' },
    ],
    accessibility: [
      'CircularProgressIndicator: Semantics(label: "로딩 중") wraps the SizedBox — screen readers announce when spinner appears.',
      'LinearProgressIndicator: role="progressbar", aria-valuenow exposed. Pair with an offscreen status message for context.',
      'MinglitButton.isLoading에 사용되는 spinner는 버튼의 aria-label이 상태 변화를 전달한다.',
    ],
    guidelines: [
      { kind: 'do',   text: '카드 목록처럼 모양이 알려진 영역은 MinglitSkeleton 사용 — 레이아웃 이동 방지.',          recipeKey: 'do-skeleton-over-spinner' },
      { kind: 'dont', text: '200ms 이하 fetch에서 스피너를 즉시 표시하지 말 것 — 순간 깜빡임이 더 나쁜 UX.',          recipeKey: 'dont-flash-spinner' },
      { kind: 'do',   text: '비동기 fetch 중 MinglitAsyncValueWidget의 loading 슬롯에 스피너 또는 스켈레톤.',          recipeKey: 'do-async-loading' },
      { kind: 'dont', text: 'lg(48px) 스피너를 버튼/칩 인라인에 쓰지 말 것 — 크기 불균형.',                           recipeKey: 'dont-size-overuse' },
      { kind: 'do',   text: '진행률을 알 수 있는 경우(파일 업로드, 단계 이동)는 LinearProgressIndicator.value를 활용.', recipeKey: 'do-linear-determinate' },
    ],
    dartUsage: `// 원형 스피너 — 기본
MinglitCircularProgressIndicator()

// 원형 스피너 — 커스텀 사이즈 + 색상
MinglitCircularProgressIndicator(size: 48, strokeWidth: 4, color: MinglitColors.success)

// 선형 진행률 바 — 미결정
MinglitLinearProgressIndicator()

// 선형 진행률 바 — 30%
MinglitLinearProgressIndicator(value: 0.3)

// 선형 진행률 바 — 100% (완료 표시)
MinglitLinearProgressIndicator(value: 1.0, color: MinglitColors.success)`,
    placement: {
      where: [
        '`MinglitContentLayout` 중앙 — 페이지 전체 데이터 fetch 로딩.',
        '`MinglitAsyncValueWidget` loading 슬롯 — 기본값으로 자동 삽입.',
        '`MinglitButton` isLoading=true 내부 — 버튼 인라인 size:16 스피너.',
        '페이지 상단 전역 — route transition 진행률 (linear, indeterminate).',
      ],
      spacing: [
        { neighbor: 'MinglitContentLayout 내 상하 콘텐츠', gap: 'spacing-large (24px)', note: '스피너는 항상 Center()로 감싸 수직 중앙 배치' },
      ],
      compositions: [
        { label: 'Circular inside AsyncValueWidget', description: 'loading: () => MinglitCircularProgressIndicator()가 기본값.', recipeKey: 'do-async-loading' },
        { label: 'Linear upload progress',           description: 'value: uploadProgress로 실시간 진행률 노출.',                  recipeKey: 'do-linear-determinate' },
      ],
    },
    usedIn: ['MinglitAsyncValueWidget', 'MinglitButton'],
  },
  {
    name: 'MinglitSkeleton',
    category: 'Loading',
    purpose: '로딩 중 콘텐츠 자리에 펄스 애니메이션 placeholder. 데이터 fetch 중 레이아웃 모양을 유지해 카드 / 텍스트 라인 / 아바타 형태로 조합 가능.',
    props: [
      { name: 'width',        type: 'double?',                  default: 'null', notes: '고정 너비. null = SizedBox(width: double.infinity) — 부모 채움.' },
      { name: 'height',       type: 'double?',                  default: 'null', notes: '고정 높이. 명시적으로 모든 스켈레톤에 설정해야 함.' },
      { name: 'borderRadius', type: 'BorderRadiusGeometry?',    default: 'null', notes: 'null → radius-small (8px). 원형은 BorderRadius.circular(height/2).' },
    ],
    variants: ['text-line (h14–20)', 'circle/avatar (borderRadius: height/2)', 'image-block (h80–180, radius-card)', 'card (composed)'],
    states: ['shimmer-active (always)', 'replaced (data loaded — 위젯 제거)'],
    tokens: [
      { name: 'color-surface',           where: 'shimmer 시작 색 (light mode)' },
      { name: 'color-text-primary',      where: 'shimmer 끝 색 @ opacity (light mode)' },
      { name: 'color-dark-surface',      where: 'shimmer 시작 (dark mode)' },
      { name: 'color-dark-text-primary', where: 'shimmer 끝 @ opacity (dark mode)' },
      { name: 'radius-small',            where: '기본 borderRadius (8px)' },
      { name: 'radius-card',             where: 'image-block / card 스켈레톤 radius (16px)' },
    ],
    accessibility: [
      'aria-hidden="true" — 스켈레톤 블록 자체는 스크린 리더에서 숨김.',
      '스켈레톤 표시 중 상위에 role="status" + aria-live="polite" + aria-label="이벤트 목록 로딩 중" 권장.',
      '로드 완료 후 실제 콘텐츠가 DOM에 삽입되면 스크린 리더가 자동으로 새 콘텐츠를 읽는다.',
    ],
    guidelines: [
      { kind: 'do',   text: '카드 목록처럼 모양이 알려진 영역에는 스켈레톤 사용 — 레이아웃 이동 없이 자연스러운 전환.', recipeKey: 'do-skeleton-for-known-shape' },
      { kind: 'dont', text: '카드 영역에 일반 스피너 대신 스켈레톤을 — 스피너는 모양 정보가 없어 레이아웃이 흔들린다.',  recipeKey: 'dont-generic-spinner-for-card' },
      { kind: 'do',   text: '스켈레톤 → 실제 콘텐츠 전환 시 opacity 0→1 fade-in 0.2s 적용 — 갑작스러운 교체 방지.',     recipeKey: 'do-fade-in-transition' },
      { kind: 'dont', text: '텍스트 스켈레톤 너비를 모두 100%로 맞추지 말 것 — 실제 텍스트는 각 줄 길이가 다양하다.',     recipeKey: 'dont-mix-widths' },
      { kind: 'do',   text: '텍스트 라인 스켈레톤은 너비를 90%, 70%, 55%처럼 점진적으로 줄여 자연스럽게.',               recipeKey: 'do-varied-widths' },
    ],
    dartUsage: `// 텍스트 라인 스켈레톤
MinglitSkeleton(width: 200, height: 16)
MinglitSkeleton(width: 140, height: 16)

// 원형 아바타 스켈레톤
MinglitSkeleton(width: 40, height: 40, borderRadius: BorderRadius.circular(20))

// 이미지 블록 스켈레톤
MinglitSkeleton(width: double.infinity, height: 120, borderRadius: BorderRadius.circular(MinglitRadius.card))

// 이벤트 카드 스켈레톤 (조합)
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    MinglitSkeleton(width: double.infinity, height: 120, borderRadius: BorderRadius.circular(MinglitRadius.card)),
    SizedBox(height: MinglitSpacing.small),
    MinglitSkeleton(width: 180, height: 16),
    SizedBox(height: MinglitSpacing.xsmall),
    MinglitSkeleton(width: 120, height: 14),
  ],
)`,
    placement: {
      where: [
        '`List + Filter chips` 스캐폴드 — 카드 리스트 fetch 중 MinglitContentCard 자리 대체.',
        '`Detail + Bottom CTA` 스캐폴드 — MinglitSection 내부 콘텐츠 로딩 중 플레이스홀더.',
        'MinglitAsyncValueWidget loading: 슬롯 — 커스텀 loading 콜백에 스켈레톤 주입.',
      ],
      spacing: [
        { neighbor: 'sibling 스켈레톤 블록', gap: 'spacing-xsmall (4px)',    note: '텍스트 라인 스택' },
        { neighbor: 'card 사이',             gap: 'spacing-card-gap (12px)', note: '카드 스켈레톤 목록' },
      ],
      compositions: [
        { label: 'Card list skeleton in AsyncValueWidget', description: 'loading: () => 카드 스켈레톤 2–3개 Column으로 채워 레이아웃 확보.', recipeKey: 'do-skeleton-for-known-shape' },
      ],
    },
    usedIn: ['MinglitAsyncValueWidget'],
  },
  {
    name: 'MinglitAsyncValueWidget',
    category: 'Loading',
    purpose: '표준화된 Riverpod AsyncValue<T> 렌더러. data / loading / error 상태를 mds 기본값으로 dispatch. 모든 화면에서 value.when() 보일러플레이트를 제거한다.',
    props: [
      { name: 'value',            type: 'AsyncValue<T>',                        required: true,  notes: 'Riverpod provider의 ref.watch() 결과. ConsumerWidget 안에서만 사용.' },
      { name: 'data',             type: 'Widget Function(T)',                   required: true,  notes: '데이터가 있을 때 빌드하는 위젯 빌더.' },
      { name: 'loading',          type: 'Widget Function()?',                   default: 'null', notes: 'null → MinglitCircularProgressIndicator(). 스켈레톤 커스텀 주입 가능.' },
      { name: 'error',            type: 'Widget Function(Object, StackTrace)?', default: 'null', notes: 'null → _DefaultErrorView. MinglitErrorState + onRetry 조합 권장.' },
      { name: 'showErrorDetails', type: 'bool',                                 default: 'false', notes: 'true 시 error.toString()을 기본 에러 뷰에 노출. 개발/QA 전용.' },
    ],
    variants: ['default (circular loading + default error)', 'skeleton loading (custom loading slot)', 'error + retry (custom error slot)'],
    states: ['loading', 'data', 'error'],
    tokens: [
      { name: 'color-primary',        where: 'default loading spinner arc' },
      { name: 'color-error',          where: 'default error view icon + text' },
      { name: 'spacing-large',        where: 'default error view internal padding (24px)' },
      { name: 'color-text-secondary', where: 'default error detail text (showErrorDetails=true)' },
    ],
    accessibility: [
      'loading 상태: MinglitCircularProgressIndicator의 Semantics(label: "로딩 중") 자동 적용.',
      'error 상태: role="alert" + aria-live="assertive"를 커스텀 error 위젯에 추가 권장.',
      'data 상태: 실제 콘텐츠 위젯이 a11y 책임을 이어받는다.',
      'ConsumerWidget 바깥에서 사용 시 ProviderScope가 없으면 런타임 에러 — 반드시 Riverpod tree 안에서만 사용.',
    ],
    guidelines: [
      { kind: 'do',   text: '카드 목록 fetch엔 loading: () => EventListSkeleton()으로 스켈레톤 주입 — 레이아웃 이동 방지.', recipeKey: 'do-skeleton-loading' },
      { kind: 'dont', text: 'error 슬롯을 null로 두지 말 것 — 기본 뷰는 retry 없음. 항상 onRetry 콜백을 제공.',             recipeKey: 'dont-null-for-error' },
      { kind: 'do',   text: 'error 슬롯에 MinglitErrorState + onRetry: () => ref.invalidate(provider) 패턴 사용.',           recipeKey: 'do-retry-on-error' },
      { kind: 'dont', text: 'showErrorDetails=true를 프로덕션 빌드에 포함하지 말 것 — 내부 스택 트레이스 노출.',              recipeKey: 'dont-show-raw-error' },
      { kind: 'do',   text: 'retry 시 ref.invalidate(provider)로 provider를 재실행 — ref.refresh는 즉시 새 값 필요 시만.', recipeKey: 'do-invalidate-on-retry' },
    ],
    dartUsage: `// 기본 — 원형 스피너 + 기본 에러 뷰
MinglitAsyncValueWidget<List<Event>>(
  value: ref.watch(eventsProvider),
  data: (events) => EventListView(events: events),
)

// 커스텀 로딩 — 스켈레톤
MinglitAsyncValueWidget<List<Event>>(
  value: ref.watch(eventsProvider),
  loading: () => const EventListSkeleton(),
  data: (events) => EventListView(events: events),
)

// 커스텀 에러 — MinglitErrorState + retry
MinglitAsyncValueWidget<UserProfile>(
  value: ref.watch(profileProvider),
  error: (err, _) => MinglitErrorState(
    title: '프로필 정보를 불러오지 못했습니다',
    onRetry: () => ref.invalidate(profileProvider),
  ),
  data: (profile) => ProfileView(profile: profile),
)`,
    placement: {
      where: [
        '`Detail + Bottom CTA` 스캐폴드 body — 이벤트 상세 / 프로필 상세 페이지 전체 래핑.',
        '`List + Filter chips` 스캐폴드 scrollable list 영역 — 이벤트 목록 fetch.',
        'MinglitSection 내부 콘텐츠 — 섹션 단위 데이터 로딩.',
        '어느 scaffold body에도 사용 가능 — AsyncValue를 리턴하는 provider가 있는 곳 어디든.',
      ],
      spacing: [
        { neighbor: 'loading/error 기본 뷰 내 패딩', gap: 'spacing-large (24px)', note: '_DefaultErrorView 내부 Center + Padding' },
      ],
      compositions: [
        { label: 'With EventListSkeleton', description: '카드 목록 로딩 중 레이아웃 유지. loading 슬롯에 스켈레톤 조합.', recipeKey: 'do-skeleton-loading' },
        { label: 'With MinglitErrorState', description: 'error 슬롯에 MinglitErrorState + ref.invalidate 패턴.',         recipeKey: 'do-retry-on-error' },
      ],
    },
    usedIn: ['eventsProvider', 'profileProvider', 'partiesProvider'],
  },

  // ---------- Overlay ----------
  {
    name: 'MinglitAlert',
    category: 'Overlay',
    purpose: '결정 요구 또는 단순 알림을 위한 모달 다이얼로그. showAlert/showConfirm static API 제공.',
    props: [
      { name: 'title',   type: 'String',           required: true,  notes: '다이얼로그 타이틀. bodyLarge(18) bold 스타일.' },
      { name: 'content', type: 'String?',          default: 'null', notes: '선택적 본문 텍스트. bodyMedium(16).' },
      { name: 'actions', type: 'List<Widget>?',    default: 'null', notes: '액션 버튼 목록. showConfirm 사용 시 자동 생성.' },
      { name: 'type',    type: 'MinglitAlertType', default: 'MinglitAlertType.info', notes: 'info (기본) | destructive — destructive 시 확인 버튼만 빨강 (bold). 아이콘 / 타이틀은 일반 색 유지 (industry 표준 — iOS / Linear / GitHub 등).' },
    ],
    variants: ['alert (info)', 'confirm (info)', 'confirm (destructive)'],
    states: ['visible', 'confirmed', 'cancelled'],
    tokens: [
      { name: 'color-scrim',        where: '배경 스크림 오버레이 rgba(0,0,0,0.5)' },
      { name: 'radius-dialog',      where: '다이얼로그 카드 코너 반경 28px (M3 default)' },
      { name: 'color-error',        where: 'destructive 타입 — 확인 버튼만 빨강 (아이콘 / 타이틀은 일반 색 유지). 빨강 한 곳 집중으로 시선 유도.' },
      { name: 'color-primary',      where: 'info 타입 — 확인 버튼 색상' },
      { name: 'spacing-medium',     where: 'insetPadding horizontal (16px, M3 mobile 권장) · title↔content 갭' },
      { name: 'spacing-large',      where: 'insetPadding vertical · 내부 padding 좌우상하 · content↔actions 갭 (24px, M3 default)' },
      { name: 'spacing-small',      where: '액션 버튼 사이 간격 (8px)' },
    ],
    accessibility: [
      'showDialog wraps with semantic barrier — aria-modal="true" equivalent',
      'Focus trap: Flutter showDialog locks focus inside the dialog',
      'Escape / back-gesture closes (Navigator.pop)',
      'destructive 버튼 foregroundColor = colorScheme.error — 색이 의미를 전달하지만 텍스트로도 명시 (삭제/탈퇴)',
      'confirmText / cancelText 커스터마이즈 가능 — 스크린 리더 라벨로 직접 사용됨',
    ],
    guidelines: [
      { kind: 'do',   text: 'destructive 액션 전에 반드시 showConfirm(isDestructive: true)를 거칠 것.',  recipeKey: 'do-confirm-destructive' },
      { kind: 'dont', text: 'destructive 버튼 탭 즉시 실행 금지 — 실수 클릭 복구 불가.',                 recipeKey: 'dont-skip-confirm' },
      { kind: 'do',   text: 'Alert content는 한두 줄 이내 — 길면 MinglitDialog로 전환.',                recipeKey: 'do-alert-for-info' },
      { kind: 'dont', text: 'Alert에 장문 본문/약관/스크롤 컨텐츠 넣지 말 것 — MinglitDialog 사용.',     recipeKey: 'dont-long-content-alert' },
      { kind: 'dont', text: '모달 위에 다른 모달 스택 금지 — 한 번에 하나만 표시할 것.' },
      { kind: 'do',   text: 'showConfirm은 await로 결과를 기다린 후 액션 수행 — result == true 확인.' },
    ],
    dartUsage: `// Alert — 단순 알림
await MinglitAlert.show(
  context: context,
  title: '알림',
  content: '이미 최신 버전입니다.',
);

// Confirm — 되돌아가기 확인
final ok = await MinglitAlert.showConfirm(
  context: context,
  title: '정말 나가시겠어요?',
  content: '저장하지 않은 내용이 사라집니다.',
);
if (ok) Navigator.pop(context);

// Confirm (destructive) — 삭제
final confirmed = await MinglitAlert.showConfirm(
  context: context,
  title: '정말 삭제하시겠어요?',
  content: '삭제된 파티는 복구할 수 없습니다.',
  confirmText: '삭제',
  isDestructive: true,
);
if (confirmed) await deleteParty();`,
    placement: {
      where: [
        '`Centered dialog` 스캐폴드 자체 — MinglitAlert가 스크림 위에 떠 있는 카드.',
        '어느 화면에서든 showDialog 호출로 표시. 특정 scaffold 종속 없음.',
      ],
      spacing: [
        { neighbor: '스크림(배경)',          gap: 'color-scrim overlay',           note: '화면 전체를 덮고 그 위에 카드가 중앙 정렬' },
        { neighbor: '외부 여백(insetPadding)', gap: 'medium 16 H · large 24 V',    note: 'M3 mobile 권장 — 화면 가장자리에서 카드까지 거리. dialog 폭 = 화면 폭 − 32' },
        { neighbor: '카드 내부 타이틀 패딩', gap: 'large 24 / medium 16',          note: 'fromLTRB(24, 24, 24, 16) — 마지막 16은 title↔content 갭 (M3)' },
        { neighbor: '카드 내부 콘텐츠 패딩', gap: 'large 24 / large 24',           note: 'fromLTRB(24, 0, 24, 24) — 마지막 24는 content↔actions 갭 (M3)' },
        { neighbor: '카드 내부 액션 패딩',   gap: 'sm 12 L · large 24 R/B',         note: 'fromLTRB(12, 0, 24, 24)' },
        { neighbor: '액션 버튼 사이',        gap: 'spacing-sm (12px)', note: 'M3 minimum 8보다 살짝 분리 — 클릭미스 방지' },
      ],
      compositions: [
        { label: 'Destructive + MinglitButton pair', description: 'MinglitButton.destructive 탭 → showConfirm(isDestructive: true) → 확인 시 삭제 실행.', recipeKey: 'do-confirm-destructive' },
        { label: 'Logout confirm',                   description: 'MinglitSettingsTile(destructive: true) → showConfirm → 로그아웃.' },
      ],
    },
    usedIn: ['user-MyPageRoute'],
  },
  {
    name: 'MinglitDialog',
    category: 'Overlay',
    purpose: '임의 Widget 컨텐츠를 담는 커스텀 모달 다이얼로그. MinglitAlert보다 표현 자유도가 높음.',
    props: [
      { name: 'title',   type: 'String',          required: true,  notes: '다이얼로그 타이틀 (bodyLarge 18 / bold).' },
      { name: 'content', type: 'Widget',          required: true,  notes: '메인 컨텐츠 위젯 — 입력 폼, 선택 리스트, 스테퍼 등 자유 구성.' },
      { name: 'actions', type: 'List<Widget>?',   default: 'null', notes: '하단 액션 버튼 목록. null이면 액션 row 미표시.' },
    ],
    variants: ['custom-content (default)'],
    states: ['visible', 'confirmed', 'dismissed'],
    tokens: [
      { name: 'color-scrim',    where: '배경 스크림 오버레이 rgba(0,0,0,0.5)' },
      { name: 'radius-dialog',  where: '다이얼로그 카드 코너 반경 28px (M3 default)' },
      { name: 'color-primary',  where: '확인 버튼 foreground (호출자가 MinglitButton 사용 시)' },
      { name: 'spacing-medium', where: 'insetPadding horizontal (16px, M3 mobile 권장) · title↔content 갭' },
      { name: 'spacing-large',  where: 'insetPadding vertical · 내부 padding 좌우상하 · content↔actions 갭 (24px, M3 default)' },
      { name: 'spacing-small',  where: '액션 row 버튼 간격 (8px)' },
    ],
    accessibility: [
      'Flutter showDialog — focus trap + back-gesture dismiss',
      'content Widget에 포함된 TextField 등은 자동 포커스 가능 — autofocus 속성 활용',
      '액션 버튼은 명확한 라벨 필수 — "확인" 보다 "신고하기", "저장" 같이 행동 명사로',
      'Dialog 닫힘 후 트리거 요소로 포커스 복귀 (Flutter 기본 동작)',
    ],
    guidelines: [
      { kind: 'do',   text: 'content에 Widget 트리를 자유롭게 — 입력 필드, 선택 리스트, 스테퍼 모두 가능.',  recipeKey: 'do-custom-content' },
      { kind: 'dont', text: '스크롤이 필요한 장문 폼은 Dialog 금지 — 전용 화면(Route)으로 분리.',          recipeKey: 'dont-long-form-in-dialog' },
      { kind: 'dont', text: '모달 위에 다른 모달 스택 금지.' },
      { kind: 'do',   text: '액션이 없는 Dialog(actions=null)는 반드시 명시적 닫기 방법 제공 (X 버튼 등).' },
      { kind: 'do',   text: 'MinglitAlert로 충분한 경우 Dialog 쓰지 말 것 — content가 String이면 Alert.' },
    ],
    dartUsage: `// 커스텀 컨텐츠 Dialog
await MinglitDialog.show(
  context: context,
  title: '참여 인원 설정',
  content: NumberStepperInput(
    value: count,
    min: 1,
    max: 20,
    onChanged: (v) => setState(() => count = v),
  ),
  actions: [
    TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
    TextButton(onPressed: () => Navigator.pop(context, count), child: const Text('확인')),
  ],
);

// 신고 사유 선택
final reason = await MinglitDialog.show<String>(
  context: context,
  title: '신고하기',
  content: ReportReasonList(onSelected: (r) => Navigator.pop(context, r)),
);`,
    placement: {
      where: [
        '`Centered dialog` 스캐폴드 자체 — MinglitDialog가 스크림 위에 떠 있는 카드.',
        '어느 화면에서든 MinglitDialog.show() 호출로 표시. scaffold 종속 없음.',
      ],
      spacing: [
        { neighbor: '스크림(배경)',           gap: 'color-scrim overlay' },
        { neighbor: '외부 여백(insetPadding)', gap: 'medium 16 H · large 24 V', note: 'M3 mobile 권장' },
        { neighbor: '카드 내부 타이틀 패딩',  gap: 'large 24 / medium 16',      note: 'fromLTRB(24, 24, 24, 16) — title↔content 갭 16 (M3)' },
        { neighbor: '카드 내부 콘텐츠 패딩',  gap: 'large 24 / large 24',       note: 'fromLTRB(24, 0, 24, 24) — content↔actions 갭 24 (M3)' },
        { neighbor: '카드 내부 액션 패딩',    gap: 'sm 12 L · large 24 R/B',     note: 'fromLTRB(12, 0, 24, 24)' },
        { neighbor: '액션 버튼 사이',         gap: 'spacing-sm (12px)', note: 'M3 minimum 8보다 살짝 분리 — 클릭미스 방지' },
      ],
      compositions: [
        { label: 'NumberStepperInput embed',      description: '인원/수량 입력을 모달로 처리.' },
        { label: 'MinglitImageSourceSheet embed', description: '이미지 소스 선택 — 카메라/앨범.', recipeKey: 'do-custom-content' },
        { label: 'Report reason list',            description: '신고 사유 선택 리스트.' },
      ],
    },
  },
  {
    name: 'MinglitBottomSheet',
    category: 'Overlay',
    purpose: '하단에서 올라오는 모달 시트. 드래그 핸들 + 선택적 타이틀 + 자유 컨텐츠 child.',
    props: [
      { name: 'child',              type: 'Widget',          required: true,  notes: '시트 본문 — MinglitListTile 목록, 이미지 소스 피커, 정렬 옵션 등.' },
      { name: 'title',              type: 'String?',         default: 'null', notes: '핸들 아래 표시되는 타이틀. titleLarge 스타일.' },
      { name: 'showHandle',         type: 'bool',            default: 'true', notes: '상단 드래그 핸들 표시 여부. 핸들 숨기면 닫기 수단 별도 제공 필요.' },
      { name: 'padding',            type: 'EdgeInsets?',     default: 'null', notes: '커스텀 콘텐츠 패딩. 기본: H=screenEdge(16), B=medium(16).' },
      { name: 'isScrollControlled', type: 'bool',            default: 'false', notes: 'showMinglitBottomSheet 파라미터. true 시 화면 높이까지 확장 가능.' },
      { name: 'constraints',        type: 'BoxConstraints?', default: 'null', notes: 'showMinglitBottomSheet 파라미터. 시트 최대/최솟값 제어.' },
    ],
    variants: ['default (isDismissible=true)', 'isScrollControlled=true (tall sheet)', 'showHandle=false (no drag handle)'],
    states: ['visible', 'dragging', 'dismissed'],
    tokens: [
      { name: 'color-scrim',          where: '시트 위 배경 스크림 rgba(0,0,0,0.5)' },
      { name: 'radius-card',          where: '상단 두 코너 반경 16px (하단은 0)' },
      { name: 'color-divider',        where: '드래그 핸들 색상 (with muted opacity)' },
      { name: 'spacing-small',        where: '핸들 상하 여백 8px' },
      { name: 'spacing-screen-edge',  where: '콘텐츠 좌우 패딩 16px' },
      { name: 'spacing-medium',       where: '콘텐츠 하단 패딩 16px · 타이틀 → 콘텐츠 간격 16px (MinglitDialog와 통일)' },
    ],
    accessibility: [
      'showModalBottomSheet — barrier dismissible by tapping scrim (default isDismissible=true)',
      'Drag handle는 시각적 affordance — 스크린 리더용 Semantics label "닫기" 추가 권장',
      'isScrollControlled=true 시 DraggableScrollableSheet 활용 고려 — 긴 컨텐츠 스크롤 접근성',
      '시트 내부 첫 인터랙티브 요소에 autofocus 설정하면 키보드 포커스 자동 이동',
      'SafeArea 적용 — 홈 인디케이터 위 안전 영역 확보',
    ],
    guidelines: [
      { kind: 'do',   text: '이미지 소스 선택, 정렬 옵션, 멤버 액션 등 단계적 옵션 선택에 사용.',                       recipeKey: 'do-image-source' },
      { kind: 'dont', text: '모달 위에 다른 모달 스택 금지 — dialog 위 sheet, sheet 위 dialog 모두 NG.',               recipeKey: 'dont-stack-modals' },
      { kind: 'do',   text: '정렬·필터 옵션처럼 컨텍스트 유지가 필요한 선택 UI에 사용.',                                 recipeKey: 'do-sort-options' },
      { kind: 'dont', text: 'isScrollControlled=false인데 컨텐츠가 화면 절반 초과 시 isScrollControlled=true로 전환.' },
      { kind: 'do',   text: 'showHandle=false 시 반드시 명시적 닫기 수단 제공 (X 버튼 / 취소 row).' },
      { kind: 'dont', text: '복잡한 다단계 폼은 BottomSheet 금지 — 전용 Route 사용.' },
    ],
    dartUsage: `// 이미지 소스 선택
await showMinglitBottomSheet(
  context: context,
  title: '사진 가져오기',
  child: MinglitImageSourceSheet(
    onCamera: () { /* 카메라 */ },
    onGallery: () { /* 앨범 */ },
  ),
);

// 긴 목록 (isScrollControlled)
await showMinglitBottomSheet(
  context: context,
  title: '전체 멤버',
  isScrollControlled: true,
  child: ListView.builder(
    shrinkWrap: true,
    itemCount: members.length,
    itemBuilder: (_, i) => MinglitListTile(title: members[i].name),
  ),
);`,
    placement: {
      where: [
        '`Bottom sheet` 스캐폴드 자체 — MinglitBottomSheet가 스크림 아래쪽에서 올라오는 surface.',
        '어느 화면에서든 showMinglitBottomSheet() 호출로 표시. scaffold 종속 없음.',
      ],
      spacing: [
        { neighbor: '스크림(배경)',           gap: 'color-scrim overlay' },
        { neighbor: '시트 상단 핸들 여백',     gap: 'spacing-small (8px) 상하' },
        { neighbor: '타이틀 → 콘텐츠',         gap: 'spacing-medium (16px)', note: 'MinglitDialog와 통일' },
        { neighbor: '콘텐츠 좌우 패딩',         gap: 'spacing-screen-edge (16px)' },
        { neighbor: '콘텐츠 하단 패딩',         gap: 'spacing-medium (16px) + SafeArea' },
      ],
      compositions: [
        { label: 'MinglitImageSourceSheet', description: '이미지 소스 선택의 표준 패턴.', recipeKey: 'do-image-source' },
        { label: 'Sort / filter options',   description: '정렬·필터 옵션 선택.',           recipeKey: 'do-sort-options' },
        { label: 'MinglitListTile rows',    description: '멤버 액션 / 옵션 목록.' },
      ],
    },
  },

  // ---------- Media ----------
  {
    name: 'MinglitImage',
    category: 'Media',
    purpose: '테마 네트워크 이미지. 로딩 중 shimmer placeholder + 로드 실패 시 error fallback overlay를 자동 처리한다.',
    props: [
      { name: 'url',          type: 'String',           required: true,   notes: '네트워크 이미지 URL. 빈 문자열이면 즉시 error fallback 표시.' },
      { name: 'width',        type: 'double?',          default: 'null',  notes: 'null이면 부모 폭 채움.' },
      { name: 'height',       type: 'double?',          default: 'null',  notes: 'null이면 aspectRatio 또는 부모 크기 기준.' },
      { name: 'fit',          type: 'BoxFit',           default: 'BoxFit.cover', notes: '이미지 핏. 카드 썸네일은 cover, 프리뷰는 contain.' },
      { name: 'borderRadius', type: 'BorderRadius?',    default: 'radius-card (16px)', notes: '기본 card radius 적용. 원형은 BorderRadius.circular(999) 전달.' },
      { name: 'placeholder',  type: 'Widget?',          default: 'null',  notes: 'null이면 shimmer gradient 스켈레톤 자동 표시.' },
    ],
    variants: ['loaded (default)', 'placeholder (loading)', 'error fallback'],
    states: ['loading → shimmer', 'loaded → 이미지 표시', 'error → fallback overlay'],
    tokens: [
      { name: 'radius-card',   where: '이미지 border-radius 기본값 (16px)' },
      { name: 'color-surface', where: 'placeholder shimmer 베이스 색상' },
      { name: 'color-divider', where: 'placeholder shimmer highlight 색상' },
      { name: 'color-error',   where: 'error fallback 오버레이 색상 힌트' },
    ],
    accessibility: [
      'url이 의미 있는 이미지이면 상위에서 Semantics(label: "...") 또는 excludeSemantics: true 처리 필요.',
      'error fallback은 텍스트 레이블("이미지 없음")을 포함 — 이미지 내용을 알 수 없을 때 스크린 리더 지원.',
    ],
    guidelines: [
      { kind: 'do',   text: '이미지 로딩 중에는 반드시 placeholder(shimmer)를 표시해 레이아웃 이동(CLS)을 방지한다.', recipeKey: 'do-placeholder' },
      { kind: 'dont', text: '로드 실패 시 broken-image 아이콘을 직접 노출하지 말 것 — MinglitImage error fallback이 표준.', recipeKey: 'dont-broken-icon' },
      { kind: 'do',   text: '에러 상태에는 error fallback overlay를 사용 — 사용자가 이미지가 없다는 것을 인지할 수 있게 한다.', recipeKey: 'do-error-fallback' },
      { kind: 'do',   text: 'fit=BoxFit.cover를 유지해 종횡비를 보존한다. 카드 내 이미지 영역을 압축하지 말 것.', recipeKey: 'do-maintain-ratio' },
      { kind: 'dont', text: '이미지 width/height를 임의로 늘려 종횡비를 깨지 말 것 — 콘텐츠가 찌그러져 보인다.', recipeKey: 'dont-stretch-image' },
    ],
    dartUsage: `// 기본 이미지 (이벤트 썸네일)
MinglitImage(url: party.coverImageUrl, width: double.infinity, height: 200)

// 프로필 원형 이미지
MinglitImage(
  url: user.profileImageUrl,
  width: 48,
  height: 48,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(999),
)

// contain 핏 (포스터 프리뷰)
MinglitImage(url: event.posterUrl, width: 120, height: 160, fit: BoxFit.contain)`,
    placement: {
      where: [
        '`Detail + Bottom CTA` 스캐폴드 — MinglitSection 안 이벤트 대표 이미지 히어로.',
        '`List + Filter chips` 스캐폴드 — MinglitContentCard 내 썸네일 영역.',
        '프로필 페이지 — 원형 아바타 (borderRadius.circular(999)).',
      ],
      spacing: [
        { neighbor: 'MinglitSection 제목',     gap: 'spacing-medium (16px)', note: '이미지 하단 → 섹션 제목 상단' },
        { neighbor: 'MinglitContentCard 경계', gap: '0',                     note: '카드 썸네일은 카드 상단에 붙임 — 별도 패딩 없음' },
        { neighbor: '인접 텍스트',             gap: 'spacing-small (8px)',   note: '인라인 이미지-텍스트 페어' },
      ],
      compositions: [
        { label: 'Event detail hero', description: '이벤트 상세 상단 풀폭 히어로 이미지.', recipeKey: 'do-maintain-ratio' },
        { label: 'Card thumbnail',    description: 'MinglitContentCard 좌측 고정 썸네일.' },
        { label: 'Profile avatar',    description: '원형 클립 아바타 (borderRadius.circular).' },
      ],
    },
  },
  {
    name: 'MinglitImageCarousel',
    category: 'Media',
    purpose: '수평 페이지 슬라이드 이미지 캐러셀. PageView + 하단 도트 인디케이터로 구성. 이벤트 상세 히어로에 사진 여러 장 표시.',
    props: [
      { name: 'urls',          type: 'List<String>',       required: true,   notes: '이미지 URL 목록. 비어 있으면 빈 상태(empty placeholder) 표시.' },
      { name: 'aspectRatio',   type: 'double',             default: '16 / 9', notes: '캐러셀 종횡비. 변경 시 모든 페이지에 동일 비율 적용.' },
      { name: 'showIndicator', type: 'bool',               default: 'true',  notes: 'false이면 하단 도트 인디케이터 숨김.' },
      { name: 'onPageChanged', type: 'ValueChanged<int>?', default: 'null',  notes: '페이지 변경 콜백. 페이지 번호(0-indexed) 전달.' },
    ],
    variants: ['with indicator (default)', 'without indicator (showIndicator=false)', 'square ratio', 'landscape ratio (default)'],
    states: ['page 1 / N (첫 페이지 활성 dot)', 'page N / N (마지막 페이지)', 'single image (인디케이터 숨김 권장)'],
    tokens: [
      { name: 'radius-card',    where: '캐러셀 컨테이너 border-radius + overflow:hidden' },
      { name: 'color-primary',  where: '활성 도트 색상 (18px 너비)' },
      { name: 'color-divider',  where: '비활성 도트 색상 (6px 원형)' },
      { name: 'spacing-xsmall', where: '도트 인디케이터 gap (4px)' },
    ],
    accessibility: [
      'PageView에 Semantics(label: "이미지 캐러셀, N장") 래핑 권장.',
      '각 이미지에 의미 있는 레이블 제공이 어려울 경우 excludeSemantics: true 처리.',
      '스와이프 외에 접근성 도구로도 페이지 이동 가능하도록 onPageChanged 콜백 연결 필요.',
    ],
    guidelines: [
      { kind: 'do',   text: 'aspectRatio를 고정해 모든 페이지가 동일한 높이를 유지한다 — 스와이프 시 레이아웃 점프 방지.', recipeKey: 'do-maintain-aspect-ratio' },
      { kind: 'dont', text: '페이지마다 이미지 크기를 다르게 하지 말 것 — 높이가 달라지면 인디케이터 위치가 튄다.', recipeKey: 'dont-random-heights' },
      { kind: 'do',   text: '이미지가 2장 이상일 때 showIndicator=true(기본)로 현재 페이지를 사용자에게 알린다.', recipeKey: 'do-show-indicator' },
      { kind: 'dont', text: '이미지가 1장뿐인데 인디케이터를 표시하지 말 것 — showIndicator=false로 설정.', recipeKey: 'dont-no-feedback' },
      { kind: 'do',   text: '캐러셀은 이벤트 상세 히어로 슬롯에만 사용 — 리스트 카드 안 인라인 캐러셀은 스크롤 충돌 원인.' },
    ],
    dartUsage: `// 이벤트 상세 히어로 캐러셀
MinglitImageCarousel(
  urls: party.imageUrls,
  aspectRatio: 16 / 9,
  showIndicator: true,
  onPageChanged: (page) => debugPrint('page: $page'),
)

// 단일 이미지 — 인디케이터 끄기
MinglitImageCarousel(
  urls: [party.coverImageUrl],
  showIndicator: false,
)`,
    placement: {
      where: [
        '`Detail + Bottom CTA` 스캐폴드 — AppBar 바로 아래 풀폭 히어로 영역.',
        'MinglitSection 안 — 이벤트 사진 섹션 (섹션 타이틀 아래 직접 배치).',
      ],
      spacing: [
        { neighbor: 'AppBar 하단',                   gap: '0',                          note: '히어로는 AppBar에 붙임 (edge-to-edge)' },
        { neighbor: '아래 MinglitSection',           gap: 'spacing-section-gap (40px)', note: '히어로 → 첫 섹션 표준 간격' },
        { neighbor: '도트 인디케이터 ↔ 다음 콘텐츠', gap: 'spacing-medium (16px)',      note: '인디케이터 아래 여백' },
      ],
      compositions: [
        { label: 'Event detail hero carousel', description: '풀폭 16:9 히어로에 사진 N장 슬라이드.', recipeKey: 'do-maintain-aspect-ratio' },
        { label: 'Single image fallback',      description: '1장일 때 showIndicator=false로 인디케이터 숨김.', recipeKey: 'dont-no-feedback' },
      ],
    },
  },
  {
    name: 'MinglitImageSourceSheet',
    category: 'Media',
    purpose: '이미지 소스 선택 bottom sheet 컨텐츠. 카메라 촬영 / 앨범 선택 / 취소 행으로 구성. 반드시 MinglitBottomSheet의 child로 사용한다.',
    props: [
      { name: 'onCamera',  type: 'VoidCallback',  required: true,  notes: '"카메라로 촬영" 행 탭 콜백. 카메라 권한 요청 → 촬영 플로우 시작.' },
      { name: 'onGallery', type: 'VoidCallback?', default: 'null', notes: '"앨범에서 선택" 행. null이면 행 자체가 렌더되지 않음 (camera-only variant).' },
    ],
    variants: ['both (default) — 카메라 + 앨범 + 취소', 'camera-only — 카메라 + 취소 (onGallery=null)'],
    states: ['default — 모든 행 탭 가능', 'loading (외부 관리) — 권한 요청 중 dim 처리 권장'],
    tokens: [
      { name: 'color-surface',        where: '옵션 행 배경 (기본)' },
      { name: 'color-divider',        where: '취소 행 위 구분선 + 비활성 도트' },
      { name: 'color-text-primary',   where: '옵션 행 레이블 색상' },
      { name: 'color-text-secondary', where: '취소 행 레이블 + 아이콘 색상' },
      { name: 'radius-small',         where: '옵션 행 border-radius (8px)' },
      { name: 'spacing-sm',           where: '행 내부 수평 패딩 (12px)' },
      { name: 'spacing-small',        where: '아이콘 ↔ 레이블 gap (8px)' },
      { name: 'spacing-medium',       where: '행 좌우 외부 여백 (MinglitBottomSheet 패딩과 일치)' },
    ],
    accessibility: [
      '각 행에 Semantics(button: true, label: "카메라로 촬영") 적용 — 스크린 리더가 버튼으로 읽음.',
      '취소 행은 Semantics(label: "취소, 시트 닫기") 추가 권장.',
      '최소 터치 타겟 height: 40px — WCAG 2.5.5 (44dp 권장) 상 허용 범위 (InkWell 영역 확장 가능).',
    ],
    guidelines: [
      { kind: 'do',   text: 'MinglitBottomSheet의 child로만 사용한다 — 독립 위젯으로 직접 push하지 말 것.', recipeKey: 'do-inside-bottom-sheet' },
      { kind: 'dont', text: 'MinglitBottomSheet 없이 단독으로 렌더하지 말 것 — 스크림·드래그 핸들·타이틀 없이 UI가 노출된다.', recipeKey: 'dont-standalone' },
      { kind: 'do',   text: '카메라만 필요한 경우 onGallery를 생략(null)해 camera-only variant를 사용한다.', recipeKey: 'do-camera-only' },
      { kind: 'dont', text: '커스텀 시트를 직접 구현하지 말 것 — MinglitImageSourceSheet가 표준 패턴이다.', recipeKey: 'dont-custom-sheet' },
      { kind: 'do',   text: '취소 행은 반드시 포함한다 — 사용자가 언제든 작업을 취소할 수 있어야 한다.' },
    ],
    dartUsage: `// 표준 — 카메라 + 앨범 + 취소
await showMinglitBottomSheet(
  context: context,
  title: '사진 가져오기',
  child: MinglitImageSourceSheet(
    onCamera: () async {
      Navigator.pop(context);
      await _pickFromCamera();
    },
    onGallery: () async {
      Navigator.pop(context);
      await _pickFromGallery();
    },
  ),
);

// 카메라 전용
await showMinglitBottomSheet(
  context: context,
  title: '사진 가져오기',
  child: MinglitImageSourceSheet(
    onCamera: () async {
      Navigator.pop(context);
      await _pickFromCamera();
    },
  ),
);`,
    placement: {
      where: [
        '`Bottom sheet` 스캐폴드 — MinglitBottomSheet의 child 슬롯 안. 직접 scaffold 종속 없음.',
        '어느 화면에서든 showMinglitBottomSheet() 호출로 표시 — 프로필 편집, 이벤트 생성, 채팅 첨부 등.',
      ],
      spacing: [
        { neighbor: 'MinglitBottomSheet title 아래', gap: 'spacing-small (8px)',   note: '시트 내부 gap — MinglitBottomSheet가 처리' },
        { neighbor: '취소 행 위 구분선',             gap: 'spacing-xsmall (4px)',  note: 'marginTop on cancel row' },
        { neighbor: '시트 하단',                     gap: 'spacing-medium (16px)', note: 'MinglitBottomSheet 하단 패딩' },
      ],
      compositions: [
        { label: 'Inside MinglitBottomSheet', description: 'showMinglitBottomSheet(child: MinglitImageSourceSheet(...)) — 표준.', recipeKey: 'do-inside-bottom-sheet' },
        { label: 'Camera-only variant',       description: 'onGallery 없이 카메라 전용 플로우.',                                  recipeKey: 'do-camera-only' },
      ],
    },
  },
];

const ORDERED: ComponentCategory[] = [
  'Action',
  'Chips',
  'Inputs',
  'Cards',
  'Tags & Badges',
  'Sections',
  'Lists',
  'Layouts',
  'Settings',
  'Feedback',
  'Loading',
  'Overlay',
  'Media',
];

export function getComponentsByCategory(): Array<{
  category: ComponentCategory;
  items: ComponentSpec[];
}> {
  const groups = new Map<ComponentCategory, ComponentSpec[]>();
  for (const c of MDS_COMPONENTS) {
    if (!groups.has(c.category)) groups.set(c.category, []);
    groups.get(c.category)!.push(c);
  }
  return ORDERED.filter((cat) => groups.has(cat)).map((category) => ({
    category,
    items: groups.get(category)!,
  }));
}

export function getComponentByName(name: string): ComponentSpec | undefined {
  return MDS_COMPONENTS.find((c) => c.name === name);
}

