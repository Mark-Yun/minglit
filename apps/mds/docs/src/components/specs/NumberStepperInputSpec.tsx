/**
 * Inline visual spec for NumberStepperInput.
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/common/number_stepper_input.dart
 *
 *   Props: value (required), onChanged (required), label, min (0), max (999999),
 *          step (1), suffixText
 *
 *   Layout:  optional label text → Row[ − | value input | + ]
 *   Border:  radius-input (12px), color outlineVariant, bg surface
 *   Buttons: 40×40 tap target. Icon 20px. Disabled when at min/max.
 *   Input:   TextFormField center-aligned, digits-only, bold titleMedium.
 *   suffixText: shown inside the field after the number (e.g., "명").
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

interface StepperProps {
  label?: string;
  value?: number;
  min?: number;
  max?: number;
  suffixText?: string;
  /** Force simulate min-reached state */
  atMin?: boolean;
  /** Force simulate max-reached state */
  atMax?: boolean;
}

function Stepper({
  label,
  value = 3,
  min = 0,
  max = 999999,
  suffixText,
  atMin = false,
  atMax = false,
}: StepperProps) {
  const minusDim = atMin || value <= min;
  const plusDim = atMax || value >= max;

  return (
    <div className="mds-spec-stepper__root">
      {label && (
        <span className="mds-spec-stepper__label">{label}</span>
      )}
      <div className="mds-spec-stepper__row">
        {/* Minus button */}
        <button
          className={[
            'mds-spec-stepper__btn',
            minusDim ? 'mds-spec-stepper__btn--disabled' : '',
          ].filter(Boolean).join(' ')}
          disabled={minusDim}
          aria-label="감소"
        >
          {/* minus icon — inline SVG to avoid @mds/icons-react dep in this file */}
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
            <path d="M5 12h14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          </svg>
        </button>

        {/* Value display */}
        <div className="mds-spec-stepper__value-box">
          <span className="mds-spec-stepper__value">{value}</span>
          {suffixText && (
            <span className="mds-spec-stepper__suffix">{suffixText}</span>
          )}
        </div>

        {/* Plus button */}
        <button
          className={[
            'mds-spec-stepper__btn',
            plusDim ? 'mds-spec-stepper__btn--disabled' : '',
          ].filter(Boolean).join(' ')}
          disabled={plusDim}
          aria-label="증가"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
            <path d="M12 5v14M5 12h14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          </svg>
        </button>
      </div>
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
// Default export — visual playground
// ---------------------------------------------------------------------------
export default function NumberStepperInputSpec() {
  return (
    <div className="mds-spec">

      {/* Hero — classic − [3] + */}
      <div className="mds-spec__hero">
        <Stepper label="참여 인원" value={3} suffixText="명" />
      </div>

      {/* Anatomy */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec__anatomy" style={{ minHeight: 100 }}>
          <div className="mds-spec__anatomy-btn">
            <Stepper value={5} suffixText="명" />
          </div>
          <span className="mds-spec__anatomy-label" style={{ top: '30%', left: 0 }}>
            − button (40×40 tap target)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: 0, left: '50%', transform: 'translateX(-50%)' }}>
            value box — bold, center-aligned
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '30%', right: 0 }}>
            + button (40×40 tap target)
          </span>
          <span className="mds-spec__anatomy-label" style={{ bottom: 0, left: '50%', transform: 'translateX(-50%)' }}>
            radius-input (12px) · border outlineVariant · bg surface
          </span>
        </div>
      </div>

      {/* States */}
      <div>
        <p className="mds-spec__label">States</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'default',
                preview: <Stepper value={3} />,
                description: '양방향 증감 가능. min=0, max=999999, step=1 기본값.',
              },
              {
                name: 'min reached (−disabled)',
                preview: <Stepper value={0} min={0} atMin />,
                description: 'value == min → − 버튼 비활성. 탭 차단, 아이콘 dim.',
              },
              {
                name: 'max reached (+disabled)',
                preview: <Stepper value={20} max={20} atMax />,
                description: 'value == max → + 버튼 비활성. 정원 꽉 찬 이벤트 등에 사용.',
              },
              {
                name: 'with label',
                preview: <Stepper label="참여 인원" value={5} />,
                description: 'label prop이 있으면 stepper 위에 bold labelMedium 라벨 표시.',
              },
              {
                name: 'with suffixText',
                preview: <Stepper value={12} suffixText="명" />,
                description: 'suffixText: 숫자 뒤 단위 표기 (명, 개, 회 등).',
              },
              {
                name: 'custom step',
                preview: <Stepper value={10} />,
                description: 'step > 1이면 step 단위로 증감. 예: step=5 → 0, 5, 10, 15…',
              },
            ]}
          />
        </div>
      </div>

      {/* Layout — form context */}
      <div>
        <p className="mds-spec__label">Layout — Form 안에서</p>
        <div className="mds-spec__panel">
          <div className="mds-spec-input__form-stack" style={{ maxWidth: 320 }}>
            {/* Simulated adjacent text field rows using stepper-native approach */}
            <div className="mds-spec-input__field-root">
              <label className="mds-spec-input__label">이벤트 이름</label>
              <div className="mds-spec-input__box" style={{ borderColor: 'var(--color-divider)', borderWidth: 1, backgroundColor: 'var(--color-background)' }}>
                <input type="text" className="mds-spec-input__input" placeholder="이벤트 이름을 입력하세요" readOnly />
              </div>
            </div>
            <Stepper label="참여 인원" value={8} suffixText="명" />
          </div>
          <p
            className="mds-text-caption"
            style={{ color: 'var(--color-text-secondary)', marginTop: 8 }}
          >
            Form + Bottom CTA 스캐폴드에서 MinglitTextField와 같은 세로 스택. 간격 spacing-medium (16px).
          </p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes — do/don't previews
// ---------------------------------------------------------------------------

function DoShowMinMax() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-start' }}>
      <Stepper label="최소 1명" value={1} min={1} atMin />
      <Stepper label="최대 20명" value={20} max={20} atMax />
    </div>
  );
}

function DontHideLimits() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-start' }}>
      <Stepper value={0} min={0} />
      {/* no label, no suffixText — user doesn't know limits */}
    </div>
  );
}

function DoSuffixUnit() {
  return <Stepper label="참여 인원" value={5} suffixText="명" />;
}

function DontRawNumber() {
  return <Stepper label="참여 인원" value={5} />;
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-show-min-max': DoShowMinMax,
  'dont-hide-limits': DontHideLimits,
  'do-suffix-unit': DoSuffixUnit,
  'dont-raw-number': DontRawNumber,
};
