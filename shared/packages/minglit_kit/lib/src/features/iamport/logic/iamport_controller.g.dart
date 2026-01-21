// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iamport_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IamportController)
const iamportControllerProvider = IamportControllerProvider._();

final class IamportControllerProvider
    extends
        $NotifierProvider<IamportController, AsyncValue<IamportResultModel?>> {
  const IamportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'iamportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$iamportControllerHash();

  @$internal
  @override
  IamportController create() => IamportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<IamportResultModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<IamportResultModel?>>(
        value,
      ),
    );
  }
}

String _$iamportControllerHash() => r'f45d925fe45305d65720f6bf65bd8bd46bda2120';

abstract class _$IamportController
    extends $Notifier<AsyncValue<IamportResultModel?>> {
  AsyncValue<IamportResultModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<IamportResultModel?>,
              AsyncValue<IamportResultModel?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<IamportResultModel?>,
                AsyncValue<IamportResultModel?>
              >,
              AsyncValue<IamportResultModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
