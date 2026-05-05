/**
 * Inline visual spec — MinglitHelpSheet
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/common/minglit_help_sheet.dart
 *
 * API:
 *   showMinglitHelpSheet()  — top-level function wrapping showModalBottomSheet
 *   HelpSection             — model (title, body, leading?)
 *
 * Scaffold: "Bottom sheet" — sheet rises from bottom on scrim (45% black).
 * Top corners only: radius-card (16px). Handle bar: 36×4px, muted divider color.
 * Max height: 75vh. Sticky CTA at bottom (partner-primary, 48px).
 *
 * Two exports:
 *   default          — visual playground
 *   GUIDELINE_RECIPES — keyed do/don't previews
 */

import type { ComponentType } from 'react';
import { SpecRoot, SpecSection } from './_atoms';

// ---------------------------------------------------------------------------
// Help-sheet-specific CSS (uses shared mds-spec-overlay__* base classes
// already injected by MinglitAlertSpec; adding sheet & help-specific atoms).
// ---------------------------------------------------------------------------
const HELP_SHEET_CSS = `
/* ── help sheet body inside phone ─────────────────────────────────────── */
.hs-sheet {
  position: absolute;
  left: 0; right: 0; bottom: 0;
  background: white;
  border-top-left-radius: var(--radius-card);
  border-top-right-radius: var(--radius-card);
  display: flex;
  flex-direction: column;
  max-height: 75%;
  overflow: hidden;
}
.hs-handle {
  width: 36px; height: 4px;
  background: var(--color-divider);
  border-radius: 999px;
  align-self: center;
  margin: var(--spacing-xsmall) 0 var(--spacing-xxsmall);
  opacity: 0.4;
}
.hs-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--color-text-primary);
  padding: var(--spacing-small) var(--spacing-medium);
}
.hs-body {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.hs-section {
  padding: var(--spacing-small) var(--spacing-medium);
  border-top: 1px solid var(--color-divider);
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.hs-section:first-child { border-top: none; }
.hs-section-row {
  display: flex;
  align-items: center;
  gap: 6px;
}
.hs-section-icon {
  width: 14px; height: 14px;
  background: #7c3aed;
  border-radius: 2px;
  flex-shrink: 0;
}
.hs-section-title {
  font-size: 12px;
  font-weight: 700;
  color: var(--color-text-primary);
}
.hs-section-body {
  font-size: 10px;
  color: var(--color-text-secondary);
  line-height: 1.55;
}
.hs-cta {
  padding: var(--spacing-small) var(--spacing-medium);
  border-top: 1px solid var(--color-divider);
}
.hs-cta-btn {
  width: 100%;
  height: 32px;
  background: #7c3aed;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
  color: white;
}

/* ── anatomy labels ────────────────────────────────────────────────────── */
.hs-anatomy-wrap {
  position: relative;
  display: flex;
  justify-content: center;
  padding: 24px;
  background: var(--color-surface);
  border-radius: var(--radius-card);
}
.hs-anatomy-label {
  position: absolute;
  font: 500 10px/1.2 ui-monospace, monospace;
  color: var(--color-primary);
  background: white;
  border: 1px solid var(--color-divider);
  padding: 2px 5px;
  border-radius: 4px;
  white-space: nowrap;
  pointer-events: none;
}
`;

function HelpSheetStyles() {
  return <style dangerouslySetInnerHTML={{ __html: HELP_SHEET_CSS }} />;
}

