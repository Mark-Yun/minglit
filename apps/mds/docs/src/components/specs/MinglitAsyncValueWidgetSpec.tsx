/**
 * Inline visual spec for MinglitAsyncValueWidget.
 *
 * Source of truth (Dart): shared/packages/mds/core/.../minglit_async_value_widget.dart
 *   Generic StatelessWidget<T> — wraps AsyncValue<T>.when(data/loading/error)
 *   loading: defaults to MinglitCircularProgressIndicator()
 *   error:   defaults to _DefaultErrorView (icon + "오류가 발생했습니다.")
 *   showErrorDetails: false (default) — hides error.toString()
 *   Custom loading / error slots via Function callbacks
 *
 * Two exports:
 *   default          — visual playground (Hero 3-state matrix, Anatomy,
 *                      Props, Custom slots, Composition with Riverpod pattern)
 *   GUIDELINE_RECIPES — keyed do/don't preview components
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Shared atoms (no Flutter imports)
// ---------------------------------------------------------------------------

function CircleSpinner({ size = 24, color }: { size?: number; color?: string }) {
  const c = color ?? 'var(--color-primary)';
  const sw = 2;
  const r = (size - sw * 2) / 2;
  const circ = 2 * Math.PI * r;
  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      aria-label="로딩 중"
      role="img"
      style={{ display: 'block' }}
    >
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="var(--color-divider)" strokeWidth={sw} />
      <circle
        cx={size / 2} cy={size / 2} r={r} fill="none" stroke={c} strokeWidth={sw}
        strokeLinecap="round"
        strokeDasharray={`${circ * 0.7} ${circ * 0.3}`}
        style={{ transformOrigin: 'center', animation: 'mds-spec-loader-spin 0.9s linear infinite' }}
      />
    </svg>
  );
}

function SkeletonBlock({ width, height, radius }: { width?: number | string; height?: number | string; radius?: number | string }) {
  return (
    <div
      aria-hidden="true"
      style={{
        width: width ?? '100%',
        height: height ?? 14,
        borderRadius: radius ?? 'var(--radius-small)',
        background: 'var(--color-divider)',
        animation: 'mds-spec-shimmer 1.4s ease-in-out infinite',
      }}
    />
  );
}

// ---------------------------------------------------------------------------
// State card — reusable 3-state display
// ---------------------------------------------------------------------------
function StateCard({
  label,
  state,
  children,
}: {
  label: string;
  state: 'data' | 'loading' | 'error';
  children: React.ReactNode;
}) {
  const accent =
    state === 'data'    ? 'var(--color-success)' :
    state === 'loading' ? 'var(--color-primary)' :
                          'var(--color-error)';
  return (
    <div
      className="mds-spec-async-state-card"
      style={{
        flex: '1 1 0',
        minWidth: 140,
        border: `1.5px solid ${accent}`,
        borderRadius: 'var(--radius-card)',
        padding: 'var(--spacing-medium)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--spacing-small)',
        background: 'var(--color-surface)',
      }}
    >
      <div style={{
        fontSize: 'var(--typography-font-size-caption)',
        fontWeight: 'var(--typography-font-weight-semi-bold)',
        color: accent,
        letterSpacing: '0.04em',
        textTransform: 'uppercase',
      }}>
        {label}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 64 }}>
        {children}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Error SVG icon (no Flutter)
// ---------------------------------------------------------------------------
function ErrorIcon({ size = 32, color = 'var(--color-error)' }: { size?: number; color?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={color} aria-hidden>
      <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z" />
    </svg>
  );
}

// ---------------------------------------------------------------------------
// Default export — visual playground.
// ---------------------------------------------------------------------------
export default function MinglitAsyncValueWidgetSpec() {
  return (
    <div className="mds-spec">
      {/* Hero — 3-state matrix */}
      <div className="mds-spec__hero">
        <div style={{ display: 'flex', gap: 'var(--spacing-small)', flexWrap: 'wrap', justifyContent: 'center', width: '100%' }}>
          <StateCard label="loading" state="loading">
            <CircleSpinner size={24} />
          </StateCard>
          <div style={{ display: 'flex', alignItems: 'center', fontSize: 20, color: 'var(--color-text-secondary)', flexShrink: 0 }}>→</div>
          <StateCard label="data" state="data">
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontWeight: 'var(--typography-font-weight-semi-bold)', fontSize: 'var(--typography-font-size-body)', color: 'var(--color-text-primary)' }}>
                이벤트 목록
              </div>
              <div style={{ fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)', marginTop: 4 }}>
                3건 로드됨
              </div>
            </div>
          </StateCard>
          <div style={{ display: 'flex', alignItems: 'center', fontSize: 20, color: 'var(--color-text-secondary)', flexShrink: 0 }}>↘</div>
          <StateCard label="error" state="error">
            <div style={{ textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 'var(--spacing-xsmall)' }}>
              <ErrorIcon size={28} />
              <span style={{ fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)' }}>
                오류가 발생했습니다.
              </span>
            </div>
          </StateCard>
        </div>
      </div>

      {/* Anatomy */}
      <div>
        <p className="mds-spec__label">Anatomy — AsyncValue.when() dispatch</p>
        <div className="mds-spec__panel">
          <div
            className="mds-spec-async"
            style={{
              border: '1px solid var(--color-divider)',
              borderRadius: 'var(--radius-card)',
              padding: 'var(--spacing-medium)',
              fontFamily: 'monospace',
              fontSize: 'var(--typography-font-size-caption)',
              color: 'var(--color-text-primary)',
              background: 'var(--color-surface)',
            }}
          >
            <div>
              <span style={{ color: 'var(--color-primary)', fontWeight: 'var(--typography-font-weight-semi-bold)' }}>MinglitAsyncValueWidget&lt;T&gt;</span>
            </div>
            <div style={{ marginLeft: 12, marginTop: 4 }}>
              <span style={{ color: 'var(--color-text-secondary)' }}>value: AsyncValue&lt;T&gt;</span>
              <span style={{ color: 'var(--color-text-secondary)', display: 'block' }}>data:    </span>
              <span style={{ marginLeft: 12, color: 'var(--color-success)' }}>Widget Function(T) — 데이터 빌드</span>
              <span style={{ color: 'var(--color-text-secondary)', display: 'block' }}>loading: </span>
              <span style={{ marginLeft: 12, color: 'var(--color-primary)' }}>() → MinglitCircularProgressIndicator()</span>
              <span style={{ color: 'var(--color-text-secondary)', display: 'block' }}>error:   </span>
              <span style={{ marginLeft: 12, color: 'var(--color-error)' }}>(err, stack) → _DefaultErrorView</span>
            </div>
          </div>
          <p style={{ fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)', marginTop: 8, marginBottom: 0 }}>
            <strong>value.when()</strong>은 AsyncValue 상태 변화 시 자동으로 Riverpod이 위젯 재빌드를 트리거한다.
            ConsumerWidget 또는 ConsumerStatefulWidget 안에서만 사용한다.
          </p>
        </div>
      </div>

      {/* Props table */}
      <div>
        <p className="mds-spec__label">Props</p>
        <div className="mds-spec__panel">
          <table className="mds-spec__preview-table">
            <thead>
              <tr>
                <th style={{ width: 160 }}>Prop</th>
                <th style={{ width: 200 }}>Type</th>
                <th>Notes</th>
              </tr>
            </thead>
            <tbody>
              {[
                { name: 'value', type: 'AsyncValue<T>', notes: '필수. Riverpod provider의 ref.watch() 결과를 넘긴다.' },
                { name: 'data', type: 'Widget Function(T)', notes: '필수. 데이터가 있을 때 빌드하는 위젯 빌더.' },
                { name: 'loading', type: 'Widget Function()?', notes: 'null이면 MinglitCircularProgressIndicator 사용. 커스텀 스켈레톤 주입에 사용.' },
                { name: 'error', type: 'Widget Function(Object, StackTrace)?', notes: 'null이면 기본 에러 뷰. MinglitErrorState + onRetry 조합 권장.' },
                { name: 'showErrorDetails', type: 'bool (default: false)', notes: 'true 시 error.toString()을 기본 에러 뷰에 노출. 개발/QA 환경 전용.' },
              ].map((r) => (
                <tr key={r.name}>
                  <td><code>{r.name}</code></td>
                  <td style={{ fontFamily: 'monospace', fontSize: 12 }}>{r.type}</td>
                  <td style={{ color: 'var(--color-text-secondary)' }}>{r.notes}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Default states */}
      <div>
        <p className="mds-spec__label">Default States</p>
        <div className="mds-spec__panel">
          <div style={{ display: 'flex', gap: 'var(--spacing-medium)', flexWrap: 'wrap' }}>
            {/* Loading default */}
            <div style={{ flex: '1 1 160px' }}>
              <p style={{ margin: '0 0 8px', fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)' }}>
                <strong>loading</strong> (default)
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

            {/* Error default */}
            <div style={{ flex: '1 1 160px' }}>
              <p style={{ margin: '0 0 8px', fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)' }}>
                <strong>error</strong> (default — showErrorDetails=false)
              </p>
              <div style={{
                border: '1px dashed var(--color-divider)',
                borderRadius: 'var(--radius-card)',
                padding: 'var(--spacing-large)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 'var(--spacing-small)',
                minHeight: 80,
              }}>
                <ErrorIcon size={32} />
                <span style={{ fontSize: 'var(--typography-font-size-body)', fontWeight: 'var(--typography-font-weight-semi-bold)' }}>
                  오류가 발생했습니다.
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Custom slots */}
      <div>
        <p className="mds-spec__label">Custom Slots — 스켈레톤 + 에러 리트라이</p>
        <div className="mds-spec__panel">
          <div style={{ display: 'flex', gap: 'var(--spacing-medium)', flexWrap: 'wrap' }}>
            {/* Custom loading — skeleton */}
            <div style={{ flex: '1 1 180px' }}>
              <p style={{ margin: '0 0 8px', fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)' }}>
                loading: () → MinglitSkeleton 조합
              </p>
              <div style={{
                border: '1px dashed var(--color-divider)',
                borderRadius: 'var(--radius-card)',
                padding: 'var(--spacing-medium)',
                display: 'flex',
                flexDirection: 'column',
                gap: 'var(--spacing-small)',
              }}>
                <SkeletonBlock height={12} radius="var(--radius-card)" width="100%" />
                <SkeletonBlock height={80} radius="var(--radius-card)" />
                <SkeletonBlock height={12} width="70%" />
                <SkeletonBlock height={12} width="50%" />
              </div>
            </div>

            {/* Custom error — with retry */}
            <div style={{ flex: '1 1 180px' }}>
              <p style={{ margin: '0 0 8px', fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)' }}>
                error: (err, _) → MinglitErrorState + onRetry
              </p>
              <div style={{
                border: '1px dashed var(--color-divider)',
                borderRadius: 'var(--radius-card)',
                padding: 'var(--spacing-medium)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 'var(--spacing-small)',
              }}>
                <ErrorIcon size={28} />
                <span style={{ fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)', textAlign: 'center' }}>
                  이벤트 목록을 불러오지 못했습니다.
                </span>
                <button
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    height: 36,
                    padding: '0 var(--spacing-medium)',
                    background: 'var(--color-primary)',
                    color: '#fff',
                    border: 'none',
                    borderRadius: 'var(--radius-button)',
                    fontSize: 'var(--typography-font-size-caption)',
                    cursor: 'pointer',
                    fontWeight: 'var(--typography-font-weight-medium)',
                  }}
                >
                  다시 시도
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Composition — Riverpod pattern */}
      <div>
        <p className="mds-spec__label">Composition — Riverpod 패턴</p>
        <div className="mds-spec__panel">
          <p style={{ fontSize: 'var(--typography-font-size-caption)', color: 'var(--color-text-secondary)', marginTop: 0, marginBottom: 8 }}>
            ConsumerWidget에서 provider watch → MinglitAsyncValueWidget 전달 → 자동 상태 교체.
            상태가 바뀔 때마다 Riverpod이 위젯 재빌드를 트리거한다.
          </p>
          <div style={{
            background: 'var(--color-surface)',
            border: '1px solid var(--color-divider)',
            borderRadius: 'var(--radius-card)',
            padding: 'var(--spacing-medium)',
            fontFamily: 'monospace',
            fontSize: 12,
            color: 'var(--color-text-primary)',
            lineHeight: 1.6,
          }}>
            <div style={{ color: 'var(--color-text-secondary)' }}>{'// ConsumerWidget 안'}</div>
            <div>{'final events = ref.watch(eventsProvider);'}</div>
            <div style={{ marginTop: 4 }}><span style={{ color: 'var(--color-primary)', fontWeight: 'bold' }}>MinglitAsyncValueWidget</span>{'<List<Event>>('}</div>
            <div style={{ marginLeft: 16 }}>{'value: events,'}</div>
            <div style={{ marginLeft: 16 }}>{'loading: () => '}<span style={{ color: 'var(--color-primary)' }}>EventListSkeleton</span>{'(),'}</div>
            <div style={{ marginLeft: 16 }}>{'error: (e, _) => '}<span style={{ color: 'var(--color-error)' }}>MinglitErrorState</span>{'(onRetry: () => ref.invalidate(eventsProvider)),'}</div>
            <div style={{ marginLeft: 16 }}>{'data: (list) => '}<span style={{ color: 'var(--color-success)' }}>EventListView</span>{'(events: list),'}</div>
            <div>{')'}</div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Recipes — do/don't preview components
// ---------------------------------------------------------------------------

function DoSkeletonLoading() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8, width: 200 }}>
      <div style={{ height: 80, background: 'var(--color-divider)', borderRadius: 'var(--radius-card)', animation: 'mds-spec-shimmer 1.4s ease-in-out infinite' }} />
      <div style={{ height: 12, width: '80%', background: 'var(--color-divider)', borderRadius: 'var(--radius-small)', animation: 'mds-spec-shimmer 1.4s ease-in-out infinite' }} />
      <div style={{ height: 12, width: '60%', background: 'var(--color-divider)', borderRadius: 'var(--radius-small)', animation: 'mds-spec-shimmer 1.4s ease-in-out infinite' }} />
    </div>
  );
}

function DontNullForError() {
  return (
    <div style={{
      width: 200,
      height: 80,
      border: '1px dashed var(--color-error)',
      borderRadius: 'var(--radius-card)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: 'var(--typography-font-size-caption)',
      color: 'var(--color-error)',
      textAlign: 'center',
      padding: 8,
    }}>
      error 슬롯 null — 빈 화면. 사용자에게 아무 피드백 없음
    </div>
  );
}

function DoRetryOnError() {
  return (
    <div style={{
      width: 200,
      border: '1px solid var(--color-divider)',
      borderRadius: 'var(--radius-card)',
      padding: 'var(--spacing-medium)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 8,
    }}>
      <ErrorIcon size={24} />
      <span style={{ fontSize: 10, color: 'var(--color-text-secondary)', textAlign: 'center' }}>
        프로필 정보를 불러오지 못했습니다.
      </span>
      <button style={{
        height: 28, padding: '0 12px',
        background: 'var(--color-primary)', color: '#fff',
        border: 'none', borderRadius: 'var(--radius-button)',
        fontSize: 10, cursor: 'pointer',
      }}>
        다시 시도
      </button>
    </div>
  );
}

function DontShowRawError() {
  return (
    <div style={{
      width: 200,
      border: '1px dashed var(--color-error)',
      borderRadius: 'var(--radius-card)',
      padding: 'var(--spacing-medium)',
      fontSize: 10,
      color: 'var(--color-error)',
      wordBreak: 'break-all',
    }}>
      showErrorDetails=true in prod:<br />
      <span style={{ opacity: 0.7 }}>SocketException: Failed host lookup ...</span>
    </div>
  );
}

function DoInvalidateOnRetry() {
  return (
    <div style={{ fontSize: 'var(--typography-font-size-caption)', fontFamily: 'monospace', color: 'var(--color-text-primary)', lineHeight: 1.6 }}>
      <div style={{ color: 'var(--color-text-secondary)' }}>{'// error callback 안'}</div>
      <div>{'onRetry: () =>'}</div>
      <div style={{ marginLeft: 12 }}>{'ref.invalidate('}</div>
      <div style={{ marginLeft: 24 }}>{'eventsProvider'}</div>
      <div style={{ marginLeft: 12 }}>{'),'}</div>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-skeleton-loading': DoSkeletonLoading,
  'dont-null-for-error': DontNullForError,
  'do-retry-on-error': DoRetryOnError,
  'dont-show-raw-error': DontShowRawError,
  'do-invalidate-on-retry': DoInvalidateOnRetry,
};
