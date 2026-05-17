import { MdsIcons, type MdsIconName } from '@/lib/mds-icons-react';
// Fix #2537: Vercel 빌드는 apps/mds/docs/ 만 업로드해서 shared/ 접근 불가.
// manifest.json + SVG를 vendor 파일로 정적 포함 (npm run icons:sync-data 로 갱신).
import { MDS_ICONS_DATA, type IconEntry } from '@/lib/mds-icons-data';

// ---------------------------------------------------------------------------
// Icon card component
// ---------------------------------------------------------------------------
function IconCard({ icon }: { icon: IconEntry }) {
  const Component = MdsIcons[icon.name as MdsIconName];

  return (
    <div className="bg-white rounded-xl border border-[var(--color-divider)] overflow-hidden hover:shadow-sm transition-shadow">
      {/* Live React component preview */}
      <div
        className="flex items-center justify-center h-24 bg-[var(--color-surface)]"
        style={{ color: 'var(--color-text-primary)' }}
      >
        {Component ? <Component size={32} /> : null}
      </div>

      <div className="p-3 space-y-2">
        <p className="text-xs font-semibold text-[var(--color-text-primary)] font-mono truncate">
          {icon.name}
        </p>
        <code className="text-[10px] text-[var(--color-text-secondary)] bg-[var(--color-surface)] px-2 py-1 rounded block truncate">
          MdsIcons.{icon.camel}(size: 24)
        </code>
        <code className="text-[10px] text-[#0d9488] bg-[#ecfdf5] px-2 py-1 rounded block truncate">
          &lt;{icon.name.replace(/_([a-z])/g, (_, c) => c.toUpperCase()).replace(/^./, c => c.toUpperCase())} size={'{24}'} /&gt;
        </code>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Page (Server Component — reads files at build time)
// ---------------------------------------------------------------------------
export default function IconsPage() {
  const icons = MDS_ICONS_DATA;

  return (
    <div className="max-w-5xl space-y-16">
      {/* Header */}
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-2">
          Design System
        </p>
        <h1 className="text-3xl font-bold text-[var(--color-text-primary)] mb-3">
          Icons
          <span className="ml-3 text-sm font-normal text-[var(--color-text-secondary)]">
            {icons.length} icons
          </span>
        </h1>
        <p className="text-[var(--color-text-secondary)] mb-2">
          Auto-generated from{' '}
          <code className="text-xs bg-[var(--color-surface)] px-1 rounded text-[var(--color-primary)]">
            shared/packages/mds/icons/icons/*.svg
          </code>
          . SVG sources are from{' '}
          <a
            href="https://lucide.dev"
            target="_blank"
            rel="noopener noreferrer"
            className="text-[var(--color-primary)] underline"
          >
            Lucide
          </a>{' '}
          (ISC license), optimised with svgo for{' '}
          <code className="text-xs bg-[var(--color-surface)] px-1 rounded text-[var(--color-primary)]">
            currentColor
          </code>{' '}
          theme awareness.
        </p>
        <p className="text-sm text-[var(--color-text-secondary)]">
          Add a new icon: place{' '}
          <code className="text-xs bg-[var(--color-surface)] px-1 rounded text-[var(--color-primary)]">
            name.svg
          </code>{' '}
          in{' '}
          <code className="text-xs bg-[var(--color-surface)] px-1 rounded text-[var(--color-primary)]">
            icons/
          </code>{' '}
          then run{' '}
          <code className="text-xs bg-[var(--color-surface)] px-1 rounded text-[var(--color-primary)]">
            npm run build
          </code>
          .
        </p>
      </div>

      {/* Migration callout */}
      <div className="bg-[var(--color-surface)] border border-[var(--color-divider)] rounded-xl p-4 text-sm">
        <p className="font-semibold text-[var(--color-text-primary)] mb-2">
          Migration from Material Icons
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 font-mono text-xs">
          <div>
            <p className="text-[var(--color-text-secondary)] mb-1">Before</p>
            <code className="block bg-white border border-[var(--color-divider)] rounded px-3 py-2 text-[var(--color-text-primary)]">
              Icon(Icons.person, size: 24)
            </code>
          </div>
          <div>
            <p className="text-[var(--color-text-secondary)] mb-1">After</p>
            <code className="block bg-white border border-[var(--color-divider)] rounded px-3 py-2 text-[var(--color-primary)]">
              MdsIcons.person(size: 24)
            </code>
          </div>
        </div>
      </div>

      {/* Icon grid */}
      <section>
        <h2 className="text-xl font-bold text-[var(--color-text-primary)] mb-6">
          Icon Catalogue
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {icons.map((icon) => (
            <IconCard key={icon.name} icon={icon} />
          ))}
        </div>
      </section>

      {/* Lucide mapping table */}
      <section>
        <h2 className="text-xl font-bold text-[var(--color-text-primary)] mb-4">
          Source mapping
        </h2>
        <p className="text-sm text-[var(--color-text-secondary)] mb-4">
          Material Icons → Lucide → mds_icons accessor
        </p>
        <div className="bg-white rounded-xl border border-[var(--color-divider)] overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-[var(--color-divider)] bg-[var(--color-surface)]">
                <th className="px-4 py-3 text-left font-semibold text-[var(--color-text-primary)] text-xs uppercase tracking-wider">
                  MdsIcons accessor
                </th>
                <th className="px-4 py-3 text-left font-semibold text-[var(--color-text-primary)] text-xs uppercase tracking-wider">
                  Material equivalent
                </th>
                <th className="px-4 py-3 text-left font-semibold text-[var(--color-text-primary)] text-xs uppercase tracking-wider hidden sm:table-cell">
                  Lucide source
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[var(--color-divider)]">
              {icons.map((icon) => (
                <tr key={icon.name} className="hover:bg-[var(--color-surface)]">
                  <td className="px-4 py-3 font-mono text-[var(--color-primary)] text-xs">
                    MdsIcons.{icon.camel}
                  </td>
                  <td className="px-4 py-3 font-mono text-[var(--color-text-secondary)] text-xs">
                    Icons.{icon.name}
                  </td>
                  <td className="px-4 py-3 text-[var(--color-text-secondary)] text-xs hidden sm:table-cell">
                    {icon.name}.svg
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
