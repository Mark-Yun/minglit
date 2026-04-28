'use client';

import { useState, type ComponentType } from 'react';
import {
  getComponentsByCategory,
  MDS_COMPONENTS,
  isPropDef,
  isGuidelineEntry,
  isTokenUsage,
  type ComponentCategory,
  type ComponentSpec,
  type PropDef,
  type GuidelineEntry,
  type TokenUsage,
  type PlacementSpec,
} from '@/lib/components';
import MinglitButtonSpec, {
  GUIDELINE_RECIPES as MINGLIT_BUTTON_RECIPES,
} from '@/components/specs/MinglitButtonSpec';
import MinglitChipSpec, {
  GUIDELINE_RECIPES as MINGLIT_CHIP_RECIPES,
} from '@/components/specs/MinglitChipSpec';
import MinglitFilterChipSpec, {
  GUIDELINE_RECIPES as MINGLIT_FILTER_CHIP_RECIPES,
} from '@/components/specs/MinglitFilterChipSpec';
import MinglitChipGroupSpec, {
  GUIDELINE_RECIPES as MINGLIT_CHIP_GROUP_RECIPES,
} from '@/components/specs/MinglitChipGroupSpec';
import MinglitTextFieldSpec, {
  GUIDELINE_RECIPES as MINGLIT_TEXT_FIELD_RECIPES,
} from '@/components/specs/MinglitTextFieldSpec';
import NumberStepperInputSpec, {
  GUIDELINE_RECIPES as NUMBER_STEPPER_INPUT_RECIPES,
} from '@/components/specs/NumberStepperInputSpec';
import MinglitEmptyStateSpec, {
  GUIDELINE_RECIPES as MINGLIT_EMPTY_STATE_RECIPES,
} from '@/components/specs/MinglitEmptyStateSpec';
import MinglitErrorStateSpec, {
  GUIDELINE_RECIPES as MINGLIT_ERROR_STATE_RECIPES,
} from '@/components/specs/MinglitErrorStateSpec';
import MinglitAlertSpec, {
  GUIDELINE_RECIPES as MINGLIT_ALERT_RECIPES,
} from '@/components/specs/MinglitAlertSpec';
import MinglitDialogSpec, {
  GUIDELINE_RECIPES as MINGLIT_DIALOG_RECIPES,
} from '@/components/specs/MinglitDialogSpec';
import MinglitBottomSheetSpec, {
  GUIDELINE_RECIPES as MINGLIT_BOTTOM_SHEET_RECIPES,
} from '@/components/specs/MinglitBottomSheetSpec';
import MinglitTagSpec, {
  GUIDELINE_RECIPES as MINGLIT_TAG_RECIPES,
} from '@/components/specs/MinglitTagSpec';
import MinglitBadgeSpec, {
  GUIDELINE_RECIPES as MINGLIT_BADGE_RECIPES,
} from '@/components/specs/MinglitBadgeSpec';
import MinglitParticipantGaugeSpec, {
  GUIDELINE_RECIPES as MINGLIT_PARTICIPANT_GAUGE_RECIPES,
} from '@/components/specs/MinglitParticipantGaugeSpec';
import LoadingIndicatorSpec, {
  GUIDELINE_RECIPES as LOADING_INDICATOR_RECIPES,
} from '@/components/specs/LoadingIndicatorSpec';
import MinglitSkeletonSpec, {
  GUIDELINE_RECIPES as MINGLIT_SKELETON_RECIPES,
} from '@/components/specs/MinglitSkeletonSpec';
import MinglitAsyncValueWidgetSpec, {
  GUIDELINE_RECIPES as MINGLIT_ASYNC_VALUE_RECIPES,
} from '@/components/specs/MinglitAsyncValueWidgetSpec';
import MinglitImageSpec, {
  GUIDELINE_RECIPES as MINGLIT_IMAGE_RECIPES,
} from '@/components/specs/MinglitImageSpec';
import MinglitImageCarouselSpec, {
  GUIDELINE_RECIPES as MINGLIT_IMAGE_CAROUSEL_RECIPES,
} from '@/components/specs/MinglitImageCarouselSpec';
import MinglitImageSourceSheetSpec, {
  GUIDELINE_RECIPES as MINGLIT_IMAGE_SOURCE_SHEET_RECIPES,
} from '@/components/specs/MinglitImageSourceSheetSpec';

