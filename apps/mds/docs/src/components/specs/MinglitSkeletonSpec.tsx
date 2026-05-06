/**
 * Inline visual spec for MinglitSkeleton.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../minglit_skeleton.dart
 *   StatefulWidget — AnimationController (vsync, duration: slow*2, repeat reverse)
 *   ColorTween: surface → textPrimary.withOpacity(highlight/muted) — theme-aware
 *   borderRadius defaults to radius-small (8px)
 *   props: width?, height?, borderRadius?
 *
 * Two exports:
 *   default          — visual playground (Hero card skeleton, Anatomy,
 *                      Variant types, Card recipe composition)
 *   GUIDELINE_RECIPES — keyed do/don't preview components
 *
 * CSS: shimmer animation defined in NEW_CSS (loading.ts)
 *   @keyframes mds-spec-shimmer — opacity pulse 0.4 → 0.85
 *   .mds-spec-skeleton-block   — base block styles
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------
function SkeletonBlock({
  width,
  height,
  radius,
  style: extraStyle,
}: {
  width?: number | string;
  height?: number | string;
  radius?: number | string;
  style?: React.CSSProperties;
}) {
  return (
    <div
      className="mds-spec-skeleton-block"
      aria-hidden="true"
      style={{
        width: width ?? '100%',
        height: height ?? 16,
        borderRadius: radius ?? 'var(--radius-small)',
        background: 'var(--color-divider)',
        animation: 'mds-spec-shimmer 1.4s ease-in-out infinite',
        ...extraStyle,
      }}
    />
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
          <th style={{ width: 220 }}>{previewLabel}</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((r) => (
          <tr key={r.name}>
            <td><code>{r.name}</code></td>
            <td>{r.preview}</td>
            <td style={{ color: 'var(--color-text-secondary)' }}>{r.description}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// ---------------------------------------------------------------------------
// Card skeleton — event card shape (avatar + lines + image block)
// ---------------------------------------------------------------------------
function EventCardSkeleton() {
  return (
    <div
      style={{
        background: 'var(--color-surface)',
        border: '1px solid var(--color-divider)',
        borderRadius: 'var(--radius-card)',
        padding: 'var(--spacing-medium)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--spacing-small)',
        width: 240,
      }}
    >
      {/* Image block */}
      <SkeletonBlock height={120} radius="var(--radius-card)" />
      {/* Title line */}
      <SkeletonBlock width="75%" height={14} />
      {/* Subtitle line */}
      <SkeletonBlock width="55%" height={12} />
      {/* Avatar + meta row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--spacing-small)', marginTop: 'var(--spacing-xsmall)' }}>
        <SkeletonBlock width={32} height={32} radius="50%" style={{ flexShrink: 0 }} />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 'var(--spacing-xsmall)' }}>
          <SkeletonBlock width="60%" height={10} />
          <SkeletonBlock width="40%" height={10} />
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export — visual playground.
// ---------------------------------------------------------------------------
export default function MinglitSkeletonSpec() {
  return (
    <div className="mds-spec">
      {/* Hero — event card skeleton */}
      <div className="mds-spec__hero">
        <EventCardSkeleton />
      </div>

      {/* Anatomy */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec__anatomy" style={{ minHeight: 120 }}>
          <div className="mds-spec__anatomy-btn" style={{ width: 200, display: 'flex', flexDirection: 'column', gap: 8 }}>
            <SkeletonBlock width="100%" height={20} />
            <SkeletonBlock width="70%" height={20} />
          </div>
          <span className="mds-spec__anatomy-label" style={{ top: 12, left: '50%', transform: 'translateX(-50%)' }}>
            animation: opacity 0.4 → 0.85 · duration slow×2 (≈ 700ms)
          </span>
          <span className="mds-spec__anatomy-label" style={{ bottom: 12, left: '50%', transform: 'translateX(-50%)' }}>
            borderRadius: radius-small (8px) — override for circles/cards
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', left: 0 }}>
            color-surface → color-text-primary (theme-aware)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', right: 0 }}>
            width?: fixed or 100%. height?: fixed
          </span>
        </div>
      </div>

      {/* Shimmer timing note */}
      <div>
        <p className="mds-spec__label">Shimmer Animation</p>
        <div className="mds-spec__panel">
          <p style={{ fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)', margin: '0 0 12px' }}>
            <strong>keyframe</strong>: 0% opacity 0.4 → 50% opacity 0.85 → 100% opacity 0.4 (ease-in-out)<br />
            <strong>duration</strong>: 1.4s infinite (Dart: MinglitAnimation.slow × 2, repeat + reverse)<br />
            <strong>색상</strong>: light mode — <code>color-surface</code> base, <code>color-text-primary</code> @ opacity(highlight). Dark mode: <code>color-dark-surface</code> base, <code>color-dark-text-primary</code> @ opacity(muted).
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, maxWidth: 300 }}>
            <SkeletonBlock height={12} width="90%" />
            <SkeletonBlock height={12} width="70%" />
            <SkeletonBlock height={12} width="80%" />
          </div>
        </div>
      </div>

      {/* Variants */}
      <div>
        <p className="mds-spec__label">Variants</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'text-line',
                preview: (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6, width: 160 }}>
                    <SkeletonBlock height={14} />
                    <SkeletonBlock width="65%" height={14} />
                  </div>
                ),
                description: 'MinglitSkeleton(width: N, height: 14–20). 제목/본문 텍스트 플레이스홀더.',
              },
              {
                name: 'circle / avatar',
                preview: (
                  <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                    <SkeletonBlock width={40} height={40} radius="50%" />
                    <SkeletonBlock width={32} height={32} radius="50%" />
                  </div>
                ),
                description: 'borderRadius: BorderRadius.circular(size/2). 프로필 아바타, 아이콘 슬롯.',
              },
              {
                name: 'image-block',
                preview: (
                  <SkeletonBlock height={80} radius="var(--radius-card)" />
                ),
                description: 'height 고정 + borderRadius: radius-card(16px). 이벤트 썸네일 플레이스홀더.',
              },
              {
                name: 'card (composed)',
                preview: <EventCardSkeleton />,
                description: 'image-block + text-line + circle 조합. 이벤트 카드 전체 플레이스홀더.',
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
                name: 'shimmer (active)',
                preview: (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6, width: 160 }}>
                    <SkeletonBlock height={12} />
                    <SkeletonBlock width="70%" height={12} />
                  </div>
                ),
                description: '기본 상태 — 항상 shimmer 재생 중. AnimationController.repeat(reverse: true).',
              },
              {
                name: 'replaced (data loaded)',
                preview: (
                  <div style={{ width: 160, padding: 8, background: 'var(--color-surface)', borderRadius: 'var(--radius-small)', fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)', textAlign: 'center' }}>
                    [실제 콘텐츠로 교체됨]
                  </div>
                ),
                description: '데이터 로드 완료 시 스켈레톤이 위젯 트리에서 제거되고 실제 콘텐츠로 교체.',
              },
            ]}
          />
        </div>
      </div>

      {/* Card recipe — full composition */}
      <div>
        <p className="mds-spec__label">Recipe — 이벤트 카드 리스트 스켈레톤</p>
        <div className="mds-spec__panel">
          <p style={{ fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)', marginTop: 0, marginBottom: 12 }}>
            이벤트 목록 fetch 중: 실제 MinglitContentCard 자리를 스켈레톤으로 채워 레이아웃 이동을 방지한다.
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-card-gap)' }}>
            <EventCardSkeleton />
            <EventCardSkeleton />
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes — do/don't keyed to GuidelineEntry.recipeKey.
// ---------------------------------------------------------------------------
function DoSkeletonForKnownShape() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-card-gap)' }}>
      <EventCardSkeleton />
    </div>
  );
}

