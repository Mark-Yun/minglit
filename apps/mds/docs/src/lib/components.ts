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
export interface ComponentSpec {
  /** Component name (PascalCase). */
  name: string;
  /** Visual / functional grouping. */
  category: ComponentCategory;
  /** One-line role description. */
  purpose: string;
  /** Public API contract (props with conceptual meaning). */
  props?: string[];
  /** Visual variants (e.g. primary / secondary / destructive). */
  variants?: string[];
  /** Interactive states (e.g. default / disabled / loading / focused). */
  states?: string[];
  /** mds_tokens this component consumes. */
  tokens?: string[];
  /** Accessibility requirements (ARIA, keyboard nav). */
  accessibility?: string[];
  /** Usage do/don't notes. */
  guidelines?: string[];
  /**
   * Path under /public/specs/components/ to a static HTML design spec
   * (visual mockup with spec-mode annotations). Optional — not all
   * components need a visual spec yet.
   */
  visualSpec?: string;
  /** Routes / specs that reference this component (anchor IDs). */
  usedIn?: string[];
}

export const MDS_COMPONENTS: ComponentSpec[] = [
  // ---------- Buttons ----------
  {
    name: 'MinglitButton',
    category: 'Action',
    purpose: 'Unified CTA button enforcing mds tokens. 4 variants × 3 sizes, with loading + leading icon.',
    props: [
      'label',
      'onPressed',
      'icon',
      'isLoading',
      'size (default: large; text default: medium)',
      'expand (default: true; text default: false)',
    ],
    variants: ['primary', 'secondary', 'text', 'destructive'],
    states: ['default', 'hovered', 'pressed', 'disabled', 'loading'],
    tokens: [
      'color-primary', 'color-on-primary',
      'color-error', 'color-on-error',
      'spacing-small (icon-label gap)',
      'spacing-medium (horizontal padding)',
      'radius-button (12px)',
    ],
    accessibility: [
      'Disabled state announced to screen readers (onPressed == null)',
      'Loading state blocks taps; spinner color matches foreground (onPrimary / onError / primary)',
      'Min touch target ≥ 36px (size=small) — prefer medium/large for primary CTAs',
    ],
    guidelines: [
      'DO: one primary per screen (main CTA)',
      'DON\'T: stack multiple destructive buttons in same view',
      'DO: use isLoading for async actions (prevents double-tap)',
      'DO: pair destructive with confirm dialog (MinglitAlert.showConfirm)',
      'DO: use text variant for inline / secondary actions inside cards',
    ],
    visualSpec: '/specs/components/minglit_button.html',
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

