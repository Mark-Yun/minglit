/**
 * Inline visual spec for MinglitErrorState.
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/common/minglit_error_state.dart
 *   variants:    fullPage / card / inline
 *   icon:        IconData (default: Icons.error_outline)
 *   title:       String (default: '오류가 발생했습니다.')
 *   subtitle:    optional String
 *   onRetry:     VoidCallback? — fullPage only, shows retry CTA when set
 *   retryLabel:  String (default: '다시 시도')
 *
 * Icon decision:
 *   @mds/icons-react does not export an error_outline or warning icon.
 *   We render a plain SVG circle-with-exclamation mark (no external dep)
 *   in color-error so the visual reads as an error without requiring an
 *   icon library match. The Dart widget uses Icons.error_outline which maps
 *   to this same semantic.
 *
 * Two exports:
 *   default            — visual playground rendered in the Visual section.
 *   GUIDELINE_RECIPES  — keyed do/don't preview components.
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

/** Error icon — circle with exclamation, rendered in color-error. */
function ErrorIcon({ size = 64, small = false }: { size?: number; small?: boolean }) {
  const s = small ? 32 : size;
  return (
    <svg
      aria-hidden
      width={s}
      height={s}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      style={{ flexShrink: 0 }}
    >
      <circle
        cx="12"
        cy="12"
        r="10"
        stroke="var(--color-error)"
        strokeWidth="1.75"
        fill="none"
      />
      <line
        x1="12"
        y1="7"
        x2="12"
        y2="13"
        stroke="var(--color-error)"
        strokeWidth="1.75"
        strokeLinecap="round"
      />
      <circle cx="12" cy="16.5" r="1" fill="var(--color-error)" />
    </svg>
  );
}

/** Retry CTA button — secondary style with destructive-adjacent error color border. */
function RetryButton({ label = '다시 시도' }: { label?: string }) {
  return (
    <button
      className="mds-spec-btn mds-spec-btn--md"
      style={{
        background: 'transparent',
        color: 'var(--color-error)',
        border: '1px solid var(--color-error)',
        borderRadius: 'var(--radius-button)',
        maxWidth: 200,
        width: '100%',
      }}
    >
      {label}
    </button>
  );
}

/** Centered column layout used by all variants. */
function ErrorContent({
  showIcon = true,
  iconSmall = false,
  title = '데이터를 불러올 수 없어요',
  subtitle,
  onRetry,
  retryLabel = '다시 시도',
  padding = 32,
}: {
  showIcon?: boolean;
  iconSmall?: boolean;
  title?: string;
  subtitle?: string;
  onRetry?: boolean;
  retryLabel?: string;
  padding?: number;
}) {
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding,
        textAlign: 'center',
        gap: 0,
      }}
    >
      {showIcon && (
        <>
          <ErrorIcon small={iconSmall} />
          <div style={{ height: 'var(--spacing-medium)' }} />
        </>
      )}
      <p
        style={{
          margin: 0,
          fontWeight: 'var(--typography-font-weight-bold)' as React.CSSProperties['fontWeight'],
          fontSize: 'var(--typography-font-size-button)',
          color: 'var(--color-error)',
          lineHeight: 'var(--typography-line-height-tight)',
        }}
      >
        {title}
      </p>
      {subtitle && (
        <>
          <div style={{ height: 'var(--spacing-small)' }} />
          <p
            style={{
              margin: 0,
              fontSize: 'var(--typography-font-size-body)',
              color: 'var(--color-text-secondary)',
              lineHeight: 'var(--typography-line-height-relaxed)',
            }}
          >
            {subtitle}
          </p>
        </>
      )}
      {onRetry && (
        <>
          <div style={{ height: 'var(--spacing-large)' }} />
          <RetryButton label={retryLabel} />
        </>
      )}
    </div>
  );
}

/** fullPage variant — transparent bg, large icon, optional retry. */
function FullPageError({
  title = '데이터를 불러올 수 없어요',
  subtitle,
  onRetry = false,
  retryLabel = '다시 시도',
}: {
  title?: string;
  subtitle?: string;
  onRetry?: boolean;
  retryLabel?: string;
}) {
  return (
    <div className="mds-spec-state mds-spec-state--error-full" style={{ width: '100%' }}>
      <ErrorContent
        title={title}
        subtitle={subtitle}
        onRetry={onRetry}
        retryLabel={retryLabel}
        padding={32}
      />
    </div>
  );
}

