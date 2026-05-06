/**
 * Inline visual spec — MinglitImageSourceSheet
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/media/minglit_image_source_sheet.dart
 *
 * API:
 *   MinglitImageSourceSheet — onCamera, onGallery, [optional: onCancel]
 *   Companion widget for MinglitBottomSheet. Must be passed as `child` to
 *   showMinglitBottomSheet(). Do NOT use as a standalone widget.
 *
 * Scaffold:  "Bottom sheet" — MinglitImageSourceSheet lives inside
 *            MinglitBottomSheet's child slot.
 *
 * Two exports:
 *   default          — visual playground (Hero, Anatomy, Variants, Placement)
 *   GUIDELINE_RECIPES — keyed do/don't previews
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// CSS injected via style tag (prefixed mds-spec-image-src*)
// ---------------------------------------------------------------------------
const IMAGE_SRC_CSS = `
/* ── Source sheet option row ─────────────────────────────────────────────── */
.mds-spec-image-src__row {
  height: 40px;
  margin: 0 var(--spacing-medium);
  border-radius: var(--radius-small);
  background: var(--color-surface);
  display: flex;
  align-items: center;
  gap: var(--spacing-small);
  padding: 0 var(--spacing-sm);
  flex-shrink: 0;
}
.mds-spec-image-src__row--cancel {
  background: transparent;
  border-top: 1px solid var(--color-divider);
  margin-top: var(--spacing-xsmall);
}
.mds-spec-image-src__row-icon {
  display: inline-flex;
  align-items: center;
  color: var(--color-text-secondary);
  flex-shrink: 0;
}
.mds-spec-image-src__row-label {
  font-size: var(--typography-font-size-body);
  font-weight: var(--typography-font-weight-medium);
  color: var(--color-text-primary);
  line-height: 1;
}
.mds-spec-image-src__row--cancel .mds-spec-image-src__row-label {
  color: var(--color-text-secondary);
  font-weight: var(--typography-font-weight-regular);
}

