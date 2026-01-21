// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotificationSettingsController)
const notificationSettingsControllerProvider =
    NotificationSettingsControllerProvider._();

final class NotificationSettingsControllerProvider
    extends
        $AsyncNotifierProvider<NotificationSettingsController, UserSettings?> {
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
    r'6bd6b3b3cb0ea348bdb1d3ef959a722caab1dfd2';

abstract class _$NotificationSettingsController
    extends $AsyncNotifier<UserSettings?> {
  FutureOr<UserSettings?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<UserSettings?>, UserSettings?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserSettings?>, UserSettings?>,
              AsyncValue<UserSettings?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
