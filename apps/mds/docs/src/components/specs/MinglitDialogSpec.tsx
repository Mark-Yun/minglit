/**
 * Inline visual spec — MinglitDialog
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/common/minglit_dialog.dart
 *
 * Key difference from MinglitAlert:
 *   - content is a Widget (arbitrary child), not a plain String
 *   - No built-in destructive / info type — caller controls actions list
 *   - Larger card by convention (more vertical space for custom content)
 *
 * Scaffold: "Centered dialog" — this component IS the dialog card on the scrim.
 *
 * Two exports:
 *   default          — visual playground
 *   GUIDELINE_RECIPES — keyed do/don't previews
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Shared CSS is defined in MinglitAlertSpec.tsx (mds-spec-overlay__*).
// MinglitDialogSpec reuses those classes — no separate <style> needed as long
// as MinglitAlertSpec is loaded first on the page. For standalone safety we
// re-inject the minimal subset needed here with a guard class.
// ---------------------------------------------------------------------------
const DIALOG_CSS = `
/* guard: only inject once */
.mds-spec-overlay__phone { /* already defined in MinglitAlertSpec */ }

/* dialog card — wider than alert card for rich custom content */
.mds-spec-overlay__dialog-card--wide {
  width: 236px;
}

/* custom content area inside dialog */
.mds-spec-overlay__dialog-custom-content {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-small);
}
.mds-spec-overlay__dialog-field {
  height: 28px;
  border-radius: var(--radius-input);
  background: var(--color-surface);
  border: 1px solid var(--color-divider);
  padding: 0 var(--spacing-small);
  display: flex;
  align-items: center;
}
.mds-spec-overlay__dialog-field-label {
  font-size: 11px;
  color: var(--color-text-secondary);
}
.mds-spec-overlay__dialog-divider {
  height: 1px;
  background: var(--color-divider);
  margin: var(--spacing-xsmall) 0;
}
`;

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

function DialogStyles() {
  return <style dangerouslySetInnerHTML={{ __html: DIALOG_CSS }} />;
}

/** Faux phone with a dialog containing arbitrary children */
function PhoneWithCustomDialog({
  title,
  children,
  actions,
}: {
  title: string;
  children: React.ReactNode;
  actions?: React.ReactNode;
}) {
  return (
    <div
      className="mds-spec-overlay__phone"
      style={{ width: 280, height: 480 }}
    >
      {/* background content */}
      <div className="mds-spec-overlay__bg-content">
        <div className="mds-spec-overlay__bg-appbar" />
        <div className="mds-spec-overlay__bg-row mds-spec-overlay__bg-row--tall" />
        <div className="mds-spec-overlay__bg-row" />
        <div className="mds-spec-overlay__bg-row" style={{ width: '80%' }} />
        <div className="mds-spec-overlay__bg-row" style={{ width: '60%' }} />
      </div>

      {/* scrim */}
      <div className="mds-spec-overlay__scrim">
        <div
          className="mds-spec-overlay__dialog-card mds-spec-overlay__dialog-card--wide"
          style={{ gap: 'var(--spacing-sm)' }}
        >
          <span className="mds-spec-overlay__dialog-title">{title}</span>
          <div className="mds-spec-overlay__dialog-custom-content">{children}</div>
          {actions && (
            <div className="mds-spec-overlay__dialog-actions">{actions}</div>
          )}
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
          <th style={{ width: 310 }}>{previewLabel}</th>
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
// Sample content snippets
// ---------------------------------------------------------------------------

/** Image picker stub */
function ImagePickerContent() {
  return (
    <>
      <div className="mds-spec-overlay__dialog-field">
        <span className="mds-spec-overlay__dialog-field-label">프로필 사진 선택</span>
      </div>
      <div style={{ display: 'flex', gap: 6 }}>
        <div style={{ flex: 1, height: 48, borderRadius: 8, background: 'var(--color-surface)', border: '1px solid var(--color-divider)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ fontSize: 11, color: 'var(--color-text-secondary)' }}>카메라</span>
        </div>
        <div style={{ flex: 1, height: 48, borderRadius: 8, background: 'var(--color-surface)', border: '1px solid var(--color-divider)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ fontSize: 11, color: 'var(--color-text-secondary)' }}>앨범</span>
        </div>
      </div>
    </>
  );
}

/** Report reason picker stub */
function ReportContent() {
  const reasons = ['부적절한 내용', '스팸 또는 광고', '사기 또는 허위 정보'];
  return (
    <>
      {reasons.map((r) => (
        <div
          key={r}
          style={{
            height: 28,
            borderRadius: 6,
            background: 'var(--color-surface)',
            display: 'flex',
            alignItems: 'center',
            paddingLeft: 8,
          }}
        >
          <span style={{ fontSize: 11, color: 'var(--color-text-secondary)' }}>{r}</span>
        </div>
      ))}
    </>
  );
}

/** Member count stepper stub */
function StepperContent() {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '4px 0' }}>
      <span style={{ fontSize: 12, color: 'var(--color-text-secondary)' }}>참여 인원</span>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{ width: 28, height: 28, borderRadius: 8, background: 'var(--color-surface)', border: '1px solid var(--color-divider)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ fontSize: 16, color: 'var(--color-text-primary)', lineHeight: 1 }}>−</span>
        </div>
        <span style={{ fontSize: 14, fontWeight: 700, minWidth: 24, textAlign: 'center' }}>4</span>
        <div style={{ width: 28, height: 28, borderRadius: 8, background: 'var(--color-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ fontSize: 16, color: 'white', lineHeight: 1 }}>+</span>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitDialogSpec() {
  return (
    <div className="mds-spec">
      <DialogStyles />

      {/* ── Hero ─────────────────────────────────────────────────────── */}
      <div className="mds-spec__hero" style={{ gap: 24 }}>
        <PhoneWithCustomDialog
          title="사진 가져오기"
          actions={
            <>
              <button className="mds-spec-btn mds-spec-btn--text mds-spec-btn--sm" style={{ height: 34, fontSize: 13 }}>취소</button>
              <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--sm" style={{ height: 34, fontSize: 13 }}>확인</button>
            </>
          }
        >
          <ImagePickerContent />
        </PhoneWithCustomDialog>

        <PhoneWithCustomDialog
          title="신고하기"
          actions={
            <>
              <button className="mds-spec-btn mds-spec-btn--text mds-spec-btn--sm" style={{ height: 34, fontSize: 13 }}>취소</button>
              <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--sm" style={{ height: 34, fontSize: 13 }}>신고</button>
            </>
          }
        >
          <ReportContent />
        </PhoneWithCustomDialog>
      </div>
      <p className="mds-spec__label" style={{ textAlign: 'center', marginTop: -8 }}>
        MinglitDialog — 커스텀 content Widget + actions
      </p>

      {/* ── Anatomy ──────────────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Anatomy</p>
        <div
          style={{
            position: 'relative',
            display: 'flex',
            justifyContent: 'center',
            padding: '48px 24px',
            background: 'var(--color-surface)',
            borderRadius: 'var(--radius-card)',
          }}
        >
          {/* annotation labels */}
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 8, left: '50%', transform: 'translateX(-50%)' }}>
            color-scrim — 배경 dimming
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 56, left: 8 }}>
            radius-dialog · 28px
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 56, right: 8 }}>
            title → content: spacing-small (8px)
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ bottom: 8, left: '50%', transform: 'translateX(-50%)' }}>
            actions padding: spacing-large (24px) horizontal
          </span>

          <div className="mds-spec-overlay__phone" style={{ width: 220, height: 360 }}>
            <div className="mds-spec-overlay__bg-content">
              <div className="mds-spec-overlay__bg-appbar" />
              <div className="mds-spec-overlay__bg-row mds-spec-overlay__bg-row--tall" />
              <div className="mds-spec-overlay__bg-row" />
            </div>
            <div className="mds-spec-overlay__scrim">
              <div className="mds-spec-overlay__dialog-card" style={{ width: 175 }}>
                <span className="mds-spec-overlay__dialog-title">참여 인원 설정</span>
                <StepperContent />
                <div className="mds-spec-overlay__dialog-actions">
                  <button className="mds-spec-btn mds-spec-btn--text mds-spec-btn--sm" style={{ height: 32, fontSize: 12 }}>취소</button>
                  <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--sm" style={{ height: 32, fontSize: 12 }}>확인</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ── Variants / Use cases ─────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Use cases</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'image-picker',
                preview: (
                  <PhoneWithCustomDialog
                    title="사진 가져오기"
                    actions={
                      <>
                        <button className="mds-spec-btn mds-spec-btn--text mds-spec-btn--sm" style={{ height: 32, fontSize: 12 }}>취소</button>
                        <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--sm" style={{ height: 32, fontSize: 12 }}>확인</button>
                      </>
                    }
                  >
                    <ImagePickerContent />
                  </PhoneWithCustomDialog>
                ),
                description: '카메라 / 앨범 선택 — MinglitImageSourceSheet를 dialog 안에 embed.',
              },
              {
                name: 'stepper',
                preview: (
                  <PhoneWithCustomDialog
                    title="참여 인원 설정"
                    actions={
                      <>
                        <button className="mds-spec-btn mds-spec-btn--text mds-spec-btn--sm" style={{ height: 32, fontSize: 12 }}>취소</button>
                        <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--sm" style={{ height: 32, fontSize: 12 }}>확인</button>
                      </>
                    }
                  >
                    <StepperContent />
                  </PhoneWithCustomDialog>
                ),
                description: 'NumberStepperInput embed — 숫자 입력을 모달로 처리할 때.',
              },
              {
                name: 'report',
                preview: (
                  <PhoneWithCustomDialog
                    title="신고하기"
                    actions={
                      <>
                        <button className="mds-spec-btn mds-spec-btn--text mds-spec-btn--sm" style={{ height: 32, fontSize: 12 }}>취소</button>
                        <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--sm" style={{ height: 32, fontSize: 12 }}>신고</button>
                      </>
                    }
                  >
                    <ReportContent />
                  </PhoneWithCustomDialog>
                ),
                description: '신고 사유 선택 — 라디오 리스트를 custom content로 전달.',
              },
            ]}
          />
        </div>
      </div>

      {/* ── Alert vs Dialog ──────────────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">MinglitAlert vs MinglitDialog</p>
        <div className="mds-spec__panel">
          <table className="mds-spec__tokens-table">
            <thead>
              <tr>
                <th style={{ width: 120 }}>항목</th>
                <th>MinglitAlert</th>
                <th>MinglitDialog</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><strong>content</strong></td>
                <td><code>String?</code> — 짧은 한 줄 설명</td>
                <td><code>Widget</code> — 임의 위젯 트리</td>
              </tr>
              <tr>
                <td><strong>actions</strong></td>
                <td>내장 (confirm/cancel TextButton)</td>
                <td>호출자가 <code>List&lt;Widget&gt;</code> 전달</td>
              </tr>
              <tr>
                <td><strong>destructive</strong></td>
                <td><code>isDestructive</code> 플래그 지원</td>
                <td>직접 MinglitButton.destructive 사용</td>
              </tr>
              <tr>
                <td><strong>적합한 상황</strong></td>
                <td>결정 요구 · 확인 · 단순 알림</td>
                <td>입력 · 선택 · 폼이 포함된 모달</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Guideline recipes
// ---------------------------------------------------------------------------
function DoCustomContent() {
  return (
    <PhoneWithCustomDialog
      title="신고하기"
      actions={
        <>
          <button className="mds-spec-btn mds-spec-btn--text mds-spec-btn--sm" style={{ height: 32, fontSize: 12 }}>취소</button>
          <button className="mds-spec-btn mds-spec-btn--primary mds-spec-btn--sm" style={{ height: 32, fontSize: 12 }}>신고</button>
        </>
      }
    >
      <ReportContent />
    </PhoneWithCustomDialog>
  );
}

function DontLongFormInDialog() {
  return (
    <div style={{ padding: 8, background: 'var(--color-surface)', borderRadius: 8, maxWidth: 200 }}>
      <p style={{ fontSize: 11, color: 'var(--color-text-secondary)', margin: 0 }}>
        NG: 스크롤이 필요한 장문 폼은 Dialog 금지 — 전용 화면으로 분리.
      </p>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-custom-content': DoCustomContent,
  'dont-long-form-in-dialog': DontLongFormInDialog,
};
