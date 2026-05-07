/**
 * Shared atoms for component inline visual specs.
 *
 * Every per-component spec (e.g. MinglitButtonSpec, MinglitChipSpec) follows
 * the same skeleton:
 *   <SpecRoot>
 *     <SpecHero>...</SpecHero>
 *     <SpecAnatomy>...</SpecAnatomy>          (optional)
 *     <SpecSection title="Variants"><PreviewTable .../></SpecSection>
 *     <SpecSection title="Sizes"><PreviewTable .../></SpecSection>
 *     <SpecSection title="States"><PreviewTable .../></SpecSection>
 *   </SpecRoot>
 *
 * Up to 2026-05-01 each spec file re-defined PreviewTable, PreviewRow, and
 * inlined the same `<div className="mds-spec__hero">` / `mds-spec__anatomy`
 * boilerplate. This file extracts those into a single source.
 *
 * Migrating an existing spec:
 *   1. Replace the local `interface PreviewRow` and `function PreviewTable`
 *      with `import { PreviewTable, type PreviewRow } from './_atoms'`.
 *   2. Wrap the outer JSX with `<SpecRoot>` instead of `<div className="mds-spec">`.
 *   3. Replace `<div><p className="mds-spec__label">X</p><div className="mds-spec__panel">...</div></div>`
 *      with `<SpecSection title="X">...</SpecSection>`.
 *   4. Replace the hero/anatomy wrappers with <SpecHero> / <SpecAnatomy>.
 */

import type { CSSProperties, ReactNode } from 'react';

// ---------------------------------------------------------------------------
// Root — outer container of every inline spec.
// ---------------------------------------------------------------------------
export function SpecRoot({ children }: { children: ReactNode }) {
  return <div className="mds-spec">{children}</div>;
}

// ---------------------------------------------------------------------------
// Hero — one big representative preview at default size.
// Centered, fills the panel. Pass a single component as children.
// ---------------------------------------------------------------------------
export function SpecHero({ children }: { children: ReactNode }) {
  return <div className="mds-spec__hero">{children}</div>;
}

// ---------------------------------------------------------------------------
// Section — micro-label header + soft panel. Used for Variants / Sizes /
// States / etc. Pass `wrap={false}` if children bring their own panel.
// ---------------------------------------------------------------------------
export function SpecSection({
  title,
  children,
  wrap = true,
}: {
  title: string;
  children: ReactNode;
  wrap?: boolean;
}) {
  return (
    <div>
      <p className="mds-spec__label">{title}</p>
      {wrap ? <div className="mds-spec__panel">{children}</div> : children}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Anatomy — preview surrounded by absolutely-positioned annotation labels.
// Pass `subject` (the centered component) and `labels` (each with position
// and text). Each label is rendered as a `mds-spec__anatomy-label` span.
// ---------------------------------------------------------------------------
export interface AnatomyLabel {
  /** Label text (e.g. `radius-button (12px)`). */
  text: string;
  /** Absolute position relative to the anatomy box. */
  style: CSSProperties;
}

export function SpecAnatomy({
  subject,
  labels,
  subjectClassName,
  minHeight,
}: {
  subject: ReactNode;
  labels: AnatomyLabel[];
  /** Optional class on the inner subject wrapper (e.g. `mds-spec__anatomy-btn`). */
  subjectClassName?: string;
  /** Optional explicit min-height for the anatomy box. */
  minHeight?: number;
}) {
  return (
    <SpecSection title="Anatomy" wrap={false}>
      <div
        className="mds-spec__anatomy"
        style={minHeight !== undefined ? { minHeight } : undefined}
      >
        {subjectClassName ? (
          <div className={subjectClassName}>{subject}</div>
        ) : (
          subject
        )}
        {labels.map((l, i) => (
          <span key={i} className="mds-spec__anatomy-label" style={l.style}>
            {l.text}
          </span>
        ))}
      </div>
    </SpecSection>
  );
}

// ---------------------------------------------------------------------------
// PreviewTable — name | preview | description rows.
// Used for Variants / Sizes / States / Slots / etc.
// ---------------------------------------------------------------------------
export interface PreviewRow {
  name: string;
  description: string;
  preview: ReactNode;
}

export function PreviewTable({
  rows,
  previewLabel = 'Preview',
}: {
  rows: PreviewRow[];
  previewLabel?: string;
}) {
  return (
    <table className="mds-spec__preview-table">
      <thead>
        <tr>
          <th style={{ width: 130 }}>Name</th>
          <th style={{ width: 220 }}>{previewLabel}</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((r) => (
          <tr key={r.name}>
            <td>
              <code>{r.name}</code>
            </td>
            <td>{r.preview}</td>
            <td style={{ color: 'var(--color-text-secondary)' }}>{r.description}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
