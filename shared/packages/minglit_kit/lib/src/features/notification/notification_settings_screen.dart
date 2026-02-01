import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/features/notification/logic/notification_settings_controller.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_async_value_widget.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: MinglitAsyncValueWidget(
        value: settingsAsync,
        data: (settings) {
          if (settings == null) {
            return const Center(child: Text('설정 정보를 불러올 수 없습니다.'));
          }

          return ListView(
            children: [
              SwitchListTile(
                title: const Text('서비스 알림'),
                subtitle: const Text('예약, 매칭 등 서비스 이용에 필수적인 알림을 받습니다.'),
                value: settings.serviceNotification,
                onChanged: (value) {
                  unawaited(
                    ref
                        .read(notificationSettingsControllerProvider.notifier)
                        .updateSetting(
                          key: 'service_notification',
                          value: value,
                        ),
                  );
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('마케팅 정보 수신 동의'),
                subtitle: const Text('이벤트, 할인 혜택 등 유용한 소식을 받습니다.'),
                value: settings.marketingConsent,
                onChanged: (value) {
                  unawaited(
                    ref
                        .read(notificationSettingsControllerProvider.notifier)
                        .updateSetting(
                          key: 'marketing_consent',
                          value: value,
                        ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
