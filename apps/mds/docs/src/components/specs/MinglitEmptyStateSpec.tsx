/**
 * Inline visual spec for MinglitEmptyState.
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/common/minglit_empty_state.dart
 *   variants: fullPage / card / inline
 *   icon:     IconData (default: Icons.inbox_outlined)
 *   title:    required String
 *   subtitle: optional String
 *   actionLabel + onAction: fullPage only, both required to show CTA
 *
 * Icon decision:
 *   @mds/icons-react does not export an inbox/empty icon.
 *   We use the Search icon at 0.35 opacity to communicate
 *   "nothing found" — a common empty-state metaphor. For the
 *   "no action" variant we use a simple CSS box-with-lines SVG.
 *   Integrators should pass a context-appropriate IconData in Dart
 *   (default is Icons.inbox_outlined). The React spec uses Search as
 *   the closest available stand-in.
 *
 * Two exports:
 *   default            — visual playground (Hero + Anatomy + Variants + States
 *                        + Composition), rendered in the Visual section of the
 *                        components page.
 *   GUIDELINE_RECIPES  — keyed do/don't preview components.
 */

import { Search } from '@mds/icons-react';
import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

/** Faded icon slot — approximates the inbox_outlined icon in Flutter. */
function EmptyIcon({ size = 48, faded = false }: { size?: number; faded?: boolean }) {
  return (
    <span
      aria-hidden
      style={{
        display: 'inline-flex',
        opacity: faded ? 0.28 : 0.45,
        color: 'var(--color-text-secondary)',
      }}
    >
      <Search size={size} />
    </span>
  );
}

/** Full-width CTA button (primary, matches Dart FilledButton). */
function CtaButton({ children }: { children: React.ReactNode }) {
  return (
    <button
      className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--md"
      style={{ width: '100%', maxWidth: 200 }}
    >
      {children}
    </button>
  );
}