/**
 * Inline visual specs registered by component name.
 * Each entry has a `Visual` component (rich playground) and an optional
 * `recipes` map for do/don't visualisations next to guideline text.
 */
interface InlineSpecModule {
  Visual: ComponentType;
  recipes?: Record<string, ComponentType>;
}

const INLINE_SPECS: Record<string, InlineSpecModule> = {
  MinglitButton:     { Visual: MinglitButtonSpec,     recipes: MINGLIT_BUTTON_RECIPES },
  MinglitChip:       { Visual: MinglitChipSpec,       recipes: MINGLIT_CHIP_RECIPES },
  MinglitFilterChip: { Visual: MinglitFilterChipSpec, recipes: MINGLIT_FILTER_CHIP_RECIPES },
  MinglitChipGroup:  { Visual: MinglitChipGroupSpec,  recipes: MINGLIT_CHIP_GROUP_RECIPES },
  MinglitTextField:    { Visual: MinglitTextFieldSpec,    recipes: MINGLIT_TEXT_FIELD_RECIPES },
  NumberStepperInput:  { Visual: NumberStepperInputSpec,  recipes: NUMBER_STEPPER_INPUT_RECIPES },
  MinglitEmptyState:   { Visual: MinglitEmptyStateSpec,   recipes: MINGLIT_EMPTY_STATE_RECIPES },
  MinglitErrorState:   { Visual: MinglitErrorStateSpec,   recipes: MINGLIT_ERROR_STATE_RECIPES },
  MinglitAlert:        { Visual: MinglitAlertSpec,        recipes: MINGLIT_ALERT_RECIPES },
  MinglitDialog:       { Visual: MinglitDialogSpec,       recipes: MINGLIT_DIALOG_RECIPES },
  MinglitBottomSheet:  { Visual: MinglitBottomSheetSpec,  recipes: MINGLIT_BOTTOM_SHEET_RECIPES },
  MinglitTag:                 { Visual: MinglitTagSpec,                 recipes: MINGLIT_TAG_RECIPES },
  MinglitBadge:               { Visual: MinglitBadgeSpec,               recipes: MINGLIT_BADGE_RECIPES },
  MinglitParticipantGauge:    { Visual: MinglitParticipantGaugeSpec,    recipes: MINGLIT_PARTICIPANT_GAUGE_RECIPES },
  LoadingIndicator:           { Visual: LoadingIndicatorSpec,           recipes: LOADING_INDICATOR_RECIPES },
  MinglitSkeleton:            { Visual: MinglitSkeletonSpec,            recipes: MINGLIT_SKELETON_RECIPES },
  MinglitAsyncValueWidget:    { Visual: MinglitAsyncValueWidgetSpec,    recipes: MINGLIT_ASYNC_VALUE_RECIPES },
  MinglitImage:               { Visual: MinglitImageSpec,               recipes: MINGLIT_IMAGE_RECIPES },
  MinglitImageCarousel:       { Visual: MinglitImageCarouselSpec,       recipes: MINGLIT_IMAGE_CAROUSEL_RECIPES },
  MinglitImageSourceSheet:    { Visual: MinglitImageSourceSheetSpec,    recipes: MINGLIT_IMAGE_SOURCE_SHEET_RECIPES },
};

// ---------------------------------------------------------------------------
// Completeness — drives the SPEC / API only / stub badge in the header.
// ---------------------------------------------------------------------------
function specCompleteness(c: ComponentSpec): 'rich' | 'minimal' | 'stub' {
  const hasRich =
    (c.variants && c.variants.length > 0) ||
    (c.states && c.states.length > 0) ||
    (c.tokens && c.tokens.length > 0) ||
    (c.guidelines && c.guidelines.length > 0) ||
    !!c.visualSpec;
  if (hasRich) return 'rich';
  if (c.props && c.props.length > 0) return 'minimal';
  return 'stub';
}

// ---------------------------------------------------------------------------
// Section primitive — micro-label header + soft surface panel.
// Hierarchy comes from the outer card border + spacing-xlarge gaps
// between sections + the surface-bg inner panel. Pass wrap={false} for
// content that brings its own panel (e.g. dark code block).
// ---------------------------------------------------------------------------
function Section({
  title,
  children,
  wrap = true,
}: {
  title: string;
  children: React.ReactNode;
  wrap?: boolean;
}) {
  return (
    <section>
      <p
        className="mds-text-caption-tiny font-bold uppercase"
        style={{
          letterSpacing: '0.5px',
          color: 'var(--color-text-secondary)',
          marginBottom: 'var(--spacing-small)',
        }}
      >
        {title}
      </p>
      {wrap ? <div className="mds-spec__panel">{children}</div> : children}
    </section>
  );
}