/* ── Annotation ring for anatomy ─────────────────────────────────────────── */
.mds-spec-image-src-anatomy {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: flex-end;
  padding: 56px 32px 32px;
  background: var(--color-surface);
  border-radius: var(--radius-card);
  overflow: visible;
}
`;

function ImageSrcStyles() {
  return <style dangerouslySetInnerHTML={{ __html: IMAGE_SRC_CSS }} />;
}

// ---------------------------------------------------------------------------
// Inline SVG icons
// ---------------------------------------------------------------------------
function CameraIcon({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="12" cy="13" r="4" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function GalleryIcon({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden>
      <rect x="3" y="3" width="18" height="18" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M3 15l5-5 4 4 3-3 6 5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      <circle cx="8" cy="9" r="1.5" fill="currentColor" />
    </svg>
  );
}

function CloseIcon({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden>
      <path d="M18 6L6 18M6 6l12 12" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

// ---------------------------------------------------------------------------
// Faux phone with bottom sheet — uses the existing overlay CSS classes
// ---------------------------------------------------------------------------
function PhoneWithSheet({
  title = '사진 가져오기',
  children,
  heightPct = 48,
  showHandle = true,
}: {
  title?: string;
  children: React.ReactNode;
  heightPct?: number;
  showHandle?: boolean;
}) {
  return (
    <div
      className="mds-spec-overlay__phone"
      style={{ width: 240, height: 400 }}
    >
      {/* background content placeholder */}
      <div className="mds-spec-overlay__bg-content">
        <div className="mds-spec-overlay__bg-appbar" />
        <div className="mds-spec-overlay__bg-row mds-spec-overlay__bg-row--tall" />
        <div className="mds-spec-overlay__bg-row" />
        <div className="mds-spec-overlay__bg-row" style={{ width: '70%' }} />
      </div>

      {/* scrim + sheet */}
      <div className="mds-spec-overlay__scrim" style={{ alignItems: 'flex-end' }}>
        <div
          className="mds-spec-overlay__sheet"
          style={{ height: `${heightPct}%` }}
        >
          {showHandle && <div className="mds-spec-overlay__sheet-handle" />}
          {title && (
            <span className="mds-spec-overlay__sheet-title">{title}</span>
          )}
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              gap: 'var(--spacing-xsmall)',
              paddingBottom: 'var(--spacing-medium)',
            }}
          >
            {children}
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Source rows — the actual MinglitImageSourceSheet content
// ---------------------------------------------------------------------------
type SourceVariant = 'both' | 'camera-only';

function SourceRows({ variant = 'both' }: { variant?: SourceVariant }) {
  return (
    <>
      <div className="mds-spec-image-src__row">
        <span className="mds-spec-image-src__row-icon">
          <CameraIcon size={14} />
        </span>
        <span className="mds-spec-image-src__row-label">카메라로 촬영</span>
      </div>

      {variant === 'both' && (
        <div className="mds-spec-image-src__row">
          <span className="mds-spec-image-src__row-icon">
            <GalleryIcon size={14} />
          </span>
          <span className="mds-spec-image-src__row-label">앨범에서 선택</span>
        </div>
      )}

      <div className="mds-spec-image-src__row mds-spec-image-src__row--cancel">
        <span className="mds-spec-image-src__row-icon">
          <CloseIcon size={12} />
        </span>
        <span className="mds-spec-image-src__row-label">취소</span>
      </div>
    </>
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
  previewWidth = 270,
}: {
  rows: PreviewRow[];
  previewLabel?: string;
  previewWidth?: number;
}) {
  return (
    <table className="mds-spec__preview-table">
      <thead>
        <tr>
          <th style={{ width: 160 }}>Name</th>
          <th style={{ width: previewWidth }}>{previewLabel}</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((r) => (
          <tr key={r.name}>
            <td><code>{r.name}</code></td>
            <td style={{ textAlign: 'center', verticalAlign: 'middle', padding: '16px 10px' }}>
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
export default function MinglitImageSourceSheetSpec() {
  return (
    <div className="mds-spec">
      <ImageSrcStyles />

      {/* ── Hero ─────────────────────────────────────────────────────── */}
      <div className="mds-spec__hero" style={{ gap: 32, flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhoneWithSheet title="사진 가져오기">
            <SourceRows variant="both" />
          </PhoneWithSheet>
          <p className="mds-spec__label" style={{ textAlign: 'center' }}>
            카메라 + 앨범 (both variant)
          </p>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhoneWithSheet title="사진 가져오기" heightPct={36}>
            <SourceRows variant="camera-only" />
          </PhoneWithSheet>
          <p className="mds-spec__label" style={{ textAlign: 'center' }}>
            카메라만 (camera-only variant)
          </p>
        </div>
      </div>

      {/* ── Anatomy ──────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec-image-src-anatomy">
          {/* annotation labels */}
          <span className="mds-spec__anatomy-label" style={{ top: 14, left: '50%', transform: 'translateX(-50%)' }}>
            MinglitBottomSheet — title "사진 가져오기" · showHandle=true
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '38%', left: 8 }}>
            row height: 40px · spacing-sm (12px) padding H
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '55%', right: 8 }}>
            row radius: radius-small (8px)
          </span>
          <span className="mds-spec__anatomy-label" style={{ bottom: 14, left: '50%', transform: 'translateX(-50%)' }}>
            cancel row: border-top divider · transparent bg · text-secondary
          </span>

          <PhoneWithSheet title="사진 가져오기">
            <SourceRows variant="both" />
          </PhoneWithSheet>
        </div>
      </div>

      {/* ── Row layout ───────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Row layout</p>
        <div className="mds-spec__panel">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-xsmall)', maxWidth: 320 }}>
            <div className="mds-spec-image-src__row">
              <span className="mds-spec-image-src__row-icon"><CameraIcon size={16} /></span>
              <span className="mds-spec-image-src__row-label">카메라로 촬영</span>
            </div>
            <div className="mds-spec-image-src__row">
              <span className="mds-spec-image-src__row-icon"><GalleryIcon size={16} /></span>
              <span className="mds-spec-image-src__row-label">앨범에서 선택</span>
            </div>
            <div className="mds-spec-image-src__row mds-spec-image-src__row--cancel">
              <span className="mds-spec-image-src__row-icon"><CloseIcon size={14} /></span>
              <span className="mds-spec-image-src__row-label">취소</span>
            </div>
          </div>
          <p
            className="mds-text-caption"
            style={{ color: 'var(--color-text-secondary)', marginTop: 10 }}
          >
            각 행: icon (14–16px) + spacing-small (8px) + label. height 40px, radius-small (8px), bg color-surface. 취소 행: border-top divider, transparent bg.
          </p>
        </div>
      </div>

      {/* ── Variants ─────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Variants</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'both (default)',
                preview: (
                  <PhoneWithSheet title="사진 가져오기">
                    <SourceRows variant="both" />
                  </PhoneWithSheet>
                ),
                description: 'onCamera + onGallery 모두 제공. 표준 이미지 선택 패턴.',
              },
              {
                name: 'camera-only',
                preview: (
                  <PhoneWithSheet title="사진 가져오기" heightPct={36}>
                    <SourceRows variant="camera-only" />
                  </PhoneWithSheet>
                ),
                description: 'onGallery 없이 onCamera만. 인증 사진 촬영 등 카메라 강제 케이스.',
              },
            ]}
          />
        </div>
      </div>

      {/* ── Placement ────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Placement — MinglitBottomSheet child slot</p>
        <div className="mds-spec__panel">
          <p
            className="mds-text-body"
            style={{ color: 'var(--color-text-primary)', marginBottom: 'var(--spacing-small)' }}
          >
            MinglitImageSourceSheet는 <strong>반드시</strong> MinglitBottomSheet의 child로만 사용한다.
            독립 위젯으로 직접 push/show 금지 — 스크림·드래그 핸들·타이틀은 MinglitBottomSheet가 담당한다.
          </p>
          <div
            style={{
              padding: 'var(--spacing-small) var(--spacing-medium)',
              background: 'color-mix(in srgb, var(--color-primary) 8%, var(--color-surface))',
              borderRadius: 'var(--radius-small)',
              borderLeft: '3px solid var(--color-primary)',
            }}
          >
            <code
              style={{
                fontSize: 'var(--typography-font-size-caption)',
                color: 'var(--color-primary)',
                fontFamily: 'ui-monospace, monospace',
                lineHeight: 1.6,
                whiteSpace: 'pre',
                display: 'block',
              }}
            >
              {`await showMinglitBottomSheet(\n  context: context,\n  title: '사진 가져오기',\n  child: MinglitImageSourceSheet(\n    onCamera: () { /* 촬영 */ },\n    onGallery: () { /* 앨범 */ },\n  ),\n);`}
            </code>
          </div>
          <p
            className="mds-text-caption"
            style={{ color: 'var(--color-text-secondary)', marginTop: 'var(--spacing-small)' }}
          >
            스캐폴드: <code>`Bottom sheet`</code> — MinglitBottomSheet가 scrim 위에서 올라오는 surface.
            MinglitImageSourceSheet는 그 안의 content 슬롯을 채운다.
          </p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Guideline recipes
// ---------------------------------------------------------------------------
function DoInsideBottomSheet() {
  return (
    <PhoneWithSheet title="사진 가져오기">
      <SourceRows variant="both" />
    </PhoneWithSheet>
  );
}

function DontStandalone() {
  // Shows rows without the bottom-sheet wrapper — the "dont" case
  return (
    <div
      style={{
        width: 200,
        padding: 'var(--spacing-small)',
        background: 'var(--color-background)',
        borderRadius: 'var(--radius-card)',
        border: '2px dashed var(--color-error)',
        display: 'flex',
        flexDirection: 'column',
        gap: 4,
      }}
    >
      <span style={{ fontSize: 9, color: 'var(--color-error)', fontWeight: 700, marginBottom: 4 }}>
        NG: 직접 렌더 — MinglitBottomSheet 없음
      </span>
      <div className="mds-spec-image-src__row">
        <span className="mds-spec-image-src__row-icon"><CameraIcon size={12} /></span>
        <span style={{ fontSize: 11, color: 'var(--color-text-primary)' }}>카메라로 촬영</span>
      </div>
      <div className="mds-spec-image-src__row">
        <span className="mds-spec-image-src__row-icon"><GalleryIcon size={12} /></span>
        <span style={{ fontSize: 11, color: 'var(--color-text-primary)' }}>앨범에서 선택</span>
      </div>
    </div>
  );
}

function DoCameraOnly() {
  return (
    <PhoneWithSheet title="사진 가져오기" heightPct={36}>
      <SourceRows variant="camera-only" />
    </PhoneWithSheet>
  );
}

function DontCustomSheet() {
  // Shows a hand-rolled sheet instead of using MinglitImageSourceSheet
  return (
    <div
      style={{
        width: 200,
        padding: 'var(--spacing-small)',
        background: 'white',
        borderRadius: 'var(--radius-card) var(--radius-card) 0 0',
        boxShadow: '0 -4px 16px rgba(0,0,0,0.12)',
        display: 'flex',
        flexDirection: 'column',
        gap: 4,
        border: '2px dashed var(--color-error)',
      }}
    >
      <span style={{ fontSize: 9, color: 'var(--color-error)', fontWeight: 700 }}>
        NG: 커스텀 시트 직접 구현
      </span>
      {['촬영', '앨범', '취소'].map((t) => (
        <div
          key={t}
          style={{
            height: 32,
            background: 'var(--color-surface)',
            borderRadius: 6,
            display: 'flex',
            alignItems: 'center',
            padding: '0 8px',
          }}
        >
          <span style={{ fontSize: 11 }}>{t}</span>
        </div>
      ))}
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-inside-bottom-sheet': DoInsideBottomSheet,
  'dont-standalone':        DontStandalone,
  'do-camera-only':         DoCameraOnly,
  'dont-custom-sheet':      DontCustomSheet,
};
