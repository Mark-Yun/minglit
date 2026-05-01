/**
 * MinglitSectionDivider — content separator.
 *
 * Source: shared/packages/mds/core/lib/src/ui/widgets/common/minglit_section_divider.dart
 *   variants: thin (1px · divider color) · thick (8px · surface gray)
 *
 * Visual contract — what the user sees:
 *   thin  = 카드 / 그룹 안에서 한 행과 다음 행을 가르는 부드러운 선
 *   thick = 화면을 두 영역으로 갈라주는 굵은 회색 띠
 */

import type { ComponentType } from 'react';
import {
  PreviewTable,
  SpecHero,
  SpecRoot,
  SpecSection,
} from './_atoms';

// ---------------------------------------------------------------------------
// Visual atom — bare div with the right height + color.
// ---------------------------------------------------------------------------
function DividerDemo({ variant = 'thin' }: { variant?: 'thin' | 'thick' }) {
  if (variant === 'thick') {
    return (
      <div
        style={{
          width: '100%',
          height: 8,
          background: 'var(--color-surface)',
          borderRadius: 1,
        }}
      />
    );
  }
  return (
    <div
      style={{
        width: '100%',
        height: 1,
        background: 'var(--color-divider)',
      }}
    />
  );
}

// Demo wrapper that shows the divider sandwiched between two text rows so
// readers see how it functions in real use.
function DividerInContext({ variant = 'thin' }: { variant?: 'thin' | 'thick' }) {
  return (
    <div style={{ width: '100%', display: 'flex', flexDirection: 'column' }}>
      <div
        style={{
          padding: '12px 16px',
          color: 'var(--color-text-primary)',
          fontSize: 14,
        }}
      >
        위쪽 행
      </div>
      <DividerDemo variant={variant} />
      <div
        style={{
          padding: '12px 16px',
          color: 'var(--color-text-primary)',
          fontSize: 14,
        }}
      >
        아래쪽 행
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Default export
// ---------------------------------------------------------------------------
export default function MinglitSectionDividerSpec() {
  return (
    <SpecRoot>
      <SpecHero>
        <div style={{ width: '100%', maxWidth: 360 }}>
          <DividerInContext variant="thin" />
        </div>
      </SpecHero>

      <SpecSection title="Variants">
        <PreviewTable
          rows={[
            {
              name: 'thin',
              preview: (
                <div style={{ width: 200 }}>
                  <DividerDemo variant="thin" />
                </div>
              ),
              description:
                '같은 그룹 안에서 행과 행을 가르는 1px 얇은 선. 카드 안 리스트, 설정 항목 사이 등 부드러운 구분에 사용.',
            },
            {
              name: 'thick',
              preview: (
                <div style={{ width: 200 }}>
                  <DividerDemo variant="thick" />
                </div>
              ),
              description:
                '화면을 두 영역으로 갈라주는 8px 굵은 회색 띠. 계정 / 알림 / 정보 같은 큰 섹션 사이에 사용.',
            },
          ]}
        />
      </SpecSection>

      <SpecSection title="In context">
        <PreviewTable
          previewLabel="Preview"
          rows={[
            {
              name: 'thin · 같은 그룹 내',
              preview: (
                <div style={{ width: 240, background: 'white', borderRadius: 12 }}>
                  <DividerInContext variant="thin" />
                </div>
              ),
              description:
                '카드 / 그룹 안에서 행 사이 — 카드의 둥근 모서리 안쪽에서 좌우 끝까지 또는 leading 아이콘 폭만큼 들여쓴 형태로 그어짐.',
            },
            {
              name: 'thick · 큰 섹션 사이',
              preview: (
                <div style={{ width: 240 }}>
                  <DividerInContext variant="thick" />
                </div>
              ),
              description:
                '카드 밖 — 화면 전체 폭으로 회색 띠가 그어져 영역이 다르다는 신호를 강하게 줌.',
            },
          ]}
        />
      </SpecSection>
    </SpecRoot>
  );
}

// ---------------------------------------------------------------------------
// Recipes
// ---------------------------------------------------------------------------
function DoThinInsideGroup() {
  return (
    <div style={{ width: 240, background: 'white', borderRadius: 12 }}>
      <DividerInContext variant="thin" />
    </div>
  );
}

function DoThickBetweenSections() {
  return (
    <div style={{ width: 240 }}>
      <DividerInContext variant="thick" />
    </div>
  );
}

function DontStackedThicks() {
  return (
    <div style={{ width: 240, display: 'flex', flexDirection: 'column' }}>
      <div style={{ padding: '8px 12px', fontSize: 13, color: 'var(--color-text-primary)' }}>
        프로필
      </div>
      <DividerDemo variant="thick" />
      <div style={{ padding: '8px 12px', fontSize: 13, color: 'var(--color-text-primary)' }}>
        보안
      </div>
      <DividerDemo variant="thick" />
      <div style={{ padding: '8px 12px', fontSize: 13, color: 'var(--color-text-primary)' }}>
        알림
      </div>
    </div>
  );
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-thin-inside-group': DoThinInsideGroup,
  'do-thick-between-sections': DoThickBetweenSections,
  'dont-stacked-thicks': DontStackedThicks,
};