// ---------------------------------------------------------------------------
// Component card
// ---------------------------------------------------------------------------
function ComponentSection({ c }: { c: ComponentSpec }) {
  const completeness = specCompleteness(c);
  const inlineSpec = INLINE_SPECS[c.name];
  const richProps = (c.props ?? []).filter(isPropDef) as PropDef[];
  const stringProps = (c.props ?? []).filter((p) => !isPropDef(p)) as string[];
  const richGuidelines = (c.guidelines ?? []).filter(isGuidelineEntry) as GuidelineEntry[];
  const stringGuidelines = (c.guidelines ?? []).filter((g) => !isGuidelineEntry(g)) as string[];

  return (
    <article
      id={c.name}
      className="bg-white scroll-mt-20 flex flex-col"
      style={{
        borderRadius: 'var(--radius-card)',
        border: '1px solid var(--color-divider)',
        padding: 'var(--spacing-xlarge)',
        gap: 'var(--spacing-xlarge)',
      }}
    >
      {/* Header — name + category + completeness badge. No bottom border;
          spacing carries the separation. */}
      <header
        className="flex items-baseline justify-between flex-wrap"
        style={{ gap: 'var(--spacing-small)' }}
      >
        <div className="flex items-baseline flex-wrap" style={{ gap: 'var(--spacing-sm)' }}>
          <h2 className="font-mono mds-text-page-title" style={{ color: 'var(--color-text-primary)' }}>
            {c.name}
          </h2>
          <span className="mds-text-caption" style={{ color: 'var(--color-text-secondary)' }}>
            {c.category}
          </span>
        </div>
        <CompletenessBadge state={completeness} />
      </header>

      {/* Purpose — sits right under header with normal gap, no own section. */}
      <p
        className="mds-text-body"
        style={{ color: 'var(--color-text-secondary)', marginTop: 'calc(-1 * var(--spacing-medium))' }}
      >
        {c.purpose}
      </p>

      {/* Visual playground (inline spec — has hero, anatomy, grids) */}
      {inlineSpec && <inlineSpec.Visual />}

      {/* Fallback link to static visual spec */}
      {!inlineSpec && c.visualSpec && (
        <a
          href={c.visualSpec}
          target="_blank"
          rel="noopener noreferrer"
          className="mds-text-caption font-mono self-start hover:underline"
          style={{ color: 'var(--color-primary)' }}
        >
          design spec ↗
        </a>
      )}

      {/* Code (Dart usage) — pre brings its own dark panel. */}
      {c.dartUsage && (
        <Section title="Code" wrap={false}>
          <pre className="mds-spec__code">{c.dartUsage}</pre>
        </Section>
      )}

      {/* Props — table for rich, chips for stub.
          (Variants/States/Tokens chip lists removed — Visual playground
          + Anatomy already cover them. Tokens stay only in Anatomy.) */}
      {(richProps.length > 0 || stringProps.length > 0) && (
        <Section title="Props">
          {richProps.length > 0 ? (
            <PropsTable props={richProps} />
          ) : (
            <ChipList items={stringProps} accent="muted" />
          )}
        </Section>
      )}

      {/* Variants & States — chip list ONLY when there's no rich Visual
          (otherwise the playground shows them already). */}
      {!inlineSpec && (c.variants || c.states) && (
        <div className="grid grid-cols-1 md:grid-cols-2" style={{ gap: 'var(--spacing-medium)' }}>
          {c.variants && c.variants.length > 0 && (
            <Section title="Variants">
              <ChipList items={c.variants} accent="primary" />
            </Section>
          )}
          {c.states && c.states.length > 0 && (
            <Section title="States">
              <ChipList items={c.states} accent="muted" />
            </Section>
          )}
        </div>
      )}

      {/* Placement — where on a screen + spacing to neighbors + compositions. */}
      {c.placement && (
        <Section title="Placement">
          <PlacementBlock
            placement={c.placement}
            recipes={inlineSpec?.recipes}
          />
        </Section>
      )}

      {/* Tokens — table when entries are TokenUsage, chip list otherwise. */}
      {c.tokens && c.tokens.length > 0 && (
        <Section title="Tokens">
          {c.tokens.some(isTokenUsage) ? (
            <TokensTable tokens={c.tokens.filter(isTokenUsage) as TokenUsage[]} />
          ) : (
            <ChipList items={c.tokens.filter((t) => !isTokenUsage(t)) as string[]} accent="muted" />
          )}
        </Section>
      )}

      {/* Accessibility */}
      {c.accessibility && c.accessibility.length > 0 && (
        <Section title="Accessibility">
          <ul
            className="mds-text-body list-disc pl-5"
            style={{ color: 'var(--color-text-secondary)' }}
          >
            {c.accessibility.map((a) => (
              <li key={a}>{a}</li>
            ))}
          </ul>
        </Section>
      )}

      {/* Guidelines — simple ✓/✗ rows with optional inline recipe.
          No colored backgrounds, no boxes — just hierarchy. */}
      {(richGuidelines.length > 0 || stringGuidelines.length > 0) && (
        <Section title="Guidelines">
          <div className="mds-spec__guideline-list">
            {richGuidelines.map((g) => (
              <GuidelineRow
                key={g.text}
                entry={g}
                recipes={inlineSpec?.recipes}
              />
            ))}
            {stringGuidelines.map((g) => (
              <p
                key={g}
                className="mds-text-body"
                style={{ color: 'var(--color-text-secondary)', paddingLeft: 64 }}
              >
                {g}
              </p>
            ))}
          </div>
        </Section>
      )}

      {/* Used in */}
      {c.usedIn && c.usedIn.length > 0 && (
        <Section title="Used in">
          <div className="flex flex-wrap" style={{ gap: 'var(--spacing-xsmall)' }}>
            {c.usedIn.map((ref) => (
              <a
                key={ref}
                href={`/flows#${ref}`}
                className="mds-text-caption font-mono hover:underline"
                style={{ color: 'var(--color-primary)' }}
              >
                {ref}
              </a>
            ))}
          </div>
        </Section>
      )}
    </article>
  );
}