// ---------------------------------------------------------------------------
// Faux phone with help sheet open
// ---------------------------------------------------------------------------
function PhoneWithHelpSheet({
  sections,
  title = '파티 관리 가이드',
  confirmLabel = '확인',
}: {
  sections: Array<{ title: string; body: string; hasIcon?: boolean }>;
  title?: string;
  confirmLabel?: string;
}) {
  return (
    <div className="mds-spec-overlay__phone" style={{ width: 240, height: 420 }}>
      {/* background content */}
      <div className="mds-spec-overlay__bg-content">
        <div className="mds-spec-overlay__bg-appbar" />
        <div className="mds-spec-overlay__bg-row mds-spec-overlay__bg-row--tall" />
        <div className="mds-spec-overlay__bg-row" />
        <div className="mds-spec-overlay__bg-row" style={{ width: '70%' }} />
      </div>
      {/* scrim */}
      <div
        className="mds-spec-overlay__scrim"
        style={{ alignItems: 'flex-end', background: 'rgba(0,0,0,0.45)' }}
      >
        <div className="hs-sheet" style={{ width: '100%' }}>
          <div className="hs-handle" />
          <div className="hs-title">{title}</div>
          <div className="hs-body">
            {sections.map((s, i) => (
              <div key={i} className="hs-section">
                <div className="hs-section-row">
                  {s.hasIcon && <div className="hs-section-icon" />}
                  <span className="hs-section-title">{s.title}</span>
                </div>
                <div className="hs-section-body">{s.body}</div>
              </div>
            ))}
          </div>
          <div className="hs-cta">
            <div className="hs-cta-btn">{confirmLabel}</div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export — visual playground
// ---------------------------------------------------------------------------
export default function MinglitHelpSheetSpec() {
  return (
    <SpecRoot>
      <HelpSheetStyles />

      {/* ── Hero ── */}
      <SpecSection title="Hero">
        <div style={{ display: 'flex', gap: 'var(--spacing-large)', flexWrap: 'wrap', alignItems: 'flex-start', justifyContent: 'center' }}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
            <PhoneWithHelpSheet
              title="파티 관리 가이드"
              sections={[
                { title: '파티가 뭔가요?', body: '이벤트를 묶어 관리하는 단위입니다.' },
                { title: '이벤트와 파티의 차이는?', body: '이벤트는 구체적 활동, 파티는 여러 이벤트를 묶은 프로그램 단위.' },
                { title: '승인이 필요한가요?', body: '파티 생성은 즉시 활성화. 이벤트 단위로 신청 심사를 설정 가능.', hasIcon: true },
              ]}
            />
            <span style={{ fontSize: 11, color: 'var(--color-text-secondary)' }}>기본 — 다단 Q&A + leading icon</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
            <PhoneWithHelpSheet
              title="이벤트 도움말"
              sections={[
                { title: '이벤트 시작 전 무엇을 확인해야 하나요?', body: '참가자 심사 결과와 현장 체크인 코드를 확인하세요.' },
                { title: '심사를 거부하면 어떻게 되나요?', body: '참가자는 알림을 받고 자동 환불됩니다.' },
              ]}
              confirmLabel="닫기"
            />
            <span style={{ fontSize: 11, color: 'var(--color-text-secondary)' }}>2-section · 아이콘 없음 · 커스텀 라벨</span>
          </div>
        </div>
      </SpecSection>

      {/* ── Anatomy ── */}
      <SpecSection title="Anatomy">
        <div>
          <div className="hs-anatomy-wrap" style={{ minHeight: 340 }}>
            {/* Annotated help sheet cross-section */}
            <div
              style={{
                width: 220,
                background: 'white',
                borderRadius: 'var(--radius-card)',
                display: 'flex',
                flexDirection: 'column',
                border: '1px solid var(--color-divider)',
                boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
              }}
            >
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', paddingTop: 6, paddingBottom: 2 }}>
                <div className="hs-handle" />
              </div>
              <div className="hs-title">파티 관리 가이드</div>
              <div className="hs-section">
                <div className="hs-section-row">
                  <div className="hs-section-icon" />
                  <span className="hs-section-title">파티가 뭔가요?</span>
                </div>
                <div className="hs-section-body">이벤트를 묶어 관리하는 단위입니다.</div>
              </div>
              <div className="hs-section">
                <div className="hs-section-row">
                  <span className="hs-section-title">이벤트와 파티의 차이는?</span>
                </div>
                <div className="hs-section-body">이벤트는 구체적 활동, 파티는 여러 이벤트를 묶은 프로그램.</div>
              </div>
              <div className="hs-cta">
                <div className="hs-cta-btn">확인</div>
              </div>
            </div>

            {/* Anatomy labels */}
            <div className="hs-anatomy-label" style={{ top: 24, left: 8 }}>① handle bar — 36×4px · muted</div>
            <div className="hs-anatomy-label" style={{ top: 58, left: 8 }}>② title — 16/700 onSurface</div>
            <div className="hs-anatomy-label" style={{ top: 104, right: 8 }}>③ section — 1px divider-top</div>
            <div className="hs-anatomy-label" style={{ top: 148, right: 8 }}>④ leading icon — 18×18 partner-primary (optional)</div>
            <div className="hs-anatomy-label" style={{ top: 192, right: 8 }}>⑤ section title — 14/700</div>
            <div className="hs-anatomy-label" style={{ top: 230, right: 8 }}>⑥ section body — 13 secondary 1.55lh</div>
            <div className="hs-anatomy-label" style={{ bottom: 48, left: 8 }}>⑦ sticky CTA — 48px partner-primary</div>
          </div>
          <table style={{ marginTop: 12, fontSize: 12, width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--color-divider)' }}>
                <th style={{ textAlign: 'left', padding: '4px 8px', color: 'var(--color-text-secondary)' }}>Region</th>
                <th style={{ textAlign: 'left', padding: '4px 8px', color: 'var(--color-text-secondary)' }}>Token / 크기</th>
              </tr>
            </thead>
            <tbody>
              {[
                ['① Handle bar', '36×4px · radius 999 · color-divider + muted opacity · margin xxsmall/xsmall'],
                ['② Title', 'titleMedium 16/700 · onSurface · padding small/medium'],
                ['③ Section divider', '1px top border · color-divider (첫 섹션 제외)'],
                ['④ Leading icon', '18×18 · partner-primary color · optional (HelpSection.leading)'],
                ['⑤ Section title', '14/700 · onSurface · gap small 아래 본문'],
                ['⑥ Section body', '13px regular · onSurfaceVariant · 1.55 line-height'],
                ['⑦ Sticky CTA', '48px height · full width · 15/700 white · partner-primary bg · padding medium + SafeArea'],
              ].map(([r, t]) => (
                <tr key={r} style={{ borderBottom: '1px solid var(--color-divider)' }}>
                  <td style={{ padding: '4px 8px', fontFamily: 'monospace' }}>{r}</td>
                  <td style={{ padding: '4px 8px', color: 'var(--color-text-secondary)' }}>{t}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </SpecSection>

      {/* ── HelpSection variants ── */}
      <SpecSection title="HelpSection variants">
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
          <thead>
            <tr style={{ borderBottom: '1px solid var(--color-divider)' }}>
              <th style={{ textAlign: 'left', padding: '4px 8px', color: 'var(--color-text-secondary)' }}>Variant</th>
              <th style={{ textAlign: 'left', padding: '4px 8px', color: 'var(--color-text-secondary)' }}>When</th>
              <th style={{ textAlign: 'left', padding: '4px 8px', color: 'var(--color-text-secondary)' }}>Preview</th>
            </tr>
          </thead>
          <tbody>
            <tr style={{ borderBottom: '1px solid var(--color-divider)' }}>
              <td style={{ padding: '8px' }}>Text only</td>
              <td style={{ padding: '8px', color: 'var(--color-text-secondary)' }}>leading: null (기본)</td>
              <td style={{ padding: '8px' }}>
                <div className="hs-section" style={{ border: '1px solid var(--color-divider)', borderRadius: 8 }}>
                  <div className="hs-section-title">이벤트와 파티의 차이는?</div>
                  <div className="hs-section-body">이벤트는 구체적 활동, 파티는 여러 이벤트를 묶은 프로그램 단위.</div>
                </div>
              </td>
            </tr>
            <tr>
              <td style={{ padding: '8px' }}>With leading icon</td>
              <td style={{ padding: '8px', color: 'var(--color-text-secondary)' }}>leading: Icon(...) — 규칙/정책 강조</td>
              <td style={{ padding: '8px' }}>
                <div className="hs-section" style={{ border: '1px solid var(--color-divider)', borderRadius: 8 }}>
                  <div className="hs-section-row">
                    <div className="hs-section-icon" />
                    <span className="hs-section-title">승인이 필요한가요?</span>
                  </div>
                  <div className="hs-section-body">파티 생성은 즉시 활성화. 이벤트 단위로 신청 심사를 설정할 수 있어요.</div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </SpecSection>
    </SpecRoot>
  );
}

// ---------------------------------------------------------------------------
// GUIDELINE_RECIPES — do/don't recipe previews
// ---------------------------------------------------------------------------
function DoInfoIconPattern() {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: 'var(--spacing-medium)' }}>
      <div
        style={{
          width: 36, height: 36,
          borderRadius: 'var(--radius-card)',
          background: 'var(--color-surface)',
          border: '1px solid var(--color-divider)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 18,
        }}
      >ℹ️</div>
      <div style={{ fontSize: 12, color: 'var(--color-text-secondary)' }}>
        AppBar 우측 info 아이콘 → showMinglitHelpSheet
      </div>
    </div>
  );
}

function DontActionInHelp() {
  return (
    <div style={{ padding: 'var(--spacing-medium)' }}>
      <div style={{ fontSize: 12, color: 'var(--color-text-secondary)', marginBottom: 8 }}>
        HelpSheet 안에 버튼/폼 삽입 ❌
      </div>
      <div className="hs-section" style={{ border: '1px solid var(--color-error)', borderRadius: 8 }}>
        <div className="hs-section-title">파티 삭제하기</div>
        <div style={{ marginTop: 4 }}>
          <div className="hs-cta-btn" style={{ background: '#dc2626', height: 24, fontSize: 10 }}>삭제</div>
        </div>
      </div>
    </div>
  );
}

function DoQaFormat() {
  return (
    <div style={{ padding: 'var(--spacing-medium)' }}>
      <div className="hs-section" style={{ border: '1px solid var(--color-divider)', borderRadius: 8 }}>
        <div className="hs-section-title">파티가 뭔가요? ✓</div>
        <div className="hs-section-body">질문 형태 제목 — 사용자 mental model 반영</div>
      </div>
    </div>
  );
}

function DontSingleSection() {
  return (
    <div style={{ padding: 'var(--spacing-medium)' }}>
      <div style={{ fontSize: 12, color: 'var(--color-text-secondary)', marginBottom: 8 }}>
        단일 섹션이면 MinglitBottomSheet + Text 사용 ✓
      </div>
      <div className="hs-section" style={{ border: '1px solid var(--color-warning)', borderRadius: 8, opacity: 0.7 }}>
        <div className="hs-section-title">도움말 (단일)</div>
        <div className="hs-section-body">섹션 1개면 HelpSheet 오버킬 — BottomSheet 사용.</div>
      </div>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-info-icon-pattern': DoInfoIconPattern,
  'dont-action-in-help':   DontActionInHelp,
  'do-qa-format':          DoQaFormat,
  'dont-single-section':   DontSingleSection,
};
