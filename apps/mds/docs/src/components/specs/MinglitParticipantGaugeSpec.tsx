/**
 * Inline visual spec for MinglitParticipantGauge.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../minglit_participant_gauge.dart
 *   current: int — current participant count
 *   max:     int — maximum capacity
 *
 * Renders a 3-segment "battery" gauge:
 *   Segment colors (all segments share a single segmentColor per fill level):
 *     0 segments   → outlineVariant (gray)  — empty
 *     1 segment (0–33%)  → secondary (orange) — low
 *     2 segments (34–66%) → tertiary (mint)   — medium
 *     3 segments (67–100%) → primary (purple) — full/high
 *
 * Layout: pill container (radius-chip) > [3 rect segments] [gap] [N/M text] [gap] [people icon]
 * Container bg: surfaceContainerHighest
 * Each segment: 10px × 8px (spacing-small), border-radius 2px
 *
 * Two exports:
 *   default — visual playground (Hero, Anatomy, Variants/fill states, States)
 *   GUIDELINE_RECIPES — keyed do/don't preview components
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

type FillLevel = 0 | 1 | 2 | 3;

function getFillLevel(current: number, max: number): FillLevel {
  if (max <= 0) return 0;
  const ratio = Math.min(current / max, 1.0);
  if (ratio <= 0) return 0;
  if (ratio <= 0.33) return 1;
  if (ratio <= 0.66) return 2;
  return 3;
}

const FILL_COLOR: Record<FillLevel, string> = {
  0: 'var(--color-divider, #e5e7eb)',
  1: 'var(--color-secondary, #ff9900)',
  2: 'var(--color-tertiary, #48c9b0)',
  3: 'var(--color-primary, #9900ff)',
};

// People icon (SVG, no Flutter import)
function PeopleIcon({ size = 11 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z" />
    </svg>
  );
}

function Gauge({
  current,
  max,
}: {
  current: number;
  max: number;
}) {
  const fillLevel = getFillLevel(current, max);
  const segmentColor = FILL_COLOR[fillLevel];
  const emptyColor = 'var(--color-divider, #e5e7eb)';

  return (
    <span className="mds-spec-gauge">
      {/* 3 segments */}
      {[0, 1, 2].map((i) => (
        <span
          key={i}
          className="mds-spec-gauge__segment"
          style={{
            background: i < fillLevel ? segmentColor : emptyColor,
          }}
        />
      ))}
      {/* label */}
      <span className="mds-spec-gauge__label">
        {current}/{max}
      </span>
      {/* icon */}
      <PeopleIcon size={11} />
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
          <th style={{ width: 160 }}>Name</th>
          <th style={{ width: 180 }}>{previewLabel}</th>
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
export default function MinglitParticipantGaugeSpec() {
  return (
    <div className="mds-spec">
      {/* Hero — a typical 7/20 gauge at center */}
      <div className="mds-spec__hero">
        <Gauge current={7} max={20} />
      </div>

      {/* Anatomy */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec__anatomy">
          <div className="mds-spec__anatomy-btn">
            <Gauge current={14} max={20} />
          </div>
          <span
            className="mds-spec__anatomy-label"
            style={{ top: 18, left: '50%', transform: 'translateX(-50%)' }}
          >
            radius-chip (100px — pill container, same token as Chip)
          </span>
          <span
            className="mds-spec__anatomy-label"
            style={{ bottom: 18, left: '50%', transform: 'translateX(-50%)' }}
          >
            bg: surfaceContainerHighest (neutral surface tint)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', left: 0 }}>
            spacing-xsmall2 (6px) h-padding, spacing-xxsmall (2px) v-padding
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', right: 0 }}>
            segments: 10×8px, radius 2px, gap spacing-xxsmall (2px)
          </span>
        </div>
      </div>

      {/* Fill states (segment color logic) */}
      <div>
        <p className="mds-spec__label">Fill states (segment color)</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'empty (0/n)',
                preview: <Gauge current={0} max={20} />,
                description: '0 세그먼트 활성화. 모든 세그먼트 outlineVariant (회색). 아직 아무도 없음.',
              },
              {
                name: 'low (0–33%)',
                preview: <Gauge current={3} max={20} />,
                description: '1 세그먼트. secondary (orange). 모집 초반 — 참여 유도 강조 시.',
              },
              {
                name: 'medium (34–66%)',
                preview: <Gauge current={10} max={20} />,
                description: '2 세그먼트. tertiary (mint). 절반 채워진 상태.',
              },
              {
                name: 'high / full (67–100%)',
                preview: <Gauge current={14} max={20} />,
                description: '3 세그먼트. primary (purple). 70% 이상 — 마감 임박 시각화.',
              },
              {
                name: 'full (n/n)',
                preview: <Gauge current={20} max={20} />,
                description: '3 세그먼트 + primary. 정원 마감. "20/20" 텍스트로 모집 불가 전달.',
              },
            ]}
          />
        </div>
      </div>

      {/* Label */}
      <div>
        <p className="mds-spec__label">Label format</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'partial',
                preview: <Gauge current={7} max={20} />,
                description: '"current/max" 텍스트 (11px, w700). 세그먼트 우측에 gap spacing-xsmall2(6px) 후 배치.',
              },
              {
                name: 'single slot',
                preview: <Gauge current={0} max={1} />,
                description: 'max=1 엣지 케이스. "0/1" 표시. 개인 예약 슬롯 패턴.',
              },
            ]}
          />
        </div>
      </div>

      {/* Context / usage */}
      <div>
        <p className="mds-spec__label">Context — card inline usage</p>
        <div className="mds-spec__panel">
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              padding: '10px 12px',
              background: 'var(--color-surface)',
              borderRadius: 12,
              gap: 8,
            }}
          >
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 4,
                padding: '2px 8px',
                borderRadius: 100,
                background: 'color-mix(in srgb, var(--color-primary) 12%, transparent)',
                color: 'var(--color-primary)',
                fontSize: 10,
                fontWeight: 600,
              }}
            >
              재즈
            </span>
            <Gauge current={7} max={20} />
          </div>
          <p style={{ fontSize: 11, color: 'var(--color-text-secondary)', marginTop: 8 }}>
            MinglitContentCard 하단 row — 좌측 MinglitTag(small), 우측 MinglitParticipantGauge. Spacer()로 양쪽 정렬.
          </p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes — keyed to GuidelineEntry.recipeKey.
