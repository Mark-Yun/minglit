import {
  getRoutesByApp,
  widgetNameFor,
  screenSourceFor,
  hasDesignFor,
  designUrlFor,
} from '@/lib/flow-data';

const APP_LABELS = { user: 'app_user', partner: 'app_partner' } as const;

export default function RouteScreenIndex() {
  const routesByApp = getRoutesByApp();

  return (
    <div className="space-y-8">
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
                  return (
                    <tr key={route} className="hover:bg-[var(--color-surface)]">
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
    </div>
  );
}
