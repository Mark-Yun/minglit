/**
 * Inline visual spec — MinglitAlert
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/common/minglit_alert.dart
 *
 * Variants: info (showAlert) · destructive-confirm (showConfirm + isDestructive)
 * Static API: MinglitAlert.show() · MinglitAlert.showConfirm()
 * Scaffold:   "Centered dialog" — this component IS the dialog card on the scrim.
 *
 * Two exports:
 *   default          — visual playground (Hero / Anatomy / Variants / Compositions)
 *   GUIDELINE_RECIPES — keyed do/don't previews for guideline rows
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// New CSS — injected via <style> in the component.
// Class prefix: mds-spec-overlay (no conflict with globals.css mds-spec-*).
// ---------------------------------------------------------------------------
const OVERLAY_CSS = `
/* ── faux phone shell ─────────────────────────────────────────────────── */
.mds-spec-overlay__phone {
  width: 280px;
  height: 480px;
  border-radius: 28px;
  border: 2px solid var(--color-divider);
  background: white;
  position: relative;
  overflow: hidden;
  flex-shrink: 0;
}

/* scrim layer — sits above phone content */
.mds-spec-overlay__scrim {
  position: absolute;
  inset: 0;
  background: var(--color-scrim);
  display: flex;
  align-items: center;
  justify-content: center;
}

/* background content peeking through scrim */
.mds-spec-overlay__bg-content {
  position: absolute;
  inset: 0;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.mds-spec-overlay__bg-row {
  height: 14px;
  border-radius: 4px;
  background: var(--color-surface);
}
.mds-spec-overlay__bg-row--tall { height: 48px; }
.mds-spec-overlay__bg-appbar {
  height: 24px;
  border-radius: 4px;
  background: var(--color-surface);
  margin-bottom: 4px;
}

/* ── alert / dialog card — M3 mobile 톤 (2026-05-01 spec contract):
   - 외부 insetPadding 16 H · 24 V (M3 mobile 권장)
   - 내부 padding 24 (M3 default)
   - title↔content 갭 16 / content↔actions 갭 24 (M3 표준 — 내부 vertical 호흡)
   - radius 28 (M3 default)
   - actions 우측 정렬 small text buttons */
.mds-spec-overlay__dialog-card {
  width: 220px;
  background: white;
  border-radius: var(--radius-dialog);   /* 28px — M3 default */
  padding: var(--spacing-large);         /* 24px */
  display: flex;
  flex-direction: column;
  gap: var(--spacing-medium);            /* 16px — title↔content gap */
  box-shadow: 0 8px 24px rgba(0,0,0,0.25);
  position: relative;
  z-index: 1;
}
.mds-spec-overlay__dialog-title {
  font-size: 18px;
  font-weight: 700;
  color: var(--color-text-primary);
  line-height: 1.35;
}
.mds-spec-overlay__dialog-title--destructive {
  color: var(--color-text-primary);     /* destructive도 title은 일반 색 (option C) */
}
.mds-spec-overlay__dialog-icon {
  display: inline-flex;
  align-items: center;
  gap: var(--spacing-small);
}
.mds-spec-overlay__dialog-content {
  font-size: 16px;
  color: var(--color-text-secondary);
  line-height: 1.5;
}
.mds-spec-overlay__dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--spacing-sm);                /* 12px — M3 minimum 8보다 살짝 분리. 클릭미스 방지 */
  margin-top: var(--spacing-small);      /* 16(card gap) + 8(this) = 24 (content↔actions, M3) */
}

/* ── anatomy labels ──────────────────────────────────────────────────── */
.mds-spec-overlay__anatomy-wrap {
  position: relative;
  display: flex;
  justify-content: center;
  padding: 48px 24px;
  background: var(--color-surface);
  border-radius: var(--radius-card);
  overflow: visible;
}
.mds-spec-overlay__anatomy-label {
  position: absolute;
  font: 500 10px/1.2 ui-monospace, monospace;
  color: var(--color-primary);
  background: white;
  border: 1px solid var(--color-divider);
  padding: 3px 6px;
  border-radius: 4px;
  white-space: nowrap;
  pointer-events: none;
}

/* ── preview table cell centering ────────────────────────────────────── */
.mds-spec-overlay__phone-cell {
  display: flex;
  align-items: center;
  justify-content: center;
}

