/**
 * Inline visual spec — MinglitImage
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/media/minglit_image.dart
 *
 * API:
 *   MinglitImage — url, width, height, fit, borderRadius, placeholder
 *   Themed network image with placeholder skeleton + error fallback overlay.
 *
 * Two exports:
 *   default          — visual playground (Hero, Anatomy, Variants, States)
 *   GUIDELINE_RECIPES — keyed do/don't previews
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// CSS injected via style tag (component-scoped, prefixed mds-spec-image*)
// ---------------------------------------------------------------------------
const IMAGE_CSS = `
/* ── MinglitImage faux image block ───────────────────────────────────────── */
.mds-spec-image {
  position: relative;
  overflow: hidden;
  border-radius: var(--radius-card);
  flex-shrink: 0;
  background: linear-gradient(135deg,
    color-mix(in srgb, var(--color-primary) 20%, var(--color-surface)) 0%,
    color-mix(in srgb, var(--color-secondary) 25%, var(--color-surface)) 60%,
    color-mix(in srgb, var(--color-tertiary) 15%, var(--color-surface)) 100%
  );
}
/* aspect ratio presets */
.mds-spec-image--square   { aspect-ratio: 1 / 1; }
.mds-spec-image--landscape { aspect-ratio: 16 / 9; }
.mds-spec-image--portrait  { aspect-ratio: 3 / 4; }
/* cover vs contain */
.mds-spec-image--cover   { background-size: cover; }
.mds-spec-image--contain { background-size: contain; background-repeat: no-repeat; background-position: center; }
/* placeholder skeleton — animated shimmer */
.mds-spec-image--placeholder {
  background: linear-gradient(90deg,
    var(--color-surface) 25%,
    color-mix(in srgb, var(--color-divider) 80%, white) 50%,
    var(--color-surface) 75%
  );
  background-size: 200% 100%;
  animation: mds-spec-image-shimmer 1.4s ease infinite;
}
@keyframes mds-spec-image-shimmer {
  0%   { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
/* error overlay */
.mds-spec-image--error {
  background: color-mix(in srgb, var(--color-surface) 90%, var(--color-error));
  display: flex;
  align-items: center;
  justify-content: center;
}
/* photo content icon (the faux "loaded" state) */
.mds-spec-image__icon {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0.18;
}
/* "loaded" label */
.mds-spec-image__label {
  position: absolute;
  bottom: var(--spacing-small);
  left: var(--spacing-small);
  font: 600 10px/1 ui-monospace, monospace;
  color: #fff;
  background: rgba(0,0,0,0.45);
  padding: 2px 6px;
  border-radius: var(--radius-badge);
  letter-spacing: 0.5px;
}
/* anatomy annotation wrapper */
.mds-spec-image-anatomy {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 56px 40px;
  background: var(--color-surface);
  border-radius: var(--radius-card);
  overflow: visible;
}
`;

function ImageStyles() {
  return <style dangerouslySetInnerHTML={{ __html: IMAGE_CSS }} />;
}

// ---------------------------------------------------------------------------
// Camera icon SVG (no Flutter import)
// ---------------------------------------------------------------------------
function CameraIcon({ size = 32, opacity = 0.6 }: { size?: number; opacity?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden
      style={{ opacity }}
    >
      <path
        d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"
        stroke="var(--color-text-secondary)"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle
        cx="12"
        cy="13"
        r="4"
        stroke="var(--color-text-secondary)"
        strokeWidth="1.5"
      />
    </svg>
  );
}

function BrokenImageIcon({ size = 28 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden>
      <rect x="3" y="3" width="18" height="18" rx="2" stroke="var(--color-error)" strokeWidth="1.5" />
      <path d="M3 16l5-5 4 4 3-3 6 6" stroke="var(--color-error)" strokeWidth="1.5" strokeLinecap="round" />
      <line x1="2" y1="2" x2="22" y2="22" stroke="var(--color-error)" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

// ---------------------------------------------------------------------------
// FauxImage atom — renders the visual state
// ---------------------------------------------------------------------------
type ImageState = 'loaded' | 'placeholder' | 'error';
type ImageFit   = 'cover' | 'contain';
type ImageRatio = 'square' | 'landscape' | 'portrait';

function FauxImage({
  state = 'loaded',
  fit = 'cover',
  ratio = 'landscape',
  width,
  label,
}: {
  state?: ImageState;
  fit?: ImageFit;
  ratio?: ImageRatio;
  width?: number | string;
  label?: string;
}) {
  const cls = [
    'mds-spec-image',
    `mds-spec-image--${ratio}`,
    state === 'placeholder' && 'mds-spec-image--placeholder',
    state === 'error'       && 'mds-spec-image--error',
    state === 'loaded'      && `mds-spec-image--${fit}`,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={cls} style={{ width: width ?? '100%' }}>
      {state === 'loaded' && (
        <div className="mds-spec-image__icon">
          <CameraIcon size={40} opacity={0.22} />
        </div>
      )}
      {state === 'error' && (
        <div
          style={{
            position: 'absolute', inset: 0,
            display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center',
            gap: 4,
          }}
        >
          <BrokenImageIcon size={24} />
          <span style={{ fontSize: 9, color: 'var(--color-error)', fontWeight: 600 }}>
            이미지 없음
          </span>
        </div>
      )}
      {label && <span className="mds-spec-image__label">{label}</span>}
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
  previewWidth = 220,
}: {
  rows: PreviewRow[];
  previewLabel?: string;
  previewWidth?: number;
}) {
  return (
    <table className="mds-spec__preview-table">
      <thead>
        <tr>
          <th style={{ width: 150 }}>Name</th>
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
export default function MinglitImageSpec() {
  return (
    <div className="mds-spec">
      <ImageStyles />

      {/* ── Hero ─────────────────────────────────────────────────────── */}
      <div className="mds-spec__hero" style={{ gap: 16, flexDirection: 'column' }}>
        <FauxImage state="loaded" ratio="landscape" width={320} label="이벤트 대표 이미지" />
        <p className="mds-spec__label" style={{ textAlign: 'center' }}>
          MinglitImage — 로드 완료 상태 (16:9, cover fit)
        </p>
      </div>

      {/* ── Anatomy ──────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec-image-anatomy">
          {/* annotation labels */}
          <span className="mds-spec__anatomy-label" style={{ top: 16, left: '50%', transform: 'translateX(-50%)' }}>
            radius-card (16px) — 모서리 모두 둥글게
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', left: 12, transform: 'translateY(-50%)' }}>
            gradient placeholder — shimmer 애니메이션
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', right: 12, transform: 'translateY(-50%)' }}>
            fit: BoxFit.cover (기본)
          </span>
          <span className="mds-spec__anatomy-label" style={{ bottom: 16, left: '50%', transform: 'translateX(-50%)' }}>
            error overlay — 중앙 아이콘 + 텍스트
          </span>

          <FauxImage state="loaded" ratio="landscape" width={240} label="url 기반 이미지" />
        </div>
      </div>

      {/* ── Variants ─────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Variants</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'default (loaded)',
                preview: <FauxImage state="loaded" ratio="landscape" width={160} />,
                description: 'url 로드 완료. 이미지 풀 표시. fit=cover 기본.',
              },
              {
                name: 'placeholder (loading)',
                preview: <FauxImage state="placeholder" ratio="landscape" width={160} />,
                description: '로딩 중 shimmer 스켈레톤. 이미지 크기를 즉시 예약해 레이아웃 이동 방지.',
              },
              {
                name: 'error fallback',
                preview: <FauxImage state="error" ratio="landscape" width={160} />,
                description: 'url 로드 실패 시 에러 fallback 표시. broken-image 아이콘 금지 — 이 overlay를 사용.',
              },
            ]}
          />
        </div>
      </div>

      {/* ── Aspect Ratios ────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Aspect Ratios</p>
        <div className="mds-spec__panel">
          <div
            style={{
              display: 'flex',
              gap: 'var(--spacing-medium)',
              alignItems: 'flex-end',
              flexWrap: 'wrap',
            }}
          >
            {(
              [
                { ratio: 'square' as ImageRatio,    label: '1 : 1', desc: '프로필, 썸네일' },
                { ratio: 'landscape' as ImageRatio, label: '16 : 9', desc: '이벤트 히어로 (기본)' },
                { ratio: 'portrait' as ImageRatio,  label: '3 : 4',  desc: '포스터 스타일' },
              ] as Array<{ ratio: ImageRatio; label: string; desc: string }>
            ).map(({ ratio, label, desc }) => (
              <div key={ratio} style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'center' }}>
                <FauxImage state="loaded" ratio={ratio} width={ratio === 'portrait' ? 90 : 120} />
                <span style={{ fontSize: 10, fontWeight: 700, color: 'var(--color-text-secondary)' }}>{label}</span>
                <span style={{ fontSize: 10, color: 'var(--color-text-secondary)' }}>{desc}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── States ───────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">States — 로딩 흐름</p>
        <div className="mds-spec__panel">
          <div
            style={{
              display: 'flex',
              gap: 'var(--spacing-medium)',
              alignItems: 'center',
              flexWrap: 'wrap',
            }}
          >
            {(
              [
                { state: 'placeholder' as ImageState, label: '① loading', arrow: true },
                { state: 'loaded' as ImageState,      label: '② loaded',  arrow: true },
                { state: 'error' as ImageState,       label: '③ error',   arrow: false },
              ] as Array<{ state: ImageState; label: string; arrow: boolean }>
            ).map(({ state, label, arrow }) => (
              <div key={state} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'center' }}>
                  <FauxImage state={state} ratio="landscape" width={110} />
                  <span style={{ fontSize: 10, fontWeight: 600, color: 'var(--color-text-secondary)' }}>
                    {label}
                  </span>
                </div>
                {arrow && (
                  <span style={{ fontSize: 16, color: 'var(--color-text-secondary)', paddingBottom: 16 }}>→</span>
                )}
              </div>
            ))}
          </div>
          <p
            className="mds-text-caption"
            style={{ color: 'var(--color-text-secondary)', marginTop: 8 }}
          >
            url 전달 → placeholder shimmer → CachedNetworkImage 로드 → loaded 또는 error fallback.
          </p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Guideline recipes
// ---------------------------------------------------------------------------
function DoPlaceholder() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'center' }}>
      <FauxImage state="placeholder" ratio="landscape" width={140} />
      <span style={{ fontSize: 10, color: 'var(--color-success)' }}>shimmer placeholder ✓</span>
    </div>
  );
}

function DontBrokenIcon() {
  return (
    <div
      style={{
        width: 140,
        aspectRatio: '16/9',
        borderRadius: 'var(--radius-card)',
        background: 'var(--color-surface)',
        border: '1px solid var(--color-divider)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        gap: 4,
      }}
    >
      {/* raw broken image icon — the "dont" */}
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden>
        <rect x="3" y="3" width="18" height="18" rx="2" stroke="var(--color-divider)" strokeWidth="1.5" />
        <path d="M3 16l5-5 4 4 3-3 6 6" stroke="var(--color-divider)" strokeWidth="1.5" strokeLinecap="round" />
      </svg>
      <span style={{ fontSize: 9, color: 'var(--color-text-secondary)' }}>broken icon ✗</span>
    </div>
  );
}

function DoErrorFallback() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'center' }}>
      <FauxImage state="error" ratio="landscape" width={140} />
      <span style={{ fontSize: 10, color: 'var(--color-success)' }}>error fallback overlay ✓</span>
    </div>
  );
}

function DoMaintainRatio() {
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
      <FauxImage state="loaded" ratio="landscape" width={120} />
    </div>
  );
}

function DontStretchImage() {
  return (
    <div
      style={{
        width: 120,
        height: 90,
        borderRadius: 'var(--radius-card)',
        overflow: 'hidden',
        background: 'linear-gradient(135deg, #e0d0ff 0%, #ffe0a0 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <CameraIcon size={32} opacity={0.3} />
      {/* stretched indicator */}
      <div style={{
        position: 'absolute',
        width: '100%', height: '100%',
        background: 'repeating-linear-gradient(45deg, transparent, transparent 4px, rgba(239,68,68,0.15) 4px, rgba(239,68,68,0.15) 8px)',
      }} />
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-placeholder':     DoPlaceholder,
  'dont-broken-icon':   DontBrokenIcon,
  'do-error-fallback':  DoErrorFallback,
  'do-maintain-ratio':  DoMaintainRatio,
  'dont-stretch-image': DontStretchImage,
};
