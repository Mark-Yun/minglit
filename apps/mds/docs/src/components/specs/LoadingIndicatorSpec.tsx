/**
 * Inline visual spec for LoadingIndicator.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../loading_indicator.dart
 *   MinglitCircularProgressIndicator — centered spinner, configurable size/color
 *   MinglitLinearProgressIndicator  — full-width track, optional value (0–1), color override
 *
 * Two exports:
 *   default          — visual playground (Hero, Anatomy, Circular Variants,
 *                      Linear Variants, Pattern contexts)
 *   GUIDELINE_RECIPES — keyed do/don't preview components
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// NEW CSS (injected via NEW_CSS in loading.ts — referenced here as comments)
// Classes: mds-spec-loader-circle, mds-spec-loader-linear
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------
function CircleSpinner({
  size = 24,
  strokeWidth = 2,
  color,
}: {
  size?: number;
  strokeWidth?: number;
  color?: string;
}) {
  const c = color ?? 'var(--color-primary)';
  const r = (size - strokeWidth * 2) / 2;
  const circ = 2 * Math.PI * r;
  return (
    <svg
      className="mds-spec-loader-circle"
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      aria-label="로딩 중"
      role="img"
      style={{ display: 'block' }}
    >
      {/* Track */}
      <circle
        cx={size / 2}
        cy={size / 2}
        r={r}
        fill="none"
        stroke="var(--color-divider)"
        strokeWidth={strokeWidth}
      />
      {/* Spinner arc — animated via CSS */}
      <circle
        cx={size / 2}
        cy={size / 2}
        r={r}
        fill="none"
        stroke={c}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeDasharray={`${circ * 0.7} ${circ * 0.3}`}
        style={{ transformOrigin: 'center', animation: 'mds-spec-loader-spin 0.9s linear infinite' }}
      />
    </svg>
  );
}

