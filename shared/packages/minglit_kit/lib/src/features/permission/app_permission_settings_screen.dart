import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Fix #186: App permission settings screen showing current
/// permission statuses.
/// Implemented in minglit_kit so both app_user and app_partner
/// can reuse it.
class AppPermissionSettingsScreen extends StatefulWidget {
  /// Creates an [AppPermissionSettingsScreen].
  const AppPermissionSettingsScreen({super.key});

  @override
  State<AppPermissionSettingsScreen> createState() =>
      _AppPermissionSettingsScreenState();
}

class _AppPermissionSettingsScreenState
    extends State<AppPermissionSettingsScreen>
    with WidgetsBindingObserver {
  final List<_PermissionItem> _permissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadPermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Fix #186: 시스템 설정에서 돌아왔을 때 권한 상태를 다시 로드
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadPermissions());
    }
  }

  Future<void> _loadPermissions() async {
    final items = <_PermissionItem>[];

    // Fix #186: 위치 권한 — geolocator로 확인
    final locationStatus = await _checkLocationPermission();
    items.add(
      _PermissionItem(
        icon: Icons.location_on_outlined,
        title: '위치',
        description: '내 주변 이벤트 검색에 사용됩니다',
        status: locationStatus,
      ),
    );

    // Fix #186: 알림 권한 — firebase_messaging으로 확인
    if (!kIsWeb) {
      final notifStatus =
          await _checkNotificationPermission();
      items.add(
        _PermissionItem(
          icon: Icons.notifications_outlined,
          title: '알림',
          description: '예약, 매칭 등 서비스 알림을 받습니다',
          status: notifStatus,
        ),
      );
    }

    // Fix #186: 카메라 — 사용 시 시스템이 요청 (image_picker 위임)
    if (!kIsWeb) {
      items.add(
        const _PermissionItem(
          icon: Icons.camera_alt_outlined,
          title: '카메라',
          description: '프로필 사진 촬영에 사용됩니다',
          status: _PermissionStatus.onDemand,
        ),
      );
    }

    // Fix #186: 사진 — 사용 시 시스템이 요청
    if (!kIsWeb) {
      items.add(
        const _PermissionItem(
          icon: Icons.photo_library_outlined,
          title: '사진',
          description: '프로필 사진 및 파일 업로드에 사용됩니다',
          status: _PermissionStatus.onDemand,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _permissions
          ..clear()
          ..addAll(items);
        _loading = false;
      });
    }
  }

  Future<_PermissionStatus> _checkLocationPermission() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _PermissionStatus.disabled;

      final permission = await Geolocator.checkPermission();
      return switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse =>
          _PermissionStatus.granted,
        LocationPermission.deniedForever =>
          _PermissionStatus.permanentlyDenied,
        _ => _PermissionStatus.denied,
      };
    } on Exception {
      return _PermissionStatus.denied;
    }
  }

  Future<_PermissionStatus> _checkNotificationPermission()
      async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional =>
          _PermissionStatus.granted,
        AuthorizationStatus.denied =>
          _PermissionStatus.denied,
        _ => _PermissionStatus.denied,
      };
    } on Exception {
      return _PermissionStatus.denied;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('권한 설정')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '앱에서 사용하는 권한을 확인하고 '
                    '관리할 수 있습니다.',
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ..._permissions.map(
                  (item) => _PermissionTile(
                    item: item,
                    onTap: item.status ==
                            _PermissionStatus.onDemand
                        ? null
                        : _openAppSettings,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Text(
                    _settingsGuideText,
                    style:
                        theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _openAppSettings,
                    icon: const Icon(
                      Icons.settings_outlined,
                    ),
                    label: const Text('시스템 설정 열기'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  String get _settingsGuideText {
    if (kIsWeb) {
      return '브라우저 설정에서 권한을 관리할 수 있습니다.';
    }
    if (Platform.isIOS) {
      return '설정 > 밍글릿에서 각 권한을 변경할 수 있습니다.';
    }
    return '설정 > 앱 > 밍글릿에서 각 권한을 변경할 수 있습니다.';
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

enum _PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  disabled,
  onDemand,
}

class _PermissionItem {
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String description;
  final _PermissionStatus status;
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.item, this.onTap});

  final _PermissionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusText, statusColor) = _statusDisplay(theme);

    return ListTile(
      leading: Icon(
        item.icon,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(item.title),
      subtitle: Text(item.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: statusColor),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  (String, Color) _statusDisplay(ThemeData theme) {
    return switch (item.status) {
      _PermissionStatus.granted => (
        '허용됨',
        MinglitColors.success,
      ),
      _PermissionStatus.denied => (
        '거부됨',
        MinglitColors.error,
      ),
      _PermissionStatus.permanentlyDenied => (
        '거부됨',
        MinglitColors.error,
      ),
      _PermissionStatus.disabled => (
        '비활성',
        theme.colorScheme.onSurfaceVariant,
      ),
      _PermissionStatus.onDemand => (
        '사용 시 요청',
        theme.colorScheme.onSurfaceVariant,
      ),
    };
  }
}
