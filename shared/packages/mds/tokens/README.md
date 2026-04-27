# mds_tokens

Design tokens single source of truth for the Minglit Design System.

Color, spacing, radius, and typography values are authored in `tokens/*.json`
(W3C Design Tokens format) and compiled to a Dart `const` class via
[Style Dictionary](https://style-dictionary-v4.netlify.app/).

## What's here

```
tokens/
  color.json         # Color palette (light, dark, partner variants)
  spacing.json       # Spacing scale (0–64 px + semantic aliases)
  radius.json        # Border radius values
  typography.json    # Font family, size, weight tokens

lib/
  mds_tokens.dart        # Barrel export
  generated/
    tokens.g.dart        # AUTO-GENERATED — do not edit
```

## Using tokens in Dart

```dart
import 'package:mds_tokens/mds_tokens.dart';

// Color (int — pass directly to Color())
final bg = Color(MdsTokens.colorBackground);      // 0xFFFFFFFF
final primary = Color(MdsTokens.colorPrimary);    // 0xFF9900FF

// Spacing
SizedBox(height: MdsTokens.spacingMedium);        // 16.0

// Radius
BorderRadius.circular(MdsTokens.radiusCard);      // 16.0
```

## Adding or updating a token

1. Edit the relevant `tokens/*.json` file.
2. Run codegen:
   ```bash
   cd shared/packages/mds/tokens
   npm install    # first time only
   npm run build
   ```
3. Commit **both** the JSON source change and the regenerated `lib/generated/tokens.g.dart`.

## Why Style Dictionary?

Style Dictionary decouples the _source of truth_ (JSON) from platform-specific
output formats. Today it generates Dart consts. The same `tokens/*.json` can
later generate:

- **CSS custom properties** for `landing_user` / `landing_partner`
- **TypeScript / JS** for any future web SDK (`mds-react`)
- **iOS (Swift/ObjC)** if needed

Running `npm run build` is the only step needed to sync all platforms.

## Codegen output is git-tracked

`lib/generated/tokens.g.dart` is committed so Dart consumers do **not** need
Node.js installed. Only token authors need to run `npm run build`.