function DontGenericSpinnerForCard() {
  return (
    <div style={{
      width: 240,
      height: 140,
      background: 'var(--color-surface)',
      border: '1px dashed var(--color-error)',
      borderRadius: 'var(--radius-card)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}>
      <div style={{
        width: 24, height: 24, border: '2px solid var(--color-error)',
        borderTopColor: 'transparent',
        borderRadius: '50%',
        animation: 'mds-spec-loader-spin 0.9s linear infinite',
      }} />
    </div>
  );
}

function DoFadeInTransition() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, width: 200, opacity: 1, transition: 'opacity 0.2s' }}>
      <SkeletonBlock height={12} />
      <SkeletonBlock width="70%" height={12} />
      <div style={{ marginTop: 4, fontSize: 10, color: 'var(--color-text-secondary)' }}>→ 로드 후 0.2s fade-in 교체</div>
    </div>
  );
}

function DontMixWidths() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, width: 200 }}>
      <SkeletonBlock height={14} width="100%" />
      <SkeletonBlock height={14} width="100%" />
      <SkeletonBlock height={14} width="100%" />
      <div style={{ marginTop: 4, fontSize: 10, color: 'var(--color-error)' }}>같은 너비 3줄 — 부자연스러운 텍스트 모양</div>
    </div>
  );
}

function DoVariedWidths() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, width: 200 }}>
      <SkeletonBlock height={14} width="90%" />
      <SkeletonBlock height={14} width="75%" />
      <SkeletonBlock height={14} width="60%" />
      <div style={{ marginTop: 4, fontSize: 10, color: 'var(--color-success)' }}>다양한 너비 — 실제 텍스트처럼 자연스러움</div>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-skeleton-for-known-shape': DoSkeletonForKnownShape,
  'dont-generic-spinner-for-card': DontGenericSpinnerForCard,
  'do-fade-in-transition': DoFadeInTransition,
  'dont-mix-widths': DontMixWidths,
  'do-varied-widths': DoVariedWidths,
};
