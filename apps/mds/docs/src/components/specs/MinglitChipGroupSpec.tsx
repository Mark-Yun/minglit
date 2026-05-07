/**
 * Inline visual spec for MinglitChipGroup.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../minglit_chip_group.dart
 *   layout:   scrollable=true (ListView.separated, default) / false (Wrap)
 *   props:    children, height (40, scrollable only), spacing (8px default),
 *             padding (horizontal 16px default), scrollable (true)
 *
 * No Hero (container widget — visual identity lives in its children).
 * No Anatomy (single layout token surface — spacing-small chip gap,
 *             spacing-screen-edge outer padding).
 *
 * Exports:
 *   default — visual playground (Layout modes, Spacing, Composition)
 *   GUIDELINE_RECIPES — keyed do/don't previews
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms — reuse minimal chip atoms inline
// ---------------------------------------------------------------------------
function Chip({
  children,
  selected = false,
  variant = 'surface',
}: {
  children?: React.ReactNode;
  selected?: boolean;
  variant?: 'surface' | 'primary' | 'fchip';
}) {
  if (variant === 'fchip') {
    return (
      <span
        className={['mds-spec-fchip', 'mds-spec-fchip--lg', selected && 'mds-spec-fchip--selected']
          .filter(Boolean)
          .join(' ')}
        role="button"
        aria-pressed={selected}
      >
        <span className="mds-spec-fchip__label">{children}</span>
      </span>
    );
  }
  const cls = [
    'mds-spec-chip',
    'mds-spec-chip--md',
    `mds-spec-chip--${variant}`,
  ].join(' ');
  return (
    <span className={cls}>
      <span className="mds-spec-chip__label">{children}</span>
    </span>
  );
}

// Chip group layout containers (pure CSS — no Flutter)
function ScrollGroup({
  children,
  spacing = 8,
  outerPadding = 16,
}: {
  children: React.ReactNode;
  spacing?: number;
  outerPadding?: number;
}) {
  return (
    <div className="mds-spec-chipgroup mds-spec-chipgroup--scroll" style={{ paddingInline: outerPadding }}>
      <div className="mds-spec-chipgroup__track" style={{ gap: spacing }}>
        {children}
      </div>
    </div>
  );
}

function WrapGroup({
  children,
  spacing = 8,
  outerPadding = 16,
}: {
  children: React.ReactNode;
  spacing?: number;
  outerPadding?: number;
}) {
  return (
    <div className="mds-spec-chipgroup mds-spec-chipgroup--wrap" style={{ paddingInline: outerPadding, gap: spacing }}>
      {children}
    </div>
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
          <th style={{ width: 140 }}>Name</th>
          <th style={{ width: 300 }}>{previewLabel}</th>
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
export default function MinglitChipGroupSpec() {
  return (
    <div className="mds-spec">
      {/* Layout modes */}
      <div>
        <p className="mds-spec__label">Layout modes</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'scrollable (default)',
                preview: (
                  <ScrollGroup>
                    <Chip variant="fchip" selected>최신순</Chip>
                    <Chip variant="fchip">인기순</Chip>
                    <Chip variant="fchip">거리순</Chip>
                    <Chip variant="fchip">재즈</Chip>
                    <Chip variant="fchip">인디</Chip>
                    <Chip variant="fchip">락</Chip>
                  </ScrollGroup>
                ),
                description: 'scrollable=true (default). ListView.separated 기반 가로 스크롤. height=40 고정. `List + Filter chips` 스캐폴드 상단 표준 패턴.',
              },
              {
                name: 'wrap',
                preview: (
                  <WrapGroup>
                    <Chip>재즈</Chip>
                    <Chip>인디</Chip>
                    <Chip>락</Chip>
                    <Chip>팝</Chip>
                    <Chip variant="primary">음악 모임</Chip>
                    <Chip>클래식</Chip>
                  </WrapGroup>
                ),
                description: 'scrollable=false. Wrap 기반 줄바꿈 레이아웃. 높이 제한 없음 — 상세 페이지 태그 목록에 적합.',
              },
            ]}
          />
        </div>
      </div>

      {/* Spacing variants */}
      <div>
        <p className="mds-spec__label">Spacing (chip gap)</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'spacing-small (8px, default)',
                preview: (
                  <ScrollGroup spacing={8}>
                    <Chip variant="fchip" selected>최신순</Chip>
                    <Chip variant="fchip">인기순</Chip>
                    <Chip variant="fchip">거리순</Chip>
                  </ScrollGroup>
                ),
                description: 'spacing=MinglitSpacing.small (8px). 대부분의 필터 그룹 기본값.',
              },
              {
                name: 'spacing-xsmall (4px)',
                preview: (
                  <ScrollGroup spacing={4}>
                    <Chip variant="fchip" selected>최신순</Chip>
                    <Chip variant="fchip">인기순</Chip>
                    <Chip variant="fchip">거리순</Chip>
                    <Chip variant="fchip">재즈</Chip>
                  </ScrollGroup>
                ),
                description: 'spacing=MinglitSpacing.xsmall (4px). 칩이 많고 공간이 좁을 때.',
              },
              {
                name: 'spacing-sm (12px)',
                preview: (
                  <WrapGroup spacing={12}>
                    <Chip>재즈</Chip>
                    <Chip>인디</Chip>
                    <Chip>락</Chip>
                    <Chip variant="primary">음악 모임</Chip>
                  </WrapGroup>
                ),
                description: 'spacing=MinglitSpacing.sm (12px). wrap 레이아웃에서 숨쉬는 태그 목록.',
              },
            ]}
          />
        </div>
      </div>

      {/* Outer padding */}
      <div>
        <p className="mds-spec__label">Outer padding</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'screen-edge (16px, default)',
                preview: (
                  <div style={{ position: 'relative', background: 'var(--color-surface)', borderRadius: 8, overflow: 'hidden' }}>
                    <div className="mds-spec-chipgroup__edge-indicator" />
                    <ScrollGroup outerPadding={16}>
                      <Chip variant="fchip" selected>최신순</Chip>
                      <Chip variant="fchip">인기순</Chip>
                      <Chip variant="fchip">거리순</Chip>
                    </ScrollGroup>
                  </div>
                ),
                description: 'padding=EdgeInsets.symmetric(horizontal: spacing-screen-edge). 화면 가장자리와 칩 사이 16px 여백.',
              },
              {
                name: 'zero padding',
                preview: (
                  <ScrollGroup outerPadding={0}>
                    <Chip variant="fchip" selected>최신순</Chip>
                    <Chip variant="fchip">인기순</Chip>
                    <Chip variant="fchip">거리순</Chip>
                  </ScrollGroup>
                ),
                description: 'padding=EdgeInsets.zero. 부모 컨테이너가 이미 패딩을 가질 때만 — 중복 패딩 방지.',
              },
            ]}
          />
        </div>
      </div>

      {/* Composition — standard scaffold pattern */}
      <div>
        <p className="mds-spec__label">Composition — `List + Filter chips` 스캐폴드</p>
        <div className="mds-spec__panel">
          <div className="mds-spec-chipgroup__scaffold-demo">
            <div className="mds-spec-chipgroup__appbar">
              <span style={{ fontWeight: 600, fontSize: 16 }}>파티 탐색</span>
            </div>
            <ScrollGroup>
              <Chip variant="fchip" selected>최신순</Chip>
              <Chip variant="fchip">인기순</Chip>
              <Chip variant="fchip">거리순</Chip>
              <Chip variant="fchip">재즈</Chip>
              <Chip variant="fchip">인디</Chip>
            </ScrollGroup>
            <div className="mds-spec-chipgroup__list-placeholder">
              <div className="mds-spec-chipgroup__card-ph" />
              <div className="mds-spec-chipgroup__card-ph" />
              <div className="mds-spec-chipgroup__card-ph" style={{ opacity: 0.5 }} />
            </div>
          </div>
          <p className="mds-text-caption" style={{ color: 'var(--color-text-secondary)', marginTop: 8 }}>
            AppBar 아래 ChipGroup(scrollable=true), 카드 리스트 위. spacing-small(8px) 칩 간격, spacing-screen-edge(16px) 외부 패딩 표준.
          </p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes
