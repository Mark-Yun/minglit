/**
 * Inline visual spec for MinglitTag.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../minglit_tag.dart
 *   sizes:    small (h≈22, font 10px) / medium (h≈28, font 13px) — medium default
 *   color:    required — sets both bg tint (subtle opacity) and text/icon color
 *   icon:     optional leading icon, always same color as label
 *   read-only: never interactive (unlike MinglitChip which can have onTap)
 *
 * Two exports:
 *   default — visual playground (Hero, Anatomy, Variants, Sizes, States)
 *   GUIDELINE_RECIPES — keyed do/don't preview components
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

type TagColor = 'primary' | 'success' | 'warning' | 'error' | 'info';
type TagSize = 'sm' | 'md';

const TAG_COLOR_MAP: Record<TagColor, string> = {
  primary: 'var(--color-primary, #9900ff)',
  success: 'var(--color-success, #16a34a)',
  warning: 'var(--color-warning, #d97706)',
  error:   'var(--color-error, #ef4444)',
  info:    'var(--color-info, #3b82f6)',
};

function Tag({
  children,
  color = 'primary',
  size = 'md',
  icon,
}: {
  children?: React.ReactNode;
  color?: TagColor;
  size?: TagSize;
  icon?: React.ReactNode;
}) {
  const cls = [
    'mds-spec-tag',
    `mds-spec-tag--${color}`,
    `mds-spec-tag--${size}`,
  ].join(' ');

  return (
    <span className={cls} style={{ '--tag-color': TAG_COLOR_MAP[color] } as React.CSSProperties}>
      {icon && (
        <span className="mds-spec-tag__icon" aria-hidden>
          {icon}
        </span>
      )}
      <span className="mds-spec-tag__label">{children}</span>
    </span>
  );
}

// SVG icons (no Flutter import)
function MusicIcon({ size = 12 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
    </svg>
  );
}

function CategoryIcon({ size = 12 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 2l-5.5 9h11L12 2zm0 3.84L13.93 9h-3.87L12 5.84zM17.5 13c-2.49 0-4.5 2.01-4.5 4.5S15.01 22 17.5 22s4.5-2.01 4.5-4.5-2.01-4.5-4.5-4.5zm0 7c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5zM3 21.5h8v-8H3v8zm2-6h4v4H5v-4z"/>
    </svg>
  );
}

function CheckIcon({ size = 12 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z" />
    </svg>
  );
}

function WarningIcon({ size = 12 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z" />
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
export default function MinglitTagSpec() {
  return (
    <div className="mds-spec">
      {/* Hero — 4 colored tags: Minglit-realistic Korean copy */}
      <div className="mds-spec__hero">
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center' }}>
          <Tag color="primary" icon={<MusicIcon size={13} />}>음악</Tag>
          <Tag color="success" icon={<CheckIcon size={13} />}>승인</Tag>
          <Tag color="warning" icon={<WarningIcon size={13} />}>대기</Tag>
          <Tag color="error">취소</Tag>
        </div>
      </div>

      {/* Anatomy */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec__anatomy">
          <div className="mds-spec__anatomy-btn">
            <Tag color="primary" size="md" icon={<CategoryIcon size={13} />}>카테고리</Tag>
          </div>
          <span
            className="mds-spec__anatomy-label"
            style={{ top: 18, left: '50%', transform: 'translateX(-50%)' }}
          >
            radius-chip (100px — fully rounded, shares chip token)
          </span>
          <span
            className="mds-spec__anatomy-label"
            style={{ bottom: 18, left: '50%', transform: 'translateX(-50%)' }}
          >
            bg = color × 0.12 opacity tint (MinglitOpacity.subtle)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', left: 0 }}>
            spacing-sm → horizontal padding (12px, medium)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', right: 0 }}>
            spacing-xsmall → icon ↔ label gap (4px)
          </span>
        </div>
      </div>

      {/* Variants — color */}
      <div>
        <p className="mds-spec__label">Variants (color)</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'primary',
                preview: <Tag color="primary">음악</Tag>,
                description: 'MinglitColors.primary (brand purple). 카테고리 레이블 기본.',
              },
              {
                name: 'success',
                preview: <Tag color="success">승인</Tag>,
                description: 'MinglitColors.success (green). 승인됨 / 모집 중 상태.',
              },
              {
                name: 'warning',
                preview: <Tag color="warning">대기</Tag>,
                description: 'MinglitColors.warning (amber). 대기 중 / 마감 임박 상태.',
              },
              {
                name: 'error',
                preview: <Tag color="error">취소</Tag>,
                description: 'MinglitColors.error (red). 취소됨 / 거절됨 상태.',
              },
              {
                name: 'info',
                preview: <Tag color="info">온라인</Tag>,
                description: 'MinglitColors.info (blue). 온라인 / 채널 유형 정보 표시.',
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
                preview: <Tag color="primary" size="sm" icon={<MusicIcon size={12} />}>재즈</Tag>,
                description: 'h ≈22px · font 10px (labelSmall) · icon 12px · padding h:8px v:2px — 카드 인라인 좁은 공간.',
              },
              {
                name: 'medium (default)',
                preview: <Tag color="primary" size="md" icon={<MusicIcon size={13} />}>재즈</Tag>,
                description: 'h ≈28px · font 13px (labelMedium) · icon 14px · padding h:12px v:4px — 기본 사용.',
              },
            ]}
          />
        </div>
      </div>

      {/* States — read-only only */}
      <div>
        <p className="mds-spec__label">States</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'default',
                preview: <Tag color="primary">음악</Tag>,
                description: 'MinglitTag는 항상 read-only. 상호작용 없음 — onTap 필요 시 MinglitChip 사용.',
              },
              {
                name: 'with icon',
                preview: <Tag color="success" icon={<CheckIcon size={13} />}>승인</Tag>,
                description: 'icon != null. 아이콘은 label과 동일 색상. spacing-xsmall(4px) 갭.',
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
                preview: <Tag color="warning">대기</Tag>,
                description: 'icon=null (default). 텍스트만 표시.',
              },
              {
                name: 'with leading icon',
                preview: <Tag color="primary" icon={<CategoryIcon size={13} />}>카테고리</Tag>,
                description: 'icon: IconData. label과 동일 color 적용. spacing-xsmall(4px) 갭.',
              },
            ]}
          />
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes — keyed to GuidelineEntry.recipeKey.
// ---------------------------------------------------------------------------
function DoTagInCard() {
  return (
    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      <Tag color="primary" size="sm" icon={<MusicIcon size={12} />}>재즈</Tag>
      <Tag color="success" size="sm">모집 중</Tag>
    </div>
  );
}

