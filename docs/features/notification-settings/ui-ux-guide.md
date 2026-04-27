# UI/UX Guide: Notification Settings Screen

## Overview
This document provides the UI/UX design guide for the new category-based notification settings screen.

## IA (Information Architecture)
- **Path**: `My Page` > `Settings` > `Notification Settings` (`/settings/notifications`)
- **Structure**:
    - **Group 1: Essential Service Notifications** (Mandatory toggle or high priority)
    - **Group 2: Activity-based Notifications** (Optional toggles)
    - **Group 3: Marketing Information** (Optional toggle)

## UI Components
- **MinglitSettingsGroup**: Use to wrap each logical group.
- **MinglitSettingsTile**: Use for each notification toggle.
    - `trailing`: `SettingsTileTrailing.toggle`
    - `subtitle`: Brief description of what notifications are included.

## Category Mapping
| Display Name | Included Event Types | Description |
| :--- | :--- | :--- |
| **Service Notifications** | `event_reminder`, etc. | Essential service updates. |
| **Match Results** | `match_result` | Notification for event matching success/failure. |
| **Application Status** | `application_approved`, `application_rejected`, `new_application` | Updates on your join requests. |
| **Event News & Changes** | `event_updated`, `event_cancelled` | Changes to events you are participating in. |
| **Activity & Interactions**| `party_created`, `user_interaction` | Social interactions and party creations. |
| **Verification & Security**| `verification_result` | Identity verification results and account security. |
| **Marketing Info** | - | Promotions, discounts, and news. |

## UX Principles
1. **Consistency**: Use existing design tokens (`MinglitSpacing`, `MinglitRadius`, `MinglitSettingsGroup`).
2. **Clarity**: Descriptions must clearly explain what the user will (or won't) receive.
3. **Optimistic UI**: Toggle should switch immediately, with background sync and error handling.

## Prototype
Refer to [wireframe.html](./wireframe.html) for the visual layout.
