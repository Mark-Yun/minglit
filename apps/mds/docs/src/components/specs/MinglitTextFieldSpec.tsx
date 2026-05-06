/**
 * Inline visual spec for MinglitTextField.
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/common/minglit_text_field.dart
 *
 *   Props: label (required), controller, hintText, errorText, helperText,
 *          prefixIcon, suffixIcon, enabled, maxLines, obscureText,
 *          keyboardType, onChanged, onSubmitted, inputFormatters,
 *          textInputAction, focusNode, autofocus
 *
 *   Borders:   radius-input (12px) on all four states
 *   Padding:   horizontal spacing-medium (16px), vertical spacing-sm (12px)
 *   Error:     errorText renders below field in color-error
 *   Disabled:  enabled=false → outline opacity-muted, bg surface
 *
 * Two exports:
 *   default              — visual playground rendered in the Visual section
 *   GUIDELINE_RECIPES    — keyed do/don't previews for GuidelineEntry
 */

import { Search, Person, Close } from '@mds/icons-react';
import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

interface FieldProps {
  label?: string;
  placeholder?: string;
  value?: string;
  error?: string;
  helper?: string;
  disabled?: boolean;
  prefixIcon?: React.ReactNode;
  suffixIcon?: React.ReactNode;
  multiline?: boolean;
  focused?: boolean;
}

