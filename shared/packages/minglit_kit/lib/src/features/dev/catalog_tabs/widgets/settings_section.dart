import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Section for the design catalog to showcase settings components.
class SettingsSection extends StatelessWidget {
  /// Creates a [SettingsSection].
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.medium),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: MinglitSpacing.medium),
          child: Text(
            'Settings Components',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        
        MinglitSettingsGroup(
          header: 'General',
          children: [
            const MinglitSettingsTile(
              leading: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Enabled',
            ),
            MinglitSettingsTile(
              leading: Icons.dark_mode_outlined,
              title: 'Theme',
              subtitle: 'System',
              onTap: () {},
            ),
            const MinglitSettingsTile(
              leading: Icons.language_outlined,
              title: 'Language',
              trailing: SettingsTileTrailing.value,
              trailingValue: 'English',
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.large),
        
        MinglitSettingsGroup(
          header: 'Preferences',
          children: [
            MinglitSettingsTile(
              leading: Icons.vibration_outlined,
              title: 'Haptic Feedback',
              trailing: SettingsTileTrailing.toggle,
              toggleValue: true,
              onToggleChanged: (v) {},
            ),
            MinglitSettingsTile(
              leading: Icons.location_on_outlined,
              title: 'Location Access',
              trailing: SettingsTileTrailing.toggle,
              toggleValue: false,
              onToggleChanged: (v) {},
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.large),
        
        MinglitSettingsGroup(
          header: 'Account',
          children: [
            const MinglitSettingsTile(
              leading: Icons.info_outline,
              title: 'App Version',
              trailing: SettingsTileTrailing.value,
              trailingValue: '1.0.0',
            ),
            MinglitSettingsTile(
              leading: Icons.logout_outlined,
              title: 'Logout',
              destructive: true,
              trailing: SettingsTileTrailing.none,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}
