'use client';

import { useState, type ComponentType } from 'react';
import {
  getComponentsByCategory,
  MDS_COMPONENTS,
  type ComponentCategory,
  type ComponentSpec,
} from '@/lib/components';
import MinglitButtonSpec from '@/components/specs/MinglitButtonSpec';

/**
 * Inline visual specs registered by component name.
 * Add a new entry here when you author a new spec component.
 */
const INLINE_SPECS: Record<string, ComponentType> = {
  MinglitButton: MinglitButtonSpec,
};

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

function MicroLabel({ children }: { children: React.ReactNode }) {
  return (
    <p
      className="mds-text-caption-tiny font-bold uppercase mb-2"
      style={{
        letterSpacing: '0.5px',
        color: 'var(--color-text-secondary)',
      }}
    >
      {children}
    </p>
  );
}

function ComponentSection({ c }: { c: ComponentSpec }) {
  const completeness = specCompleteness(c);
  const SpecComponent = INLINE_SPECS[c.name];
  return (
    <article
      id={c.name}
      className="bg-white scroll-mt-20 flex flex-col"
      style={{
        borderRadius: 'var(--radius-card)',
        border: '1px solid var(--color-divider)',
        padding: 'var(--spacing-large)',
        gap: 'var(--spacing-medium)',
      }}
    >
      <header
        className="flex items-baseline justify-between flex-wrap"
        style={{
          gap: 'var(--spacing-small)',
          paddingBottom: 'var(--spacing-sm)',
          borderBottom: '1px solid var(--color-divider)',
        }}
      >
        <div className="flex items-baseline flex-wrap" style={{ gap: 'var(--spacing-sm)' }}>
          <h2 className="mds-text-section-title font-mono">{c.name}</h2>
          <span className="mds-text-caption" style={{ color: 'var(--color-text-secondary)' }}>
            {c.category}
          </span>
        </div>
        <CompletenessBadge state={completeness} />
      </header>

      <p
        className="mds-text-body"
        style={{ color: 'var(--color-text-secondary)' }}
      >
        {c.purpose}
      </p>

      {SpecComponent && (
        <div>
          <MicroLabel>Visual</MicroLabel>
          <SpecComponent />
        </div>
      )}

      {!SpecComponent && c.visualSpec && (
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

      <div
        className="grid grid-cols-1 md:grid-cols-2"
        style={{ gap: 'var(--spacing-medium)' }}
      >
        {c.variants && c.variants.length > 0 && (
          <Field label="Variants" items={c.variants} accent="primary" />
        )}
        {c.states && c.states.length > 0 && (
          <Field label="States" items={c.states} accent="muted" />
        )}
        {c.props && c.props.length > 0 && (
          <Field label="Props" items={c.props} accent="muted" />
        )}
        {c.tokens && c.tokens.length > 0 && (
          <Field label="Tokens" items={c.tokens} accent="muted" />
        )}
      </div>

      {c.accessibility && c.accessibility.length > 0 && (
        <div>
          <MicroLabel>Accessibility</MicroLabel>
          <ul
            className="mds-text-body list-disc pl-5"
            style={{ color: 'var(--color-text-secondary)' }}
          >
            {c.accessibility.map((a) => (
              <li key={a}>{a}</li>
            ))}
          </ul>
        </div>
      )}

      {c.guidelines && c.guidelines.length > 0 && (
        <div>
          <MicroLabel>Guidelines</MicroLabel>
          <ul
            className="mds-text-body list-disc pl-5"
            style={{ color: 'var(--color-text-secondary)' }}
          >
            {c.guidelines.map((g) => (
              <li key={g}>{g}</li>
            ))}
          </ul>
        </div>
      )}

      {c.usedIn && c.usedIn.length > 0 && (
        <div
          style={{
            paddingTop: 'var(--spacing-sm)',
            borderTop: '1px dashed var(--color-divider)',
          }}
        >
          <MicroLabel>Used in</MicroLabel>
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
        </div>
      )}
    </article>
  );
}

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

function Field({
  label,
  items,
  accent,
}: {
  label: string;
  items: string[];
  accent: 'primary' | 'muted';
}) {
  const codeStyle: React.CSSProperties =
    accent === 'primary'
      ? {
          background: 'rgba(153, 0, 255, 0.1)',
          color: 'var(--color-primary)',
        }
      : {
          background: 'var(--color-surface)',
          color: 'var(--color-text-primary)',
        };
  return (
    <div>
      <MicroLabel>{label}</MicroLabel>
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
    </div>
  );
}

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
          style={{
            letterSpacing: '1px',
            color: 'var(--color-text-secondary)',
          }}
        >
          Component Spec
        </p>
        <h1
          className="mds-text-page-title"
          style={{ color: 'var(--color-text-primary)' }}
        >
          Components
        </h1>
        <p
          className="mds-text-body"
          style={{ color: 'var(--color-text-secondary)' }}
        >
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
        <p
          className="mds-text-body"
          style={{ color: 'var(--color-text-secondary)' }}
        >
          <strong>{total}</strong> components total ·{' '}
          <strong style={{ color: 'var(--color-success)' }}>{rich}</strong> with rich spec ·{' '}
          <strong style={{ color: 'var(--color-warning)' }}>{total - rich}</strong> need authoring
        </p>
        <div
          className="mds-text-body"
          style={{
            background: 'var(--color-surface)',
            border: '1px solid var(--color-divider)',
            borderRadius: 'var(--radius-card)',
            padding: 'var(--spacing-sm)',
            color: 'var(--color-text-secondary)',
          }}
        >
          <strong style={{ color: 'var(--color-warning)' }}>Authoring flow:</strong>{' '}
          add the spec entry in{' '}
          <code
            className="mds-text-caption"
            style={{
              background: 'white',
              padding: '1px 4px',
              borderRadius: 'var(--radius-badge)',
            }}
          >
            apps/mds/docs/src/lib/components.ts
          </code>{' '}
          first (purpose, variants, states, tokens, guidelines), then implement the
          Dart widget against it.
        </div>
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

      {/* All categories rendered, only active visible.
          DOM keeps all content for AI scraping. */}
      {groups.map(({ category, items }) => (
        <section
          key={category}
          hidden={category !== active}
          aria-labelledby={`tab-${category}`}
        >
          <div
            className="flex flex-col"
            style={{ gap: 'var(--spacing-medium)' }}
          >
            {items.map((c) => (
              <ComponentSection key={c.name} c={c} />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
