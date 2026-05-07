/**
 * Inline visual spec — MinglitBottomSheet
 *
 * Source of truth (Dart):
 *   shared/packages/mds/core/lib/src/ui/widgets/common/minglit_bottom_sheet.dart
 *
 * API:
 *   showMinglitBottomSheet()  — top-level function wrapping showModalBottomSheet
 *   MinglitBottomSheet        — content widget (title, showHandle, padding, child)
 *
 * Scaffold: "Bottom sheet" — this component IS the sheet surface on the scrim.
 * Top corners only: radius-card (16px). Drag handle: 32×4 px, divider color.
 *
 * Two exports:
 *   default          — visual playground
 *   GUIDELINE_RECIPES — keyed do/don't previews
 */

import type { ComponentType } from 'react';

// ---------------------------------------------------------------------------
// Shared phone / scrim CSS already injected by MinglitAlertSpec.
// This file adds bottom-sheet-specific overrides only.
// ---------------------------------------------------------------------------
const SHEET_CSS = `
/* bottom sheet variant labels for anatomy */
.mds-spec-overlay__anatomy-wrap--sheet {
  position: relative;
  display: flex;
  justify-content: center;
  padding: 48px 24px;
  background: var(--color-surface);
  border-radius: var(--radius-card);
  overflow: visible;
}
`;

function SheetStyles() {
  return <style dangerouslySetInnerHTML={{ __html: SHEET_CSS }} />;
}

