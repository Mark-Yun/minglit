import { getScreenGroups, type ScreenDefinition, type ScreenKind } from '@/lib/screen-definitions';

const KIND_LABELS: Record<ScreenKind, string> = {
  route: 'route',
  'sub-component': 'sub',
  'spec-only': 'spec',
  'web-route': 'web',
};

const KIND_CLASS: Record<ScreenKind, string> = {
  route: 'bg-[var(--color-surface)] text-[var(--color-text-secondary)]',
  'sub-component': 'bg-[var(--color-primary)]/10 text-[var(--color-primary)]',
  'spec-only': 'bg-amber-50 text-amber-700',
  'web-route': 'bg-emerald-50 text-emerald-700',
};

function githubUrl(path: string): string {
  return `https://github.com/Mark-Yun/minglit/blob/dev/${path}`;
}

function KindBadge({ kind }: { kind: ScreenKind }) {
  return (
    <span
      className={`inline-flex h-5 items-center rounded-full px-2 text-[10px] font-bold uppercase ${KIND_CLASS[kind]}`}
    >
      {KIND_LABELS[kind]}
    </span>
  );
}

function ScreenNameCell({ screen }: { screen: ScreenDefinition }) {
  const specUrl = screen.specBasename ? `/specs/${screen.specBasename}/index.html` : null;
  const name = screen.screen ?? '—';

  return (
    <div className={screen.kind === 'sub-component' ? 'pl-6' : undefined}>
      {screen.kind === 'sub-component' ? (
        <span className="mr-1 text-[var(--color-text-secondary)]">↳</span>
      ) : null}
      {specUrl ? (
        <a
          href={specUrl}
          className="font-mono text-xs text-[var(--color-primary)] hover:underline"
          title="Open MDS spec"
        >
          {name}
        </a>
      ) : (
        <span className="font-mono text-xs text-[var(--color-text-secondary)]">{name}</span>
      )}
      {screen.note ? (
        <div className="mt-1 text-xs text-[var(--color-text-secondary)]">{screen.note}</div>
      ) : null}
    </div>
  );
}

function RouteCell({ screen }: { screen: ScreenDefinition }) {
  if (screen.routeSourcePath) {
    return (
      <a
        href={githubUrl(screen.routeSourcePath)}
        target="_blank"
        rel="noopener noreferrer"
        className="font-mono text-xs text-[var(--color-text-secondary)] hover:text-[var(--color-primary)] hover:underline"
        title={screen.routeSourcePath}
      >
        {screen.route} ↗
      </a>
    );
  }

  return <span className="font-mono text-xs text-[var(--color-text-secondary)]">{screen.route}</span>;
}

function CodeCell({ screen }: { screen: ScreenDefinition }) {
  if (!screen.codeSourcePath) {
    return <span className="text-xs text-[var(--color-divider)]">—</span>;
  }

  if (screen.codeSourceExists) {
    return (
      <a
        href={githubUrl(screen.codeSourcePath)}
        target="_blank"
        rel="noopener noreferrer"
        className="text-xs font-mono text-[var(--color-primary)] hover:underline"
        title={screen.codeSourcePath}
      >
        code ↗
      </a>
    );
  }

  return (
    <span className="font-mono text-xs text-[var(--color-text-secondary)]">
      planned: {screen.codeSourcePath}
    </span>
  );
}

function ScreenRow({ screen }: { screen: ScreenDefinition }) {
  const isSecondary = screen.kind === 'sub-component' || screen.kind === 'spec-only';

  return (
    <tr className={isSecondary ? 'bg-[var(--color-surface)]/30 hover:bg-[var(--color-surface)]' : 'hover:bg-[var(--color-surface)]'}>
      <td className="px-4 py-2">
        <ScreenNameCell screen={screen} />
      </td>
      <td className="px-4 py-2">
        <RouteCell screen={screen} />
      </td>
      <td className="px-4 py-2">
        <KindBadge kind={screen.kind} />
      </td>
      <td className="px-4 py-2">
        <CodeCell screen={screen} />
      </td>
    </tr>
  );
}

export default function RouteScreenIndex() {
  const groups = getScreenGroups();

  return (
    <div className="space-y-8">
      {groups.map(({ surface, screens }) => (
        <div key={surface.id} className="space-y-3" data-app={surface.id}>
          <div className="flex flex-wrap items-baseline gap-x-2 gap-y-1">
            <h3 className="text-lg font-bold text-[var(--color-text-primary)]">{surface.label}</h3>
            <span className="text-xs text-[var(--color-text-secondary)]">{screens.length} screens</span>
            <span className="basis-full text-xs text-[var(--color-text-secondary)]">
              {surface.description}
            </span>
          </div>
          <div className="overflow-hidden rounded-xl border border-[var(--color-divider)] bg-white">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-[var(--color-divider)] bg-[var(--color-surface)]">
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-[var(--color-text-primary)]">
                    Screen
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-[var(--color-text-primary)]">
                    Route / Surface
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-[var(--color-text-primary)]">
                    Kind
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-[var(--color-text-primary)]">
                    Code
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[var(--color-divider)]">
                {screens.map((screen) => (
                  <ScreenRow key={screen.id} screen={screen} />
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ))}
    </div>
  );
}
