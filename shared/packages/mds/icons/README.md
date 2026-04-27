# mds_icons

Minglit Design System icons — SVG-based, theme-aware via `currentColor`.

## Usage

```dart
import 'package:mds_icons/mds_icons.dart';

// Basic usage — inherits color from parent DefaultTextStyle / IconTheme
MdsIcons.search(size: 24)

// Explicit color
MdsIcons.person(size: 20, color: Theme.of(context).colorScheme.primary)

// Inside a Row / Column
Row(
  children: [
    MdsIcons.chevronRight(size: 16, color: context.colors.textSecondary),
    const SizedBox(width: 4),
    Text('Next'),
  ],
)
```

## Migration from Material Icons

New code should use `mds_icons` instead of `Icon(Icons.X)`. Existing usages are
not forced to migrate — replacement is gradual.

```dart
// Before
Icon(Icons.person, size: 24, color: theme.colorScheme.primary)

// After
MdsIcons.person(size: 24, color: theme.colorScheme.primary)
```

## Icon set (PoC — 8 icons)

| `MdsIcons` accessor   | Material equivalent     | Lucide source          |
|-----------------------|-------------------------|------------------------|
| `chevronRight`        | `Icons.chevron_right`   | `chevron-right`        |
| `search`              | `Icons.search`          | `search`               |
| `close`               | `Icons.close`           | `x`                    |
| `add`                 | `Icons.add`             | `plus`                 |
| `check`               | `Icons.check`           | `check`                |
| `person`              | `Icons.person`          | `user`                 |
| `notifications`       | `Icons.notifications`   | `bell`                 |
| `moreVert`            | `Icons.more_vert`       | `ellipsis-vertical`    |

## Codegen

SVG sources live in `icons/*.svg`. The build script optimises them with svgo
(currentColor substitution for theme awareness) and generates `lib/generated/icons.g.dart`.

```bash
cd shared/packages/mds/icons
npm install
npm run build
# → lib/generated/icons.g.dart  (git-tracked)
# → manifest.json               (git-tracked)
```

Generated files are **committed** so consumers do not need to run the build step.

## Adding a new icon

1. Place `<name>.svg` in `icons/` (snake_case name).
2. Run `npm run build`.
3. Commit both the SVG and the regenerated `lib/generated/icons.g.dart` + `manifest.json`.

## License

SVG sources from [Lucide](https://lucide.dev) — ISC License.
Minglit custom icons (if any) — Proprietary.
