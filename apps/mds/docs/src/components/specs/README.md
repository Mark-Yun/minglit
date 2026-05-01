# Component inline visual specs

Per-component visual playgrounds rendered on `/components`. Each `Foo Spec.tsx`
file exports:

- **default** — the inline playground (Hero / Anatomy / Variants / Sizes /
  States / etc.) shown in the component's section on `/components`.
- **`GUIDELINE_RECIPES`** — keyed do/don't previews rendered next to
  guideline text. Keys must match `GuidelineEntry.recipeKey` in
  `src/lib/components.ts`.

## Authoring a new spec

**Start from the template.** All shared boilerplate lives in `_atoms.tsx`,
and `_template.tsx` is a fully-annotated starting point.

1. Copy `_template.tsx` → `<ComponentName>Spec.tsx` in this directory.
2. Read the Flutter widget at `shared/packages/mds/core/lib/src/ui/widgets/...`
   to capture its visual contract (variants, sizes, states, anatomy).
3. Implement the React `Demo` atom — token-driven only. Keep prop names
   aligned with the Dart side, even if the React stand-in is simpler.
4. Fill out Hero / Anatomy / Variants / Sizes / States — drop sections
   that don't apply (e.g. a divider has no variants).
5. Author do/don't recipes and export them via `GUIDELINE_RECIPES`.
6. Register in `src/app/components/page.tsx` `INLINE_SPECS` map.
7. Fill the matching entry in `src/lib/components.ts` — props / variants /
   states / tokens / guidelines (with `recipeKey` matching this file).

## Tone rule

Same as the screen specs under `apps/mds/docs/public/specs/`:

> 구현의 자율성을 이 문서에서 강요하지 않는다. 여기서는 비주얼적인 것,
> 유저의 눈에 보이는 것만 정의한다.

Description cells in `PreviewTable` rows, the Hero copy, and the Anatomy
labels should describe **what the user sees / does**. Do not name
providers, controllers, lifecycle methods, or other implementation
mechanisms in user-visible cells.

Code references are still appropriate in:

- The `dartUsage` block in `components.ts` (it's literal sample code).
- The Tokens table (token names are the contract).
- Variant / state / size names themselves (they're API contract).

## Files

| File | Purpose |
|---|---|
| `_atoms.tsx` | `SpecRoot`, `SpecHero`, `SpecAnatomy`, `SpecSection`, `PreviewTable`, `PreviewRow`. Import these — do **not** redeclare locally. |
| `_template.tsx` | Copy this when starting a new spec. |
| `<Component>Spec.tsx` | Per-component playground + `GUIDELINE_RECIPES`. |

## Migrating a legacy spec to the shared atoms

Specs created before 2026-05-01 inline their own `PreviewTable` /
`PreviewRow`. To migrate one:

1. Delete the local `interface PreviewRow` and `function PreviewTable`.
2. Add `import { PreviewTable, type PreviewRow, SpecRoot, SpecHero, SpecSection, SpecAnatomy } from './_atoms';`
3. Replace `<div className="mds-spec">…</div>` with `<SpecRoot>…</SpecRoot>`.
4. Replace `<div><p className="mds-spec__label">X</p><div className="mds-spec__panel">…</div></div>`
   with `<SpecSection title="X">…</SpecSection>`.
5. Replace the inlined Hero / Anatomy markup with `<SpecHero>` / `<SpecAnatomy>`.