// ---------------------------------------------------------------------------
// Subviews
// ---------------------------------------------------------------------------
function CompletenessBadge({ state }: { state: 'rich' | 'minimal' | 'stub' }) {
  const baseStyle: React.CSSProperties = {
    fontSize: 'var(--typography-font-size-caption-tiny)',
    fontFamily: 'ui-monospace, monospace',
    padding: '2px 6px',
    borderRadius: 'var(--radius-badge)',
  };
  if (state === 'rich') {
    return (
      <span
        style={{
          ...baseStyle,
          background: 'rgba(22, 163, 74, 0.12)',
          color: 'var(--color-success)',
        }}
        title="Spec includes variants/states/tokens or design"
      >
        SPEC
      </span>
    );
  }
  if (state === 'minimal') {
    return (
      <span
        style={{
          ...baseStyle,
          background: 'rgba(217, 119, 6, 0.12)',
          color: 'var(--color-warning)',
        }}
        title="API only — variants / states / tokens missing"
      >
        API only
      </span>
    );
  }
  return (
    <span
      style={{
        ...baseStyle,
        background: 'var(--color-surface)',
        color: 'var(--color-text-secondary)',
      }}
      title="Stub entry — author this spec"
    >
      stub
    </span>
  );
}

function ChipList({
  items,
  accent,
}: {
  items: string[];
  accent: 'primary' | 'muted';
}) {
  const codeStyle: React.CSSProperties =
    accent === 'primary'
      ? { background: 'rgba(153, 0, 255, 0.1)', color: 'var(--color-primary)' }
      : { background: 'var(--color-surface)', color: 'var(--color-text-primary)' };
  return (
    <div className="flex flex-wrap" style={{ gap: 'var(--spacing-xsmall)' }}>
      {items.map((p) => (
        <code
          key={p}
          className="mds-text-caption-tiny font-mono"
          style={{
            padding: '2px 6px',
            borderRadius: 'var(--radius-badge)',
            ...codeStyle,
          }}
        >
          {p}
        </code>
      ))}
    </div>
  );
}