function Field({
  label,
  placeholder,
  value,
  error,
  helper,
  disabled = false,
  prefixIcon,
  suffixIcon,
  multiline = false,
  focused = false,
}: FieldProps) {
  const borderColor = error
    ? 'var(--color-error)'
    : focused
    ? 'var(--color-primary)'
    : disabled
    ? 'var(--color-divider)'
    : 'var(--color-divider)';
  const borderWidth = focused || error ? 2 : 1;
  const opacity = disabled ? 0.45 : 1;

  return (
    <div
      className="mds-spec-input__field-root"
      style={{ opacity, pointerEvents: disabled ? 'none' : undefined }}
    >
      {label && (
        <label className="mds-spec-input__label">
          {label}
        </label>
      )}
      <div
        className="mds-spec-input__box"
        style={{
          borderColor,
          borderWidth,
          backgroundColor: disabled ? 'var(--color-surface)' : 'var(--color-background)',
        }}
      >
        {prefixIcon && (
          <span className="mds-spec-input__icon mds-spec-input__icon--prefix" aria-hidden>
            {prefixIcon}
          </span>
        )}
        {multiline ? (
          <textarea
            className="mds-spec-input__input mds-spec-input__input--multiline"
            placeholder={placeholder}
            disabled={disabled}
            readOnly
            defaultValue={value}
            rows={3}
          />
        ) : (
          <input
            type="text"
            className="mds-spec-input__input"
            placeholder={placeholder}
            disabled={disabled}
            readOnly
            defaultValue={value}
          />
        )}
        {suffixIcon && (
          <span className="mds-spec-input__icon mds-spec-input__icon--suffix" aria-hidden>
            {suffixIcon}
          </span>
        )}
      </div>
      {error && (
        <span className="mds-spec-input__error">{error}</span>
      )}
      {!error && helper && (
        <span className="mds-spec-input__helper">{helper}</span>
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
          <th style={{ width: 130 }}>Name</th>
          <th style={{ width: 260 }}>{previewLabel}</th>
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
export default function MinglitTextFieldSpec() {
  return (
    <div className="mds-spec">

      {/* Hero — single default field. */}
      <div className="mds-spec__hero">
        <div style={{ width: 320 }}>
          <Field
            label="이름"
            placeholder="홍길동"
          />
        </div>
      </div>

      {/* Anatomy — annotated field showing each part. */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec__anatomy" style={{ minHeight: 140 }}>
          <div className="mds-spec__anatomy-btn" style={{ width: 300 }}>
            <Field
              label="이름"
              placeholder="홍길동"
              helper="입력 후 저장됩니다"
            />
          </div>
          {/* Anatomy callout labels */}
          <span className="mds-spec__anatomy-label" style={{ top: 0, left: 0 }}>
            label (labelText)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '30%', right: 0 }}>
            radius-input (12px)
          </span>
          <span className="mds-spec__anatomy-label" style={{ top: '55%', left: 0 }}>
            padding: spacing-medium × spacing-sm
          </span>
          <span className="mds-spec__anatomy-label" style={{ bottom: 0, left: 0 }}>
            helperText / errorText
          </span>
        </div>
      </div>

      {/* Variants */}
      <div>
        <p className="mds-spec__label">Variants</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'default',
                preview: (
                  <Field label="이름" placeholder="홍길동" />
                ),
                description: 'prefixIcon/suffixIcon 없는 기본형. label + hintText만.',
              },
              {
                name: 'with prefix icon',
                preview: (
                  <Field
                    label="검색"
                    placeholder="이벤트 검색..."
                    prefixIcon={<Search size={18} />}
                  />
                ),
                description: 'prefixIcon: 입력 앞 아이콘 — 검색, 사람 등 의미 강화.',
              },
              {
                name: 'with suffix icon',
                preview: (
                  <Field
                    label="이름"
                    value="홍길동"
                    suffixIcon={<Close size={18} />}
                  />
                ),
                description: 'suffixIcon: 입력 뒤 아이콘 — 지우기, 토글 등.',
              },
              {
                name: 'multiline',
                preview: (
                  <Field
                    label="소개"
                    placeholder="자기소개를 입력하세요..."
                    multiline
                  />
                ),
                description: 'maxLines > 1. 텍스트 영역으로 확장. obscureText는 maxLines=1만 허용.',
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
                name: 'default',
                preview: <Field label="이메일" placeholder="example@minglit.com" />,
                description: '비활성화되지 않은 기본 상태. 테두리 color-divider.',
              },
              {
                name: 'focused',
                preview: (
                  <Field label="이메일" placeholder="example@minglit.com" focused />
                ),
                description: 'FocusNode 획득 시. 테두리 color-primary + 2px. Flutter에서 자동 처리.',
              },
              {
                name: 'with value',
                preview: (
                  <Field label="이메일" value="user@minglit.com" />
                ),
                description: '값이 입력된 상태. label이 위로 float.',
              },
              {
                name: 'error',
                preview: (
                  <Field
                    label="이메일"
                    value="invalid-email"
                    error="올바른 이메일 형식이 아닙니다"
                  />
                ),
                description: 'errorText != null. 테두리 + 하단 텍스트 color-error.',
              },
              {
                name: 'disabled',
                preview: (
                  <Field label="비활성 필드" placeholder="입력 불가" disabled />
                ),
                description: 'enabled=false. opacity 낮춤, 탭 차단. 읽기 전용 데이터에 사용.',
              },
            ]}
          />
        </div>
      </div>

      {/* Layout — vertical form stack */}
      <div>
        <p className="mds-spec__label">Layout — Form 세로 스택</p>
        <div className="mds-spec__panel">
          <div className="mds-spec-input__form-stack">
            <Field label="이름" placeholder="홍길동" />
            <Field label="이메일" placeholder="example@minglit.com" />
            <Field
              label="연락처"
              placeholder="010-0000-0000"
              prefixIcon={<Person size={18} />}
            />
            <Field
              label="이메일"
              value="bad-email"
              error="올바른 이메일 형식이 아닙니다"
            />
          </div>
          <p
            className="mds-text-caption"
            style={{ color: 'var(--color-text-secondary)', marginTop: 8 }}
          >
            Form + Bottom CTA 스캐폴드에서 필드 간 간격은 spacing-medium (16px). 마지막 필드 아래 spacing-large (24px)로 CTA와 분리.
          </p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes — do/don't previews
// ---------------------------------------------------------------------------

function DoLabelEveryField() {
  return (
    <div className="mds-spec-input__form-stack" style={{ maxWidth: 260 }}>
      <Field label="이름" placeholder="홍길동" />
      <Field label="이메일" placeholder="example@minglit.com" />
    </div>
  );
}

function DontPlaceholderOnlyField() {
  return (
    <div className="mds-spec-input__form-stack" style={{ maxWidth: 260 }}>
      <Field placeholder="이름을 입력하세요" />
      <Field placeholder="이메일을 입력하세요" />
    </div>
  );
}

function DoErrorBelow() {
  return (
    <div style={{ maxWidth: 260 }}>
      <Field
        label="이메일"
        value="bad-email"
        error="올바른 이메일 형식이 아닙니다"
      />
    </div>
  );
}

function DontInlineError() {
  return (
    <div style={{ maxWidth: 260 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Field label="이메일" value="bad-email" />
        <span style={{ color: 'var(--color-error)', fontSize: 12, whiteSpace: 'nowrap' }}>
          형식 오류
        </span>
      </div>
    </div>
  );
}

function DoDisabledReadonly() {
  return (
    <div style={{ maxWidth: 260 }}>
      <Field label="등록일" value="2026-04-28" disabled />
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-label-every-field': DoLabelEveryField,
  'dont-placeholder-only': DontPlaceholderOnlyField,
  'do-error-below': DoErrorBelow,
  'dont-inline-error': DontInlineError,
  'do-disabled-readonly': DoDisabledReadonly,
};
