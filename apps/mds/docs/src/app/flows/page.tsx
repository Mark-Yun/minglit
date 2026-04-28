'use client';

import dynamic from 'next/dynamic';
import {
  RAW_DIAGRAMS,
  withWidgetLabels,
  getRoutesByApp,
  widgetNameFor,
  screenSourceFor,
  hasDesignFor,
  designUrlFor,
} from '@/lib/flow-data';

const MermaidDiagram = dynamic(() => import('@/components/MermaidDiagram'), {
  ssr: false,
  loading: () => (
    <div className="bg-white rounded-xl border border-[var(--color-divider)] p-8 text-center text-sm text-[var(--color-text-secondary)]">
      Loading diagram...
    </div>
  ),
});

const APP_LABELS = { user: 'app_user', partner: 'app_partner' } as const;

const diagrams = RAW_DIAGRAMS.map((d) => ({
  ...d,
  chart: withWidgetLabels(d.chart, d.app),
}));

export default function FlowsPage() {
  const routesByApp = getRoutesByApp();

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

      {/* Route → Screen index */}
      <section className="space-y-8 pt-4 border-t border-[var(--color-divider)]">
        <div>
          <p className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-2">
            Route → Screen Index
          </p>
          <h2 className="text-2xl font-bold text-[var(--color-text-primary)] mb-2">
            Routes &amp; screen widgets
          </h2>
          <p className="text-sm text-[var(--color-text-secondary)]">
            Every route resolves to a screen widget. The{' '}
            <code className="text-xs bg-[var(--color-surface)] px-1 rounded">source ↗</code>{' '}
            link goes directly to the widget&apos;s Dart file (not the routes file). Anchor IDs
            (e.g.{' '}
            <code className="text-xs bg-[var(--color-surface)] px-1 rounded">#user-HomeRoute</code>
            ) reserved for future screenshot integration.
          </p>
        </div>

        {(['user', 'partner'] as const).map((app) => (
          <div key={app} className="space-y-3" data-app={app}>
            <div className="flex items-baseline gap-2">
              <h3 className="text-lg font-bold text-[var(--color-text-primary)]">
                {APP_LABELS[app]}
              </h3>
              <span className="text-xs text-[var(--color-text-secondary)]">
                {routesByApp[app].length} routes
              </span>
            </div>
            <div className="bg-white rounded-xl border border-[var(--color-divider)] overflow-hidden">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-[var(--color-divider)] bg-[var(--color-surface)]">
                    <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-[var(--color-text-primary)]">
                      Route
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-[var(--color-text-primary)]">
                      Screen Widget
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-[var(--color-text-primary)]">
                      Design Spec
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[var(--color-divider)]">
                  {routesByApp[app].map((route) => {
                    const widget = widgetNameFor(app, route);
                    const screen = screenSourceFor(app, route);
                    const routesUrl = `https://github.com/Mark-Yun/minglit/blob/dev/apps/app_${app}/lib/src/routing/app_routes.dart`;
                    const designAnchor = `#design-${app}-${route}`;
                    return (
                      <tr
                        key={route}
                        className="hover:bg-[var(--color-surface)]"
                      >
                        <td className="px-4 py-2">
                          <a
                            href={routesUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="font-mono text-xs text-[var(--color-text-secondary)] hover:text-[var(--color-primary)] hover:underline"
                            title={`apps/app_${app}/lib/src/routing/app_routes.dart`}
                          >
                            {route} ↗
                          </a>
                        </td>
                        <td className="px-4 py-2">
                          {widget && screen.isWidget ? (
                            <a
                              href={screen.url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="font-mono text-xs text-[var(--color-primary)] hover:underline"
                              title={screen.filePath}
                            >
                              {widget} ↗
                            </a>
                          ) : (
                            <span className="font-mono text-xs text-[var(--color-text-secondary)]">
                              {widget ?? '—'}
                            </span>
                          )}
                        </td>
                        <td className="px-4 py-2">
                          {hasDesignFor(app, route) ? (
                            <a
                              href={designUrlFor(app, route) ?? '#'}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-xs font-mono text-[var(--color-primary)] hover:underline"
                              title="Open design spec in new tab"
                            >
                              spec ↗
                            </a>
                          ) : (
                            <span className="text-xs text-[var(--color-divider)]">—</span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        ))}
      </section>
    </div>
  );
}
