/**
 * Inline visual spec for MinglitChip.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../minglit_chip.dart
 *   sizes:    small / medium (default) / large
 *   variants: default surface / primary color / custom color
 *   states:   default / interactive (onTap) / disabled
 *   icon:     optional leading icon — medium/large get separator bar
 *
 * Two exports:
 *   default — visual playground (Hero, Anatomy, Variants, Sizes, States, Icon slot)
 *   GUIDELINE_RECIPES — keyed do/don't preview components
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------
function Chip({
  children,
  size = 'md',
  variant = 'surface',
  icon,
  disabled = false,
}: {
  children?: React.ReactNode;
  size?: 'sm' | 'md' | 'lg';
  variant?: 'surface' | 'primary' | 'success' | 'info' | 'warning';
  icon?: React.ReactNode;
  disabled?: boolean;
}) {
  const cls = [
    'mds-spec-chip',
    `mds-spec-chip--${size}`,
    `mds-spec-chip--${variant}`,
    disabled && 'mds-spec-chip--disabled',
  ]
    .filter(Boolean)
    .join(' ');

  const showSeparator = icon && (size === 'md' || size === 'lg');

  return (
    <span className={cls}>
      {icon && (
        <>
          <span className="mds-spec-chip__icon" aria-hidden>
            {icon}
          </span>
          {showSeparator && <span className="mds-spec-chip__sep" aria-hidden />}
        </>
      )}
      <span className="mds-spec-chip__label">{children}</span>
    </span>
  );
}

// Simple SVG music note icon (no Flutter import)
function MusicIcon({ size = 12 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
    </svg>
  );
}

function StarIcon({ size = 12 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z" />
    </svg>
  );
}

interface PreviewRow {
  name: string;
  description: string;
  preview: React.ReactNode;
}

function PreviewTable({ rows, previewLabel = 'Preview' }: { rows: PreviewRow[]; previewLabel?: string }) {
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

// ---------------------------------------------------------------------------
// Default export — visual playground.
// ---------------------------------------------------------------------------
export default function MinglitChipSpec() {
  return (
    <div className="mds-spec">
      {/* Hero */}
      <div className="mds-spec__hero">
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center' }}>
          <Chip size="md">재즈</Chip>
          <Chip size="md" icon={<MusicIcon size={14} />}>인디</Chip>
          <Chip size="md" variant="primary">락</Chip>
          <Chip size="md" icon={<StarIcon size={14} />} variant="success">음악 모임</Chip>
        </div>
      </div>

      {/* Anatomy */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec__anatomy">
          <div className="mds-spec__anatomy-btn">
            <Chip size="lg" icon={<MusicIcon size={16} />}>인디 음악</Chip>
          </div>
          <span
            className="mds-spec__anatomy-label"
            style={{ top: 18, left: '50%', transform: 'translateX(-50%)' }}
          >
            radius-chip (100px — fully rounded)
          </span>
          <span
            className="mds-spec__anatomy-label"
            style={{ bottom: 18, left: '50%', transform: 'translateX(-50%)' }}
          >
            spacing-xsmall2 vertical padding (6px)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', left: 0 }}>
            spacing-sm → horizontal padding (12px)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', right: 0 }}>
            spacing-xsmall → icon ↔ sep ↔ label (4px each)
          </span>
        </div>
      </div>

      {/* Variants */}
      <div>
        <p className="mds-spec__label">Variants (color)</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'surface (default)',
                preview: <Chip size="md">재즈</Chip>,
                description: 'surfaceContainerHighest 기반. 카테고리, 태그, 상태 표시용.',
              },
              {
                name: 'primary',
                preview: <Chip size="md" variant="primary">파티</Chip>,
                description: 'color: MinglitColors.primary. 주요 강조 태그.',
              },
              {
                name: 'success',
                preview: <Chip size="md" variant="success">모집 중</Chip>,
                description: 'color: success green. 긍정 상태 (모집 중 / 완료).',
              },
              {
                name: 'info',
                preview: <Chip size="md" variant="info">온라인</Chip>,
                description: 'color: info blue. 정보성 태그 (장소 유형 / 채널).',
              },
              {
                name: 'warning',
                preview: <Chip size="md" variant="warning">마감 임박</Chip>,
                description: 'color: warning amber. 주의/긴급 상태.',
              },
            ]}
          />
        </div>
      </div>

      {/* Sizes */}
      <div>
        <p className="mds-spec__label">Sizes</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'small',
                preview: <Chip size="sm" icon={<StarIcon size={12} />}>재즈</Chip>,
                description: 'h ~22px · font 10px · icon 12 — 공간이 극히 제한된 슬롯 (리스트 인라인).',
              },
              {
                name: 'medium (default)',
                preview: <Chip size="md" icon={<MusicIcon size={14} />}>인디</Chip>,
                description: 'h ~28px · font 12px · icon 14 — 일반 카드/섹션 내 태그.',
              },
              {
                name: 'large',
                preview: <Chip size="lg" icon={<MusicIcon size={16} />}>음악 모임</Chip>,
                description: 'h ~34px · font 14px · icon 16 — 상세 페이지 강조 태그.',
              },
            ]}
          />
        </div>
      </div>

      {/* States */}
      <div>
        <p className="mds-spec__label">States</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'default',
                preview: <Chip size="md">재즈</Chip>,
                description: 'onTap=null. 읽기 전용 표시 전용.',
              },
              {
                name: 'interactive',
                preview: (
                  <span
                    style={{ display: 'inline-flex', cursor: 'pointer' }}
                    title="onTap 있음"
                  >
                    <Chip size="md">인디</Chip>
                  </span>
                ),
                description: 'onTap != null. InkWell + 48dp 최소 터치 타겟 보장.',
              },
              {
                name: 'disabled',
                preview: <Chip size="md" disabled>비활성</Chip>,
                description: 'opacity 0.4. 탭 차단. onTap=null로 구현.',
              },
            ]}
          />
        </div>
      </div>

      {/* Icon slot */}
      <div>
        <p className="mds-spec__label">Icon slot</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'without icon',
                preview: <Chip size="md">재즈</Chip>,
                description: 'icon=null (default). 텍스트 전용 칩.',
              },
              {
                name: 'with leading icon (small)',
                preview: <Chip size="sm" icon={<StarIcon size={12} />}>락</Chip>,
                description: 'small: icon 바로 옆 텍스트 — 구분선 없음 (공간 절약).',
              },
              {
                name: 'with leading icon (md/lg)',
                preview: <Chip size="md" icon={<MusicIcon size={14} />}>인디</Chip>,
                description: 'medium/large: icon | sep | label — 1px 수직 구분선으로 시각적 분리.',
              },
            ]}
          />
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes — do/don't preview components keyed to GuidelineEntry.recipeKey.
// ---------------------------------------------------------------------------
function DoStatusInCard() {
  return (
    <div style={{ display: 'flex', gap: 6 }}>
      <Chip size="sm" variant="success">모집 중</Chip>
      <Chip size="sm">재즈</Chip>
      <Chip size="sm">인디</Chip>
    </div>
  );
}

function DontOverloadChips() {
  return (
    <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
      <Chip size="sm">재즈</Chip>
      <Chip size="sm">인디</Chip>
      <Chip size="sm">락</Chip>
      <Chip size="sm">팝</Chip>
      <Chip size="sm">클래식</Chip>
      <Chip size="sm">R&amp;B</Chip>
      <Chip size="sm">힙합</Chip>
    </div>
  );
}

function DoIconWithSemantics() {
  return (
    <div style={{ display: 'flex', gap: 6 }}>
      <Chip size="md" icon={<MusicIcon size={14} />} variant="primary">음악 파티</Chip>
    </div>
  );
}

function DontMixSizesInline() {
  return (
    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      <Chip size="sm">재즈</Chip>
      <Chip size="lg">인디</Chip>
      <Chip size="sm">락</Chip>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-status-in-card': DoStatusInCard,
  'dont-overload-chips': DontOverloadChips,
  'do-icon-with-semantics': DoIconWithSemantics,
  'dont-mix-sizes-inline': DontMixSizesInline,
};
