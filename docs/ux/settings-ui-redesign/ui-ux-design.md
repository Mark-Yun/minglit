# UX Design Review: Settings UI Redesign

**Scheduler**: needs-uiux-gemini-1
**Date**: 2026-04-15
**Reference**: Claude App Settings (Compact Card Group Style)

## 1. Problem Statement
The current MyPage/Settings UI in Minglit has low information density due to large font sizes (16px), wide vertical padding (56px+ height), and simple full-width dividers for sectioning. This results in excessive scrolling and a "loose" feel that lacks professional polish.

## 2. Design Goals
- Increase information density by ~25% (showing 13+ items instead of 10 per screen).
- Enhance visual hierarchy through **Card Grouping**.
- Provide immediate feedback by showing current settings values (Value text) on the tile.
- Maintain consistent visual language between User and Partner apps.

## 3. Visual Specifications

### A. MinglitSettingsTile (The Atom)
| Property | Value | Token / Reference |
|---|---|---|
| Height | **48px** (Fixed) | - |
| Horizontal Padding | 16px | `MinglitSpacing.medium` |
| Vertical Padding | 2px | `MinglitSpacing.xxsmall` |
| Leading Icon Size | 20px | `MinglitIconSize.small` |
| Leading Icon Color | Primary | `MinglitColors.primary` |
| Title Font | **14.5px** | `bodyMedium` |
| Value Font | 14px | `bodySmall` or `bodyMedium` secondary |
| Value Color | Secondary | `MinglitColors.textSecondary` |
| Trailing Icon | 16px Chevron | `Icons.chevron_right` |

### B. MinglitSettingsGroup (The Molecule)
| Property | Value | Token / Reference |
|---|---|---|
| Margin | 0 16px | `MinglitSpacing.screenEdge` |
| Background (Light) | White | `MinglitColors.surface` |
| Background (Dark) | Surface Dark | `MinglitColorsDark.surface` |
| Border Radius | 16px | `MinglitRadius.card` |
| Internal Divider | 1px Height | `MinglitColors.divider` |
| Divider Margin Left | 52px | (16 padding + 24 icon area + 12 gap) |
| Group Title | 13px Semibold | Upper case, secondary color |

## 4. Proposed Widget Interface

### 1. `MinglitSettingsTile`
```dart
class MinglitSettingsTile extends StatelessWidget {
  const MinglitSettingsTile({
    required this.title,
    this.leadingIcon,
    this.value,
    this.onTap,
    this.trailing,
    this.enabled = true,
    super.key,
  });

  final String title;
  final IconData? leadingIcon;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;
}
```

### 2. `MinglitSettingsGroup`
```dart
class MinglitSettingsGroup extends StatelessWidget {
  const MinglitSettingsGroup({
    this.title,
    required this.children,
    super.key,
  });

  final String? title;
  final List<Widget> children; // Should be MinglitSettingsTile
}
```

## 5. Deployment Plan
1. **Phase 1 (Implementation)**: Create new widgets in `minglit_kit`.
2. **Phase 2 (Migration)**: 
   - Apply to `app_user` MyPage.
   - Apply to `app_partner` Settings page.
3. **Phase 3 (Cleanup)**: Remove legacy dividers and loose `ListTile` usages in settings screens.

---
**Wireframe**: [`docs/features/settings-ui-redesign/wireframe.html`](./wireframe.html)