function LinearBar({
  value,
  color,
}: {
  value?: number;
  color?: string;
}) {
  const c = color ?? 'var(--color-primary)';
  const isIndeterminate = value === undefined;
  return (
    <div
      className="mds-spec-loader-linear"
      role="progressbar"
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={value !== undefined ? Math.round(value * 100) : undefined}
      aria-label={isIndeterminate ? '로딩 중' : `${Math.round((value ?? 0) * 100)}% 완료`}
      style={{
        position: 'relative',
        width: '100%',
        height: 4,
        background: 'var(--color-divider)',
        borderRadius: 2,
        overflow: 'hidden',
      }}
    >
      {isIndeterminate ? (
        <div
          style={{
            position: 'absolute',
            top: 0,
            height: '100%',
            width: '40%',
            background: c,
            borderRadius: 2,
            animation: 'mds-spec-loader-slide 1.4s ease-in-out infinite',
          }}
        />
      ) : (
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            height: '100%',
            width: `${(value ?? 0) * 100}%`,
            background: c,
            borderRadius: 2,
            transition: 'width 0.3s ease',
          }}
        />
      )}
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
          <th style={{ width: 160 }}>Name</th>
          <th style={{ width: 200 }}>{previewLabel}</th>
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
// Default export — visual playground.
// ---------------------------------------------------------------------------
export default function LoadingIndicatorSpec() {
  return (
    <div className="mds-spec">
      {/* Hero — centered spinner at default size */}
      <div className="mds-spec__hero">
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 'var(--spacing-medium)' }}>
          <CircleSpinner size={24} />
          <span style={{ fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)' }}>
            데이터를 불러오는 중...
          </span>
        </div>
      </div>

      {/* Anatomy — circular */}
      <div>
        <p className="mds-spec__label">Anatomy — Circular</p>
        <div className="mds-spec__anatomy" style={{ minHeight: 120 }}>
          <div className="mds-spec__anatomy-btn">
            <CircleSpinner size={32} strokeWidth={3} />
          </div>
          <span className="mds-spec__anatomy-label" style={{ top: 12, left: '50%', transform: 'translateX(-50%)' }}>
            color-primary (arc) / color-divider (track)
          </span>
          <span className="mds-spec__anatomy-label" style={{ bottom: 12, left: '50%', transform: 'translateX(-50%)' }}>
            size=24 (default) · strokeWidth=2 (default)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', left: 0 }}>
            Center() wrapper — always centered
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', right: 0 }}>
            SizedBox(size × size)
          </span>
        </div>
      </div>

      {/* Circular Variants */}
      <div>
        <p className="mds-spec__label">MinglitCircularProgressIndicator — Sizes</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'sm  (size: 16)',
                preview: (
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 32 }}>
                    <CircleSpinner size={16} strokeWidth={2} />
                  </div>
                ),
                description: '아이콘 버튼 내부, 인라인 미니 액션. MinglitButton.isLoading 기본값.',
              },
              {
                name: 'md  (size: 24, default)',
                preview: (
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 32 }}>
                    <CircleSpinner size={24} strokeWidth={2} />
                  </div>
                ),
                description: 'MinglitAsyncValueWidget 기본 로딩. 일반 콘텐츠 영역 중앙.',
              },
              {
                name: 'lg  (size: 48)',
                preview: (
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 56 }}>
                    <CircleSpinner size={48} strokeWidth={4} />
                  </div>
                ),
                description: '페이지 전체 블로킹 로딩. MinglitContentLayout 중앙 단독.',
              },
              {
                name: 'color override (success)',
                preview: (
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 32 }}>
                    <CircleSpinner size={24} color="var(--color-success)" />
                  </div>
                ),
                description: 'color: MinglitColors.success. 업로드 완료 전 단계 표시 등.',
              },
            ]}
          />
        </div>
      </div>

      {/* Linear Variants */}
      <div>
        <p className="mds-spec__label">MinglitLinearProgressIndicator — Variants</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'indeterminate (default)',
                preview: (
                  <div style={{ width: 160, padding: '8px 0' }}>
                    <LinearBar />
                  </div>
                ),
                description: 'value=null. 파일 로딩, 서버 연결 등 완료 시점 미정.',
              },
              {
                name: 'determinate  30%',
                preview: (
                  <div style={{ width: 160, padding: '8px 0' }}>
                    <LinearBar value={0.3} />
                  </div>
                ),
                description: 'value: 0.0–1.0. 파일 업로드, 단계 진행률 표시.',
              },
              {
                name: 'determinate 100% (success)',
                preview: (
                  <div style={{ width: 160, padding: '8px 0' }}>
                    <LinearBar value={1.0} color="var(--color-success)" />
                  </div>
                ),
                description: 'value=1.0 + color override. 업로드 완료 등 긍정 피드백.',
              },
            ]}
          />
        </div>
      </div>

      {/* Pattern Contexts */}
      <div>
        <p className="mds-spec__label">Pattern — 어디에 쓰이나</p>
        <div className="mds-spec__panel" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-medium)' }}>
          {/* In AsyncValueWidget */}
          <div>
            <p style={{ margin: '0 0 8px', fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)', fontWeight: 'var(--typography-font-weight-medium)' }}>
              MinglitAsyncValueWidget 내부 (default loading slot)
            </p>
            <div style={{
              border: '1px dashed var(--color-divider)',
              borderRadius: 'var(--radius-card)',
              padding: 'var(--spacing-large)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              minHeight: 80,
            }}>
              <CircleSpinner size={24} />
            </div>
          </div>
          {/* In Button */}
          <div>
            <p style={{ margin: '0 0 8px', fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)', fontWeight: 'var(--typography-font-weight-medium)' }}>
              MinglitButton.isLoading=true 내부 (size=16 spinner)
            </p>
            <button
              disabled
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 'var(--spacing-small)',
                height: 48,
                padding: '0 var(--spacing-medium)',
                background: 'var(--color-primary)',
                color: '#fff',
                border: 'none',
                borderRadius: 'var(--radius-button)',
                fontSize: 'var(--typography-font-size-body)',
                cursor: 'not-allowed',
                opacity: 0.85,
              }}
            >
              <CircleSpinner size={16} strokeWidth={2} color="#fff" />
              <span>처리 중</span>
            </button>
          </div>
          {/* Linear — page top */}
          <div>
            <p style={{ margin: '0 0 8px', fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)', fontWeight: 'var(--typography-font-weight-medium)' }}>
              페이지 상단 전역 진행률 바 (route transition 등)
            </p>
            <LinearBar />
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes — do/don't preview components keyed to GuidelineEntry.recipeKey.
// ---------------------------------------------------------------------------
function DoSkeletonOverSpinner() {
  // Show skeleton blocks mimicking a card, preferred over spinner
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-small)', width: 200 }}>
      <div style={{
        height: 12, borderRadius: 'var(--radius-small)',
        background: 'var(--color-divider)',
        animation: 'mds-spec-shimmer 1.4s ease-in-out infinite',
        width: '80%',
      }} />
      <div style={{
        height: 12, borderRadius: 'var(--radius-small)',
        background: 'var(--color-divider)',
        animation: 'mds-spec-shimmer 1.4s ease-in-out infinite',
        width: '60%',
      }} />
    </div>
  );
}

function DontFlashSpinner() {
  // Shows a spinner that should NOT flash on sub-200ms fetches
  return (
    <div style={{
      padding: 'var(--spacing-medium)',
      border: '1px dashed var(--color-error)',
      borderRadius: 'var(--radius-card)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 'var(--spacing-small)',
    }}>
      <CircleSpinner size={24} color="var(--color-error)" />
      <span style={{ fontSize: 10, color: 'var(--color-error)' }}>즉시 스피너 — 200ms 미만 fetch에서 금지</span>
    </div>
  );
}

function DoAsyncLoading() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 'var(--spacing-small)' }}>
      <CircleSpinner size={24} />
      <span style={{ fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)' }}>
        데이터를 불러오는 중...
      </span>
    </div>
  );
}

function DontSizeOveruse() {
  return (
    <div style={{ display: 'flex', gap: 'var(--spacing-small)', alignItems: 'center' }}>
      <CircleSpinner size={48} />
      <span style={{ fontSize: 10, color: 'var(--color-error)' }}>lg 스피너를 버튼 인라인에 — 너무 큼</span>
    </div>
  );
}

function DoLinearDeterminate() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-xsmall)', width: 200 }}>
      <span style={{ fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)' }}>
        사진 업로드 중 (60%)
      </span>
      <LinearBar value={0.6} />
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-skeleton-over-spinner': DoSkeletonOverSpinner,
  'dont-flash-spinner': DontFlashSpinner,
  'do-async-loading': DoAsyncLoading,
  'dont-size-overuse': DontSizeOveruse,
  'do-linear-determinate': DoLinearDeterminate,
};
