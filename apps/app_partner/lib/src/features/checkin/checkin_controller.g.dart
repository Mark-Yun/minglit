// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CheckinController)
const checkinControllerProvider = CheckinControllerProvider._();

final class CheckinControllerProvider
    extends $NotifierProvider<CheckinController, CheckinState> {
  const CheckinControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkinControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkinControllerHash();

  @$internal
  @override
  CheckinController create() => CheckinController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckinState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckinState>(value),
    );
  }
}

String _$checkinControllerHash() => r'1f2eb82b25de3cdf059caa84845ec090b4f5220e';

abstract class _$CheckinController extends $Notifier<CheckinState> {
  CheckinState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CheckinState, CheckinState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CheckinState, CheckinState>,
              CheckinState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
