/**
 * Inline visual spec — MinglitImageCarousel
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/media/minglit_image_carousel.dart
 *
 * API:
 *   MinglitImageCarousel — urls, aspectRatio, showIndicator, onPageChanged
 *   Horizontally paged image carousel. PageView with dot indicator.
 *
 * Two exports:
 *   default          — visual playground (Hero, Anatomy, Variants, States)
 *   GUIDELINE_RECIPES — keyed do/don't previews
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// CSS injected via style tag (prefixed mds-spec-carousel*)
// ---------------------------------------------------------------------------
const CAROUSEL_CSS = `
/* ── Carousel container ─────────────────────────────────────────────────── */
.mds-spec-carousel {
  position: relative;
  overflow: hidden;
  border-radius: var(--radius-card);
  flex-shrink: 0;
}
.mds-spec-carousel--square    { aspect-ratio: 1 / 1; }
.mds-spec-carousel--landscape { aspect-ratio: 16 / 9; }

/* ── Track (horizontal strip of pages) ──────────────────────────────────── */
.mds-spec-carousel__track {
  display: flex;
  width: 100%;
  height: 100%;
}
/* Each page — gradient with slightly different hue offset to feel "different" */
.mds-spec-carousel__page {
  flex: 0 0 100%;
  height: 100%;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}
.mds-spec-carousel__page--1 {
  background: linear-gradient(135deg,
    color-mix(in srgb, var(--color-primary) 22%, var(--color-surface)) 0%,
    color-mix(in srgb, var(--color-secondary) 28%, var(--color-surface)) 100%
  );
}
.mds-spec-carousel__page--2 {
  background: linear-gradient(135deg,
    color-mix(in srgb, var(--color-secondary) 20%, var(--color-surface)) 0%,
    color-mix(in srgb, var(--color-tertiary) 25%, var(--color-surface)) 100%
  );
}
.mds-spec-carousel__page--3 {
  background: linear-gradient(135deg,
    color-mix(in srgb, var(--color-tertiary) 22%, var(--color-surface)) 0%,
    color-mix(in srgb, var(--color-primary) 18%, var(--color-surface)) 100%
  );
}
/* "peek" effect for page 2/3 visible fraction */
.mds-spec-carousel--peeked .mds-spec-carousel__track {
  transform: translateX(-88%);
}

/* ── Page counter badge (top-right) ─────────────────────────────────────── */
.mds-spec-carousel__counter {
  position: absolute;
  top: var(--spacing-small);
  right: var(--spacing-small);
  background: rgba(0, 0, 0, 0.5);
  color: #fff;
  font: 600 10px/1 ui-monospace, monospace;
  padding: 3px 7px;
  border-radius: var(--radius-badge);
  letter-spacing: 0.3px;
  z-index: 2;
  pointer-events: none;
}

/* ── Camera icon inside each page ────────────────────────────────────────── */
.mds-spec-carousel__page-icon {
  opacity: 0.18;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* ── Dot indicator row ───────────────────────────────────────────────────── */
.mds-spec-carousel__indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-xsmall);
  padding: var(--spacing-xsmall) 0;
}
.mds-spec-carousel__dot {
  width: 6px;
  height: 6px;
  border-radius: 999px;
  background: var(--color-divider);
  transition: width 0.2s ease, background 0.2s ease;
  flex-shrink: 0;
}
.mds-spec-carousel__dot--active {
  width: 18px;
  background: var(--color-primary);
}

/* ── Anatomy wrapper ─────────────────────────────────────────────────────── */
.mds-spec-carousel-anatomy {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--spacing-xsmall);
  padding: 52px 40px 52px;
  background: var(--color-surface);
  border-radius: var(--radius-card);
  overflow: visible;
}