/** Centered column layout used by all variants. */
function EmptyContent({
  icon,
  iconSize = 48,
  iconFaded = false,
  title,
  subtitle,
  action,
  padding = 32,
}: {
  icon?: React.ReactNode;
  iconSize?: number;
  iconFaded?: boolean;
  title: string;
  subtitle?: string;
  action?: string;
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
      {icon !== undefined ? (
        icon
      ) : (
        <EmptyIcon size={iconSize} faded={iconFaded} />
      )}
      <div style={{ height: icon === null ? 0 : 'var(--spacing-medium)' }} />
      <p
        style={{
          margin: 0,
          fontWeight: 'var(--typography-font-weight-semi-bold)' as React.CSSProperties['fontWeight'],
          fontSize: 'var(--typography-font-size-button)',
          color: 'var(--color-text-primary)',
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
      {action && (
        <>
          <div style={{ height: 'var(--spacing-large)' }} />
          <CtaButton>{action}</CtaButton>
        </>
      )}
    </div>
  );
}

/** fullPage variant container — transparent bg, full stretch. */
function FullPageEmpty({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: string;
}) {
  return (
    <div
      className="mds-spec-state mds-spec-state--empty-full"
      style={{ width: '100%' }}
    >
      <EmptyContent title={title} subtitle={subtitle} action={action} iconSize={48} />
    </div>
  );
}

/** card variant container — surface bg + radius-card, no CTA. */
function CardEmpty({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div
      className="mds-spec-state mds-spec-state--empty-card"
      style={{
        background: 'var(--color-surface)',
        borderRadius: 'var(--radius-card)',
        width: '100%',
      }}
    >
      <EmptyContent
        title={title}
        subtitle={subtitle}
        iconSize={32}
        iconFaded
        padding={24}
      />
    </div>
  );
}

/** inline variant container — surface bg + border + radius-card, no icon, no CTA. */
function InlineEmpty({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div
      className="mds-spec-state mds-spec-state--empty-inline"
      style={{
        background: 'var(--color-surface)',
        border: '1px solid var(--color-divider)',
        borderRadius: 'var(--radius-card)',
        width: '100%',
      }}
    >
      <EmptyContent
        title={title}
        subtitle={subtitle}
        icon={null}
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
export default function MinglitEmptyStateSpec() {
  return (
    <div className="mds-spec">
      {/* Hero — fullPage with CTA. */}
      <div className="mds-spec__hero">
        <FullPageEmpty
          title="저장된 모임이 없어요"
          subtitle="새로운 모임을 만들거나 참여해보세요."
          action="모임 찾기"
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
            <EmptyIcon size={48} />
            <span
              className="mds-spec__anatomy-label"
              style={{ top: '50%', right: -160, transform: 'translateY(-50%)' }}
            >
              icon — 48px fullPage · 32px card
            </span>
          </div>
          {/* spacing-medium gap */}
          <div
            style={{
              height: 'var(--spacing-medium)',
              width: 2,
              background: 'var(--color-primary)',
              opacity: 0.5,
              margin: '2px auto',
            }}
          />
          {/* Title */}
          <div style={{ position: 'relative', display: 'inline-flex' }}>
            <p
              style={{
                margin: 0,
                fontWeight: 600,
                fontSize: 'var(--typography-font-size-button)',
                color: 'var(--color-text-primary)',
              }}
            >
              저장된 모임이 없어요
            </p>
            <span
              className="mds-spec__anatomy-label"
              style={{ top: '50%', left: -172, transform: 'translateY(-50%)' }}
            >
              title — font-size-button · semi-bold
            </span>
          </div>
          {/* spacing-small gap */}
          <div
            style={{
              height: 'var(--spacing-small)',
              width: 2,
              background: 'var(--color-primary)',
              opacity: 0.5,
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
              새로운 모임을 만들거나 참여해보세요.
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
              background: 'var(--color-primary)',
              opacity: 0.5,
              margin: '2px auto',
            }}
          />
          {/* CTA */}
          <div style={{ position: 'relative', display: 'inline-flex' }}>
            <CtaButton>모임 찾기</CtaButton>
            <span
              className="mds-spec__anatomy-label"
              style={{ top: '50%', left: -168, transform: 'translateY(-50%)' }}
            >
              action — fullPage only · spacing-large above
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
                  <FullPageEmpty
                    title="저장된 모임이 없어요"
                    subtitle="새로운 모임을 만들어보세요."
                    action="모임 만들기"
                  />
                ),
                description:
                  '탭/페이지 레벨. 48px 아이콘 + 선택적 CTA. 투명 배경. 아이콘 opacity 0.45.',
              },
              {
                name: 'card',
                preview: (
                  <CardEmpty
                    title="아직 참여한 이벤트가 없어요"
                    subtitle="이벤트에 참여해보세요."
                  />
                ),
                description:
                  '카드/섹션 레벨. 32px 아이콘 (더 흐리게). surface 배경 + radius-card. CTA 없음.',
              },
              {
                name: 'inline',
                preview: (
                  <InlineEmpty
                    title="선택된 항목 없음"
                    subtitle="위에서 항목을 선택하세요."
                  />
                ),
                description:
                  '폼/입력 플레이스홀더. 아이콘 숨김. surface 배경 + divider 보더 + radius-card. CTA 없음.',
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
                  <FullPageEmpty
                    title="저장된 모임이 없어요"
                    subtitle="새로운 모임을 만들거나 참여해보세요."
                    action="모임 찾기"
                  />
                ),
                description:
                  '빈 상태는 단일 상태 — 항상 "default". 인터랙션 상태 없음 (CTA 버튼 자체의 상태는 MinglitButton 스펙 참조).',
              },
            ]}
          />
        </div>
      </div>

      {/* Composition */}
      <div>
        <p className="mds-spec__label">Composition</p>
        <div className="mds-spec__panel" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-medium)' }}>
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
              fullPage — MinglitContentLayout 본문 영역을 채울 때
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
              {/* mock appbar */}
              <div
                style={{
                  height: 24,
                  background: 'var(--color-surface)',
                  borderRadius: 4,
                  margin: 4,
                }}
              />
              <FullPageEmpty
                title="아직 참여한 이벤트가 없어요"
                subtitle="이벤트를 검색해서 참여해보세요."
                action="이벤트 찾기"
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
              card — MinglitContentCard 내부 섹션 빈 상태
            </p>
            <div
              style={{
                border: '1px solid var(--color-divider)',
                borderRadius: 'var(--radius-card)',
                padding: 'var(--spacing-medium)',
                background: 'var(--color-background)',
              }}
            >
              <CardEmpty
                title="등록된 공지사항이 없어요"
                subtitle="파트너가 공지를 남기면 여기에 표시됩니다."
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

function DoSpecificCopy() {
  return (
    <FullPageEmpty
      title="저장된 모임이 없어요"
      subtitle="새로운 모임을 만들거나 참여해보세요."
    />
  );
}

function DontGenericCopy() {
  return (
    <FullPageEmpty
      title="Empty"
      subtitle="No data available."
    />
  );
}

function DoCtaWhenActionable() {
  return (
    <FullPageEmpty
      title="아직 참여한 이벤트가 없어요"
      subtitle="이벤트를 검색해서 참여해보세요."
      action="이벤트 찾기"
    />
  );
}

function DontErrorForEmpty() {
  // shows what NOT to do — error icon color on an empty state
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: 24, gap: 12 }}>
      <span style={{ fontSize: 32, color: 'var(--color-error)' }}>⚠</span>
      <p style={{ margin: 0, fontWeight: 600, color: 'var(--color-error)' }}>오류</p>
      <p style={{ margin: 0, fontSize: 'var(--typography-font-size-body)', color: 'var(--color-text-secondary)' }}>
        저장된 모임이 없습니다
      </p>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-specific-copy': DoSpecificCopy,
  'dont-generic-copy': DontGenericCopy,
  'do-cta-when-actionable': DoCtaWhenActionable,
  'dont-error-for-empty': DontErrorForEmpty,
};

export { Search };
