/**
 * Template for an inline visual spec.
 *
 * COPY this file, rename to `<ComponentName>Spec.tsx`, then:
 *   1. Read the Flutter widget at the path noted in HEADER below.
 *   2. Replace `Foo` placeholders with the real component name.
 *   3. Implement the `FooDemo` atom — a React-only stand-in that mirrors
 *      the widget's visual contract (NOT its implementation). Use only
 *      design tokens (`var(--color-primary)`, `var(--spacing-medium)`, …)
 *      and the same prop names as the Dart side, even if the demo is a
 *      simple HTML element underneath.
 *   4. Fill out Hero / Anatomy / Variants / Sizes / States / etc. sections
 *      below. Delete sections that don't apply to the component (e.g. a
 *      divider doesn't have variants — drop the Variants section).
 *   5. Author do/don't recipes and export them via GUIDELINE_RECIPES so
 *      the components page can render them next to guideline text.
 *   6. Register in src/app/components/page.tsx INLINE_SPECS map.
 *   7. Fill the matching components.ts entry — props / variants / states /
 *      tokens / guidelines (with recipeKey matching this file's recipes).
 *
 * RULE — same as for the screen specs (apps/mds/docs/public/specs/):
 * This file documents WHAT the user sees and the component's visual
 * contract. It does NOT prescribe Flutter implementation details
 * (no provider names, controller methods, lifecycle calls, etc.).
 * Code references are OK in: the Dart usage block, the Tokens table,
 * and the prop names / variant names / state names themselves
 * (those are the contract).
 */

// ---------------------------------------------------------------------------
// HEADER (delete after filling)
//
// Component:    Foo
// Source:       shared/packages/mds/core/lib/src/ui/widgets/.../foo.dart
// Category:     atoms | molecules | feedback | layout | etc.
// Status:       new — please review
// ---------------------------------------------------------------------------

import type { ComponentType, ReactNode } from 'react';
import {
  PreviewTable,
  SpecAnatomy,
  SpecHero,
  SpecRoot,
  SpecSection,
} from './_atoms';

// ---------------------------------------------------------------------------
// Visual atom — React stand-in that mirrors the Flutter widget's visual
// contract. Keep prop names aligned with Dart so the spec reads consistently.
// Implement with design tokens only (no hardcoded colors / sizes).
// ---------------------------------------------------------------------------
function FooDemo({
  variant = 'default',
  size = 'md',
  disabled = false,
  children,
}: {
  variant?: 'default' | 'emphasized';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  children?: ReactNode;
}) {
  const cls = [
    'mds-spec-foo',
    `mds-spec-foo--${variant}`,
    `mds-spec-foo--${size}`,
    disabled && 'mds-spec-foo--disabled',
  ]
    .filter(Boolean)
    .join(' ');
  return <span className={cls}>{children}</span>;
}

// ---------------------------------------------------------------------------
// Default export — the playground rendered inline on /components.
// ---------------------------------------------------------------------------
export default function FooSpec() {
  return (
    <SpecRoot>
      {/* Hero — one canonical preview at default size. Single child. */}
      <SpecHero>
        <FooDemo variant="default" size="md">
          예시 텍스트
        </FooDemo>
      </SpecHero>

      {/* Anatomy — labels point to which token controls which dimension.
          Position is up to you (top/bottom/left/right with absolute style).
          Drop this section if the component has no interesting anatomy. */}
      <SpecAnatomy
        subject={<FooDemo>예시 텍스트</FooDemo>}
        subjectClassName="mds-spec__anatomy-foo"
        labels={[
          { text: 'radius-… (Npx)', style: { top: 12, left: '50%', transform: 'translateX(-50%)' } },
          { text: 'spacing-… → padding', style: { top: '50%', left: 0 } },
        ]}
      />

      {/* Variants — drop section if the component has none. */}
      <SpecSection title="Variants">
        <PreviewTable
          rows={[
            {
              name: 'default',
              preview: <FooDemo variant="default">기본</FooDemo>,
              description: '언제 쓰는지 — 사용자 관점에서 한 줄.',
            },
            {
              name: 'emphasized',
              preview: <FooDemo variant="emphasized">강조</FooDemo>,
              description: '언제 쓰는지 — 사용자 관점에서 한 줄.',
            },
          ]}
        />
      </SpecSection>

      {/* Sizes — drop section if the component is single-size. */}
      <SpecSection title="Sizes">
        <PreviewTable
          rows={[
            {
              name: 'small',
              preview: <FooDemo size="sm">예시</FooDemo>,
              description: 'height N · 어디 쓰는지 한 줄.',
            },
            {
              name: 'medium (default)',
              preview: <FooDemo size="md">예시</FooDemo>,
              description: 'height N · 기본 크기. 폼 인라인 등.',
            },
            {
              name: 'large',
              preview: <FooDemo size="lg">예시</FooDemo>,
              description: 'height N · 메인 액션 등.',
            },
          ]}
        />
      </SpecSection>

      {/* States — Default / Disabled / Loading / etc. */}
      <SpecSection title="States">
        <PreviewTable
          rows={[
            {
              name: 'default',
              preview: <FooDemo>예시</FooDemo>,
              description: '인터랙션 가능한 일반 상태.',
            },
            {
              name: 'disabled',
              preview: <FooDemo disabled>예시</FooDemo>,
              description: '탭 차단 — 흐려진 색상으로 표시.',
            },
          ]}
        />
      </SpecSection>
    </SpecRoot>
  );
}

// ---------------------------------------------------------------------------
// Recipes — short visual previews keyed to GuidelineEntry.recipeKey in
// components.ts. The components page renders these next to guideline text
// for inline do/don't visualisations. Add as many as the component needs.
// ---------------------------------------------------------------------------
function DoExample() {
  return <FooDemo variant="default">올바른 예</FooDemo>;
}

function DontExample() {
  return <FooDemo variant="emphasized">잘못된 예</FooDemo>;
}

export const GUIDELINE_RECIPES: Record<string, ComponentType> = {
  'do-example': DoExample,
  'dont-example': DontExample,
};