/* ── Gesture region hint ─────────────────────────────────────────────────── */
.mds-spec-carousel__gesture-hint {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  pointer-events: none;
  padding: 0 var(--spacing-small);
}
.mds-spec-carousel__arrow {
  width: 24px;
  height: 24px;
  border-radius: 999px;
  background: rgba(0,0,0,0.35);
  display: flex;
  align-items: center;
  justify-content: center;
}
`;

function CarouselStyles() {
  return <style dangerouslySetInnerHTML={{ __html: CAROUSEL_CSS }} />;
}

// ---------------------------------------------------------------------------
// Camera icon (no Flutter import)
// ---------------------------------------------------------------------------
function CameraIcon({ size = 32 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"
        stroke="var(--color-text-secondary)"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="12" cy="13" r="4" stroke="var(--color-text-secondary)" strokeWidth="1.5" />
    </svg>
  );
}

// ---------------------------------------------------------------------------
// FauxCarousel atom
// ---------------------------------------------------------------------------
function FauxCarousel({
  activePage = 0,
  totalPages = 3,
  showIndicator = true,
  ratio = 'landscape',
  showCounter = false,
  width,
  peeked = false,
}: {
  activePage?: number;
  totalPages?: number;
  showIndicator?: boolean;
  ratio?: 'square' | 'landscape';
  showCounter?: boolean;
  width?: number | string;
  peeked?: boolean;
}) {
  const pages = Array.from({ length: totalPages }, (_, i) => i);
  const pageClass = (i: number) => `mds-spec-carousel__page mds-spec-carousel__page--${(i % 3) + 1}`;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, width: width ?? '100%' }}>
      <div
        className={[
          'mds-spec-carousel',
          `mds-spec-carousel--${ratio}`,
          peeked && 'mds-spec-carousel--peeked',
        ]
          .filter(Boolean)
          .join(' ')}
      >
        <div
          className="mds-spec-carousel__track"
          style={{ transform: `translateX(-${activePage * 100}%)` }}
        >
          {pages.map((i) => (
            <div key={i} className={pageClass(i)}>
              <div className="mds-spec-carousel__page-icon">
                <CameraIcon size={28} />
              </div>
            </div>
          ))}
        </div>

        {/* gesture arrows hint */}
        <div className="mds-spec-carousel__gesture-hint">
          {activePage > 0 ? (
            <div className="mds-spec-carousel__arrow">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="white" aria-hidden>
                <path d="M15 18l-6-6 6-6" stroke="white" strokeWidth="2" strokeLinecap="round" fill="none" />
              </svg>
            </div>
          ) : (
            <div />
          )}
          {activePage < totalPages - 1 ? (
            <div className="mds-spec-carousel__arrow">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="white" aria-hidden>
                <path d="M9 18l6-6-6-6" stroke="white" strokeWidth="2" strokeLinecap="round" fill="none" />
              </svg>
            </div>
          ) : (
            <div />
          )}
        </div>

        {showCounter && (
          <div className="mds-spec-carousel__counter">
            {activePage + 1} / {totalPages}
          </div>
        )}
      </div>

      {showIndicator && (
        <div className="mds-spec-carousel__indicator">
          {pages.map((i) => (
            <div
              key={i}
              className={[
                'mds-spec-carousel__dot',
                i === activePage && 'mds-spec-carousel__dot--active',
              ]
                .filter(Boolean)
                .join(' ')}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// PreviewTable
// ---------------------------------------------------------------------------
interface PreviewRow {
  name: string;
  description: string;
  preview: React.ReactNode;
}

function PreviewTable({
  rows,
  previewLabel = 'Preview',
  previewWidth = 240,
}: {
  rows: PreviewRow[];
  previewLabel?: string;
  previewWidth?: number;
}) {
  return (
    <table className="mds-spec__preview-table">
      <thead>
        <tr>
          <th style={{ width: 170 }}>Name</th>
          <th style={{ width: previewWidth }}>{previewLabel}</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((r) => (
          <tr key={r.name}>
            <td><code>{r.name}</code></td>
            <td style={{ textAlign: 'center', verticalAlign: 'middle', padding: '14px 10px' }}>
              {r.preview}
            </td>
            <td style={{ color: 'var(--color-text-secondary)' }}>{r.description}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// ---------------------------------------------------------------------------
// Default export — visual playground
// ---------------------------------------------------------------------------
export default function MinglitImageCarouselSpec() {
  return (
    <div className="mds-spec">
      <CarouselStyles />

      {/* ── Hero ─────────────────────────────────────────────────────── */}
      <div className="mds-spec__hero" style={{ flexDirection: 'column', gap: 8 }}>
        <FauxCarousel
          activePage={0}
          totalPages={3}
          showIndicator
          ratio="landscape"
          width={320}
        />
        <p className="mds-spec__label" style={{ textAlign: 'center' }}>
          사진 3장 — 페이지 1 활성 · 도트 인디케이터
        </p>
      </div>

      {/* ── Anatomy ──────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec-carousel-anatomy">
          {/* annotation labels */}
          <span className="mds-spec__anatomy-label" style={{ top: 14, left: '50%', transform: 'translateX(-50%)' }}>
            radius-card (16px) — overflow: hidden
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '40%', left: 14 }}>
            ← swipe gesture region (전체 너비)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '40%', right: 14 }}>
            swipe 오른쪽 → 다음 페이지
          </span>
          <span className="mds-spec__anatomy-label" style={{ bottom: 14, left: '50%', transform: 'translateX(-50%)' }}>
            dot indicator — spacing-xsmall (4px) gap · active dot 18px wide
          </span>

          <FauxCarousel
            activePage={0}
            totalPages={3}
            showIndicator
            ratio="landscape"
            width={240}
            showCounter
          />
        </div>
      </div>

      {/* ── Variants ─────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Variants</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'with indicator (default)',
                preview: <FauxCarousel activePage={0} totalPages={3} showIndicator ratio="landscape" width={180} />,
                description: 'showIndicator=true. 아래 도트 인디케이터로 현재 페이지 시각화.',
              },
              {
                name: 'without indicator',
                preview: <FauxCarousel activePage={0} totalPages={3} showIndicator={false} ratio="landscape" width={180} showCounter />,
                description: 'showIndicator=false. 오버레이 카운터 배지로 대체 가능. 이미지가 많을 때 도트 과부하 방지.',
              },
              {
                name: 'square ratio',
                preview: <FauxCarousel activePage={0} totalPages={3} showIndicator ratio="square" width={120} />,
                description: 'aspectRatio=1/1. 프로필 또는 앨범 그리드 용도.',
              },
            ]}
          />
        </div>
      </div>

      {/* ── States (page position) ───────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">States — 페이지 위치</p>
        <div className="mds-spec__panel">
          <div
            style={{
              display: 'flex',
              gap: 'var(--spacing-medium)',
              alignItems: 'flex-start',
              flexWrap: 'wrap',
            }}
          >
            {(
              [
                { page: 0, label: '1 / 3 (첫 페이지)' },
                { page: 1, label: '2 / 3 (중간 페이지)' },
                { page: 2, label: '3 / 3 (마지막 페이지)' },
              ] as Array<{ page: number; label: string }>
            ).map(({ page, label }) => (
              <div key={page} style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'center' }}>
                <FauxCarousel
                  activePage={page}
                  totalPages={3}
                  showIndicator
                  ratio="landscape"
                  width={130}
                />
                <span style={{ fontSize: 10, color: 'var(--color-text-secondary)', fontWeight: 600 }}>
                  {label}
                </span>
              </div>
            ))}
          </div>
          <p
            className="mds-text-caption"
            style={{ color: 'var(--color-text-secondary)', marginTop: 10 }}
          >
            활성 도트(primary, 18px 너비)가 현재 페이지를 표시. 비활성 도트는 color-divider (6px 원형).
          </p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Guideline recipes
// ---------------------------------------------------------------------------
function DoMaintainAspectRatio() {
  return (
    <FauxCarousel
      activePage={0}
      totalPages={3}
      showIndicator
      ratio="landscape"
      width={160}
    />
  );
}

function DontRandomHeights() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <div
        style={{
          width: 160,
          height: 60,
          borderRadius: 'var(--radius-card)',
          background: 'linear-gradient(135deg, #e0d0ff, #ffe0a0)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}
      >
        <span style={{ fontSize: 9, color: 'var(--color-text-secondary)' }}>높이 무작위 ✗</span>
      </div>
      <div style={{ display: 'flex', gap: 4, justifyContent: 'center' }}>
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            style={{
              width: i === 0 ? 14 : 5,
              height: 5,
              borderRadius: 999,
              background: i === 0 ? 'var(--color-primary)' : 'var(--color-divider)',
            }}
          />
        ))}
      </div>
    </div>
  );
}

function DoShowIndicator() {
  return (
    <FauxCarousel
      activePage={1}
      totalPages={3}
      showIndicator
      ratio="landscape"
      width={140}
    />
  );
}

function DontNoFeedback() {
  return (
    <FauxCarousel
      activePage={1}
      totalPages={3}
      showIndicator={false}
      ratio="landscape"
      width={140}
    />
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-maintain-aspect-ratio': DoMaintainAspectRatio,
  'dont-random-heights':       DontRandomHeights,
  'do-show-indicator':         DoShowIndicator,
  'dont-no-feedback':          DontNoFeedback,
};
