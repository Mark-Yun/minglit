# mds_storybook

Widgetbook-based storybook app for the Minglit Design System (MDS).

Provides an isolated environment to browse and test MDS components without running the full app.

## Running

```bash
cd apps/mds_storybook
flutter run --flavor dev --target lib/main.dart
```

## Building (debug APK)

```bash
flutter build apk --flavor dev --debug
```

## Status

This is the bootstrap skeleton (PoC). Real MDS component stories will be migrated from
`features/dev/catalog_tabs/` in a follow-up PR once `shared/packages/mds` is wired in.

## Dependencies

- [widgetbook](https://pub.dev/packages/widgetbook) ^3.22.0 — Flutter Storybook
- [widgetbook_annotation](https://pub.dev/packages/widgetbook_annotation) ^3.11.0 — codegen annotations (for follow-up PR)
- [widgetbook_generator](https://pub.dev/packages/widgetbook_generator) ^3.22.0 — build_runner codegen
