import {
  getColorTokens,
  getSpacingTokens,
  getRadiusTokens,
  getTypographyTokens,
} from '@/lib/tokens';

// ---------------------------------------------------------------------------
// Color swatch card
// ---------------------------------------------------------------------------
function ColorCard({
  name,
  hex,
  dartName,
  description,
}: {
  name: string;
  hex: string;
  dartName: string;
  description: string;
}) {
  return (
    <div className="bg-white rounded-xl border border-[var(--color-divider)] overflow-hidden hover:shadow-sm transition-shadow">
      {/* Color preview */}
      <div
        className="h-14 w-full"
        style={{ backgroundColor: hex }}
        title={hex}
      />
      <div className="p-3 space-y-1">
        <p className="text-xs font-semibold text-[var(--color-text-primary)] truncate">{name}</p>
        <p className="text-xs text-[var(--color-text-secondary)] font-mono uppercase">{hex}</p>
        <code className="text-xs text-[var(--color-primary)] bg-[var(--color-surface)] px-1 py-0.5 rounded block truncate">
          {dartName}
        </code>
        {description && (
          <p className="text-xs text-[var(--color-text-secondary)] leading-tight">{description}</p>
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Page (Server Component — reads files at build time)
// ---------------------------------------------------------------------------
export default function TokensPage() {
  const colors = getColorTokens();
  const spacing = getSpacingTokens();
  const radii = getRadiusTokens();
  const typography = getTypographyTokens();

  const semanticColors = colors.filter((c) => c.group === 'semantic');
  const darkColors = colors.filter((c) => c.group === 'dark');
  const partnerColors = colors.filter((c) => c.group === 'partner');

  const maxSpacing = Math.max(...spacing.map((s) => s.value));

  return (
    <div className="max-w-5xl space-y-16">
      {/* Header */}
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-2">
          Design Tokens
        </p>
        <h1 className="text-3xl font-bold text-[var(--color-text-primary)] mb-3">Tokens</h1>
        <p className="text-[var(--color-text-secondary)]">
          Auto-generated from{' '}
          <code className="text-xs bg-[var(--color-surface)] px-1 rounded text-[var(--color-primary)]">
            shared/packages/mds_tokens/tokens/*.json
          </code>
          . Editing the JSON files regenerates this page on next build.
        </p>
      </div>

      {/* ------------------------------------------------------------------ */}
      {/* Colors                                                               */}
      {/* ------------------------------------------------------------------ */}
      <section>
        <h2 className="text-xl font-bold text-[var(--color-text-primary)] mb-1">
          Colors
          <span className="ml-2 text-sm font-normal text-[var(--color-text-secondary)]">
            {colors.length} tokens
          </span>
        </h2>
        <p className="text-sm text-[var(--color-text-secondary)] mb-6">
          Semantic brand colors, dark-mode variants, and partner brand palette.
        </p>

        {/* Semantic */}
        <h3 className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-3">
          Semantic / Brand
        </h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3 mb-8">
          {semanticColors.map((c) => (
            <ColorCard key={c.name} {...c} />
          ))}
        </div>

        {/* Dark */}
        <h3 className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-3">
          Dark Mode
        </h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3 mb-8">
          {darkColors.map((c) => (
            <ColorCard key={c.name} {...c} />
          ))}
        </div>

        {/* Partner */}
        <h3 className="text-xs font-bold uppercase tracking-widest text-[var(--color-text-secondary)] mb-3">
          Partner Brand
        </h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3">
          {partnerColors.map((c) => (
            <ColorCard key={c.name} {...c} />
          ))}
        </div>
      </section>

      {/* ------------------------------------------------------------------ */}
      {/* Spacing                                                              */}
      {/* ------------------------------------------------------------------ */}
      <section>
        <h2 className="text-xl font-bold text-[var(--color-text-primary)] mb-1">
          Spacing
          <span className="ml-2 text-sm font-normal text-[var(--color-text-secondary)]">
            {spacing.length} tokens
          </span>
        </h2>
        <p className="text-sm text-[var(--color-text-secondary)] mb-6">
          Pixel values used for padding, margin, and gap. Bars show relative size.
        </p>
        <div className="bg-white rounded-xl border border-[var(--color-divider)] overflow-hidden divide-y divide-[var(--color-divider)]">
          {spacing.map((s) => (
            <div key={s.name} className="flex items-center gap-4 px-4 py-3">
              <div className="w-40 shrink-0">
                <p className="text-sm font-semibold text-[var(--color-text-primary)] font-mono">{s.name}</p>
                <p className="text-xs text-[var(--color-text-secondary)]">{s.description}</p>
              </div>
              <div className="text-sm font-mono text-[var(--color-text-secondary)] w-12 shrink-0">
                {s.value}px
              </div>
              <div className="flex-1 min-w-0">
                <div
                  className="h-4 rounded-sm"
                  style={{
                    width: `${Math.max(2, (s.value / maxSpacing) * 100)}%`,
                    backgroundColor: 'var(--color-primary)',
                    opacity: 0.6,
                  }}
                />
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ------------------------------------------------------------------ */}
      {/* Radius                                                               */}
      {/* ------------------------------------------------------------------ */}
      <section>
        <h2 className="text-xl font-bold text-[var(--color-text-primary)] mb-1">
          Border Radius
          <span className="ml-2 text-sm font-normal text-[var(--color-text-secondary)]">
            {radii.length} tokens
          </span>
        </h2>
        <p className="text-sm text-[var(--color-text-secondary)] mb-6">
          Radius values applied to cards, buttons, dialogs, chips, and badges.
        </p>
        <div className="flex flex-wrap gap-6">
          {radii.map((r) => (
            <div key={r.name} className="flex flex-col items-center gap-2">
              <div
                className="w-20 h-20 bg-[var(--color-primary)] opacity-20 border-2 border-[var(--color-primary)]"
                style={{ borderRadius: `${Math.min(r.value, 40)}px` }}
              />
              <div className="text-center">
                <p className="text-xs font-semibold text-[var(--color-text-primary)] font-mono">{r.name}</p>
                <p className="text-xs text-[var(--color-text-secondary)]">{r.value}px</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ------------------------------------------------------------------ */}
      {/* Typography                                                           */}
      {/* ------------------------------------------------------------------ */}
      <section>
        <h2 className="text-xl font-bold text-[var(--color-text-primary)] mb-1">
          Typography
          <span className="ml-2 text-sm font-normal text-[var(--color-text-secondary)]">
            {typography.length} tokens
          </span>
        </h2>
        <p className="text-sm text-[var(--color-text-secondary)] mb-6">
          Font family, sizes, and weights from the MDS token scale.
        </p>
        <div className="bg-white rounded-xl border border-[var(--color-divider)] overflow-hidden divide-y divide-[var(--color-divider)]">
          {typography.map((t) => (
            <div key={t.name} className="flex items-center gap-4 px-4 py-4">
              <div className="w-56 shrink-0">
                <p className="text-xs font-semibold text-[var(--color-text-primary)] font-mono">{t.name}</p>
                <p className="text-xs text-[var(--color-text-secondary)] capitalize">{t.type}</p>
              </div>
              <div className="text-xs font-mono text-[var(--color-text-secondary)] w-20 shrink-0">
                {String(t.value)}
              </div>
              <div className="flex-1 min-w-0">
                {t.type === 'fontSize' ? (
                  <span
                    className="text-[var(--color-text-primary)]"
                    style={{ fontSize: `${t.value}px` }}
                  >
                    Aa — {t.description}
                  </span>
                ) : t.type === 'fontWeight' ? (
                  <span
                    className="text-base text-[var(--color-text-primary)]"
                    style={{ fontWeight: Number(t.value) }}
                  >
                    Minglit — {t.description}
                  </span>
                ) : (
                  <span className="text-sm text-[var(--color-text-secondary)]">
                    {String(t.value)}
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
