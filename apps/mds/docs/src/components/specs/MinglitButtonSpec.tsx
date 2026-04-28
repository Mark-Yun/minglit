/**
 * Inline visual spec for MinglitButton.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../minglit_button.dart
 *   variants: primary / secondary / text / destructive
 *   sizes:    small (h36, font14) / medium (h48, font15) / large (h56, font16) — large default
 *   icon, isLoading, expand
 *
 * Two exports:
 *   default — the visual playground rendered in the Visual section
 *             of the components page (Hero, Anatomy, then Variants/Sizes/
 *             States/Icon as `name | preview | description` tables).
 *   GUIDELINE_RECIPES — keyed do/don't preview components rendered
 *             alongside the guideline text on the components page.
 */

import { Add } from '@mds/icons-react';
import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------
function Btn({
  children,
  variant = 'primary',
  size = 'lg',
  loading = false,
  disabled = false,
  expand = false,
  icon,
  ariaLabel,
}: {
  children?: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'text' | 'destructive';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  disabled?: boolean;
  expand?: boolean;
  icon?: React.ReactNode;
  ariaLabel?: string;
}) {
  const cls = [
    'mds-spec-btn',
    `mds-spec-btn--${variant}`,
    `mds-spec-btn--${size}`,
    loading && 'mds-spec-btn--loading',
    expand && 'mds-spec__expand-demo',
  ]
    .filter(Boolean)
    .join(' ');
  return (
    <button className={cls} disabled={disabled} aria-label={ariaLabel}>
      {icon && !loading && (
        <span aria-hidden style={{ display: 'inline-flex', alignItems: 'center' }}>
          {icon}
        </span>
      )}
      {children && <span>{children}</span>}
    </button>
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
export default function MinglitButtonSpec() {
  return (
    <div className="mds-spec">
      {/* Hero — one big primary at default size. */}
      <div className="mds-spec__hero">
        <Btn variant="primary" size="lg">
          참여하기
        </Btn>
      </div>

      {/* Anatomy — labels show which token controls which dimension. */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec__anatomy">
          <div className="mds-spec__anatomy-btn">
            <Btn variant="primary" size="lg" icon={<Add size={20} />}>
              참여하기
            </Btn>
          </div>
          <span
            className="mds-spec__anatomy-label"
            style={{ top: 24, left: '50%', transform: 'translateX(-50%)' }}
          >
            radius-button (12px)
          </span>
          <span
            className="mds-spec__anatomy-label"
            style={{ bottom: 24, left: '50%', transform: 'translateX(-50%)' }}
          >
            height = 56px (lg)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', left: 0 }}>
            spacing-medium → horizontal padding
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '50%', right: 0 }}>
            spacing-small → icon ↔ label gap
          </span>
        </div>
      </div>

      {/* Variants — table with live preview + description. */}
      <div>
        <p className="mds-spec__label">Variants</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'primary',
                preview: <Btn variant="primary" size="md">참여하기</Btn>,
                description: '메인 CTA. 한 화면에 하나만 — submit, join 같은 핵심 액션.',
              },
              {
                name: 'secondary',
                preview: <Btn variant="secondary" size="md">취소</Btn>,
                description: '보조 액션. cancel / back / 폼 부수 동작.',
              },
              {
                name: 'text',
                preview: <Btn variant="text" size="md">더보기 →</Btn>,
                description: '카드 안 인라인 / 3차 액션. expand=false 기본, size=md 기본.',
              },
              {
                name: 'destructive',
                preview: <Btn variant="destructive" size="md">삭제하기</Btn>,
                description: '되돌릴 수 없는 액션. 항상 confirm dialog와 짝.',
              },
            ]}
          />
        </div>
      </div>

      {/* Sizes. */}
      <div>
        <p className="mds-spec__label">Sizes</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'small',
                preview: <Btn size="sm">참여</Btn>,
                description: 'height 36 · font 14 · icon 16 — 칩/리스트 옆 보조 버튼.',
              },
              {
                name: 'medium',
                preview: <Btn size="md">참여하기</Btn>,
                description: 'height 48 · font 15 · icon 18 — 폼 인라인, text variant 기본.',
              },
              {
                name: 'large (default)',
                preview: <Btn size="lg">지금 참여하기</Btn>,
                description: 'height 56 · font 16 · icon 20 — 메인 CTA 기본.',
              },
            ]}
          />
        </div>
      </div>

      {/* States. */}
      <div>
        <p className="mds-spec__label">States</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'default',
                preview: <Btn size="md">참여하기</Btn>,
                description: 'onPressed != null. 탭 가능.',
              },
              {
                name: 'disabled',
                preview: <Btn size="md" disabled>참여하기</Btn>,
                description: 'onPressed == null. opacity 0.4, 탭 차단.',
              },
              {
                name: 'loading',
                preview: <Btn size="md" loading>처리 중</Btn>,
                description: 'isLoading=true. 스피너로 라벨 대체, 탭 차단. 비동기 액션에 사용.',
              },
            ]}
          />
        </div>
      </div>

      {/* Icon. */}
      <div>
        <p className="mds-spec__label">Icon slot</p>
        <div className="mds-spec__panel">
          <PreviewTable
            previewLabel="Preview"
            rows={[
              {
                name: 'without',
                preview: <Btn size="md">추가하기</Btn>,
                description: 'icon=null (default). 라벨만.',
              },
              {
                name: 'with leading icon',
                preview: <Btn size="md" icon={<Add size={20} />}>추가하기</Btn>,
                description: 'icon: IconData. 라벨 앞에 spacing-small (8px) 갭으로 배치.',
              },
            ]}
          />
        </div>
      </div>

      {/* Expand. */}
      <div>
        <p className="mds-spec__label">Expand (full-width)</p>
        <div className="mds-spec__panel">
          <Btn expand>참여하기</Btn>
          <p className="mds-text-caption" style={{ color: 'var(--color-text-secondary)', marginTop: 8 }}>
            expand=true가 primary/secondary/destructive의 기본값. text variant는 false.
          </p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes — short visual previews keyed to GuidelineEntry.recipeKey.
// ---------------------------------------------------------------------------
function DoSinglePrimary() {
  return (
    <>
      <Btn variant="secondary" size="md">취소</Btn>
      <Btn variant="primary" size="md">저장</Btn>
    </>
  );
}

function DontDoublePrimary() {
  return (
    <>
      <Btn variant="primary" size="md">저장</Btn>
      <Btn variant="primary" size="md">제출</Btn>
    </>
  );
}

function DoDestructivePair() {
  return (
    <>
      <Btn variant="secondary" size="md">취소</Btn>
      <Btn variant="destructive" size="md">삭제</Btn>
    </>
  );
}

function DontBareDestructive() {
  return <Btn variant="destructive" size="md">삭제</Btn>;
}

function DoLoadingAsync() {
  return <Btn variant="primary" size="md" loading>처리 중</Btn>;
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-single-primary': DoSinglePrimary,
  'dont-double-primary': DontDoublePrimary,
  'do-destructive-pair': DoDestructivePair,
  'dont-bare-destructive': DontBareDestructive,
  'do-loading-async': DoLoadingAsync,
};

export { Add };
