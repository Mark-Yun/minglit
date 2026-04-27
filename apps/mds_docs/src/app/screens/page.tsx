const screens = [
  {
    id: 'profile_home',
    name: 'Profile Home',
    specPath: '/specs/profile_home.html',
    description: 'User profile home screen — verification badge, stats, party history.',
  },
];

export default function ScreensPage() {
  return (
    <div className="max-w-5xl space-y-10">
      {/* Header */}
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-2">
          Screen Specs
        </p>
        <h1 className="text-3xl font-bold text-[var(--color-text-primary)] mb-3">Screens</h1>
        <p className="text-[var(--color-text-secondary)]">
          Wireframe gallery. Each card shows a scaled preview; click{' '}
          <strong>Open full spec</strong> to view the annotated HTML in a new tab.
          Phase 1 has {screens.length} spec{screens.length !== 1 ? 's' : ''} — more coming in Phase 3.
        </p>
      </div>

      {/* Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8">
        {screens.map((screen) => (
          <div
            key={screen.id}
            className="bg-white rounded-2xl border border-[var(--color-divider)] overflow-hidden hover:shadow-md transition-shadow"
          >
            {/* Scaled iframe preview */}
            <div
              className="relative bg-[#e5e5e5] overflow-hidden"
              style={{ height: 260 }}
            >
              <div
                style={{
                  width: 375,
                  height: 650,
                  transform: 'scale(0.4)',
                  transformOrigin: 'top left',
                  pointerEvents: 'none',
                  position: 'absolute',
                  top: 0,
                  left: 0,
                }}
              >
                <iframe
                  src={screen.specPath}
                  title={screen.name}
                  width={375}
                  height={650}
                  className="border-0"
                  loading="lazy"
                />
              </div>
            </div>

            {/* Card body */}
            <div className="p-4 space-y-2">
              <h2 className="text-base font-bold text-[var(--color-text-primary)]">
                {screen.name}
              </h2>
              <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed">
                {screen.description}
              </p>
              <a
                href={screen.specPath}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 text-sm font-semibold text-[var(--color-primary)] hover:underline mt-1"
              >
                Open full spec
                <svg
                  width="12"
                  height="12"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
                  <polyline points="15 3 21 3 21 9" />
                  <line x1="10" y1="14" x2="21" y2="3" />
                </svg>
              </a>
            </div>
          </div>
        ))}
      </div>

      <p className="text-xs text-[var(--color-text-secondary)]">
        Source files: <code className="bg-[var(--color-surface)] px-1 rounded">docs/screen-specs/_demo/</code> →
        copied to <code className="bg-[var(--color-surface)] px-1 rounded">apps/mds_docs/public/specs/</code>.
      </p>
    </div>
  );
}