/* ── bottom sheet specific ───────────────────────────────────────────── */
.mds-spec-overlay__sheet {
  position: absolute;
  left: 0; right: 0; bottom: 0;
  background: white;
  border-top-left-radius: var(--radius-card);   /* 16px */
  border-top-right-radius: var(--radius-card);
  padding: var(--spacing-small) 0 var(--spacing-medium);
  display: flex;
  flex-direction: column;
  gap: var(--spacing-small);
}
.mds-spec-overlay__sheet-handle {
  width: 28px; height: 3px;
  background: var(--color-divider);
  border-radius: 999px;
  align-self: center;
  margin-bottom: var(--spacing-xsmall);
}
.mds-spec-overlay__sheet-title {
  font-size: 14px;
  font-weight: 700;
  color: var(--color-text-primary);
  padding: 0 var(--spacing-medium);
}
.mds-spec-overlay__sheet-row {
  height: 36px;
  margin: 0 var(--spacing-medium);
  border-radius: 6px;
  background: var(--color-surface);
}
`;

// ---------------------------------------------------------------------------
// Shared atoms
// ---------------------------------------------------------------------------

function OverlayStyles() {
  return <style dangerouslySetInnerHTML={{ __html: OVERLAY_CSS }} />;
}

/** Faux phone with scrim + dialog card centered */
function PhoneWithDialog({
  title,
  content,
  destructive = false,
  showCancel = true,
  size = 'compact',
}: {
  title: string;
  content?: string;
  destructive?: boolean;
  showCancel?: boolean;
  /** 'screen' = 375×812 (Hero 전용) · 'compact' = 280×480 (PreviewTable 등). */
  size?: 'screen' | 'compact';
}) {
  const dim = size === 'screen' ? { width: 375, height: 812 } : undefined;
  return (
    <div className="mds-spec-overlay__phone" style={dim}>
      {/* background content behind scrim */}
      <div className="mds-spec-overlay__bg-content">
        <div className="mds-spec-overlay__bg-appbar" />
        <div className="mds-spec-overlay__bg-row mds-spec-overlay__bg-row--tall" />
        <div className="mds-spec-overlay__bg-row" />
        <div className="mds-spec-overlay__bg-row" />
        <div className="mds-spec-overlay__bg-row" style={{ width: '70%' }} />
      </div>

      {/* scrim overlay */}
      <div className="mds-spec-overlay__scrim">
        {/* M3 mobile 톤 (2026-05-01):
            - 외부 16 H · 24 V (insetPadding) → screen mode 폭 343
            - 내부 padding 24 / radius 28 / 우측 정렬 actions
            - destructive 버튼만 빨강 (option C) */}
        <div
          className="mds-spec-overlay__dialog-card"
          style={size === 'screen' ? { width: 343 } : undefined}
        >
          <span className="mds-spec-overlay__dialog-title">{title}</span>
          {content && (
            <span className="mds-spec-overlay__dialog-content">{content}</span>
          )}

          <div className="mds-spec-overlay__dialog-actions">
            {showCancel && (
              <button
                className="mds-spec-btn mds-spec-btn--text mds-spec-btn--sm"
                style={{ height: 44, fontSize: 16, color: 'var(--color-text-secondary)', fontWeight: 500 }}
              >
                취소
              </button>
            )}
            <button
              className={`mds-spec-btn mds-spec-btn--sm${destructive ? ' mds-spec-btn--destructive' : ' mds-spec-btn--primary'}`}
              style={{ height: 44, fontSize: 16, fontWeight: destructive ? 700 : 600 }}
            >
              {destructive ? '삭제' : '확인'}
            </button>
          </div>
        </div>
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
          <th style={{ width: 120 }}>Name</th>
          <th style={{ width: 300 }}>{previewLabel}</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((r) => (
          <tr key={r.name}>
            <td><code>{r.name}</code></td>
            <td className="mds-spec-overlay__phone-cell">{r.preview}</td>
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
export default function MinglitAlertSpec() {
  return (
    <div className="mds-spec">
      <OverlayStyles />

      {/* ── Hero — 풀스크린(375×812) phone 두 개. 좁은 화면에선 wrap. */}
      <div className="mds-spec__hero" style={{ gap: 24, flexWrap: 'wrap', justifyContent: 'center' }}>
        <PhoneWithDialog
          title="정말 삭제하시겠어요?"
          content="삭제된 파티는 복구할 수 없습니다."
          destructive
          size="screen"
        />
        <PhoneWithDialog
          title="정말 나가시겠어요?"
          content="저장하지 않은 내용이 사라집니다."
          showCancel
          size="screen"
        />
      </div>
      <p className="mds-spec__label" style={{ textAlign: 'center', marginTop: -8 }}>
        좌: showConfirm (destructive) · 우: showConfirm (info)
      </p>

      {/* ── Anatomy ──────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div className="mds-spec-overlay__anatomy-wrap">
          {/* anatomy labels */}
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 8, left: '50%', transform: 'translateX(-50%)' }}>
            color-scrim · rgba(0,0,0,0.5) — 화면 전체 덮음
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 40, left: 8 }}>
            insetPadding: medium 16 H · large 24 V (외부 여백, M3 mobile)
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 40, right: 8 }}>
            radius-dialog · 28px — card corners
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 96, right: 8 }}>
            spacing-large · 24px — 내부 padding 좌우상하
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 130, left: 8 }}>
            spacing-medium · 16px — title↔content 갭
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ bottom: 40, left: 8 }}>
            spacing-large · 24px — content↔actions 갭
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ bottom: 8, left: '50%', transform: 'translateX(-50%)' }}>
            spacing-small · 8px — button gap in action row
          </span>

          {/* faux phone */}
          <div className="mds-spec-overlay__phone" style={{ width: 220, height: 360 }}>
            <div className="mds-spec-overlay__bg-content">
              <div className="mds-spec-overlay__bg-appbar" />
              <div className="mds-spec-overlay__bg-row mds-spec-overlay__bg-row--tall" />
              <div className="mds-spec-overlay__bg-row" />
              <div className="mds-spec-overlay__bg-row" />
            </div>
            <div className="mds-spec-overlay__scrim">
              <div className="mds-spec-overlay__dialog-card" style={{ width: 170 }}>
                <span className="mds-spec-overlay__dialog-title">정말 삭제하시겠어요?</span>
                <span className="mds-spec-overlay__dialog-content">삭제된 파티는 복구할 수 없습니다.</span>
                <div className="mds-spec-overlay__dialog-actions">
                  <button className="mds-spec-btn mds-spec-btn--text mds-spec-btn--sm" style={{ height: 38, fontSize: 13, color: 'var(--color-text-secondary)', fontWeight: 500 }}>취소</button>
                  <button className="mds-spec-btn mds-spec-btn--destructive mds-spec-btn--sm" style={{ height: 38, fontSize: 13 }}>삭제</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ── Variants ─────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Variants</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'alert (info)',
                preview: (
                  <PhoneWithDialog
                    title="알림"
                    content="이미 최신 버전입니다."
                    showCancel={false}
                  />
                ),
                description: 'MinglitAlert.show() — 단일 확인 버튼. 정보 고지, 에러 알림. type=info.',
              },
              {
                name: 'confirm (info)',
                preview: (
                  <PhoneWithDialog
                    title="정말 나가시겠어요?"
                    content="저장되지 않은 내용이 사라집니다."
                    showCancel
                  />
                ),
                description: 'MinglitAlert.showConfirm() — 취소+확인 페어. 뒤로가기 확인, 로그아웃 등.',
              },
              {
                name: 'confirm (destructive)',
                preview: (
                  <PhoneWithDialog
                    title="정말 삭제하시겠어요?"
                    content="삭제된 파티는 복구할 수 없습니다."
                    destructive
                  />
                ),
                description: 'showConfirm(isDestructive: true) — 확인 버튼만 빨강 (bold). 아이콘 / 타이틀은 일반 색. 삭제·탈퇴 등 비가역 액션에 사용.',
              },
            ]}
          />
        </div>
      </div>

      {/* ── Compositions ─────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Compositions</p>
        <div className="mds-spec__panel">
          <p className="mds-text-body" style={{ color: 'var(--color-text-secondary)', marginBottom: 12 }}>
            Destructive confirm는 반드시 <code>MinglitButton.destructive</code>와 짝 — 버튼 탭 → showConfirm 순서를 지킨다.
          </p>
          <div className="mds-spec__row">
            <button className="mds-spec-btn mds-spec-btn--destructive mds-spec-btn--md">
              파티 삭제하기
            </button>
            <span style={{ fontSize: 13, color: 'var(--color-text-secondary)' }}>
              → showConfirm(isDestructive: true) →
            </span>
            <PhoneWithDialog
              title="정말 삭제하시겠어요?"
              content="삭제된 파티는 복구할 수 없습니다."
              destructive
            />
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Guideline recipes
// ---------------------------------------------------------------------------
function DoConfirmDestructive() {
  return (
    <PhoneWithDialog
      title="정말 삭제하시겠어요?"
      content="삭제된 파티는 복구할 수 없습니다."
      destructive
    />
  );
}

function DontSkipConfirm() {
  return (
    <button className="mds-spec-btn mds-spec-btn--destructive mds-spec-btn--md">
      즉시 삭제
    </button>
  );
}

function DoAlertForInfo() {
  return (
    <PhoneWithDialog
      title="저장되었습니다"
      showCancel={false}
    />
  );
}

function DontLongContentAlert() {
  return (
    <PhoneWithDialog
      title="이용약관"
      content="제1조 (목적) 이 약관은 서비스의 이용조건 및 절차, 권리·의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다. 제2조…"
      showCancel={false}
    />
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-confirm-destructive': DoConfirmDestructive,
  'dont-skip-confirm': DontSkipConfirm,
  'do-alert-for-info': DoAlertForInfo,
  'dont-long-content-alert': DontLongContentAlert,
};
