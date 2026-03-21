// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages notification settings for the current user.

@ProviderFor(NotificationSettingsController)
const notificationSettingsControllerProvider =
    NotificationSettingsControllerProvider._();

/// Manages notification settings for the current user.
final class NotificationSettingsControllerProvider
    extends $AsyncNotifierProvider<NotificationSettingsController,
        UserSettings?> {
  /// Manages notification settings for the current user.
  const NotificationSettingsControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationSettingsControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationSettingsControllerHash();

  @$internal
  @override
  NotificationSettingsController create() => NotificationSettingsController();
}

String _$notificationSettingsControllerHash() =>
    r'3eb76130a30f844bbc6833a38bb9827ff5d75500';

/// Manages notification settings for the current user.

abstract class _$NotificationSettingsController
    extends $AsyncNotifier<UserSettings?> {
  FutureOr<UserSettings?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<UserSettings?>, UserSettings?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<UserSettings?>, UserSettings?>,
        AsyncValue<UserSettings?>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