// ---------------------------------------------------------------------------
function DoScrollableFilterRow() {
  return (
    <ScrollGroup>
      <Chip variant="fchip" selected>최신순</Chip>
      <Chip variant="fchip">인기순</Chip>
      <Chip variant="fchip">거리순</Chip>
      <Chip variant="fchip">재즈</Chip>
      <Chip variant="fchip">인디</Chip>
    </ScrollGroup>
  );
}

function DontWrapFilterRow() {
  return (
    <WrapGroup>
      <Chip variant="fchip" selected>최신순</Chip>
      <Chip variant="fchip">인기순</Chip>
      <Chip variant="fchip">거리순</Chip>
      <Chip variant="fchip">재즈</Chip>
      <Chip variant="fchip">인디</Chip>
    </WrapGroup>
  );
}

function DoWrapTagList() {
  return (
    <WrapGroup spacing={8}>
      <Chip>재즈</Chip>
      <Chip>인디</Chip>
      <Chip>락</Chip>
      <Chip variant="primary">음악 모임</Chip>
      <Chip>클래식</Chip>
    </WrapGroup>
  );
}

function DontNestedGroups() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <ScrollGroup>
        <Chip variant="fchip" selected>최신순</Chip>
        <Chip variant="fchip">인기순</Chip>
      </ScrollGroup>
      <ScrollGroup>
        <Chip variant="fchip">재즈</Chip>
        <Chip variant="fchip">인디</Chip>
      </ScrollGroup>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-scrollable-filter-row': DoScrollableFilterRow,
  'dont-wrap-filter-row': DontWrapFilterRow,
  'do-wrap-tag-list': DoWrapTagList,
  'dont-nested-groups': DontNestedGroups,
};