function PlacementBlock({
  placement,
  recipes,
}: {
  placement: PlacementSpec;
  recipes?: Record<string, ComponentType>;
}) {
  return (
    <div className="flex flex-col" style={{ gap: 'var(--spacing-medium)' }}>
      {/* Where */}
      <div>
        <p
          className="mds-text-caption-tiny font-bold uppercase"
          style={{
            letterSpacing: '0.5px',
            color: 'var(--color-text-secondary)',
            marginBottom: 'var(--spacing-xsmall)',
          }}
        >
          Where on a screen
        </p>
        <ul
          className="mds-text-body list-disc pl-5"
          style={{ color: 'var(--color-text-primary)' }}
        >
          {placement.where.map((w) => (
            <li key={w} dangerouslySetInnerHTML={{ __html: w.replace(/`([^`]+)`/g, '<code>$1</code>') }} />
          ))}
        </ul>
      </div>

      {/* Spacing relations */}
      {placement.spacing && placement.spacing.length > 0 && (
        <div>
          <p
            className="mds-text-caption-tiny font-bold uppercase"
            style={{
              letterSpacing: '0.5px',
              color: 'var(--color-text-secondary)',
              marginBottom: 'var(--spacing-xsmall)',
            }}
          >
            Spacing to neighbors
          </p>
          <table className="mds-spec__tokens-table">
            <thead>
              <tr>
                <th style={{ width: 200 }}>Neighbor</th>
                <th style={{ width: 200 }}>Gap</th>
                <th>Reason</th>
              </tr>
            </thead>
            <tbody>
              {placement.spacing.map((s) => (
                <tr key={s.neighbor}>
                  <td style={{ color: 'var(--color-text-primary)' }}>{s.neighbor}</td>
                  <td><code>{s.gap}</code></td>
                  <td style={{ color: 'var(--color-text-secondary)' }}>{s.note ?? ''}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Compositions */}
      {placement.compositions && placement.compositions.length > 0 && (
        <div>
          <p
            className="mds-text-caption-tiny font-bold uppercase"
            style={{
              letterSpacing: '0.5px',
              color: 'var(--color-text-secondary)',
              marginBottom: 'var(--spacing-xsmall)',
            }}
          >
            Common compositions
          </p>
          <div className="flex flex-col" style={{ gap: 'var(--spacing-sm)' }}>
            {placement.compositions.map((comp) => {
              const Recipe = comp.recipeKey ? recipes?.[comp.recipeKey] : undefined;
              return (
                <div
                  key={comp.label}
                  className="flex items-center flex-wrap"
                  style={{ gap: 'var(--spacing-medium)' }}
                >
                  <div style={{ flex: '1 1 240px', minWidth: 240 }}>
                    <p
                      className="mds-text-body"
                      style={{ color: 'var(--color-text-primary)', fontWeight: 600 }}
                    >
                      {comp.label}
                    </p>
                    {comp.description && (
                      <p
                        className="mds-text-caption"
                        style={{ color: 'var(--color-text-secondary)' }}
                      >
                        {comp.description}
                      </p>
                    )}
                  </div>
                  {Recipe && (
                    <div
                      className="flex items-center"
                      style={{ gap: 'var(--spacing-xsmall)', flex: '0 0 auto' }}
                    >
                      <Recipe />
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

function TokensTable({ tokens }: { tokens: TokenUsage[] }) {
  return (
    <div style={{ overflowX: 'auto' }}>
      <table className="mds-spec__tokens-table">
        <thead>
          <tr>
            <th style={{ width: 220 }}>Token</th>
            <th>Where applied</th>
          </tr>
        </thead>
        <tbody>
          {tokens.map((t) => (
            <tr key={t.name}>
              <td>
                <code>{t.name}</code>
              </td>
              <td style={{ color: 'var(--color-text-secondary)' }}>{t.where}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function PropsTable({ props }: { props: PropDef[] }) {
  return (
    <div style={{ overflowX: 'auto' }}>
      <table className="mds-spec__props-table">
        <thead>
          <tr>
            <th>Prop</th>
            <th>Type</th>
            <th>Default</th>
            <th>Notes</th>
          </tr>
        </thead>
        <tbody>
          {props.map((p) => (
            <tr key={p.name}>
              <td>
                <code>{p.name}</code>
                {p.required && <span className="req" title="required">*</span>}
              </td>
              <td>
                <code>{p.type}</code>
              </td>
              <td>{p.default ? <code>{p.default}</code> : <span style={{ color: 'var(--color-text-secondary)' }}>—</span>}</td>
              <td style={{ color: 'var(--color-text-secondary)' }}>{p.notes ?? ''}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function GuidelineRow({
  entry,
  recipes,
}: {
  entry: GuidelineEntry;
  recipes?: Record<string, ComponentType>;
}) {
  const Recipe = entry.recipeKey ? recipes?.[entry.recipeKey] : undefined;
  return (
    <div className="mds-spec__guideline-row">
      <span
        className={`mds-spec__guideline-mark mds-spec__guideline-mark--${entry.kind}`}
      >
        {entry.kind === 'do' ? '✓ DO' : '✗ DON\'T'}
      </span>
      <p className="mds-spec__guideline-text">{entry.text}</p>
      {Recipe && (
        <div className="mds-spec__guideline-recipe">
          <Recipe />
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
export default function ComponentsPage() {
  const groups = getComponentsByCategory();
  const total = MDS_COMPONENTS.length;
  const rich = MDS_COMPONENTS.filter((c) => specCompleteness(c) === 'rich').length;

  const [active, setActive] = useState<ComponentCategory>(
    groups[0]?.category ?? 'Action',
  );

  return (
    <div
      className="max-w-5xl flex flex-col"
      style={{ gap: 'var(--spacing-large)' }}
    >
      <div className="flex flex-col" style={{ gap: 'var(--spacing-sm)' }}>
        <p
          className="mds-text-caption font-bold uppercase"
          style={{ letterSpacing: '1px', color: 'var(--color-text-secondary)' }}
        >
          Component Spec
        </p>
        <h1 className="mds-text-page-title" style={{ color: 'var(--color-text-primary)' }}>
          Components
        </h1>
        <p className="mds-text-body" style={{ color: 'var(--color-text-secondary)' }}>
          Spec-first manifest: this defines what each mds component <em>is</em>.
          Implementation lives under{' '}
          <code
            className="mds-text-caption"
            style={{
              background: 'var(--color-surface)',
              color: 'var(--color-primary)',
              padding: '1px 4px',
              borderRadius: 'var(--radius-badge)',
            }}
          >
            shared/packages/mds/core/
          </code>{' '}
          and follows these specs — not the other way around.
        </p>
        <p className="mds-text-body" style={{ color: 'var(--color-text-secondary)' }}>
          <strong>{total}</strong> components total ·{' '}
          <strong style={{ color: 'var(--color-success)' }}>{rich}</strong> with rich spec ·{' '}
          <strong style={{ color: 'var(--color-warning)' }}>{total - rich}</strong> need authoring
        </p>
      </div>

      {/* Tabs */}
      <nav
        className="flex flex-wrap sticky top-0 z-10"
        style={{
          gap: 'var(--spacing-small)',
          paddingTop: 'var(--spacing-small)',
          paddingBottom: 'var(--spacing-small)',
          background: 'var(--color-surface)',
          borderBottom: '1px solid var(--color-divider)',
        }}
        role="tablist"
      >
        {groups.map(({ category, items }) => {
          const isActive = active === category;
          return (
            <button
              key={category}
              role="tab"
              aria-selected={isActive}
              onClick={() => setActive(category)}
              className="mds-text-body flex items-center transition-colors"
              style={{
                padding: 'var(--spacing-small) var(--spacing-medium)',
                borderRadius: 'var(--radius-button)',
                gap: 'var(--spacing-small)',
                fontWeight: 'var(--typography-font-weight-medium)',
                background: isActive ? 'var(--color-primary)' : 'white',
                color: isActive ? 'white' : 'var(--color-text-primary)',
                border: isActive ? 'none' : '1px solid var(--color-divider)',
              }}
            >
              {category}
              <span
                className="mds-text-caption-tiny font-mono"
                style={{
                  padding: '2px 6px',
                  borderRadius: 'var(--radius-badge)',
                  background: isActive ? 'rgba(255,255,255,0.2)' : 'var(--color-surface)',
                  color: isActive ? 'white' : 'var(--color-text-secondary)',
                }}
              >
                {items.length}
              </span>
            </button>
          );
        })}
      </nav>

      {groups.map(({ category, items }) => (
        <section key={category} hidden={category !== active} aria-labelledby={`tab-${category}`}>
          <div className="flex flex-col" style={{ gap: 'var(--spacing-medium)' }}>
            {items.map((c) => (
              <ComponentSection key={c.name} c={c} />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
