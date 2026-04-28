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
 *   2. Add an entry below
 *   3. Optionally add a Widgetbook story (kept until 2026-06)
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
    purpose: 'Fixed-bottom CTA bar (e.g. "Apply" on detail screens).',
    props: ['label', 'onPressed', 'isLoading'],
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
    purpose: 'Generic content card with optional header / footer.',
    props: ['child', 'header', 'footer', 'onTap', 'padding'],
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
  },
  {
    name: 'MinglitTag',
    category: 'Tags & Badges',
    purpose: 'Inline label tag (variant of chip without interaction).',
    props: ['label', 'size', 'color'],
  },
  {
    name: 'MinglitBadge',
    category: 'Tags & Badges',
    purpose: 'Notification badge (numeric / dot).',
    props: ['count', 'maxCount', 'showZero'],
  },
  {
    name: 'MinglitParticipantGauge',
    category: 'Tags & Badges',
    purpose: 'Progress gauge for "N / M participants".',
    props: ['current', 'max', 'showLabel'],
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
    purpose: 'Section wrapper with optional header / divider spacing.',
    props: ['header', 'children', 'padding'],
    placement: {
      where: [
        '`Detail + Bottom CTA`의 스크롤 본문 안 — 한 화면당 여러 섹션을 세로로 쌓음.',
        '`MinglitContentLayout` 안의 직계 자식.',
      ],
      spacing: [
        { neighbor: '다음 섹션',           gap: 'spacing-section-gap (40px)', note: '큰 토픽 단위 분리' },
        { neighbor: '섹션 헤더 → 본문',    gap: 'spacing-medium (16px)' },
        { neighbor: '섹션 내 그룹 사이',    gap: 'spacing-large (24px)' },
      ],
    },
  },
  {
    name: 'MinglitSectionDivider',
    category: 'Sections',
    purpose: 'Horizontal divider with consistent spacing.',
    props: ['spacing'],
    placement: {
      where: [
        '섹션 사이 명시적 시각 구분이 필요할 때만 — 보통은 spacing-section-gap 만으로 충분.',
        'thick(8px) — 섹션 단위 강한 분리. thin(1px) — 그룹 단위 약한 분리.',
      ],
    },
  },
  {
    name: 'MinglitListTile',
    category: 'Lists',
    purpose: 'Generic list row with leading / trailing slots.',
    props: ['leading', 'title', 'subtitle', 'trailing', 'onTap'],
    placement: {
      where: [
        '리스트 / 멤버 / 알림 같은 동질적 row의 반복 단위.',
        '`MinglitContentCard` 안에서도 사용 가능 (카드 내부 row).',
      ],
      spacing: [
        { neighbor: '같은 리스트의 sibling tile', gap: '0', note: '연속 row는 보더 없이 붙음 (divider는 별도)' },
        { neighbor: '내부 vertical padding',       gap: 'spacing-card-content-v (16px)', note: 'hit zone 56pt 이상 보장' },
      ],
    },
  },
  {
    name: 'MinglitKeyValueRow',
    category: 'Lists',
    purpose: 'Aligned key-value pair row (info displays).',
    props: ['keyText', 'value', 'highlight'],
    placement: {
      where: [
        '`MinglitContentCard` 내부 — 정산 / 상세 정보 / 통계 row.',
        'highlight=true는 합계 / 강조 row 1개에만.',
      ],
      spacing: [
        { neighbor: '같은 카드 안 sibling row', gap: 'spacing-small (8px)' },
        { neighbor: 'highlight row 위 divider', gap: 'thin divider', note: '합계 앞에 명시적 구분' },
      ],
    },
  },
  {
    name: 'MinglitContentLayout',
    category: 'Layouts',
    purpose: 'Standard content area scaffolding (padding + scroll).',
    props: ['child', 'padding', 'scrollable'],
    placement: {
      where: [
        '대부분의 화면 본문 — `Detail + Bottom CTA`, `Form + Bottom CTA`, `List + Filter chips` 스캐폴드의 body root.',
        'AppBar 아래 / Bottom CTA 위에 배치.',
      ],
      spacing: [
        { neighbor: '좌/우 화면 가장자리', gap: 'spacing-screen-edge (16px)', note: '내부 패딩으로 처리' },
        { neighbor: '내부 sections 사이',  gap: 'spacing-section-gap (40px)' },
        { neighbor: '상단 (AppBar 아래)',  gap: 'spacing-medium (16px)' },
      ],
    },
  },
  {
    name: 'MinglitHorizontalScrollGroup',
    category: 'Lists',
    purpose: 'Horizontally scrolling row of cards / chips.',
    props: ['children', 'spacing', 'padding'],
    placement: {
      where: [
        '섹션 안에서 sibling 카드들이 가로로 펼쳐질 때 — 추천 / 인기 / 최근 같은 카탈로그.',
        '한 화면 안에 2-3개 이상 스택하지 말 것 (수직 정보가 묻힘).',
      ],
      spacing: [
        { neighbor: '내부 카드 사이',          gap: 'spacing-card-gap (12px)' },
        { neighbor: '좌/우 첫·마지막 카드 패딩', gap: 'spacing-screen-edge (16px)', note: '스크롤 끝에서 화면 가장자리까지' },
      ],
    },
  },

  // ---------- Settings ----------
  {
    name: 'MinglitSettingsGroup',
    category: 'Settings',
    purpose: 'Grouped settings list with optional header label.',
    props: ['header', 'children'],
    usedIn: ['user-MyPageRoute'],
    placement: {
      where: [
        '`Settings groups` 스캐폴드 — 한 화면에 여러 그룹을 세로로 스택.',
        '같은 토픽의 설정 tile들을 묶음. 헤더 라벨로 그룹 의미 명시.',
      ],
      spacing: [
        { neighbor: '다음 그룹',          gap: 'spacing-large (24px)' },
        { neighbor: '그룹 헤더 → 첫 tile', gap: 'spacing-small (8px)' },
        { neighbor: '내부 tiles 사이',     gap: '0', note: 'tile 자체 padding이 hit zone 보장' },
      ],
    },
  },
  {
    name: 'MinglitSettingsTile',
    category: 'Settings',
    purpose: 'Settings row with leading icon, title, optional subtitle, trailing chevron.',
    props: ['leading', 'title', 'subtitle', 'trailing', 'destructive', 'onTap'],
    usedIn: ['user-MyPageRoute'],
    placement: {
      where: [
        '`MinglitSettingsGroup` 내부 직계 자식. 단독 사용 안 함.',
        'destructive=true는 그룹의 마지막 tile에 — 계정 삭제 / 로그아웃 같은 종결 액션.',
      ],
      spacing: [
        { neighbor: '같은 그룹 sibling tile', gap: '0', note: '연속 row는 붙고, 내부 padding이 hit zone 형성' },
        { neighbor: '내부 vertical padding',  gap: 'spacing-card-content-v (16px)', note: 'hit zone 56pt' },
        { neighbor: '내부 horizontal padding', gap: 'spacing-medium (16px)' },
      ],
    },
  },

  // ---------- Loading ----------
  {
    name: 'LoadingIndicator',
    category: 'Loading',
    purpose: 'App-wide loading spinner wrapper.',
    props: ['size', 'color'],
  },
  {
    name: 'MinglitSkeleton',
    category: 'Loading',
    purpose: 'Skeleton placeholder for loading content.',
    props: ['width', 'height', 'borderRadius'],
  },
  {
    name: 'MinglitAsyncValueWidget',
    category: 'Loading',
    purpose: 'Riverpod AsyncValue<T> renderer (data / loading / error).',
    props: ['value', 'data', 'loading', 'error'],
  },

  // ---------- Overlay ----------
  {
    name: 'MinglitAlert',
    category: 'Overlay',
    purpose: '결정 요구 또는 단순 알림을 위한 모달 다이얼로그. showAlert/showConfirm static API 제공.',
    props: [
      { name: 'title',   type: 'String',           required: true,  notes: '다이얼로그 타이틀. titleMedium bold 스타일 적용.' },
      { name: 'content', type: 'String?',          default: 'null', notes: '선택적 본문 텍스트 (body medium).' },
      { name: 'actions', type: 'List<Widget>?',    default: 'null', notes: '액션 버튼 목록. showConfirm 사용 시 자동 생성.' },
      { name: 'type',    type: 'MinglitAlertType', default: 'MinglitAlertType.info', notes: 'info (기본) | destructive — destructive 시 경고 아이콘 + error 색상.' },
    ],
    variants: ['alert (info)', 'confirm (info)', 'confirm (destructive)'],
    states: ['visible', 'confirmed', 'cancelled'],
    tokens: [
      { name: 'color-scrim',        where: '배경 스크림 오버레이 rgba(0,0,0,0.5)' },
      { name: 'radius-dialog',      where: '다이얼로그 카드 코너 반경 28px' },
      { name: 'color-error',        where: 'destructive 타입 — 아이콘 · 타이틀 · 확인 버튼 색상' },
      { name: 'color-primary',      where: 'info 타입 — 확인 버튼 색상' },
      { name: 'spacing-large',      where: '타이틀 / 콘텐츠 패딩 상하좌우 24px' },
      { name: 'spacing-small',      where: '액션 row 버튼 간격 8px' },
      { name: 'spacing-sm',         where: '액션 패딩 leading 12px' },
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
        { neighbor: '스크림(배경)',           gap: 'color-scrim overlay',  note: '화면 전체를 덮고 그 위에 카드가 중앙 정렬' },
        { neighbor: '카드 내부 타이틀 패딩',  gap: 'spacing-large (24px)', note: 'fromLTRB(24, 24, 24, 8)' },
        { neighbor: '카드 내부 액션 패딩',    gap: 'spacing-large (24px)', note: 'fromLTRB(12, 0, 24, 24)' },
        { neighbor: '액션 버튼 사이',         gap: 'spacing-small (8px)' },
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
      { name: 'title',   type: 'String',          required: true,  notes: '다이얼로그 타이틀 (titleMedium bold).' },
      { name: 'content', type: 'Widget',          required: true,  notes: '메인 컨텐츠 위젯 — 입력 폼, 선택 리스트, 스테퍼 등 자유 구성.' },
      { name: 'actions', type: 'List<Widget>?',   default: 'null', notes: '하단 액션 버튼 목록. null이면 액션 row 미표시.' },
    ],
    variants: ['custom-content (default)'],
    states: ['visible', 'confirmed', 'dismissed'],
    tokens: [
      { name: 'color-scrim',    where: '배경 스크림 오버레이 rgba(0,0,0,0.5)' },
      { name: 'radius-dialog',  where: '다이얼로그 카드 코너 반경 28px' },
      { name: 'color-primary',  where: '확인 버튼 foreground (호출자가 MinglitButton 사용 시)' },
      { name: 'spacing-large',  where: '타이틀 / 콘텐츠 패딩 24px' },
      { name: 'spacing-small',  where: '액션 row 버튼 간격 8px' },
      { name: 'spacing-xsmall', where: '콘텐츠 하단 패딩 4px' },
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
        { neighbor: '스크림(배경)',          gap: 'color-scrim overlay' },
        { neighbor: '카드 내부 타이틀 패딩', gap: 'spacing-large (24px)', note: 'fromLTRB(24, 24, 24, 8)' },
        { neighbor: '카드 내부 콘텐츠 패딩', gap: 'spacing-large (24px) H · spacing-xsmall (4px) B' },
        { neighbor: '액션 버튼 사이',        gap: 'spacing-small (8px)' },
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
      { name: 'spacing-medium',       where: '콘텐츠 하단 패딩 16px' },
      { name: 'spacing-sm',           where: '타이틀 → 콘텐츠 간격 12px' },
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
        { neighbor: '타이틀 → 콘텐츠',         gap: 'spacing-sm (12px)' },
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
    purpose: 'Themed image with placeholder + error fallback.',
    props: ['url', 'width', 'height', 'fit', 'placeholder'],
  },
  {
    name: 'MinglitImageCarousel',
    category: 'Media',
    purpose: 'Horizontally paged image carousel with indicator.',
    props: ['urls', 'aspectRatio', 'showIndicator'],
  },
  {
    name: 'MinglitImageSourceSheet',
    category: 'Media',
    purpose: 'Bottom sheet to pick image source (camera / library).',
    props: ['onCamera', 'onGallery'],
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