/** card variant — errorContainer-tinted bg + radius-card, no retry. */
function CardError({
  title = '데이터를 불러올 수 없어요',
  subtitle,
}: {
  title?: string;
  subtitle?: string;
}) {
  return (
    <div
      className="mds-spec-state mds-spec-state--error-card"
      style={{
        background: 'rgba(239, 68, 68, 0.06)',
        borderRadius: 'var(--radius-card)',
        width: '100%',
      }}
    >
      <ErrorContent
        title={title}
        subtitle={subtitle}
        iconSmall
        padding={24}
      />
    </div>
  );
}

/** inline variant — errorContainer-tinted bg + error-color border + radius-card, no icon, no retry. */
function InlineError({
  title = '오류가 발생했습니다.',
  subtitle,
}: {
  title?: string;
  subtitle?: string;
}) {
  return (
    <div
      className="mds-spec-state mds-spec-state--error-inline"
      style={{
        background: 'rgba(239, 68, 68, 0.06)',
        border: '1px solid rgba(239, 68, 68, 0.5)',
        borderRadius: 'var(--radius-card)',
        width: '100%',
      }}
    >
      <ErrorContent
        title={title}
        subtitle={subtitle}
        showIcon={false}
        padding={20}
      />
    </div>
  );
}

interface PreviewRow {
  name: string;
  description: string;
  preview: React.ReactNode;
}

function PreviewTable({
  rows,
  previewLabel = 'Preview',
}: {
  rows: PreviewRow[];
  previewLabel?: string;
}) {
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
// Default export — visual playground.
// ---------------------------------------------------------------------------
export default function MinglitErrorStateSpec() {
  return (
    <div className="mds-spec">
      {/* Hero — fullPage with retry. */}
      <div className="mds-spec__hero">
        <FullPageError
          title="데이터를 불러올 수 없어요"
          subtitle="네트워크 연결을 확인해주세요."
          onRetry
        />
      </div>

      {/* Anatomy */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div
          className="mds-spec__anatomy"
          style={{ flexDirection: 'column', alignItems: 'center', gap: 0 }}
        >
          {/* Icon */}
          <div style={{ position: 'relative', display: 'inline-flex' }}>
            <ErrorIcon size={64} />
            <span
              className="mds-spec__anatomy-label"
              style={{ top: '50%', right: -164, transform: 'translateY(-50%)' }}
            >
              icon — 64px fullPage · 32px card
            </span>
          </div>
          {/* spacing-medium gap */}
          <div
            style={{
              height: 'var(--spacing-medium)',
              width: 2,
              background: 'var(--color-error)',
              opacity: 0.4,
              margin: '2px auto',
            }}
          />
          {/* Title */}
          <div style={{ position: 'relative', display: 'inline-flex' }}>
            <p
              style={{
                margin: 0,
                fontWeight: 700,
                fontSize: 'var(--typography-font-size-button)',
                color: 'var(--color-error)',
              }}
            >
              데이터를 불러올 수 없어요
            </p>
            <span
              className="mds-spec__anatomy-label"
              style={{ top: '50%', left: -168, transform: 'translateY(-50%)' }}
            >
              title — color-error · bold
            </span>
          </div>
          {/* spacing-small gap */}
          <div
            style={{
              height: 'var(--spacing-small)',
              width: 2,
              background: 'var(--color-error)',
              opacity: 0.4,
              margin: '2px auto',
            }}
          />
          {/* Subtitle */}
          <div style={{ position: 'relative', display: 'inline-flex' }}>
            <p
              style={{
                margin: 0,
                fontSize: 'var(--typography-font-size-body)',
                color: 'var(--color-text-secondary)',
              }}
            >
              네트워크 연결을 확인해주세요.
            </p>
            <span
              className="mds-spec__anatomy-label"
              style={{ top: '50%', right: -164, transform: 'translateY(-50%)' }}
            >
              subtitle — font-size-body · text-secondary
            </span>
          </div>
          {/* spacing-large gap */}
          <div
            style={{
              height: 'var(--spacing-large)',
              width: 2,
              background: 'var(--color-error)',
              opacity: 0.4,
              margin: '2px auto',
            }}
          />
          {/* Retry */}
          <div style={{ position: 'relative', display: 'inline-flex' }}>
            <RetryButton />
            <span
              className="mds-spec__anatomy-label"
              style={{ top: '50%', left: -180, transform: 'translateY(-50%)' }}
            >
              retry — fullPage + onRetry only · spacing-large above
            </span>
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
                name: 'fullPage',
                preview: (
                  <FullPageError
                    title="데이터를 불러올 수 없어요"
                    subtitle="네트워크 연결을 확인해주세요."
                    onRetry
                  />
                ),
                description:
                  '탭/페이지 레벨. 64px 아이콘 + 선택적 재시도 버튼. 투명 배경. onRetry != null 일 때만 CTA 노출.',
              },
              {
                name: 'card',
                preview: (
                  <CardError
                    title="참여자 정보를 불러오지 못했어요"
                    subtitle="잠시 후 다시 시도해주세요."
                  />
                ),
                description:
                  '카드/섹션 레벨. 32px 아이콘. error 색상 tinted 배경 + radius-card. 재시도 버튼 없음.',
              },
              {
                name: 'inline',
                preview: (
                  <InlineError
                    title="올바르지 않은 값입니다"
                    subtitle="입력 형식을 확인해주세요."
                  />
                ),
                description:
                  '폼/필드 레벨. 아이콘 숨김. error tinted 배경 + error 보더 + radius-card. 재시도 버튼 없음.',
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
                preview: (
                  <FullPageError
                    title="데이터를 불러올 수 없어요"
                    subtitle="네트워크 연결을 확인해주세요."
                    onRetry
                  />
                ),
                description:
                  '에러 상태는 단일 상태 — 항상 "default". 재시도 버튼 자체의 상태는 MinglitButton 스펙 참조.',
              },
            ]}
          />
        </div>
      </div>

      {/* Composition */}
      <div>
        <p className="mds-spec__label">Composition</p>
        <div
          className="mds-spec__panel"
          style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-medium)' }}
        >
          {/* Inside MinglitContentLayout */}
          <div>
            <p
              style={{
                fontSize: 'var(--typography-font-size-caption)',
                fontWeight: 600,
                color: 'var(--color-text-secondary)',
                marginBottom: 8,
              }}
            >
              fullPage — MinglitContentLayout 본문 영역 에러 시
            </p>
            <div
              style={{
                border: '1px dashed var(--color-divider)',
                borderRadius: 'var(--radius-card)',
                background: 'var(--color-background)',
                padding: 4,
                display: 'flex',
                flexDirection: 'column',
              }}
            >
              <div
                style={{
                  height: 24,
                  background: 'var(--color-surface)',
                  borderRadius: 4,
                  margin: 4,
                }}
              />
              <FullPageError
                title="이벤트 목록을 불러올 수 없어요"
                subtitle="네트워크 연결을 확인하고 다시 시도해주세요."
                onRetry
              />
            </div>
          </div>
          {/* Inside MinglitContentCard */}
          <div>
            <p
              style={{
                fontSize: 'var(--typography-font-size-caption)',
                fontWeight: 600,
                color: 'var(--color-text-secondary)',
                marginBottom: 8,
              }}
            >
              card — MinglitContentCard 내부 섹션 에러 시
            </p>
            <div
              style={{
                border: '1px solid var(--color-divider)',
                borderRadius: 'var(--radius-card)',
                padding: 'var(--spacing-medium)',
                background: 'var(--color-background)',
              }}
            >
              <CardError
                title="정산 내역을 불러오지 못했어요"
                subtitle="잠시 후 다시 시도해주세요."
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes — keyed to GuidelineEntry.recipeKey.
// ---------------------------------------------------------------------------