// ---------------------------------------------------------------------------
function DoGaugeInCard() {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '8px 12px',
        background: 'var(--color-surface)',
        borderRadius: 12,
        gap: 8,
        minWidth: 200,
      }}
    >
      <div style={{ fontSize: 13, color: 'var(--color-text-primary)' }}>재즈 파티</div>
      <Gauge current={7} max={20} />
    </div>
  );
}

function DontShowRawText() {
  return (
    <div style={{ fontSize: 13, color: 'var(--color-text-secondary)' }}>
      참여자: 7 / 20명
    </div>
  );
}

function DoFullStateHighlight() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <Gauge current={14} max={20} />
      <Gauge current={20} max={20} />
    </div>
  );
}

function DontOverrideColors() {
  return (
    <div style={{ display: 'flex', gap: 4 }}>
      {/* wrong: manual red segments override semantic fill logic */}
      {[0, 1, 2].map((i) => (
        <span
          key={i}
          style={{
            display: 'inline-block',
            width: 10, height: 8,
            borderRadius: 2,
            background: 'var(--color-error)',
          }}
        />
      ))}
      <span style={{ fontSize: 11, marginLeft: 6 }}>20/20</span>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-gauge-in-card': DoGaugeInCard,
  'dont-show-raw-text': DontShowRawText,
  'do-full-state-highlight': DoFullStateHighlight,
  'dont-override-colors': DontOverrideColors,
};
