'use client';

import dynamic from 'next/dynamic';
import Link from 'next/link';
import { RAW_DIAGRAMS, withWidgetLabels } from '@/lib/flow-data';

const MermaidDiagram = dynamic(() => import('@/components/MermaidDiagram'), {
  ssr: false,
  loading: () => (
    <div className="bg-white rounded-xl border border-[var(--color-divider)] p-8 text-center text-sm text-[var(--color-text-secondary)]">
      Loading diagram...
    </div>
  ),
});

const diagrams = RAW_DIAGRAMS.map((d) => ({
  ...d,
  chart: withWidgetLabels(d.chart, d.app),
}));

export default function FlowsPage() {
  return (
    <div className="max-w-5xl space-y-12">
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-2">
          Navigation Flows
        </p>
        <h1 className="text-3xl font-bold text-[var(--color-text-primary)] mb-3">Flows</h1>
        <p className="text-[var(--color-text-secondary)]">
          Navigation graphs for <strong>app_user</strong> and <strong>app_partner</strong>.
          Edges are GoRouter transitions. Nodes show the actual{' '}
          <strong>screen widget</strong> class names (e.g.{' '}
          <code className="text-xs bg-[var(--color-surface)] px-1 rounded text-[var(--color-primary)]">
            EventDetailPage
          </code>
          ); each route&apos;s source link in the table below jumps to that widget&apos;s file.
        </p>
        <div className="mt-3 flex flex-wrap gap-x-6 gap-y-1 text-xs text-[var(--color-text-secondary)]">
          <span>
            <span className="inline-block align-middle w-6 h-px bg-[var(--color-text-secondary)] mr-2" />
            <strong className="text-[var(--color-text-primary)]">solid</strong> — direct route push
          </span>
          <span>
            <span
              className="inline-block align-middle w-6 h-px mr-2"
              style={{
                background:
                  'repeating-linear-gradient(to right, var(--color-text-secondary) 0 3px, transparent 3px 6px)',
              }}
            />
            <strong className="text-[var(--color-text-primary)]">dashed</strong> — overlay
            route (modal sheet · dialog) or embedded widget — same router stack, presented
            in-place
          </span>
        </div>
        <div className="mt-3 p-3 bg-[var(--color-surface)] rounded-lg border border-[var(--color-divider)] text-sm text-[var(--color-text-secondary)]">
          <strong className="text-[var(--color-warning)]">Manual update required:</strong> When
          routes change, update{' '}
          <code className="text-xs bg-white px-1 rounded">
            apps/mds/docs/src/lib/flow-data.ts
          </code>{' '}
          and regenerate{' '}
          <code className="text-xs bg-white px-1 rounded">
            apps/mds/docs/src/lib/route-pages.json
          </code>
          .
        </div>
      </div>

      {/* Diagrams */}
      {diagrams.map((d) => (
        <section key={d.id} className="space-y-3">
          <div>
            <h2 className="text-lg font-bold text-[var(--color-text-primary)]">{d.title}</h2>
            <p className="text-xs text-[var(--color-text-secondary)] mt-0.5">
              Generated from{' '}
              <code className="bg-[var(--color-surface)] px-1 rounded">{d.attribution}</code>
            </p>
          </div>
          <MermaidDiagram chart={d.chart} id={d.id} />
        </section>
      ))}

      {/* Pointer to dedicated index page */}
      <section className="pt-4 border-t border-[var(--color-divider)]">
        <p className="text-sm text-[var(--color-text-secondary)]">
          Looking for the full route → widget → spec table? See{' '}
          <Link
            href="/screens"
            className="text-[var(--color-primary)] font-semibold hover:underline"
          >
            /screens
          </Link>
          .
        </p>
      </section>
    </div>
  );
}
