'use client';

import { useState } from 'react';
import {
  TEXT_STYLES,
  type ColorToken,
  type SpacingToken,
  type RadiusToken,
  type TypographyToken,
  type TextStyle,
} from '@/lib/tokens-shared';

type TabId = 'colors' | 'spacing' | 'radius' | 'typography';

interface Props {
  colors: ColorToken[];
  spacing: SpacingToken[];
  radii: RadiusToken[];
  typography: TypographyToken[];
}

const TOKEN_DIR_REF = 'shared/packages/mds/tokens/tokens/*.json';

export default function TokensPageClient({ colors, spacing, radii, typography }: Props) {
  const [active, setActive] = useState<TabId>('colors');

  const semanticColors = colors.filter((c) => c.group === 'semantic');
  const darkColors = colors.filter((c) => c.group === 'dark');
  const partnerColors = colors.filter((c) => c.group === 'partner');
  const maxSpacing = Math.max(...spacing.map((s) => s.value));

  const tabs: Array<{ id: TabId; label: string; count: string }> = [
    { id: 'colors', label: 'Colors', count: `${colors.length}` },
    { id: 'spacing', label: 'Spacing', count: `${spacing.length}` },
    { id: 'radius', label: 'Radius', count: `${radii.length}` },
    { id: 'typography', label: 'Typography', count: `${typography.length}+${TEXT_STYLES.length}` },
  ];

  return (
    <div
      className="max-w-5xl flex flex-col"
      style={{ gap: 'var(--spacing-large)' }}
    >
      {/* Header */}
      <div className="flex flex-col" style={{ gap: 'var(--spacing-sm)' }}>
        <p
          className="mds-text-caption font-bold uppercase"
          style={{ letterSpacing: '1px', color: 'var(--color-text-secondary)' }}
        >
          Design Tokens
        </p>
        <h1
          className="mds-text-page-title"
          style={{ color: 'var(--color-text-primary)' }}
        >
          Tokens
        </h1>
        <p
          className="mds-text-body"
          style={{ color: 'var(--color-text-secondary)' }}
        >
          Auto-generated from{' '}
          <code
            className="mds-text-caption"
            style={{
              background: 'var(--color-surface)',
              color: 'var(--color-primary)',
              padding: '1px 4px',
              borderRadius: 'var(--radius-badge)',
            }}
          >
            {TOKEN_DIR_REF}
          </code>
          . Editing the JSON files regenerates this page on next build.
        </p>
      </div>

      {/* Tabs */}
      <nav
        role="tablist"
        className="flex flex-wrap sticky top-0 z-10"
        style={{
          gap: 'var(--spacing-small)',
          paddingTop: 'var(--spacing-small)',
          paddingBottom: 'var(--spacing-small)',
          background: 'var(--color-surface)',
          borderBottom: '1px solid var(--color-divider)',
        }}
      >
        {tabs.map((t) => {
          const isActive = active === t.id;
          return (
            <button
              key={t.id}
              role="tab"
              aria-selected={isActive}
              onClick={() => setActive(t.id)}
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
              {t.label}
              <span
                className="mds-text-caption-tiny font-mono"
                style={{
                  padding: '2px 6px',
                  borderRadius: 'var(--radius-badge)',
                  background: isActive ? 'rgba(255,255,255,0.2)' : 'var(--color-surface)',
                  color: isActive ? 'white' : 'var(--color-text-secondary)',
                }}
              >
                {t.count}
              </span>
            </button>
          );
        })}
      </nav>

      {/* Colors */}
      <section hidden={active !== 'colors'} aria-labelledby="tab-colors">
        <SectionIntro
          subtitle="Semantic brand colors, dark-mode variants, and partner brand palette."
        />
        <SubsectionHeader>Semantic / Brand</SubsectionHeader>
        <ColorGrid items={semanticColors} />
        <SubsectionHeader top>Dark Mode</SubsectionHeader>
        <ColorGrid items={darkColors} />
        <SubsectionHeader top>Partner Brand</SubsectionHeader>
        <ColorGrid items={partnerColors} />
      </section>

      {/* Spacing */}
      <section hidden={active !== 'spacing'} aria-labelledby="tab-spacing">
        <SectionIntro subtitle="Pixel values used for padding, margin, and gap. Bars show relative size." />
        <Card>
          {spacing.map((s) => (
            <div
              key={s.name}
              className="flex items-center"
              style={{
                gap: 'var(--spacing-medium)',
                padding: 'var(--spacing-sm) var(--spacing-medium)',
                borderTop: '1px solid var(--color-divider)',
              }}
            >
              <div className="w-40 shrink-0">
                <p className="mds-text-body font-mono" style={{ color: 'var(--color-text-primary)', fontWeight: 600 }}>
                  {s.name}
                </p>
                <p className="mds-text-caption" style={{ color: 'var(--color-text-secondary)' }}>
                  {s.description}
                </p>
              </div>
              <div className="mds-text-body font-mono w-12 shrink-0" style={{ color: 'var(--color-text-secondary)' }}>
                {s.value}px
              </div>
              <div className="flex-1 min-w-0">
                <div
                  className="h-4"
                  style={{
                    width: `${Math.max(2, (s.value / maxSpacing) * 100)}%`,
                    backgroundColor: 'var(--color-primary)',
                    opacity: 0.6,
                    borderRadius: 'var(--radius-small)',
                  }}
                />
              </div>
            </div>
          ))}
        </Card>
      </section>

      {/* Radius */}
      <section hidden={active !== 'radius'} aria-labelledby="tab-radius">
        <SectionIntro subtitle="Radius values applied to cards, buttons, dialogs, chips, and badges." />
        <div className="flex flex-wrap" style={{ gap: 'var(--spacing-large)' }}>
          {radii.map((r) => (
            <div key={r.name} className="flex flex-col items-center" style={{ gap: 'var(--spacing-small)' }}>
              <div
                className="w-20 h-20"
                style={{
                  background: 'var(--color-primary)',
                  opacity: 0.2,
                  border: '2px solid var(--color-primary)',
                  borderRadius: `${Math.min(r.value, 40)}px`,
                }}
              />
              <div className="text-center">
                <p
                  className="mds-text-caption font-mono"
                  style={{ color: 'var(--color-text-primary)', fontWeight: 600 }}
                >
                  {r.name}
                </p>
                <p className="mds-text-caption" style={{ color: 'var(--color-text-secondary)' }}>
                  {r.value}px
                </p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Typography */}
      <section hidden={active !== 'typography'} aria-labelledby="tab-typography">
        <SectionIntro
          subtitle={
            <>
              Primitive scales (family / size / weight / line-height) and the composite
              text styles built on top of them. Use text styles by class
              (e.g. <code className="font-mono mds-text-caption" style={{ background: 'var(--color-surface)', padding: '1px 4px', borderRadius: 'var(--radius-badge)' }}>.mds-text-body</code>);
              drop to primitives only when composing a new style.
            </>
          }
        />

        <TypographySubsection title="Font Family" hint="2 tokens — body vs display.">
          {typography.filter((t) => t.type === 'fontFamily').map((t) => (
            <FontFamilyRow key={t.name} t={t} />
          ))}
        </TypographySubsection>

        <TypographySubsection title="Font Size" hint="11 tokens — purpose-named.">
          {typography.filter((t) => t.type === 'fontSize').map((t) => (
            <FontSizeRow key={t.name} t={t} />
          ))}
        </TypographySubsection>

        <TypographySubsection title="Font Weight" hint="4 weights.">
          {typography.filter((t) => t.type === 'fontWeight').map((t) => (
            <FontWeightRow key={t.name} t={t} />
          ))}
        </TypographySubsection>

        <TypographySubsection title="Line Height" hint="3 multipliers — applied to two lines of body text.">
          {typography.filter((t) => t.type === 'lineHeight').map((t) => (
            <LineHeightRow key={t.name} t={t} />
          ))}
        </TypographySubsection>

        <h3
          className="mds-text-caption-tiny font-bold uppercase"
          style={{
            letterSpacing: '1px',
            color: 'var(--color-text-secondary)',
            marginTop: 'var(--spacing-large)',
            marginBottom: 'var(--spacing-sm)',
          }}
        >
          Text Styles
          <span className="normal-case font-normal" style={{ marginLeft: 6 }}>
            ({TEXT_STYLES.length}) — composite, use these in code
          </span>
        </h3>
        <Card>
          {TEXT_STYLES.map((s) => (
            <TextStyleRow key={s.key} s={s} />
          ))}
        </Card>
      </section>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------
function SectionIntro({ subtitle }: { subtitle: React.ReactNode }) {
  return (
    <p
      className="mds-text-body"
      style={{ color: 'var(--color-text-secondary)', marginBottom: 'var(--spacing-medium)' }}
    >
      {subtitle}
    </p>
  );
}

function SubsectionHeader({ children, top }: { children: React.ReactNode; top?: boolean }) {
  return (
    <h3
      className="mds-text-caption-tiny font-bold uppercase"
      style={{
        letterSpacing: '1px',
        color: 'var(--color-text-secondary)',
        marginBottom: 'var(--spacing-sm)',
        marginTop: top ? 'var(--spacing-large)' : undefined,
      }}
    >
      {children}
    </h3>
  );
}

function Card({ children }: { children: React.ReactNode }) {
  return (
    <div
      className="bg-white overflow-hidden"
      style={{
        borderRadius: 'var(--radius-card)',
        border: '1px solid var(--color-divider)',
      }}
    >
      {children}
    </div>
  );
}

function ColorGrid({ items }: { items: ColorToken[] }) {
  return (
    <div
      className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5"
      style={{ gap: 'var(--spacing-sm)' }}
    >
      {items.map((c) => (
        <ColorCard key={c.name} {...c} />
      ))}
    </div>
  );
}

function ColorCard({ name, hex, dartName, description }: ColorToken) {
  return (
    <div
      className="bg-white overflow-hidden hover:shadow-sm transition-shadow"
      style={{ borderRadius: 'var(--radius-card)', border: '1px solid var(--color-divider)' }}
    >
      <div className="h-14 w-full" style={{ backgroundColor: hex }} title={hex} />
      <div className="flex flex-col" style={{ padding: 'var(--spacing-sm)', gap: 2 }}>
        <p className="mds-text-caption font-semibold truncate" style={{ color: 'var(--color-text-primary)' }}>
          {name}
        </p>
        <p className="mds-text-caption font-mono uppercase" style={{ color: 'var(--color-text-secondary)' }}>
          {hex}
        </p>
        <code
          className="mds-text-caption block truncate"
          style={{
            color: 'var(--color-primary)',
            background: 'var(--color-surface)',
            padding: '1px 4px',
            borderRadius: 'var(--radius-badge)',
          }}
        >
          {dartName}
        </code>
        {description && (
          <p className="mds-text-caption" style={{ color: 'var(--color-text-secondary)', lineHeight: 1.3 }}>
            {description}
          </p>
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Typography internals
// ---------------------------------------------------------------------------
function TypographySubsection({
  title,
  hint,
  children,
}: {
  title: string;
  hint: string;
  children: React.ReactNode;
}) {
  return (
    <div style={{ marginBottom: 'var(--spacing-large)' }}>
      <SubsectionHeader>{title}</SubsectionHeader>
      <p className="mds-text-caption" style={{ color: 'var(--color-text-secondary)', marginBottom: 'var(--spacing-sm)' }}>
        {hint}
      </p>
      <Card>{children}</Card>
    </div>
  );
}

function MetaCol({ t }: { t: TypographyToken }) {
  return (
    <div className="w-56 shrink-0">
      <p className="mds-text-caption font-semibold font-mono" style={{ color: 'var(--color-text-primary)' }}>
        {t.name}
      </p>
      <p className="mds-text-caption" style={{ color: 'var(--color-text-secondary)' }}>
        {t.description}
      </p>
    </div>
  );
}

function Row({ children, align = 'center' }: { children: React.ReactNode; align?: 'center' | 'baseline' | 'start' }) {
  return (
    <div
      className="flex"
      style={{
        alignItems: align,
        gap: 'var(--spacing-medium)',
        padding: 'var(--spacing-medium)',
        borderTop: '1px solid var(--color-divider)',
      }}
    >
      {children}
    </div>
  );
}

function FontFamilyRow({ t }: { t: TypographyToken }) {
  const quoted = `"${String(t.value)}"`;
  const isDisplay = /Racing/i.test(String(t.value));
  const sample = isDisplay ? 'MINGLIT — Tonight Out' : '안녕하세요 Hello — 밍글릿';
  return (
    <Row>
      <MetaCol t={t} />
      <div
        className="mds-text-caption font-mono shrink-0"
        style={{ color: 'var(--color-text-secondary)', width: 140 }}
      >
        {String(t.value)}
      </div>
      <div
        className="flex-1 min-w-0 truncate"
        style={{
          color: 'var(--color-text-primary)',
          fontFamily: `${quoted}, system-ui, sans-serif`,
          fontSize: isDisplay ? '32px' : '20px',
          lineHeight: 1.1,
        }}
      >
        {sample}
      </div>
    </Row>
  );
}

function FontSizeRow({ t }: { t: TypographyToken }) {
  return (
    <Row align="baseline">
      <MetaCol t={t} />
      <div
        className="mds-text-caption font-mono w-12 shrink-0"
        style={{ color: 'var(--color-text-secondary)' }}
      >
        {t.value}px
      </div>
      <div
        className="flex-1 min-w-0"
        style={{ color: 'var(--color-text-primary)', fontSize: `${t.value}px`, lineHeight: 1.2 }}
      >
        Aa
      </div>
    </Row>
  );
}

function FontWeightRow({ t }: { t: TypographyToken }) {
  return (
    <Row>
      <MetaCol t={t} />
      <div className="mds-text-caption font-mono w-12 shrink-0" style={{ color: 'var(--color-text-secondary)' }}>
        {String(t.value)}
      </div>
      <div
        className="flex-1 min-w-0 mds-text-body"
        style={{ color: 'var(--color-text-primary)', fontWeight: Number(t.value) }}
      >
        오늘 밤 어디 갈까? — Tonight Out
      </div>
    </Row>
  );
}

function LineHeightRow({ t }: { t: TypographyToken }) {
  return (
    <Row align="start">
      <MetaCol t={t} />
      <div className="mds-text-caption font-mono w-12 shrink-0" style={{ color: 'var(--color-text-secondary)', marginTop: 4 }}>
        {String(t.value)}
      </div>
      <div
        className="flex-1 min-w-0 mds-text-body"
        style={{ color: 'var(--color-text-primary)', lineHeight: Number(t.value) }}
      >
        오늘 저녁 7시, 강남의 한 재즈바에서 작은 모임을 열어요. 처음 오는 분들도 편하게 참여하실 수 있어요.
      </div>
    </Row>
  );
}

function TextStyleRow({ s }: { s: TextStyle }) {
  const primitives = Object.entries(s.primitives)
    .filter(([, v]) => !!v)
    .map(([k, v]) => `${k}: var(${v})`);
  return (
    <Row align="start">
      {/* Col 1: class + primitive recipe */}
      <div className="w-56 shrink-0">
        <code className="mds-text-caption font-semibold font-mono" style={{ color: 'var(--color-primary)' }}>
          .mds-text-{s.key}
        </code>
        <div
          className="mds-text-caption-tiny font-mono"
          style={{ color: 'var(--color-text-secondary)', lineHeight: 1.4, marginTop: 6 }}
        >
          {primitives.map((p) => (
            <span key={p} className="block">
              {p}
            </span>
          ))}
        </div>
      </div>

      {/* Col 2: live sample */}
      <div className={`flex-1 min-w-0 mds-text-${s.key}`} style={{ color: 'var(--color-text-primary)' }}>
        {s.sample}
      </div>

      {/* Col 3: purpose / when to use */}
      <p
        className="mds-text-caption shrink-0"
        style={{ width: 220, color: 'var(--color-text-secondary)', lineHeight: 1.5 }}
      >
        {s.description}
      </p>
    </Row>
  );
}
