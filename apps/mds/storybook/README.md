# mds_storybook (DEPRECATED)

> ⚠️ **This package is deprecated as of 2026-04. Scheduled for removal: 2026-06.**
>
> Use **mds_docs** (https://dev.design.minglit.com — TBD) as the canonical design system catalog.
> The component-level showcase functionality of this app is being absorbed into `apps/mds/docs/components/` (Phase 2).

## Why deprecated

- Maintaining two separate catalogs (Widgetbook + mds_docs) at minglit's team scale exceeds the value
- Golden test infrastructure that justified Widgetbook is not yet active
- Designers/PM workflow centers on browser-based mds_docs — Flutter-only Widgetbook adds friction
- See `docs/architecture/mds-storybook-wiring-plan.md` for the original consolidation discussion

## Migration path

If you currently use mds_storybook for:

| Use case | Replacement |
|---|---|
| Browse mds components | `apps/mds/docs/` `/components` page (Phase 2) |
| Design review with isolated rendering | `apps/mds/docs/` + future component preview iframes |
| Golden test snapshots | TBD — direct `alchemist` integration in `apps/mds/storybook` will be considered if/when golden tests become a priority |

## Status

Until removal, this app remains buildable and functional for backward compatibility. **Do not add new stories here** — author them in mds_docs `/components` instead.

## Running (until removal)

```bash
cd apps/mds/storybook
flutter run --flavor dev --target lib/main.dart
```

## Building (debug APK)

```bash
flutter build apk --flavor dev --debug
```

## Dependencies

- [widgetbook](https://pub.dev/packages/widgetbook) ^3.22.0
- [widgetbook_annotation](https://pub.dev/packages/widgetbook_annotation) ^3.11.0
- [widgetbook_generator](https://pub.dev/packages/widgetbook_generator) ^3.22.0