function DontTagAsButton() {
  return (
    <div style={{ display: 'flex', gap: 6, cursor: 'pointer' }}>
      <Tag color="primary">+ 장르 추가</Tag>
    </div>
  );
}

function DoStatusMapping() {
  return (
    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
      <Tag color="success" icon={<CheckIcon size={13} />}>승인</Tag>
      <Tag color="warning" icon={<WarningIcon size={13} />}>대기</Tag>
      <Tag color="error">취소</Tag>
    </div>
  );
}

function DontOverrideWithChip() {
  return (
    <div style={{ display: 'flex', gap: 6 }}>
      <span style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 4,
        padding: '4px 12px',
        borderRadius: 100,
        background: 'color-mix(in srgb, var(--color-primary) 15%, transparent)',
        color: 'var(--color-primary)',
        fontSize: 13,
        cursor: 'pointer',
      }}>음악 ✕</span>
    </div>
  );
}

function DoSmallSizeInline() {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: 8,
      padding: '8px 12px',
      background: 'var(--color-surface)',
      borderRadius: 12,
    }}>
      <span style={{ fontSize: 14, color: 'var(--color-text-primary)' }}>재즈 파티</span>
      <Tag color="primary" size="sm">음악</Tag>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-tag-in-card': DoTagInCard,
  'dont-tag-as-button': DontTagAsButton,
  'do-status-mapping': DoStatusMapping,
  'dont-override-with-chip': DontOverrideWithChip,
  'do-small-size-inline': DoSmallSizeInline,
};
