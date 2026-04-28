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
    purpose: 'Small selectable label / status chip.',
    props: ['label', 'icon', 'size', 'color', 'onTap'],
  },
  {
    name: 'MinglitFilterChip',
    category: 'Chips',
    purpose: 'Toggleable filter chip with selected state.',
    props: ['label', 'isSelected', 'onSelected', 'icon'],
  },
  {
    name: 'MinglitChipGroup',
    category: 'Chips',
    purpose: 'Horizontal/scrollable chip container.',
    props: ['children', 'scrollable', 'spacing'],
  },
  {
    name: 'MinglitBottomCta',
    category: 'Action',
    purpose: 'Fixed-bottom CTA bar (e.g. "Apply" on detail screens).',
    props: ['label', 'onPressed', 'isLoading'],
  },

  // ---------- Inputs ----------
  {
    name: 'MinglitTextField',
    category: 'Inputs',
    purpose: 'Theme-aware text input with error / disabled / icon support.',
    props: ['controller', 'label', 'hint', 'errorText', 'prefixIcon', 'suffixIcon', 'enabled', 'maxLines'],
  },
  {
    name: 'NumberStepperInput',
    category: 'Inputs',
    purpose: 'Plus/minus stepper for integer values.',
    props: ['value', 'onChanged', 'min', 'max', 'step'],
  },

  // ---------- Cards ----------
  {
    name: 'MinglitContentCard',
    category: 'Cards',
    purpose: 'Generic content card with optional header / footer.',
    props: ['child', 'header', 'footer', 'onTap', 'padding'],
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
    purpose: 'Empty list / no-results placeholder with optional CTA.',
    props: ['icon', 'title', 'message', 'action'],
  },
  {
    name: 'MinglitErrorState',
    category: 'Feedback',
    purpose: 'Error placeholder with retry CTA.',
    props: ['title', 'message', 'onRetry'],
  },

  // ---------- Layout ----------
  {
    name: 'MinglitSection',
    category: 'Sections',
    purpose: 'Section wrapper with optional header / divider spacing.',
    props: ['header', 'children', 'padding'],
  },
  {
    name: 'MinglitSectionDivider',
    category: 'Sections',
    purpose: 'Horizontal divider with consistent spacing.',
    props: ['spacing'],
  },
  {
    name: 'MinglitListTile',
    category: 'Lists',
    purpose: 'Generic list row with leading / trailing slots.',
    props: ['leading', 'title', 'subtitle', 'trailing', 'onTap'],
  },
  {
    name: 'MinglitKeyValueRow',
    category: 'Lists',
    purpose: 'Aligned key-value pair row (info displays).',
    props: ['keyText', 'value', 'highlight'],
  },
  {
    name: 'MinglitContentLayout',
    category: 'Layouts',
    purpose: 'Standard content area scaffolding (padding + scroll).',
    props: ['child', 'padding', 'scrollable'],
  },
  {
    name: 'MinglitHorizontalScrollGroup',
    category: 'Lists',
    purpose: 'Horizontally scrolling row of cards / chips.',
    props: ['children', 'spacing', 'padding'],
  },

  // ---------- Settings ----------
  {
    name: 'MinglitSettingsGroup',
    category: 'Settings',
    purpose: 'Grouped settings list with optional header label.',
    props: ['header', 'children'],
    usedIn: ['user-MyPageRoute'],
  },
  {
    name: 'MinglitSettingsTile',
    category: 'Settings',
    purpose: 'Settings row with leading icon, title, optional subtitle, trailing chevron.',
    props: ['leading', 'title', 'subtitle', 'trailing', 'destructive', 'onTap'],
    usedIn: ['user-MyPageRoute'],
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
    purpose: 'Modal alert / confirm dialog (showAlert/showConfirm static methods).',
    props: ['title', 'content', 'confirmText', 'cancelText', 'isDestructive'],
    usedIn: ['user-MyPageRoute'],
  },
  {
    name: 'MinglitDialog',
    category: 'Overlay',
    purpose: 'Custom-content modal dialog.',
    props: ['title', 'child', 'actions'],
  },
  {
    name: 'MinglitBottomSheet',
    category: 'Overlay',
    purpose: 'Bottom sheet with handle + drag-to-dismiss.',
    props: ['child', 'isDismissible', 'isScrollControlled'],
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