function DoRetryOnNetworkError() {
  return (
    <FullPageError
      title="데이터를 불러올 수 없어요"
      subtitle="네트워크 연결을 확인해주세요."
      onRetry
    />
  );
}

function DontRetryOnEmpty() {
  // shows wrong: using ErrorState when data is simply empty
  return (
    <div
      style={{
        background: 'rgba(239, 68, 68, 0.06)',
        border: '1px solid rgba(239, 68, 68, 0.4)',
        borderRadius: 'var(--radius-card)',
        padding: 24,
        textAlign: 'center',
      }}
    >
      <p style={{ margin: 0, fontWeight: 700, color: 'var(--color-error)' }}>오류</p>
      <p
        style={{
          margin: '8px 0 0',
          fontSize: 'var(--typography-font-size-body)',
          color: 'var(--color-text-secondary)',
        }}
      >
        저장된 모임이 없습니다
      </p>
    </div>
  );
}

function DoSpecificErrorMessage() {
  return (
    <FullPageError
      title="서버에 연결할 수 없어요"
      subtitle="인터넷 연결 상태를 확인하고 다시 시도해주세요."
      onRetry
    />
  );
}

function DontGenericErrorOnly() {
  return (
    <FullPageError
      title="오류가 발생했습니다."
    />
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-retry-on-network-error': DoRetryOnNetworkError,
  'dont-retry-on-empty': DontRetryOnEmpty,
  'do-specific-error-message': DoSpecificErrorMessage,
  'dont-generic-error-only': DontGenericErrorOnly,
};
