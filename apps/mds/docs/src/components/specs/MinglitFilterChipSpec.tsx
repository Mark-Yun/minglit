/**
 * Inline visual spec for MinglitFilterChip.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../minglit_filter_chip.dart
 *   sizes:    small / medium / large (default)
 *   states:   unselected / selected — YouTube-style color inversion
 *   icon:     optional leading icon (no separator bar — clean toggle style)
 *   a11y:     Semantics(selected: isSelected, button: true) + 48dp min touch target
 *
 * Two exports:
 *   default — visual playground (Hero, Anatomy, Sizes, States, Icon, Groups)
 *   GUIDELINE_RECIPES — keyed do/don't preview components
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------
function FilterChip({
  children,
  selected = false,
  size = 'lg',
  icon,
  disabled = false,
}: {
  children?: React.ReactNode;
  selected?: boolean;
  size?: 'sm' | 'md' | 'lg';
  icon?: React.ReactNode;
  disabled?: boolean;
}) {
  const cls = [
    'mds-spec-fchip',
    `mds-spec-fchip--${size}`,
    selected && 'mds-spec-fchip--selected',
    disabled && 'mds-spec-fchip--disabled',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <span className={cls} role="button" aria-pressed={selected}>
      {icon && (
        <span className="mds-spec-fchip__icon" aria-hidden>
          {icon}
        </span>
      )}
      <span className="mds-spec-fchip__label">{children}</span>
    </span>
  );
}

// SVG icons
function SortIcon({ size = 14 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M3 18h6v-2H3v2zm0-5h12v-2H3v2zm0-7v2h18V6H3z" />
    </svg>
  );
}

function LocationIcon({ size = 14 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" />
    </svg>
  );
}

function MusicIcon({ size = 14 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
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
          <th style={{ width: 240 }}>{previewLabel}</th>
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
export default function MinglitFilterChipSpec() {
  return (
    <div className="mds-spec">
      {/* Hero — selected vs unselected pair */}
      <div className="mds-spec__hero">
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center' }}>
          <FilterChip size="lg" icon={<SortIcon size={15} />} selected>최신순</FilterChip>
          <FilterChip size="lg" icon={<SortIcon size={15} />}>인기순</FilterChip>
          <FilterChip size="lg" icon={<LocationIcon size={15} />}>서울</FilterChip>
          <FilterChip size="lg" icon={<MusicIcon size={15} />}>재즈</FilterChip>
        </div>
      </div>

      {/* Anatomy */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec__anatomy">
          <div className="mds-spec__anatomy-btn">
            <FilterChip size="lg" icon={<SortIcon size={15} />} selected>최신순</FilterChip>
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
            spacing-xsmall vertical padding (4px, lg size)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', left: 0 }}>
            spacing-sm → horizontal padding (12px)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', right: 0 }}>
            spacing-xsmall → icon ↔ label gap (4px)
          </span>
        </div>
      </div>

      {/* States — the most important section for FilterChip */}
      <div>
        <p className="mds-spec__label">States</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'unselected',
                preview: (
                  <div style={{ display: 'flex', gap: 6 }}>
                    <FilterChip size="lg" icon={<SortIcon size={15} />}>인기순</FilterChip>
                  </div>
                ),
                description: 'isSelected=false. onSurface(α=tintFill) 배경 + onSurfaceVariant 텍스트. 미선택 기본 상태.',
              },
              {
                name: 'selected',
                preview: (
                  <div style={{ display: 'flex', gap: 6 }}>
                    <FilterChip size="lg" icon={<SortIcon size={15} />} selected>최신순</FilterChip>
                  </div>
                ),
                description: 'isSelected=true. onSurface 배경 + surface 텍스트 — YouTube-style 완전 반전. 다크모드 공통.',
              },
              {
                name: 'disabled',
                preview: (
                  <div style={{ display: 'flex', gap: 6 }}>
                    <FilterChip size="lg" disabled>비활성</FilterChip>
                  </div>
                ),
                description: 'onTap 제공 안 됨. opacity 0.4. 탭 차단.',
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
                preview: (
                  <div style={{ display: 'flex', gap: 4 }}>
                    <FilterChip size="sm">재즈</FilterChip>
                    <FilterChip size="sm" selected>인디</FilterChip>
                  </div>
                ),
                description: 'h ~26px · font 12px (labelMedium) · icon 12 — 컴팩트 필터 영역.',
              },
              {
                name: 'medium',
                preview: (
                  <div style={{ display: 'flex', gap: 4 }}>
                    <FilterChip size="md">재즈</FilterChip>
                    <FilterChip size="md" selected>인디</FilterChip>
                  </div>
                ),
                description: 'h ~32px · font 13px (chipLabel) · icon 14 — 일반 필터 UI.',
              },
              {
                name: 'large (default)',
                preview: (
                  <div style={{ display: 'flex', gap: 4 }}>
                    <FilterChip size="lg">최신순</FilterChip>
                    <FilterChip size="lg" selected icon={<SortIcon size={15} />}>인기순</FilterChip>
                  </div>
                ),
                description: 'h ~36px · font 14px (labelLarge) · icon 15 — 검색/목록 기본 정렬 칩.',
              },
            ]}
          />
        </div>
      </div>

      {/* Icon */}
      <div>
        <p className="mds-spec__label">Icon slot</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'text only',
                preview: (
                  <div style={{ display: 'flex', gap: 6 }}>
                    <FilterChip size="lg">인기순</FilterChip>
                    <FilterChip size="lg" selected>최신순</FilterChip>
                  </div>
                ),
                description: 'icon=null (default). 텍스트 전용 토글 스타일.',
              },
              {
                name: 'with icon',
                preview: (
                  <div style={{ display: 'flex', gap: 6 }}>
                    <FilterChip size="lg" icon={<SortIcon size={15} />}>인기순</FilterChip>
                    <FilterChip size="lg" icon={<SortIcon size={15} />} selected>최신순</FilterChip>
                  </div>
                ),
                description: 'icon=IconData. 구분선 없음 — icon 바로 옆 label (MinglitChip과 다름).',
              },
            ]}
          />
        </div>
      </div>

      {/* Composition — sort group example */}
      <div>
        <p className="mds-spec__label">Sort group (단일 선택 패턴)</p>
        <div className="mds-spec__panel">
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <FilterChip size="lg" icon={<SortIcon size={15} />} selected>최신순</FilterChip>
            <FilterChip size="lg" icon={<SortIcon size={15} />}>인기순</FilterChip>
            <FilterChip size="lg">거리순</FilterChip>
          </div>
          <p className="mds-text-caption" style={{ color: 'var(--color-text-secondary)', marginTop: 8 }}>
            한 번에 하나만 selected. onTap에서 setState로 단일 인덱스 유지. MinglitChipGroup + scrollable=true로 감싸는 표준 패턴.
          </p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes
// ---------------------------------------------------------------------------
function DoSingleSelectSort() {
  return (
    <div style={{ display: 'flex', gap: 6 }}>
      <FilterChip size="lg" icon={<SortIcon size={15} />} selected>최신순</FilterChip>
      <FilterChip size="lg" icon={<SortIcon size={15} />}>인기순</FilterChip>
      <FilterChip size="lg">거리순</FilterChip>
    </div>
  );
}

function DontAllSelected() {
  return (
    <div style={{ display: 'flex', gap: 6 }}>
      <FilterChip size="lg" selected>최신순</FilterChip>
      <FilterChip size="lg" selected>인기순</FilterChip>
      <FilterChip size="lg" selected>거리순</FilterChip>
    </div>
  );
}

function DoMultiToggleGenre() {
  return (
    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
      <FilterChip size="lg" icon={<MusicIcon size={15} />} selected>재즈</FilterChip>
      <FilterChip size="lg" icon={<MusicIcon size={15} />} selected>인디</FilterChip>
      <FilterChip size="lg" icon={<MusicIcon size={15} />}>락</FilterChip>
      <FilterChip size="lg" icon={<MusicIcon size={15} />}>팝</FilterChip>
    </div>
  );
}

function DontFilterChipAsButton() {
  return (
    <div style={{ display: 'flex', gap: 6 }}>
      <FilterChip size="lg" selected>파티 만들기</FilterChip>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-single-select-sort': DoSingleSelectSort,
  'dont-all-selected': DontAllSelected,
  'do-multi-toggle-genre': DoMultiToggleGenre,
  'dont-filter-chip-as-button': DontFilterChipAsButton,
};
