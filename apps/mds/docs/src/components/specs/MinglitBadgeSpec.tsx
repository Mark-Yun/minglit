/**
 * Inline visual spec for MinglitBadge.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../minglit_badge.dart
 *   label:    required — visible text (status word, numeric count, or dot placeholder)
 *   color:    required — bg tint (subtle opacity) + text color
 *   compact:  false (default) / true — smaller padding + font for tight spaces
 *
 * Unlike MinglitTag, MinglitBadge:
 *   - Uses radius-small (8px rectangular) NOT radius-chip (pill)
 *   - Has no icon slot
 *   - Is text-only: label is a status word or number string
 *   - Replaces ad-hoc inline badge implementations (SettlementStatusBadge etc.)
 *
 * Two exports:
 *   default — visual playground (Hero, Anatomy, Variants, States)
 *   GUIDELINE_RECIPES — keyed do/don't preview components
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

type BadgeColor = 'primary' | 'success' | 'warning' | 'error' | 'info';

const BADGE_COLOR_MAP: Record<BadgeColor, string> = {
  primary: 'var(--color-primary, #9900ff)',
  success: 'var(--color-success, #16a34a)',
  warning: 'var(--color-warning, #d97706)',
  error:   'var(--color-error, #ef4444)',
  info:    'var(--color-info, #3b82f6)',
};

function Badge({
  children,
  color = 'primary',
  compact = false,
}: {
  children?: React.ReactNode;
  color?: BadgeColor;
  compact?: boolean;
}) {
  const cls = [
    'mds-spec-badge',
    `mds-spec-badge--${color}`,
    compact && 'mds-spec-badge--compact',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <span className={cls} style={{ '--badge-color': BADGE_COLOR_MAP[color] } as React.CSSProperties}>
      {children}
    </span>
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
export default function MinglitBadgeSpec() {
  return (
    <div className="mds-spec">
      {/* Hero — standard + compact variants with Minglit status copy */}
      <div className="mds-spec__hero">
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center', alignItems: 'center' }}>
          <Badge color="success">승인됨</Badge>
          <Badge color="warning">대기</Badge>
          <Badge color="error">거절</Badge>
          <Badge color="primary">정산</Badge>
          <Badge color="primary" compact>compact</Badge>
        </div>
      </div>

      {/* Anatomy */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec__anatomy">
          <div className="mds-spec__anatomy-btn">
            <Badge color="success">승인됨</Badge>
          </div>
          <span
            className="mds-spec__anatomy-label"
            style={{ top: 18, left: '50%', transform: 'translateX(-50%)' }}
          >
            radius-small (8px) — rectangular pill, distinct from chip
          </span>
          <span
            className="mds-spec__anatomy-label"
            style={{ bottom: 18, left: '50%', transform: 'translateX(-50%)' }}
          >
            bg = color × 0.12 opacity tint (MinglitOpacity.subtle)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', left: 0 }}>
            spacing-sm → horizontal padding (12px, default)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', right: 0 }}>
            font-size: chip-label (13px) / caption (11px, compact)
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
                name: 'success',
                preview: <Badge color="success">승인됨</Badge>,
                description: 'MinglitColors.success. 정산 승인, 파티 참여 확정 상태.',
              },
              {
                name: 'warning',
                preview: <Badge color="warning">대기</Badge>,
                description: 'MinglitColors.warning. 검토 대기 중, 처리 보류 상태.',
              },
              {
                name: 'error',
                preview: <Badge color="error">거절</Badge>,
                description: 'MinglitColors.error. 거절됨, 취소됨 최종 상태.',
              },
              {
                name: 'primary',
                preview: <Badge color="primary">정산</Badge>,
                description: 'MinglitColors.primary. 일반 레이블, 카테고리, 중립 상태.',
              },
              {
                name: 'info',
                preview: <Badge color="info">온라인</Badge>,
                description: 'MinglitColors.info. 정보성 분류 (장소 유형, 채널 타입).',
              },
            ]}
          />
        </div>
      </div>

      {/* compact vs default */}
      <div>
        <p className="mds-spec__label">Compact variant</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'default',
                preview: <Badge color="primary">정산</Badge>,
                description: 'h ≈26px · font 13px · padding h:12px v:4px — 리스트 행, 상세 섹션.',
              },
              {
                name: 'compact',
                preview: <Badge color="primary" compact>정산</Badge>,
                description: 'h ≈20px · font 11px · padding h:8px v:2px — 테이블 셀, 좁은 슬롯, 리스트 trailing.',
              },
            ]}
          />
        </div>
      </div>

      {/* States — text label patterns */}
      <div>
        <p className="mds-spec__label">Label patterns</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'status word',
                preview: (
                  <div style={{ display: 'flex', gap: 6 }}>
                    <Badge color="success">승인됨</Badge>
                    <Badge color="error">거절</Badge>
                  </div>
                ),
                description: '단어형 상태 레이블. 앱 전역 상태(파티, 이벤트, 정산)에 사용.',
              },
              {
                name: 'numeric count',
                preview: (
                  <div style={{ display: 'flex', gap: 6 }}>
                    <Badge color="error">3</Badge>
                    <Badge color="error">12</Badge>
                    <Badge color="error">99+</Badge>
                  </div>
                ),
                description: '숫자 카운트. 99 초과는 "99+" 표시. 알림 배지 패턴.',
              },
              {
                name: 'category label',
                preview: (
                  <div style={{ display: 'flex', gap: 6 }}>
                    <Badge color="primary" compact>재즈</Badge>
                    <Badge color="info" compact>온라인</Badge>
                  </div>
                ),
                description: 'compact + 카테고리 분류. 테이블 셀, 리스트 trailing 슬롯.',
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
function DoBadgeInListRow() {
  const rows = [
    { name: '4월 정산', status: '승인됨', color: 'success' as BadgeColor },
    { name: '3월 정산', status: '대기',   color: 'warning' as BadgeColor },
    { name: '2월 정산', status: '거절',   color: 'error' as BadgeColor },
  ];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, width: '100%' }}>
      {rows.map((r) => (
        <div
          key={r.name}
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '6px 8px',
            background: 'var(--color-surface)',
            borderRadius: 8,
          }}
        >
          <span style={{ fontSize: 13, color: 'var(--color-text-primary)' }}>{r.name}</span>
          <Badge color={r.color} compact>{r.status}</Badge>
        </div>
      ))}
    </div>
  );
}

function DontBadgeAsAction() {
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      <span
        style={{
          display: 'inline-flex',
          padding: '4px 12px',
          borderRadius: 8,
          background: 'color-mix(in srgb, var(--color-primary) 12%, transparent)',
          color: 'var(--color-primary)',
          fontSize: 13,
          cursor: 'pointer',
        }}
      >
        + 정산 요청
      </span>
    </div>
  );
}

function DoMaxOverflow() {
  return (
    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      <Badge color="error">99+</Badge>
      <span style={{ fontSize: 12, color: 'var(--color-text-secondary)' }}>
        → 99 초과 시 "99+" 고정
      </span>
    </div>
  );
}

function DoStatusConsistency() {
  return (
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
      <Badge color="success">승인됨</Badge>
      <Badge color="warning">대기</Badge>
      <Badge color="error">거절</Badge>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-badge-in-list-row': DoBadgeInListRow,
  'dont-badge-as-action': DontBadgeAsAction,
  'do-max-overflow': DoMaxOverflow,
  'do-status-consistency': DoStatusConsistency,
};
