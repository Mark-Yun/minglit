import Link from 'next/link';

const sections = [
  {
    href: '/tokens',
    title: 'Tokens',
    description:
      'Color swatches, spacing scale, border radius, and typography — auto-generated from tokens/*.json.',
    badge: null,
    accent: 'var(--color-primary)',
  },
  {
    href: '/screens',
    title: 'Screens',
    description:
      'Interactive wireframe gallery. Click any screen to view the full spec in a new tab.',
    badge: '1 spec',
    accent: 'var(--color-success)',
  },
  {
    href: '/flows',
    title: 'Flows',
    description:
      'Navigation diagrams for app_user and app_partner, derived directly from GoRouter route definitions.',
    badge: '2 diagrams',
    accent: 'var(--color-info)',
  },
  {
    href: '#',
    title: 'Components',
    description:
      'Interactive component playground powered by mds_storybook (Flutter Web). Coming in Phase 2.',
    badge: 'coming soon',
    accent: 'var(--color-divider)',
  },
];

export default function HomePage() {
  return (
    <div className="max-w-4xl">
      {/* Hero */}
      <div className="mb-12">
        <p className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-2">
          Design Reference
        </p>
        <h1 className="text-4xl font-bold text-[var(--color-text-primary)] leading-tight mb-4">
          Minglit Design System
        </h1>
        <p className="text-lg text-[var(--color-text-secondary)] max-w-2xl leading-relaxed">
          A single source of truth for tokens, screen specs, navigation flows, and
          components. Built to dogfood the MDS token pipeline.
        </p>
      </div>

      {/* Card grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {sections.map(({ href, title, description, badge, accent }) => {
          const isDisabled = href === '#';
          const card = (
            <div
              className={`relative bg-white rounded-2xl p-6 border border-[var(--color-divider)] transition-all ${
                isDisabled
                  ? 'opacity-50 cursor-not-allowed'
                  : 'hover:shadow-md hover:-translate-y-0.5 cursor-pointer'
              }`}
            >
              {/* Accent bar */}
              <div
                className="w-8 h-1 rounded-full mb-4"
                style={{ backgroundColor: accent }}
              />
              <div className="flex items-start justify-between mb-2">
                <h2 className="text-xl font-bold text-[var(--color-text-primary)]">
                  {title}
                </h2>
                {badge && (
                  <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-[var(--color-surface)] text-[var(--color-text-secondary)] border border-[var(--color-divider)] ml-2 mt-0.5 shrink-0">
                    {badge}
                  </span>
                )}
              </div>
              <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed">
                {description}
              </p>
            </div>
          );

          return isDisabled ? (
            <div key={title}>{card}</div>
          ) : (
            <Link key={title} href={href} className="block">
              {card}
            </Link>
          );
        })}
      </div>

      {/* Meta */}
      <div className="mt-12 pt-6 border-t border-[var(--color-divider)]">
        <p className="text-xs text-[var(--color-text-secondary)]">
          Phase 1 &mdash; tokens.css pipeline + 4 pages. Source:{' '}
          <code className="bg-[var(--color-surface)] px-1 rounded text-[var(--color-primary)]">
            apps/mds_docs/
          </code>
        </p>
      </div>
    </div>
  );
}