// ---------------------------------------------------------------------------
// Faux phone with bottom sheet
// ---------------------------------------------------------------------------
function PhoneWithSheet({
  title,
  children,
  showHandle = true,
  heightPct = 55,
}: {
  title?: string;
  children: React.ReactNode;
  showHandle?: boolean;
  heightPct?: number;
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
        <div className="mds-spec-overlay__bg-row" style={{ width: '75%' }} />
        <div className="mds-spec-overlay__bg-row" style={{ width: '55%' }} />
      </div>

      {/* scrim */}
      <div className="mds-spec-overlay__scrim" style={{ alignItems: 'flex-end' }}>
        <div
          className="mds-spec-overlay__sheet"
          style={{ height: `${heightPct}%` }}
        >
          {showHandle && <div className="mds-spec-overlay__sheet-handle" />}
          {title && (
            <span className="mds-spec-overlay__sheet-title">{title}</span>
          )}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-small)', padding: '0 var(--spacing-medium)' }}>
            {children}
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Content snippets
// ---------------------------------------------------------------------------

/** Image source picker rows */
function ImageSourceRows() {
  const options = ['사진 가져오기', '카메라로 촬영', '앨범에서 선택', '취소'];
  return (
    <>
      {options.map((opt, i) => (
        <div
          key={opt}
          className="mds-spec-overlay__sheet-row"
          style={{
            display: 'flex',
            alignItems: 'center',
            paddingLeft: 12,
            background: i === 3 ? 'transparent' : 'var(--color-surface)',
            borderTop: i === 3 ? '1px solid var(--color-divider)' : undefined,
            marginTop: i === 3 ? 4 : undefined,
          }}
        >
          <span style={{ fontSize: 12, color: i === 3 ? 'var(--color-text-secondary)' : 'var(--color-text-primary)', fontWeight: i === 3 ? 400 : 500 }}>
            {opt}
          </span>
        </div>
      ))}
    </>
  );
}

/** Sort / filter option rows */
function SortOptionRows() {
  const options = [
    { label: '최신순', selected: true },
    { label: '인기순', selected: false },
    { label: '거리순', selected: false },
    { label: '가격순', selected: false },
  ];
  return (
    <>
      {options.map((opt) => (
        <div
          key={opt.label}
          className="mds-spec-overlay__sheet-row"
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            paddingLeft: 12,
            paddingRight: 12,
            background: opt.selected ? 'rgba(153,0,255,0.07)' : 'var(--color-surface)',
          }}
        >
          <span style={{ fontSize: 12, color: opt.selected ? 'var(--color-primary)' : 'var(--color-text-primary)', fontWeight: opt.selected ? 700 : 400 }}>
            {opt.label}
          </span>
          {opt.selected && (
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path d="M5 13l4 4L19 7" stroke="var(--color-primary)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          )}
        </div>
      ))}
    </>
  );
}

/** Member action rows */
function MemberActionRows() {
  const actions = [
    { label: '프로필 보기', destructive: false },
    { label: '1:1 채팅 보내기', destructive: false },
    { label: '참여 취소', destructive: true },
  ];
  return (
    <>
      {actions.map((a) => (
        <div
          key={a.label}
          className="mds-spec-overlay__sheet-row"
          style={{
            display: 'flex',
            alignItems: 'center',
            paddingLeft: 12,
            background: a.destructive ? 'transparent' : 'var(--color-surface)',
            borderTop: a.destructive ? '1px solid var(--color-divider)' : undefined,
            marginTop: a.destructive ? 4 : undefined,
          }}
        >
          <span style={{ fontSize: 12, color: a.destructive ? 'var(--color-error)' : 'var(--color-text-primary)' }}>
            {a.label}
          </span>
        </div>
      ))}
    </>
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
          <th style={{ width: 140 }}>Name</th>
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
// Default export
// ---------------------------------------------------------------------------
export default function MinglitBottomSheetSpec() {
  return (
    <div className="mds-spec">
      <SheetStyles />

      {/* ── Hero ─────────────────────────────────────────────────────── */}
      <div className="mds-spec__hero" style={{ gap: 24 }}>
        <PhoneWithSheet title="사진 가져오기">
          <ImageSourceRows />
        </PhoneWithSheet>
        <PhoneWithSheet title="정렬">
          <SortOptionRows />
        </PhoneWithSheet>
      </div>
      <p className="mds-spec__label" style={{ textAlign: 'center', marginTop: -8 }}>
        좌: 이미지 소스 선택 · 우: 정렬 옵션
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
            overflow: 'visible',
          }}
        >
          {/* annotation labels */}
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 8, left: '50%', transform: 'translateX(-50%)' }}>
            color-scrim — 상단 스크림
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 56, left: 8 }}>
            radius-card · 16px — 상단 모서리만
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ top: 56, right: 8 }}>
            drag handle: 32×4 px · color-divider
          </span>
          <span className="mds-spec-overlay__anatomy-label" style={{ bottom: 8, left: '50%', transform: 'translateX(-50%)' }}>
            content padding: spacing-screen-edge (16px) H · spacing-medium (16px) B
          </span>

          <div className="mds-spec-overlay__phone" style={{ width: 220, height: 360 }}>
            <div className="mds-spec-overlay__bg-content">
              <div className="mds-spec-overlay__bg-appbar" />
              <div className="mds-spec-overlay__bg-row mds-spec-overlay__bg-row--tall" />
              <div className="mds-spec-overlay__bg-row" />
            </div>
            <div className="mds-spec-overlay__scrim" style={{ alignItems: 'flex-end' }}>
              <div className="mds-spec-overlay__sheet" style={{ height: '58%' }}>
                <div className="mds-spec-overlay__sheet-handle" />
                <span className="mds-spec-overlay__sheet-title">사진 가져오기</span>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6, padding: '0 12px' }}>
                  {['카메라로 촬영', '앨범에서 선택', '취소'].map((t, i) => (
                    <div key={t} className="mds-spec-overlay__sheet-row" style={{ display: 'flex', alignItems: 'center', paddingLeft: 8, background: i === 2 ? 'transparent' : undefined }}>
                      <span style={{ fontSize: 11, color: i === 2 ? 'var(--color-text-secondary)' : 'var(--color-text-primary)' }}>{t}</span>
                    </div>
                  ))}
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
                name: 'default (isDismissible=true)',
                preview: (
                  <PhoneWithSheet title="사진 가져오기">
                    <ImageSourceRows />
                  </PhoneWithSheet>
                ),
                description: '외부 탭으로 닫힘. showHandle=true 기본. 이미지 선택, 옵션 시트 등 일반 케이스.',
              },
              {
                name: 'isScrollControlled=true',
                preview: (
                  <PhoneWithSheet title="전체 멤버 목록" heightPct={80}>
                    {[1, 2, 3, 4, 5, 6].map((i) => (
                      <div key={i} className="mds-spec-overlay__sheet-row" style={{ display: 'flex', alignItems: 'center', paddingLeft: 12 }}>
                        <span style={{ fontSize: 11, color: 'var(--color-text-primary)' }}>멤버 {i}</span>
                      </div>
                    ))}
                  </PhoneWithSheet>
                ),
                description: 'isScrollControlled=true — 시트 높이를 화면 80%까지 확장. 긴 목록 / 스크롤 컨텐츠에 사용.',
              },
              {
                name: 'showHandle=false',
                preview: (
                  <PhoneWithSheet showHandle={false} title="공지사항">
                    {[0, 1, 2].map((i) => (
                      <div key={i} className="mds-spec-overlay__sheet-row" style={{ display: 'flex', alignItems: 'center', paddingLeft: 12 }}>
                        <span style={{ fontSize: 11, color: 'var(--color-text-primary)' }}>공지 항목 {i + 1}</span>
                      </div>
                    ))}
                  </PhoneWithSheet>
                ),
                description: 'showHandle=false — 드래그 핸들 숨김. 닫기 버튼을 명시적으로 제공할 때.',
              },
            ]}
          />
        </div>
      </div>

      {/* ── Layout (inner components) ─────────────────────────────────── */}
      <div>
        <p className="mds-spec__label">Layout — 내부에 들어가는 mds 컴포넌트</p>
        <div className="mds-spec__panel">
          <PreviewTable
            rows={[
              {
                name: 'MinglitListTile rows',
                preview: (
                  <PhoneWithSheet title="멤버 옵션">
                    <MemberActionRows />
                  </PhoneWithSheet>
                ),
                description: 'MinglitListTile 또는 단순 row — 멤버 액션 / 정렬 옵션.',
              },
              {
                name: 'MinglitImageSourceSheet',
                preview: (
                  <PhoneWithSheet title="사진 가져오기">
                    <ImageSourceRows />
                  </PhoneWithSheet>
                ),
                description: 'MinglitImageSourceSheet를 child로 — 카메라/앨범 선택 패턴의 표준.',
              },
            ]}
          />
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Guideline recipes
// ---------------------------------------------------------------------------
function DoImageSource() {
  return (
    <PhoneWithSheet title="사진 가져오기">
      <ImageSourceRows />
    </PhoneWithSheet>
  );
}

function DontStackModals() {
  return (
    <div style={{ position: 'relative', width: 200, height: 140 }}>
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 20, background: 'rgba(0,0,0,0.3)', borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ width: 140, background: 'white', borderRadius: 12, padding: 10 }}>
          <div style={{ height: 8, background: 'var(--color-surface)', borderRadius: 4, marginBottom: 6 }} />
          <div style={{ height: 8, background: 'var(--color-surface)', borderRadius: 4, width: '60%' }} />
        </div>
      </div>
      <div style={{ position: 'absolute', bottom: 0, left: 10, right: 10, background: 'rgba(0,0,0,0.25)', borderRadius: '10px 10px 0 0', height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <span style={{ fontSize: 10, color: 'white' }}>NG: 모달 위 모달</span>
      </div>
    </div>
  );
}

function DoSortOptions() {
  return (
    <PhoneWithSheet title="정렬">
      <SortOptionRows />
    </PhoneWithSheet>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-image-source': DoImageSource,
  'dont-stack-modals': DontStackModals,
  'do-sort-options': DoSortOptions,
};
