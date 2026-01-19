import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/notification/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _marketingConsent = false;
  bool _serviceNotification = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final repository = ref.read(notificationRepositoryProvider);
      final settings = await repository.getSettings(user.id);

      if (settings != null) {
        if (mounted) {
          setState(() {
            _marketingConsent = (settings['marketing_consent'] as bool?) ?? false;
            _serviceNotification = (settings['service_notification'] as bool?) ?? true;
            _isLoading = false;
          });
        }
      } else {
         // 설정이 없으면 기본값 유지 (이미 user_settings는 트리거로 생성되겠지만, 예외 처리)
         if (mounted) setState(() => _isLoading = false);
      }
    } on Object {
      if (mounted) setState(() => _isLoading = false);
      // 에러 처리
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Optimistic Update
    setState(() {
      if (key == 'marketing_consent') _marketingConsent = value;
      if (key == 'service_notification') _serviceNotification = value;
    });

    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.updateSettings(user.id, {key: value});
    } on Object {
      // Revert on error
      if (mounted) {
        setState(() {
          if (key == 'marketing_consent') _marketingConsent = !value;
          if (key == 'service_notification') _serviceNotification = !value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정 저장에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('서비스 알림'),
            subtitle: const Text('예약, 매칭 등 서비스 이용에 필수적인 알림을 받습니다.'),
            value: _serviceNotification,
            onChanged: (value) => _updateSetting('service_notification', value),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('마케팅 정보 수신 동의'),
            subtitle: const Text('이벤트, 할인 혜택 등 유용한 소식을 받습니다.'),
            value: _marketingConsent,
            onChanged: (value) => _updateSetting('marketing_consent', value),
          ),
        ],
      ),
    );
  }
}
